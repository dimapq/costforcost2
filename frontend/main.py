import sys
import os
from pathlib import Path

# Исправление путей для PySide6
import PySide6
pyside6_dir = Path(PySide6.__file__).parent
os.environ["QT_PLUGIN_PATH"] = str(pyside6_dir / "plugins")
os.environ["QML_IMPORT_PATH"] = str(pyside6_dir / "qml")
os.environ["QML2_IMPORT_PATH"] = str(pyside6_dir / "qml")
if sys.platform == "win32":
    try:
        os.add_dll_directory(str(pyside6_dir))
    except AttributeError:
        pass

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtCore import QUrl

# Импорт контроллеров и моделей
from frontend.controllers.backend_controller import BackendController
from frontend.controllers.table_models import (
    MaterialTableModel,
    ToolsTableModel,
    EmployeeTableModel,
    MachineListModel,
    MachineSpecModel,
    FinishedGoodsModel,
    InProgressModel
)

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)

    # Регистрация кастомных моделей ДО создания движка QML
    qmlRegisterType(MaterialTableModel, "TableModels", 1, 0, "MaterialTableModel")
    qmlRegisterType(ToolsTableModel, "TableModels", 1, 0, "ToolsTableModel")
    qmlRegisterType(EmployeeTableModel, "TableModels", 1, 0, "EmployeeTableModel")
    qmlRegisterType(MachineListModel, "TableModels", 1, 0, "MachineListModel")
    qmlRegisterType(MachineSpecModel, "TableModels", 1, 0, "MachineSpecModel")
    qmlRegisterType(FinishedGoodsModel, "TableModels", 1, 0, "FinishedGoodsModel")
    qmlRegisterType(InProgressModel, "TableModels", 1, 0, "InProgressModel")

    engine = QQmlApplicationEngine()

    backend = BackendController()
    engine.rootContext().setContextProperty("backend", backend)

    qml_file = os.path.join(os.path.dirname(__file__), "qml", "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec())