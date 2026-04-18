# backend/models/production.py
from decimal import Decimal
from backend.db.connection import get_connection
from backend.models.machine import calculate_machine_cost_from_purchases
from backend.models.tools import apply_tool_depreciation_for_production


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
                print("Недостаточно материалов на складе:")
                for name, req, avail in shortages:
                    print(f"  - {name}: требуется {req}, в наличии {avail}")
                return False
            return True


def _produce_machine_impl(machine_id, quantity=1, notes=None, ask_labor=False):
    if not check_material_availability(machine_id, quantity):
        return False, []

    with get_connection() as conn:
        with conn.cursor() as cur:
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
            print(f"Произведено {quantity} шт. станка '{model}'.")
            print(f"Себестоимость единицы: {final_unit_cost:.2f} руб.")
            print(f"  - материалы: {material_cost_per_unit:.2f}")
            print(f"  - работа (план): {labor_cost_per_unit:.2f}")
            print(f"  - амортизация инструментов: {total_tool_depr/quantity:.2f}")

            if ask_labor:
                from backend.models.labor import add_labor_to_finished_good
                for fg_id in new_fg_ids:
                    print(f"\n--- Учёт работы для станка ID {fg_id} ---")
                    add_labor_to_finished_good(fg_id)

            return True, new_fg_ids


def produce_machine(machine_id, quantity=1, notes=None):
    success, fg_ids = _produce_machine_impl(machine_id, quantity, notes, ask_labor=False)
    if success:
        add_labor_now = input("Добавить фактические трудозатраты сейчас? (y/n): ").strip().lower()
        if add_labor_now == 'y':
            from backend.models.labor import add_labor_to_finished_good
            for fg_id in fg_ids:
                print(f"\n--- Учёт работы для станка ID {fg_id} ---")
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
                print("Нет готовых станков на складе.")
                return
            print("\n=== Готовые станки в наличии ===")
            for fg_id, model, cost, prod_date in items:
                print(f"ID: {fg_id} | Модель: {model} | Себестоимость: {cost:.2f} | Произведён: {prod_date}")
            try:
                fg_id = int(input("Введите ID готового станка для продажи (0 для отмены): "))
                if fg_id == 0:
                    return
                sale_price = Decimal(input("Введите цену продажи: "))
                if sale_price <= 0:
                    print("Цена должна быть положительной.")
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
                    VALUES (CURRENT_DATE, %s, 'Продажа станка ID ' || %s)
                """, (sale_price, fg_id))
                conn.commit()
                print(f"Продажа оформлена. Прибыль: {profit:.2f} руб.")
            except ValueError:
                print("Ошибка ввода.")


def sell_finished_good_gui(finished_good_id, sale_price, buyer=None):
    """GUI-версия продажи готового станка с указанием покупателя."""
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
            """, (sale_price, f"Продажа станка ID {finished_good_id} покупателю {buyer}"))
            conn.commit()
    return True


def plan_purchases():
    from backend.models.machine import select_machine
    machine = select_machine()
    if not machine:
        return
    machine_id, model = machine
    try:
        qty_to_produce = int(input(f"Сколько станков '{model}' планируется произвести? "))
        if qty_to_produce <= 0:
            print("Количество должно быть положительным.")
            return
    except ValueError:
        print("Неверное число.")
        return

    print(f"\n=== План закупок для производства {qty_to_produce} шт. станка '{model}' ===\n")
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
                print("Спецификация станка пуста.")
                return
            print(f"{'Материал':<40} {'Требуется':>12} {'В наличии':>12} {'Заказать':>12} {'Ед.':<5}")
            print("-" * 85)
            for name, req, stock, order, unit in rows:
                print(f"{name:<40} {req:>12.2f} {stock:>12.2f} {order:>12.2f} {unit or 'шт':<5}")
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
                print(f"Примерная стоимость закупки недостающих материалов: {est_cost:.2f} руб.")
            else:
                print("Все материалы в наличии, закупка не требуется.")


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


def start_production_gui(machine_id, quantity, notes):
    """Создаёт станки со статусом 'in_progress'."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT model FROM machines WHERE id = %s", (machine_id,))
            model = cur.fetchone()[0]
            for _ in range(quantity):
                cur.execute("""
                    INSERT INTO finished_goods (machine_model, machine_id, cost_price, produced_date, status, notes)
                    VALUES (%s, %s, 0, CURRENT_DATE, 'in_progress', %s)
                """, (model, machine_id, notes))
            conn.commit()
    return True


def set_machine_completed(finished_good_id, inventory_number=None):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE finished_goods
                SET status = 'completed', inventory_number = COALESCE(%s, inventory_number)
                WHERE id = %s
            """, (inventory_number, finished_good_id))
            conn.commit()


def get_finished_goods_summary():
    """Возвращает суммарную себестоимость готовой продукции на складе."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COALESCE(SUM(cost_price), 0) FROM finished_goods WHERE status = 'completed'")
            return cur.fetchone()[0] or Decimal('0')