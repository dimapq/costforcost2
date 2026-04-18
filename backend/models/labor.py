# backend/models/labor.py
from decimal import Decimal
from backend.db.connection import get_connection

# ---------- Работники ----------
def add_employee():
    name = input("Имя работника: ").strip()
    if not name:
        return
    try:
        rate = Decimal(input("Почасовая ставка (руб/час): "))
    except:
        print("Неверная ставка.")
        return
    position = input("Должность (необязательно): ").strip()
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO employees (name, hourly_rate, position)
                VALUES (%s, %s, %s)
            """, (name, rate, position if position else None))
            conn.commit()
    print(f"Работник '{name}' добавлен.")

def list_employees():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, hourly_rate, position FROM employees WHERE active ORDER BY name")
            rows = cur.fetchall()
    if not rows:
        print("Нет работников.")
        return []
    print("\n=== Список работников ===")
    for eid, name, rate, pos in rows:
        print(f"ID: {eid} | {name} | Ставка: {rate} руб/ч | {pos or ''}")
    return rows

def select_employee():
    employees = list_employees()
    if not employees:
        return None
    while True:
        try:
            eid = int(input("Введите ID работника (0 для отмены): "))
            if eid == 0:
                return None
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT id, name FROM employees WHERE id=%s AND active", (eid,))
                    emp = cur.fetchone()
                    if emp:
                        return emp
                    else:
                        print("Работник не найден.")
        except ValueError:
            print("Введите число.")

# ---------- Виды работ ----------
def add_work_type():
    name = input("Название вида работы (например, 'Сборка'): ").strip()
    if not name:
        return
    desc = input("Описание (необязательно): ").strip()
    with get_connection() as conn:
        with conn.cursor() as cur:
            try:
                cur.execute("INSERT INTO work_types (name, description) VALUES (%s, %s)", (name, desc if desc else None))
                conn.commit()
                print(f"Вид работы '{name}' добавлен.")
            except:
                print("Такой вид работы уже существует.")

def list_work_types():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name FROM work_types ORDER BY name")
            rows = cur.fetchall()
    if not rows:
        print("Нет видов работ.")
        return []
    print("\n=== Виды работ ===")
    for wid, name in rows:
        print(f"ID: {wid} | {name}")
    return rows

def select_work_type():
    wtypes = list_work_types()
    if not wtypes:
        return None
    while True:
        try:
            wid = int(input("Введите ID вида работы (0 для отмены): "))
            if wid == 0:
                return None
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT id, name FROM work_types WHERE id=%s", (wid,))
                    wt = cur.fetchone()
                    if wt:
                        return wt
                    else:
                        print("Вид работы не найден.")
        except ValueError:
            print("Введите число.")

# ---------- Учёт часов ----------
def log_work_hours():
    print("\n--- Учёт отработанного времени ---")
    employee = select_employee()
    if not employee:
        return
    work_type = select_work_type()
    if not work_type:
        return
    from backend.models.machine import select_machine
    machine = select_machine()
    machine_id = machine[0] if machine else None

    try:
        hours = Decimal(input("Отработано часов: "))
        if hours <= 0:
            print("Часы должны быть положительными.")
            return
    except:
        print("Неверное число.")
        return
    date_str = input("Дата (ГГГГ-ММ-ДД, Enter - сегодня): ").strip()
    if date_str:
        from datetime import datetime
        try:
            date = datetime.strptime(date_str, "%Y-%m-%d").date()
        except:
            print("Неверный формат даты.")
            return
    else:
        date = None
    notes = input("Примечание: ").strip()

    with get_connection() as conn:
        with conn.cursor() as cur:
            if date:
                cur.execute("""
                    INSERT INTO work_logs (employee_id, work_type_id, machine_id, date, hours, notes)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (employee[0], work_type[0], machine_id, date, hours, notes if notes else None))
            else:
                cur.execute("""
                    INSERT INTO work_logs (employee_id, work_type_id, machine_id, hours, notes)
                    VALUES (%s, %s, %s, %s, %s)
                """, (employee[0], work_type[0], machine_id, hours, notes if notes else None))
            conn.commit()
    print(f"Записано {hours} ч для {employee[1]} ({work_type[1]}).")

# ---------- Привязка часов к готовому станку (новая функция) ----------
def add_labor_to_finished_good(finished_good_id, employee_id=None, hours=None, notes=""):
    """
    Привязывает отработанные часы к готовому станку.
    Если employee_id не указан, запрашивает интерактивно.
    Если hours не указаны, запрашивает.
    """
    if employee_id is None:
        emp = select_employee()
        if not emp:
            return False
        employee_id = emp[0]
    if hours is None:
        try:
            hours = Decimal(input("Отработано часов: "))
        except:
            print("Неверное количество часов.")
            return False
    # Для простоты используем вид работы по умолчанию или создадим универсальный
    work_type_id = 1  # предположим, что есть хотя бы один вид работы, или можно получить из БД
    with get_connection() as conn:
        with conn.cursor() as cur:
            # Убедимся, что есть вид работы
            cur.execute("SELECT id FROM work_types LIMIT 1")
            wt = cur.fetchone()
            if not wt:
                # Создадим вид работы "Общая работа"
                cur.execute("INSERT INTO work_types (name) VALUES ('Общая работа') ON CONFLICT (name) DO NOTHING RETURNING id")
                work_type_id = cur.fetchone()[0]
            else:
                work_type_id = wt[0]

            # Вставляем запись в work_logs
            cur.execute("""
                INSERT INTO work_logs (employee_id, work_type_id, hours, notes, date)
                VALUES (%s, %s, %s, %s, CURRENT_DATE)
                RETURNING id
            """, (employee_id, work_type_id, hours, notes if notes else None))
            work_log_id = cur.fetchone()[0]

            # Связываем с готовым изделием
            cur.execute("""
                INSERT INTO finished_good_labor (finished_good_id, work_log_id)
                VALUES (%s, %s)
            """, (finished_good_id, work_log_id))

            # Увеличиваем себестоимость готового изделия
            cur.execute("SELECT hourly_rate FROM employees WHERE id = %s", (employee_id,))
            rate = cur.fetchone()[0] or Decimal('0')
            additional_cost = hours * rate
            cur.execute("""
                UPDATE finished_goods
                SET cost_price = cost_price + %s
                WHERE id = %s
            """, (additional_cost, finished_good_id))

            conn.commit()
            print(f"Добавлено {hours} ч работы. Себестоимость станка ID {finished_good_id} увеличена на {additional_cost:.2f} руб.")
            return True

# ---------- Расчёт зарплаты ----------
def calculate_payroll():
    from datetime import datetime, date
    start_str = input("Начальная дата (ГГГГ-ММ-ДД, Enter - начало месяца): ").strip()
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
                SELECT e.id, e.name, e.hourly_rate, SUM(wl.hours) AS total_hours
                FROM employees e
                LEFT JOIN work_logs wl ON e.id = wl.employee_id
                WHERE e.active AND (wl.date BETWEEN %s AND %s OR wl.date IS NULL)
                GROUP BY e.id
                ORDER BY e.name
            """, (start_date, end_date))
            rows = cur.fetchall()
    if not rows:
        print("Нет данных.")
        return
    print(f"\n=== Зарплата за период {start_date} – {end_date} ===")
    print(f"{'Работник':<25} {'Часы':>8} {'Ставка':>10} {'Сумма':>12}")
    print("-" * 60)
    total_payroll = Decimal('0.00')
    for eid, name, rate, hours in rows:
        hours = hours or Decimal('0.00')
        amount = hours * (rate or Decimal('0.00'))
        total_payroll += amount
        print(f"{name:<25} {hours:>8.2f} {rate or 0:>10.2f} {amount:>12.2f}")
    print("-" * 60)
    print(f"{'ИТОГО:':<46} {total_payroll:>12.2f} руб.")

# ---------- Задание трудозатрат для модели станка ----------
def set_machine_labor_cost():
    from backend.models.machine import select_machine
    machine = select_machine()
    if not machine:
        return
    work_type = select_work_type()
    if not work_type:
        return
    print("Оставьте пустым, если не нужно задавать.")
    fixed_str = input("Фиксированная стоимость за станок (руб): ").strip()
    fixed = Decimal(fixed_str) if fixed_str else None
    hours_str = input("Плановое количество часов: ").strip()
    hours = Decimal(hours_str) if hours_str else None
    if fixed is None and hours is None:
        print("Ничего не задано.")
        return
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO machine_labor_costs (machine_id, work_type_id, fixed_cost, estimated_hours)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (machine_id, work_type_id) DO UPDATE
                SET fixed_cost = EXCLUDED.fixed_cost, estimated_hours = EXCLUDED.estimated_hours
            """, (machine[0], work_type[0], fixed, hours))
            conn.commit()
    print("Параметры трудозатрат сохранены.")

def add_employee_gui(name, rate, position):
    from backend.db.connection import get_connection
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO employees (name, hourly_rate, position)
                VALUES (%s, %s, %s)
            """, (name, rate, position if position else None))
            conn.commit()
    return True