import argparse
import os
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile
from pathlib import Path


def wait_for_process_exit(pid: int, timeout_seconds: int = 120):
    if pid <= 0:
        return
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        try:
            os.kill(pid, 0)
        except OSError:
            return
        time.sleep(0.5)


def wait_for_path_release(path: Path, timeout_seconds: int = 60):
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        if not path.exists():
            return
        try:
            with path.open("ab"):
                return
        except OSError:
            time.sleep(0.5)


def resolve_source_root(extract_dir: Path, app_exe_name: str):
    children = [child for child in extract_dir.iterdir()]
    if len(children) == 1 and children[0].is_dir():
        candidate = children[0]
        if (candidate / app_exe_name).exists() or (candidate / "frontend").exists():
            return candidate
    return extract_dir


def copy_file_with_retries(source: Path, destination: Path, attempts: int = 120, delay_seconds: float = 0.5):
    last_error = None
    for _ in range(attempts):
        try:
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.exists():
                try:
                    os.chmod(destination, 0o666)
                except OSError:
                    pass
            shutil.copy2(source, destination)
            return
        except PermissionError as e:
            last_error = e
            wait_for_path_release(destination, timeout_seconds=1)
            time.sleep(delay_seconds)
        except OSError as e:
            last_error = e
            time.sleep(delay_seconds)
    raise last_error or RuntimeError(f"Failed to copy file: {destination}")


def copy_tree(source_root: Path, target_root: Path, updater_name: str):
    for item in source_root.rglob("*"):
        relative = item.relative_to(source_root)
        destination = target_root / relative
        if item.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
            continue
        if item.name.lower() == updater_name.lower():
            continue
        copy_file_with_retries(item, destination)


def validate_zip_file(zip_path: Path):
    with zipfile.ZipFile(zip_path, "r") as archive:
        bad_entry = archive.testzip()
        if bad_entry:
            raise RuntimeError(f"Update archive is corrupted near: {bad_entry}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", required=True)
    parser.add_argument("--target-dir", required=True)
    parser.add_argument("--app-exe", required=True)
    parser.add_argument("--pid", type=int, default=0)
    args = parser.parse_args()

    zip_path = Path(args.zip)
    target_dir = Path(args.target_dir)
    target_dir.mkdir(parents=True, exist_ok=True)

    wait_for_process_exit(args.pid)
    wait_for_path_release(target_dir / args.app_exe, timeout_seconds=60)

    temp_dir = Path(tempfile.mkdtemp(prefix="machinecostpro-update-"))
    try:
        validate_zip_file(zip_path)
        with zipfile.ZipFile(zip_path, "r") as archive:
            archive.extractall(temp_dir)
        source_root = resolve_source_root(temp_dir, args.app_exe)
        copy_tree(source_root, target_dir, Path(sys.argv[0]).name)
        subprocess.Popen([str(target_dir / args.app_exe)], cwd=str(target_dir))
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
