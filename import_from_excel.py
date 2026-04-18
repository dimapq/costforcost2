import pandas as pd
import psycopg2
from decimal import Decimal
from datetime import datetime
import re

# ========== НАСТРОЙКИ ==========
DATABASE_URL = "postgresql://postgres:dbcost1@localhost:5432/cost?client_encoding=utf8"
EXCEL_FILE = 'шаблон базы.xlsx'

def get_connection():
    return psycopg2.connect(DATABASE_URL)

def create_tables():
    drop_commands = [
        "DROP TABLE IF EXISTS machine_materials CASCADE",
        "DROP TABLE IF EXISTS machines CASCADE",
        "DROP TABLE IF EXISTS purchases CASCADE",
        "DROP TABLE IF EXISTS materials CASCADE",
        "DROP TABLE IF EXISTS suppliers CASCADE",
        "DROP TABLE IF EXISTS material_types CASCADE",
    ]
    create_commands = [
        "CREATE TABLE material_types (id SERIAL PRIMARY KEY, name VARCHAR(100) UNIQUE NOT NULL)",
        "CREATE TABLE suppliers (id SERIAL PRIMARY KEY, name VARCHAR(255) UNIQUE NOT NULL)",
        """CREATE TABLE materials (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL UNIQUE,
            unit VARCHAR(50),
            type_id INT REFERENCES material_types(id) ON DELETE SET NULL,
            product_url TEXT,
            notes TEXT
        )""",
        """CREATE TABLE purchases (
            id SERIAL PRIMARY KEY,
            material_id INT REFERENCES materials(id) ON DELETE CASCADE,
            supplier_id INT REFERENCES suppliers(id) ON DELETE SET NULL,
            purchase_date DATE,
            price_per_unit DECIMAL(12, 2),
            quantity DECIMAL(12, 4),
            remaining_quantity DECIMAL(12, 4),
            purchased_by VARCHAR(100),
            notes TEXT
        )""",
        "CREATE TABLE machines (id SERIAL PRIMARY KEY, model VARCHAR(255) NOT NULL, total_cost DECIMAL(12, 2) DEFAULT 0)",
        """CREATE TABLE machine_materials (
            machine_id INT REFERENCES machines(id) ON DELETE CASCADE,
            material_id INT REFERENCES materials(id) ON DELETE RESTRICT,
            quantity DECIMAL(12, 4) NOT NULL,
            PRIMARY KEY (machine_id, material_id)
        )"""
    ]
    with get_connection() as conn:
        with conn.cursor() as cur:
            for cmd in drop_commands + create_commands:
                cur.execute(cmd)
        conn.commit()
    print("Таблицы пересозданы.")

def parse_excel_formula(val):
    if isinstance(val, str) and val.startswith('='):
        m = re.match(r'=(\d+\.?\d*)/(\d+\.?\d*)', val)
        if m:
            return Decimal(m.group(1)) / Decimal(m.group(2))
    return val

def safe_decimal(val, default=None):
    if pd.isna(val) or val == '' or val is None:
        return default
    try:
        return Decimal(str(val).replace(',', '.').replace(' ', ''))
    except:
        return default

def safe_date(val):
    if pd.isna(val) or val == '' or val is None:
        return None
    if isinstance(val, datetime):
        return val.date()
    try:
        return pd.to_datetime(val).date()
    except:
        return None

def import_warehouse_sheet(file_path):
    df = pd.read_excel(file_path, sheet_name='склад', header=0)
    df = df.dropna(subset=['А']).copy()
    df.columns = ['npp', 'name', 'type', 'supplier', 'purchase_date', 'price', 'buyer', 'remainder', 'note', 'empty', 'sum']
    
    with get_connection() as conn:
        with conn.cursor() as cur:
            for _, row in df.iterrows():
                if pd.notna(row['type']):
                    cur.execute("INSERT INTO material_types (name) VALUES (%s) ON CONFLICT (name) DO NOTHING", (row['type'],))
                if pd.notna(row['supplier']):
                    cur.execute("INSERT INTO suppliers (name) VALUES (%s) ON CONFLICT (name) DO NOTHING", (row['supplier'],))
            conn.commit()
            
            cur.execute("SELECT name, id FROM material_types")
            type_ids = dict(cur.fetchall())
            cur.execute("SELECT name, id FROM suppliers")
            supplier_ids = dict(cur.fetchall())
            
            for _, row in df.iterrows():
                name = str(row['name']).strip()
                if not name:
                    continue
                
                cur.execute("""
                    INSERT INTO materials (name, unit, type_id, notes)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (name) DO UPDATE SET type_id = EXCLUDED.type_id, notes = EXCLUDED.notes
                    RETURNING id
                """, (name, 'шт', type_ids.get(row['type']), row['note'] if pd.notna(row['note']) else None))
                mat_id = cur.fetchone()[0]
                
                price = parse_excel_formula(row['price'])
                price = safe_decimal(price, None)
                qty = safe_decimal(row['remainder'], Decimal('1'))
                purchase_date = safe_date(row['purchase_date'])
                supplier_id = supplier_ids.get(row['supplier'])
                
                cur.execute("""
                    INSERT INTO purchases (material_id, supplier_id, purchase_date, price_per_unit, quantity, remaining_quantity, purchased_by, notes)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (mat_id, supplier_id, purchase_date, price, qty, qty, row['buyer'] if pd.notna(row['buyer']) else None, row['note']))
            conn.commit()
    print("Лист 'склад' импортирован.")

def get_or_create_material(cur, name, type_name=None):
    cur.execute("SELECT id FROM materials WHERE name = %s", (name,))
    res = cur.fetchone()
    if res:
        return res[0]
    
    cur.execute("SELECT id FROM materials WHERE name ILIKE %s", (f"%{name}%",))
    res = cur.fetchone()
    if res:
        return res[0]
    
    type_id = None
    if type_name and isinstance(type_name, str):
        cur.execute("INSERT INTO material_types (name) VALUES (%s) ON CONFLICT (name) DO NOTHING", (type_name,))
        cur.execute("SELECT id FROM material_types WHERE name = %s", (type_name,))
        res_type = cur.fetchone()
        if res_type:
            type_id = res_type[0]
    
    cur.execute("""
        INSERT INTO materials (name, unit, type_id, notes)
        VALUES (%s, 'шт', %s, 'Добавлено автоматически из спецификации')
        RETURNING id
    """, (name, type_id))
    print(f"Создан новый материал: '{name}'")
    return cur.fetchone()[0]

def import_specification_sheet(file_path, sheet_name, model_name):
    df = pd.read_excel(file_path, sheet_name=sheet_name, header=None)
    header_idx = None
    for i, row in df.iterrows():
        if row.astype(str).str.contains('№пп|наименование|кол-во', case=False).any():
            header_idx = i
            break
        if isinstance(row.iloc[0], str) and 'Болт' in row.iloc[0]:
            header_idx = None
            break
    if header_idx is None:
        df = pd.read_excel(file_path, sheet_name=sheet_name, header=None)
        df = df.dropna(how='all').reset_index(drop=True)
        df.columns = ['наименование', 'кол-во'] + list(df.columns[2:])
        df = df[df['наименование'].apply(lambda x: isinstance(x, str) and len(x.strip()) > 0)]
    else:
        df = pd.read_excel(file_path, sheet_name=sheet_name, header=header_idx)
        df = df.dropna(subset=['наименование']).copy()
    
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO machines (model) VALUES (%s) RETURNING id", (model_name,))
            machine_id = cur.fetchone()[0]
            
            for _, row in df.iterrows():
                name = str(row['наименование']).strip()
                qty = safe_decimal(row['кол-во'], Decimal('1'))
                if qty == 0:
                    continue
                
                type_name = None
                if 'тип' in row and pd.notna(row['тип']):
                    type_name = str(row['тип']).strip()
                
                mat_id = get_or_create_material(cur, name, type_name)
                
                cur.execute("""
                    INSERT INTO machine_materials (machine_id, material_id, quantity)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (machine_id, material_id) DO UPDATE SET quantity = EXCLUDED.quantity
                """, (machine_id, mat_id, qty))
            conn.commit()
    print(f"Спецификация '{model_name}' импортирована.")

def main():
    create_tables()
    
    xl = pd.ExcelFile(EXCEL_FILE)
    sheets = xl.sheet_names
    
    if 'склад' in sheets:
        import_warehouse_sheet(EXCEL_FILE)
    else:
        print("Лист 'склад' не найден.")
    
    if 'СНО-3П' in sheets:
        import_specification_sheet(EXCEL_FILE, 'СНО-3П', 'СНО-4')
    
    if 'ШП.11-300' in sheets:
        import_specification_sheet(EXCEL_FILE, 'ШП.11-300', 'ШП.11-300')

if __name__ == "__main__":
    main()