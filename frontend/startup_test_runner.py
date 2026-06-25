import subprocess
from pathlib import Path

from PySide6.QtCore import QObject, QThread, Signal, Slot


class StartupTestWorker(QObject):
    testCountChanged = Signal(int)
    testStatusChanged = Signal(int, str, str)
    allTestsPassed = Signal()
    testsFailed = Signal(str)
    finished = Signal()

    def __init__(self, tests):
        super().__init__()
        self._tests = tests

    @Slot()
    def run(self):
        self.testCountChanged.emit(len(self._tests))
        failed_messages = []

        for index, test in enumerate(self._tests):
            name = test["name"]
            self.testStatusChanged.emit(index, "running", name)
            try:
                test["fn"]()
            except Exception as exc:
                message = f"{name}: {exc}"
                failed_messages.append(message)
                self.testStatusChanged.emit(index, "failed", name)
            else:
                self.testStatusChanged.emit(index, "passed", name)

        if failed_messages:
            self.testsFailed.emit("Startup self-check failed:\n" + "\n".join(failed_messages))
        else:
            self.allTestsPassed.emit()

        self.finished.emit()


class StartupTestRunner(QObject):
    testCountChanged = Signal(int)
    testStatusChanged = Signal(int, str, str)
    allTestsPassed = Signal()
    testsFailed = Signal(str)

    def __init__(self, root_dir: Path, qml_dir: Path, install_dir: Path):
        super().__init__()
        self.root_dir = Path(root_dir)
        self.qml_dir = Path(qml_dir)
        self.install_dir = Path(install_dir)
        self._thread = None
        self._worker = None
        self._tests = self._build_tests()

    @Slot(result="QVariantList")
    def testNames(self):
        return [test["name"] for test in self._tests]

    @Slot()
    def runTests(self):
        if self._thread and self._thread.isRunning():
            return

        self._thread = QThread()
        self._worker = StartupTestWorker(self._tests)
        self._worker.moveToThread(self._thread)

        self._thread.started.connect(self._worker.run)
        self._worker.testCountChanged.connect(self.testCountChanged)
        self._worker.testStatusChanged.connect(self.testStatusChanged)
        self._worker.allTestsPassed.connect(self.allTestsPassed)
        self._worker.testsFailed.connect(self.testsFailed)
        self._worker.finished.connect(self._thread.quit)
        self._worker.finished.connect(self._worker.deleteLater)
        self._thread.finished.connect(self._thread.deleteLater)
        self._thread.finished.connect(self._clear_thread_refs)
        self._thread.start()

    @Slot()
    def launchPreviousRelease(self):
        previous_dir = self.install_dir / "previous_release"
        candidates = [
            previous_dir / "MachineCostPro.exe",
            previous_dir / "MachineCostPro" / "MachineCostPro.exe",
        ]
        for candidate in candidates:
            if candidate.exists():
                subprocess.Popen([str(candidate)], cwd=str(candidate.parent))
                return
        self.testsFailed.emit(f"Previous release was not found in {previous_dir}")

    @Slot()
    def _clear_thread_refs(self):
        self._thread = None
        self._worker = None

    def _build_tests(self):
        return [
            {"name": "Database connection", "fn": self._test_database_opens},
            {"name": "Required tables", "fn": self._test_required_tables_exist},
            {"name": "Material model query", "fn": self._test_material_model_loads},
            {"name": "Machine model query", "fn": self._test_machine_model_loads},
            {"name": "Machine cost query", "fn": self._test_machine_cost_query_loads},
            {"name": "Finance model query", "fn": self._test_finance_model_loads},
            {"name": "QML files", "fn": self._test_qml_files_exist},
        ]

    def _test_database_opens(self):
        from backend.db.connection import get_connection

        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                if cur.fetchone()[0] != 1:
                    raise RuntimeError("Database did not return SELECT 1")

    def _test_required_tables_exist(self):
        required_tables = {
            "materials",
            "purchases",
            "material_inventory",
            "machines",
            "machine_materials",
            "finished_goods",
            "balance",
        }
        existing_tables = self._fetch_existing_tables(required_tables)
        missing = sorted(required_tables - existing_tables)
        if missing:
            raise RuntimeError("Missing tables: " + ", ".join(missing))

    def _test_material_model_loads(self):
        self._run_count_query(
            """
            SELECT COUNT(*)
            FROM materials m
            LEFT JOIN material_inventory inv ON inv.material_id = m.id
            """
        )

    def _test_machine_model_loads(self):
        self._run_count_query("SELECT COUNT(*) FROM machines")
        self._run_count_query(
            """
            SELECT COUNT(*)
            FROM machine_materials mm
            JOIN materials m ON m.id = mm.material_id
            JOIN machines mach ON mach.id = mm.machine_id
            """
        )

    def _test_machine_cost_query_loads(self):
        self._run_count_query(
            """
            WITH latest_prices AS (
                SELECT DISTINCT ON (material_id)
                    material_id,
                    COALESCE(price_per_unit, 1) AS price_per_unit
                FROM purchases
                ORDER BY material_id, purchase_date DESC NULLS LAST, id DESC
            )
            SELECT COUNT(*)
            FROM machines mach
            LEFT JOIN machine_materials mm ON mm.machine_id = mach.id
            LEFT JOIN latest_prices lp ON lp.material_id = mm.material_id
            """
        )

    def _test_finance_model_loads(self):
        self._run_count_query("SELECT COUNT(*) FROM balance")
        self._run_count_query("SELECT COUNT(*) FROM finished_goods")

    def _test_qml_files_exist(self):
        required_files = [
            "Main.qml",
            "OperationsPage.qml",
            "InventoryPage.qml",
            "EmployeesPage.qml",
            "MachinesPage.qml",
            "FinancePage.qml",
        ]
        missing = [name for name in required_files if not (self.qml_dir / name).exists()]
        if missing:
            raise RuntimeError("Missing QML files: " + ", ".join(missing))

    def _fetch_existing_tables(self, table_names):
        from backend.db.connection import get_connection

        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT table_name
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                      AND table_name = ANY(%s)
                    """,
                    (list(table_names),),
                )
                return {row[0] for row in cur.fetchall()}

    def _run_count_query(self, query):
        from backend.db.connection import get_connection

        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query)
                cur.fetchone()
