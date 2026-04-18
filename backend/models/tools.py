# backend/models/tools.py
from decimal import Decimal
from datetime import date, datetime
from backend.db.connection import get_connection

# ---------- Сводка по инструментам ----------
def get_tools_summary():
    """Возвращает остаточную стоимость всех активных инструментов."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT COALESCE(SUM(residual_value), 0) FROM tools WHERE status = 'active'")
            return cur.fetchone()[0] or Decimal('0')

# ---------- Автоматическое списание амортизации при производстве ----------
def apply_tool_depreciation_for_production(machine_id, quantity, finished_good_id=None):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT t.id, t.residual_value, mt.usage_per_unit * %s AS amount_to_depreciate
                FROM machine_tools mt
                JOIN tools t ON mt.tool_id = t.id
                WHERE mt.machine_id = %s AND t.status = 'active'
            """, (quantity, machine_id))
            rows = cur.fetchall()
            total_depr = Decimal('0')
            for tool_id, residual, amount in rows:
                if amount > residual:
                    amount = residual
                    cur.execute("UPDATE tools SET status = 'written_off' WHERE id = %s", (tool_id,))
                cur.execute("""
                    INSERT INTO tool_depreciation (tool_id, amount, finished_good_id, notes)
                    VALUES (%s, %s, %s, %s)
                """, (tool_id, amount, finished_good_id, 'Автоматическое списание при производстве'))
                cur.execute("UPDATE tools SET residual_value = residual_value - %s WHERE id = %s", (amount, tool_id))
                total_depr += amount
            return total_depr

# ---------- Добавление инструмента ----------
def add_tool():
    print("\n--- Добавление инструмента/оборудования ---")
    name = input("Название: ").strip()
    if not name:
        return
    inv_num = input("Инвентарный номер (необязательно): ").strip()
    try:
        cost = Decimal(input("Стоимость покупки (руб): "))
        if cost <= 0:
            print("Стоимость должна быть положительной.")
            return
    except:
        print("Неверная стоимость.")
        return
    months_str = input("Срок полезного использования (месяцев, Enter - не задан): ").strip()
    useful_life = int(months_str) if months_str else None
    monthly_depr = (cost / useful_life).quantize(Decimal('0.01')) if useful_life else None
    purchase_date_str = input("Дата покупки (ГГГГ-ММ-ДД, Enter - сегодня): ").strip()
    if purchase_date_str:
        try:
            purchase_date = datetime.strptime(purchase_date_str, "%Y-%m-%d").date()
        except:
            print("Неверный формат даты.")
            return
    else:
        purchase_date = date.today()
    notes = input("Примечание: ").strip()

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO tools (name, inventory_number, purchase_date, purchase_cost,
                                   useful_life_months, monthly_depreciation, residual_value, notes)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (name, inv_num if inv_num else None, purchase_date, cost,
                  useful_life, monthly_depr, cost, notes if notes else None))
            conn.commit()
    print(f"Инструмент '{name}' добавлен. Остаточная стоимость: {cost} руб.")

# ---------- Список инструментов ----------
def list_tools(only_active=True):
    with get_connection() as conn:
        with conn.cursor() as cur:
            if only_active:
                cur.execute("SELECT id, name, inventory_number, purchase_cost, residual_value, status FROM tools WHERE status='active' ORDER BY name")
            else:
                cur.execute("SELECT id, name, inventory_number, purchase_cost, residual_value, status FROM tools ORDER BY name")
            tools = cur.fetchall()
            
            if only_active:
                cur.execute("SELECT SUM(purchase_cost), SUM(residual_value) FROM tools WHERE status='active'")
            else:
                cur.execute("SELECT SUM(purchase_cost), SUM(residual_value) FROM tools")
            total_purchase, total_residual = cur.fetchone()
            
    if not tools:
        print("Нет инструментов.")
        return []
    
    print("\n=== Инструменты и оборудование ===")
    print(f"{'ID':<4} {'Название':<30} {'Инв.№':<10} {'Стоимость покупки':>15} {'Остаточная':>15} {'Статус':<10}")
    print("-" * 90)
    for t in tools:
        print(f"{t[0]:<4} {t[1][:30]:<30} {t[2] or '—':<10} {t[3]:>15.2f} {t[4]:>15.2f} {t[5]:<10}")
    print("-" * 90)
    print(f"{'ИТОГО:':<44} {total_purchase or 0:>15.2f} {total_residual or 0:>15.2f}")
    print(f"Общая амортизация (списано): {(total_purchase or 0) - (total_residual or 0):.2f} руб.")
    return tools

def select_tool():
    tools = list_tools()
    if not tools:
        return None
    while True:
        try:
            tid = int(input("Введите ID инструмента (0 для отмены): "))
            if tid == 0:
                return None
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT id, name, residual_value FROM tools WHERE id=%s", (tid,))
                    tool = cur.fetchone()
                    if tool:
                        return tool
                    else:
                        print("Инструмент не найден.")
        except ValueError:
            print("Введите число.")

# ---------- Начисление амортизации и списание ----------
def depreciate_tool():
    tool = select_tool()
    if not tool:
        return
    tool_id, tool_name, current_residual = tool

    print(f"\nИнструмент: {tool_name} (остаточная стоимость: {current_residual:.2f} руб.)")
    print("1. Начислить амортизацию за месяц (автоматически)")
    print("2. Ввести произвольную сумму списания")
    print("3. Списать на готовый станок (привязать к изделию)")
    choice = input("Выберите действие: ").strip()

    if choice == '1':
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT monthly_depreciation FROM tools WHERE id=%s", (tool_id,))
                monthly = cur.fetchone()[0]
                if not monthly:
                    print("Для этого инструмента не задан срок службы, автоматическая амортизация невозможна.")
                    return
                amount = monthly
                if amount > current_residual:
                    amount = current_residual
                    print(f"Остаточная стоимость меньше месячной амортизации, списываем {amount:.2f}")
                cur.execute("""
                    INSERT INTO tool_depreciation (tool_id, amount, notes)
                    VALUES (%s, %s, %s)
                """, (tool_id, amount, 'Ежемесячная амортизация'))
                cur.execute("UPDATE tools SET residual_value = residual_value - %s WHERE id=%s", (amount, tool_id))
                conn.commit()
                print(f"Начислена амортизация {amount:.2f} руб.")
    elif choice == '2':
        try:
            amount = Decimal(input("Сумма списания: "))
        except:
            print("Неверная сумма.")
            return
        if amount <= 0 or amount > current_residual:
            print("Сумма должна быть положительной и не больше остаточной стоимости.")
            return
        notes = input("Примечание: ").strip()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO tool_depreciation (tool_id, amount, notes)
                    VALUES (%s, %s, %s)
                """, (tool_id, amount, notes if notes else 'Ручное списание'))
                cur.execute("UPDATE tools SET residual_value = residual_value - %s WHERE id=%s", (amount, tool_id))
                conn.commit()
        print(f"Списано {amount:.2f} руб.")
    elif choice == '3':
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, machine_model, cost_price, produced_date
                    FROM finished_goods
                    WHERE status = 'in_stock'
                    ORDER BY produced_date
                """)
                fg_list = cur.fetchall()
        if not fg_list:
            print("Нет готовых станков на складе.")
            return
        print("\nДоступные готовые станки:")
        for fg in fg_list:
            print(f"ID: {fg[0]} | Модель: {fg[1]} | Себестоимость: {fg[2]:.2f} | Произведён: {fg[3]}")
        try:
            fg_id = int(input("Введите ID готового станка: "))
        except:
            print("Неверный ID.")
            return
        if not any(fg[0] == fg_id for fg in fg_list):
            print("Неверный ID.")
            return
        try:
            amount = Decimal(input("Сумма списания (часть стоимости инструмента на этот станок): "))
        except:
            print("Неверная сумма.")
            return
        if amount <= 0 or amount > current_residual:
            print("Сумма должна быть положительной и не больше остаточной стоимости.")
            return
        notes = input("Примечание: ").strip()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO tool_depreciation (tool_id, amount, finished_good_id, notes)
                    VALUES (%s, %s, %s, %s)
                """, (tool_id, amount, fg_id, notes if notes else f'Списано на станок ID {fg_id}'))
                cur.execute("UPDATE tools SET residual_value = residual_value - %s WHERE id=%s", (amount, tool_id))
                cur.execute("UPDATE finished_goods SET cost_price = cost_price + %s WHERE id=%s", (amount, fg_id))
                conn.commit()
        print(f"Списано {amount:.2f} руб. на станок ID {fg_id}. Себестоимость станка увеличена.")
    else:
        print("Неверный выбор.")

# ---------- Привязка инструмента к модели станка ----------
def link_tool_to_machine():
    from backend.models.machine import select_machine
    machine = select_machine()
    if not machine:
        return
    tool = select_tool()
    if not tool:
        return
    try:
        usage = Decimal(input("Доля стоимости инструмента, приходящаяся на один станок (например, 0.01 = 1%): "))
        if usage <= 0 or usage > 1:
            print("Доля должна быть от 0 до 1.")
            return
    except:
        print("Неверное значение.")
        return
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO machine_tools (machine_id, tool_id, usage_per_unit)
                VALUES (%s, %s, %s)
                ON CONFLICT (machine_id, tool_id) DO UPDATE SET usage_per_unit = EXCLUDED.usage_per_unit
            """, (machine[0], tool[0], usage))
            conn.commit()
    print(f"Инструмент '{tool[1]}' привязан к модели '{machine[1]}' с долей {usage}.")

# ---------- Списание инструмента при поломке/утере ----------
def write_off_tool():
    tool = select_tool()
    if not tool:
        return
    tool_id, tool_name, current_residual = tool

    if current_residual <= 0:
        print("Инструмент уже полностью самортизирован. Можно просто изменить статус вручную.")
        return

    print(f"\nИнструмент: {tool_name}")
    print(f"Остаточная стоимость: {current_residual:.2f} руб.")
    reason = input("Причина списания (поломка/утеря/иное): ").strip()
    if not reason:
        reason = "Списание"
    
    attach_to_fg = input("Списать на готовый станок? (y/n): ").strip().lower()
    finished_good_id = None
    if attach_to_fg == 'y':
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, machine_model, cost_price, produced_date
                    FROM finished_goods
                    WHERE status = 'in_stock'
                    ORDER BY produced_date
                """)
                fg_list = cur.fetchall()
        if not fg_list:
            print("Нет готовых станков на складе. Списание будет учтено как общий убыток.")
        else:
            print("\nДоступные готовые станки:")
            for fg in fg_list:
                print(f"ID: {fg[0]} | Модель: {fg[1]} | Себестоимость: {fg[2]:.2f} | Произведён: {fg[3]}")
            try:
                finished_good_id = int(input("Введите ID готового станка (0 - списать без привязки): "))
                if finished_good_id == 0:
                    finished_good_id = None
                else:
                    if not any(fg[0] == finished_good_id for fg in fg_list):
                        print("Неверный ID, списание без привязки.")
                        finished_good_id = None
            except ValueError:
                print("Неверный ввод, списание без привязки.")

    confirm = input(f"Списать остаточную стоимость {current_residual:.2f} руб.? (y/n): ").strip().lower()
    if confirm != 'y':
        print("Списание отменено.")
        return

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO tool_depreciation (tool_id, amount, finished_good_id, notes)
                VALUES (%s, %s, %s, %s)
            """, (tool_id, current_residual, finished_good_id, f"Списание: {reason}"))
            
            cur.execute("""
                UPDATE tools
                SET residual_value = 0,
                    status = 'written_off'
                WHERE id = %s
            """, (tool_id,))
            
            if finished_good_id:
                cur.execute("""
                    UPDATE finished_goods
                    SET cost_price = cost_price + %s
                    WHERE id = %s
                """, (current_residual, finished_good_id))
                print(f"Стоимость списания добавлена к себестоимости станка ID {finished_good_id}.")
            
            cur.execute("""
                INSERT INTO balance (date, expense, notes)
                VALUES (CURRENT_DATE, %s, %s)
            """, (current_residual, f"Списание инструмента '{tool_name}': {reason}"))
            
            conn.commit()
    
    print(f"Инструмент '{tool_name}' списан. Остаточная стоимость {current_residual:.2f} руб. учтена в расходах.")

# ---------- Отчёт по амортизации за период ----------
def show_depreciation_report():
    start_str = input("Начальная дата (ГГГГ-ММ-ДД, Enter - начало текущего месяца): ").strip()
    end_str = input("Конечная дата (ГГГГ-ММ-ДД, Enter - сегодня): ").strip()
    
    if start_str:
        start_date = datetime.strptime(start_str, "%Y-%m-%d").date()
    else:
        today = date.today()
        start_date = today.replace(day=1)
    if end_str:
        end_date = datetime.strptime(end_str, "%Y-%m-%d").date()
    else:
        end_date = date.today()
    
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT t.name, SUM(td.amount) AS total_amount
                FROM tool_depreciation td
                JOIN tools t ON td.tool_id = t.id
                WHERE td.depreciation_date BETWEEN %s AND %s
                GROUP BY t.name
                ORDER BY total_amount DESC
            """, (start_date, end_date))
            rows = cur.fetchall()
            
            cur.execute("""
                SELECT SUM(amount) FROM tool_depreciation
                WHERE depreciation_date BETWEEN %s AND %s
            """, (start_date, end_date))
            total = cur.fetchone()[0] or Decimal('0')
    
    if not rows:
        print("За указанный период амортизация не начислялась.")
        return
    
    print(f"\n=== Амортизация инструментов за период {start_date} – {end_date} ===")
    print(f"{'Инструмент':<40} {'Сумма':>12}")
    print("-" * 55)
    for name, amount in rows:
        print(f"{name:<40} {amount:>12.2f}")
    print("-" * 55)
    print(f"{'ИТОГО:':<40} {total:>12.2f}")