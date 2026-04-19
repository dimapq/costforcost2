# frontend/controllers/backend_controller.py
from PySide6.QtCore import QObject, Slot
from decimal import Decimal

from backend.models.labor import add_labor_to_finished_good
from backend.models.inventory import get_materials_summary
from backend.models.tools import get_tools_summary
from backend.models.production import get_finished_goods_summary
from backend.models.analytics import get_recent_transactions
from backend.models.machine import list_machines, calculate_machine_cost_from_purchases
from backend.db.connection import get_connection


class BackendController(QObject):

    # ---------- Станки ----------
    @Slot(str, result=str)
    def calculate_cost(self, machine_id):
        try:
            cost = calculate_machine_cost_from_purchases(int(machine_id))
            return f"{cost:.2f}"
        except Exception as e:
            print(f"Ошибка расчёта стоимости: {e}")
            return "0.00"

    @Slot(result="QVariantList")
    def get_machines(self):
        machines = list_machines()
        return [{"id": m[0], "model": m[1], "cost": float(m[2]) if m[2] else 0.0} for m in machines]

    # ---------- Сотрудники ----------
    @Slot(result="QVariantList")
    def getEmployeesList(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, name FROM employees WHERE active ORDER BY name")
                rows = cur.fetchall()
        return [{"id": row[0], "name": row[1]} for row in rows]

    @Slot(str, float, str, result=bool)
    def addEmployee(self, name, rate, position):
        try:
            from backend.models.labor import add_employee_gui
            return add_employee_gui(name, Decimal(str(rate)), position)
        except Exception as e:
            print(f"Ошибка добавления сотрудника: {e}")
            return False

    @Slot(int, str, float, str, bool, result=bool)
    def updateEmployee(self, emp_id, name, rate, position, active):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE employees
                        SET name = %s, hourly_rate = %s, position = %s, active = %s
                        WHERE id = %s
                    """, (name, Decimal(str(rate)), position if position else None, active, emp_id))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка обновления сотрудника: {e}")
            return False

    @Slot(int, result=bool)
    def toggleEmployeeActive(self, emp_id):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("UPDATE employees SET active = NOT active WHERE id = %s", (emp_id,))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка изменения статуса: {e}")
            return False

    @Slot(str, str, result=str)
    def calculatePayroll(self, start_date_str, end_date_str):
        try:
            from datetime import datetime, date
            if start_date_str:
                start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
            else:
                today = date.today()
                start_date = today.replace(day=1)
            if end_date_str:
                end_date = datetime.strptime(end_date_str, "%Y-%m-%d").date()
            else:
                end_date = date.today()

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT e.name, SUM(wl.hours) AS total_hours, e.hourly_rate
                        FROM employees e
                        LEFT JOIN work_logs wl ON e.id = wl.employee_id
                        WHERE e.active AND (wl.date BETWEEN %s AND %s OR wl.date IS NULL)
                        GROUP BY e.id
                        ORDER BY e.name
                    """, (start_date, end_date))
                    rows = cur.fetchall()
            lines = []
            total = Decimal('0.00')
            for name, hours, rate in rows:
                hours = hours or Decimal('0.00')
                rate = rate or Decimal('0.00')
                amount = hours * rate
                total += amount
                lines.append(f"{name}: {hours:.2f} ч × {rate:.2f} = {amount:.2f} руб.")
            lines.append(f"ИТОГО: {total:.2f} руб.")
            return "\n".join(lines)
        except Exception as e:
            print(f"Ошибка расчёта зарплаты: {e}")
            return "Ошибка расчёта"

    # ---------- Готовые станки ----------
    @Slot(result="QVariantList")
    def getFinishedGoodsList(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, machine_model, cost_price, produced_date
                    FROM finished_goods
                    WHERE status = 'completed'
                    ORDER BY produced_date DESC
                """)
                rows = cur.fetchall()
        return [{"id": row[0], "display": f"{row[1]} (ID {row[0]}, {row[2]:.2f} руб.)"} for row in rows]

    @Slot(result="QVariantList")
    def getInProgressMachinesList(self):
        """Возвращает список станков в активном пуле (статус 'in_progress')."""
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, machine_model, produced_date
                    FROM finished_goods
                    WHERE status = 'in_progress'
                    ORDER BY produced_date DESC
                """)
                rows = cur.fetchall()
        return [
            {
                "id": row[0], 
                "display": f"{row[1]} (ID {row[0]}, начат {row[2]})"
            } 
            for row in rows
        ]

    # ---------- Учёт рабочего времени ----------
    @Slot(int, int, float, str, result=bool)
    def logWorkHours(self, employee_id, finished_good_id, hours, notes):
        try:
            add_labor_to_finished_good(finished_good_id, employee_id, Decimal(str(hours)), notes)
            return True
        except Exception as e:
            print(f"Ошибка записи часов: {e}")
            return False

    # ---------- Складские сводки ----------
    @Slot(result=str)
    def getMaterialsSummary(self):
        try:
            return f"{get_materials_summary():.2f}"
        except:
            return "0.00"

    @Slot(result=str)
    def getToolsSummary(self):
        try:
            return f"{get_tools_summary():.2f}"
        except:
            return "0.00"

    @Slot(result=str)
    def getFinishedGoodsSummary(self):
        try:
            return f"{get_finished_goods_summary():.2f}"
        except:
            return "0.00"

    @Slot(int, result="QVariantList")
    def getRecentTransactions(self, limit):
        try:
            transactions = get_recent_transactions(limit)
            result = []
            for t in transactions:
                result.append({
                    "date": t['date'].strftime("%d.%m.%Y %H:%M") if t.get('date') else "",
                    "type": t.get('type', ''),
                    "description": t.get('description', ''),
                    "amount": f"{t.get('amount', 0):.2f} руб." if t.get('amount') else ""
                })
            return result
        except Exception as e:
            print(f"Ошибка получения транзакций: {e}")
            return []

    # ---------- Материалы ----------
    @Slot(str, str, float, float, result=bool)
    def addMaterial(self, name, unit, price, quantity):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO materials (name, unit) VALUES (%s, %s)
                        ON CONFLICT (name) DO UPDATE SET unit = EXCLUDED.unit
                        RETURNING id
                    """, (name, unit))
                    mat_id = cur.fetchone()[0]
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE)
                    """, (mat_id, Decimal(str(price)), Decimal(str(quantity)), Decimal(str(quantity))))
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (mat_id, Decimal(str(quantity))))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка добавления материала: {e}")
            return False

    @Slot(str, result=bool)
    def parseAndAddMaterial(self, url):
        try:
            from backend.models.scraper import quick_add_product
            quick_add_product(url)
            return True
        except Exception as e:
            print(f"Ошибка парсинга: {e}")
            return False

    @Slot(int, float, str, result=bool)
    def adjustInventory(self, material_id, new_qty, reason):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT quantity FROM material_inventory WHERE material_id = %s", (material_id,))
                    old_qty = cur.fetchone()
                    old_qty = old_qty[0] if old_qty else Decimal('0')
                    diff = Decimal(str(new_qty)) - old_qty
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE SET quantity = EXCLUDED.quantity
                    """, (material_id, new_qty))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type)
                        VALUES (%s, %s, 'adjustment')
                    """, (material_id, diff))
                    cur.execute("""
                        INSERT INTO inventory_adjustments (material_id, old_quantity, new_quantity, difference, reason)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (material_id, old_qty, new_qty, diff, reason))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка инвентаризации: {e}")
            return False

    @Slot(result="QVariantList")
    def getMaterialsList(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, name FROM materials ORDER BY name")
                rows = cur.fetchall()
        return [{"id": row[0], "name": row[1]} for row in rows]

    # ---------- Инструменты ----------
    @Slot(str, str, float, int, str, result=bool)
    def addTool(self, name, inv_num, cost, life_months, notes):
        try:
            monthly = Decimal(str(cost)) / life_months if life_months else None
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO tools (name, inventory_number, purchase_date, purchase_cost,
                                           useful_life_months, monthly_depreciation, residual_value, notes)
                        VALUES (%s, %s, CURRENT_DATE, %s, %s, %s, %s, %s)
                    """, (name, inv_num if inv_num else None, Decimal(str(cost)), life_months,
                          monthly, Decimal(str(cost)), notes if notes else None))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка добавления инструмента: {e}")
            return False

    @Slot(result="QVariantList")
    def getToolsList(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, name FROM tools WHERE status = 'active' ORDER BY name")
                rows = cur.fetchall()
        return [{"id": row[0], "name": row[1]} for row in rows]

    @Slot(int, str, result=bool)
    def writeOffTool(self, tool_id, reason):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT residual_value FROM tools WHERE id = %s", (tool_id,))
                    residual = cur.fetchone()[0]
                    cur.execute("""
                        INSERT INTO tool_depreciation (tool_id, amount, notes)
                        VALUES (%s, %s, %s)
                    """, (tool_id, residual, f"Списание: {reason}"))
                    cur.execute("UPDATE tools SET residual_value = 0, status = 'written_off' WHERE id = %s", (tool_id,))
                    cur.execute("""
                        INSERT INTO balance (date, expense, notes)
                        VALUES (CURRENT_DATE, %s, %s)
                    """, (residual, f"Списание инструмента: {reason}"))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка списания инструмента: {e}")
            return False

    @Slot(int, float, result=bool)
    def depreciateTool(self, tool_id, amount):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    if amount <= 0:
                        cur.execute("SELECT monthly_depreciation FROM tools WHERE id = %s", (tool_id,))
                        monthly = cur.fetchone()[0]
                        if not monthly:
                            return False
                        amount = float(monthly)
                    cur.execute("SELECT residual_value FROM tools WHERE id = %s", (tool_id,))
                    residual = cur.fetchone()[0]
                    if amount > float(residual):
                        amount = float(residual)
                    cur.execute("""
                        INSERT INTO tool_depreciation (tool_id, amount, notes)
                        VALUES (%s, %s, 'Амортизация')
                    """, (tool_id, Decimal(str(amount))))
                    cur.execute("UPDATE tools SET residual_value = residual_value - %s WHERE id = %s",
                                (Decimal(str(amount)), tool_id))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка начисления амортизации: {e}")
            return False

    # ---------- Модели станков ----------
    @Slot(str, result=bool)
    def addMachineModel(self, model):
        try:
            from backend.models.machine import add_new_machine_gui
            return add_new_machine_gui(model)
        except Exception as e:
            print(f"Ошибка добавления модели: {e}")
            return False

    @Slot(int, int, float, result=bool)
    def addMaterialToMachine(self, machine_id, material_id, quantity):
        try:
            from backend.models.machine import add_material_to_machine_gui
            return add_material_to_machine_gui(machine_id, material_id, Decimal(str(quantity)))
        except Exception as e:
            print(f"Ошибка добавления материала: {e}")
            return False

    @Slot(int, int, result=bool)
    def removeMaterialFromMachine(self, machine_id, material_id):
        try:
            from backend.models.machine import remove_material_from_machine_gui
            return remove_material_from_machine_gui(machine_id, material_id)
        except Exception as e:
            print(f"Ошибка удаления материала: {e}")
            return False

    @Slot(int, int, float, result=bool)
    def updateMaterialInMachine(self, machine_id, material_id, quantity):
        try:
            from backend.models.machine import edit_material_quantity_in_machine_gui
            return edit_material_quantity_in_machine_gui(machine_id, material_id, Decimal(str(quantity)))
        except Exception as e:
            print(f"Ошибка изменения количества: {e}")
            return False

    @Slot(int, result=bool)
    def deleteMachineModel(self, machine_id):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # Проверяем что нет станков в производстве с этой моделью
                    cur.execute("""
                        SELECT COUNT(*) FROM finished_goods 
                        WHERE machine_id = %s AND status IN ('in_progress', 'completed')
                    """, (machine_id,))
                    count = cur.fetchone()[0]
                    if count > 0:
                        print(f"Нельзя удалить модель: есть {count} станков в производстве/на складе")
                        return False
                
                # Удаляем модель (каскадно удалятся machine_materials, machine_tools, machine_labor_costs)
                    cur.execute("DELETE FROM machines WHERE id = %s", (machine_id,))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка удаления модели: {e}")
            return False

    @Slot(int, int, str, result=bool)
    def produceMachine(self, machine_id, quantity, notes):
        try:
            from backend.models.production import produce_machine_gui
            return produce_machine_gui(machine_id, quantity, notes)
        except Exception as e:
            print(f"Ошибка производства: {e}")
            return False

    @Slot(int, float, str, result=bool)
    def sellFinishedGood(self, finished_good_id, sale_price, buyer):
        try:
            from backend.models.production import sell_finished_good_gui
            return sell_finished_good_gui(finished_good_id, Decimal(str(sale_price)), buyer)
        except Exception as e:
            print(f"Ошибка продажи: {e}")
            return False

    @Slot(int, int, str, result=bool)
    def startProduction(self, machine_id, quantity, notes):
        try:
            from backend.models.production import start_production_gui
            return start_production_gui(machine_id, quantity, notes)
        except Exception as e:
            print(f"Ошибка начала производства: {e}")
            return False

    @Slot(int, str, result=bool)
    def completeMachine(self, finished_good_id, inventory_number):
        try:
            from backend.models.production import set_machine_completed
            set_machine_completed(finished_good_id, inventory_number)
            return True
        except Exception as e:
            print(f"Ошибка завершения производства: {e}")
            return False

    # ---------- Финансы и аналитика ----------
    @Slot(result=str)
    def getTotalAssets(self):
        try:
            from backend.models.analytics import get_total_assets
            return f"{get_total_assets():.2f}"
        except Exception as e:
            print(f"Ошибка получения активов: {e}")
            return "0.00"

    @Slot(str, str, result=str)
    def getMonthlyRevenue(self, start_date_str, end_date_str):
        try:
            from datetime import datetime, date
            start = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else date.today().replace(day=1)
            end = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else date.today()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT COALESCE(SUM(sale_price), 0) FROM sales WHERE sale_date BETWEEN %s AND %s", (start, end))
                    revenue = cur.fetchone()[0]
            return f"{revenue:.2f}"
        except Exception as e:
            print(f"Ошибка расчёта выручки: {e}")
            return "0.00"

    @Slot(str, str, result=str)
    def getMonthlyProfit(self, start_date_str, end_date_str):
        try:
            from datetime import datetime, date
            start = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else date.today().replace(day=1)
            end = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else date.today()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT COALESCE(SUM(profit), 0) FROM sales WHERE sale_date BETWEEN %s AND %s", (start, end))
                    profit = cur.fetchone()[0]
            return f"{profit:.2f}"
        except Exception as e:
            print(f"Ошибка расчёта прибыли: {e}")
            return "0.00"

    @Slot(str, str, result=str)
    def getProfitLossReport(self, start_date_str, end_date_str):
        try:
            from datetime import datetime, date
            start = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else date.today().replace(day=1)
            end = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else date.today()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT COALESCE(SUM(sale_price), 0) FROM sales WHERE sale_date BETWEEN %s AND %s", (start, end))
                    revenue = cur.fetchone()[0] or Decimal('0')
                    cur.execute("""
                        SELECT COALESCE(SUM(amount), 0) FROM tool_depreciation WHERE depreciation_date BETWEEN %s AND %s
                    """, (start, end))
                    tool_depr = cur.fetchone()[0] or Decimal('0')
                    cur.execute("""
                        SELECT COALESCE(SUM(hours * hourly_rate), 0)
                        FROM work_logs wl
                        JOIN employees e ON wl.employee_id = e.id
                        WHERE wl.date BETWEEN %s AND %s
                    """, (start, end))
                    salary = cur.fetchone()[0] or Decimal('0')
                    cur.execute("""
                        SELECT COALESCE(SUM(mt.quantity_change * lp.price_per_unit), 0)
                        FROM material_transactions mt
                        JOIN materials m ON mt.material_id = m.id
                        LEFT JOIN LATERAL (
                            SELECT price_per_unit FROM purchases
                            WHERE material_id = mt.material_id AND price_per_unit IS NOT NULL
                            ORDER BY purchase_date DESC LIMIT 1
                        ) lp ON true
                        WHERE mt.transaction_type = 'production'
                          AND mt.created_at::date BETWEEN %s AND %s
                    """, (start, end))
                    material_cost = abs(cur.fetchone()[0] or Decimal('0'))
                    total_expense = tool_depr + salary + material_cost
                    profit = revenue - total_expense
                    report = f"ОТЧЁТ О ПРИБЫЛЯХ И УБЫТКАХ\nПериод: {start} – {end}\n"
                    report += f"{'='*50}\n"
                    report += f"Доходы (продажи): {revenue:.2f} руб.\n"
                    report += f"Расходы:\n"
                    report += f"  - Материалы: {material_cost:.2f} руб.\n"
                    report += f"  - Зарплата: {salary:.2f} руб.\n"
                    report += f"  - Амортизация инструментов: {tool_depr:.2f} руб.\n"
                    report += f"  Итого расходов: {total_expense:.2f} руб.\n"
                    report += f"{'='*50}\n"
                    report += f"ЧИСТАЯ ПРИБЫЛЬ: {profit:.2f} руб.\n"
                    return report
        except Exception as e:
            print(f"Ошибка формирования отчёта: {e}")
            return "Ошибка при формировании отчёта"

    @Slot(str, str)
    def exportReportToExcel(self, start_date_str, end_date_str):
        try:
            from datetime import datetime, date
            import pandas as pd
            start = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else date.today().replace(day=1)
            end = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else date.today()
            with get_connection() as conn:
                df_sales = pd.read_sql_query("SELECT * FROM sales WHERE sale_date BETWEEN %s AND %s", conn, params=(start, end))
                df_production = pd.read_sql_query("SELECT * FROM finished_goods WHERE produced_date BETWEEN %s AND %s", conn, params=(start, end))
                filename = f"report_{start}_{end}.xlsx"
                with pd.ExcelWriter(filename) as writer:
                    df_sales.to_excel(writer, sheet_name="Продажи", index=False)
                    df_production.to_excel(writer, sheet_name="Производство", index=False)
            print(f"Отчёт сохранён в {filename}")
        except Exception as e:
            print(f"Ошибка экспорта: {e}")