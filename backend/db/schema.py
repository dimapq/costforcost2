from backend.db.connection import get_connection

def init_db():
    commands = [
        """
        CREATE TABLE IF NOT EXISTS material_inventory (
            material_id INT PRIMARY KEY REFERENCES materials(id) ON DELETE CASCADE,
            quantity DECIMAL(12, 4) NOT NULL DEFAULT 0
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS material_transactions (
            id SERIAL PRIMARY KEY,
            material_id INT REFERENCES materials(id),
            quantity_change DECIMAL(12, 4),
            transaction_type VARCHAR(20),
            reference_id INT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS finished_goods (
            id SERIAL PRIMARY KEY,
            machine_model VARCHAR(255) NOT NULL,
            machine_id INT REFERENCES machines(id),
            cost_price DECIMAL(12, 2) NOT NULL,
            produced_date DATE DEFAULT CURRENT_DATE,
            status VARCHAR(20) DEFAULT 'in_stock',
            notes TEXT
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS sales (
            id SERIAL PRIMARY KEY,
            finished_good_id INT REFERENCES finished_goods(id),
            sale_date DATE DEFAULT CURRENT_DATE,
            sale_price DECIMAL(12, 2) NOT NULL,
            profit DECIMAL(12, 2)
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS balance (
            id SERIAL PRIMARY KEY,
            date DATE DEFAULT CURRENT_DATE,
            income DECIMAL(12, 2) DEFAULT 0,
            expense DECIMAL(12, 2) DEFAULT 0,
            notes TEXT
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS inventory_adjustments (
            id SERIAL PRIMARY KEY,
            material_id INT REFERENCES materials(id),
            old_quantity DECIMAL(12, 4),
            new_quantity DECIMAL(12, 4),
            difference DECIMAL(12, 4),
            reason TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS employees (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            hourly_rate DECIMAL(10, 2),
            position VARCHAR(100),
            active BOOLEAN DEFAULT TRUE
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS work_types (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL UNIQUE,
            description TEXT
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS work_logs (
            id SERIAL PRIMARY KEY,
            employee_id INT REFERENCES employees(id),
            work_type_id INT REFERENCES work_types(id),
            machine_id INT REFERENCES machines(id) NULL,
            date DATE DEFAULT CURRENT_DATE,
            hours DECIMAL(10, 2) NOT NULL,
            notes TEXT
        )
        """,
        """
        CREATE TABLE IF NOT EXISTS machine_labor_costs (
            machine_id INT REFERENCES machines(id),
            work_type_id INT REFERENCES work_types(id),
            fixed_cost DECIMAL(12, 2),
            estimated_hours DECIMAL(10, 2),
            PRIMARY KEY (machine_id, work_type_id)
        )
        """,
        """
CREATE TABLE IF NOT EXISTS tools (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    inventory_number VARCHAR(50),          -- инвентарный номер
    purchase_date DATE,
    purchase_cost DECIMAL(12, 2) NOT NULL, -- стоимость покупки
    useful_life_months INT,                 -- срок полезного использования (месяцев)
    monthly_depreciation DECIMAL(12, 2),    -- амортизация в месяц (расчётная)
    residual_value DECIMAL(12, 2),          -- остаточная стоимость
    status VARCHAR(20) DEFAULT 'active',    -- active, written_off
    notes TEXT
);
""","""
-- Начисление амортизации (журнал)
CREATE TABLE IF NOT EXISTS tool_depreciation (
    id SERIAL PRIMARY KEY,
    tool_id INT REFERENCES tools(id),
    depreciation_date DATE DEFAULT CURRENT_DATE,
    amount DECIMAL(12, 2) NOT NULL,        -- сумма амортизации
    finished_good_id INT REFERENCES finished_goods(id) NULL, -- если списано на конкретный станок
    notes TEXT
);
""","""
-- Связь инструментов с моделями станков (для планирования списания)
CREATE TABLE IF NOT EXISTS machine_tools (
    machine_id INT REFERENCES machines(id),
    tool_id INT REFERENCES tools(id),
    usage_per_unit DECIMAL(10, 4),          -- доля использования инструмента на один станок (например, 0.01 = 1% стоимости)
    PRIMARY KEY (machine_id, tool_id)
);""","""
-- Добавляем инвентарный номер для готового станка
ALTER TABLE finished_goods ADD COLUMN IF NOT EXISTS inventory_number VARCHAR(50);
""","""
-- Добавляем статус производства (in_progress, completed, sold)
-- Если поле status уже есть, можно расширить его использование
ALTER TABLE finished_goods ADD COLUMN IF NOT EXISTS production_status VARCHAR(20) DEFAULT 'in_progress';
""","""
-- Добавляем информацию о покупателе (можно также брать из sales, но для удобства хранения)
ALTER TABLE finished_goods ADD COLUMN IF NOT EXISTS buyer VARCHAR(255);
ALTER TABLE finished_goods ADD COLUMN IF NOT EXISTS sale_date DATE;""",
    ]
    with get_connection() as conn:
        with conn.cursor() as cur:
            for cmd in commands:
                cur.execute(cmd)
        conn.commit()
    print("База данных инициализирована.")

def sync_inventory_from_purchases():
    """Однократная синхронизация остатков с таблицей purchases."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("TRUNCATE material_inventory")
            cur.execute("""
                INSERT INTO material_inventory (material_id, quantity)
                SELECT material_id, COALESCE(SUM(quantity), 0)
                FROM purchases
                GROUP BY material_id
            """)
            conn.commit()
    print("Остатки синхронизированы с закупками.")

