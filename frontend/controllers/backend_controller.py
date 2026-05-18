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
    def _ensure_indirect_schema(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS start_date DATE")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS indirect_cost DECIMAL(12, 2) DEFAULT 0")
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS indirect_expense_categories (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        monthly_amount DECIMAL(12, 2) NOT NULL,
                        is_active BOOLEAN DEFAULT TRUE,
                        notes TEXT
                    )
                """)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS indirect_cost_allocations (
                        id SERIAL PRIMARY KEY,
                        category_id INT REFERENCES indirect_expense_categories(id) ON DELETE CASCADE,
                        finished_good_id INT REFERENCES finished_goods(id) ON DELETE CASCADE,
                        allocation_date DATE NOT NULL,
                        amount DECIMAL(12, 4) NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cur.execute("""
                    UPDATE finished_goods
                    SET start_date = COALESCE(start_date, produced_date, CURRENT_DATE)
                """)
            conn.commit()

    def _recalculate_months_for_machine(self, finished_good_id):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT COALESCE(start_date, produced_date, CURRENT_DATE), COALESCE(produced_date, CURRENT_DATE)
                    FROM finished_goods
                    WHERE id = %s
                """, (finished_good_id,))
                row = cur.fetchone()
        if not row:
            return
        start_date, end_date = row
        if end_date < start_date:
            end_date = start_date
        y, m = start_date.year, start_date.month
        while (y < end_date.year) or (y == end_date.year and m <= end_date.month):
            self.recalculateIndirectExpenses(f"{y:04d}-{m:02d}")
            m += 1
            if m > 12:
                y += 1
                m = 1

    # ---------- РЎС‚Р°РЅРєРё ----------
    @Slot(str, result=str)
    def calculate_cost(self, machine_id):
        try:
            cost = calculate_machine_cost_from_purchases(int(machine_id))
            return f"{cost:.2f}"
        except Exception as e:
            print(f"РћС€РёР±РєР° СЂР°СЃС‡С‘С‚Р° СЃС‚РѕРёРјРѕСЃС‚Рё: {e}")
            return "0.00"

    @Slot(result="QVariantList")
    def get_machines(self):
        machines = list_machines()
        return [{"id": m[0], "model": m[1], "cost": float(m[2]) if m[2] else 0.0} for m in machines]

    # ---------- РЎРѕС‚СЂСѓРґРЅРёРєРё ----------
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
            print(f"РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЃРѕС‚СЂСѓРґРЅРёРєР°: {e}")
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
            print(f"РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ СЃРѕС‚СЂСѓРґРЅРёРєР°: {e}")
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
            print(f"РћС€РёР±РєР° РёР·РјРµРЅРµРЅРёСЏ СЃС‚Р°С‚СѓСЃР°: {e}")
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
                lines.append(f"{name}: {hours:.2f} С‡ Г— {rate:.2f} = {amount:.2f} СЂСѓР±.")
            lines.append(f"РРўРћР“Рћ: {total:.2f} СЂСѓР±.")
            return "\n".join(lines)
        except Exception as e:
            print(f"РћС€РёР±РєР° СЂР°СЃС‡С‘С‚Р° Р·Р°СЂРїР»Р°С‚С‹: {e}")
            return "РћС€РёР±РєР° СЂР°СЃС‡С‘С‚Р°"

    # ---------- Р“РѕС‚РѕРІС‹Рµ СЃС‚Р°РЅРєРё ----------
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
        return [{"id": row[0], "display": f"{row[1]} (ID {row[0]}, {row[2]:.2f} СЂСѓР±.)"} for row in rows]

    @Slot(result="QVariantList")
    def getInProgressMachinesList(self):
        """Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃРїРёСЃРѕРє СЃС‚Р°РЅРєРѕРІ РІ Р°РєС‚РёРІРЅРѕРј РїСѓР»Рµ (СЃС‚Р°С‚СѓСЃ 'in_progress')."""
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
                "display": f"{row[1]} (ID {row[0]}, РЅР°С‡Р°С‚ {row[2]})"
            } 
            for row in rows
        ]

    # ---------- РЈС‡С‘С‚ СЂР°Р±РѕС‡РµРіРѕ РІСЂРµРјРµРЅРё ----------
    @Slot(int, int, float, str, result=bool)
    def logWorkHours(self, employee_id, finished_good_id, hours, notes):
        try:
            add_labor_to_finished_good(finished_good_id, employee_id, Decimal(str(hours)), notes)
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° Р·Р°РїРёСЃРё С‡Р°СЃРѕРІ: {e}")
            return False

    # ---------- РЎРєР»Р°РґСЃРєРёРµ СЃРІРѕРґРєРё ----------
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
                    "amount": f"{t.get('amount', 0):.2f} СЂСѓР±." if t.get('amount') else ""
                })
            return result
        except Exception as e:
            print(f"РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С‚СЂР°РЅР·Р°РєС†РёР№: {e}")
            return []

    # ---------- РњР°С‚РµСЂРёР°Р»С‹ ----------
    @Slot(str, str, float, float, str, str, result=bool)
    def addMaterial(self, name, unit, price, quantity, source, notes):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("""
                        INSERT INTO materials (name, unit, source, notes)
                        VALUES (%s, %s, NULLIF(%s, ''), NULLIF(%s, ''))
                        ON CONFLICT (name) DO UPDATE SET
                            unit = EXCLUDED.unit,
                            source = COALESCE(EXCLUDED.source, materials.source),
                            notes = COALESCE(EXCLUDED.notes, materials.notes)
                        RETURNING id
                    """, (name, unit, source, notes))
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
            print(f"РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РјР°С‚РµСЂРёР°Р»Р°: {e}")
            return False

    @Slot(str, result=bool)
    def parseAndAddMaterial(self, url):
        try:
            from backend.models.scraper import quick_add_product
            quick_add_product(url, notes=url)
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° РїР°СЂСЃРёРЅРіР°: {e}")
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
            print(f"РћС€РёР±РєР° РёРЅРІРµРЅС‚Р°СЂРёР·Р°С†РёРё: {e}")
            return False

    @Slot(result="QVariantList")
    def getMaterialsList(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, name FROM materials ORDER BY name")
                rows = cur.fetchall()
        return [{"id": row[0], "name": row[1]} for row in rows]

    @Slot(int, float, str, result=bool)
    def updateMaterialUnitPrice(self, material_id, new_price, note):
        try:
            if new_price <= 0:
                return False
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                        VALUES (%s, %s, 0, 0, CURRENT_DATE, %s)
                    """, (material_id, Decimal(str(new_price)), note if note else "РћР±РЅРѕРІР»РµРЅРёРµ С†РµРЅС‹ Р·Р° РµРґРёРЅРёС†Сѓ"))
                    conn.commit()
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ С†РµРЅС‹ РјР°С‚РµСЂРёР°Р»Р°: {e}")
            return False

    # ---------- РРЅСЃС‚СЂСѓРјРµРЅС‚С‹ ----------
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
            print(f"РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РёРЅСЃС‚СЂСѓРјРµРЅС‚Р°: {e}")
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
                    """, (tool_id, residual, f"РЎРїРёСЃР°РЅРёРµ: {reason}"))
                    cur.execute("UPDATE tools SET residual_value = 0, status = 'written_off' WHERE id = %s", (tool_id,))
                    cur.execute("""
                        INSERT INTO balance (date, expense, notes)
                        VALUES (CURRENT_DATE, %s, %s)
                    """, (residual, f"РЎРїРёСЃР°РЅРёРµ РёРЅСЃС‚СЂСѓРјРµРЅС‚Р°: {reason}"))
                    conn.commit()
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° СЃРїРёСЃР°РЅРёСЏ РёРЅСЃС‚СЂСѓРјРµРЅС‚Р°: {e}")
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
                        VALUES (%s, %s, 'РђРјРѕСЂС‚РёР·Р°С†РёСЏ')
                    """, (tool_id, Decimal(str(amount))))
                    cur.execute("UPDATE tools SET residual_value = residual_value - %s WHERE id = %s",
                                (Decimal(str(amount)), tool_id))
                    conn.commit()
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° РЅР°С‡РёСЃР»РµРЅРёСЏ Р°РјРѕСЂС‚РёР·Р°С†РёРё: {e}")
            return False

    # ---------- РњРѕРґРµР»Рё СЃС‚Р°РЅРєРѕРІ ----------
    @Slot(str, result=bool)
    def addMachineModel(self, model):
        try:
            from backend.models.machine import add_new_machine_gui
            return add_new_machine_gui(model)
        except Exception as e:
            print(f"РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РјРѕРґРµР»Рё: {e}")
            return False

    @Slot(int, int, float, result=bool)
    def addMaterialToMachine(self, machine_id, material_id, quantity):
        try:
            from backend.models.machine import add_material_to_machine_gui
            return add_material_to_machine_gui(machine_id, material_id, Decimal(str(quantity)))
        except Exception as e:
            print(f"РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РјР°С‚РµСЂРёР°Р»Р°: {e}")
            return False

    @Slot(int, int, result=bool)
    def removeMaterialFromMachine(self, machine_id, material_id):
        try:
            from backend.models.machine import remove_material_from_machine_gui
            return remove_material_from_machine_gui(machine_id, material_id)
        except Exception as e:
            print(f"РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РјР°С‚РµСЂРёР°Р»Р°: {e}")
            return False

    @Slot(int, int, float, result=bool)
    def updateMaterialInMachine(self, machine_id, material_id, quantity):
        try:
            from backend.models.machine import edit_material_quantity_in_machine_gui
            return edit_material_quantity_in_machine_gui(machine_id, material_id, Decimal(str(quantity)))
        except Exception as e:
            print(f"РћС€РёР±РєР° РёР·РјРµРЅРµРЅРёСЏ РєРѕР»РёС‡РµСЃС‚РІР°: {e}")
            return False

    @Slot(int, result=bool)
    def deleteMachineModel(self, machine_id):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РЅРµС‚ СЃС‚Р°РЅРєРѕРІ РІ РїСЂРѕРёР·РІРѕРґСЃС‚РІРµ СЃ СЌС‚РѕР№ РјРѕРґРµР»СЊСЋ
                    cur.execute("""
                        SELECT COUNT(*) FROM finished_goods 
                        WHERE machine_id = %s AND status IN ('in_progress', 'completed')
                    """, (machine_id,))
                    count = cur.fetchone()[0]
                    if count > 0:
                        print(f"РќРµР»СЊР·СЏ СѓРґР°Р»РёС‚СЊ РјРѕРґРµР»СЊ: РµСЃС‚СЊ {count} СЃС‚Р°РЅРєРѕРІ РІ РїСЂРѕРёР·РІРѕРґСЃС‚РІРµ/РЅР° СЃРєР»Р°РґРµ")
                        return False
                
                # РЈРґР°Р»СЏРµРј РјРѕРґРµР»СЊ (РєР°СЃРєР°РґРЅРѕ СѓРґР°Р»СЏС‚СЃСЏ machine_materials, machine_tools, machine_labor_costs)
                    cur.execute("DELETE FROM machines WHERE id = %s", (machine_id,))
                    conn.commit()
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РјРѕРґРµР»Рё: {e}")
            return False

    @Slot(int, int, str, result=bool)
    def produceMachine(self, machine_id, quantity, notes):
        try:
            from backend.models.production import produce_machine_gui
            return produce_machine_gui(machine_id, quantity, notes)
        except Exception as e:
            print(f"РћС€РёР±РєР° РїСЂРѕРёР·РІРѕРґСЃС‚РІР°: {e}")
            return False

    @Slot(int, float, str, result=bool)
    def sellFinishedGood(self, finished_good_id, sale_price, buyer):
        try:
            from backend.models.production import sell_finished_good_gui
            return sell_finished_good_gui(finished_good_id, Decimal(str(sale_price)), buyer)
        except Exception as e:
            print(f"РћС€РёР±РєР° РїСЂРѕРґР°Р¶Рё: {e}")
            return False

    @Slot(int, int, str, result=bool)
    def startProduction(self, machine_id, quantity, notes):
        try:
            from backend.models.production import start_production_gui
            ok = start_production_gui(machine_id, quantity, notes)
            if ok:
                from datetime import date
                self.recalculateIndirectExpenses(date.today().strftime("%Y-%m"))
            return ok
        except Exception as e:
            print(f"РћС€РёР±РєР° РЅР°С‡Р°Р»Р° РїСЂРѕРёР·РІРѕРґСЃС‚РІР°: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, str, result=bool)
    def completeMachine(self, finished_good_id, inventory_number):
        try:
            from backend.models.production import complete_machine_with_material_deduction
            ok = complete_machine_with_material_deduction(finished_good_id, inventory_number)
            if ok:
                self._recalculate_months_for_machine(finished_good_id)
            return ok
        except Exception as e:
            print(f"РћС€РёР±РєР° Р·Р°РІРµСЂС€РµРЅРёСЏ РїСЂРѕРёР·РІРѕРґСЃС‚РІР°: {e}")
            import traceback
            traceback.print_exc()
            return False

    # ---------- Р¤РёРЅР°РЅСЃС‹ Рё Р°РЅР°Р»РёС‚РёРєР° ----------
    @Slot(result=str)
    def getTotalAssets(self):
        try:
            from backend.models.analytics import get_total_assets
            return f"{get_total_assets():.2f}"
        except Exception as e:
            print(f"РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р°РєС‚РёРІРѕРІ: {e}")
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
            print(f"РћС€РёР±РєР° СЂР°СЃС‡С‘С‚Р° РІС‹СЂСѓС‡РєРё: {e}")
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
            print(f"РћС€РёР±РєР° СЂР°СЃС‡С‘С‚Р° РїСЂРёР±С‹Р»Рё: {e}")
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
                    report = f"РћРўР§РЃРў Рћ РџР РР‘Р«Р›РЇРҐ Р РЈР‘Р«РўРљРђРҐ\nРџРµСЂРёРѕРґ: {start} вЂ“ {end}\n"
                    report += f"{'='*50}\n"
                    report += f"Р”РѕС…РѕРґС‹ (РїСЂРѕРґР°Р¶Рё): {revenue:.2f} СЂСѓР±.\n"
                    report += f"Р Р°СЃС…РѕРґС‹:\n"
                    report += f"  - РњР°С‚РµСЂРёР°Р»С‹: {material_cost:.2f} СЂСѓР±.\n"
                    report += f"  - Р—Р°СЂРїР»Р°С‚Р°: {salary:.2f} СЂСѓР±.\n"
                    report += f"  - РђРјРѕСЂС‚РёР·Р°С†РёСЏ РёРЅСЃС‚СЂСѓРјРµРЅС‚РѕРІ: {tool_depr:.2f} СЂСѓР±.\n"
                    report += f"  РС‚РѕРіРѕ СЂР°СЃС…РѕРґРѕРІ: {total_expense:.2f} СЂСѓР±.\n"
                    report += f"{'='*50}\n"
                    report += f"Р§РРЎРўРђРЇ РџР РР‘Р«Р›Р¬: {profit:.2f} СЂСѓР±.\n"
                    return report
        except Exception as e:
            print(f"РћС€РёР±РєР° С„РѕСЂРјРёСЂРѕРІР°РЅРёСЏ РѕС‚С‡С‘С‚Р°: {e}")
            return "РћС€РёР±РєР° РїСЂРё С„РѕСЂРјРёСЂРѕРІР°РЅРёРё РѕС‚С‡С‘С‚Р°"

    @Slot(result="QVariantList")
    def getSoldMachinesList(self):
        """Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃРїРёСЃРѕРє РїСЂРѕРґР°РЅРЅС‹С… СЃС‚Р°РЅРєРѕРІ СЃ РїСЂРёР±С‹Р»СЊСЋ."""
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT 
                        fg.id,
                        fg.machine_model,
                        fg.inventory_number,
                        fg.sale_date,
                        fg.buyer,
                        s.sale_price,
                        s.profit
                    FROM finished_goods fg
                    JOIN sales s ON fg.id = s.finished_good_id
                    WHERE fg.status = 'sold'
                    ORDER BY fg.sale_date DESC
                """)
                rows = cur.fetchall()
        return [
            {
                "id": r[0],
                "machine_model": r[1],
                "inv_num": r[2],
                "sale_date": str(r[3]) if r[3] else None,
                "buyer": r[4],
                "sale_price": float(r[5]) if r[5] else 0.0,
                "profit": float(r[6]) if r[6] else 0.0
            }
            for r in rows
        ]

    @Slot(int, float, str, str, str, result=bool)
    def sellFinishedGoodExtended(self, finished_good_id, sale_price, buyer, inv_number, sale_date):
        """Р Р°СЃС€РёСЂРµРЅРЅР°СЏ РІРµСЂСЃРёСЏ РїСЂРѕРґР°Р¶Рё СЃ РёРЅРІ. РЅРѕРјРµСЂРѕРј Рё РґР°С‚РѕР№."""
        try:
            from datetime import datetime, date
            
            # РћР±СЂР°Р±РѕС‚РєР° РґР°С‚С‹
            if sale_date:
                try:
                    sale_date_obj = datetime.strptime(sale_date, "%Y-%m-%d").date()
                except:
                    sale_date_obj = date.today()
            else:
                sale_date_obj = date.today()

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT cost_price FROM finished_goods WHERE id = %s", (finished_good_id,))
                    cost_row = cur.fetchone()
                    if not cost_row:
                        print("РЎС‚Р°РЅРѕРє РЅРµ РЅР°Р№РґРµРЅ")
                        return False
                    
                    cost = cost_row[0]  # Decimal РёР· Р‘Р”
                    sale_price_decimal = Decimal(str(sale_price))  # в†ђ РРЎРџР РђР’Р›Р•РќРР•
                    profit = sale_price_decimal - cost  # РўРµРїРµСЂСЊ РѕР±Р° Decimal

                    cur.execute("""
                        INSERT INTO sales (finished_good_id, sale_price, profit, sale_date)
                        VALUES (%s, %s, %s, %s)
                    """, (finished_good_id, sale_price_decimal, profit, sale_date_obj))

                    cur.execute("""
                        UPDATE finished_goods
                        SET status = 'sold', 
                            buyer = %s, 
                            sale_date = %s,
                            inventory_number = COALESCE(%s, inventory_number)
                        WHERE id = %s
                    """, (buyer, sale_date_obj, inv_number if inv_number else None, finished_good_id))

                    cur.execute("""
                        INSERT INTO balance (date, income, notes)
                        VALUES (%s, %s, %s)
                    """, (sale_date_obj, sale_price_decimal, f"РџСЂРѕРґР°Р¶Р° СЃС‚Р°РЅРєР° ID {finished_good_id} РїРѕРєСѓРїР°С‚РµР»СЋ {buyer}"))

                    conn.commit()
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° РїСЂРѕРґР°Р¶Рё: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, result="QVariantMap")
    def getMachineCostDetails(self, finished_good_id):
        """Р’РѕР·РІСЂР°С‰Р°РµС‚ РґРµС‚Р°Р»СЊРЅСѓСЋ СЂР°Р·Р±РёРІРєСѓ СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚Рё СЃС‚Р°РЅРєР°."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РћСЃРЅРѕРІРЅР°СЏ РёРЅС„РѕСЂРјР°С†РёСЏ
                    cur.execute("""
                        SELECT machine_model, cost_price, produced_date, machine_id
                        FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    fg = cur.fetchone()
                    if not fg:
                        return {"header": "РЎС‚Р°РЅРѕРє РЅРµ РЅР°Р№РґРµРЅ", "breakdown": ""}

                    model, total_cost, prod_date, machine_id = fg
                    header = f"РЎС‚Р°РЅРѕРє: {model} (ID {finished_good_id})\nРћР±С‰Р°СЏ СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ: {total_cost:.2f} в‚Ѕ"

                    breakdown = f"РџСЂРѕРёР·РІРµРґС‘РЅ: {prod_date}\n\n"
                    breakdown += "=" * 60 + "\n"
                    breakdown += "Р РђР—Р‘РР’РљРђ РЎР•Р‘Р•РЎРўРћРРњРћРЎРўР\n"
                    breakdown += "=" * 60 + "\n\n"

                    # РњР°С‚РµСЂРёР°Р»С‹
                    cur.execute("""
                        WITH latest_prices AS (
                            SELECT DISTINCT ON (material_id) material_id, price_per_unit
                            FROM purchases WHERE price_per_unit IS NOT NULL
                            ORDER BY material_id, purchase_date DESC
                        )
                        SELECT m.name, mm.quantity, lp.price_per_unit, (mm.quantity * lp.price_per_unit) as total
                        FROM machine_materials mm
                        JOIN materials m ON mm.material_id = m.id
                        LEFT JOIN latest_prices lp ON mm.material_id = lp.material_id
                        WHERE mm.machine_id = %s
                        ORDER BY total DESC
                    """, (machine_id,))
                    materials = cur.fetchall()
                    
                    materials_total = Decimal('0')
                    breakdown += "РњРђРўР•Р РРђР›Р«:\n"
                    breakdown += "-" * 60 + "\n"
                    for name, qty, price, total in materials:
                        if price:
                            breakdown += f"{name:<35} {qty:>8.2f} Г— {price:>8.2f} = {total:>10.2f} в‚Ѕ\n"
                            materials_total += total
                    breakdown += "-" * 60 + "\n"
                    breakdown += f"{'РРўРћР“Рћ РњРђРўР•Р РРђР›Р«:':<52} {materials_total:>10.2f} в‚Ѕ\n\n"

                    # РўСЂСѓРґРѕР·Р°С‚СЂР°С‚С‹
                    cur.execute("""
                        SELECT e.name, wl.hours, e.hourly_rate, (wl.hours * e.hourly_rate) as cost
                        FROM work_logs wl
                        JOIN employees e ON wl.employee_id = e.id
                        JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                        WHERE fgl.finished_good_id = %s
                        ORDER BY cost DESC
                    """, (finished_good_id,))
                    labor = cur.fetchall()

                    labor_total = Decimal('0')
                    if labor:
                        breakdown += "РўР РЈР”РћР—РђРўР РђРўР«:\n"
                        breakdown += "-" * 60 + "\n"
                        for emp_name, hours, rate, cost in labor:
                            breakdown += f"{emp_name:<35} {hours:>8.2f} С‡ Г— {rate:>8.2f} = {cost:>10.2f} в‚Ѕ\n"
                            labor_total += cost
                        breakdown += "-" * 60 + "\n"
                        breakdown += f"{'РРўРћР“Рћ Р РђР‘РћРўРђ:':<52} {labor_total:>10.2f} в‚Ѕ\n\n"

                    # РђРјРѕСЂС‚РёР·Р°С†РёСЏ РёРЅСЃС‚СЂСѓРјРµРЅС‚РѕРІ
                    cur.execute("""
                        SELECT t.name, td.amount
                        FROM tool_depreciation td
                        JOIN tools t ON td.tool_id = t.id
                        WHERE td.finished_good_id = %s
                    """, (finished_good_id,))
                    tools_depr = cur.fetchall()

                    tools_total = Decimal('0')
                    if tools_depr:
                        breakdown += "РђРњРћР РўРР—РђР¦РРЇ РРќРЎРўР РЈРњР•РќРўРћР’:\n"
                        breakdown += "-" * 60 + "\n"
                        for tool_name, amount in tools_depr:
                            breakdown += f"{tool_name:<52} {amount:>10.2f} в‚Ѕ\n"
                            tools_total += amount
                        breakdown += "-" * 60 + "\n"
                        breakdown += f"{'РРўРћР“Рћ РђРњРћР РўРР—РђР¦РРЇ:':<52} {tools_total:>10.2f} в‚Ѕ\n\n"

                    # Косвенные расходы
                    cur.execute("""
                        SELECT c.name, a.allocation_date, a.amount
                        FROM indirect_cost_allocations a
                        JOIN indirect_expense_categories c ON c.id = a.category_id
                        WHERE a.finished_good_id = %s
                        ORDER BY a.allocation_date, c.name
                    """, (finished_good_id,))
                    indirect_rows = cur.fetchall()
                    indirect_total = Decimal('0')
                    if indirect_rows:
                        breakdown += "КОСВЕННЫЕ РАСХОДЫ:\n"
                        breakdown += "-" * 60 + "\n"
                        for cat_name, alloc_date, amount in indirect_rows:
                            breakdown += f"{str(alloc_date):<12} {cat_name:<38} {amount:>10.2f} ₽\n"
                            indirect_total += amount
                        breakdown += "-" * 60 + "\n"
                        breakdown += f"{'ИТОГО КОСВЕННЫЕ:':<52} {indirect_total:>10.2f} ₽\n\n"

                    breakdown += "=" * 60 + "\n"
                    calculated_total = materials_total + labor_total + tools_total + indirect_total
                    breakdown += f"{'Р РђРЎР§РЃРўРќРђРЇ РЎР•Р‘Р•РЎРўРћРРњРћРЎРўР¬:':<52} {calculated_total:>10.2f} в‚Ѕ\n"
                    breakdown += f"{'Р—РђРџРРЎРђРќРћ Р’ Р‘Р”:':<52} {total_cost:>10.2f} в‚Ѕ\n"
                    
                    diff = total_cost - calculated_total
                    if abs(diff) > Decimal('0.01'):
                        breakdown += f"{'Р РђР—РќРР¦Рђ:':<52} {diff:>10.2f} в‚Ѕ\n"

                    return {"header": header, "breakdown": breakdown}

        except Exception as e:
            print(f"РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РґРµС‚Р°Р»РµР№: {e}")
            return {"header": "РћС€РёР±РєР°", "breakdown": str(e)}

    @Slot(int, result=bool)
    def returnMachineToStock(self, finished_good_id):
        """Р’РѕР·РІСЂР°С‰Р°РµС‚ РїСЂРѕРґР°РЅРЅС‹Р№ СЃС‚Р°РЅРѕРє РЅР° СЃРєР»Р°Рґ, СѓРґР°Р»СЏРµС‚ Р·Р°РїРёСЃСЊ Рѕ РїСЂРѕРґР°Р¶Рµ."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ СЃС‚Р°РЅРѕРє РґРµР№СЃС‚РІРёС‚РµР»СЊРЅРѕ РїСЂРѕРґР°РЅ
                    cur.execute("""
                        SELECT status FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row or row[0] != 'sold':
                        print("РЎС‚Р°РЅРѕРє РЅРµ РЅР°Р№РґРµРЅ РёР»Рё РЅРµ РїСЂРѕРґР°РЅ")
                        return False

                    # РЈРґР°Р»СЏРµРј Р·Р°РїРёСЃСЊ Рѕ РїСЂРѕРґР°Р¶Рµ
                    cur.execute("""
                        DELETE FROM sales WHERE finished_good_id = %s
                    """, (finished_good_id,))

                    # Р’РѕР·РІСЂР°С‰Р°РµРј СЃС‚Р°РЅРѕРє РЅР° СЃРєР»Р°Рґ
                    cur.execute("""
                        UPDATE finished_goods
                        SET status = 'completed',
                            buyer = NULL,
                            sale_date = NULL
                        WHERE id = %s
                    """, (finished_good_id,))

                    # РЈРґР°Р»СЏРµРј Р·Р°РїРёСЃСЊ РёР· Р±Р°Р»Р°РЅСЃР° (РµСЃР»Рё РµСЃС‚СЊ)
                    cur.execute("""
                        DELETE FROM balance 
                        WHERE notes LIKE %s
                    """, (f"%СЃС‚Р°РЅРєР° ID {finished_good_id}%",))

                    conn.commit()
                    print(f"РЎС‚Р°РЅРѕРє ID {finished_good_id} РІРѕР·РІСЂР°С‰С‘РЅ РЅР° СЃРєР»Р°Рґ")
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° РІРѕР·РІСЂР°С‚Р° РЅР° СЃРєР»Р°Рґ: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(str, str, int, result="QVariantList")
    def getWorkHistory(self, date_from, date_to, employee_id=None):
        """Р’РѕР·РІСЂР°С‰Р°РµС‚ РёСЃС‚РѕСЂРёСЋ СЂР°Р±РѕС‚С‹ СЃ С„РёР»СЊС‚СЂР°С†РёРµР№."""
        try:
            from datetime import datetime, date
            
            if date_from:
                start_date = datetime.strptime(date_from, "%Y-%m-%d").date()
            else:
                today = date.today()
                start_date = today.replace(day=1)
                
            if date_to:
                end_date = datetime.strptime(date_to, "%Y-%m-%d").date()
            else:
                end_date = date.today()

            with get_connection() as conn:
                with conn.cursor() as cur:
                    if employee_id and employee_id > 0:
                        cur.execute("""
                            SELECT 
                                wl.id,
                                wl.date,
                                e.name,
                                fg.machine_model,
                                wl.hours,
                                e.hourly_rate,
                                (wl.hours * e.hourly_rate) as cost
                            FROM work_logs wl
                            JOIN employees e ON wl.employee_id = e.id
                            LEFT JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                            LEFT JOIN finished_goods fg ON fgl.finished_good_id = fg.id
                            WHERE wl.date BETWEEN %s AND %s
                            AND wl.employee_id = %s
                            ORDER BY wl.date DESC, wl.id DESC
                        """, (start_date, end_date, employee_id))
                    else:
                        cur.execute("""
                            SELECT 
                                wl.id,
                                wl.date,
                                e.name,
                                fg.machine_model,
                                wl.hours,
                                e.hourly_rate,
                                (wl.hours * e.hourly_rate) as cost
                            FROM work_logs wl
                            JOIN employees e ON wl.employee_id = e.id
                            LEFT JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                            LEFT JOIN finished_goods fg ON fgl.finished_good_id = fg.id
                            WHERE wl.date BETWEEN %s AND %s
                            ORDER BY wl.date DESC, wl.id DESC
                        """, (start_date, end_date))
                    
                    rows = cur.fetchall()
                    
            return [
                {
                    "work_log_id": r[0],
                    "date": str(r[1]),
                    "employee_name": r[2],
                    "machine_model": r[3],
                    "hours": float(r[4]),
                    "hourly_rate": float(r[5]),
                    "cost": float(r[6])
                }
                for r in rows
            ]
        except Exception as e:
            print(f"РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РёСЃС‚РѕСЂРёРё: {e}")
            return []

    @Slot(int, result=bool)
    def undoWorkLog(self, work_log_id):
        """РћС‚РјРµРЅСЏРµС‚ Р·Р°РїРёСЃСЊ Рѕ СЂР°Р±РѕС‚Рµ Рё РїРµСЂРµСЃС‡РёС‚С‹РІР°РµС‚ СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ СЃС‚Р°РЅРєР°."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РџРѕР»СѓС‡Р°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р·Р°РїРёСЃРё
                    cur.execute("""
                        SELECT e.hourly_rate, wl.hours, fgl.finished_good_id
                        FROM work_logs wl
                        JOIN employees e ON wl.employee_id = e.id
                        LEFT JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                        WHERE wl.id = %s
                    """, (work_log_id,))
                    
                    row = cur.fetchone()
                    if not row:
                        print("Р—Р°РїРёСЃСЊ РЅРµ РЅР°Р№РґРµРЅР°")
                        return False
                        
                    rate, hours, finished_good_id = row
                    cost_to_subtract = rate * hours
                    
                    # Р•СЃР»Рё РїСЂРёРІСЏР·Р°РЅРѕ Рє СЃС‚Р°РЅРєСѓ вЂ” СѓРјРµРЅСЊС€Р°РµРј СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ
                    if finished_good_id:
                        cur.execute("""
                            UPDATE finished_goods
                            SET cost_price = cost_price - %s
                            WHERE id = %s
                        """, (cost_to_subtract, finished_good_id))
                        
                        # РЈРґР°Р»СЏРµРј СЃРІСЏР·СЊ
                        cur.execute("""
                            DELETE FROM finished_good_labor
                            WHERE work_log_id = %s
                        """, (work_log_id,))
                    
                    # РЈРґР°Р»СЏРµРј СЃР°РјСѓ Р·Р°РїРёСЃСЊ
                    cur.execute("DELETE FROM work_logs WHERE id = %s", (work_log_id,))
                    
                    conn.commit()
                    print(f"Р—Р°РїРёСЃСЊ Рѕ СЂР°Р±РѕС‚Рµ ID {work_log_id} РѕС‚РјРµРЅРµРЅР°, СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ СѓРјРµРЅСЊС€РµРЅР° РЅР° {cost_to_subtract:.2f}")
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° РѕС‚РјРµРЅС‹ Р·Р°РїРёСЃРё: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, float, str, str, str, float, result=bool)
    def sellFinishedGoodWithShipping(self, finished_good_id, sale_price, buyer, inv_number, sale_date, shipping_cost):
        """РџСЂРѕРґР°Р¶Р° СЃ СѓС‡С‘С‚РѕРј С‚СЂР°РЅСЃРїРѕСЂС‚РёСЂРѕРІРєРё."""
        try:
            from datetime import datetime, date
            
            if sale_date:
                try:
                    sale_date_obj = datetime.strptime(sale_date, "%Y-%m-%d").date()
                except:
                    sale_date_obj = date.today()
            else:
                sale_date_obj = date.today()

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT cost_price FROM finished_goods WHERE id = %s", (finished_good_id,))
                    cost_row = cur.fetchone()
                    if not cost_row:
                        print("РЎС‚Р°РЅРѕРє РЅРµ РЅР°Р№РґРµРЅ")
                        return False
                    
                    cost = cost_row[0]
                    shipping_cost_decimal = Decimal(str(shipping_cost))
                    
                    # Р•СЃР»Рё РґРѕСЃС‚Р°РІРєР° РїР»Р°С‚РЅР°СЏ вЂ” РґРѕР±Р°РІР»СЏРµРј Рє СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚Рё
                    if shipping_cost_decimal > 0:
                        cur.execute("""
                            UPDATE finished_goods
                            SET cost_price = cost_price + %s
                            WHERE id = %s
                        """, (shipping_cost_decimal, finished_good_id))
                        final_cost = cost + shipping_cost_decimal
                    else:
                        final_cost = cost
                    
                    sale_price_decimal = Decimal(str(sale_price))
                    profit = sale_price_decimal - final_cost

                    cur.execute("""
                        INSERT INTO sales (finished_good_id, sale_price, profit, sale_date)
                        VALUES (%s, %s, %s, %s)
                    """, (finished_good_id, sale_price_decimal, profit, sale_date_obj))

                    cur.execute("""
                        UPDATE finished_goods
                        SET status = 'sold', 
                            buyer = %s, 
                            sale_date = %s,
                            inventory_number = COALESCE(%s, inventory_number)
                        WHERE id = %s
                    """, (buyer, sale_date_obj, inv_number if inv_number else None, finished_good_id))

                    notes = f"РџСЂРѕРґР°Р¶Р° СЃС‚Р°РЅРєР° ID {finished_good_id} РїРѕРєСѓРїР°С‚РµР»СЋ {buyer}"
                    if shipping_cost_decimal > 0:
                        notes += f" (РґРѕСЃС‚Р°РІРєР° {shipping_cost_decimal} в‚Ѕ РІРєР»СЋС‡РµРЅР° РІ СЃРµР±РµСЃС‚РѕРёРјРѕСЃС‚СЊ)"

                    cur.execute("""
                        INSERT INTO balance (date, income, notes)
                        VALUES (%s, %s, %s)
                    """, (sale_date_obj, sale_price_decimal, notes))

                    conn.commit()
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° РїСЂРѕРґР°Р¶Рё: {e}")
            import traceback
            traceback.print_exc()
        return False

    @Slot(int, result="QVariantList")
    def checkMaterialsForMachine(self, finished_good_id):
        """РџСЂРѕРІРµСЂСЏРµС‚ РЅР°Р»РёС‡РёРµ РјР°С‚РµСЂРёР°Р»РѕРІ РґР»СЏ Р·Р°РІРµСЂС€РµРЅРёСЏ РїСЂРѕРёР·РІРѕРґСЃС‚РІР° СЃС‚Р°РЅРєР°."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РџРѕР»СѓС‡Р°РµРј machine_id РёР· finished_goods
                    cur.execute("""
                        SELECT machine_id FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row or not row[0]:
                        return []
                    
                    machine_id = row[0]
                    
                    # РџСЂРѕРІРµСЂСЏРµРј РјР°С‚РµСЂРёР°Р»С‹
                    cur.execute("""
                        SELECT 
                            m.name,
                            mm.quantity AS required,
                            COALESCE(inv.quantity, 0) AS in_stock,
                            CASE 
                                WHEN COALESCE(inv.quantity, 0) >= mm.quantity THEN true
                                ELSE false
                            END AS available
                        FROM machine_materials mm
                        JOIN materials m ON mm.material_id = m.id
                        LEFT JOIN material_inventory inv ON mm.material_id = inv.material_id
                        WHERE mm.machine_id = %s
                        ORDER BY available ASC, m.name
                    """, (machine_id,))
                    
                    rows = cur.fetchall()
                    
                    return [
                        {
                            "material_name": r[0],
                            "required": float(r[1]),
                            "in_stock": float(r[2]),
                            "available": r[3]
                        }
                        for r in rows
                    ]
        except Exception as e:
            print(f"РћС€РёР±РєР° РїСЂРѕРІРµСЂРєРё РјР°С‚РµСЂРёР°Р»РѕРІ: {e}")
            import traceback
            traceback.print_exc()
            return []

    @Slot(int, result=str)
    def getDisassemblePreview(self, finished_good_id):
        """РџРѕРєР°Р·С‹РІР°РµС‚ РїСЂРµРґРїСЂРѕСЃРјРѕС‚СЂ С‡С‚Рѕ РІРµСЂРЅС‘С‚СЃСЏ РЅР° СЃРєР»Р°Рґ РїСЂРё СЂР°Р·Р±РѕСЂРєРµ."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РџРѕР»СѓС‡Р°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ СЃС‚Р°РЅРєРµ
                    cur.execute("""
                        SELECT machine_model, machine_id FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row:
                        return "РЎС‚Р°РЅРѕРє РЅРµ РЅР°Р№РґРµРЅ"
                    
                    model, machine_id = row
                    
                    preview = f"РЎС‚Р°РЅРѕРє: {model} (ID {finished_good_id})\n\n"
                    preview += "РњРђРўР•Р РРђР›Р«, РљРћРўРћР Р«Р• Р’Р•Р РќРЈРўРЎРЇ РќРђ РЎРљР›РђР”:\n"
                    preview += "=" * 60 + "\n"
                    
                    # РџРѕР»СѓС‡Р°РµРј РјР°С‚РµСЂРёР°Р»С‹ РёР· СЃРїРµС†РёС„РёРєР°С†РёРё
                    cur.execute("""
                        SELECT 
                            m.name,
                            mm.quantity,
                            COALESCE(inv.quantity, 0) as current_stock,
                            (mm.quantity + COALESCE(inv.quantity, 0)) as after_return
                        FROM machine_materials mm
                        JOIN materials m ON mm.material_id = m.id
                        LEFT JOIN material_inventory inv ON mm.material_id = inv.material_id
                        WHERE mm.machine_id = %s
                        ORDER BY m.name
                    """, (machine_id,))
                    
                    materials = cur.fetchall()
                    
                    if not materials:
                        preview += "РќРµС‚ РјР°С‚РµСЂРёР°Р»РѕРІ РґР»СЏ РІРѕР·РІСЂР°С‚Р°\n"
                    else:
                        preview += f"{'РњР°С‚РµСЂРёР°Р»':<35} {'Р’РµСЂРЅС‘С‚СЃСЏ':>10} {'РЎРµР№С‡Р°СЃ':>10} {'РЎС‚Р°РЅРµС‚':>10}\n"
                        preview += "-" * 60 + "\n"
                        
                        for name, qty, current, after in materials:
                            preview += f"{name:<35} {qty:>10.2f} {current:>10.2f} {after:>10.2f}\n"
                        
                        preview += "=" * 60 + "\n"
                    
                    # РРЅС„РѕСЂРјР°С†РёСЏ Рѕ СЂР°Р±РѕС‚Рµ (РЅРµ РІРµСЂРЅС‘С‚СЃСЏ)
                    cur.execute("""
                        SELECT SUM(wl.hours * e.hourly_rate)
                        FROM work_logs wl
                        JOIN employees e ON wl.employee_id = e.id
                        JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                        WHERE fgl.finished_good_id = %s
                    """, (finished_good_id,))
                    
                    labor_cost = cur.fetchone()[0] or Decimal('0')
                    
                    if labor_cost > 0:
                        preview += f"\nР’РќРРњРђРќРР•: Р—Р°С‚СЂР°С‚С‹ РЅР° СЂР°Р±РѕС‚Сѓ ({labor_cost:.2f} в‚Ѕ) РќР• РІРѕР·РјРµС‰Р°СЋС‚СЃСЏ!\n"
                    
                    preview += "\nРЎС‚Р°РЅРѕРє Р±СѓРґРµС‚ СѓРґР°Р»С‘РЅ РёР· Р±Р°Р·С‹ РґР°РЅРЅС‹С…."
                    
                    return preview
                    
        except Exception as e:
            print(f"РћС€РёР±РєР° РїСЂРµРґРїСЂРѕСЃРјРѕС‚СЂР° СЂР°Р·Р±РѕСЂРєРё: {e}")
            return f"РћС€РёР±РєР°: {str(e)}"

    @Slot(int, result=bool)
    def disassembleMachine(self, finished_good_id):
        """Р Р°Р·Р±РёСЂР°РµС‚ СЃС‚Р°РЅРѕРє Рё РІРѕР·РІСЂР°С‰Р°РµС‚ РјР°С‚РµСЂРёР°Р»С‹ РЅР° СЃРєР»Р°Рґ."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РџРѕР»СѓС‡Р°РµРј machine_id
                    cur.execute("""
                        SELECT machine_id FROM finished_goods WHERE id = %s AND status = 'completed'
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row:
                        print("РЎС‚Р°РЅРѕРє РЅРµ РЅР°Р№РґРµРЅ РёР»Рё СѓР¶Рµ РїСЂРѕРґР°РЅ")
                        return False
                    
                    machine_id = row[0]
                    
                    # РџРѕР»СѓС‡Р°РµРј РјР°С‚РµСЂРёР°Р»С‹ РёР· СЃРїРµС†РёС„РёРєР°С†РёРё
                    cur.execute("""
                        SELECT material_id, quantity
                        FROM machine_materials
                        WHERE machine_id = %s
                    """, (machine_id,))
                    materials = cur.fetchall()
                    
                    # Р’РѕР·РІСЂР°С‰Р°РµРј РјР°С‚РµСЂРёР°Р»С‹ РЅР° СЃРєР»Р°Рґ
                    for material_id, quantity in materials:
                        cur.execute("""
                            INSERT INTO material_inventory (material_id, quantity)
                            VALUES (%s, %s)
                            ON CONFLICT (material_id) 
                            DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
                        """, (material_id, quantity))
                        
                        # Р”РѕР±Р°РІР»СЏРµРј С‚СЂР°РЅР·Р°РєС†РёСЋ
                        cur.execute("""
                            INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                            VALUES (%s, %s, 'disassembly', %s)
                        """, (material_id, quantity, finished_good_id))
                    
                    # РЈРґР°Р»СЏРµРј СЃРІСЏР·Рё СЃ Р°РјРѕСЂС‚РёР·Р°С†РёРµР№ РёРЅСЃС‚СЂСѓРјРµРЅС‚РѕРІ
                    cur.execute("DELETE FROM tool_depreciation WHERE finished_good_id = %s", (finished_good_id,))
                    
                    # РЈРґР°Р»СЏРµРј СЃРІСЏР·Рё СЃ СЂР°Р±РѕС‚РѕР№
                    cur.execute("DELETE FROM finished_good_labor WHERE finished_good_id = %s", (finished_good_id,))
                    
                    # РЈРґР°Р»СЏРµРј СЃС‚Р°РЅРѕРє
                    cur.execute("DELETE FROM finished_goods WHERE id = %s", (finished_good_id,))
                    
                    conn.commit()
                    print(f"РЎС‚Р°РЅРѕРє ID {finished_good_id} СЂР°Р·РѕР±СЂР°РЅ, РјР°С‚РµСЂРёР°Р»С‹ РІРѕР·РІСЂР°С‰РµРЅС‹ РЅР° СЃРєР»Р°Рґ")
                    
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° СЂР°Р·Р±РѕСЂРєРё СЃС‚Р°РЅРєР°: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, result=bool)
    def deleteMachine(self, finished_good_id):
        """РЈРґР°Р»СЏРµС‚ СЃС‚Р°РЅРѕРє Р‘Р•Р— РІРѕР·РІСЂР°С‚Р° РјР°С‚РµСЂРёР°Р»РѕРІ."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ СЃС‚Р°РЅРѕРє РЅР° СЃРєР»Р°РґРµ
                    cur.execute("""
                        SELECT status FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row:
                        print("РЎС‚Р°РЅРѕРє РЅРµ РЅР°Р№РґРµРЅ")
                        return False
                    
                    if row[0] == 'sold':
                        print("РќРµР»СЊР·СЏ СѓРґР°Р»РёС‚СЊ РїСЂРѕРґР°РЅРЅС‹Р№ СЃС‚Р°РЅРѕРє")
                        return False
                    
                    # РЈРґР°Р»СЏРµРј СЃРІСЏР·Рё СЃ СЂР°Р±РѕС‚РѕР№
                    cur.execute("""
                        DELETE FROM finished_good_labor WHERE finished_good_id = %s
                    """, (finished_good_id,))
                    
                    # РЈРґР°Р»СЏРµРј СЃС‚Р°РЅРѕРє
                    cur.execute("""
                        DELETE FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    
                    conn.commit()
                    print(f"РЎС‚Р°РЅРѕРє ID {finished_good_id} СѓРґР°Р»С‘РЅ")
                    
            return True
        except Exception as e:
            print(f"РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЃС‚Р°РЅРєР°: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, str, float, result=bool)
    def updateFinishedGood(self, finished_good_id, produced_date_str, indirect_cost):
        try:
            from datetime import datetime
            self._ensure_indirect_schema()
            produced_date = datetime.strptime(produced_date_str, "%Y-%m-%d").date()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE finished_goods
                        SET produced_date = %s,
                            indirect_cost = %s
                        WHERE id = %s AND status = 'completed'
                    """, (produced_date, Decimal(str(indirect_cost)), finished_good_id))
                    cur.execute("""
                        UPDATE finished_goods fg
                        SET cost_price = COALESCE(base.base_cost, 0) + COALESCE(fg.indirect_cost, 0)
                        FROM (
                            SELECT
                                fg2.id AS finished_good_id,
                                COALESCE(SUM(mm.quantity * p.price_per_unit), 0) +
                                COALESCE((
                                    SELECT SUM(fgl.hours_worked * e.hourly_rate)
                                    FROM finished_good_labor fgl
                                    JOIN work_logs wl ON wl.id = fgl.work_log_id
                                    JOIN employees e ON e.id = wl.employee_id
                                    WHERE fgl.finished_good_id = fg2.id
                                ), 0) +
                                COALESCE((
                                    SELECT SUM(COALESCE(t.monthly_depreciation, 0))
                                    FROM machine_tools mt
                                    JOIN tools t ON t.id = mt.tool_id
                                    WHERE mt.machine_id = fg2.machine_id
                                ), 0) AS base_cost
                            FROM finished_goods fg2
                            LEFT JOIN machines m ON m.id = fg2.machine_id
                            LEFT JOIN machine_materials mm ON mm.machine_id = m.id
                            LEFT JOIN LATERAL (
                                SELECT price_per_unit
                                FROM purchases
                                WHERE material_id = mm.material_id
                                ORDER BY purchase_date DESC, id DESC
                                LIMIT 1
                            ) p ON TRUE
                            WHERE fg2.id = %s
                            GROUP BY fg2.id
                        ) base
                        WHERE fg.id = base.finished_good_id
                    """, (finished_good_id,))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка обновления готового станка: {e}")
            return False

    @Slot(result="QVariantList")
    def getIndirectCategories(self):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT id, name, monthly_amount, is_active, notes
                        FROM indirect_expense_categories
                        ORDER BY name
                    """)
                    rows = cur.fetchall()
            return [
                {"id": r[0], "name": r[1], "monthly_amount": float(r[2]), "is_active": bool(r[3]), "notes": r[4] or ""}
                for r in rows
            ]
        except Exception as e:
            print(f"Ошибка получения косвенных категорий: {e}")
            return []

    @Slot(str, float, bool, str, result=bool)
    def addIndirectCategory(self, name, amount, is_active, notes):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO indirect_expense_categories (name, monthly_amount, is_active, notes)
                        VALUES (%s, %s, %s, %s)
                    """, (name, Decimal(str(amount)), is_active, notes if notes else None))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка добавления косвенной категории: {e}")
            return False

    @Slot(int, str, float, bool, str, result=bool)
    def updateIndirectCategory(self, category_id, name, amount, is_active, notes):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE indirect_expense_categories
                        SET name = %s, monthly_amount = %s, is_active = %s, notes = %s
                        WHERE id = %s
                    """, (name, Decimal(str(amount)), is_active, notes if notes else None, category_id))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка обновления косвенной категории: {e}")
            return False

    @Slot(int, result=bool)
    def deleteIndirectCategory(self, category_id):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("DELETE FROM indirect_expense_categories WHERE id = %s", (category_id,))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка удаления косвенной категории: {e}")
            return False

    @Slot(str, result=bool)
    def recalculateIndirectExpenses(self, month_str):
        try:
            import calendar
            from datetime import date, timedelta
            self._ensure_indirect_schema()
            year, month = [int(x) for x in month_str.split("-")]
            _, days_in_month = calendar.monthrange(year, month)
            month_start = date(year, month, 1)
            month_end = date(year, month, days_in_month)

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        DELETE FROM indirect_cost_allocations
                        WHERE allocation_date BETWEEN %s AND %s
                    """, (month_start, month_end))

                    cur.execute("""
                        SELECT id, monthly_amount
                        FROM indirect_expense_categories
                        WHERE is_active = TRUE
                    """)
                    categories = cur.fetchall()

                    for cat_id, monthly_amount in categories:
                        day_rate = (monthly_amount or Decimal('0')) / Decimal(days_in_month)
                        day = month_start
                        while day <= month_end:
                            cur.execute("""
                                SELECT id
                                FROM finished_goods
                                WHERE start_date <= %s
                                  AND (
                                      (status = 'in_progress' AND %s <= CURRENT_DATE)
                                      OR
                                      (status <> 'in_progress' AND produced_date IS NOT NULL AND produced_date >= %s)
                                  )
                            """, (day, day, day))
                            fg_ids = [r[0] for r in cur.fetchall()]
                            if fg_ids:
                                per_machine = day_rate / Decimal(len(fg_ids))
                                for fg_id in fg_ids:
                                    cur.execute("""
                                        INSERT INTO indirect_cost_allocations (category_id, finished_good_id, allocation_date, amount)
                                        VALUES (%s, %s, %s, %s)
                                    """, (cat_id, fg_id, day, per_machine))
                            day += timedelta(days=1)

                    cur.execute("UPDATE finished_goods SET indirect_cost = 0")
                    cur.execute("""
                        UPDATE finished_goods fg
                        SET indirect_cost = t.sum_indirect
                        FROM (
                            SELECT finished_good_id, COALESCE(SUM(amount), 0)::DECIMAL(12,2) AS sum_indirect
                            FROM indirect_cost_allocations
                            GROUP BY finished_good_id
                        ) t
                        WHERE fg.id = t.finished_good_id
                    """)
                    cur.execute("""
                        UPDATE finished_goods fg
                        SET cost_price = COALESCE(base.base_cost, 0) + COALESCE(fg.indirect_cost, 0)
                        FROM (
                            SELECT
                                fg2.id AS finished_good_id,
                                COALESCE(SUM(mm.quantity * p.price_per_unit), 0) +
                                COALESCE((
                                    SELECT SUM(fgl.hours_worked * e.hourly_rate)
                                    FROM finished_good_labor fgl
                                    JOIN work_logs wl ON wl.id = fgl.work_log_id
                                    JOIN employees e ON e.id = wl.employee_id
                                    WHERE fgl.finished_good_id = fg2.id
                                ), 0) +
                                COALESCE((
                                    SELECT SUM(COALESCE(t.monthly_depreciation, 0))
                                    FROM machine_tools mt
                                    JOIN tools t ON t.id = mt.tool_id
                                    WHERE mt.machine_id = fg2.machine_id
                                ), 0) AS base_cost
                            FROM finished_goods fg2
                            LEFT JOIN machines m ON m.id = fg2.machine_id
                            LEFT JOIN machine_materials mm ON mm.machine_id = m.id
                            LEFT JOIN LATERAL (
                                SELECT price_per_unit
                                FROM purchases
                                WHERE material_id = mm.material_id
                                ORDER BY purchase_date DESC, id DESC
                                LIMIT 1
                            ) p ON TRUE
                            GROUP BY fg2.id
                        ) base
                        WHERE fg.id = base.finished_good_id
                    """)
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка пересчёта косвенных расходов: {e}")
            return False

    @Slot(str, result="QVariantList")
    def getIndirectAllocations(self, month_str):
        try:
            import calendar
            from datetime import date
            self._ensure_indirect_schema()
            year, month = [int(x) for x in month_str.split("-")]
            _, days_in_month = calendar.monthrange(year, month)
            month_start = date(year, month, 1)
            month_end = date(year, month, days_in_month)
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT c.name, a.allocation_date, fg.machine_model, a.amount, fg.id
                        FROM indirect_cost_allocations a
                        JOIN indirect_expense_categories c ON c.id = a.category_id
                        JOIN finished_goods fg ON fg.id = a.finished_good_id
                        WHERE a.allocation_date BETWEEN %s AND %s
                        ORDER BY a.allocation_date DESC, c.name, fg.machine_model
                    """, (month_start, month_end))
                    rows = cur.fetchall()
            return [{"category": r[0], "date": str(r[1]), "machine_model": r[2], "amount": float(r[3]), "finished_good_id": r[4]} for r in rows]
        except Exception as e:
            print(f"Ошибка получения распределений косвенных расходов: {e}")
            return []

    @Slot(str, str, result="QVariantList")
    def getIndirectAllocationsByPeriod(self, date_from_str, date_to_str):
        try:
            from datetime import datetime
            self._ensure_indirect_schema()
            date_from = datetime.strptime(date_from_str, "%Y-%m-%d").date()
            date_to = datetime.strptime(date_to_str, "%Y-%m-%d").date()
            if date_to < date_from:
                date_from, date_to = date_to, date_from
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT c.name, a.allocation_date, fg.machine_model, a.amount, fg.id
                        FROM indirect_cost_allocations a
                        JOIN indirect_expense_categories c ON c.id = a.category_id
                        JOIN finished_goods fg ON fg.id = a.finished_good_id
                        WHERE a.allocation_date BETWEEN %s AND %s
                        ORDER BY a.allocation_date DESC, c.name, fg.machine_model
                    """, (date_from, date_to))
                    rows = cur.fetchall()
            return [{"category": r[0], "date": str(r[1]), "machine_model": r[2], "amount": float(r[3]), "finished_good_id": r[4]} for r in rows]
        except Exception as e:
            print(f"Ошибка получения косвенных расходов за период: {e}")
            return []

    @Slot(int, result="QVariantList")
    def getMachineIndirectCostDetails(self, finished_good_id):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT c.name, a.allocation_date, a.amount
                        FROM indirect_cost_allocations a
                        JOIN indirect_expense_categories c ON c.id = a.category_id
                        WHERE a.finished_good_id = %s
                        ORDER BY a.allocation_date, c.name
                    """, (finished_good_id,))
                    rows = cur.fetchall()
            return [{"category": r[0], "date": str(r[1]), "amount": float(r[2])} for r in rows]
        except Exception as e:
            print(f"Ошибка детализации косвенных расходов: {e}")
            return []

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
                    df_sales.to_excel(writer, sheet_name="РџСЂРѕРґР°Р¶Рё", index=False)
                    df_production.to_excel(writer, sheet_name="РџСЂРѕРёР·РІРѕРґСЃС‚РІРѕ", index=False)
            print(f"РћС‚С‡С‘С‚ СЃРѕС…СЂР°РЅС‘РЅ РІ {filename}")
        except Exception as e:
            print(f"РћС€РёР±РєР° СЌРєСЃРїРѕСЂС‚Р°: {e}")

