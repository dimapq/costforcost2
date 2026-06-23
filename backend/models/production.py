# backend/models/production.py
from decimal import Decimal
from backend.db.connection import get_connection
from backend.models.machine import calculate_machine_cost_from_purchases
from backend.models.tools import apply_tool_depreciation_for_production

def _ensure_production_reservation_schema(cur):
    cur.execute("ALTER TABLE IF EXISTS purchases ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS finished_good_material_consumptions (
            id SERIAL PRIMARY KEY,
            finished_good_id INT REFERENCES finished_goods(id) ON DELETE CASCADE,
            material_id INT REFERENCES materials(id),
            purchase_id INT REFERENCES purchases(id),
            quantity DECIMAL(12, 4) NOT NULL DEFAULT 0,
            amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
            is_cash BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS finished_good_material_reservations (
            id SERIAL PRIMARY KEY,
            finished_good_id INT REFERENCES finished_goods(id) ON DELETE CASCADE,
            material_id INT REFERENCES materials(id),
            purchase_id INT REFERENCES purchases(id),
            quantity DECIMAL(12, 4) NOT NULL DEFAULT 0,
            amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
            is_cash BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

def _consume_material_fifo(cur, material_id, required_qty, finished_good_id=None):
    required_qty = Decimal(str(required_qty or 0))
    if required_qty <= 0:
        return Decimal('0.00')

    total_cost = Decimal('0.00')
    remaining = required_qty

    cur.execute("""
        SELECT id, COALESCE(remaining_quantity, 0), price_per_unit, COALESCE(is_cash, FALSE)
        FROM purchases
        WHERE material_id = %s
          AND price_per_unit IS NOT NULL
          AND COALESCE(remaining_quantity, 0) > 0
        ORDER BY purchase_date ASC NULLS LAST, id ASC
    """, (material_id,))
    lots = cur.fetchall()

    for purchase_id, lot_qty, lot_price, lot_is_cash in lots:
        if remaining <= 0:
            break
        lot_qty = Decimal(str(lot_qty or 0))
        lot_price = Decimal(str(lot_price or 0))
        if lot_qty <= 0:
            continue
        take = lot_qty if lot_qty < remaining else remaining
        total_cost += take * lot_price
        cur.execute("""
            UPDATE purchases
            SET remaining_quantity = remaining_quantity - %s
            WHERE id = %s
        """, (take, purchase_id))
        if finished_good_id is not None:
            cur.execute("""
                INSERT INTO finished_good_material_consumptions
                    (finished_good_id, material_id, purchase_id, quantity, amount, is_cash)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (finished_good_id, material_id, purchase_id, take, take * lot_price, bool(lot_is_cash)))
        remaining -= take

    if remaining > 0:
        cur.execute("""
            SELECT price_per_unit, COALESCE(is_cash, FALSE)
            FROM purchases
            WHERE material_id = %s AND price_per_unit IS NOT NULL
            ORDER BY purchase_date DESC NULLS LAST, id DESC
            LIMIT 1
        """, (material_id,))
        row = cur.fetchone()
        if row and row[0] is not None:
            fallback_price = Decimal(str(row[0]))
            total_cost += remaining * fallback_price
            if finished_good_id is not None:
                cur.execute("""
                    INSERT INTO finished_good_material_consumptions
                        (finished_good_id, material_id, purchase_id, quantity, amount, is_cash)
                    VALUES (%s, %s, NULL, %s, %s, %s)
                """, (finished_good_id, material_id, remaining, remaining * fallback_price, bool(row[1])))

    return total_cost


def check_material_availability(machine_id, quantity=1):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT m.name, mm.quantity * %s AS required, COALESCE(inv.quantity, 0) AS available
                FROM machine_materials mm
                JOIN materials m ON mm.material_id = m.id
                LEFT JOIN material_inventory inv ON mm.material_id = inv.material_id
                WHERE mm.machine_id = %s
                  AND COALESCE(inv.quantity, 0) < mm.quantity * %s
            """, (quantity, machine_id, quantity))
            shortages = cur.fetchall()
            if shortages:
                print("РќРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ РјР°С‚РµСЂРёР°Р»РѕРІ РЅР° СЃРєР»Р°РґРµ:")
                for name, req, avail in shortages:
                    print(f"  - {name}: С‚СЂРµР±СѓРµС‚СЃСЏ {req}, РІ РЅР°Р»РёС‡РёРё {avail}")
                return False
            return True


def _produce_machine_impl(machine_id, quantity=1, notes=None, ask_labor=False):
    if not check_material_availability(machine_id, quantity):
        return False, []

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS start_date DATE")
            cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS indirect_cost DECIMAL(12, 2) DEFAULT 0")
            cur.execute("SELECT model FROM machines WHERE id = %s", (machine_id,))
            model = cur.fetchone()[0]
            material_cost_per_unit = calculate_machine_cost_from_purchases(machine_id)

            labor_cost_per_unit = Decimal('0.00')
            cur.execute("""
                SELECT mlc.fixed_cost, mlc.estimated_hours, e.hourly_rate
                FROM machine_labor_costs mlc
                JOIN work_types wt ON mlc.work_type_id = wt.id
                LEFT JOIN employees e ON e.active = true
                WHERE mlc.machine_id = %s
            """, (machine_id,))
            for fixed, est_hours, rate in cur.fetchall():
                if fixed is not None:
                    labor_cost_per_unit += fixed
                elif est_hours is not None and rate is not None:
                    labor_cost_per_unit += est_hours * rate

            total_unit_cost_before_tools = material_cost_per_unit + labor_cost_per_unit

            cur.execute("""
                SELECT material_id, quantity * %s
                FROM machine_materials
                WHERE machine_id = %s
            """, (quantity, machine_id))
            materials = cur.fetchall()
            for mat_id, req_qty in materials:
                cur.execute("""
                    UPDATE material_inventory
                    SET quantity = quantity - %s
                    WHERE material_id = %s
                """, (req_qty, mat_id))
                cur.execute("""
                    INSERT INTO material_transactions (material_id, quantity_change, transaction_type)
                    VALUES (%s, %s, 'production')
                """, (mat_id, -req_qty))
                _consume_material_fifo(cur, mat_id, req_qty)

            new_fg_ids = []
            for _ in range(quantity):
                cur.execute("""
                    INSERT INTO finished_goods (machine_model, machine_id, cost_price, produced_date, status, notes)
                    VALUES (%s, %s, %s, CURRENT_DATE, 'completed', %s)
                    RETURNING id
                """, (model, machine_id, total_unit_cost_before_tools, notes))
                fg_id = cur.fetchone()[0]
                new_fg_ids.append(fg_id)

            total_tool_depr = Decimal('0.00')
            for fg_id in new_fg_ids:
                depr_amount = apply_tool_depreciation_for_production(machine_id, 1, fg_id)
                total_tool_depr += depr_amount
                if depr_amount > 0:
                    cur.execute("""
                        UPDATE finished_goods
                        SET cost_price = cost_price + %s
                        WHERE id = %s
                    """, (depr_amount, fg_id))

            conn.commit()

            final_unit_cost = total_unit_cost_before_tools + (total_tool_depr / quantity if quantity else 0)
            print(f"РџСЂРѕРёР·РІРµРґРµРЅРѕ {quantity} С€С‚. СЃС‚Р°РЅРєР° '{model}'.")
            print(f"РЎРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ РµРґРёРЅРёС†С‹: {final_unit_cost:.2f} СЂСѓР±.")
            print(f"  - РјР°С‚РµСЂРёР°Р»С‹: {material_cost_per_unit:.2f}")
            print(f"  - СЂР°Р±РѕС‚Р° (РїР»Р°РЅ): {labor_cost_per_unit:.2f}")
            print(f"  - Р°РјРѕСЂС‚РёР·Р°С†РёСЏ РёРЅСЃС‚СЂСѓРјРµРЅС‚РѕРІ: {total_tool_depr/quantity:.2f}")

            if ask_labor:
                from backend.models.labor import add_labor_to_finished_good
                for fg_id in new_fg_ids:
                    print(f"\n--- РЈС‡С‘С‚ СЂР°Р±РѕС‚С‹ РґР»СЏ СЃС‚Р°РЅРєР° ID {fg_id} ---")
                    add_labor_to_finished_good(fg_id)

            return True, new_fg_ids


def produce_machine(machine_id, quantity=1, notes=None):
    success, fg_ids = _produce_machine_impl(machine_id, quantity, notes, ask_labor=False)
    if success:
        add_labor_now = input("Р”РѕР±Р°РІРёС‚СЊ С„Р°РєС‚РёС‡РµСЃРєРёРµ С‚СЂСѓРґРѕР·Р°С‚СЂР°С‚С‹ СЃРµР№С‡Р°СЃ? (y/n): ").strip().lower()
        if add_labor_now == 'y':
            from backend.models.labor import add_labor_to_finished_good
            for fg_id in fg_ids:
                print(f"\n--- РЈС‡С‘С‚ СЂР°Р±РѕС‚С‹ РґР»СЏ СЃС‚Р°РЅРєР° ID {fg_id} ---")
                add_labor_to_finished_good(fg_id)
    return success


def produce_machine_gui(machine_id, quantity, notes):
    success, _ = _produce_machine_impl(machine_id, quantity, notes, ask_labor=False)
    return success


def sell_finished_good():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, machine_model, cost_price, produced_date
                FROM finished_goods
                WHERE status = 'completed'
                ORDER BY produced_date
            """)
            items = cur.fetchall()
            if not items:
                print("РќРµС‚ РіРѕС‚РѕРІС‹С… СЃС‚Р°РЅРєРѕРІ РЅР° СЃРєР»Р°РґРµ.")
                return
            print("\n=== Р“РѕС‚РѕРІС‹Рµ СЃС‚Р°РЅРєРё РІ РЅР°Р»РёС‡РёРё ===")
            for fg_id, model, cost, prod_date in items:
                print(f"ID: {fg_id} | РњРѕРґРµР»СЊ: {model} | РЎРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ: {cost:.2f} | РџСЂРѕРёР·РІРµРґС‘РЅ: {prod_date}")
            try:
                fg_id = int(input("Р’РІРµРґРёС‚Рµ ID РіРѕС‚РѕРІРѕРіРѕ СЃС‚Р°РЅРєР° РґР»СЏ РїСЂРѕРґР°Р¶Рё (0 РґР»СЏ РѕС‚РјРµРЅС‹): "))
                if fg_id == 0:
                    return
                sale_price = Decimal(input("Р’РІРµРґРёС‚Рµ С†РµРЅСѓ РїСЂРѕРґР°Р¶Рё: "))
                if sale_price <= 0:
                    print("Р¦РµРЅР° РґРѕР»Р¶РЅР° Р±С‹С‚СЊ РїРѕР»РѕР¶РёС‚РµР»СЊРЅРѕР№.")
                    return
                cur.execute("SELECT cost_price FROM finished_goods WHERE id = %s", (fg_id,))
                cost = cur.fetchone()[0]
                profit = sale_price - cost
                cur.execute("""
                    INSERT INTO sales (finished_good_id, sale_date, sale_price, profit)
                    VALUES (%s, CURRENT_DATE, %s, %s)
                """, (fg_id, sale_price, profit))
                cur.execute("UPDATE finished_goods SET status = 'sold' WHERE id = %s", (fg_id,))
                cur.execute("""
                    INSERT INTO balance (date, income, notes)
                    VALUES (CURRENT_DATE, %s, 'РџСЂРѕРґР°Р¶Р° СЃС‚Р°РЅРєР° ID ' || %s)
                """, (sale_price, fg_id))
                conn.commit()
                print(f"РџСЂРѕРґР°Р¶Р° РѕС„РѕСЂРјР»РµРЅР°. РџСЂРёР±С‹Р»СЊ: {profit:.2f} СЂСѓР±.")
            except ValueError:
                print("РћС€РёР±РєР° РІРІРѕРґР°.")


def sell_finished_good_gui(finished_good_id, sale_price, buyer=None):
    """GUI-РІРµСЂСЃРёСЏ РїСЂРѕРґР°Р¶Рё РіРѕС‚РѕРІРѕРіРѕ СЃС‚Р°РЅРєР° СЃ СѓРєР°Р·Р°РЅРёРµРј РїРѕРєСѓРїР°С‚РµР»СЏ."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT cost_price FROM finished_goods WHERE id = %s", (finished_good_id,))
            cost = cur.fetchone()
            if not cost:
                return False
            cost = cost[0]
            profit = sale_price - cost
            cur.execute("""
                INSERT INTO sales (finished_good_id, sale_price, profit)
                VALUES (%s, %s, %s)
            """, (finished_good_id, sale_price, profit))
            cur.execute("""
                UPDATE finished_goods
                SET status = 'sold', buyer = %s, sale_date = CURRENT_DATE
                WHERE id = %s
            """, (buyer, finished_good_id))
            cur.execute("""
                INSERT INTO balance (date, income, notes)
                VALUES (CURRENT_DATE, %s, %s)
            """, (sale_price, f"РџСЂРѕРґР°Р¶Р° СЃС‚Р°РЅРєР° ID {finished_good_id} РїРѕРєСѓРїР°С‚РµР»СЋ {buyer}"))
            conn.commit()
    return True


def plan_purchases():
    from backend.models.machine import select_machine
    machine = select_machine()
    if not machine:
        return
    machine_id, model = machine
    try:
        qty_to_produce = int(input(f"РЎРєРѕР»СЊРєРѕ СЃС‚Р°РЅРєРѕРІ '{model}' РїР»Р°РЅРёСЂСѓРµС‚СЃСЏ РїСЂРѕРёР·РІРµСЃС‚Рё? "))
        if qty_to_produce <= 0:
            print("РљРѕР»РёС‡РµСЃС‚РІРѕ РґРѕР»Р¶РЅРѕ Р±С‹С‚СЊ РїРѕР»РѕР¶РёС‚РµР»СЊРЅС‹Рј.")
            return
    except ValueError:
        print("РќРµРІРµСЂРЅРѕРµ С‡РёСЃР»Рѕ.")
        return

    print(f"\n=== РџР»Р°РЅ Р·Р°РєСѓРїРѕРє РґР»СЏ РїСЂРѕРёР·РІРѕРґСЃС‚РІР° {qty_to_produce} С€С‚. СЃС‚Р°РЅРєР° '{model}' ===\n")
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    m.name,
                    mm.quantity * %s AS total_required,
                    COALESCE(inv.quantity, 0) AS in_stock,
                    GREATEST(mm.quantity * %s - COALESCE(inv.quantity, 0), 0) AS to_order,
                    m.unit
                FROM machine_materials mm
                JOIN materials m ON mm.material_id = m.id
                LEFT JOIN material_inventory inv ON mm.material_id = inv.material_id
                WHERE mm.machine_id = %s
                ORDER BY to_order DESC, m.name
            """, (qty_to_produce, qty_to_produce, machine_id))
            rows = cur.fetchall()
            if not rows:
                print("РЎРїРµС†РёС„РёРєР°С†РёСЏ СЃС‚Р°РЅРєР° РїСѓСЃС‚Р°.")
                return
            print(f"{'РњР°С‚РµСЂРёР°Р»':<40} {'РўСЂРµР±СѓРµС‚СЃСЏ':>12} {'Р’ РЅР°Р»РёС‡РёРё':>12} {'Р—Р°РєР°Р·Р°С‚СЊ':>12} {'Р•Рґ.':<5}")
            print("-" * 85)
            for name, req, stock, order, unit in rows:
                print(f"{name:<40} {req:>12.2f} {stock:>12.2f} {order:>12.2f} {unit or 'С€С‚':<5}")
            print("-" * 85)
            cur.execute("""
                WITH latest_prices AS (
                    SELECT DISTINCT ON (material_id) material_id, price_per_unit
                    FROM purchases WHERE price_per_unit IS NOT NULL
                    ORDER BY material_id, purchase_date DESC
                )
                SELECT SUM(lp.price_per_unit * GREATEST(mm.quantity * %s - COALESCE(inv.quantity, 0), 0))
                FROM machine_materials mm
                JOIN materials m ON mm.material_id = m.id
                LEFT JOIN material_inventory inv ON mm.material_id = inv.material_id
                LEFT JOIN latest_prices lp ON mm.material_id = lp.material_id
                WHERE mm.machine_id = %s
            """, (qty_to_produce, machine_id))
            est_cost = cur.fetchone()[0] or Decimal('0.00')
            if est_cost > 0:
                print(f"РџСЂРёРјРµСЂРЅР°СЏ СЃС‚РѕРёРјРѕСЃС‚СЊ Р·Р°РєСѓРїРєРё РЅРµРґРѕСЃС‚Р°СЋС‰РёС… РјР°С‚РµСЂРёР°Р»РѕРІ: {est_cost:.2f} СЂСѓР±.")
            else:
                print("Р’СЃРµ РјР°С‚РµСЂРёР°Р»С‹ РІ РЅР°Р»РёС‡РёРё, Р·Р°РєСѓРїРєР° РЅРµ С‚СЂРµР±СѓРµС‚СЃСЏ.")


def get_in_progress_machines():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, machine_model, produced_date, notes
                FROM finished_goods
                WHERE status = 'in_progress'
                ORDER BY produced_date DESC
            """)
            rows = cur.fetchall()
            return [{'id': r[0], 'model': r[1], 'date': str(r[2]), 'notes': r[3] or ''} for r in rows]


def start_production_gui(machine_id, inventory_number, notes):
    """Creates one machine in progress with the provided inventory number."""
    inventory_number = (inventory_number or "").strip()
    if not inventory_number:
        print("Для запуска производства укажите ID станка")
        return False

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS start_date DATE")
            cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS indirect_cost DECIMAL(12, 2) DEFAULT 0")
            cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS inventory_number VARCHAR(50)")
            _ensure_production_reservation_schema(cur)
            cur.execute("SELECT model FROM machines WHERE id = %s", (machine_id,))
            row = cur.fetchone()
            if not row:
                print(f"Модель станка с ID {machine_id} не найдена")
                return False
            model = row[0]

            cur.execute(
                """
                SELECT id
                FROM finished_goods
                WHERE inventory_number = %s
                LIMIT 1
                """,
                (inventory_number,),
            )
            if cur.fetchone():
                print(f"Machine with ID {inventory_number} already exists")
                return False

            cur.execute(
                """
                INSERT INTO finished_goods (
                    machine_model,
                    machine_id,
                    cost_price,
                    produced_date,
                    start_date,
                    status,
                    inventory_number,
                    notes
                )
                VALUES (%s, %s, 0, CURRENT_DATE, CURRENT_DATE, 'in_progress', %s, %s)
                """,
                (model, machine_id, inventory_number, notes),
            )
            conn.commit()
    return True


def set_machine_completed(finished_good_id, inventory_number=None):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE finished_goods
                SET status = 'completed', produced_date = CURRENT_DATE, inventory_number = COALESCE(%s, inventory_number)
                WHERE id = %s
            """, (inventory_number, finished_good_id))
            conn.commit()

def complete_machine_with_material_deduction(finished_good_id, inventory_number=None):
    """
    Р—Р°РІРµСЂС€Р°РµС‚ РїСЂРѕРёР·РІРѕРґСЃС‚РІРѕ СЃС‚Р°РЅРєР°:
    - РџСЂРѕРІРµСЂСЏРµС‚, С‡С‚Рѕ СЃС‚Р°С‚СѓСЃ 'in_progress'
    - РЎРїРёСЃС‹РІР°РµС‚ РјР°С‚РµСЂРёР°Р»С‹ РїРѕ СЃРїРµС†РёС„РёРєР°С†РёРё РјРѕРґРµР»Рё
    - Р Р°СЃСЃС‡РёС‚С‹РІР°РµС‚ СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ (РјР°С‚РµСЂРёР°Р»С‹ + СЂР°Р±РѕС‚Р° + Р°РјРѕСЂС‚РёР·Р°С†РёСЏ)
    - РћР±РЅРѕРІР»СЏРµС‚ finished_goods (cost_price, status='completed', inventory_number)
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            _ensure_production_reservation_schema(cur)
            # 1. РџРѕР»СѓС‡Р°РµРј РґР°РЅРЅС‹Рµ Рѕ СЃС‚Р°РЅРєРµ
            cur.execute("""
                SELECT machine_id, machine_model
                FROM finished_goods
                WHERE id = %s AND status = 'in_progress'
            """, (finished_good_id,))
            row = cur.fetchone()
            if not row:
                print(f"РЎС‚Р°РЅРѕРє {finished_good_id} РЅРµ РЅР°Р№РґРµРЅ РёР»Рё РЅРµ РІ РїСЂРѕС†РµСЃСЃРµ")
                return False
            machine_id, model = row

            # 2. Проверяем, что все материалы уже зарезервированы для этого станка.
            cur.execute("""
                SELECT
                    m.name,
                    COALESCE(mm.quantity, 0) AS required_qty,
                    COALESCE(SUM(r.quantity), 0) AS reserved_qty
                FROM machine_materials mm
                JOIN materials m ON mm.material_id = m.id
                LEFT JOIN finished_good_material_reservations r
                    ON r.finished_good_id = %s AND r.material_id = mm.material_id
                WHERE mm.machine_id = %s
                GROUP BY m.name, mm.quantity
                HAVING COALESCE(SUM(r.quantity), 0) < COALESCE(mm.quantity, 0)
            """, (finished_good_id, machine_id))
            shortages = cur.fetchall()
            if shortages:
                print("Не все материалы зарезервированы:")
                for name, req, reserved in shortages:
                    print(f"  - {name}: требуется {req}, в резерве {reserved}")
                return False

            # 3. Переносим зарезервированные материалы в фактическое потребление.
            material_cost = Decimal('0.00')
            cur.execute("""
                SELECT material_id, purchase_id, quantity, amount, COALESCE(is_cash, FALSE)
                FROM finished_good_material_reservations
                WHERE finished_good_id = %s
                ORDER BY id
            """, (finished_good_id,))
            reservation_rows = cur.fetchall()
            material_totals = {}
            for mat_id, purchase_id, qty, amount, is_cash in reservation_rows:
                qty = Decimal(str(qty or 0))
                amount = Decimal(str(amount or 0))
                material_cost += amount
                material_totals[mat_id] = material_totals.get(mat_id, Decimal("0")) + qty
                cur.execute("""
                    INSERT INTO finished_good_material_consumptions
                        (finished_good_id, material_id, purchase_id, quantity, amount, is_cash)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (finished_good_id, mat_id, purchase_id, qty, amount, bool(is_cash)))

            for mat_id, qty in material_totals.items():
                cur.execute("""
                    INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                    VALUES (%s, %s, 'production', %s)
                """, (mat_id, -qty, finished_good_id))

            cur.execute("DELETE FROM finished_good_material_reservations WHERE finished_good_id = %s", (finished_good_id,))

            # 4. РЈС‡РёС‚С‹РІР°РµРј С‚СЂСѓРґРѕР·Р°С‚СЂР°С‚С‹ (С„Р°РєС‚РёС‡РµСЃРєРёРµ С‡Р°СЃС‹)
            cur.execute("""
                SELECT COALESCE(SUM(wl.hours * e.hourly_rate), 0)
                FROM finished_good_labor fgl
                JOIN work_logs wl ON fgl.work_log_id = wl.id
                JOIN employees e ON wl.employee_id = e.id
                WHERE fgl.finished_good_id = %s
            """, (finished_good_id,))
            labor_cost = cur.fetchone()[0] or Decimal('0.00')

            # 5. РђРјРѕСЂС‚РёР·Р°С†РёСЏ РёРЅСЃС‚СЂСѓРјРµРЅС‚РѕРІ (РµСЃР»Рё РїСЂРёРІСЏР·Р°РЅР°)
            from backend.models.tools import apply_tool_depreciation_for_production
            tool_cost = apply_tool_depreciation_for_production(machine_id, 1, finished_good_id)

            total_cost = material_cost + labor_cost + tool_cost

            # 6. РћР±РЅРѕРІР»СЏРµРј finished_goods
            cur.execute("""
                UPDATE finished_goods
                SET status = 'completed',
                    produced_date = CURRENT_DATE,
                    cost_price = %s,
                    inventory_number = COALESCE(%s, inventory_number)
                WHERE id = %s
            """, (total_cost, inventory_number, finished_good_id))

            conn.commit()
            print(f"РџСЂРѕРёР·РІРѕРґСЃС‚РІРѕ СЃС‚Р°РЅРєР° ID {finished_good_id} Р·Р°РІРµСЂС€РµРЅРѕ. РЎРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ: {total_cost:.2f}")
            return True

def get_finished_goods_summary():
    """Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃСѓРјРјР°СЂРЅСѓСЋ СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ РіРѕС‚РѕРІРѕР№ РїСЂРѕРґСѓРєС†РёРё РЅР° СЃРєР»Р°РґРµ."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COALESCE(SUM(cost_price), 0) FROM finished_goods WHERE status = 'completed'")
            return cur.fetchone()[0] or Decimal('0')
