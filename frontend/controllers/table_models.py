# frontend/controllers/table_models.py
from PySide6.QtCore import QAbstractListModel, QAbstractTableModel, Qt, QModelIndex, Slot
from backend.db.connection import get_connection


class MaterialTableModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._data = []
        self._headers = ["ID", "Название", "Остаток", "Цена за ед.", "Сумма"]

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
                return f"{row['quantity']:.2f}"
            elif col == 3:
                return f"{row['price']:.2f}" if row['price'] else "—"
            elif col == 4:
                return f"{row['total']:.2f}" if row['total'] else "—"
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
                    WITH latest_prices AS (
                        SELECT DISTINCT ON (material_id) material_id, price_per_unit
                        FROM purchases WHERE price_per_unit IS NOT NULL
                        ORDER BY material_id, purchase_date DESC
                    )
                    SELECT 
                        m.id,
                        m.name,
                        COALESCE(inv.quantity, 0) AS qty,
                        lp.price_per_unit,
                        COALESCE(lp.price_per_unit * inv.quantity, 0) AS total
                    FROM materials m
                    LEFT JOIN material_inventory inv ON m.id = inv.material_id
                    LEFT JOIN latest_prices lp ON m.id = lp.material_id
                    WHERE COALESCE(inv.quantity, 0) > 0
                    ORDER BY m.name
                """)
                rows = cur.fetchall()
                self._data = [
                    {
                        'id': r[0],
                        'name': r[1],
                        'quantity': r[2],
                        'price': r[3],
                        'total': r[4]
                    }
                    for r in rows
                ]
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
                cur.execute("SELECT id, model, total_cost FROM machines ORDER BY model")
                rows = cur.fetchall()
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
                cur.execute("""
                    WITH latest_prices AS (
                        SELECT DISTINCT ON (material_id) material_id, price_per_unit
                        FROM purchases WHERE price_per_unit IS NOT NULL
                        ORDER BY material_id, purchase_date DESC
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
        self._headers = ["ID", "Модель", "Дата начала", "Примечание"]

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
            if col == 2: return row['date']
            if col == 3: return row['notes']
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
                cur.execute("""
                    SELECT id, machine_model, produced_date, notes
                    FROM finished_goods
                    WHERE status = 'in_progress'
                    ORDER BY produced_date DESC
                """)
                rows = cur.fetchall()
                self._data = [
                    {'id': r[0], 'model': r[1], 'date': str(r[2]), 'notes': r[3] or ''}
                    for r in rows
                ]
        self.endResetModel()

class FinishedGoodsModel(QAbstractTableModel):
    def __init__(self):
        super().__init__()
        self._all_data = []   # полный список (для фильтрации)
        self._data = []       # отображаемый список
        self._filter = ""
        self._headers = ["ID", "Модель", "Инв.№", "Произведён", "Покупатель", "Продан", "Себестоимость", "Статус"]

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
            if col == 6: return f"{row['cost']:.2f}" if row['cost'] else "0.00"
            if col == 7: return row['status']
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
                        fg.status,
                        fg.inventory_number, 
                        fg.buyer, 
                        fg.sale_date,
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
                        'status': r[4],
                        'inv_num': r[5],
                        'buyer': r[6],
                        'sale_date': str(r[7]) if r[7] else None,
                        'materials_cost': float(r[8]) if r[8] else 0.0,
                        'labor_cost': float(r[9]) if r[9] else 0.0
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
