import os
import sys
from pathlib import Path

import PySide6
from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType

from frontend.controllers.backend_controller import BackendController
from frontend.controllers.table_models import (
    EmployeeTableModel,
    FinishedGoodsModel,
    InProgressModel,
    MachineListModel,
    MachineSpecModel,
    MaterialTableModel,
    ToolsTableModel,
)
from frontend.update_manager import UpdateManager
from version import APP_NAME, APP_VERSION_LABEL, APP_EXE_NAME, UPDATER_EXE_NAME


pyside6_dir = Path(PySide6.__file__).parent
os.environ["QT_PLUGIN_PATH"] = str(pyside6_dir / "plugins")
os.environ["QML_IMPORT_PATH"] = str(pyside6_dir / "qml")
os.environ["QML2_IMPORT_PATH"] = str(pyside6_dir / "qml")
if sys.platform == "win32":
    try:
        os.add_dll_directory(str(pyside6_dir))
    except AttributeError:
        pass


def resolve_paths():
    if getattr(sys, "frozen", False):
        base_path = Path(sys._MEIPASS)
        install_dir = Path(sys.executable).resolve().parent
        qml_dir = base_path / "frontend" / "qml"
        root_dir = base_path
        updates_enabled = True
    else:
        base_path = Path(__file__).resolve().parent
        install_dir = base_path.parent
        qml_dir = base_path / "qml"
        root_dir = base_path.parent
        updates_enabled = False
    return base_path, root_dir, install_dir, qml_dir, updates_enabled


def pick_existing_path(*candidates: Path):
    for candidate in candidates:
        if candidate and candidate.exists():
            return candidate
    return candidates[-1] if candidates else Path()


def resolve_logo_paths(base_path: Path, root_dir: Path):
    app_logo = pick_existing_path(
        base_path / "newlogo.png",
        base_path / "logo.png",
        root_dir / "newlogo.png",
        root_dir / "logo.png",
    )
    update_logo = pick_existing_path(
        base_path / "prelogo" / "update_logo.png",
        base_path / "prelogo" / "logo.png",
        base_path / "prelogo.png",
        root_dir / "prelogo" / "update_logo.png",
        root_dir / "prelogo" / "logo.png",
        root_dir / "prelogo.png",
        app_logo,
    )
    return app_logo, update_logo


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)

    base_path, root_dir, install_dir, qml_dir, updates_enabled = resolve_paths()
    app_logo_path, update_logo_path = resolve_logo_paths(base_path, root_dir)

    if app_logo_path.exists():
        app.setWindowIcon(QIcon(str(app_logo_path)))

    qmlRegisterType(MaterialTableModel, "TableModels", 1, 0, "MaterialTableModel")
    qmlRegisterType(ToolsTableModel, "TableModels", 1, 0, "ToolsTableModel")
    qmlRegisterType(EmployeeTableModel, "TableModels", 1, 0, "EmployeeTableModel")
    qmlRegisterType(MachineListModel, "TableModels", 1, 0, "MachineListModel")
    qmlRegisterType(MachineSpecModel, "TableModels", 1, 0, "MachineSpecModel")
    qmlRegisterType(FinishedGoodsModel, "TableModels", 1, 0, "FinishedGoodsModel")
    qmlRegisterType(InProgressModel, "TableModels", 1, 0, "InProgressModel")

    engine = QQmlApplicationEngine()

    backend = BackendController()
    update_manager = UpdateManager(
        install_dir=install_dir,
        updater_path=install_dir / UPDATER_EXE_NAME,
        enabled=updates_enabled,
    )

    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("updateManager", update_manager)
    engine.rootContext().setContextProperty("appLogoPath", QUrl.fromLocalFile(str(app_logo_path)).toString())
    engine.rootContext().setContextProperty("updateLogoPath", QUrl.fromLocalFile(str(update_logo_path)).toString())
    engine.rootContext().setContextProperty("appTitle", f"{APP_NAME} {APP_VERSION_LABEL}")
    engine.rootContext().setContextProperty("appVersionLabel", APP_VERSION_LABEL)
    engine.rootContext().setContextProperty("appExecutableName", APP_EXE_NAME)

    qml_file = qml_dir / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())

