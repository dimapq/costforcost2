# frontend/controllers/table_models.py
from PySide6.QtCore import QAbstractListModel, QAbstractTableModel, Qt, QModelIndex, Slot
from backend.db.connection import get_connection
from backend.models.machine import fetch_machines_with_calculated_costs, normalize_null_purchase_prices


class MaterialTableModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._data = []
        self._category_filter = ""
        self._machine_filter = ""
        self._sort_column = 1
        self._sort_ascending = True
        self._extra_headers = ["Используется в", "Откуда взят", "Примечание", "Дата обновления"]
        self._headers = ["ID", "Название", "Категория", "Остаток", "Цена за ед.", "Сумма"]

    def rowCount(self, parent=QModelIndex()):
        return len(self._data)

    def columnCount(self, parent=QModelIndex()):
        return len(self._headers) + len(self._extra_headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        if role == Qt.DisplayRole:
            row = self._data[index.row()]
            col = index.column()
            if col == 0:
                return str(row['id'])
            elif col == 1:
                return row['name']
            elif col == 2:
                return row.get('category') or "Материалы"
            elif col == 3:
                return f"{row['quantity']:.2f}"
            elif col == 4:
                return f"{row['price']:.2f}" if row['price'] else "—"
            elif col == 5:
                return f"{row['total']:.2f}" if row['total'] else "—"
            elif col == 6:
                return row.get('used_in') or "-"
            elif col == 7:
                return row.get('source') or "-"
            elif col == 8:
                return row.get('notes') or "-"
            elif col == 9:
                return row.get('updated_date') or "-"
        return None

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            if section == 6:
                return self._extra_headers[0]
            if section == 7:
                return self._extra_headers[1]
            if section == 8:
                return self._extra_headers[2]
            if section == 9:
                return self._extra_headers[3]
            return self._headers[section]
        return None

    @Slot(int, result="QVariantMap")
    def get(self, row):
        if 0 <= row < len(self._data):
            return self._data[row]
        return {}

    @Slot(int, result=str)
    def getHeader(self, section):
        value = self.headerData(section, Qt.Horizontal, Qt.DisplayRole)
        return "" if value is None else str(value)

    @Slot(result=int)
    def getSortColumn(self):
        return self._sort_column

    @Slot(result=bool)
    def getSortAscending(self):
        return self._sort_ascending

    def _sort_value(self, row, column):
        if column == 0:
            return int(row.get('id') or 0)
        if column == 1:
            return (row.get('name') or "").lower()
        if column == 2:
            return (row.get('category') or "").lower()
        if column == 3:
            return float(row.get('quantity') or 0)
        if column == 4:
            return float(row.get('price') or 0)
        if column == 5:
            return float(row.get('total') or 0)
        if column == 6:
            return (row.get('used_in') or "").lower()
        if column == 7:
            return (row.get('source') or "").lower()
        if column == 8:
            return (row.get('notes') or "").lower()
        if column == 9:
            return row.get('updated_date') or ""
        return ""

    def _apply_sort(self):
        self._data.sort(
            key=lambda row: self._sort_value(row, self._sort_column),
            reverse=not self._sort_ascending
        )

    @Slot(int)
    def sortByColumn(self, column):
        if column < 0 or column >= self.columnCount():
            return
        self.beginResetModel()
        if self._sort_column == column:
            self._sort_ascending = not self._sort_ascending
        else:
            self._sort_column = column
            self._sort_ascending = True
        self._apply_sort()
        self.endResetModel()

    def _stock_state(self, quantity, enough_threshold):
        qty = float(quantity or 0)
        enough = float(enough_threshold or 3)
        if enough <= 0:
            enough = 3
        if qty <= 0:
            return "empty"
        if qty < enough:
            return "low"
        return "enough"

    @Slot(str)
    def setCategoryFilter(self, category):
        normalized = (category or "").strip()
        self._category_filter = "" if normalized in ("", "Все") else normalized
        self.refresh()

    @Slot(str)
    def setMachineFilter(self, machine_model):
        normalized = (machine_model or "").strip()
        self._machine_filter = "" if normalized in ("", "Все", "Все станки") else normalized
        self.refresh()

    @Slot()
    def refresh(self):
        self.beginResetModel()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS low_stock_threshold DECIMAL(12, 3) DEFAULT 1")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS enough_stock_threshold DECIMAL(12, 3) DEFAULT 3")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'Материалы'")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS is_plate BOOLEAN DEFAULT FALSE")
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS composite_material_recipes (
                        id SERIAL PRIMARY KEY,
                        output_material_id INT NOT NULL UNIQUE REFERENCES materials(id) ON DELETE CASCADE,
                        output_quantity DECIMAL(12, 4) NOT NULL DEFAULT 1,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS material_conversions (
                        id SERIAL PRIMARY KEY,
                        source_material_id INT REFERENCES materials(id),
                        source_purchase_id INT REFERENCES purchases(id),
                        target_material_id INT REFERENCES materials(id),
                        source_quantity DECIMAL(12, 4) NOT NULL DEFAULT 0,
                        target_quantity DECIMAL(12, 4) NOT NULL DEFAULT 0,
                        total_cost DECIMAL(12, 2) NOT NULL DEFAULT 0,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cur.execute("""
                    WITH latest_prices AS (
                        SELECT DISTINCT ON (material_id) material_id, price_per_unit
                        FROM purchases WHERE price_per_unit IS NOT NULL
                        ORDER BY material_id, purchase_date DESC
                    ),
                    used_in AS (
                        SELECT
                            mm.material_id,
                            STRING_AGG(DISTINCT mach.model, ', ' ORDER BY mach.model) AS used_in
                        FROM machine_materials mm
                        JOIN machines mach ON mach.id = mm.machine_id
                        GROUP BY mm.material_id
                    ),
                    composite_outputs AS (
                        SELECT output_material_id AS material_id
                        FROM composite_material_recipes
                    ),
                    converted_materials AS (
                        SELECT DISTINCT target_material_id AS material_id
                        FROM material_conversions
                    )
                    SELECT 
                        m.id,
                        m.name,
                        COALESCE(
                            NULLIF(m.category, ''),
                            CASE
                                WHEN co.material_id IS NOT NULL THEN 'Составные'
                                WHEN COALESCE(m.is_plate, FALSE) = TRUE OR cm.material_id IS NOT NULL THEN 'Раскрой плит'
                                ELSE 'Материалы'
                            END
                        ) AS category,
                        m.unit,
                        COALESCE(inv.quantity, 0) AS qty,
                        lp.price_per_unit,
                        COALESCE(lp.price_per_unit * inv.quantity, 0) AS total,
                        COALESCE(ui.used_in, ''),
                        m.source,
                        m.notes,
                        m.updated_date,
                        COALESCE(m.low_stock_threshold, 1),
                        COALESCE(m.enough_stock_threshold, 3)
                    FROM materials m
                    LEFT JOIN material_inventory inv ON m.id = inv.material_id
                    LEFT JOIN latest_prices lp ON m.id = lp.material_id
                    LEFT JOIN used_in ui ON m.id = ui.material_id
                    LEFT JOIN composite_outputs co ON co.material_id = m.id
                    LEFT JOIN converted_materials cm ON cm.material_id = m.id
                    ORDER BY m.name
                """)
                rows = cur.fetchall()
                data = [
                    {
                        'id': r[0],
                        'name': r[1],
                        'category': r[2] or 'Материалы',
                        'unit': r[3],
                        'quantity': r[4],
                        'price': r[5],
                        'total': r[6],
                        'used_in': r[7] or '',
                        'source': r[8],
                        'notes': r[9],
                        'updated_date': str(r[10]) if r[10] else '',
                        'low_stock_threshold': float(r[11] or 1),
                        'enough_stock_threshold': float(r[12] or 3),
                        'stock_state': self._stock_state(r[4], r[12])
                    }
                    for r in rows
                ]
                if self._category_filter:
                    data = [row for row in data if (row.get('category') or '') == self._category_filter]
                if self._machine_filter:
                    data = [
                        row for row in data
                        if self._machine_filter in [item.strip() for item in (row.get('used_in') or '').split(',') if item.strip()]
                    ]
                self._data = data
                self._apply_sort()
        self.endResetModel()

class ToolsTableModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._data = []
        self._headers = ["ID", "Название", "Инв.№", "Остаточная стоимость", "Статус"]

    def rowCount(self, parent=QModelIndex()):
        return len(self._data)

    def columnCount(self, parent=QModelIndex()):
        return len(self._headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        if role == Qt.DisplayRole:
            row = self._data[index.row()]
            col = index.column()
            if col == 0:
                return str(row['id'])
            elif col == 1:
                return row['name']
            elif col == 2:
                return row['inv_num'] or "—"
            elif col == 3:
                return f"{row['residual']:.2f}"
            elif col == 4:
                return row['status']
        return None

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    @Slot()
    def refresh(self):
        self.beginResetModel()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, name, inventory_number, residual_value, status
                    FROM tools
                    WHERE status = 'active'
                    ORDER BY name
                """)
                rows = cur.fetchall()
                self._data = [
                    {
                        'id': r[0],
                        'name': r[1],
                        'inv_num': r[2],
                        'residual': r[3],
                        'status': r[4]
                    }
                    for r in rows
                ]
        self.endResetModel()

class EmployeeTableModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._data = []
        self._headers = ["ID", "Имя", "Ставка", "Должность", "Активен"]

    def rowCount(self, parent=QModelIndex()):
        return len(self._data)

    def columnCount(self, parent=QModelIndex()):
        return len(self._headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        row = self._data[index.row()]
        col = index.column()
        if role == Qt.DisplayRole:
            if col == 0: return str(row['id'])
            if col == 1: return row['name']
            if col == 2: return f"{row['rate']:.2f}"
            if col == 3: return row['position'] or ""
            if col == 4: return "Да" if row['active'] else "Нет"
        return None

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    @Slot(int, result="QVariantMap")
    def get(self, row):
        if 0 <= row < len(self._data):
            return self._data[row]
        return {}

    @Slot()
    def refresh(self):
        self.beginResetModel()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, name, hourly_rate, position, active FROM employees ORDER BY name")
                rows = cur.fetchall()
                self._data = [
                    {
                        'id': r[0],
                        'name': r[1],
                        'rate': float(r[2]) if r[2] else 0.0,
                        'position': r[3],
                        'active': r[4]
                    }
                    for r in rows
                ]
        self.endResetModel()

class MachineListModel(QAbstractListModel):
    IdRole = Qt.UserRole + 1
    ModelRole = Qt.UserRole + 2
    CostRole = Qt.UserRole + 3

    def __init__(self):
        super().__init__()
        self._all_data = []   # полный список (для фильтрации)
        self._data = []       # отображаемый список
        self._filter = ""

    def rowCount(self, parent=QModelIndex()):
        return len(self._data)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid() or index.row() >= len(self._data):
            return None
        item = self._data[index.row()]
        if role == MachineListModel.IdRole:
            return item['id']
        if role == MachineListModel.ModelRole:
            return item['model']
        if role == MachineListModel.CostRole:
            return item['cost']
        if role == Qt.DisplayRole:
            return item
        return None

    def roleNames(self):
        roles = super().roleNames()
        roles[MachineListModel.IdRole] = b"id"
        roles[MachineListModel.ModelRole] = b"model"
        roles[MachineListModel.CostRole] = b"cost"
        return roles

    @Slot(int, result="QVariantMap")
    def get(self, row):
        if 0 <= row < len(self._data):
            return self._data[row]
        return {}

    @Slot(str)
    def setFilter(self, text):
        """Фильтрует список моделей по подстроке в названии (без запроса к БД)."""
        self._filter = text.strip().lower()
        self.beginResetModel()
        if self._filter:
            self._data = [
                item for item in self._all_data
                if self._filter in item['model'].lower()
            ]
        else:
            self._data = list(self._all_data)
        self.endResetModel()

    @Slot()
    def refresh(self):
        self.beginResetModel()
        with get_connection() as conn:
            with conn.cursor() as cur:
                rows = fetch_machines_with_calculated_costs(cur)
                rows.sort(key=lambda item: (item[1] or "").lower())
                self._all_data = [
                    {'id': r[0], 'model': r[1] or 'Без названия', 'cost': float(r[2]) if r[2] else 0.0}
                    for r in rows
                ]
        # Переприменяем текущий фильтр после обновления данных
        if self._filter:
            self._data = [
                item for item in self._all_data
                if self._filter in item['model'].lower()
            ]
        else:
            self._data = list(self._all_data)
        self.endResetModel()

class MachineSpecModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._data = []
        self._headers = ["ID", "Материал", "Кол-во", "Цена/ед", "Сумма"]
        self._machine_id = None

    @Slot(int)
    def setMachineId(self, mid):
        self._machine_id = mid

    def rowCount(self, parent=QModelIndex()):
        return len(self._data)
    
    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        row = self._data[index.row()]
        col = index.column()
        if role == Qt.DisplayRole:
            if col == 0: return str(row['material_id'])
            if col == 1: return row['name']
            if col == 2: return f"{row['quantity']:.2f}"
            if col == 3: return f"{row['price']:.2f}" if row['price'] else "—"
            if col == 4:
                # Колонка "Сумма" = количество × цена
                if row['price']:
                    total = row['quantity'] * row['price']
                    return f"{total:.2f}"
                return "—"
        return None

    def columnCount(self, parent=QModelIndex()):
        return len(self._headers)

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    @Slot(int, result=int)
    def getMaterialId(self, row):
        if 0 <= row < len(self._data):
            return self._data[row]['material_id']
        return -1

    @Slot(int, result=float)
    def getQuantity(self, row):
        if 0 <= row < len(self._data):
            return self._data[row]['quantity']
        return 0.0

    @Slot(int, result=float)
    def getPrice(self, row):
        if 0 <= row < len(self._data):
            price = self._data[row]['price']
            return float(price) if price is not None else 0.0
        return 0.0

    @Slot()
    def refresh(self):
        if not self._machine_id:
            return
        self.beginResetModel()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT material_id FROM machine_materials WHERE machine_id = %s", (self._machine_id,))
                material_ids = [row[0] for row in cur.fetchall()]
                normalize_null_purchase_prices(cur, material_ids)
                cur.execute("""
                    WITH latest_prices AS (
                        SELECT DISTINCT ON (material_id) material_id, price_per_unit
                        FROM purchases WHERE price_per_unit IS NOT NULL
                        ORDER BY material_id, purchase_date DESC NULLS LAST, id DESC
                    )
                    SELECT mm.material_id, m.name, mm.quantity, lp.price_per_unit
                    FROM machine_materials mm
                    JOIN materials m ON mm.material_id = m.id
                    LEFT JOIN latest_prices lp ON mm.material_id = lp.material_id
                    WHERE mm.machine_id = %s
                    ORDER BY m.name
                """, (self._machine_id,))
                rows = cur.fetchall()
                self._data = [
                    {
                        'material_id': r[0],
                        'name': r[1],
                        'quantity': float(r[2]),
                        'price': float(r[3]) if r[3] else None
                    }
                    for r in rows
                ]
        self.endResetModel()

class InProgressModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._data = []
        self._headers = ["ID", "Model", "Machine ID", "Start date", "Hours", "Indirect", "Total", "Notes"]

    def rowCount(self, parent=QModelIndex()):
        return len(self._data)

    def columnCount(self, parent=QModelIndex()):
        return len(self._headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        row = self._data[index.row()]
        col = index.column()
        if role == Qt.DisplayRole:
            if col == 0: return str(row['id'])
            if col == 1: return row['model']
            if col == 2: return row['inventory_number'] or '-'
            if col == 3: return row['date']
            if col == 4: return f"{row['hours']:.2f}"
            if col == 5: return f"{row['indirect_cost']:.2f}"
            if col == 6: return f"{row['total_cost']:.2f}"
            if col == 7: return row['notes']
        return None

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    @Slot(int, result="QVariantMap")
    def get(self, row):
        if 0 <= row < len(self._data):
            return self._data[row]
        return {}

    @Slot()
    def refresh(self):
        self.beginResetModel()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS inventory_number VARCHAR(50)")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS start_date DATE")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS indirect_cost DECIMAL(12, 2) DEFAULT 0")
                cur.execute("""
                    SELECT
                        fg.id,
                        fg.machine_model,
                        fg.inventory_number,
                        COALESCE(fg.start_date, fg.produced_date),
                        COALESCE(fg.notes, ''),
                        COALESCE((
                            SELECT SUM(wl.hours)
                            FROM finished_good_labor fgl
                            JOIN work_logs wl ON wl.id = fgl.work_log_id
                            WHERE fgl.finished_good_id = fg.id
                        ), 0) AS total_hours,
                        COALESCE(fg.indirect_cost, 0) AS indirect_cost,
                        COALESCE(fg.cost_price, 0) AS total_cost
                    FROM finished_goods fg
                    WHERE fg.status = 'in_progress'
                    ORDER BY COALESCE(fg.start_date, fg.produced_date) DESC, fg.id DESC
                """)
                rows = cur.fetchall()
                self._data = [
                    {
                        'id': r[0],
                        'model': r[1],
                        'inventory_number': r[2] or '',
                        'date': str(r[3]) if r[3] else '',
                        'notes': r[4] or '',
                        'hours': float(r[5]) if r[5] else 0.0,
                        'indirect_cost': float(r[6]) if r[6] else 0.0,
                        'total_cost': float(r[7]) if r[7] else 0.0,
                    }
                    for r in rows
                ]
        self.endResetModel()

class FinishedGoodsModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._all_data = []   # полный список (для фильтрации)
        self._data = []       # отображаемый список
        self._filter = ""
        self._headers = ["ID", "Модель", "Инв.№", "Дата оконч.", "Покупатель", "Продан", "Себестоимость", "Косвенные", "Статус"]

    def rowCount(self, parent=QModelIndex()):
        return len(self._data)

    def columnCount(self, parent=QModelIndex()):
        return len(self._headers)

    def data(self, index, role=Qt.DisplayRole):
        if not index.isValid():
            return None
        row = self._data[index.row()]
        col = index.column()
        if role == Qt.DisplayRole:
            if col == 0: return str(row['id'])
            if col == 1: return row['model']
            if col == 2: return row['inv_num'] or "—"
            if col == 3: return row['produced_date']
            if col == 4: return row['buyer'] or "—"
            if col == 5: return row['sale_date'] or "—"
            if col == 6:
                cost = row.get('cost', 0.0) or 0.0
                base_cost = row.get('base_cost', cost) or 0.0
                return f"{cost:.2f} ({base_cost:.2f})"
            if col == 7: return f"{row['indirect_cost']:.2f}" if row['indirect_cost'] else "0.00"
            if col == 8: return row['status']
        return None

    def headerData(self, section, orientation, role=Qt.DisplayRole):
        if orientation == Qt.Horizontal and role == Qt.DisplayRole:
            return self._headers[section]
        return None

    @Slot(int, result="QVariantMap")
    def get(self, row):
        if 0 <= row < len(self._data):
            return self._data[row]
        return {}

    @Slot(str)
    def setFilter(self, text):
        """Фильтрует по модели, инв. номеру или покупателю (без запроса к БД)."""
        self._filter = text.strip().lower()
        self.beginResetModel()
        if self._filter:
            self._data = [
                item for item in self._all_data
                if self._filter in item['model'].lower()
                or self._filter in (item['inv_num'] or '').lower()
                or self._filter in (item['buyer'] or '').lower()
            ]
        else:
            self._data = list(self._all_data)
        self.endResetModel()

    @Slot()
    def refresh(self):
        self.beginResetModel()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS start_date DATE")
                cur.execute("""
                    WITH machine_costs AS (
                        SELECT 
                            fg.id,
                            -- Стоимость материалов
                            COALESCE(SUM(
                                mm.quantity * (
                                    SELECT price_per_unit 
                                    FROM purchases p 
                                    WHERE p.material_id = mm.material_id 
                                    AND p.price_per_unit IS NOT NULL
                                    ORDER BY p.purchase_date DESC 
                                    LIMIT 1
                                )
                            ), 0) as materials_cost,
                            -- Стоимость работы
                            COALESCE((
                                SELECT SUM(wl.hours * e.hourly_rate)
                                FROM work_logs wl
                                JOIN employees e ON wl.employee_id = e.id
                                JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                                WHERE fgl.finished_good_id = fg.id
                            ), 0) as labor_cost
                        FROM finished_goods fg
                        LEFT JOIN machine_materials mm ON fg.machine_id = mm.machine_id
                        GROUP BY fg.id
                    )
                    SELECT 
                        fg.id, 
                        fg.machine_model, 
                        fg.cost_price, 
                        fg.produced_date, 
                        fg.start_date,
                        fg.status,
                        fg.inventory_number, 
                        fg.buyer, 
                        fg.sale_date,
                        fg.indirect_cost,
                        fg.notes,
                        mc.materials_cost,
                        mc.labor_cost
                    FROM finished_goods fg
                    LEFT JOIN machine_costs mc ON fg.id = mc.id
                    WHERE fg.status = 'completed'
                    ORDER BY fg.produced_date DESC
                """)
                rows = cur.fetchall()
                self._all_data = [
                    {
                        'id': r[0],
                        'model': r[1],
                        'cost': float(r[2]) if r[2] else 0.0,
                        'produced_date': str(r[3]),
                        'start_date': str(r[4]) if r[4] else None,
                        'status': r[5],
                        'inv_num': r[6],
                        'buyer': r[7],
                        'sale_date': str(r[8]) if r[8] else None,
                        'indirect_cost': float(r[9]) if r[9] else 0.0,
                        'base_cost': float(r[2]) - float(r[9]) if r[2] is not None else 0.0,
                        'notes': r[10] or '',
                        'materials_cost': float(r[11]) if r[11] else 0.0,
                        'labor_cost': float(r[12]) if r[12] else 0.0
                    }
                    for r in rows
                ]
        # Переприменяем фильтр
        if self._filter:
            self._data = [
                item for item in self._all_data
                if self._filter in item['model'].lower()
                or self._filter in (item['inv_num'] or '').lower()
                or self._filter in (item['buyer'] or '').lower()
            ]
        else:
            self._data = list(self._all_data)
        self.endResetModel()
