from decimal import Decimal
from backend.db.connection import get_connection

def list_machines():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, model, total_cost FROM machines ORDER BY id")
            machines = cur.fetchall()
    if not machines:
        print("Станков в базе нет.")
        return []
    print("\n=== Список станков (справочник) ===")
    for mid, model, cost in machines:
        print(f"ID: {mid:<3} | Модель: {model:<20} | Расчётная себестоимость: {cost if cost else 0:.2f} руб.")
    return machines

def select_machine():
    machines = list_machines()
    if not machines:
        return None
    while True:
        try:
            mid = int(input("\nВведите ID станка (или 0 для отмены): "))
            if mid == 0:
                return None
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT id, model FROM machines WHERE id = %s", (mid,))
                    machine = cur.fetchone()
                    if machine:
                        return machine
                    else:
                        print("Станок с таким ID не найден.")
        except ValueError:
            print("Введите целое число.")

def calculate_machine_cost_from_purchases(machine_id):
    query = """
        WITH latest_prices AS (
            SELECT DISTINCT ON (material_id)
                material_id,
                price_per_unit
            FROM purchases
            WHERE price_per_unit IS NOT NULL
            ORDER BY material_id, purchase_date DESC NULLS LAST
        )
        SELECT COALESCE(SUM(lp.price_per_unit * mm.quantity), 0)
        FROM machine_materials mm
        JOIN latest_prices lp ON mm.material_id = lp.material_id
        WHERE mm.machine_id = %s
    """
    update_query = "UPDATE machines SET total_cost = %s WHERE id = %s"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (machine_id,))
            total = cur.fetchone()[0]
            cur.execute(update_query, (total, machine_id))
        conn.commit()
    return total

def show_machine_details(machine_id):
    query = """
        WITH latest_prices AS (
            SELECT DISTINCT ON (material_id)
                material_id,
                price_per_unit,
                purchase_date
            FROM purchases
            WHERE price_per_unit IS NOT NULL
            ORDER BY material_id, purchase_date DESC NULLS LAST
        )
        SELECT 
            m.name,
            mm.quantity,
            m.unit,
            lp.price_per_unit,
            (lp.price_per_unit * mm.quantity) AS line_total,
            lp.purchase_date
        FROM machine_materials mm
        JOIN materials m ON mm.material_id = m.id
        LEFT JOIN latest_prices lp ON mm.material_id = lp.material_id
        WHERE mm.machine_id = %s
        ORDER BY m.name
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT model, total_cost FROM machines WHERE id = %s", (machine_id,))
            machine = cur.fetchone()
            if not machine:
                print(f"Станок с ID {machine_id} не найден.")
                return
            model, total_cost = machine
            print(f"\n=== Спецификация станка '{model}' (ID {machine_id}) ===")
            print(f"Себестоимость (расчётная): {total_cost:.2f} руб.\n")
            cur.execute(query, (machine_id,))
            rows = cur.fetchall()
            if not rows:
                print("Состав станка пуст.")
                return
            print(f"{'№':<4} {'Наименование':<40} {'Кол-во':>8} {'Ед.':<5} {'Цена за ед.':>12} {'Сумма':>12}")
            print("-" * 90)
            total_calc = Decimal('0.00')
            for idx, (name, qty, unit, price, line_total, _) in enumerate(rows, 1):
                if price is None:
                    price_display = "нет цены"
                    line_total = Decimal('0.00')
                else:
                    price_display = f"{price:.2f}"
                    total_calc += line_total
                print(f"{idx:<4} {name:<40} {qty:>8.2f} {unit or 'шт':<5} {price_display:>12} {line_total:>12.2f}")
            print("-" * 90)
            print(f"{'ИТОГО (расчёт по последним ценам):':<70} {total_calc:.2f} руб.")

def add_material_to_machine(machine_id):
    print("\n--- Добавление материала в станок ---")
    search = input("Введите часть названия материала для поиска: ").strip()
    if not search:
        return
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, unit FROM materials WHERE name ILIKE %s ORDER BY name LIMIT 20", (f"%{search}%",))
            mats = cur.fetchall()
            if not mats:
                print("Материалы не найдены.")
                return
            for i, (mid, name, unit) in enumerate(mats, 1):
                print(f"{i}. {name} ({unit or 'шт'})")
            try:
                choice = int(input("Выберите номер (0 для отмены): "))
                if choice == 0: return
                if choice < 1 or choice > len(mats): return
                mat_id, mat_name, _ = mats[choice-1]
                qty = Decimal(input("Введите количество: "))
                if qty <= 0: return
                cur.execute("SELECT quantity FROM machine_materials WHERE machine_id=%s AND material_id=%s", (machine_id, mat_id))
                existing = cur.fetchone()
                if existing:
                    cur.execute("UPDATE machine_materials SET quantity = quantity + %s WHERE machine_id=%s AND material_id=%s", (qty, machine_id, mat_id))
                else:
                    cur.execute("INSERT INTO machine_materials (machine_id, material_id, quantity) VALUES (%s,%s,%s)", (machine_id, mat_id, qty))
                conn.commit()
                print("Добавлено.")
            except ValueError:
                print("Ошибка ввода.")

def remove_material_from_machine(machine_id):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT mm.material_id, m.name, mm.quantity
                FROM machine_materials mm JOIN materials m ON mm.material_id = m.id
                WHERE mm.machine_id = %s ORDER BY m.name
            """, (machine_id,))
            items = cur.fetchall()
            if not items:
                print("Спецификация пуста.")
                return
            for i, (mid, name, qty) in enumerate(items, 1):
                print(f"{i}. {name} — {qty}")
            try:
                choice = int(input("Номер для удаления (0 - отмена): "))
                if choice == 0: return
                mat_id = items[choice-1][0]
                cur.execute("DELETE FROM machine_materials WHERE machine_id=%s AND material_id=%s", (machine_id, mat_id))
                conn.commit()
                print("Удалено.")
            except (ValueError, IndexError):
                print("Ошибка.")

def edit_material_quantity_in_machine(machine_id):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT mm.material_id, m.name, mm.quantity
                FROM machine_materials mm JOIN materials m ON mm.material_id = m.id
                WHERE mm.machine_id = %s ORDER BY m.name
            """, (machine_id,))
            items = cur.fetchall()
            if not items:
                print("Спецификация пуста.")
                return
            print("\nТекущие материалы в спецификации:")
            for i, (mid, name, qty) in enumerate(items, 1):
                print(f"{i}. {name} — {qty}")
            try:
                choice = int(input("Выберите номер материала для изменения (0 - отмена): "))
                if choice == 0: return
                mat_id, mat_name, old_qty = items[choice-1]
                new_qty = Decimal(input(f"Введите новое количество для '{mat_name}' (текущее: {old_qty}): "))
                if new_qty < 0:
                    print("Количество не может быть отрицательным.")
                    return
                if new_qty == 0:
                    cur.execute("DELETE FROM machine_materials WHERE machine_id=%s AND material_id=%s", (machine_id, mat_id))
                    print("Материал удалён из спецификации (количество = 0).")
                else:
                    cur.execute("UPDATE machine_materials SET quantity = %s WHERE machine_id=%s AND material_id=%s", (new_qty, machine_id, mat_id))
                    print(f"Количество материала '{mat_name}' изменено на {new_qty}.")
                conn.commit()
            except (ValueError, IndexError):
                print("Ошибка ввода.")

def add_new_machine():

    model = input("Модель станка: ").strip()
    if not model: return
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO machines (model) VALUES (%s) RETURNING id", (model,))
            mid = cur.fetchone()[0]
            conn.commit()
            print(f"Станок '{model}' добавлен, ID {mid}.")

def show_finished_good_details(finished_good_id):
    """Показывает детали конкретного готового станка, включая материалы и трудозатраты."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT fg.id, fg.machine_model, fg.cost_price, fg.produced_date, fg.status, fg.notes,
                       m.id AS machine_id
                FROM finished_goods fg
                LEFT JOIN machines m ON fg.machine_id = m.id
                WHERE fg.id = %s
            """, (finished_good_id,))
            fg = cur.fetchone()
            if not fg:
                print(f"Готовое изделие с ID {finished_good_id} не найдено.")
                return
            fg_id, model, cost, prod_date, status, notes, machine_id = fg
            print(f"\n=== Готовое изделие ID {fg_id} ===")
            print(f"Модель: {model}")
            print(f"Дата производства: {prod_date}")
            print(f"Статус: {status}")
            print(f"Себестоимость: {cost:.2f} руб.")
            if notes:
                print(f"Примечание: {notes}")

            # Спецификация материалов (если есть связь с моделью)
            if machine_id:
                print("\n--- Материалы (спецификация модели) ---")
                cur.execute("""
                    WITH latest_prices AS (
                        SELECT DISTINCT ON (material_id) material_id, price_per_unit
                        FROM purchases WHERE price_per_unit IS NOT NULL
                        ORDER BY material_id, purchase_date DESC
                    )
                    SELECT m.name, mm.quantity, m.unit, lp.price_per_unit,
                           (lp.price_per_unit * mm.quantity) AS line_total
                    FROM machine_materials mm
                    JOIN materials m ON mm.material_id = m.id
                    LEFT JOIN latest_prices lp ON mm.material_id = lp.material_id
                    WHERE mm.machine_id = %s
                    ORDER BY m.name
                """, (machine_id,))
                mat_rows = cur.fetchall()
                for name, qty, unit, price, line_total in mat_rows:
                    price_str = f"{price:.2f}" if price else "нет цены"
                    print(f"  {name:<30} {qty:>8.2f} {unit or 'шт':<5} x {price_str:>10} = {line_total or 0:>10.2f}")
            else:
                print("Связь с моделью отсутствует.")

            # Трудозатраты, привязанные к данному экземпляру
            print("\n--- Трудозатраты ---")
            cur.execute("""
                SELECT e.name, wt.name, wl.hours, e.hourly_rate, (wl.hours * e.hourly_rate) AS cost, wl.date
                FROM finished_good_labor fgl
                JOIN work_logs wl ON fgl.work_log_id = wl.id
                JOIN employees e ON wl.employee_id = e.id
                JOIN work_types wt ON wl.work_type_id = wt.id
                WHERE fgl.finished_good_id = %s
                ORDER BY wl.date
            """, (finished_good_id,))
            labor_rows = cur.fetchall()
            if labor_rows:
                print(f"{'Работник':<20} {'Вид работы':<15} {'Часы':>6} {'Ставка':>8} {'Сумма':>10} {'Дата':>12}")
                total_labor = Decimal('0')
                for emp, wt_name, hrs, rate, cost, dt in labor_rows:
                    print(f"{emp:<20} {wt_name:<15} {hrs:>6.2f} {rate:>8.2f} {cost:>10.2f} {str(dt):>12}")
                    total_labor += cost
                print(f"{'Итого трудозатраты:':<50} {total_labor:>10.2f} руб.")
            else:
                print("Нет учтённых трудозатрат.")
def add_new_machine_gui(model):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO machines (model) VALUES (%s)", (model,))
            conn.commit()
    return True

def add_material_to_machine_gui(machine_id, material_id, quantity):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO machine_materials (machine_id, material_id, quantity)
                VALUES (%s, %s, %s)
                ON CONFLICT (machine_id, material_id) DO UPDATE SET quantity = machine_materials.quantity + EXCLUDED.quantity
            """, (machine_id, material_id, quantity))
            conn.commit()
    return True

def remove_material_from_machine_gui(machine_id, material_id):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM machine_materials WHERE machine_id=%s AND material_id=%s", (machine_id, material_id))
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

def edit_material_quantity_in_machine_gui(machine_id, material_id, quantity):
    if quantity == 0:
        return remove_material_from_machine_gui(machine_id, material_id)
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("UPDATE machine_materials SET quantity=%s WHERE machine_id=%s AND material_id=%s", (quantity, machine_id, material_id))
            conn.commit()
    return True