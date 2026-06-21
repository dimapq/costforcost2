import hashlib
import json
import os
import subprocess
import sys
import tempfile
import threading
from pathlib import Path
from typing import Optional

import requests
from PySide6.QtCore import QObject, Property, QCoreApplication, QMetaObject, Qt, Signal, Slot

from version import (
    APP_EXE_NAME,
    APP_NAME,
    APP_VERSION,
    GITHUB_LATEST_RELEASE_API,
    STABLE_ZIP_ASSET_NAME,
    UPDATE_MANIFEST_URL,
    UPDATER_EXE_NAME,
)


class UpdateManager(QObject):
    busyChanged = Signal()
    statusMessageChanged = Signal()
    progressChanged = Signal()
    updateAvailableChanged = Signal()
    latestVersionChanged = Signal()
    releaseNotesChanged = Signal()
    enabledChanged = Signal()

    def __init__(self, install_dir: Path, updater_path: Path, enabled: bool, parent: Optional[QObject] = None):
        super().__init__(parent)
        self._install_dir = Path(install_dir)
        self._updater_path = Path(updater_path)
        self._enabled = bool(enabled)
        self._busy = False
        self._progress = -1.0
        self._status_message = ""
        self._update_available = False
        self._latest_version = ""
        self._release_notes = ""
        self._download_url = ""
        self._sha256 = ""
        self._worker_lock = threading.Lock()

    @Property(bool, notify=enabledChanged)
    def enabled(self):
        return self._enabled

    @Property(bool, notify=busyChanged)
    def busy(self):
        return self._busy

    @Property(float, notify=progressChanged)
    def progress(self):
        return self._progress

    @Property(str, notify=statusMessageChanged)
    def statusMessage(self):
        return self._status_message

    @Property(bool, notify=updateAvailableChanged)
    def updateAvailable(self):
        return self._update_available

    @Property(str, notify=latestVersionChanged)
    def latestVersion(self):
        return self._latest_version

    @Property(str, constant=True)
    def currentVersion(self):
        return APP_VERSION

    @Property(str, notify=releaseNotesChanged)
    def releaseNotes(self):
        return self._release_notes

    @Slot()
    def dismissStatus(self):
        if not self._busy:
            self._set_status("")
            self._set_update_available(False)
            self._set_release_notes("")
            self._set_latest_version("")
            self._download_url = ""
            self._sha256 = ""
            self._set_progress(-1.0)

    @Slot(bool)
    def checkForUpdates(self, user_initiated=False):
        if not self._enabled:
            if user_initiated:
                self._set_status("\u0410\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u043e\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435 \u0432\u044b\u043a\u043b\u044e\u0447\u0435\u043d\u043e \u0432 \u0442\u0435\u043a\u0443\u0449\u0435\u0439 \u0441\u0431\u043e\u0440\u043a\u0435 \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u044f.")
            return
        self._start_background(self._check_worker, bool(user_initiated))

    @Slot()
    def downloadAndInstallUpdate(self):
        if not self._enabled:
            self._set_status("\u0410\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u043e\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435 \u0432\u044b\u043a\u043b\u044e\u0447\u0435\u043d\u043e \u0432 \u0442\u0435\u043a\u0443\u0449\u0435\u0439 \u0441\u0431\u043e\u0440\u043a\u0435 \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u044f.")
            return
        if not self._download_url:
            self._set_status("\u0421\u043d\u0430\u0447\u0430\u043b\u0430 \u043d\u0443\u0436\u043d\u043e \u043d\u0430\u0439\u0442\u0438 \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u043e\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435.")
            return
        self._start_background(self._download_worker)

    def _start_background(self, target, *args):
        if not self._worker_lock.acquire(blocking=False):
            return

        def runner():
            try:
                target(*args)
            finally:
                self._worker_lock.release()

        threading.Thread(target=runner, daemon=True).start()

    def _check_worker(self, user_initiated: bool):
        self._set_busy(True)
        self._set_progress(-1.0)
        self._set_status("\u041f\u043e\u0438\u0441\u043a \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0439...")
        try:
            metadata = self._fetch_release_metadata()
            latest_version = (metadata.get("version") or "").strip()
            if not latest_version:
                raise RuntimeError("\u0412 \u043e\u0442\u0432\u0435\u0442\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d \u043d\u043e\u043c\u0435\u0440 \u0432\u0435\u0440\u0441\u0438\u0438.")

            self._set_latest_version(latest_version)
            self._set_release_notes((metadata.get("notes") or "").strip())
            self._download_url = (metadata.get("url") or "").strip()
            self._sha256 = (metadata.get("sha256") or "").strip().lower()

            if self._is_newer_version(latest_version, APP_VERSION):
                self._set_update_available(True)
                self._set_status(f"\u041d\u0430\u0439\u0434\u0435\u043d\u043e \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435 {latest_version}. \u041d\u0430\u0447\u0438\u043d\u0430\u044e \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0443...")
                self._download_worker(already_locked=True)
                return

            self._set_update_available(False)
            self._set_release_notes("")
            self._download_url = ""
            self._sha256 = ""
            self._set_status("\u041e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0439 \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d\u043e." if user_initiated else "")
        except Exception as e:
            self._set_update_available(False)
            self._set_status(f"\u041e\u0448\u0438\u0431\u043a\u0430 \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u0438 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0439: {e}")
        finally:
            self._set_busy(False)
            if self._progress < 0:
                self._set_progress(-1.0)

    def _download_worker(self, already_locked: bool = False):
        if not already_locked:
            self._set_busy(True)
        try:
            download_url = self._download_url
            if not download_url:
                raise RuntimeError("\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043f\u043e\u043b\u0443\u0447\u0438\u0442\u044c URL \u043f\u0430\u043a\u0435\u0442\u0430 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f.")
            if not self._updater_path.exists():
                raise RuntimeError(f"\u041d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d \u0444\u0430\u0439\u043b \u043e\u0431\u043d\u043e\u0432\u043b\u044f\u0442\u043e\u0440\u0430: {self._updater_path.name}")

            temp_dir = Path(tempfile.gettempdir()) / "MachineCostPro" / "updates"
            temp_dir.mkdir(parents=True, exist_ok=True)
            zip_path = temp_dir / STABLE_ZIP_ASSET_NAME

            self._set_status("\u0417\u0430\u0433\u0440\u0443\u0437\u043a\u0430 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f...")
            self._set_progress(0.0)
            with requests.get(download_url, stream=True, timeout=60) as response:
                response.raise_for_status()
                total_size = int(response.headers.get("content-length") or 0)
                downloaded = 0
                with zip_path.open("wb") as fh:
                    for chunk in response.iter_content(chunk_size=1024 * 256):
                        if not chunk:
                            continue
                        fh.write(chunk)
                        downloaded += len(chunk)
                        if total_size > 0:
                            self._set_progress(round(downloaded * 100.0 / total_size, 1))

            if self._sha256:
                file_hash = hashlib.sha256(zip_path.read_bytes()).hexdigest().lower()
                if file_hash != self._sha256:
                    raise RuntimeError("\u041a\u043e\u043d\u0442\u0440\u043e\u043b\u044c\u043d\u0430\u044f \u0441\u0443\u043c\u043c\u0430 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f \u043d\u0435 \u0441\u043e\u0432\u043f\u0430\u043b\u0430.")

            self._set_progress(100.0)
            self._set_status("\u0417\u0430\u043f\u0443\u0441\u043a \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f...")
            app_exe_name = Path(sys.executable).name if getattr(sys, "frozen", False) else APP_EXE_NAME
            subprocess.Popen([
                str(self._updater_path),
                "--zip",
                str(zip_path),
                "--target-dir",
                str(self._install_dir),
                "--app-exe",
                app_exe_name,
                "--pid",
                str(os.getpid()),
            ])
            self._set_status("\u041e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435 \u0437\u0430\u043f\u0443\u0449\u0435\u043d\u043e. \u041f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u0435 \u0441\u0435\u0439\u0447\u0430\u0441 \u0437\u0430\u043a\u0440\u043e\u0435\u0442\u0441\u044f.")
            QMetaObject.invokeMethod(QCoreApplication.instance(), "quit", Qt.QueuedConnection)
        except Exception as e:
            self._set_status(f"\u041e\u0448\u0438\u0431\u043a\u0430 \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0438 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f: {e}")
        finally:
            self._set_busy(False)

    def _fetch_release_metadata(self):
        last_error = None
        for url in (UPDATE_MANIFEST_URL, GITHUB_LATEST_RELEASE_API):
            try:
                response = requests.get(url, timeout=20)
                response.raise_for_status()
                payload = response.json()
                if url == GITHUB_LATEST_RELEASE_API:
                    assets = payload.get("assets") or []
                    asset_url = ""
                    for asset in assets:
                        name = (asset.get("name") or "").lower()
                        if name.endswith(".zip") and "updater" not in name:
                            asset_url = asset.get("browser_download_url") or ""
                            break
                    return {
                        "version": (payload.get("tag_name") or "").lstrip("v"),
                        "url": asset_url,
                        "notes": payload.get("body") or "",
                        "sha256": "",
                    }
                return payload
            except Exception as e:
                last_error = e
        raise RuntimeError(last_error or "\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u043f\u043e\u043b\u0443\u0447\u0438\u0442\u044c \u0434\u0430\u043d\u043d\u044b\u0435 \u043e\u0431 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0438.")

    @staticmethod
    def _is_newer_version(remote: str, local: str):
        def normalize(value: str):
            parts = []
            for item in value.replace("-", ".").split("."):
                digits = "".join(ch for ch in item if ch.isdigit())
                parts.append(int(digits) if digits else 0)
            while len(parts) < 4:
                parts.append(0)
            return tuple(parts[:4])

        return normalize(remote) > normalize(local)

    def _set_busy(self, value: bool):
        if self._busy != value:
            self._busy = value
            self.busyChanged.emit()

    def _set_progress(self, value: float):
        if self._progress != value:
            self._progress = value
            self.progressChanged.emit()

    def _set_status(self, value: str):
        if self._status_message != value:
            self._status_message = value
            self.statusMessageChanged.emit()

    def _set_update_available(self, value: bool):
        if self._update_available != value:
            self._update_available = value
            self.updateAvailableChanged.emit()

    def _set_latest_version(self, value: str):
        if self._latest_version != value:
            self._latest_version = value
            self.latestVersionChanged.emit()

    def _set_release_notes(self, value: str):
        if self._release_notes != value:
            self._release_notes = value
            self.releaseNotesChanged.emit()
