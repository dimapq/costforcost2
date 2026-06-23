# frontend/controllers/backend_controller.py
import glob
import configparser
import ipaddress
import os
import random
import shutil
import subprocess
from datetime import date, timedelta
from pathlib import Path

from PySide6.QtCore import QObject, Slot
from decimal import Decimal
from psycopg2 import sql

from backend.models.labor import add_labor_to_finished_good
from backend.models.inventory import get_materials_summary
from backend.models.tools import get_tools_summary
from backend.models.production import get_finished_goods_summary
from backend.models.analytics import get_recent_transactions
from backend.models.machine import list_machines, calculate_machine_cost_from_purchases
from backend.db.connection import get_connection


class BackendController(QObject):
    def _normalize_connection_mode(self, mode):
        return "online"

    def _resolve_sslmode(self, host, sslmode=""):
        value = str(sslmode or "").strip()
        if value:
            return value
        host_value = str(host or "").strip().lower()
        if host_value in ("", "localhost", "127.0.0.1", "::1"):
            return "disable"
        try:
            ip_value = ipaddress.ip_address(host_value)
            if ip_value in ipaddress.ip_network("100.64.0.0/10"):
                return "disable"
        except ValueError:
            pass
        return "require"

    def _mask_password(self, password):
        value = str(password or "")
        if not value:
            return ""
        if len(value) <= 4:
            return "*" * len(value)
        return value[:2] + "*" * max(4, len(value) - 4) + value[-2:]

    def _build_client_online_config(self, profile):
        config = configparser.ConfigParser()
        host = str(profile.get("host", "localhost") or "localhost").strip()
        port = str(profile.get("port", "5432") or "5432").strip()
        name = str(profile.get("name", "cost_online_demo") or "cost_online_demo").strip()
        user = str(profile.get("user", "cost_client_app") or "cost_client_app").strip()
        password = str(profile.get("password", "") or "")
        sslmode = self._resolve_sslmode(host, profile.get("sslmode", ""))
        sslrootcert = str(profile.get("sslrootcert", "") or "").strip()

        config["database"] = {
            "host": host,
            "port": port,
            "name": name,
            "user": user,
            "password": password,
            "sslmode": sslmode,
            "sslrootcert": sslrootcert,
        }
        config["database_online"] = dict(config["database"])
        config["app"] = {
            "selected_connection_mode": "online",
            "connection_confirmed": "true",
            "connection_confirmed_online": "true",
        }
        return config

    def _write_client_online_config(self, destination_path=None):
        from backend.db.config import get_db_profile

        profile = get_db_profile("online")
        config = self._build_client_online_config(profile)
        export_dir = self._get_export_dir()
        path = Path(destination_path) if destination_path else (export_dir / "client_config_online.ini")
        with open(path, "w", encoding="utf-8") as file:
            config.write(file)
        return path, profile

    @Slot(result="QVariantMap")
    def getDatabaseConfig(self):
        try:
            from backend.db.config import get_config, get_config_path, get_selected_connection_mode, is_connection_confirmed
            config = get_config(create_if_missing=True)
            db = config['database']
            selected_mode = get_selected_connection_mode()
            return {
                "host": db.get('host', 'localhost'),
                "port": db.get('port', '5432'),
                "name": db.get('name', 'cost_online_demo'),
                "user": db.get('user', 'cost_client_app'),
                "password": db.get('password', ''),
                "sslmode": self._resolve_sslmode(db.get('host', 'localhost'), db.get('sslmode', '')),
                "sslrootcert": db.get('sslrootcert', ''),
                "selected_mode": selected_mode,
                "config_path": str(get_config_path()),
                "connection_confirmed": is_connection_confirmed()
            }
        except Exception as e:
            print(f"Ошибка чтения config.ini: {e}")
            return {
                "host": "localhost",
                "port": "5432",
                "name": "cost_online_demo",
                "user": "cost_client_app",
                "password": "",
                "sslmode": "disable",
                "sslrootcert": "",
                "selected_mode": "online",
                "config_path": "config.ini",
                "connection_confirmed": False
            }

    @Slot(result=bool)
    def shouldShowConnectionDialog(self):
        try:
            from backend.db.config import is_connection_confirmed
            return not is_connection_confirmed()
        except Exception:
            return True

    @Slot(str, result="QVariantMap")
    def getDatabaseConfigForMode(self, mode):
        try:
            from backend.db.config import get_config_path, get_db_profile, get_selected_connection_mode, is_connection_confirmed

            normalized_mode = "online"
            db = get_db_profile("online")
            return {
                "host": db.get("host", "localhost"),
                "port": db.get("port", "5432"),
                "name": db.get("name", "cost_online_demo"),
                "user": db.get("user", "cost_client_app"),
                "password": db.get("password", ""),
                "sslmode": self._resolve_sslmode(db.get("host", "localhost"), db.get("sslmode", "")),
                "sslrootcert": db.get("sslrootcert", ""),
                "selected_mode": get_selected_connection_mode(),
                "mode": normalized_mode,
                "config_path": str(get_config_path()),
                "connection_confirmed": is_connection_confirmed(normalized_mode)
            }
        except Exception as e:
            print(f"Ошибка чтения параметров онлайн-подключения: {e}")
            normalized_mode = "online"
            return {
                "host": "localhost",
                "port": "5432",
                "name": "cost_online_demo",
                "user": "cost_client_app",
                "password": "CostClientApp_2026!",
                "sslmode": "require",
                "sslrootcert": "",
                "selected_mode": "online",
                "mode": normalized_mode,
                "config_path": "config.ini",
                "connection_confirmed": False
            }

    @Slot(result="QVariantMap")
    def getOnlineConnectionInfo(self):
        try:
            from backend.db.config import get_db_profile

            profile = get_db_profile("online")
            config = self._build_client_online_config(profile)
            lines = []
            for section_name in config.sections():
                lines.append(f"[{section_name}]")
                for key, value in config[section_name].items():
                    lines.append(f"{key} = {value}")
                lines.append("")
            return {
                "ok": True,
                "host": profile.get("host", "localhost"),
                "port": profile.get("port", "5432"),
                "name": profile.get("name", "cost_online_demo"),
                "user": profile.get("user", "cost_client_app"),
                "password": profile.get("password", ""),
                "masked_password": self._mask_password(profile.get("password", "")),
                "sslmode": self._resolve_sslmode(profile.get("host", "localhost"), profile.get("sslmode", "")),
                "sslrootcert": profile.get("sslrootcert", ""),
                "config_text": "\n".join(lines).strip(),
            }
        except Exception as e:
            return {"ok": False, "message": f"Ошибка чтения параметров онлайн-подключения: {e}"}

    @Slot(result="QVariantMap")
    def exportClientOnlineConfig(self):
        try:
            path, _ = self._write_client_online_config()
            return {"ok": True, "message": "Клиентский config.ini для онлайн-подключения подготовлен.", "path": str(path)}
        except Exception as e:
            return {"ok": False, "message": f"Ошибка подготовки клиентского config.ini: {e}", "path": ""}

    @Slot(str, result="QVariantMap")
    def rotateOnlineDatabasePassword(self, new_password):
        try:
            password_value = str(new_password or "")
            if len(password_value) < 8:
                return {"ok": False, "message": "Новый пароль должен содержать минимум 8 символов.", "path": ""}

            import psycopg2
            from backend.db.config import get_config, get_db_profile, save_config

            profile = get_db_profile("online")
            conn = psycopg2.connect(
                host=str(profile.get("host", "localhost") or "localhost").strip(),
                port=int(profile.get("port", "5432") or 5432),
                dbname=str(profile.get("name", "cost_online_demo") or "cost_online_demo").strip(),
                user=str(profile.get("user", "cost_client_app") or "cost_client_app").strip(),
                password=str(profile.get("password", "") or ""),
                connect_timeout=5,
                options='-c client_encoding=utf8',
                sslmode=self._resolve_sslmode(profile.get("host", "localhost"), profile.get("sslmode", "")),
            )
            try:
                conn.autocommit = True
                with conn.cursor() as cur:
                    cur.execute(
                        sql.SQL("ALTER ROLE {} WITH PASSWORD %s").format(
                            sql.Identifier(str(profile.get("user", "cost_client_app")))
                        ),
                        [password_value]
                    )
            finally:
                conn.close()

            config = get_config(create_if_missing=True)
            if "database_online" not in config:
                config["database_online"] = {}
            config["database_online"]["password"] = password_value
            if config.get("app", "selected_connection_mode", fallback="online").strip().lower() == "online":
                if "database" not in config:
                    config["database"] = {}
                config["database"]["password"] = password_value
            save_config(config)

            path, _ = self._write_client_online_config()
            return {
                "ok": True,
                "message": "Пароль онлайн-подключения обновлен. Новый клиентский config.ini уже подготовлен.",
                "path": str(path),
            }
        except Exception as e:
            return {"ok": False, "message": f"Ошибка смены пароля онлайн-подключения: {e}", "path": ""}

    @Slot(result=str)
    def getSelectedConnectionMode(self):
        try:
            from backend.db.config import get_selected_connection_mode
            return get_selected_connection_mode()
        except Exception:
            return "online"

    @Slot(str, result="QVariantMap")
    def activateDatabaseMode(self, mode):
        try:
            from backend.db.config import set_selected_connection_mode

            normalized_mode = "online"
            path = set_selected_connection_mode("online")
            result = self.getDatabaseConfigForMode("online")
            result["ok"] = True
            result["message"] = "Активирован режим онлайн-подключения."
            result["config_path"] = str(path)
            return result
        except Exception as e:
            return {
                "ok": False,
                "message": f"Ошибка активации онлайн-подключения: {e}",
                "mode": "online"
            }

    @Slot(str, str, str, str, str, result="QVariantMap")
    def testDatabaseConfig(self, host, port, name, user, password):
        try:
            import psycopg2
            conn = psycopg2.connect(
                host=(host or 'localhost').strip(),
                port=int(port or 5432),
                dbname=(name or 'cost_online_demo').strip(),
                user=(user or 'cost_client_app').strip(),
                password=password or '',
                connect_timeout=3,
                options='-c client_encoding=utf8',
                sslmode=self._resolve_sslmode(host)
            )
            with conn:
                with conn.cursor() as cur:
                    cur.execute('SELECT 1')
                    cur.fetchone()
            conn.close()
            return {"ok": True, "message": "Подключение успешно"}
        except Exception as e:
            return {"ok": False, "message": f"Ошибка подключения: {e}"}

    @Slot(str, str, str, str, str, result="QVariantMap")
    def saveDatabaseConfig(self, host, port, name, user, password):
        try:
            test = self.testDatabaseConfig(host, port, name, user, password)
            if not test.get("ok"):
                return test
            from backend.db.config import save_db_config
            path = save_db_config(host, port, name, user, password, confirmed=True)
            return {"ok": True, "message": f"Подключение сохранено: {path}"}
        except Exception as e:
            return {"ok": False, "message": f"Ошибка сохранения config.ini: {e}"}

    @Slot(str, str, str, str, str, str, result="QVariantMap")
    def saveDatabaseConfigForMode(self, mode, host, port, name, user, password):
        try:
            normalized_mode = "online"
            test = self.testDatabaseConfig(host, port, name, user, password)
            if not test.get("ok"):
                return test
            from backend.db.config import save_db_config
            path = save_db_config(host, port, name, user, password, confirmed=True, mode=normalized_mode)
            return {
                "ok": True,
                "message": f"Параметры онлайн-подключения сохранены: {path}",
                "mode": normalized_mode
            }
        except Exception as e:
            return {
                "ok": False,
                "message": f"Ошибка сохранения онлайн-подключения: {e}",
                "mode": "online"
            }

    @Slot(result="QVariantMap")
    def runFifoAutotest(self):
        from backend.models.production import _consume_material_fifo

        conn = None
        try:
            case = self._build_random_fifo_case()
            conn = get_connection()
            conn.autocommit = False
            with conn.cursor() as cur:
                material_name = f"FIFO_AUTOTEST_{date.today().isoformat()}_{random.randint(1000, 9999)}"

                cur.execute(
                    """
                    INSERT INTO materials (
                        name, unit, source, notes, updated_date,
                        low_stock_threshold, enough_stock_threshold, category
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        material_name,
                        "шт",
                        "Автотест",
                        "Временный материал для проверки FIFO",
                        date.today(),
                        1,
                        3,
                        "Материалы",
                    ),
                )
                material_id = cur.fetchone()[0]

                cur.execute(
                    "INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)",
                    (material_id, sum((lot[2] for lot in case["lots"]), Decimal("0"))),
                )

                lot_ids = []
                for purchase_date, price, qty in case["lots"]:
                    cur.execute(
                        """
                        INSERT INTO purchases (
                            material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes
                        )
                        VALUES (%s, %s, %s, %s, %s, %s)
                        RETURNING id
                        """,
                        (
                            material_id,
                            price,
                            qty,
                            qty,
                            purchase_date,
                            "FIFO autotest lot",
                        ),
                    )
                    lot_ids.append(cur.fetchone()[0])

                consumed_cost = _consume_material_fifo(cur, material_id, case["consume_qty"])

                cur.execute(
                    """
                    SELECT id, COALESCE(remaining_quantity, 0)
                    FROM purchases
                    WHERE id = ANY(%s)
                    ORDER BY purchase_date ASC, id ASC
                    """,
                    (lot_ids,),
                )
                remaining_rows = cur.fetchall()
                remaining_values = [Decimal(str(row[1] or 0)) for row in remaining_rows]
                expected_remaining = case["expected_remaining"]
                expected_cost = case["expected_cost"]

                ok = remaining_values == expected_remaining and Decimal(str(consumed_cost)).quantize(Decimal("0.01")) == expected_cost
                details = (
                    f"{case['formula_text']}. "
                    f"Ожидалось: остатки {expected_remaining}, стоимость {expected_cost}. "
                    f"Получено: остатки {remaining_values}, стоимость {Decimal(str(consumed_cost)).quantize(Decimal('0.01'))}."
                )

                conn.rollback()

                return {
                    "ok": ok,
                    "name": "FIFO",
                    "indicator": "green" if ok else "red",
                    "message": "FIFO работает корректно." if ok else "FIFO работает некорректно.",
                    "details": details,
                }
        except Exception as e:
            if conn is not None:
                try:
                    conn.rollback()
                except Exception:
                    pass
            return {
                "ok": False,
                "name": "FIFO",
                "indicator": "red",
                "message": "Ошибка выполнения автотеста FIFO.",
                    "details": str(e),
            }
        finally:
            if conn is not None:
                try:
                    conn.close()
                except Exception:
                    pass

    def _make_autotest_result(self, name, ok, message, details=""):
        return {
            "name": name,
            "ok": bool(ok),
            "indicator": "green" if ok else "red",
            "message": message,
            "details": details or "",
        }

    def _random_int_pair(self, left_min=1, left_max=500, right_min=1, right_max=500):
        left = random.randint(left_min, left_max)
        right = random.randint(right_min, right_max)
        return left, right, left + right

    def _build_random_fifo_case(self):
        lot_qtys = [random.randint(2, 7), random.randint(2, 7), random.randint(2, 7)]
        lot_prices = [Decimal(str(random.randint(1, 9))), Decimal(str(random.randint(10, 30))), Decimal(str(random.randint(31, 60)))]
        consume_qty = random.randint(1, sum(lot_qtys) - 1)
        remaining = consume_qty
        expected_cost = Decimal("0.00")
        expected_remaining = []
        for qty, price in zip(lot_qtys, lot_prices):
            take = min(qty, remaining)
            expected_cost += Decimal(str(take)) * price
            expected_remaining.append(Decimal(str(qty - take)))
            remaining -= take
        lots = [
            (date.today() - timedelta(days=3), lot_prices[0], Decimal(str(lot_qtys[0]))),
            (date.today() - timedelta(days=2), lot_prices[1], Decimal(str(lot_qtys[1]))),
            (date.today() - timedelta(days=1), lot_prices[2], Decimal(str(lot_qtys[2]))),
        ]
        return {
            "lots": lots,
            "consume_qty": Decimal(str(consume_qty)),
            "expected_cost": expected_cost.quantize(Decimal("0.01")),
            "expected_remaining": expected_remaining,
            "formula_text": (
                f"Партии: {lot_qtys[0]}x{lot_prices[0]} + "
                f"{lot_qtys[1]}x{lot_prices[1]} + {lot_qtys[2]}x{lot_prices[2]}, "
                f"списание {consume_qty}"
            ),
        }

    def _build_random_indirect_case(self):
        monthly_amount = Decimal(str(random.randint(100, 900)))
        days_in_month = random.randint(28, 31)
        machine_count = random.randint(1, 12)
        day_rate = (monthly_amount / Decimal(str(days_in_month))).quantize(Decimal("0.0001"))
        per_machine = (day_rate / Decimal(str(machine_count))).quantize(Decimal("0.0001"))
        return {
            "monthly_amount": monthly_amount,
            "days_in_month": days_in_month,
            "machine_count": machine_count,
            "day_rate": day_rate,
            "per_machine": per_machine,
        }

    def _build_random_report_case(self):
        revenue = Decimal(str(random.randint(200, 2000)))
        cogs = Decimal(str(random.randint(50, int(revenue) - 30)))
        salary = Decimal(str(random.randint(10, 200)))
        tools = Decimal(str(random.randint(5, 120)))
        gross_profit = revenue - cogs
        net_profit = gross_profit - salary - tools
        return {
            "revenue": revenue,
            "cogs": cogs,
            "salary": salary,
            "tools": tools,
            "gross_profit": gross_profit,
            "net_profit": net_profit,
        }

    def _run_cost_autotest(self):
        conn = None
        suffix = f"{date.today().isoformat()}_{random.randint(1000, 9999)}"
        material_name = f"COST_AUTOTEST_{suffix}"
        machine_model = f"COST_MACHINE_{suffix}"
        try:
            case = self._build_random_fifo_case()
            conn = get_connection()
            conn.autocommit = False
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO materials (
                        name, unit, source, notes, updated_date,
                        low_stock_threshold, enough_stock_threshold, category
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        material_name,
                        "шт",
                        "Автотест",
                        "Временный материал для проверки себестоимости",
                        date.today(),
                        1,
                        3,
                        "Материалы",
                    ),
                )
                material_id = cur.fetchone()[0]
                cur.execute(
                    "INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)",
                    (material_id, sum((lot[2] for lot in case["lots"]), Decimal("0"))),
                )
                for purchase_date, price, qty in case["lots"]:
                    cur.execute(
                        """
                        INSERT INTO purchases (
                            material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes
                        )
                        VALUES (%s, %s, %s, %s, %s, %s)
                        """,
                        (material_id, price, qty, qty, purchase_date, "Cost autotest lot"),
                    )

                cur.execute(
                    "INSERT INTO machines (model, total_cost) VALUES (%s, %s) RETURNING id",
                    (machine_model, Decimal("0")),
                )
                machine_id = cur.fetchone()[0]
                cur.execute(
                    "INSERT INTO machine_materials (machine_id, material_id, quantity) VALUES (%s, %s, %s)",
                    (machine_id, material_id, case["consume_qty"]),
                )
                conn.commit()

            calculated = calculate_machine_cost_from_purchases(machine_id)
            expected = case["expected_cost"]
            ok = Decimal(str(calculated)).quantize(Decimal("0.01")) == expected
            details = (
                f"{case['formula_text']}. "
                f"Ожидалось {expected:.2f} руб., получено {Decimal(str(calculated)).quantize(Decimal('0.01')):.2f} руб."
            )
            return self._make_autotest_result(
                "Себестоимость",
                ok,
                "Себестоимость считается корректно." if ok else "Ошибка расчёта себестоимости.",
                details,
            )
        except Exception as e:
            return self._make_autotest_result("Себестоимость", False, "Ошибка автотеста себестоимости.", str(e))
        finally:
            if conn is not None:
                try:
                    conn.rollback()
                except Exception:
                    pass
                try:
                    conn.close()
                except Exception:
                    pass
            try:
                with get_connection() as cleanup_conn:
                    with cleanup_conn.cursor() as cleanup_cur:
                        cleanup_cur.execute("DELETE FROM machine_materials WHERE machine_id IN (SELECT id FROM machines WHERE model = %s)", (machine_model,))
                        cleanup_cur.execute("DELETE FROM machines WHERE model = %s", (machine_model,))
                        cleanup_cur.execute("DELETE FROM purchases WHERE material_id IN (SELECT id FROM materials WHERE name = %s)", (material_name,))
                        cleanup_cur.execute("DELETE FROM material_inventory WHERE material_id IN (SELECT id FROM materials WHERE name = %s)", (material_name,))
                        cleanup_cur.execute("DELETE FROM materials WHERE name = %s", (material_name,))
                    cleanup_conn.commit()
            except Exception:
                pass

    def _run_inventory_autotest(self):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        SELECT m.id, m.name,
                               COALESCE(inv.quantity, 0) AS inventory_qty,
                               COALESCE(SUM(COALESCE(p.remaining_quantity, 0)), 0) AS purchase_qty
                        FROM materials m
                        LEFT JOIN material_inventory inv ON inv.material_id = m.id
                        LEFT JOIN purchases p ON p.material_id = m.id
                        GROUP BY m.id, m.name, inv.quantity
                        HAVING ABS(COALESCE(inv.quantity, 0) - COALESCE(SUM(COALESCE(p.remaining_quantity, 0)), 0)) > 0.0001
                        ORDER BY m.id
                        LIMIT 10
                        """
                    )
                    mismatches = cur.fetchall()
            ok = len(mismatches) == 0
            details = "Остатки в material_inventory совпадают с суммой remaining_quantity по всем партиям."
            if mismatches:
                parts = []
                for material_id, name, inv_qty, pur_qty in mismatches:
                    parts.append(f"ID {material_id} {name}: склад={inv_qty}, партии={pur_qty}")
                details = "; ".join(parts)
            return self._make_autotest_result(
                "Остатки склада",
                ok,
                "Остатки склада согласованы." if ok else "Найдены расхождения остатков склада.",
                details,
            )
        except Exception as e:
            return self._make_autotest_result("Остатки склада", False, "Ошибка проверки остатков склада.", str(e))

    def _run_transactions_autotest(self):
        conn = None
        try:
            conn = get_connection()
            conn.autocommit = False
            with conn.cursor() as cur:
                marker = f"TX_AUTOTEST_{date.today().isoformat()}"
                cur.execute(
                    """
                    INSERT INTO materials (
                        name, unit, source, notes, updated_date,
                        low_stock_threshold, enough_stock_threshold, category
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (marker, "шт", "Автотест", "Проверка rollback", date.today(), 1, 3, "Материалы"),
                )
                material_id = cur.fetchone()[0]
                cur.execute("INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)", (material_id, Decimal("5")))
                cur.execute(
                    """
                    INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (material_id, Decimal("5"), "autotest", None),
                )
                conn.rollback()
                cur.execute("SELECT COUNT(*) FROM materials WHERE name = %s", (marker,))
                material_count = cur.fetchone()[0]
                cur.execute(
                    """
                    SELECT COUNT(*)
                    FROM material_transactions mt
                    JOIN materials m ON m.id = mt.material_id
                    WHERE m.name = %s
                    """,
                    (marker,),
                )
                tx_count = cur.fetchone()[0]
            ok = material_count == 0 and tx_count == 0
            details = f"После rollback: материалов={material_count}, транзакций={tx_count}."
            return self._make_autotest_result(
                "Транзакции",
                ok,
                "Rollback транзакций работает корректно." if ok else "Rollback транзакций работает некорректно.",
                details,
            )
        except Exception as e:
            return self._make_autotest_result("Транзакции", False, "Ошибка автотеста транзакций.", str(e))
        finally:
            if conn is not None:
                try:
                    conn.rollback()
                except Exception:
                    pass
                try:
                    conn.close()
                except Exception:
                    pass

    def _run_indirect_autotest(self):
        try:
            self._ensure_indirect_schema()
            formula_case = self._build_random_indirect_case()
            expected_day_rate = (formula_case["monthly_amount"] / Decimal(str(formula_case["days_in_month"]))).quantize(Decimal("0.0001"))
            expected_per_machine = (expected_day_rate / Decimal(str(formula_case["machine_count"]))).quantize(Decimal("0.0001"))
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        SELECT COUNT(*)
                        FROM (
                            SELECT fg.id
                            FROM finished_goods fg
                            LEFT JOIN (
                                SELECT finished_good_id, COALESCE(SUM(amount), 0)::DECIMAL(12, 2) AS allocated
                                FROM indirect_cost_allocations
                                GROUP BY finished_good_id
                            ) a ON a.finished_good_id = fg.id
                            WHERE ABS(COALESCE(fg.indirect_cost, 0) - COALESCE(a.allocated, 0)) > 0.01
                        ) t
                        """
                    )
                    mismatch_count = cur.fetchone()[0]
                    cur.execute("SELECT COUNT(*) FROM indirect_expense_categories")
                    categories_count = cur.fetchone()[0]
            ok = (
                mismatch_count == 0
                and formula_case["day_rate"] == expected_day_rate
                and formula_case["per_machine"] == expected_per_machine
            )
            details = (
                f"Формула: {formula_case['monthly_amount']} / {formula_case['days_in_month']} = {expected_day_rate}; "
                f"{expected_day_rate} / {formula_case['machine_count']} = {expected_per_machine}. "
                f"Категорий: {categories_count}. Расхождений между indirect_cost и allocations: {mismatch_count}."
            )
            return self._make_autotest_result(
                "Косвенные расходы",
                ok,
                "Косвенные расходы согласованы." if ok else "Найдены расхождения по косвенным расходам.",
                details,
            )
        except Exception as e:
            return self._make_autotest_result("Косвенные расходы", False, "Ошибка автотеста косвенных расходов.", str(e))

    def _run_reports_autotest(self):
        try:
            start = date.today().replace(day=1).isoformat()
            end = date.today().isoformat()
            pnl_text = self.getProfitLossReport(start, end)
            tax_report = self.calculateTaxReport(start, end, 6.0)
            formula_case = self._build_random_report_case()
            left, right, expected_sum = self._random_int_pair()
            expected_gross = formula_case["revenue"] - formula_case["cogs"]
            expected_net = expected_gross - formula_case["salary"] - formula_case["tools"]
            ok = (
                bool(pnl_text)
                and "Ошибка" not in pnl_text
                and isinstance(tax_report, dict)
                and "tax" in tax_report
                and expected_gross == formula_case["gross_profit"]
                and expected_net == formula_case["net_profit"]
                and (left + right) == expected_sum
            )
            details = (
                f"Контрольная формула: {left} + {right} = {expected_sum}. "
                f"Формула отчёта: {formula_case['revenue']} - {formula_case['cogs']} = {expected_gross}; "
                f"{expected_gross} - {formula_case['salary']} - {formula_case['tools']} = {expected_net}. "
                f"Отчёт P&L: {len(pnl_text or '')} символов. Налоговый отчёт: база={tax_report.get('base', 0)}, налог={tax_report.get('tax', 0)}."
            )
            return self._make_autotest_result(
                "Отчёты",
                ok,
                "Отчёты формируются корректно." if ok else "Ошибка формирования отчётов.",
                details,
            )
        except Exception as e:
            return self._make_autotest_result("Отчёты", False, "Ошибка автотеста отчётов.", str(e))

    def _run_export_autotest(self):
        try:
            excel_result = self.exportFullDatabaseToExcel()
            dump_result = self.exportDatabaseDump()
            excel_ok = bool(excel_result.get("ok")) and Path(excel_result.get("path", "")).exists()
            dump_ok = bool(dump_result.get("ok")) and Path(dump_result.get("path", "")).exists()
            ok = excel_ok and dump_ok
            details = (
                f"Excel: {'OK' if excel_ok else excel_result.get('message', 'ошибка')}. "
                f"Dump: {'OK' if dump_ok else dump_result.get('message', 'ошибка')}."
            )
            if excel_ok:
                try:
                    Path(excel_result.get("path", "")).unlink(missing_ok=True)
                except Exception:
                    pass
            if dump_ok:
                try:
                    Path(dump_result.get("path", "")).unlink(missing_ok=True)
                except Exception:
                    pass
            return self._make_autotest_result(
                "Экспорт",
                ok,
                "Экспорт работает корректно." if ok else "Ошибка одного или нескольких экспортов.",
                details,
            )
        except Exception as e:
            return self._make_autotest_result("Экспорт", False, "Ошибка автотеста экспорта.", str(e))

    @Slot(result="QVariantList")
    def runAllAutotests(self):
        fifo_result = self.runFifoAutotest()
        results = [
            fifo_result,
            self._run_cost_autotest(),
            self._run_inventory_autotest(),
            self._run_transactions_autotest(),
            self._run_indirect_autotest(),
            self._run_reports_autotest(),
            self._run_export_autotest(),
        ]
        return results

    def _get_export_dir(self):
        export_dir = Path.cwd() / "exports"
        export_dir.mkdir(parents=True, exist_ok=True)
        return export_dir

    def _build_timestamped_path(self, filename):
        from datetime import datetime

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return self._get_export_dir() / f"{filename}_{timestamp}"

    def _make_unique_sheet_name(self, table_name, used_names):
        base_name = (table_name or "sheet").replace("/", "_").replace("\\", "_").replace("*", "_").replace("?", "_")
        base_name = base_name.replace("[", "(").replace("]", ")").replace(":", "_")
        base_name = base_name[:31] or "sheet"
        candidate = base_name
        counter = 2
        while candidate in used_names:
            suffix = f"_{counter}"
            candidate = f"{base_name[:31 - len(suffix)]}{suffix}"
            counter += 1
        used_names.add(candidate)
        return candidate

    def _find_pg_dump_path(self):
        direct_path = shutil.which("pg_dump") or shutil.which("pg_dump.exe")
        if direct_path:
            return direct_path

        search_masks = [
            r"C:\Program Files\PostgreSQL\*\bin\pg_dump.exe",
            r"C:\Program Files (x86)\PostgreSQL\*\bin\pg_dump.exe",
        ]
        matches = []
        for mask in search_masks:
            matches.extend(glob.glob(mask))
        if not matches:
            return ""
        matches.sort(reverse=True)
        return matches[0]

    def _find_psql_path(self):
        direct_path = shutil.which("psql") or shutil.which("psql.exe")
        if direct_path:
            return direct_path

        search_masks = [
            r"C:\Program Files\PostgreSQL\*\bin\psql.exe",
            r"C:\Program Files (x86)\PostgreSQL\*\bin\psql.exe",
        ]
        matches = []
        for mask in search_masks:
            matches.extend(glob.glob(mask))
        if not matches:
            return ""
        matches.sort(reverse=True)
        return matches[0]

    def _ensure_operations_log_schema(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS app_operations_log (
                        id SERIAL PRIMARY KEY,
                        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        operation_type VARCHAR(100) NOT NULL,
                        description TEXT NOT NULL,
                        amount DECIMAL(14, 2),
                        details TEXT
                    )
                """)
                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_app_operations_log_created_at
                    ON app_operations_log (created_at DESC)
                """)
            conn.commit()

    def _ensure_plate_cutting_schema(self):
        plate_types = [
            (1, "Текстолит"),
            (2, "Алюминий"),
            (3, "Фанера"),
            (4, "Поликарбонат"),
        ]
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS plate_material_types (
                        id INT PRIMARY KEY,
                        name VARCHAR(100) NOT NULL UNIQUE
                    )
                """)
                for plate_type_id, plate_type_name in plate_types:
                    cur.execute("""
                        INSERT INTO plate_material_types (id, name)
                        VALUES (%s, %s)
                        ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name
                    """, (plate_type_id, plate_type_name))
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS is_plate BOOLEAN DEFAULT FALSE")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS plate_material_type_id INT REFERENCES plate_material_types(id)")
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS plate_part_templates (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        plate_material_type_id INT NOT NULL REFERENCES plate_material_types(id),
                        part_unit VARCHAR(50) NOT NULL DEFAULT 'шт',
                        production_minutes INT NOT NULL DEFAULT 0,
                        drawing_file_path TEXT,
                        process_file_path TEXT,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE (name, plate_material_type_id)
                    )
                """)
                cur.execute("ALTER TABLE IF EXISTS material_conversions ADD COLUMN IF NOT EXISTS template_id INT REFERENCES plate_part_templates(id)")
                cur.execute("ALTER TABLE IF EXISTS plate_part_templates ADD COLUMN IF NOT EXISTS drawing_file_name TEXT")
                cur.execute("ALTER TABLE IF EXISTS plate_part_templates ADD COLUMN IF NOT EXISTS drawing_file_data BYTEA")
                cur.execute("ALTER TABLE IF EXISTS plate_part_templates ADD COLUMN IF NOT EXISTS process_file_name TEXT")
                cur.execute("ALTER TABLE IF EXISTS plate_part_templates ADD COLUMN IF NOT EXISTS process_file_data BYTEA")
                cur.execute("ALTER TABLE IF EXISTS plate_part_templates ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE")
            conn.commit()

    def _ensure_material_reservation_schema(self, cur):
        cur.execute("ALTER TABLE IF EXISTS purchases ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
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

    def _ensure_composite_materials_schema(self, cur):
        cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
        cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
        cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
        cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'Материалы'")
        cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS low_stock_threshold DECIMAL(12, 3) DEFAULT 1")
        cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS enough_stock_threshold DECIMAL(12, 3) DEFAULT 3")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS composite_material_recipes (
                id SERIAL PRIMARY KEY,
                output_material_id INT NOT NULL UNIQUE REFERENCES materials(id) ON DELETE CASCADE,
                output_quantity DECIMAL(12, 4) NOT NULL DEFAULT 1,
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS composite_material_recipe_items (
                id SERIAL PRIMARY KEY,
                recipe_id INT NOT NULL REFERENCES composite_material_recipes(id) ON DELETE CASCADE,
                material_id INT NOT NULL REFERENCES materials(id),
                quantity DECIMAL(12, 4) NOT NULL DEFAULT 0
            )
        """)

    def _read_plate_template_file(self, source_path):
        clean_source = (source_path or "").strip()
        if not clean_source:
            return {"path": "", "name": "", "data": None}
        try:
            source = Path(clean_source)
            if not source.exists() or not source.is_file():
                return {"path": clean_source, "name": Path(clean_source).name, "data": None}
            return {"path": clean_source, "name": source.name, "data": source.read_bytes()}
        except Exception as e:
            print(f"Error reading template file: {e}")
            return {"path": clean_source, "name": Path(clean_source).name if clean_source else "", "data": None}

    def _export_plate_template_file(self, binary_data, fallback_path, fallback_name, target_path):
        save_target = (target_path or "").strip()
        if not save_target:
            return {"ok": False, "message": "No export path specified."}
        try:
            destination = Path(save_target)
            destination.parent.mkdir(parents=True, exist_ok=True)
            if binary_data is not None:
                destination.write_bytes(bytes(binary_data))
                return {"ok": True, "message": f"File exported: {destination}", "path": str(destination)}
            clean_fallback = (fallback_path or "").strip()
            if clean_fallback:
                source = Path(clean_fallback)
                if source.exists() and source.is_file():
                    shutil.copy2(source, destination)
                    return {"ok": True, "message": f"File exported: {destination}", "path": str(destination)}
            return {"ok": False, "message": f"File '{fallback_name or destination.name}' was not found and no binary data is available."}
        except Exception as e:
            return {"ok": False, "message": f"Error exporting file: {e}"}

    def _log_operation(self, operation_type, description, amount=None, details=None, operation_dt=None):
        try:
            self._ensure_operations_log_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO app_operations_log (created_at, operation_type, description, amount, details)
                        VALUES (COALESCE(%s, CURRENT_TIMESTAMP), %s, %s, %s, %s)
                    """, (
                        operation_dt,
                        (operation_type or "").strip() or "Операция",
                        (description or "").strip() or "Действие в программе",
                        Decimal(str(amount)).quantize(Decimal("0.01")) if amount not in (None, "") else None,
                        details.strip() if isinstance(details, str) and details.strip() else None
                    ))
                conn.commit()
        except Exception as e:
            print(f"Ошибка записи операции: {e}")

    def _get_recent_operations(self, limit):
        self._ensure_operations_log_schema()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT created_at, operation_type, description, amount
                    FROM app_operations_log
                    ORDER BY created_at DESC, id DESC
                    LIMIT %s
                """, (max(1, int(limit or 10)),))
                rows = cur.fetchall()
        return [
            {
                "date": row[0],
                "type": row[1] or "",
                "description": row[2] or "",
                "amount": row[3]
            }
            for row in rows
        ]

    @Slot(result="QVariantMap")
    def exportFullDatabaseToExcel(self):
        try:
            import pandas as pd
            from psycopg2 import sql

            filepath = self._build_timestamped_path("database_export").with_suffix(".xlsx")
            used_sheet_names = set()

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT table_name
                        FROM information_schema.tables
                        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
                        ORDER BY table_name
                    """)
                    table_names = [row[0] for row in cur.fetchall()]

                with pd.ExcelWriter(filepath, engine="openpyxl") as writer:
                    for table_name in table_names:
                        query = sql.SQL("SELECT * FROM {}").format(sql.Identifier(table_name)).as_string(conn)
                        df = pd.read_sql_query(query, conn)
                        sheet_name = self._make_unique_sheet_name(table_name, used_sheet_names)
                        df.to_excel(writer, sheet_name=sheet_name, index=False)

                        worksheet = writer.sheets[sheet_name]
                        if df.empty and len(df.columns) == 0:
                            continue
                        for column_cells in worksheet.columns:
                            max_length = 0
                            column_letter = column_cells[0].column_letter
                            for cell in column_cells:
                                value = "" if cell.value is None else str(cell.value)
                                max_length = max(max_length, len(value))
                            worksheet.column_dimensions[column_letter].width = min(max(max_length + 2, 12), 45)

            return {
                "ok": True,
                "message": f"Выгрузка базы в Excel завершена: {filepath}",
                "path": str(filepath)
            }
        except Exception as e:
            print(f"Ошибка выгрузки всей базы в Excel: {e}")
            return {
                "ok": False,
                "message": f"Ошибка выгрузки базы в Excel: {e}",
                "path": ""
            }

    @Slot(result="QVariantMap")
    def exportDatabaseDump(self):
        try:
            from backend.db.config import get_db_config

            pg_dump_path = self._find_pg_dump_path()
            if not pg_dump_path:
                return {
                    "ok": False,
                    "message": "Не найден pg_dump. Установите PostgreSQL client tools или добавьте pg_dump в PATH.",
                    "path": ""
                }

            db_config = get_db_config()
            filepath = self._build_timestamped_path("database_dump").with_suffix(".sql")
            env = os.environ.copy()
            env["PGPASSWORD"] = db_config["password"]
            env["PGCLIENTENCODING"] = "UTF8"
            env["PGSSLMODE"] = self._resolve_sslmode(db_config["host"], db_config.get("sslmode", ""))
            sslrootcert = str(db_config.get("sslrootcert", "") or "").strip()
            if sslrootcert:
                env["PGSSLROOTCERT"] = sslrootcert

            command = [
                pg_dump_path,
                "-h", str(db_config["host"]),
                "-p", str(db_config["port"]),
                "-U", str(db_config["user"]),
                "-d", str(db_config["dbname"]),
                "-F", "p",
                "--encoding=UTF8",
                "-f", str(filepath),
            ]
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                env=env,
                timeout=180
            )
            if result.returncode != 0:
                error_text = (result.stderr or result.stdout or "pg_dump завершился с ошибкой").strip()
                return {
                    "ok": False,
                    "message": f"Ошибка создания дампа: {error_text}",
                    "path": ""
                }

            return {
                "ok": True,
                "message": f"Дамп базы создан: {filepath}",
                "path": str(filepath)
            }
        except Exception as e:
            print(f"Ошибка создания дампа базы: {e}")
            return {
                "ok": False,
                "message": f"Ошибка создания дампа базы: {e}",
                "path": ""
            }

    @Slot(str, result="QVariantMap")
    def importDatabaseDump(self, dump_path):
        try:
            from backend.db.config import get_db_config
            from backend.db.schema import init_db

            source_path = Path(dump_path or "").expanduser()
            if not source_path.exists() or not source_path.is_file():
                return {
                    "ok": False,
                    "message": "\u0424\u0430\u0439\u043b \u0434\u0430\u043c\u043f\u0430 \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d.",
                    "path": str(source_path)
                }

            psql_path = self._find_psql_path()
            if not psql_path:
                return {
                    "ok": False,
                    "message": "\u041d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d psql. \u0423\u0441\u0442\u0430\u043d\u043e\u0432\u0438\u0442\u0435 PostgreSQL client tools \u0438\u043b\u0438 \u0434\u043e\u0431\u0430\u0432\u044c\u0442\u0435 psql \u0432 PATH.",
                    "path": str(source_path)
                }

            import_path = source_path
            normalized_dump_path = None
            dump_text = source_path.read_text(encoding="utf-8", errors="replace")
            if "\n\\restrict " in dump_text or "\n\\unrestrict " in dump_text or dump_text.startswith("\\restrict "):
                normalized_lines = []
                for line in dump_text.splitlines():
                    if line.startswith("\\restrict ") or line.startswith("\\unrestrict "):
                        continue
                    normalized_lines.append(line)
                normalized_dump_path = self._build_timestamped_path("database_dump_import").with_suffix(".sql")
                normalized_dump_path.write_text("\n".join(normalized_lines) + "\n", encoding="utf-8")
                import_path = normalized_dump_path

            db_config = get_db_config()
            env = os.environ.copy()
            env["PGPASSWORD"] = db_config["password"]
            env["PGCLIENTENCODING"] = "UTF8"
            env["PGSSLMODE"] = self._resolve_sslmode(db_config["host"], db_config.get("sslmode", ""))
            sslrootcert = str(db_config.get("sslrootcert", "") or "").strip()
            if sslrootcert:
                env["PGSSLROOTCERT"] = sslrootcert
            common_args = [
                psql_path,
                "-h", str(db_config["host"]),
                "-p", str(db_config["port"]),
                "-U", str(db_config["user"]),
                "-d", str(db_config["dbname"]),
                "-v", "ON_ERROR_STOP=1",
            ]

            reset_result = subprocess.run(
                common_args + [
                    "-c",
                    "DROP SCHEMA IF EXISTS public CASCADE; "
                    "CREATE SCHEMA public; "
                    "GRANT ALL ON SCHEMA public TO PUBLIC;"
                ],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                env=env,
                timeout=180
            )
            if reset_result.returncode != 0:
                error_text = (reset_result.stderr or reset_result.stdout or "\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u0431\u0440\u043e\u0441\u0438\u0442\u044c \u0441\u0445\u0435\u043c\u0443").strip()
                return {
                    "ok": False,
                    "message": f"\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u0431\u0440\u043e\u0441\u0438\u0442\u044c \u0442\u0435\u043a\u0443\u0449\u0443\u044e \u0431\u0430\u0437\u0443: {error_text}",
                    "path": str(source_path)
                }

            import_result = subprocess.run(
                common_args + ["-f", str(import_path)],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                env=env,
                timeout=600
            )
            if import_result.returncode != 0:
                error_text = (import_result.stderr or import_result.stdout or "\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0438\u043c\u043f\u043e\u0440\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0434\u0430\u043c\u043f").strip()
                return {
                    "ok": False,
                    "message": f"\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0438\u043c\u043f\u043e\u0440\u0442\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u0434\u0430\u043c\u043f: {error_text}",
                    "path": str(source_path)
                }

            init_db()
            self._ensure_indirect_schema()
            self._ensure_operations_log_schema()
            self._ensure_plate_cutting_schema()
            return {
                "ok": True,
                "message": normalized_dump_path
                    and "\u0414\u0430\u043c\u043f \u0437\u0430\u0433\u0440\u0443\u0436\u0435\u043d. \u0421\u043b\u0443\u0436\u0435\u0431\u043d\u044b\u0435 \u043a\u043e\u043c\u0430\u043d\u0434\u044b \\restrict/\\unrestrict \u0431\u044b\u043b\u0438 \u0430\u0432\u0442\u043e\u043c\u0430\u0442\u0438\u0447\u0435\u0441\u043a\u0438 \u0443\u0434\u0430\u043b\u0435\u043d\u044b \u0434\u043b\u044f \u0441\u043e\u0432\u043c\u0435\u0441\u0442\u0438\u043c\u043e\u0441\u0442\u0438. \u0415\u0441\u043b\u0438 \u043d\u0430 \u044d\u043a\u0440\u0430\u043d\u0430\u0445 \u0435\u0449\u0451 \u0432\u0438\u0434\u043d\u044b \u0441\u0442\u0430\u0440\u044b\u0435 \u0434\u0430\u043d\u043d\u044b\u0435, \u043f\u0435\u0440\u0435\u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0438\u0442\u0435\u0441\u044c \u0438\u043b\u0438 \u043f\u0435\u0440\u0435\u0437\u0430\u043f\u0443\u0441\u0442\u0438\u0442\u0435 \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u0435."
                    or "\u0414\u0430\u043c\u043f \u0431\u0430\u0437\u044b \u0443\u0441\u043f\u0435\u0448\u043d\u043e \u0437\u0430\u0433\u0440\u0443\u0436\u0435\u043d. \u0415\u0441\u043b\u0438 \u043d\u0430 \u043d\u0435\u043a\u043e\u0442\u043e\u0440\u044b\u0445 \u044d\u043a\u0440\u0430\u043d\u0430\u0445 \u0435\u0449\u0451 \u0432\u0438\u0434\u043d\u044b \u0441\u0442\u0430\u0440\u044b\u0435 \u0434\u0430\u043d\u043d\u044b\u0435, \u043f\u0435\u0440\u0435\u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0438\u0442\u0435\u0441\u044c \u0438\u043b\u0438 \u043f\u0435\u0440\u0435\u0437\u0430\u043f\u0443\u0441\u0442\u0438\u0442\u0435 \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u0435.",
                "path": str(source_path)
            }
        except Exception as e:
            print(f"\u041e\u0448\u0438\u0431\u043a\u0430 \u0438\u043c\u043f\u043e\u0440\u0442\u0430 \u0434\u0430\u043c\u043f\u0430: {e}")
            return {
                "ok": False,
                "message": f"\u041e\u0448\u0438\u0431\u043a\u0430 \u0438\u043c\u043f\u043e\u0440\u0442\u0430 \u0434\u0430\u043c\u043f\u0430: {e}",
                "path": dump_path or ""
            }

    @Slot(result="QVariantMap")
    def clearAllDatabaseData(self):
        try:
            from backend.db.schema import init_db

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT table_name
                        FROM information_schema.tables
                        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
                        ORDER BY table_name
                    """)
                    tables = [row[0] for row in cur.fetchall() if row and row[0]]
                    if tables:
                        cur.execute(
                            sql.SQL("TRUNCATE TABLE {} RESTART IDENTITY CASCADE").format(
                                sql.SQL(", ").join(sql.Identifier(table_name) for table_name in tables)
                            )
                        )
                conn.commit()

            init_db()
            self._ensure_indirect_schema()
            self._ensure_operations_log_schema()
            self._ensure_plate_cutting_schema()
            return {
                "ok": True,
                "message": "\u0412\u0441\u0435 \u0437\u0430\u043f\u0438\u0441\u0438 \u0432 \u0431\u0430\u0437\u0435 \u0443\u0434\u0430\u043b\u0435\u043d\u044b. \u0421\u0442\u0440\u0443\u043a\u0442\u0443\u0440\u0430 \u0442\u0430\u0431\u043b\u0438\u0446 \u0441\u043e\u0445\u0440\u0430\u043d\u0435\u043d\u0430.",
                "path": ""
            }
        except Exception as e:
            print(f"\u041e\u0448\u0438\u0431\u043a\u0430 \u043e\u0447\u0438\u0441\u0442\u043a\u0438 \u0431\u0430\u0437\u044b: {e}")
            return {
                "ok": False,
                "message": f"\u041e\u0448\u0438\u0431\u043a\u0430 \u043e\u0447\u0438\u0441\u0442\u043a\u0438 \u0431\u0430\u0437\u044b: {e}",
                "path": ""
            }

    def _ensure_indirect_schema(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS start_date DATE")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS indirect_cost DECIMAL(12, 2) DEFAULT 0")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS misc_expense_cost DECIMAL(12, 2) DEFAULT 0")
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS notes TEXT")
                cur.execute("ALTER TABLE IF EXISTS purchases ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                cur.execute("ALTER TABLE IF EXISTS balance ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS indirect_expense_categories (
                        id SERIAL PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        monthly_amount DECIMAL(12, 2) NOT NULL,
                        is_active BOOLEAN DEFAULT TRUE,
                        notes TEXT
                    )
                """)
                cur.execute("ALTER TABLE IF EXISTS indirect_expense_categories ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
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
                    CREATE TABLE IF NOT EXISTS misc_expenses (
                        id SERIAL PRIMARY KEY,
                        expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
                        title VARCHAR(255) NOT NULL,
                        amount DECIMAL(12, 2) NOT NULL,
                        notes TEXT,
                        is_cash BOOLEAN DEFAULT FALSE,
                        person_name VARCHAR(255),
                        allocation_mode VARCHAR(20) NOT NULL DEFAULT 'none',
                        balance_entry_id INT REFERENCES balance(id) ON DELETE SET NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS misc_expense_machine_links (
                        expense_id INT NOT NULL REFERENCES misc_expenses(id) ON DELETE CASCADE,
                        finished_good_id INT NOT NULL REFERENCES finished_goods(id) ON DELETE CASCADE,
                        allocated_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
                        PRIMARY KEY (expense_id, finished_good_id)
                    )
                """)
                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_misc_expenses_date
                    ON misc_expenses (expense_date DESC, id DESC)
                """)
                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_misc_expense_machine_links_fg
                    ON misc_expense_machine_links (finished_good_id)
                """)
                cur.execute("""
                    UPDATE finished_goods
                    SET start_date = COALESCE(start_date, produced_date, CURRENT_DATE)
                """)
            conn.commit()

    def _prepare_finished_goods_base_costs(self, cur, finished_good_ids=None):
        cur.execute("DROP TABLE IF EXISTS tmp_finished_goods_base_cost")
        if finished_good_ids:
            cur.execute("""
                CREATE TEMP TABLE tmp_finished_goods_base_cost AS
                SELECT id,
                       GREATEST(
                           cost_price
                           - COALESCE(indirect_cost, 0)
                           - COALESCE(misc_expense_cost, 0),
                           0
                       ) AS base_cost
                FROM finished_goods
                WHERE id = ANY(%s)
            """, (finished_good_ids,))
        else:
            cur.execute("""
                CREATE TEMP TABLE tmp_finished_goods_base_cost AS
                SELECT id,
                       GREATEST(
                           cost_price
                           - COALESCE(indirect_cost, 0)
                           - COALESCE(misc_expense_cost, 0),
                           0
                       ) AS base_cost
                FROM finished_goods
            """)

    def _refresh_misc_expense_totals(self, cur, finished_good_ids=None):
        if finished_good_ids:
            cur.execute("""
                UPDATE finished_goods
                SET misc_expense_cost = 0
                WHERE id = ANY(%s)
            """, (finished_good_ids,))
            cur.execute("""
                UPDATE finished_goods fg
                SET misc_expense_cost = t.sum_misc
                FROM (
                    SELECT finished_good_id, COALESCE(SUM(allocated_amount), 0)::DECIMAL(12, 2) AS sum_misc
                    FROM misc_expense_machine_links
                    WHERE finished_good_id = ANY(%s)
                    GROUP BY finished_good_id
                ) t
                WHERE fg.id = t.finished_good_id
            """, (finished_good_ids,))
        else:
            cur.execute("UPDATE finished_goods SET misc_expense_cost = 0")
            cur.execute("""
                UPDATE finished_goods fg
                SET misc_expense_cost = t.sum_misc
                FROM (
                    SELECT finished_good_id, COALESCE(SUM(allocated_amount), 0)::DECIMAL(12, 2) AS sum_misc
                    FROM misc_expense_machine_links
                    GROUP BY finished_good_id
                ) t
                WHERE fg.id = t.finished_good_id
            """)

    def _restore_finished_goods_totals(self, cur):
        cur.execute("""
            UPDATE finished_goods fg
            SET cost_price = COALESCE(t.base_cost, 0)
                           + COALESCE(fg.indirect_cost, 0)
                           + COALESCE(fg.misc_expense_cost, 0)
            FROM tmp_finished_goods_base_cost t
            WHERE fg.id = t.id
        """)
        cur.execute("DROP TABLE IF EXISTS tmp_finished_goods_base_cost")

    def _normalize_finished_good_ids(self, machine_ids):
        normalized = []
        for item in machine_ids or []:
            try:
                value = int(item)
            except (TypeError, ValueError):
                continue
            if value > 0 and value not in normalized:
                normalized.append(value)
        return normalized

    def _split_amount_evenly(self, amount, count):
        if count <= 0:
            return []
        total = Decimal(str(amount or 0)).quantize(Decimal("0.01"))
        if count == 1:
            return [total]
        share = (total / Decimal(count)).quantize(Decimal("0.01"))
        shares = [share for _ in range(count - 1)]
        remainder = total - sum(shares, Decimal("0.00"))
        shares.append(remainder.quantize(Decimal("0.01")))
        return shares

    def _ensure_bonus_schema(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS balance ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS employee_bonus_payments (
                        id SERIAL PRIMARY KEY,
                        period_start DATE NOT NULL,
                        period_end DATE NOT NULL,
                        bonus_percent DECIMAL(8, 2) NOT NULL,
                        base_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
                        bonus_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
                        paid_until DATE NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
            conn.commit()

    def _ensure_employee_settlement_schema(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS employee_settlements (
                        id SERIAL PRIMARY KEY,
                        employee_id INT REFERENCES employees(id) ON DELETE CASCADE,
                        settlement_type VARCHAR(20) NOT NULL,
                        settlement_date DATE NOT NULL DEFAULT CURRENT_DATE,
                        title VARCHAR(255) NOT NULL,
                        amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
            conn.commit()

    def _parse_period(self, start_date_str, end_date_str):
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
        if end_date < start_date:
            start_date, end_date = end_date, start_date
        return start_date, end_date

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
            ok = add_employee_gui(name, Decimal(str(rate)), position)
            if ok:
                self._log_operation(
                    "Сотрудники",
                    f"Добавлен сотрудник: {name}",
                    amount=rate,
                    details=f"Должность: {position or '-'}"
                )
            return ok
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
            self._log_operation(
                "Сотрудники",
                f"Изменен сотрудник: {name}",
                amount=rate,
                details=f"ID {emp_id}, должность: {position or '-'}, активен: {'Да' if active else 'Нет'}"
            )
            return True
        except Exception as e:
            print(f"Ошибка обновления сотрудника: {e}")
            return False

    @Slot(int, result=bool)
    def toggleEmployeeActive(self, emp_id):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE employees
                        SET active = NOT active
                        WHERE id = %s
                        RETURNING name, active
                    """, (emp_id,))
                    row = cur.fetchone()
                    conn.commit()
            if row:
                self._log_operation(
                    "Сотрудники",
                    f"Изменен статус сотрудника: {row[0]}",
                    details=f"ID {emp_id}, активен: {'Да' if row[1] else 'Нет'}"
                )
            return True
        except Exception as e:
            print(f"Ошибка изменения статуса: {e}")
            return False

    @Slot(int, result="QVariantMap")
    def deleteEmployee(self, emp_id):
        try:
            self._ensure_employee_settlement_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT name FROM employees WHERE id = %s", (emp_id,))
                    row = cur.fetchone()
                    if not row:
                        return {"ok": False, "message": "Сотрудник не найден"}

                    employee_name = row[0]

                    cur.execute("SELECT COUNT(*) FROM work_logs WHERE employee_id = %s", (emp_id,))
                    work_logs_count = int(cur.fetchone()[0] or 0)

                    cur.execute("SELECT COUNT(*) FROM employee_settlements WHERE employee_id = %s", (emp_id,))
                    settlements_count = int(cur.fetchone()[0] or 0)

                    if work_logs_count > 0 or settlements_count > 0:
                        return {
                            "ok": False,
                            "message": (
                                "Нельзя удалить сотрудника: есть связанные записи. "
                                f"Часы: {work_logs_count}, взаиморасчеты: {settlements_count}."
                            )
                        }

                    cur.execute("DELETE FROM employees WHERE id = %s", (emp_id,))
                    conn.commit()

            self._log_operation(
                "Employees",
                f"Deleted employee: {employee_name}",
                details=f"ID {emp_id}"
            )
            return {"ok": True, "message": f"Сотрудник {employee_name} удален"}
        except Exception as e:
            print(f"Error deleting employee: {e}")
            return {"ok": False, "message": f"Ошибка удаления сотрудника: {e}"}


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

            lines = [f"Зарплата за период {start_date} - {end_date}"]
            total = Decimal('0.00')
            for name, hours, rate in rows:
                hours = hours or Decimal('0.00')
                rate = rate or Decimal('0.00')
                amount = hours * rate
                total += amount
                lines.append(f"{name}: {hours:.2f} ч x {rate:.2f} = {amount:.2f} руб.")

            if len(rows) == 0:
                lines.append("Нет записей о работе за выбранный период.")

            lines.append("")
            lines.append(f"ИТОГО: {total:.2f} руб.")
            return "\n".join(lines)
        except Exception as e:
            print(f"Ошибка расчёта зарплаты: {e}")
            return f"Ошибка расчёта зарплаты: {e}"

    def _calculate_bonus_data(self, start_date_str, end_date_str, bonus_percent):
        start_date, end_date = self._parse_period(start_date_str, end_date_str)
        percent = Decimal(str(bonus_percent or 0)).quantize(Decimal("0.01"))
        if percent < 0:
            percent = Decimal("0.00")

        self._ensure_bonus_schema()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT e.name, COALESCE(SUM(wl.hours), 0) AS total_hours, COALESCE(e.hourly_rate, 0)
                    FROM employees e
                    JOIN work_logs wl ON e.id = wl.employee_id
                    WHERE wl.date BETWEEN %s AND %s
                    GROUP BY e.id, e.name, e.hourly_rate
                    ORDER BY e.name
                """, (start_date, end_date))
                rows = cur.fetchall()

        lines = [
            f"Период премии: {start_date} — {end_date}",
            f"Процент премии: {percent:.2f}%",
            ""
        ]
        base_total = Decimal("0.00")
        bonus_total = Decimal("0.00")
        for name, hours, rate in rows:
            hours = hours or Decimal("0.00")
            rate = rate or Decimal("0.00")
            base_amount = hours * rate
            bonus_amount = (base_amount * percent / Decimal("100")).quantize(Decimal("0.01"))
            base_total += base_amount
            bonus_total += bonus_amount
            lines.append(
                f"{name}: {hours:.2f} ч × {rate:.2f} = {base_amount:.2f} руб.; "
                f"премия {bonus_amount:.2f} руб."
            )

        if not rows:
            lines.append("За выбранный период нет записей о работе.")

        lines.extend([
            "",
            f"База для премии: {base_total:.2f} руб.",
            f"ИТОГО премия: {bonus_total:.2f} руб."
        ])
        return {
            "ok": True,
            "start_date": start_date,
            "end_date": end_date,
            "percent": percent,
            "base_total": base_total.quantize(Decimal("0.01")),
            "bonus_total": bonus_total.quantize(Decimal("0.01")),
            "text": "\n".join(lines)
        }

    @Slot(result=str)
    def getLastBonusPaidUntil(self):
        try:
            self._ensure_bonus_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT MAX(paid_until) FROM employee_bonus_payments")
                    row = cur.fetchone()
            return row[0].isoformat() if row and row[0] else ""
        except Exception as e:
            print(f"Ошибка чтения последней премии: {e}")
            return ""

    @Slot(str, str, float, result="QVariantMap")
    def calculateBonus(self, start_date_str, end_date_str, bonus_percent):
        try:
            data = self._calculate_bonus_data(start_date_str, end_date_str, bonus_percent)
            return {
                "ok": True,
                "text": data["text"],
                "base_amount": float(data["base_total"]),
                "bonus_amount": float(data["bonus_total"]),
                "paid_until": data["end_date"].isoformat()
            }
        except Exception as e:
            print(f"Ошибка расчёта премии: {e}")
            return {"ok": False, "message": f"Ошибка расчёта премии: {e}", "text": ""}

    @Slot(str, str, float, result="QVariantMap")
    def saveBonusPayment(self, start_date_str, end_date_str, bonus_percent):
        try:
            data = self._calculate_bonus_data(start_date_str, end_date_str, bonus_percent)
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO employee_bonus_payments
                            (period_start, period_end, bonus_percent, base_amount, bonus_amount, paid_until)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (
                        data["start_date"],
                        data["end_date"],
                        data["percent"],
                        data["base_total"],
                        data["bonus_total"],
                        data["end_date"]
                    ))
                    if data["bonus_total"] > 0:
                        cur.execute("""
                            INSERT INTO balance (date, expense, notes, is_cash)
                            VALUES (%s, %s, %s, FALSE)
                        """, (
                            data["end_date"],
                            data["bonus_total"],
                            f"Премия сотрудникам за период {data['start_date']} — {data['end_date']} ({data['percent']:.2f}%)"
                        ))
                conn.commit()
            self._log_operation(
                "Налоги",
                f"Сохранена уплата налога за период {period_start} - {period_end}",
                amount=amount,
                details=f"Ставка: {rate}%, база: {tax_base}"
            )
            return {
                "ok": True,
                "message": f"Премия сохранена. Выписана по {data['end_date']}.",
                "text": data["text"],
                "base_amount": float(data["base_total"]),
                "bonus_amount": float(data["bonus_total"]),
                "paid_until": data["end_date"].isoformat()
            }
        except Exception as e:
            print(f"Ошибка сохранения премии: {e}")
            return {"ok": False, "message": f"Ошибка сохранения премии: {e}", "text": ""}

    @Slot(int, str, str, result="QVariantMap")
    def getEmployeeSettlementSummary(self, employee_id, start_date_str, end_date_str):
        try:
            start_date, end_date = self._parse_period(start_date_str, end_date_str)
            self._ensure_employee_settlement_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT COALESCE(SUM(wl.hours * COALESCE(e.hourly_rate, 0)), 0)
                        FROM work_logs wl
                        JOIN employees e ON e.id = wl.employee_id
                        WHERE wl.employee_id = %s AND wl.date BETWEEN %s AND %s
                    """, (employee_id, start_date, end_date))
                    salary_accrued = cur.fetchone()[0] or Decimal("0.00")
                    cur.execute("""
                        SELECT
                            COALESCE(SUM(CASE WHEN settlement_type = 'salary' THEN amount ELSE 0 END), 0),
                            COALESCE(SUM(CASE WHEN settlement_type = 'service' THEN amount ELSE 0 END), 0)
                        FROM employee_settlements
                        WHERE employee_id = %s AND settlement_date BETWEEN %s AND %s
                    """, (employee_id, start_date, end_date))
                    salary_paid, service_total = cur.fetchone()
                    salary_paid = salary_paid or Decimal("0.00")
                    service_total = service_total or Decimal("0.00")
                    cur.execute("""
                        SELECT id, settlement_type, settlement_date, title, amount, COALESCE(notes, '')
                        FROM employee_settlements
                        WHERE employee_id = %s AND settlement_date BETWEEN %s AND %s
                        ORDER BY settlement_date DESC, id DESC
                    """, (employee_id, start_date, end_date))
                    rows = cur.fetchall()

            salary_balance = salary_paid - salary_accrued
            total_employee_debt = (salary_accrued - salary_paid) + service_total
            entries = []
            for row_id, settlement_type, settlement_date, title, amount, notes in rows:
                entries.append({
                    "id": row_id,
                    "type": settlement_type,
                    "type_label": "Зарплата" if settlement_type == "salary" else "Услуга",
                    "date": settlement_date.isoformat() if settlement_date else "",
                    "title": title,
                    "amount": float(amount or 0),
                    "notes": notes
                })
            return {
                "ok": True,
                "salary_accrued": float(salary_accrued),
                "salary_paid": float(salary_paid),
                "salary_balance": float(salary_balance),
                "service_balance": float(service_total),
                "total_balance": float(total_employee_debt),
                "entries": entries
            }
        except Exception as e:
            print(f"Ошибка расчёта взаиморасчётов сотрудника: {e}")
            return {"ok": False, "message": f"Ошибка расчёта взаиморасчётов: {e}", "entries": []}

    @Slot(int, str, str, str, float, result="QVariantMap")
    def addEmployeeSettlement(self, employee_id, settlement_type, settlement_date_str, title, amount):
        try:
            from datetime import datetime, date
            self._ensure_employee_settlement_schema()
            clean_type = settlement_type if settlement_type in ("salary", "service") else "service"
            settlement_date = datetime.strptime(settlement_date_str, "%Y-%m-%d").date() if settlement_date_str else date.today()
            clean_title = (title or "").strip()
            if not clean_title:
                return {"ok": False, "message": "Укажите название записи."}
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO employee_settlements
                            (employee_id, settlement_type, settlement_date, title, amount)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (
                        employee_id,
                        clean_type,
                        settlement_date,
                        clean_title,
                        Decimal(str(amount or 0))
                    ))
                conn.commit()
            return {"ok": True, "message": "Запись добавлена."}
        except Exception as e:
            print(f"Ошибка добавления взаиморасчёта сотрудника: {e}")
            return {"ok": False, "message": f"Ошибка добавления записи: {e}"}

    @Slot(int, result="QVariantMap")
    def deleteEmployeeSettlement(self, settlement_id):
        try:
            self._ensure_employee_settlement_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("DELETE FROM employee_settlements WHERE id = %s", (settlement_id,))
                conn.commit()
            return {"ok": True, "message": "Запись удалена."}
        except Exception as e:
            print(f"Ошибка удаления взаиморасчёта сотрудника: {e}")
            return {"ok": False, "message": f"Ошибка удаления записи: {e}"}

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
        """Возвращает список станков в активной работе (статус 'in_progress')."""
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
                "display": f"{row[1]} (ID {row[0]}, дата {row[2]})"
            } 
            for row in rows
        ]


    # ---------- Прочие расходы и привязки ----------
    @Slot(result="QVariantList")
    def getMiscExpenseMachineTargets(self):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT
                            fg.id,
                            fg.machine_model,
                            fg.status,
                            COALESCE(fg.inventory_number, ''),
                            COALESCE(fg.start_date, fg.produced_date, fg.sale_date),
                            COALESCE(fg.buyer, '')
                        FROM finished_goods fg
                        ORDER BY
                            CASE fg.status
                                WHEN 'in_progress' THEN 1
                                WHEN 'completed' THEN 2
                                WHEN 'sold' THEN 3
                                ELSE 4
                            END,
                            COALESCE(fg.start_date, fg.produced_date, fg.sale_date) DESC,
                            fg.id DESC
                    """)
                    rows = cur.fetchall()
            status_labels = {
                "in_progress": "В производстве",
                "completed": "На складе",
                "sold": "Продан",
            }
            result = []
            for fg_id, machine_model, status, inventory_number, ref_date, buyer in rows:
                status_label = status_labels.get(status, status or "-")
                parts = [f"{machine_model} (ID {fg_id})", status_label]
                if inventory_number:
                    parts.append(f"ID станка: {inventory_number}")
                if status == "sold" and buyer:
                    parts.append(f"Покупатель: {buyer}")
                if ref_date:
                    parts.append(str(ref_date))
                result.append({
                    "id": fg_id,
                    "machine_model": machine_model or "",
                    "status": status or "",
                    "status_label": status_label,
                    "inventory_number": inventory_number or "",
                    "display": " | ".join(parts),
                })
            return result
        except Exception as e:
            print(f"Ошибка получения списка станков для прочих расходов: {e}")
            return []

    @Slot(result="QVariantList")
    def getMiscExpenses(self):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT
                            me.id,
                            me.expense_date,
                            me.title,
                            me.amount,
                            COALESCE(me.notes, ''),
                            COALESCE(me.is_cash, FALSE),
                            COALESCE(me.person_name, ''),
                            me.allocation_mode,
                            COUNT(ml.finished_good_id),
                            COALESCE(
                                STRING_AGG(
                                    fg.machine_model || ' (ID ' || fg.id || ')',
                                    ', '
                                    ORDER BY fg.machine_model, fg.id
                                ) FILTER (WHERE fg.id IS NOT NULL),
                                ''
                            )
                        FROM misc_expenses me
                        LEFT JOIN misc_expense_machine_links ml ON ml.expense_id = me.id
                        LEFT JOIN finished_goods fg ON fg.id = ml.finished_good_id
                        GROUP BY me.id
                        ORDER BY me.expense_date DESC, me.id DESC
                    """)
                    rows = cur.fetchall()
            result = []
            for expense_id, expense_date, title, amount, notes, is_cash, person_name, allocation_mode, machine_count, machine_list in rows:
                if allocation_mode == "none":
                    target_summary = "Без привязки к станкам"
                elif allocation_mode == "all":
                    target_summary = f"Все станки ({int(machine_count or 0)})"
                else:
                    target_summary = machine_list or "Выбранные станки"
                result.append({
                    "id": expense_id,
                    "date": expense_date.isoformat() if expense_date else "",
                    "title": title or "",
                    "amount": float(amount or 0),
                    "notes": notes or "",
                    "is_cash": bool(is_cash),
                    "person_name": person_name or "",
                    "allocation_mode": allocation_mode or "none",
                    "machine_count": int(machine_count or 0),
                    "target_summary": target_summary,
                })
            return result
        except Exception as e:
            print(f"Ошибка получения прочих расходов: {e}")
            return []

    @Slot(str, str, float, bool, str, str, str, "QVariantList", result="QVariantMap")
    def addMiscExpense(self, expense_date_str, title, amount, is_cash, person_name, notes, allocation_mode, machine_ids):
        try:
            from datetime import date, datetime

            self._ensure_indirect_schema()
            expense_date = datetime.strptime(expense_date_str, "%Y-%m-%d").date() if expense_date_str else date.today()
            expense_title = (title or "").strip()
            if not expense_title:
                return {"ok": False, "message": "Укажите название расхода."}

            amount_decimal = Decimal(str(amount or 0)).quantize(Decimal("0.01"))
            if amount_decimal <= 0:
                return {"ok": False, "message": "Сумма расхода должна быть больше нуля."}

            mode = (allocation_mode or "none").strip().lower()
            if mode not in ("none", "selected", "all"):
                mode = "none"

            requested_ids = self._normalize_finished_good_ids(machine_ids)

            with get_connection() as conn:
                with conn.cursor() as cur:
                    target_ids = []
                    if mode == "all":
                        cur.execute("SELECT id FROM finished_goods ORDER BY id")
                        target_ids = [row[0] for row in cur.fetchall()]
                    elif mode == "selected":
                        if not requested_ids:
                            return {"ok": False, "message": "Выберите хотя бы один станок для привязки расхода."}
                        cur.execute("SELECT id FROM finished_goods WHERE id = ANY(%s) ORDER BY id", (requested_ids,))
                        target_ids = [row[0] for row in cur.fetchall()]
                        if not target_ids:
                            return {"ok": False, "message": "Не удалось найти выбранные станки."}

                    if target_ids:
                        self._prepare_finished_goods_base_costs(cur, target_ids)

                    cur.execute("""
                        INSERT INTO misc_expenses (expense_date, title, amount, notes, is_cash, person_name, allocation_mode)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        RETURNING id
                    """, (
                        expense_date,
                        expense_title,
                        amount_decimal,
                        notes.strip() if notes else None,
                        bool(is_cash),
                        person_name.strip() if person_name else None,
                        mode,
                    ))
                    expense_id = cur.fetchone()[0]

                    person_part = f", лицо: {person_name.strip()}" if person_name and person_name.strip() else ""
                    target_part = ""
                    if mode == "all":
                        target_part = ", привязка: все станки"
                    elif mode == "selected":
                        target_part = f", привязка: {len(target_ids)} шт."

                    cur.execute("""
                        INSERT INTO balance (date, expense, notes, is_cash)
                        VALUES (%s, %s, %s, %s)
                        RETURNING id
                    """, (
                        expense_date,
                        amount_decimal,
                        f"Прочий расход: {expense_title}{person_part}{target_part}",
                        bool(is_cash),
                    ))
                    balance_id = cur.fetchone()[0]
                    cur.execute("UPDATE misc_expenses SET balance_entry_id = %s WHERE id = %s", (balance_id, expense_id))

                    if target_ids:
                        shares = self._split_amount_evenly(amount_decimal, len(target_ids))
                        for fg_id, allocated_amount in zip(target_ids, shares):
                            cur.execute(
                                "INSERT INTO misc_expense_machine_links (expense_id, finished_good_id, allocated_amount) VALUES (%s, %s, %s)",
                                (expense_id, fg_id, allocated_amount),
                            )
                        self._refresh_misc_expense_totals(cur, target_ids)
                        self._restore_finished_goods_totals(cur)

                conn.commit()

            self._log_operation(
                "Прочие расходы",
                f"Добавлен прочий расход: {expense_title}",
                amount=amount_decimal,
                details=f"Режим: {mode}, лицо: {person_name or '-'}",
            )
            return {"ok": True, "message": "Прочий расход сохранён."}
        except Exception as e:
            print(f"Ошибка сохранения прочего расхода: {e}")
            return {"ok": False, "message": f"Ошибка сохранения прочего расхода: {e}"}

    @Slot(int, result="QVariantMap")
    def deleteMiscExpense(self, expense_id):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT title, balance_entry_id FROM misc_expenses WHERE id = %s", (expense_id,))
                    row = cur.fetchone()
                    if not row:
                        return {"ok": False, "message": "Расход не найден."}
                    title, balance_entry_id = row

                    cur.execute("SELECT finished_good_id FROM misc_expense_machine_links WHERE expense_id = %s", (expense_id,))
                    target_ids = [r[0] for r in cur.fetchall()]

                    if target_ids:
                        self._prepare_finished_goods_base_costs(cur, target_ids)

                    cur.execute("DELETE FROM misc_expenses WHERE id = %s", (expense_id,))
                    if balance_entry_id:
                        cur.execute("DELETE FROM balance WHERE id = %s", (balance_entry_id,))

                    if target_ids:
                        self._refresh_misc_expense_totals(cur, target_ids)
                        self._restore_finished_goods_totals(cur)

                conn.commit()

            self._log_operation("Прочие расходы", f"Удалён прочий расход: {title}")
            return {"ok": True, "message": "Прочий расход удалён."}
        except Exception as e:
            print(f"Ошибка удаления прочего расхода: {e}")
            return {"ok": False, "message": f"Ошибка удаления прочего расхода: {e}"}


    @Slot(int, int, float, str, result=bool)
    def logWorkHours(self, employee_id, finished_good_id, hours, notes):
        try:
            add_labor_to_finished_good(finished_good_id, employee_id, Decimal(str(hours)), notes)
            self._log_operation(
                "Операции",
                f"Добавлены трудозатраты по станку ID {finished_good_id}",
                amount=hours,
                details=f"Сотрудник ID {employee_id}, примечание: {notes or '-'}"
            )
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
            transactions = self._get_recent_operations(limit)
            if not transactions:
                transactions = get_recent_transactions(limit)
            result = []
            for t in transactions:
                result.append({
                    "date": t['date'].strftime("%d.%m.%Y %H:%M") if t.get('date') else "",
                    "type": t.get('type', ''),
                    "description": t.get('description', ''),
                    "amount": f"{t.get('amount', 0):.2f} RUB" if t.get('amount') not in (None, "") else ""
                })
            return result
        except Exception as e:
            print(f"Error loading materials list: {e}")
            return []

    # ---------- Материалы ----------
    @Slot(str, str, float, float, str, str, str, bool, float, float, result=bool)
    def addMaterial(self, name, unit, price, quantity, source, notes, updated_date_str, is_cash, low_stock_threshold, enough_stock_threshold):
        try:
            price_decimal = Decimal(str(price))
            quantity_decimal = Decimal(str(quantity))
            total_amount = price_decimal * quantity_decimal
            low_threshold_decimal = Decimal(str(low_stock_threshold or 1))
            enough_threshold_decimal = Decimal(str(enough_stock_threshold or 3))
            if low_threshold_decimal < 0:
                low_threshold_decimal = Decimal("1")
            if enough_threshold_decimal <= 0:
                enough_threshold_decimal = Decimal("3")
            if enough_threshold_decimal < low_threshold_decimal:
                enough_threshold_decimal = low_threshold_decimal
            from datetime import datetime, date
            updated_date = datetime.strptime(updated_date_str, "%Y-%m-%d").date() if updated_date_str else date.today()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS category VARCHAR(100) DEFAULT 'Материалы'")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS low_stock_threshold DECIMAL(12, 3) DEFAULT 1")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS enough_stock_threshold DECIMAL(12, 3) DEFAULT 3")
                    cur.execute("ALTER TABLE IF EXISTS purchases ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                    cur.execute("ALTER TABLE IF EXISTS balance ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                    cur.execute("""
                        INSERT INTO materials (name, unit, category, source, notes, updated_date, low_stock_threshold, enough_stock_threshold)
                        VALUES (%s, %s, 'Материалы', NULLIF(%s, ''), NULLIF(%s, ''), %s, %s, %s)
                        ON CONFLICT (name) DO UPDATE SET
                            unit = EXCLUDED.unit,
                            category = EXCLUDED.category,
                            source = COALESCE(EXCLUDED.source, materials.source),
                            notes = COALESCE(EXCLUDED.notes, materials.notes),
                            updated_date = EXCLUDED.updated_date,
                            low_stock_threshold = EXCLUDED.low_stock_threshold,
                            enough_stock_threshold = EXCLUDED.enough_stock_threshold
                        RETURNING id
                    """, (name, unit, source, notes, updated_date, low_threshold_decimal, enough_threshold_decimal))
                    mat_id = cur.fetchone()[0]
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes, is_cash)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s, %s)
                    """, (
                        mat_id,
                        price_decimal,
                        quantity_decimal,
                        quantity_decimal,
                        notes if notes else None,
                        bool(is_cash)
                    ))
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (mat_id, quantity_decimal))
                    cur.execute("""
                        INSERT INTO balance (date, expense, notes, is_cash)
                        VALUES (CURRENT_DATE, %s, %s, %s)
                    """, (
                        total_amount,
                        f"Покупка материала: {name} ({quantity_decimal} {unit or ''} x {price_decimal})",
                        bool(is_cash)
                    ))
                    conn.commit()
            self._log_operation(
                "Материалы",
                f"Добавлен материал: {name}",
                amount=total_amount,
                details=f"Количество: {quantity_decimal} {unit or '-'}, источник: {source or '-'}"
            )
            return True
        except Exception as e:
            print(f"Ошибка добавления материала: {e}")
            return False

    @Slot(result="QVariantList")
    def getPlateMaterialTypes(self):
        try:
            self._ensure_plate_cutting_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT id, name FROM plate_material_types ORDER BY id")
                    rows = cur.fetchall()
            return [{"id": row[0], "name": row[1]} for row in rows]
        except Exception as e:
            print(f"Error loading plate material types: {e}")
            return []

    @Slot(result="QVariantList")
    def getPlatePartTemplates(self):
        try:
            self._ensure_plate_cutting_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT
                            t.id,
                            t.name,
                            t.plate_material_type_id,
                            pt.name,
                            COALESCE(t.part_unit, '\u0448\u0442'),
                            COALESCE(t.production_minutes, 0),
                            COALESCE(t.drawing_file_path, ''),
                            COALESCE(t.process_file_path, ''),
                            COALESCE(t.drawing_file_name, ''),
                            COALESCE(t.process_file_name, ''),
                            COALESCE(octet_length(t.drawing_file_data), 0),
                            COALESCE(octet_length(t.process_file_data), 0),
                            COALESCE(t.notes, '')
                        FROM plate_part_templates t
                        JOIN plate_material_types pt ON pt.id = t.plate_material_type_id
                        WHERE COALESCE(t.is_active, TRUE) = TRUE
                        ORDER BY pt.id, t.name
                    """)
                    rows = cur.fetchall()
            return [
                {
                    "id": row[0],
                    "name": row[1] or "",
                    "material_type_id": row[2],
                    "material_type_name": row[3] or "",
                    "part_unit": row[4] or "\u0448\u0442",
                    "production_minutes": int(row[5] or 0),
                    "drawing_file_path": row[6] or "",
                    "process_file_path": row[7] or "",
                    "drawing_file_name": row[8] or (Path(row[6]).name if row[6] else ""),
                    "process_file_name": row[9] or (Path(row[7]).name if row[7] else ""),
                    "has_drawing_file": bool((row[10] or 0) > 0 or row[6]),
                    "has_process_file": bool((row[11] or 0) > 0 or row[7]),
                    "notes": row[12] or "",
                }
                for row in rows
            ]
        except Exception as e:
            print(f"Error loading plate part templates: {e}")
            return []

    @Slot(str, int, str, int, str, str, str, result="QVariantMap")
    def addPlatePartTemplate(self, name, material_type_id, part_unit, production_minutes, drawing_file_path, process_file_path, notes):
        try:
            clean_name = (name or "").strip()
            if not clean_name:
                return {"ok": False, "message": "Enter template name."}
            if int(material_type_id or 0) <= 0:
                return {"ok": False, "message": "Select plate material type."}
            self._ensure_plate_cutting_schema()
            unit = (part_unit or "\u0448\u0442").strip() or "\u0448\u0442"
            minutes = max(0, int(production_minutes or 0))
            drawing_info = self._read_plate_template_file(drawing_file_path)
            process_info = self._read_plate_template_file(process_file_path)
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO plate_part_templates
                            (name, plate_material_type_id, part_unit, production_minutes, drawing_file_path, process_file_path, drawing_file_name, drawing_file_data, process_file_name, process_file_data, notes, updated_at)
                        VALUES (%s, %s, %s, %s, NULLIF(%s, ''), NULLIF(%s, ''), NULLIF(%s, ''), %s, NULLIF(%s, ''), %s, NULLIF(%s, ''), CURRENT_TIMESTAMP)
                        ON CONFLICT (name, plate_material_type_id) DO UPDATE SET
                            part_unit = EXCLUDED.part_unit,
                            production_minutes = EXCLUDED.production_minutes,
                            drawing_file_path = EXCLUDED.drawing_file_path,
                            process_file_path = EXCLUDED.process_file_path,
                            drawing_file_name = EXCLUDED.drawing_file_name,
                            drawing_file_data = COALESCE(EXCLUDED.drawing_file_data, plate_part_templates.drawing_file_data),
                            process_file_name = EXCLUDED.process_file_name,
                            process_file_data = COALESCE(EXCLUDED.process_file_data, plate_part_templates.process_file_data),
                            notes = COALESCE(EXCLUDED.notes, plate_part_templates.notes),
                            is_active = TRUE,
                            updated_at = CURRENT_TIMESTAMP
                        RETURNING id
                    """, (
                        clean_name,
                        int(material_type_id),
                        unit,
                        minutes,
                        drawing_info["path"],
                        process_info["path"],
                        drawing_info["name"] or None,
                        __import__("psycopg2").Binary(drawing_info["data"]) if drawing_info["data"] is not None else None,
                        process_info["name"] or None,
                        __import__("psycopg2").Binary(process_info["data"]) if process_info["data"] is not None else None,
                        notes or "",
                    ))
                    template_id = cur.fetchone()[0]
                    conn.commit()
            self._log_operation(
                "Plate cutting",
                f"Plate part template saved: {clean_name}",
                details=f"Template ID {template_id}, material type ID {material_type_id}, time: {minutes} min."
            )
            return {"ok": True, "message": "Part template saved.", "id": int(template_id)}
        except Exception as e:
            print(f"Error saving plate part template: {e}")
            return {"ok": False, "message": f"Error saving template: {e}", "id": -1}

    @Slot(int, str, result="QVariantMap")
    def exportPlateTemplateDrawingFile(self, template_id, target_path):
        try:
            self._ensure_plate_cutting_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT COALESCE(drawing_file_data, NULL), COALESCE(drawing_file_path, ''), COALESCE(drawing_file_name, '')
                        FROM plate_part_templates
                        WHERE id = %s
                    """, (template_id,))
                    row = cur.fetchone()
            if not row:
                return {"ok": False, "message": "Template not found."}
            return self._export_plate_template_file(row[0], row[1], row[2], target_path)
        except Exception as e:
            return {"ok": False, "message": f"Error exporting drawing file: {e}"}

    @Slot(int, str, result="QVariantMap")
    def exportPlateTemplateProcessFile(self, template_id, target_path):
        try:
            self._ensure_plate_cutting_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT COALESCE(process_file_data, NULL), COALESCE(process_file_path, ''), COALESCE(process_file_name, '')
                        FROM plate_part_templates
                        WHERE id = %s
                    """, (template_id,))
                    row = cur.fetchone()
            if not row:
                return {"ok": False, "message": "Template not found."}
            return self._export_plate_template_file(row[0], row[1], row[2], target_path)
        except Exception as e:
            return {"ok": False, "message": f"Error exporting process file: {e}"}

    @Slot(int, result="QVariantMap")
    def deletePlatePartTemplate(self, template_id):
        try:
            self._ensure_plate_cutting_schema()
            if int(template_id or 0) <= 0:
                return {"ok": False, "message": "Шаблон детали не выбран."}
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT name
                        FROM plate_part_templates
                        WHERE id = %s
                    """, (int(template_id),))
                    row = cur.fetchone()
                    if not row:
                        return {"ok": False, "message": "Шаблон детали не найден."}
                    template_name = row[0] or ""
                    cur.execute("""
                        UPDATE plate_part_templates
                        SET is_active = FALSE,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = %s
                    """, (int(template_id),))
                    conn.commit()
            self._log_operation(
                "Раскрой плит",
                f"Удален шаблон детали: {template_name}",
                details=f"Шаблон #{template_id} скрыт из списка."
            )
            return {"ok": True, "message": f"Шаблон '{template_name}' удален."}
        except Exception as e:
            return {"ok": False, "message": f"Ошибка удаления шаблона: {e}"}

    @Slot(int, str, result="QVariantMap")
    def deletePlateLot(self, purchase_id, reason):
        try:
            self._ensure_plate_cutting_schema()
            if int(purchase_id or 0) <= 0:
                return {"ok": False, "message": "Плита не выбрана."}
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT
                            p.material_id,
                            COALESCE(p.remaining_quantity, 0),
                            m.name,
                            COALESCE(m.unit, 'м²')
                        FROM purchases p
                        JOIN materials m ON m.id = p.material_id
                        WHERE p.id = %s
                        FOR UPDATE OF p, m
                    """, (int(purchase_id),))
                    row = cur.fetchone()
                    if not row:
                        return {"ok": False, "message": "Плита не найдена."}
                    material_id, remaining_quantity, material_name, material_unit = row
                    remaining_quantity = Decimal(str(remaining_quantity or 0))
                    if remaining_quantity <= 0:
                        return {"ok": False, "message": "У выбранной плиты уже нет остатка."}
                    cur.execute("""
                        UPDATE purchases
                        SET remaining_quantity = 0,
                            notes = COALESCE(notes, '') ||
                                CASE WHEN COALESCE(notes, '') = '' THEN '' ELSE E'\n' END ||
                                %s
                        WHERE id = %s
                    """, (
                        f"Удалено из раскроя. Причина: {(reason or '').strip() or 'без указания причины'}",
                        int(purchase_id)
                    ))
                    cur.execute("""
                        UPDATE material_inventory
                        SET quantity = GREATEST(quantity - %s, 0)
                        WHERE material_id = %s
                    """, (remaining_quantity, material_id))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'write_off', %s)
                    """, (material_id, -remaining_quantity, int(purchase_id)))
                    conn.commit()
            self._log_operation(
                "Раскрой плит",
                f"Удалена плита из раскроя: {material_name}",
                details=f"Партия #{purchase_id}, списано {remaining_quantity} {material_unit}, причина: {(reason or '').strip() or 'без указания причины'}"
            )
            return {"ok": True, "message": f"Плита '{material_name}' удалена из раскроя."}
        except Exception as e:
            return {"ok": False, "message": f"Ошибка удаления плиты: {e}"}

    @Slot(int, str, float, float, str, str, str, bool, result=bool)
    def addPlate(self, material_type_id, name, price, quantity, source, notes, updated_date_str, is_cash):
        try:
            self._ensure_plate_cutting_schema()
            if int(material_type_id or 0) <= 0:
                return False
            from datetime import datetime, date
            updated_date = datetime.strptime(updated_date_str, "%Y-%m-%d").date() if updated_date_str else date.today()
            price_decimal = Decimal(str(price or 0))
            quantity_decimal = Decimal(str(quantity or 0))
            if price_decimal <= 0 or quantity_decimal <= 0:
                return False
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT name FROM plate_material_types WHERE id = %s", (int(material_type_id),))
                    row = cur.fetchone()
                    if not row:
                        return False
                    material_type_name = row[0]
                    material_name = material_type_name if not (name or "").strip() else f"{material_type_name} - {(name or '').strip()}"
                    total_amount = (price_decimal * quantity_decimal).quantize(Decimal("0.01"))
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                    cur.execute("ALTER TABLE IF EXISTS purchases ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                    cur.execute("ALTER TABLE IF EXISTS balance ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                    cur.execute("""
                        INSERT INTO materials (name, unit, category, source, notes, updated_date, is_plate, plate_material_type_id)
                        VALUES (%s, %s, 'Раскрой плит', NULLIF(%s, ''), NULLIF(%s, ''), %s, TRUE, %s)
                        ON CONFLICT (name) DO UPDATE SET
                            unit = EXCLUDED.unit,
                            category = EXCLUDED.category,
                            source = COALESCE(EXCLUDED.source, materials.source),
                            notes = COALESCE(EXCLUDED.notes, materials.notes),
                            updated_date = EXCLUDED.updated_date,
                            is_plate = TRUE,
                            plate_material_type_id = EXCLUDED.plate_material_type_id
                        RETURNING id
                    """, (material_name, "\u043c\u00b2", source, notes, updated_date, int(material_type_id)))
                    mat_id = cur.fetchone()[0]
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes, is_cash)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s, %s)
                    """, (mat_id, price_decimal, quantity_decimal, quantity_decimal, notes if notes else None, bool(is_cash)))
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (mat_id, quantity_decimal))
                    cur.execute("""
                        INSERT INTO balance (date, expense, notes, is_cash)
                        VALUES (CURRENT_DATE, %s, %s, %s)
                    """, (
                        total_amount,
                        f"Plate material purchase: {material_name} ({quantity_decimal} pcs x {price_decimal})",
                        bool(is_cash)
                    ))
                    conn.commit()
            self._log_operation(
                "Plate cutting",
                f"Plate added: {material_name}",
                amount=total_amount,
                details=f"Material: {material_type_name}, quantity: {quantity_decimal} pcs"
            )
            return True
        except Exception as e:
            print(f"Error adding plate: {e}")
            return False

    @Slot(int, int, float, float, str, str, result="QVariantMap")
    def convertPlateLotToTemplate(self, purchase_id, template_id, area_qty, part_qty, updated_date_str, notes):
        try:
            if purchase_id <= 0 or template_id <= 0:
                return {"ok": False, "message": "Select a plate lot and a template."}
            self._ensure_plate_cutting_schema()
            area = Decimal(str(area_qty or 0))
            quantity = Decimal(str(part_qty or 1))
            from datetime import datetime, date
            updated_date = datetime.strptime(updated_date_str, "%Y-%m-%d").date() if updated_date_str else date.today()
            if area <= 0:
                return {"ok": False, "message": "Write-off area must be greater than zero."}
            if quantity <= 0:
                return {"ok": False, "message": "Output quantity must be greater than zero."}
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT
                            p.material_id,
                            COALESCE(p.remaining_quantity, 0),
                            COALESCE(p.price_per_unit, 0),
                            m.name,
                            COALESCE(m.unit, ''),
                            m.plate_material_type_id,
                            pt.name
                        FROM purchases p
                        JOIN materials m ON m.id = p.material_id
                        LEFT JOIN plate_material_types pt ON pt.id = m.plate_material_type_id
                        WHERE p.id = %s
                        FOR UPDATE OF p, m
                    """, (purchase_id,))
                    purchase_row = cur.fetchone()
                    if not purchase_row:
                        return {"ok": False, "message": "Плита не найдена."}
                    source_material_id, lot_remaining, price_per_unit, source_name, source_unit, source_material_type_id, source_material_type_name = purchase_row
                    cur.execute("""
                        SELECT t.id, t.name, t.plate_material_type_id, COALESCE(t.part_unit, '\u0448\u0442'), COALESCE(t.production_minutes, 0),
                               COALESCE(drawing_file_path, ''), COALESCE(process_file_path, ''), COALESCE(notes, ''), pt.name
                        FROM plate_part_templates t
                        JOIN plate_material_types pt ON pt.id = t.plate_material_type_id
                        WHERE t.id = %s
                    """, (template_id,))
                    template_row = cur.fetchone()
                    if not template_row:
                        return {"ok": False, "message": "Шаблон детали не найден."}
                    _, template_name, template_material_type_id, part_unit, production_minutes, drawing_file_path, process_file_path, template_notes, template_material_type_name = template_row
                    if int(source_material_type_id or 0) != int(template_material_type_id or 0):
                        return {"ok": False, "message": f"Шаблон '{template_name}' можно делать только из материала '{template_material_type_name}'."}
                    lot_remaining = Decimal(str(lot_remaining or 0))
                    price_per_unit = Decimal(str(price_per_unit or 0))
                    if area > lot_remaining:
                        return {"ok": False, "message": f"В партии доступно {lot_remaining:.4f}, а требуется {area:.4f}."}
                    cur.execute("SELECT COALESCE(quantity, 0) FROM material_inventory WHERE material_id = %s FOR UPDATE", (source_material_id,))
                    inv_row = cur.fetchone()
                    inventory_qty = Decimal(str(inv_row[0] if inv_row else 0))
                    if area > inventory_qty:
                        return {"ok": False, "message": f"На складе доступно только {inventory_qty:.4f}."}
                    total_cost = (area * price_per_unit).quantize(Decimal("0.01"))
                    unit_price = (total_cost / quantity).quantize(Decimal("0.01"))
                    target_notes = (notes or "").strip() or template_notes or f"Деталь по шаблону: {template_name}"
                    cur.execute("""
                        INSERT INTO materials (name, unit, category, source, notes, updated_date, is_plate, plate_material_type_id)
                        VALUES (%s, %s, 'Раскрой плит', %s, %s, %s, FALSE, NULL)
                        ON CONFLICT (name) DO UPDATE SET
                            unit = EXCLUDED.unit,
                            category = EXCLUDED.category,
                            source = EXCLUDED.source,
                            notes = COALESCE(EXCLUDED.notes, materials.notes),
                            updated_date = EXCLUDED.updated_date
                        RETURNING id
                    """, (
                        template_name,
                        part_unit,
                        f"{source_material_type_name} / шаблон #{template_id}",
                        target_notes,
                        updated_date
                    ))
                    target_material_id = cur.fetchone()[0]
                    cur.execute("""
                        UPDATE purchases
                        SET remaining_quantity = GREATEST(COALESCE(remaining_quantity, 0) - %s, 0)
                        WHERE id = %s
                    """, (area, purchase_id))
                    cur.execute("""
                        UPDATE material_inventory
                        SET quantity = quantity - %s
                        WHERE material_id = %s
                    """, (area, source_material_id))
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity)
                        VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE
                        SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (target_material_id, quantity))
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s)
                    """, (
                        target_material_id,
                        unit_price,
                        quantity,
                        quantity,
                        f"Изготовлено из {source_name}, партия #{purchase_id}: списано {area} {source_unit}; время {production_minutes} мин."
                    ))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_out', %s)
                    """, (source_material_id, -area, target_material_id))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_in', %s)
                    """, (target_material_id, quantity, source_material_id))
                    cur.execute("""
                        INSERT INTO material_conversions
                            (source_material_id, source_purchase_id, target_material_id, template_id, source_quantity, target_quantity, total_cost, notes)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """, (
                        source_material_id,
                        purchase_id,
                        target_material_id,
                        template_id,
                        area,
                        quantity,
                        total_cost,
                        target_notes
                    ))
                    conn.commit()
            self._log_operation(
                "Раскрой плит",
                f"Изготовлена деталь по шаблону: {template_name}",
                amount=total_cost,
                details=f"Плита: {source_name}, материал: {source_material_type_name}, списано: {area} {source_unit}, получено: {quantity} {part_unit}, время: {production_minutes} мин., чертеж: {drawing_file_path or '-'}, файл обработки: {process_file_path or '-'}"
            )
            return {
                "ok": True,
                "message": f"Деталь '{template_name}' изготовлена. Списано {area:.4f} {source_unit}, получено {quantity:.4f} {part_unit}."
            }
        except Exception as e:
            print(f"Ошибка изготовления детали по шаблону: {e}")
            return {"ok": False, "message": f"Ошибка изготовления детали: {e}"}

    @Slot(str, result=bool)
    def parseAndAddMaterial(self, url):
        try:
            from backend.models.scraper import quick_add_product
            quick_add_product(url, notes=url)
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
            self._log_operation(
                "Материалы",
                f"Скорректирован остаток материала ID {material_id}",
                amount=diff,
                details=f"Старое количество: {old_qty}, новое количество: {new_qty}, причина: {reason or '-'}"
            )
            return True
        except Exception as e:
            print(f"Ошибка инвентаризации: {e}")
            return False

    @Slot(result="QVariantList")
    def getMaterialsList(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                cur.execute("SELECT id, name, COALESCE(unit, ''), COALESCE(source, '') FROM materials ORDER BY name")
                rows = cur.fetchall()
            conn.commit()
        return [{"id": row[0], "name": row[1], "unit": row[2] or "", "source": row[3] or ""} for row in rows]

    @Slot(result="QVariantList")
    def getCompositeMaterialRecipes(self):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_composite_materials_schema(cur)
                    cur.execute("""
                        SELECT
                            r.id,
                            m.id,
                            m.name,
                            COALESCE(m.unit, ''),
                            COALESCE(r.output_quantity, 1),
                            COALESCE(inv.quantity, 0),
                            COALESCE(m.source, ''),
                            COALESCE(m.notes, ''),
                            COALESCE(component_summary.component_count, 0),
                            COALESCE(component_summary.craftable, TRUE)
                        FROM composite_material_recipes r
                        JOIN materials m ON m.id = r.output_material_id
                        LEFT JOIN material_inventory inv ON inv.material_id = r.output_material_id
                        LEFT JOIN (
                            SELECT
                                ri.recipe_id,
                                COUNT(*) AS component_count,
                                BOOL_AND(COALESCE(mi.quantity, 0) >= COALESCE(ri.quantity, 0)) AS craftable
                            FROM composite_material_recipe_items ri
                            LEFT JOIN material_inventory mi ON mi.material_id = ri.material_id
                            GROUP BY ri.recipe_id
                        ) component_summary ON component_summary.recipe_id = r.id
                        ORDER BY m.name
                    """)
                    rows = cur.fetchall()
                    conn.commit()
            result = []
            for row in rows:
                component_count = int(row[8] or 0)
                craftable = bool(row[9]) if component_count > 0 else False
                status_key = "craftable" if craftable else ("empty" if component_count == 0 else "blocked")
                status_text = "Можно собрать" if craftable else ("Нет компонентов" if component_count == 0 else "Нельзя собрать")
                result.append({
                    "recipe_id": int(row[0]),
                    "material_id": int(row[1]),
                    "name": row[2] or "",
                    "unit": row[3] or "",
                    "output_quantity": float(row[4] or 1),
                    "stock_quantity": float(row[5] or 0),
                    "source": row[6] or "",
                    "notes": row[7] or "",
                    "component_count": component_count,
                    "craftable": craftable,
                    "status_key": status_key,
                    "status_text": status_text,
                })
            return result
        except Exception as e:
            print(f"Ошибка получения составных материалов: {e}")
            return []

    @Slot(int, result="QVariantList")
    def getCompositeMaterialRecipeItems(self, recipe_id):
        try:
            if recipe_id <= 0:
                return []
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_composite_materials_schema(cur)
                    cur.execute("""
                        SELECT
                            ri.id,
                            ri.material_id,
                            m.name,
                            COALESCE(m.unit, ''),
                            COALESCE(ri.quantity, 0),
                            COALESCE(inv.quantity, 0)
                        FROM composite_material_recipe_items ri
                        JOIN materials m ON m.id = ri.material_id
                        LEFT JOIN material_inventory inv ON inv.material_id = ri.material_id
                        WHERE ri.recipe_id = %s
                        ORDER BY m.name
                    """, (recipe_id,))
                    rows = cur.fetchall()
                    conn.commit()
            result = []
            for row in rows:
                required = float(row[4] or 0)
                in_stock = float(row[5] or 0)
                result.append({
                    "item_id": int(row[0]),
                    "material_id": int(row[1]),
                    "material_name": row[2] or "",
                    "unit": row[3] or "",
                    "required_quantity": required,
                    "in_stock": in_stock,
                    "enough": in_stock >= required
                })
            return result
        except Exception as e:
            print(f"Ошибка получения состава рецепта: {e}")
            return []

    @Slot(str, str, float, str, str, str, float, float, "QVariantList", result="QVariantMap")
    def addCompositeMaterialRecipe(self, name, unit, output_quantity, source, notes, updated_date_str, low_stock_threshold, enough_stock_threshold, components):
        try:
            from datetime import datetime, date

            clean_name = (name or "").strip()
            if not clean_name:
                return {"ok": False, "message": "Укажите название составного материала."}

            output_qty_dec = Decimal(str(output_quantity or 0))
            if output_qty_dec <= 0:
                return {"ok": False, "message": "Количество на выходе должно быть больше нуля."}

            updated_date = datetime.strptime(updated_date_str, "%Y-%m-%d").date() if updated_date_str else date.today()
            low_threshold_decimal = Decimal(str(low_stock_threshold or 1))
            enough_threshold_decimal = Decimal(str(enough_stock_threshold or 3))
            if low_threshold_decimal < 0:
                low_threshold_decimal = Decimal("1")
            if enough_threshold_decimal <= 0:
                enough_threshold_decimal = Decimal("3")
            if enough_threshold_decimal < low_threshold_decimal:
                enough_threshold_decimal = low_threshold_decimal

            normalized_components = []
            for item in components or []:
                material_id = int(item.get("material_id", 0) or 0)
                qty_dec = Decimal(str(item.get("quantity", 0) or 0))
                if material_id > 0 and qty_dec > 0:
                    normalized_components.append((material_id, qty_dec))
            if not normalized_components:
                return {"ok": False, "message": "Добавьте хотя бы один компонент."}

            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_composite_materials_schema(cur)
                    cur.execute("""
                        INSERT INTO materials (name, unit, category, source, notes, updated_date, low_stock_threshold, enough_stock_threshold)
                        VALUES (%s, %s, 'Составные', %s, %s, %s, %s, %s)
                        ON CONFLICT (name) DO UPDATE SET
                            unit = EXCLUDED.unit,
                            category = EXCLUDED.category,
                            source = EXCLUDED.source,
                            notes = COALESCE(EXCLUDED.notes, materials.notes),
                            updated_date = EXCLUDED.updated_date,
                            low_stock_threshold = EXCLUDED.low_stock_threshold,
                            enough_stock_threshold = EXCLUDED.enough_stock_threshold
                        RETURNING id
                    """, (
                        clean_name,
                        (unit or "шт").strip(),
                        (source or "Составной материал").strip(),
                        notes.strip() if notes else None,
                        updated_date,
                        low_threshold_decimal,
                        enough_threshold_decimal
                    ))
                    output_material_id = cur.fetchone()[0]

                    cur.execute("""
                        INSERT INTO composite_material_recipes (output_material_id, output_quantity, notes, updated_at)
                        VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
                        ON CONFLICT (output_material_id) DO UPDATE SET
                            output_quantity = EXCLUDED.output_quantity,
                            notes = EXCLUDED.notes,
                            updated_at = CURRENT_TIMESTAMP
                        RETURNING id
                    """, (
                        output_material_id,
                        output_qty_dec,
                        notes.strip() if notes else None
                    ))
                    recipe_id = cur.fetchone()[0]

                    for material_id, qty_dec in normalized_components:
                        if material_id == output_material_id:
                            conn.rollback()
                            return {"ok": False, "message": "Нельзя использовать материал самого рецепта как его компонент."}
                    cur.execute("DELETE FROM composite_material_recipe_items WHERE recipe_id = %s", (recipe_id,))
                    for material_id, qty_dec in normalized_components:
                        cur.execute("""
                            INSERT INTO composite_material_recipe_items (recipe_id, material_id, quantity)
                            VALUES (%s, %s, %s)
                        """, (recipe_id, material_id, qty_dec))
                conn.commit()

            self._log_operation(
                "Склад",
                f"Сохранён рецепт составного материала: {clean_name}",
                details=f"Компонентов: {len(normalized_components)}, выход: {output_qty_dec} {(unit or 'шт').strip()}"
            )
            return {"ok": True, "message": "Рецепт составного материала сохранён."}
        except Exception as e:
            print(f"Ошибка сохранения составного материала: {e}")
            return {"ok": False, "message": f"Ошибка сохранения рецепта: {e}"}

    @Slot(int, result="QVariantMap")
    def deleteCompositeMaterialRecipe(self, recipe_id):
        try:
            if recipe_id <= 0:
                return {"ok": False, "message": "Рецепт не выбран."}
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_composite_materials_schema(cur)
                    cur.execute("""
                        SELECT r.output_material_id, m.name
                        FROM composite_material_recipes r
                        JOIN materials m ON m.id = r.output_material_id
                        WHERE r.id = %s
                    """, (recipe_id,))
                    row = cur.fetchone()
                    if not row:
                        return {"ok": False, "message": "Рецепт не найден."}
                    output_material_id, material_name = row
                    cur.execute("DELETE FROM composite_material_recipes WHERE id = %s", (recipe_id,))
                    conn.commit()
            self._log_operation("Склад", f"Удалён рецепт составного материала: {material_name}")
            return {"ok": True, "message": "Рецепт удалён."}
        except Exception as e:
            print(f"Ошибка удаления рецепта: {e}")
            return {"ok": False, "message": f"Ошибка удаления рецепта: {e}"}

    @Slot(int, float, str, result="QVariantMap")
    def craftCompositeMaterial(self, recipe_id, batches, notes):
        try:
            from datetime import date
            from backend.models.production import _consume_material_fifo

            if recipe_id <= 0:
                return {"ok": False, "message": "Рецепт не выбран."}
            batches_dec = Decimal(str(batches or 0))
            if batches_dec <= 0:
                return {"ok": False, "message": "Количество партий должно быть больше нуля."}

            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_composite_materials_schema(cur)
                    cur.execute("""
                        SELECT
                            r.output_material_id,
                            m.name,
                            COALESCE(m.unit, ''),
                            COALESCE(r.output_quantity, 1),
                            COALESCE(m.source, '')
                        FROM composite_material_recipes r
                        JOIN materials m ON m.id = r.output_material_id
                        WHERE r.id = %s
                    """, (recipe_id,))
                    recipe_row = cur.fetchone()
                    if not recipe_row:
                        return {"ok": False, "message": "Рецепт не найден."}

                    output_material_id, output_name, output_unit, output_quantity, output_source = recipe_row
                    output_qty_total = Decimal(str(output_quantity or 1)) * batches_dec

                    cur.execute("""
                        SELECT ri.material_id, m.name, COALESCE(m.unit, ''), COALESCE(ri.quantity, 0)
                        FROM composite_material_recipe_items ri
                        JOIN materials m ON m.id = ri.material_id
                        WHERE ri.recipe_id = %s
                        ORDER BY m.name
                    """, (recipe_id,))
                    component_rows = cur.fetchall()
                    if not component_rows:
                        return {"ok": False, "message": "У рецепта нет компонентов."}

                    shortages = []
                    total_cost = Decimal("0.00")
                    for material_id, material_name, material_unit, base_qty in component_rows:
                        required_qty = Decimal(str(base_qty or 0)) * batches_dec
                        cur.execute("SELECT COALESCE(quantity, 0) FROM material_inventory WHERE material_id = %s FOR UPDATE", (material_id,))
                        inv_row = cur.fetchone()
                        in_stock = Decimal(str(inv_row[0] if inv_row else 0))
                        if in_stock < required_qty:
                            shortages.append(f"{material_name}: нужно {required_qty}, на складе {in_stock}")

                    if shortages:
                        return {"ok": False, "message": "Нельзя собрать материал: " + "; ".join(shortages)}

                    for material_id, material_name, material_unit, base_qty in component_rows:
                        required_qty = Decimal(str(base_qty or 0)) * batches_dec
                        cur.execute("""
                            UPDATE material_inventory
                            SET quantity = GREATEST(COALESCE(quantity, 0) - %s, 0)
                            WHERE material_id = %s
                        """, (required_qty, material_id))
                        cur.execute("""
                            INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                            VALUES (%s, %s, 'composite_out', %s)
                        """, (material_id, -required_qty, output_material_id))
                        total_cost += _consume_material_fifo(cur, material_id, required_qty)

                    unit_price = (total_cost / output_qty_total).quantize(Decimal("0.01")) if output_qty_total > 0 else Decimal("0.00")
                    craft_note = notes.strip() if notes else f"Составной материал: {output_name}"

                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity)
                        VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE
                        SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (output_material_id, output_qty_total))
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s)
                    """, (
                        output_material_id,
                        unit_price,
                        output_qty_total,
                        output_qty_total,
                        craft_note
                    ))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'composite_in', %s)
                    """, (output_material_id, output_qty_total, recipe_id))
                    cur.execute("""
                        UPDATE materials
                        SET updated_date = %s
                        WHERE id = %s
                    """, (date.today(), output_material_id))
                conn.commit()

            self._log_operation(
                "Склад",
                f"Собран составной материал: {output_name}",
                amount=total_cost,
                details=f"Партий: {batches_dec}, получено: {output_qty_total} {output_unit or ''}"
            )
            return {
                "ok": True,
                "message": f"Материал '{output_name}' изготовлен. Добавлено {output_qty_total:.4f} {output_unit or ''}. Себестоимость за единицу: {unit_price:.2f} руб."
            }
        except Exception as e:
            print(f"Ошибка изготовления составного материала: {e}")
            return {"ok": False, "message": f"Ошибка изготовления материала: {e}"}

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
                    """, (material_id, Decimal(str(new_price)), note if note else "Обновление цены за единицу"))
                    conn.commit()
            self._log_operation(
                "Материалы",
                f"Изменен материал: {name.strip()}",
                amount=new_price if new_price and new_price > 0 else None,
                details=f"ID {material_id}, количество: {quantity}, единица: {unit or '-'}, причина: {reason or '-'}"
            )
            return True
        except Exception as e:
            print(f"Ошибка обновления цены материала: {e}")
            return False

    @Slot(int, str, float, float, str, str, result="QVariantMap")
    def convertAreaMaterialToPart(self, source_material_id, part_name, area_qty, part_qty, part_unit, notes):
        try:
            if source_material_id <= 0:
                return {"ok": False, "message": "Выберите исходный материал."}
            clean_name = (part_name or "").strip()
            if not clean_name:
                return {"ok": False, "message": "Укажите название готовой детали."}
            area = Decimal(str(area_qty or 0))
            quantity = Decimal(str(part_qty or 1))
            if area <= 0:
                return {"ok": False, "message": "Площадь списания должна быть больше нуля."}
            if quantity <= 0:
                return {"ok": False, "message": "Количество деталей должно быть больше нуля."}

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                    cur.execute("""
                        CREATE TABLE IF NOT EXISTS material_conversions (
                            id SERIAL PRIMARY KEY,
                            source_material_id INT REFERENCES materials(id),
                            target_material_id INT REFERENCES materials(id),
                            source_quantity DECIMAL(12, 4) NOT NULL,
                            target_quantity DECIMAL(12, 4) NOT NULL,
                            total_cost DECIMAL(12, 2) NOT NULL DEFAULT 0,
                            notes TEXT,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """)
                    cur.execute("""
                        SELECT m.name, m.unit, COALESCE(inv.quantity, 0)
                        FROM materials m
                        LEFT JOIN material_inventory inv ON inv.material_id = m.id
                        WHERE m.id = %s
                    """, (source_material_id,))
                    source_row = cur.fetchone()
                    if not source_row:
                        return {"ok": False, "message": "Исходный материал не найден."}
                    source_name, source_unit, current_qty = source_row
                    current_qty = Decimal(str(current_qty or 0))
                    if area > current_qty:
                        return {
                            "ok": False,
                            "message": f"Недостаточно материала. На складе {current_qty:.4f}, нужно {area:.4f}."
                        }
                    if clean_name.lower() == (source_name or "").strip().lower():
                        return {"ok": False, "message": "Название детали должно отличаться от исходного материала."}

                    remaining_to_price = area
                    total_cost = Decimal("0.00")
                    cur.execute("""
                        SELECT id, COALESCE(remaining_quantity, 0), COALESCE(price_per_unit, 0)
                        FROM purchases
                        WHERE material_id = %s AND COALESCE(remaining_quantity, 0) > 0
                        ORDER BY purchase_date ASC, id ASC
                    """, (source_material_id,))
                    for purchase_id, remaining_qty, price in cur.fetchall():
                        if remaining_to_price <= 0:
                            break
                        take_qty = min(Decimal(str(remaining_qty or 0)), remaining_to_price)
                        if take_qty <= 0:
                            continue
                        total_cost += take_qty * Decimal(str(price or 0))
                        remaining_to_price -= take_qty
                        cur.execute("""
                            UPDATE purchases
                            SET remaining_quantity = GREATEST(COALESCE(remaining_quantity, 0) - %s, 0)
                            WHERE id = %s
                        """, (take_qty, purchase_id))

                    if remaining_to_price > 0:
                        cur.execute("""
                            SELECT COALESCE(price_per_unit, 0)
                            FROM purchases
                            WHERE material_id = %s AND price_per_unit IS NOT NULL
                            ORDER BY purchase_date DESC, id DESC
                            LIMIT 1
                        """, (source_material_id,))
                        price_row = cur.fetchone()
                        fallback_price = Decimal(str(price_row[0] if price_row else 0))
                        total_cost += remaining_to_price * fallback_price

                    unit_price = (total_cost / quantity).quantize(Decimal("0.01")) if quantity else Decimal("0.00")
                    target_notes = notes.strip() if notes else f"Деталь из материала: {source_name}"
                    cur.execute("""
                        INSERT INTO materials (name, unit, category, source, notes, updated_date)
                        VALUES (%s, %s, 'Раскрой плит', %s, %s, CURRENT_DATE)
                        ON CONFLICT (name) DO UPDATE SET
                            unit = EXCLUDED.unit,
                            category = EXCLUDED.category,
                            source = EXCLUDED.source,
                            notes = COALESCE(EXCLUDED.notes, materials.notes),
                            updated_date = CURRENT_DATE
                        RETURNING id
                    """, (
                        clean_name,
                        (part_unit or "шт").strip(),
                        source_name,
                        target_notes
                    ))
                    target_material_id = cur.fetchone()[0]

                    cur.execute("""
                        UPDATE material_inventory
                        SET quantity = quantity - %s
                        WHERE material_id = %s
                    """, (area, source_material_id))
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity)
                        VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE
                        SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (target_material_id, quantity))
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s)
                    """, (
                        target_material_id,
                        unit_price,
                        quantity,
                        quantity,
                        f"Изготовлено из {source_name}: списано {area} {source_unit or ''}"
                    ))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_out', %s)
                    """, (source_material_id, -area, target_material_id))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_in', %s)
                    """, (target_material_id, quantity, source_material_id))
                    cur.execute("""
                        INSERT INTO material_conversions
                            (source_material_id, target_material_id, source_quantity, target_quantity, total_cost, notes)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """, (
                        source_material_id,
                        target_material_id,
                        area,
                        quantity,
                        total_cost.quantize(Decimal("0.01")),
                        target_notes
                    ))
                    conn.commit()
            self._log_operation(
                "Раскрой плит",
                f"Создана новая деталь: {clean_name}",
                amount=total_cost,
                details=f"Плита: {source_name}, списано: {area} {source_unit}, получено: {quantity} {(part_unit or 'шт').strip()}"
            )
            return {
                "ok": True,
                "message": f"Готовая деталь создана. Списано {area:.4f} {source_unit or ''}, добавлено {quantity:.4f} {(part_unit or 'шт').strip()}. Цена детали: {unit_price:.2f} руб."
            }
        except Exception as e:
            print(f"Ошибка перевода материала в готовую деталь: {e}")
            return {"ok": False, "message": f"Ошибка перевода материала: {e}"}

    @Slot(int, result="QVariantList")
    def getPlateConversionHistory(self, purchase_id):
        try:
            if purchase_id <= 0:
                return []
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        SELECT
                            c.target_material_id,
                            m.name,
                            COALESCE(m.unit, ''),
                            SUM(c.source_quantity),
                            SUM(c.target_quantity),
                            COUNT(*),
                            MAX(c.created_at),
                            COALESCE(STRING_AGG(DISTINCT NULLIF(c.notes, ''), ' | '), '')
                        FROM material_conversions c
                        JOIN materials m ON m.id = c.target_material_id
                        WHERE c.source_purchase_id = %s
                        GROUP BY c.target_material_id, m.name, m.unit
                        ORDER BY MAX(c.created_at) DESC, m.name
                        """,
                        (purchase_id,)
                    )
                    rows = cur.fetchall()
            return [
                {
                    "target_material_id": r[0],
                    "target_name": r[1] or "",
                    "target_unit": r[2] or "",
                    "source_quantity": float(r[3] or 0),
                    "target_quantity": float(r[4] or 0),
                    "conversion_count": int(r[5] or 0),
                    "last_converted_at": r[6].isoformat(sep=" ") if r[6] else "",
                    "notes": r[7] or ""
                }
                for r in rows
            ]
        except Exception as e:
            print(f"Ошибка получения истории раскроя: {e}")
            return []

    @Slot(int, result="QVariantList")
    def getAreaMaterialLots(self, material_type_id=0):
        try:
            self._ensure_plate_cutting_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                    cur.execute("""
                        SELECT
                            p.id,
                            m.id,
                            m.name,
                            COALESCE(m.unit, ''),
                            COALESCE(p.remaining_quantity, 0),
                            COALESCE(p.quantity, 0),
                            COALESCE(p.price_per_unit, 0),
                            p.purchase_date,
                            COALESCE(p.notes, ''),
                            COALESCE(m.source, ''),
                            COALESCE(m.updated_date::text, ''),
                            COALESCE(m.plate_material_type_id, 0),
                            COALESCE(pt.name, '')
                        FROM purchases p
                        JOIN materials m ON m.id = p.material_id
                        LEFT JOIN plate_material_types pt ON pt.id = m.plate_material_type_id
                        WHERE COALESCE(p.remaining_quantity, 0) > 0
                          AND COALESCE(m.is_plate, FALSE) = TRUE
                          AND (%s <= 0 OR COALESCE(m.plate_material_type_id, 0) = %s)
                        ORDER BY p.purchase_date DESC, p.id DESC
                    """, (int(material_type_id or 0), int(material_type_id or 0)))
                    rows = cur.fetchall()
            return [
                {
                    "purchase_id": r[0],
                    "material_id": r[1],
                    "material_name": r[2],
                    "unit": r[3],
                    "remaining_quantity": float(r[4] or 0),
                    "original_quantity": float(r[5] or 0),
                    "price_per_unit": float(r[6] or 0),
                    "purchase_date": r[7].isoformat() if r[7] else "",
                    "notes": r[8] or "",
                    "source": r[9] or "",
                    "updated_date": r[10] or "",
                    "material_type_id": int(r[11] or 0),
                    "material_type_name": r[12] or "",
                }
                for r in rows
            ]
        except Exception as e:
            print(f"Error loading plate lots/materials: {e}")
            return []

    @Slot(int, int, float, float, str, str, result="QVariantMap")
    def convertMaterialLotToExistingPart(self, purchase_id, target_material_id, area_qty, part_qty, updated_date_str, notes):
        try:
            if purchase_id <= 0 or target_material_id <= 0:
                return {"ok": False, "message": "Выберите плиту и деталь."}

            area = Decimal(str(area_qty or 0))
            quantity = Decimal(str(part_qty or 1))
            from datetime import datetime, date
            updated_date = datetime.strptime(updated_date_str, "%Y-%m-%d").date() if updated_date_str else date.today()

            if area <= 0:
                return {"ok": False, "message": "Площадь списания должна быть больше нуля."}
            if quantity <= 0:
                return {"ok": False, "message": "Количество деталей должно быть больше нуля."}

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                    cur.execute("""
                        CREATE TABLE IF NOT EXISTS material_conversions (
                            id SERIAL PRIMARY KEY,
                            source_material_id INT REFERENCES materials(id),
                            source_purchase_id INT REFERENCES purchases(id),
                            target_material_id INT REFERENCES materials(id),
                            source_quantity DECIMAL(12, 4) NOT NULL,
                            target_quantity DECIMAL(12, 4) NOT NULL,
                            total_cost DECIMAL(12, 2) NOT NULL DEFAULT 0,
                            notes TEXT,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """)
                    cur.execute("ALTER TABLE IF EXISTS material_conversions ADD COLUMN IF NOT EXISTS source_purchase_id INT REFERENCES purchases(id)")
                    cur.execute("""
                        SELECT
                            p.material_id,
                            COALESCE(p.remaining_quantity, 0),
                            COALESCE(p.price_per_unit, 0),
                            m.name,
                            COALESCE(m.unit, '')
                        FROM purchases p
                        JOIN materials m ON m.id = p.material_id
                        WHERE p.id = %s
                        FOR UPDATE
                    """, (purchase_id,))
                    row = cur.fetchone()
                    if not row:
                        return {"ok": False, "message": "Плита не найдена."}

                    source_material_id, lot_remaining, price_per_unit, source_name, source_unit = row
                    lot_remaining = Decimal(str(lot_remaining or 0))
                    price_per_unit = Decimal(str(price_per_unit or 0))
                    if area > lot_remaining:
                        return {"ok": False, "message": f"В этой плите осталось {lot_remaining:.4f}, нужно {area:.4f}."}

                    cur.execute("SELECT name, COALESCE(unit, '') FROM materials WHERE id = %s", (target_material_id,))
                    target_row = cur.fetchone()
                    if not target_row:
                        return {"ok": False, "message": "Выбранная деталь не найдена."}
                    target_name, target_unit = target_row

                    cur.execute("SELECT COALESCE(quantity, 0) FROM material_inventory WHERE material_id = %s FOR UPDATE", (source_material_id,))
                    inv_row = cur.fetchone()
                    inventory_qty = Decimal(str(inv_row[0] if inv_row else 0))
                    if area > inventory_qty:
                        return {"ok": False, "message": f"Общий остаток материала меньше списания: {inventory_qty:.4f}."}

                    total_cost = (area * price_per_unit).quantize(Decimal("0.01"))
                    unit_price = (total_cost / quantity).quantize(Decimal("0.01"))
                    target_notes = notes.strip() if notes else f"Деталь из партии #{purchase_id}: {source_name}"

                    cur.execute("""
                        UPDATE purchases
                        SET remaining_quantity = GREATEST(COALESCE(remaining_quantity, 0) - %s, 0)
                        WHERE id = %s
                    """, (area, purchase_id))
                    cur.execute("""
                        UPDATE material_inventory
                        SET quantity = quantity - %s
                        WHERE material_id = %s
                    """, (area, source_material_id))
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity)
                        VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE
                        SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (target_material_id, quantity))
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s)
                    """, (
                        target_material_id,
                        unit_price,
                        quantity,
                        quantity,
                        f"Изготовлено из {source_name}, партия #{purchase_id}: списано {area} {source_unit}"
                    ))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_out', %s)
                    """, (source_material_id, -area, target_material_id))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_in', %s)
                    """, (target_material_id, quantity, source_material_id))
                    cur.execute("""
                        INSERT INTO material_conversions
                            (source_material_id, source_purchase_id, target_material_id, source_quantity, target_quantity, total_cost, notes)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (
                        source_material_id,
                        purchase_id,
                        target_material_id,
                        area,
                        quantity,
                        total_cost,
                        target_notes
                    ))
                    cur.execute("""
                        UPDATE materials
                        SET updated_date = %s,
                            category = 'Раскрой плит'
                        WHERE id = %s
                    """, (updated_date, target_material_id))
                    conn.commit()
            self._log_operation(
                "Раскрой плит",
                f"Изготовлена партия детали: {target_name}",
                amount=total_cost,
                details=f"Плита: {source_name}, списано: {area} {source_unit}, получено: {quantity} {target_unit}"
            )
            return {
                "ok": True,
                "message": f"Добавлена ещё одна партия детали '{target_name}'. Списано {area:.4f} {source_unit}, добавлено {quantity:.4f} {target_unit}."
            }
        except Exception as e:
            print(f"Ошибка перевода плиты в существующую деталь: {e}")
            return {"ok": False, "message": f"Ошибка перевода плиты: {e}"}

    @Slot(int, str, float, float, str, str, str, result="QVariantMap")
    def convertMaterialLotToPart(self, purchase_id, part_name, area_qty, part_qty, part_unit, updated_date_str, notes):
        try:
            clean_name = (part_name or "").strip()
            if purchase_id <= 0:
                return {"ok": False, "message": "Выберите плиту/партию."}
            if not clean_name:
                return {"ok": False, "message": "Укажите название готовой детали."}
            area = Decimal(str(area_qty or 0))
            quantity = Decimal(str(part_qty or 1))
            from datetime import datetime, date
            updated_date = datetime.strptime(updated_date_str, "%Y-%m-%d").date() if updated_date_str else date.today()
            if area <= 0:
                return {"ok": False, "message": "Площадь списания должна быть больше нуля."}
            if quantity <= 0:
                return {"ok": False, "message": "Количество деталей должно быть больше нуля."}

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                    cur.execute("""
                        CREATE TABLE IF NOT EXISTS material_conversions (
                            id SERIAL PRIMARY KEY,
                            source_material_id INT REFERENCES materials(id),
                            source_purchase_id INT REFERENCES purchases(id),
                            target_material_id INT REFERENCES materials(id),
                            source_quantity DECIMAL(12, 4) NOT NULL,
                            target_quantity DECIMAL(12, 4) NOT NULL,
                            total_cost DECIMAL(12, 2) NOT NULL DEFAULT 0,
                            notes TEXT,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """)
                    cur.execute("ALTER TABLE IF EXISTS material_conversions ADD COLUMN IF NOT EXISTS source_purchase_id INT REFERENCES purchases(id)")
                    cur.execute("""
                        SELECT
                            p.material_id,
                            COALESCE(p.remaining_quantity, 0),
                            COALESCE(p.price_per_unit, 0),
                            m.name,
                            COALESCE(m.unit, '')
                        FROM purchases p
                        JOIN materials m ON m.id = p.material_id
                        WHERE p.id = %s
                        FOR UPDATE
                    """, (purchase_id,))
                    row = cur.fetchone()
                    if not row:
                        return {"ok": False, "message": "Плита/партия не найдена."}
                    source_material_id, lot_remaining, price_per_unit, source_name, source_unit = row
                    lot_remaining = Decimal(str(lot_remaining or 0))
                    price_per_unit = Decimal(str(price_per_unit or 0))
                    if area > lot_remaining:
                        return {
                            "ok": False,
                            "message": f"В этой плите осталось {lot_remaining:.4f}, нужно {area:.4f}."
                        }
                    if clean_name.lower() == (source_name or "").strip().lower():
                        return {"ok": False, "message": "Название детали должно отличаться от исходного материала."}

                    cur.execute("SELECT COALESCE(quantity, 0) FROM material_inventory WHERE material_id = %s FOR UPDATE", (source_material_id,))
                    inv_row = cur.fetchone()
                    inventory_qty = Decimal(str(inv_row[0] if inv_row else 0))
                    if area > inventory_qty:
                        return {
                            "ok": False,
                            "message": f"Общий остаток материала меньше списания: {inventory_qty:.4f}."
                        }

                    total_cost = (area * price_per_unit).quantize(Decimal("0.01"))
                    unit_price = (total_cost / quantity).quantize(Decimal("0.01"))
                    target_notes = notes.strip() if notes else f"Деталь из партии #{purchase_id}: {source_name}"
                    cur.execute("""
                        INSERT INTO materials (name, unit, category, source, notes, updated_date)
                        VALUES (%s, %s, 'Раскрой плит', %s, %s, %s)
                        ON CONFLICT (name) DO UPDATE SET
                            unit = EXCLUDED.unit,
                            category = EXCLUDED.category,
                            source = EXCLUDED.source,
                            notes = COALESCE(EXCLUDED.notes, materials.notes),
                            updated_date = EXCLUDED.updated_date
                        RETURNING id
                    """, (
                        clean_name,
                        (part_unit or "шт").strip(),
                        f"{source_name} / партия #{purchase_id}",
                        target_notes,
                        updated_date
                    ))
                    target_material_id = cur.fetchone()[0]

                    cur.execute("""
                        UPDATE purchases
                        SET remaining_quantity = GREATEST(COALESCE(remaining_quantity, 0) - %s, 0)
                        WHERE id = %s
                    """, (area, purchase_id))
                    cur.execute("""
                        UPDATE material_inventory
                        SET quantity = quantity - %s
                        WHERE material_id = %s
                    """, (area, source_material_id))
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity)
                        VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE
                        SET quantity = material_inventory.quantity + EXCLUDED.quantity
                    """, (target_material_id, quantity))
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE, %s)
                    """, (
                        target_material_id,
                        unit_price,
                        quantity,
                        quantity,
                        f"Изготовлено из {source_name}, партия #{purchase_id}: списано {area} {source_unit}"
                    ))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_out', %s)
                    """, (source_material_id, -area, target_material_id))
                    cur.execute("""
                        INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                        VALUES (%s, %s, 'conversion_in', %s)
                    """, (target_material_id, quantity, source_material_id))
                    cur.execute("""
                        INSERT INTO material_conversions
                            (source_material_id, source_purchase_id, target_material_id, source_quantity, target_quantity, total_cost, notes)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (
                        source_material_id,
                        purchase_id,
                        target_material_id,
                        area,
                        quantity,
                        total_cost,
                        target_notes
                    ))
                    conn.commit()
            return {
                "ok": True,
                "message": f"Деталь создана из партии #{purchase_id}. Списано {area:.4f} {source_unit}, добавлено {quantity:.4f} {(part_unit or 'шт').strip()}. Цена детали: {unit_price:.2f} руб."
            }
        except Exception as e:
            print(f"Ошибка перевода плиты в готовую деталь: {e}")
            return {"ok": False, "message": f"Ошибка перевода плиты: {e}"}

    # ---------- РРЅСЃС‚СЂСѓРјРµРЅС‚С‹ ----------

    @Slot(int, str, str, float, str, str, str, float, str, float, float, result=bool)
    def updateMaterial(self, material_id, name, unit, quantity, source, notes, updated_date_str, new_price, reason, low_stock_threshold, enough_stock_threshold):
        try:
            if material_id <= 0 or not name:
                return False
            low_threshold_decimal = Decimal(str(low_stock_threshold or 1))
            enough_threshold_decimal = Decimal(str(enough_stock_threshold or 3))
            if low_threshold_decimal < 0:
                low_threshold_decimal = Decimal("1")
            if enough_threshold_decimal <= 0:
                enough_threshold_decimal = Decimal("3")
            if enough_threshold_decimal < low_threshold_decimal:
                enough_threshold_decimal = low_threshold_decimal
            from datetime import datetime, date
            updated_date = datetime.strptime(updated_date_str, "%Y-%m-%d").date() if updated_date_str else date.today()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS source TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS notes TEXT")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS updated_date DATE DEFAULT CURRENT_DATE")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS low_stock_threshold DECIMAL(12, 3) DEFAULT 1")
                    cur.execute("ALTER TABLE IF EXISTS materials ADD COLUMN IF NOT EXISTS enough_stock_threshold DECIMAL(12, 3) DEFAULT 3")
                    cur.execute("""
                        UPDATE materials
                        SET name = %s,
                            unit = %s,
                            source = %s,
                            notes = %s,
                            updated_date = %s,
                            low_stock_threshold = %s,
                            enough_stock_threshold = %s
                        WHERE id = %s
                    """, (
                        name.strip(),
                        unit.strip() if unit else None,
                        source.strip() if source else None,
                        notes.strip() if notes else None,
                        updated_date,
                        low_threshold_decimal,
                        enough_threshold_decimal,
                        material_id
                    ))

                    cur.execute("SELECT quantity FROM material_inventory WHERE material_id = %s", (material_id,))
                    row = cur.fetchone()
                    old_qty = row[0] if row else Decimal('0')
                    new_qty = Decimal(str(quantity))
                    diff = new_qty - old_qty
                    cur.execute("""
                        INSERT INTO material_inventory (material_id, quantity) VALUES (%s, %s)
                        ON CONFLICT (material_id) DO UPDATE SET quantity = EXCLUDED.quantity
                    """, (material_id, new_qty))

                    if diff != 0:
                        cur.execute("""
                            INSERT INTO material_transactions (material_id, quantity_change, transaction_type)
                            VALUES (%s, %s, 'adjustment')
                        """, (material_id, diff))
                        cur.execute("""
                            INSERT INTO inventory_adjustments (material_id, old_quantity, new_quantity, difference, reason)
                            VALUES (%s, %s, %s, %s, %s)
                        """, (material_id, old_qty, new_qty, diff, reason if reason else "Material update"))

                    if new_price and new_price > 0:
                        new_price_decimal = Decimal(str(new_price))
                        cur.execute("""
                            SELECT price_per_unit
                            FROM purchases
                            WHERE material_id = %s AND price_per_unit IS NOT NULL
                            ORDER BY purchase_date DESC, id DESC
                            LIMIT 1
                        """, (material_id,))
                        price_row = cur.fetchone()
                        old_price = Decimal(str(price_row[0])) if price_row and price_row[0] is not None else None
                        if old_price != new_price_decimal:
                            cur.execute("""
                                INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                                VALUES (%s, %s, 0, 0, CURRENT_DATE, %s)
                            """, (material_id, new_price_decimal, reason if reason else "Material update"))
                    conn.commit()
            self._log_operation(
                "Materials",
                f"Material updated: {name.strip()}",
                amount=new_price if new_price and new_price > 0 else None,
                details=f"ID {material_id}, qty: {quantity}, unit: {unit or '-'}, reason: {reason or '-'}"
            )
            return True
        except Exception as e:
            print(f"Error updating material: {e}")
            return False

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
            self._log_operation(
                "Инструменты",
                f"Добавлен инструмент: {name}",
                amount=cost,
                details=f"Инвентарный номер: {inv_num or '-'}, срок службы: {life_months} мес."
            )
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
                    """, (tool_id, residual, f"Write-off: {reason}"))
                    cur.execute("UPDATE tools SET residual_value = 0, status = 'written_off' WHERE id = %s", (tool_id,))
                    cur.execute("""
                        INSERT INTO balance (date, expense, notes)
                        VALUES (CURRENT_DATE, %s, %s)
                    """, (residual, f"Tool write-off: {reason}"))
                    conn.commit()
            self._log_operation(
                "Tools",
                f"Tool written off: ID {tool_id}",
                amount=residual,
                details=f"Reason: {reason or '-'}"
            )
            return True
        except Exception as e:
            print(f"Error writing off tool: {e}")
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
                        VALUES (%s, %s, 'Depreciation')
                    """, (tool_id, Decimal(str(amount))))
                    cur.execute(
                        "UPDATE tools SET residual_value = residual_value - %s WHERE id = %s",
                        (Decimal(str(amount)), tool_id)
                    )
                    conn.commit()
            self._log_operation(
                "Tools",
                f"Tool depreciation posted for tool ID {tool_id}",
                amount=amount
            )
            return True
        except Exception as e:
            print(f"Error posting depreciation: {e}")
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
            ok = sell_finished_good_gui(finished_good_id, Decimal(str(sale_price)), buyer)
            if ok:
                self._log_operation(
                    "Продажи",
                    f"Продан станок ID {finished_good_id}",
                    amount=sale_price,
                    details=f"Покупатель: {buyer or '-'}"
                )
            return ok
        except Exception as e:
            print(f"Ошибка продажи: {e}")
            return False

    @Slot(int, str, str, result=bool)
    def startProduction(self, machine_id, inventory_number, notes):
        try:
            from backend.models.production import start_production_gui
            ok = start_production_gui(machine_id, inventory_number, notes)
            if ok:
                from datetime import date
                self.recalculateIndirectExpenses(date.today().strftime("%Y-%m"))
                self._log_operation(
                    "Production",
                    f"Started machine production ID {machine_id}",
                    amount=1,
                    details=f"Inventory number: {inventory_number or '-'}, notes: {notes or '-'}"
                )
            return ok
        except Exception as e:
            print(f"Start production error: {e}")
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
                self._log_operation(
                    "Производство",
                    f"Завершено производство станка ID {finished_good_id}",
                    details=f"Инвентарный номер: {inventory_number or '-'}"
                )
            return ok
        except Exception as e:
            print(f"Ошибка завершения производства: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, result=bool)
    def cancelProduction(self, finished_good_id):
        """Отменяет станок в производстве без движения материалов."""
        try:
            if finished_good_id <= 0:
                return False
            months_to_recalculate = []
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_material_reservation_schema(cur)
                    cur.execute("""
                        SELECT status, COALESCE(start_date, produced_date, CURRENT_DATE), COALESCE(produced_date, CURRENT_DATE)
                        FROM finished_goods
                        WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row or row[0] != 'in_progress':
                        return False

                    _, start_date, end_date = row
                    if end_date < start_date:
                        end_date = start_date
                    y, m = start_date.year, start_date.month
                    while (y < end_date.year) or (y == end_date.year and m <= end_date.month):
                        months_to_recalculate.append(f"{y:04d}-{m:02d}")
                        m += 1
                        if m > 12:
                            y += 1
                            m = 1

                    cur.execute("DELETE FROM indirect_cost_allocations WHERE finished_good_id = %s", (finished_good_id,))
                    cur.execute("DELETE FROM tool_depreciation WHERE finished_good_id = %s", (finished_good_id,))
                    cur.execute("DELETE FROM finished_good_labor WHERE finished_good_id = %s", (finished_good_id,))
                    cur.execute("""
                        SELECT material_id, purchase_id, quantity
                        FROM finished_good_material_reservations
                        WHERE finished_good_id = %s
                    """, (finished_good_id,))
                    reservations = cur.fetchall()
                    for material_id, purchase_id, quantity in reservations:
                        qty_dec = Decimal(str(quantity or 0))
                        if purchase_id:
                            cur.execute("""
                                UPDATE purchases
                                SET remaining_quantity = COALESCE(remaining_quantity, 0) + %s
                                WHERE id = %s
                            """, (qty_dec, purchase_id))
                        cur.execute("""
                            INSERT INTO material_inventory (material_id, quantity)
                            VALUES (%s, %s)
                            ON CONFLICT (material_id) DO UPDATE
                            SET quantity = material_inventory.quantity + EXCLUDED.quantity
                        """, (material_id, qty_dec))
                        cur.execute("""
                            INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                            VALUES (%s, %s, 'reservation_release', %s)
                        """, (material_id, qty_dec, finished_good_id))
                    cur.execute("DELETE FROM finished_good_material_reservations WHERE finished_good_id = %s", (finished_good_id,))
                    cur.execute("DELETE FROM finished_goods WHERE id = %s AND status = 'in_progress'", (finished_good_id,))
                    conn.commit()

            for month in months_to_recalculate:
                self.recalculateIndirectExpenses(month)
            self._log_operation(
                "Производство",
                f"Отменено производство станка ID {finished_good_id}",
                details=f"Пересчитаны месяцы: {', '.join(months_to_recalculate) if months_to_recalculate else '-'}"
            )
            return True
        except Exception as e:
            print(f"Ошибка отмены производства: {e}")
            import traceback
            traceback.print_exc()
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


    def _ensure_tax_schema(self):
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS balance ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                cur.execute("ALTER TABLE IF EXISTS purchases ADD COLUMN IF NOT EXISTS is_cash BOOLEAN DEFAULT FALSE")
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS tax_payments (
                        id SERIAL PRIMARY KEY,
                        payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
                        period_start DATE NOT NULL,
                        period_end DATE NOT NULL,
                        tax_rate DECIMAL(8, 2) NOT NULL DEFAULT 0,
                        tax_base DECIMAL(12, 2) NOT NULL DEFAULT 0,
                        tax_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """)
            conn.commit()

    @Slot(str, str, float, result="QVariantMap")
    def calculateTaxReport(self, start_date_str, end_date_str, tax_rate):
        try:
            from datetime import datetime, date
            self._ensure_tax_schema()
            start = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else date.today().replace(day=1)
            end = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else date.today()
            if end < start:
                start, end = end, start
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT COALESCE(SUM(income), 0), COALESCE(SUM(expense), 0), COUNT(*)
                        FROM balance
                        WHERE date BETWEEN %s AND %s
                          AND COALESCE(is_cash, FALSE) = FALSE
                    """, (start, end))
                    income, expense, taxable_count = cur.fetchone()
                    income = income or Decimal('0')
                    expense = expense or Decimal('0')

                    cur.execute("""
                        SELECT COALESCE(SUM(income), 0), COALESCE(SUM(expense), 0), COUNT(*)
                        FROM balance
                        WHERE date BETWEEN %s AND %s
                          AND COALESCE(is_cash, FALSE) = TRUE
                    """, (start, end))
                    cash_income, cash_expense, cash_count = cur.fetchone()
                    cash_income = cash_income or Decimal('0')
                    cash_expense = cash_expense or Decimal('0')

            base = income - expense
            if base < 0:
                base = Decimal('0')
            rate = Decimal(str(tax_rate or 0))
            tax = base * rate / Decimal('100')
            return {
                "income": float(income),
                "expense": float(expense),
                "base": float(base),
                "tax": float(tax),
                "rate": float(rate),
                "cash_income_excluded": float(cash_income),
                "cash_expense_excluded": float(cash_expense),
                "taxable_count": int(taxable_count or 0),
                "cash_count": int(cash_count or 0),
                "period": f"{start} - {end}"
            }
        except Exception as e:
            print(f"Ошибка расчёта налогов: {e}")
            return {
                "income": 0.0,
                "expense": 0.0,
                "base": 0.0,
                "tax": 0.0,
                "rate": float(tax_rate or 0),
                "cash_income_excluded": 0.0,
                "cash_expense_excluded": 0.0,
                "taxable_count": 0,
                "cash_count": 0,
                "period": "",
                "error": str(e)
            }

    @Slot(result="QVariantMap")
    def getLastTaxPayment(self):
        try:
            self._ensure_tax_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT payment_date, period_start, period_end, tax_rate, tax_base, tax_amount, COALESCE(notes, '')
                        FROM tax_payments
                        ORDER BY payment_date DESC, id DESC
                        LIMIT 1
                    """)
                    row = cur.fetchone()
            if not row:
                return {"ok": True, "has_payment": False}
            return {
                "ok": True,
                "has_payment": True,
                "payment_date": row[0].isoformat() if row[0] else "",
                "period_start": row[1].isoformat() if row[1] else "",
                "period_end": row[2].isoformat() if row[2] else "",
                "rate": float(row[3] or 0),
                "base": float(row[4] or 0),
                "amount": float(row[5] or 0),
                "notes": row[6] or ""
            }
        except Exception as e:
            print(f"Ошибка чтения последней оплаты налога: {e}")
            return {"ok": False, "message": f"Ошибка чтения оплаты налога: {e}", "has_payment": False}

    @Slot(str, str, float, result="QVariantMap")
    def saveTaxPayment(self, start_date_str, end_date_str, tax_rate):
        try:
            from datetime import date
            self._ensure_tax_schema()
            report = self.calculateTaxReport(start_date_str, end_date_str, tax_rate)
            period = (report.get("period") or "").split(" - ")
            if len(period) == 2:
                period_start, period_end = self._parse_period(period[0], period[1])
            else:
                period_start, period_end = self._parse_period(start_date_str, end_date_str)
            amount = Decimal(str(report.get("tax", 0) or 0)).quantize(Decimal("0.01"))
            tax_base = Decimal(str(report.get("base", 0) or 0)).quantize(Decimal("0.01"))
            rate = Decimal(str(report.get("rate", tax_rate or 0))).quantize(Decimal("0.01"))
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO tax_payments
                            (payment_date, period_start, period_end, tax_rate, tax_base, tax_amount, notes)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """, (
                        date.today(),
                        period_start,
                        period_end,
                        rate,
                        tax_base,
                        amount,
                        f"Оплата налога за период {period_start} - {period_end}"
                    ))
                    if amount > 0:
                        cur.execute("""
                            INSERT INTO balance (date, expense, notes, is_cash)
                            VALUES (%s, %s, %s, FALSE)
                        """, (
                            date.today(),
                            amount,
                            f"Уплата налога за период {period_start} - {period_end}"
                        ))
                conn.commit()
            return {
                "ok": True,
                "message": f"Оплата налога сохранена: {amount:.2f} руб.",
                "payment_date": date.today().isoformat(),
                "period_start": period_start.isoformat(),
                "period_end": period_end.isoformat(),
                "amount": float(amount)
            }
        except Exception as e:
            print(f"Ошибка сохранения оплаты налога: {e}")
            return {"ok": False, "message": f"Ошибка сохранения оплаты налога: {e}"}

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
                    report = f"PROFIT AND LOSS REPORT\nPeriod: {start} - {end}\n"
                    report += f"{'='*50}\n"
                    report += f"Доходы (продажи): {revenue:.2f} руб.\n"
                    report += f"Expenses:\n"
                    report += f"  - Materials: {material_cost:.2f} rub.\n"
                    report += f"  - Salary: {salary:.2f} rub.\n"
                    report += f"  - Tool depreciation: {tool_depr:.2f} rub.\n"
                    report += f"  Total expenses: {total_expense:.2f} rub.\n"
                    report += f"{'='*50}\n"
                    report += f"NET PROFIT: {profit:.2f} rub.\n"
                    return report
        except Exception as e:
            print(f"Ошибка формирования отчёта: {e}")
            return "Ошибка при формировании отчёта"

    @Slot(str, str, result=str)
    def getProfitLossReport(self, start_date_str, end_date_str):
        try:
            from datetime import datetime, date

            start = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else date.today().replace(day=1)
            end = datetime.strptime(end_date_str, "%Y-%m-%d").date() if end_date_str else date.today()

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT
                            COALESCE(SUM(s.sale_price), 0),
                            COUNT(*),
                            COALESCE(SUM(fg.cost_price), 0),
                            COALESCE(SUM(COALESCE(fg.indirect_cost, 0)), 0)
                        FROM sales s
                        JOIN finished_goods fg ON fg.id = s.finished_good_id
                        WHERE s.sale_date BETWEEN %s AND %s
                    """, (start, end))
                    revenue, sold_count, cogs_total, indirect_in_cogs = cur.fetchone()
                    revenue = revenue or Decimal("0")
                    sold_count = sold_count or 0
                    cogs_total = cogs_total or Decimal("0")
                    indirect_in_cogs = indirect_in_cogs or Decimal("0")
                    direct_cogs = cogs_total - indirect_in_cogs

                    cur.execute("""
                        SELECT COALESCE(SUM(amount), 0)
                        FROM tool_depreciation
                        WHERE depreciation_date BETWEEN %s AND %s
                    """, (start, end))
                    tool_depr = cur.fetchone()[0] or Decimal("0")

                    cur.execute("""
                        SELECT COALESCE(SUM(wl.hours * COALESCE(e.hourly_rate, 0)), 0)
                        FROM work_logs wl
                        JOIN employees e ON wl.employee_id = e.id
                        WHERE wl.date BETWEEN %s AND %s
                    """, (start, end))
                    salary = cur.fetchone()[0] or Decimal("0")

                    cur.execute("""
                        SELECT COALESCE(SUM(amount), 0)
                        FROM indirect_cost_allocations
                        WHERE allocation_date BETWEEN %s AND %s
                    """, (start, end))
                    indirect_allocated = cur.fetchone()[0] or Decimal("0")

                    cur.execute("""
                        SELECT COALESCE(SUM(expense), 0)
                        FROM balance
                        WHERE date BETWEEN %s AND %s
                    """, (start, end))
                    balance_expense = cur.fetchone()[0] or Decimal("0")

                    cur.execute("""
                        SELECT fg.machine_model, s.sale_price, s.profit
                        FROM sales s
                        JOIN finished_goods fg ON fg.id = s.finished_good_id
                        WHERE s.sale_date BETWEEN %s AND %s
                        ORDER BY s.sale_date DESC, s.id DESC
                        LIMIT 5
                    """, (start, end))
                    recent_sales = cur.fetchall()

            gross_profit = revenue - cogs_total
            operating_expenses = salary + tool_depr
            net_profit = gross_profit - operating_expenses
            average_sale = (revenue / Decimal(str(sold_count))) if sold_count else Decimal("0")

            lines = [
                "Отчёт о прибыли и убытках",
                f"Период: {start} — {end}",
                "=" * 58,
                "Доходы",
                f"  Выручка от продаж: {revenue:.2f} руб.",
                f"  Продано станков: {sold_count}",
                f"  Средняя цена продажи: {average_sale:.2f} руб.",
                "",
                "Себестоимость проданных станков",
                f"  Прямые затраты: {direct_cogs:.2f} руб.",
                f"  Косвенные в себестоимости: {indirect_in_cogs:.2f} руб.",
                f"  Полная себестоимость продаж: {cogs_total:.2f} руб.",
                "",
                "Затраты периода",
                f"  Зарплата по табелям: {salary:.2f} руб.",
                f"  Амортизация инструмента: {tool_depr:.2f} руб.",
                f"  Косвенные, распределённые за период: {indirect_allocated:.2f} руб.",
                f"  Денежные расходы по балансу: {balance_expense:.2f} руб.",
                "",
                "Итоги",
                f"  Валовая прибыль: {gross_profit:.2f} руб.",
                f"  Операционные расходы: {operating_expenses:.2f} руб.",
                f"  Чистая прибыль по отчёту: {net_profit:.2f} руб.",
            ]

            if recent_sales:
                lines.append("")
                lines.append("Последние продажи за период")
                for machine_model, sale_price, profit_value in recent_sales:
                    sale_price = sale_price or Decimal("0")
                    profit_value = profit_value or Decimal("0")
                    lines.append(
                        f"  {machine_model}: продажа {sale_price:.2f} руб., прибыль {profit_value:.2f} руб."
                    )

            return "\n".join(lines)
        except Exception as e:
            print(f"Ошибка получения отчёта о прибыли и убытках: {e}")
            return "Ошибка получения отчёта о прибыли и убытках"

    @Slot(result="QVariantList")
    def getSoldMachinesList(self):
        """Returns sold machines list with real and taxable cost."""
        self._ensure_indirect_schema()
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("ALTER TABLE IF EXISTS finished_goods ADD COLUMN IF NOT EXISTS start_date DATE")
                cur.execute("""
                    SELECT 
                        fg.id,
                        fg.machine_model,
                        fg.inventory_number,
                        fg.produced_date,
                        fg.start_date,
                        fg.cost_price,
                        fg.indirect_cost,
                        COALESCE(fg.misc_expense_cost, 0),
                        fg.sale_date,
                        fg.buyer,
                        s.sale_price,
                        s.profit,
                        CASE
                            WHEN fg.start_date IS NOT NULL AND fg.sale_date IS NOT NULL
                            THEN (fg.sale_date - fg.start_date)
                            ELSE NULL
                        END AS days_to_sale,
                        COALESCE((
                            SELECT SUM(c.amount)
                            FROM finished_good_material_consumptions c
                            WHERE c.finished_good_id = fg.id
                              AND COALESCE(c.is_cash, FALSE) = FALSE
                        ), 0) AS non_cash_material_cost,
                        COALESCE((
                            SELECT COUNT(*)
                            FROM finished_good_material_consumptions c
                            WHERE c.finished_good_id = fg.id
                        ), 0) AS material_trace_count,
                        COALESCE((
                            SELECT SUM(wl.hours * e.hourly_rate)
                            FROM finished_good_labor fgl
                            JOIN work_logs wl ON fgl.work_log_id = wl.id
                            JOIN employees e ON wl.employee_id = e.id
                            WHERE fgl.finished_good_id = fg.id
                        ), 0) AS labor_cost,
                        COALESCE((
                            SELECT SUM(td.amount)
                            FROM tool_depreciation td
                            WHERE td.finished_good_id = fg.id
                        ), 0) AS tool_cost,
                        COALESCE((
                            SELECT SUM(a.amount)
                            FROM indirect_cost_allocations a
                            JOIN indirect_expense_categories c ON c.id = a.category_id
                            WHERE a.finished_good_id = fg.id
                              AND COALESCE(c.is_cash, FALSE) = FALSE
                        ), COALESCE(fg.indirect_cost, 0)) AS non_cash_indirect_cost,
                        COALESCE((
                            SELECT SUM(ml.allocated_amount)
                            FROM misc_expense_machine_links ml
                            JOIN misc_expenses me ON me.id = ml.expense_id
                            WHERE ml.finished_good_id = fg.id
                              AND COALESCE(me.is_cash, FALSE) = FALSE
                        ), COALESCE(fg.misc_expense_cost, 0)) AS non_cash_misc_cost
                    FROM finished_goods fg
                    JOIN sales s ON fg.id = s.finished_good_id
                    WHERE fg.status = 'sold'
                    ORDER BY fg.sale_date DESC
                """)
                rows = cur.fetchall()
        result = []
        for r in rows:
            real_cost = float(r[5]) if r[5] else 0.0
            indirect_cost = float(r[6]) if r[6] else 0.0
            misc_expense_cost = float(r[7]) if r[7] else 0.0
            non_cash_material_cost = float(r[13]) if r[13] else 0.0
            material_trace_count = int(r[14] or 0)
            labor_cost = float(r[15]) if r[15] else 0.0
            tool_cost = float(r[16]) if r[16] else 0.0
            non_cash_indirect_cost = float(r[17]) if r[17] else 0.0
            non_cash_misc_cost = float(r[18]) if r[18] else 0.0

            if material_trace_count > 0:
                taxable_cost = non_cash_material_cost + labor_cost + tool_cost + non_cash_indirect_cost + non_cash_misc_cost
            else:
                taxable_cost = max(real_cost - indirect_cost - misc_expense_cost, 0.0) + non_cash_indirect_cost + non_cash_misc_cost

            result.append({
                "id": r[0],
                "machine_model": r[1],
                "inv_num": r[2],
                "produced_date": str(r[3]) if r[3] else None,
                "start_date": str(r[4]) if r[4] else None,
                "real_cost": real_cost,
                "indirect_cost": indirect_cost,
                "misc_expense_cost": misc_expense_cost,
                "taxable_cost": max(taxable_cost, 0.0),
                "sale_date": str(r[8]) if r[8] else None,
                "buyer": r[9],
                "sale_price": float(r[10]) if r[10] else 0.0,
                "profit": float(r[11]) if r[11] else 0.0,
                "days_to_sale": int(r[12]) if r[12] is not None else None
            })
        return result


    @Slot(int, float, str, str, str, result=bool)
    def sellFinishedGoodExtended(self, finished_good_id, sale_price, buyer, inv_number, sale_date):
        """Расширенная версия продажи с инв. номером и датой."""
        try:
            from datetime import datetime, date
            
            # Обработка даты
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
                        print("Станок не найден")
                        return False
                    
                    cost = cost_row[0]  # Decimal из БД
                    sale_price_decimal = Decimal(str(sale_price))  # в†ђ РРЎРџР РђР’Р›Р•РќРР•
                    profit = sale_price_decimal - cost  # Теперь оба Decimal

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
                    """, (sale_date_obj, sale_price_decimal, f"Продажа станка ID {finished_good_id} покупателю {buyer}"))

                    conn.commit()
            self._log_operation(
                "Продажи",
                f"Продан станок ID {finished_good_id}",
                amount=sale_price_decimal,
                details=f"Покупатель: {buyer or '-'}, дата продажи: {sale_date_obj}, инвентарный номер: {inv_number or '-'}"
            )
            return True
        except Exception as e:
            print(f"Ошибка продажи: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, result="QVariantMap")
    def getMachineCostDetails(self, finished_good_id):
        """Возвращает понятную детализацию себестоимости готового станка."""
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT machine_model,
                               COALESCE(cost_price, 0),
                               produced_date,
                               start_date,
                               machine_id,
                               COALESCE(indirect_cost, 0),
                               COALESCE(misc_expense_cost, 0),
                               inventory_number,
                               notes
                        FROM finished_goods
                        WHERE id = %s
                    """, (finished_good_id,))
                    fg = cur.fetchone()
                    if not fg:
                        return {"header": "Станок не найден", "breakdown": ""}

                    model, total_cost, produced_date, start_date, machine_id, saved_indirect, saved_misc, inv_num, notes = fg
                    total_cost = Decimal(str(total_cost or 0))
                    saved_indirect = Decimal(str(saved_indirect or 0))
                    saved_misc = Decimal(str(saved_misc or 0))

                    lines = []
                    lines.append(f"Дата начала производства: {start_date or '-'}")
                    lines.append(f"Дата окончания производства: {produced_date or '-'}")
                    if inv_num:
                        lines.append(f"Инвентарный номер: {inv_num}")
                    if notes:
                        lines.append(f"Примечание: {notes}")
                    lines.append("")
                    lines.append("=" * 60)
                    lines.append("Детализация себестоимости")
                    lines.append("=" * 60)
                    lines.append("")

                    cur.execute("""
                        WITH latest_prices AS (
                            SELECT DISTINCT ON (material_id) material_id, price_per_unit
                            FROM purchases
                            WHERE price_per_unit IS NOT NULL
                            ORDER BY material_id, purchase_date DESC, id DESC
                        )
                        SELECT m.name,
                               COALESCE(mm.quantity, 0),
                               COALESCE(lp.price_per_unit, 0),
                               COALESCE(mm.quantity, 0) * COALESCE(lp.price_per_unit, 0) AS total
                        FROM machine_materials mm
                        JOIN materials m ON mm.material_id = m.id
                        LEFT JOIN latest_prices lp ON mm.material_id = lp.material_id
                        WHERE mm.machine_id = %s
                        ORDER BY total DESC, m.name
                    """, (machine_id,))
                    materials = cur.fetchall()

                    materials_total = Decimal('0')
                    lines.append("Материалы:")
                    lines.append("-" * 60)
                    if materials:
                        for name, qty, price, row_total in materials:
                            qty = Decimal(str(qty or 0))
                            price = Decimal(str(price or 0))
                            row_total = Decimal(str(row_total or 0))
                            materials_total += row_total
                            lines.append(f"{name:<32} {qty:>8.2f} x {price:>10.2f} = {row_total:>10.2f} руб.")
                    else:
                        lines.append("Материалы не найдены")
                    lines.append("-" * 60)
                    lines.append(f"{'Итого материалы:':<52} {materials_total:>10.2f} руб.")
                    lines.append("")

                    cur.execute("""
                        SELECT e.name,
                               COALESCE(wl.hours, 0),
                               COALESCE(e.hourly_rate, 0),
                               COALESCE(wl.hours, 0) * COALESCE(e.hourly_rate, 0) AS cost
                        FROM work_logs wl
                        JOIN employees e ON wl.employee_id = e.id
                        JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                        WHERE fgl.finished_good_id = %s
                        ORDER BY cost DESC, e.name
                    """, (finished_good_id,))
                    labor = cur.fetchall()

                    labor_total = Decimal('0')
                    lines.append("Работа сотрудников:")
                    lines.append("-" * 60)
                    if labor:
                        for emp_name, hours, rate, cost in labor:
                            hours = Decimal(str(hours or 0))
                            rate = Decimal(str(rate or 0))
                            cost = Decimal(str(cost or 0))
                            labor_total += cost
                            lines.append(f"{emp_name:<32} {hours:>8.2f} ч x {rate:>8.2f} = {cost:>10.2f} руб.")
                    else:
                        lines.append("Работы по станку не найдены")
                    lines.append("-" * 60)
                    lines.append(f"{'Итого работа:':<52} {labor_total:>10.2f} руб.")
                    lines.append("")

                    cur.execute("""
                        SELECT t.name, COALESCE(td.amount, 0)
                        FROM tool_depreciation td
                        JOIN tools t ON td.tool_id = t.id
                        WHERE td.finished_good_id = %s
                        ORDER BY td.amount DESC, t.name
                    """, (finished_good_id,))
                    tool_rows = cur.fetchall()

                    tools_total = Decimal('0')
                    lines.append("Амортизация инструментов:")
                    lines.append("-" * 60)
                    if tool_rows:
                        for tool_name, amount in tool_rows:
                            amount = Decimal(str(amount or 0))
                            tools_total += amount
                            lines.append(f"{tool_name:<52} {amount:>10.2f} руб.")
                    else:
                        lines.append("Амортизация не начислялась")
                    lines.append("-" * 60)
                    lines.append(f"{'Итого амортизация:':<52} {tools_total:>10.2f} руб.")
                    lines.append("")

                    cur.execute("""
                        SELECT c.name, a.allocation_date, COALESCE(a.amount, 0)
                        FROM indirect_cost_allocations a
                        JOIN indirect_expense_categories c ON c.id = a.category_id
                        WHERE a.finished_good_id = %s
                        ORDER BY a.allocation_date, c.name
                    """, (finished_good_id,))
                    indirect_rows = cur.fetchall()

                    allocated_indirect_total = Decimal('0')
                    lines.append("Косвенные расходы:")
                    lines.append("-" * 60)
                    if indirect_rows:
                        for cat_name, allocation_date, amount in indirect_rows:
                            amount = Decimal(str(amount or 0))
                            allocated_indirect_total += amount
                            lines.append(f"{str(allocation_date):<12} {cat_name:<38} {amount:>10.2f} руб.")
                    else:
                        lines.append("Распределения не найдены")
                    display_indirect = allocated_indirect_total if indirect_rows else saved_indirect
                    if not indirect_rows and saved_indirect:
                        lines.append(f"{'Сохранено в карточке станка:':<52} {saved_indirect:>10.2f} руб.")
                    lines.append("-" * 60)
                    lines.append(f"{'Итого косвенные расходы:':<52} {display_indirect:>10.2f} руб.")
                    lines.append("")

                    cur.execute("""
                        SELECT me.expense_date,
                               me.title,
                               COALESCE(me.person_name, ''),
                               COALESCE(ml.allocated_amount, 0),
                               COALESCE(me.is_cash, FALSE)
                        FROM misc_expense_machine_links ml
                        JOIN misc_expenses me ON me.id = ml.expense_id
                        WHERE ml.finished_good_id = %s
                        ORDER BY me.expense_date, me.id
                    """, (finished_good_id,))
                    misc_rows = cur.fetchall()

                    misc_total = Decimal('0')
                    lines.append("Прочие расходы:")
                    lines.append("-" * 60)
                    if misc_rows:
                        for expense_date, title, person_name, amount, is_cash in misc_rows:
                            amount = Decimal(str(amount or 0))
                            misc_total += amount
                            person_part = f" / {person_name}" if person_name else ""
                            cash_part = " [наличка]" if is_cash else ""
                            lines.append(f"{str(expense_date):<12} {(title + person_part):<38} {amount:>10.2f} руб.{cash_part}")
                    else:
                        lines.append("Прочие расходы не привязаны")
                    display_misc = misc_total if misc_rows else saved_misc
                    if not misc_rows and saved_misc:
                        lines.append(f"{'Сохранено в карточке станка:':<52} {saved_misc:>10.2f} руб.")
                    lines.append("-" * 60)
                    lines.append(f"{'Итого прочие расходы:':<52} {display_misc:>10.2f} руб.")
                    lines.append("")

                    calculated_total = materials_total + labor_total + tools_total + display_indirect + display_misc
                    base_total = total_cost - saved_indirect - saved_misc
                    calculated_base_total = calculated_total - display_indirect - display_misc

                    lines.append("=" * 60)
                    lines.append(f"{'Материалы + работа + амортизация:':<52} {calculated_base_total:>10.2f} руб.")
                    lines.append(f"{'Косвенные расходы:':<52} {display_indirect:>10.2f} руб.")
                    lines.append(f"{'Прочие расходы:':<52} {display_misc:>10.2f} руб.")
                    lines.append(f"{'Расчётная себестоимость:':<52} {calculated_total:>10.2f} руб.")
                    lines.append(f"{'Сохранено в станке:':<52} {total_cost:>10.2f} руб.")
                    lines.append(f"{'Без косвенных и прочих расходов:':<52} {base_total:>10.2f} руб.")
                    diff = total_cost - calculated_total
                    if abs(diff) > Decimal('0.01'):
                        lines.append(f"{'Расхождение:':<52} {diff:>10.2f} руб.")

                    header = (
                        f"Станок: {model} (ID {finished_good_id})\n"
                        f"Себестоимость: {total_cost:.2f} руб. "
                        f"(без косвенных и прочих расходов: {base_total:.2f} руб.)"
                    )
                    return {"header": header, "breakdown": "\n".join(lines)}

        except Exception as e:
            print(f"Ошибка получения деталей себестоимости: {e}")
            return {"header": "Ошибка", "breakdown": str(e)}
    @Slot(int, result=bool)
    def returnMachineToStock(self, finished_good_id):
        """Возвращает проданный станок на склад, удаляет запись о продаже."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # Проверяем что станок действительно продан
                    cur.execute("""
                        SELECT status FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row or row[0] != 'sold':
                        print("Станок не найден или не продан")
                        return False

                    # Удаляем запись о продаже
                    cur.execute("""
                        DELETE FROM sales WHERE finished_good_id = %s
                    """, (finished_good_id,))

                    # Возвращаем станок на склад
                    cur.execute("""
                        UPDATE finished_goods
                        SET status = 'completed',
                            buyer = NULL,
                            sale_date = NULL
                        WHERE id = %s
                    """, (finished_good_id,))

                    # Удаляем запись из баланса (если есть)
                    cur.execute("""
                        DELETE FROM balance 
                        WHERE notes LIKE %s
                    """, (f"%станка ID {finished_good_id}%",))

                    conn.commit()
                    print(f"Станок ID {finished_good_id} возвращён на склад")
            return True
        except Exception as e:
            print(f"Ошибка возврата на склад: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(str, str, int, result="QVariantList")
    def getWorkHistory(self, date_from, date_to, employee_id=None):
        """Возвращает историю работы с фильтрацией."""
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
                                (wl.hours * e.hourly_rate) as cost,
                                COALESCE(wl.notes, '')
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
                                (wl.hours * e.hourly_rate) as cost,
                                COALESCE(wl.notes, '')
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
                    "cost": float(r[6]),
                    "notes": r[7] or ""
                }
                for r in rows
            ]
        except Exception as e:
            print(f"Ошибка получения истории: {e}")
            return []

    @Slot(int, result=bool)
    def undoWorkLog(self, work_log_id):
        """Отменяет запись о работе и пересчитывает себестоимость станка."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # Получаем информацию о записи
                    cur.execute("""
                        SELECT e.hourly_rate, wl.hours, fgl.finished_good_id
                        FROM work_logs wl
                        JOIN employees e ON wl.employee_id = e.id
                        LEFT JOIN finished_good_labor fgl ON wl.id = fgl.work_log_id
                        WHERE wl.id = %s
                    """, (work_log_id,))
                    
                    row = cur.fetchone()
                    if not row:
                        print("Запись не найдена")
                        return False
                        
                    rate, hours, finished_good_id = row
                    cost_to_subtract = rate * hours
                    
                    # Если привязано к станку — уменьшаем себестоимость
                    if finished_good_id:
                        cur.execute("""
                            UPDATE finished_goods
                            SET cost_price = cost_price - %s
                            WHERE id = %s
                        """, (cost_to_subtract, finished_good_id))
                        
                        # Удаляем связь
                        cur.execute("""
                            DELETE FROM finished_good_labor
                            WHERE work_log_id = %s
                        """, (work_log_id,))
                    
                    # Удаляем саму запись
                    cur.execute("DELETE FROM work_logs WHERE id = %s", (work_log_id,))
                    
                    conn.commit()
                    print(f"Запись о работе ID {work_log_id} отменена, себестоимость уменьшена на {cost_to_subtract:.2f}")
            return True
        except Exception as e:
            print(f"Ошибка отмены записи: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, float, str, str, str, float, result=bool)
    def sellFinishedGoodWithShipping(self, finished_good_id, sale_price, buyer, inv_number, sale_date, shipping_cost):
        """Продажа с учётом транспортировки."""
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
                        print("Станок не найден")
                        return False
                    
                    cost = cost_row[0]
                    shipping_cost_decimal = Decimal(str(shipping_cost))
                    
                    # Если доставка платная — добавляем к себестоимости
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

                    notes = f"Продажа станка ID {finished_good_id} покупателю {buyer}"
                    if shipping_cost_decimal > 0:
                        notes += f" (доставка {shipping_cost_decimal} ₽ включена в себестоимость)"

                    cur.execute("""
                        INSERT INTO balance (date, income, notes)
                        VALUES (%s, %s, %s)
                    """, (sale_date_obj, sale_price_decimal, notes))

                    conn.commit()
            self._log_operation(
                "Продажи",
                f"Продан станок ID {finished_good_id} с доставкой",
                amount=sale_price_decimal,
                details=f"Покупатель: {buyer or '-'}, доставка: {shipping_cost_decimal}, дата продажи: {sale_date_obj}"
            )
            return True
        except Exception as e:
            print(f"Ошибка продажи: {e}")
            import traceback
            traceback.print_exc()
        return False

    @Slot(int, result="QVariantList")
    def checkMaterialsForMachine(self, finished_good_id):
        """Проверяет наличие материалов для завершения производства станка."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_material_reservation_schema(cur)
                    # Получаем machine_id из finished_goods
                    cur.execute("""
                        SELECT machine_id FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row or not row[0]:
                        return []
                    
                    machine_id = row[0]
                    
                    # РџСЂРѕРІРµСЂСЏРµРј РјР°С‚РµСЂРёР°Р»С‹, резерв и свободный остаток
                    cur.execute("""
                        SELECT
                            m.id,
                            m.name,
                            COALESCE(mm.quantity, 0) AS required,
                            COALESCE(res.reserved_qty, 0) AS reserved_qty,
                            COALESCE(inv.quantity, 0) AS in_stock
                        FROM machine_materials mm
                        JOIN materials m ON mm.material_id = m.id
                        LEFT JOIN (
                            SELECT material_id, SUM(quantity) AS reserved_qty
                            FROM finished_good_material_reservations
                            WHERE finished_good_id = %s
                            GROUP BY material_id
                        ) res ON res.material_id = mm.material_id
                        LEFT JOIN material_inventory inv ON mm.material_id = inv.material_id
                        WHERE mm.machine_id = %s
                        ORDER BY m.name
                    """, (finished_good_id, machine_id))
                    
                    rows = cur.fetchall()
                    result = []
                    for material_id, material_name, required, reserved_qty, in_stock in rows:
                        required_val = float(required or 0)
                        reserved_val = float(reserved_qty or 0)
                        in_stock_val = float(in_stock or 0)
                        if reserved_val >= required_val and required_val > 0:
                            status_key = "reserved"
                            status_text = "В резерве"
                        elif reserved_val + in_stock_val >= required_val:
                            status_key = "enough"
                            status_text = "Достаточно"
                        else:
                            status_key = "shortage"
                            status_text = "Не хватает"
                        result.append({
                            "material_id": int(material_id),
                            "material_name": material_name,
                            "required": required_val,
                            "reserved": reserved_val,
                            "in_stock": in_stock_val,
                            "available": status_key == "reserved",
                            "status_key": status_key,
                            "status_text": status_text,
                            "missing": max(required_val - reserved_val - in_stock_val, 0.0)
                        })
                    return result
        except Exception as e:
            print(f"Ошибка проверки материалов: {e}")
            import traceback
            traceback.print_exc()
            return []

    @Slot(int, result="QVariantMap")
    def reserveMaterialsForMachine(self, finished_good_id):
        try:
            if finished_good_id <= 0:
                return {"ok": False, "message": "Не выбран станок."}
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_material_reservation_schema(cur)
                    cur.execute("""
                        SELECT machine_id, machine_model
                        FROM finished_goods
                        WHERE id = %s AND status = 'in_progress'
                    """, (finished_good_id,))
                    fg_row = cur.fetchone()
                    if not fg_row:
                        return {"ok": False, "message": "Станок не найден или уже не в производстве."}

                    machine_id, machine_model = fg_row
                    cur.execute("""
                        SELECT mm.material_id,
                               m.name,
                               COALESCE(mm.quantity, 0) AS required_qty,
                               COALESCE(res.reserved_qty, 0) AS reserved_qty
                        FROM machine_materials mm
                        JOIN materials m ON m.id = mm.material_id
                        LEFT JOIN (
                            SELECT material_id, SUM(quantity) AS reserved_qty
                            FROM finished_good_material_reservations
                            WHERE finished_good_id = %s
                            GROUP BY material_id
                        ) res ON res.material_id = mm.material_id
                        WHERE mm.machine_id = %s
                        ORDER BY m.name
                    """, (finished_good_id, machine_id))
                    material_rows = cur.fetchall()

                    reserved_lines = []
                    for material_id, material_name, required_qty, reserved_qty in material_rows:
                        required_dec = Decimal(str(required_qty or 0))
                        reserved_dec = Decimal(str(reserved_qty or 0))
                        missing = required_dec - reserved_dec
                        if missing <= 0:
                            continue

                        cur.execute("""
                            SELECT COALESCE(quantity, 0)
                            FROM material_inventory
                            WHERE material_id = %s
                            FOR UPDATE
                        """, (material_id,))
                        inv_row = cur.fetchone()
                        free_qty = Decimal(str(inv_row[0] if inv_row else 0))
                        if free_qty <= 0:
                            continue

                        to_reserve = min(missing, free_qty)
                        cur.execute("""
                            SELECT id, COALESCE(remaining_quantity, 0), COALESCE(price_per_unit, 0), COALESCE(is_cash, FALSE)
                            FROM purchases
                            WHERE material_id = %s
                              AND COALESCE(remaining_quantity, 0) > 0
                            ORDER BY purchase_date ASC NULLS LAST, id ASC
                            FOR UPDATE
                        """, (material_id,))
                        purchase_rows = cur.fetchall()
                        remaining = to_reserve
                        reserved_for_material = Decimal("0")
                        for purchase_id, remaining_qty, price_per_unit, is_cash in purchase_rows:
                            if remaining <= 0:
                                break
                            lot_qty = Decimal(str(remaining_qty or 0))
                            if lot_qty <= 0:
                                continue
                            take_qty = min(lot_qty, remaining)
                            amount = take_qty * Decimal(str(price_per_unit or 0))
                            cur.execute("""
                                UPDATE purchases
                                SET remaining_quantity = GREATEST(COALESCE(remaining_quantity, 0) - %s, 0)
                                WHERE id = %s
                            """, (take_qty, purchase_id))
                            cur.execute("""
                                INSERT INTO finished_good_material_reservations
                                    (finished_good_id, material_id, purchase_id, quantity, amount, is_cash)
                                VALUES (%s, %s, %s, %s, %s, %s)
                            """, (finished_good_id, material_id, purchase_id, take_qty, amount, bool(is_cash)))
                            remaining -= take_qty
                            reserved_for_material += take_qty

                        if reserved_for_material > 0:
                            cur.execute("""
                                UPDATE material_inventory
                                SET quantity = GREATEST(COALESCE(quantity, 0) - %s, 0)
                                WHERE material_id = %s
                            """, (reserved_for_material, material_id))
                            cur.execute("""
                                INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                                VALUES (%s, %s, 'reservation', %s)
                            """, (material_id, -reserved_for_material, finished_good_id))
                            reserved_lines.append(f"{material_name}: {reserved_for_material}")

                    conn.commit()

            if reserved_lines:
                self._log_operation(
                    "Производство",
                    f"Зарезервированы материалы для станка ID {finished_good_id}",
                    details=f"Модель: {machine_model or '-'}; " + "; ".join(reserved_lines)
                )
                return {"ok": True, "message": "Материалы отправлены в резерв."}
            return {"ok": True, "message": "Нечего резервировать: либо всё уже в резерве, либо на складе пока нет свободных материалов."}
        except Exception as e:
            print(f"Ошибка резервирования материалов: {e}")
            import traceback
            traceback.print_exc()
            return {"ok": False, "message": f"Ошибка резервирования: {e}"}

    @Slot(int, result="QVariantMap")
    def releaseReservedMaterialsForMachine(self, finished_good_id):
        try:
            if finished_good_id <= 0:
                return {"ok": False, "message": "Не выбран станок."}
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_material_reservation_schema(cur)
                    cur.execute("""
                        SELECT machine_model
                        FROM finished_goods
                        WHERE id = %s AND status = 'in_progress'
                    """, (finished_good_id,))
                    fg_row = cur.fetchone()
                    if not fg_row:
                        return {"ok": False, "message": "Станок не найден или уже не в производстве."}
                    machine_model = fg_row[0] or ""

                    cur.execute("""
                        SELECT material_id, purchase_id, quantity
                        FROM finished_good_material_reservations
                        WHERE finished_good_id = %s
                        ORDER BY id
                    """, (finished_good_id,))
                    reservations = cur.fetchall()
                    if not reservations:
                        return {"ok": True, "message": "У этого станка нет резервов."}

                    for material_id, purchase_id, quantity in reservations:
                        qty_dec = Decimal(str(quantity or 0))
                        if purchase_id:
                            cur.execute("""
                                UPDATE purchases
                                SET remaining_quantity = COALESCE(remaining_quantity, 0) + %s
                                WHERE id = %s
                            """, (qty_dec, purchase_id))
                        cur.execute("""
                            INSERT INTO material_inventory (material_id, quantity)
                            VALUES (%s, %s)
                            ON CONFLICT (material_id) DO UPDATE
                            SET quantity = material_inventory.quantity + EXCLUDED.quantity
                        """, (material_id, qty_dec))
                        cur.execute("""
                            INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                            VALUES (%s, %s, 'reservation_release', %s)
                        """, (material_id, qty_dec, finished_good_id))

                    cur.execute("DELETE FROM finished_good_material_reservations WHERE finished_good_id = %s", (finished_good_id,))
                    conn.commit()

            self._log_operation(
                "Производство",
                f"Снят резерв материалов для станка ID {finished_good_id}",
                details=f"Модель: {machine_model or '-'}"
            )
            return {"ok": True, "message": "Резерв материалов снят."}
        except Exception as e:
            print(f"Ошибка снятия резерва материалов: {e}")
            import traceback
            traceback.print_exc()
            return {"ok": False, "message": f"Ошибка снятия резерва: {e}"}


    def _write_purchase_materials_excel(self, rows, filename_prefix):
        from datetime import datetime
        import os
        import pandas as pd

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{filename_prefix}_{timestamp}.xlsx"
        filepath = os.path.abspath(filename)
        columns = [
            "Материал",
            "Ед. изм.",
            "Требуется",
            "На складе",
            "Купить",
            "Цена за ед.",
            "Сумма",
            "Откуда взят",
            "Примечание",
            "Станки"
        ]
        if not rows:
            return ""
        df = pd.DataFrame(rows, columns=columns)
        with pd.ExcelWriter(filepath, engine="openpyxl") as writer:
            df.to_excel(writer, sheet_name="Купить", index=False)
            worksheet = writer.sheets["Купить"]
            for column_cells in worksheet.columns:
                max_length = 0
                column_letter = column_cells[0].column_letter
                for cell in column_cells:
                    value = "" if cell.value is None else str(cell.value)
                    max_length = max(max_length, len(value))
                worksheet.column_dimensions[column_letter].width = min(max(max_length + 2, 12), 45)
        return filepath

    @Slot(int, result=str)
    def exportMissingMaterialsForMachine(self, finished_good_id):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_material_reservation_schema(cur)
                    cur.execute("""
                        SELECT machine_id, machine_model
                        FROM finished_goods
                        WHERE id = %s AND status = 'in_progress'
                    """, (finished_good_id,))
                    fg = cur.fetchone()
                    if not fg:
                        return ""
                    machine_id, machine_model = fg
                    cur.execute("""
                        WITH latest_prices AS (
                            SELECT DISTINCT ON (material_id) material_id, price_per_unit
                            FROM purchases
                            WHERE price_per_unit IS NOT NULL
                            ORDER BY material_id, purchase_date DESC NULLS LAST, id DESC
                        ), reserved AS (
                            SELECT material_id, SUM(quantity) AS reserved_qty
                            FROM finished_good_material_reservations
                            WHERE finished_good_id = %s
                            GROUP BY material_id
                        )
                        SELECT m.name,
                               COALESCE(m.unit, ''),
                               COALESCE(mm.quantity, 0) AS required_qty,
                               COALESCE(inv.quantity, 0) AS in_stock,
                               GREATEST(COALESCE(mm.quantity, 0) - COALESCE(res.reserved_qty, 0) - COALESCE(inv.quantity, 0), 0) AS to_buy,
                               COALESCE(lp.price_per_unit, 0) AS price_per_unit,
                               COALESCE(m.source, ''),
                               COALESCE(m.notes, '')
                        FROM machine_materials mm
                        JOIN materials m ON m.id = mm.material_id
                        LEFT JOIN reserved res ON res.material_id = mm.material_id
                        LEFT JOIN material_inventory inv ON inv.material_id = mm.material_id
                        LEFT JOIN latest_prices lp ON lp.material_id = mm.material_id
                        WHERE mm.machine_id = %s
                          AND GREATEST(COALESCE(mm.quantity, 0) - COALESCE(res.reserved_qty, 0) - COALESCE(inv.quantity, 0), 0) > 0
                        ORDER BY to_buy DESC, m.name
                    """, (finished_good_id, machine_id))
                    rows = []
                    for name, unit, required_qty, in_stock, to_buy, price, source, notes in cur.fetchall():
                        required_qty = Decimal(str(required_qty or 0))
                        in_stock = Decimal(str(in_stock or 0))
                        to_buy = Decimal(str(to_buy or 0))
                        price = Decimal(str(price or 0))
                        rows.append([
                            name,
                            unit,
                            float(required_qty),
                            float(in_stock),
                            float(to_buy),
                            float(price),
                            float(to_buy * price),
                            source,
                            notes,
                            f"{machine_model} (ID {finished_good_id})"
                        ])
            return self._write_purchase_materials_excel(rows, f"materials_to_buy_machine_{finished_good_id}")
        except Exception as e:
            print(f"Ошибка выгрузки материалов для выбранного станка: {e}")
            import traceback
            traceback.print_exc()
            return ""

    @Slot(result=str)
    def exportMissingMaterialsForAllInProgress(self):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    self._ensure_material_reservation_schema(cur)
                    cur.execute("""
                        WITH in_progress AS (
                            SELECT id, machine_id, machine_model
                            FROM finished_goods
                            WHERE status = 'in_progress'
                        ), required_by_material AS (
                            SELECT mm.material_id,
                                   SUM(COALESCE(mm.quantity, 0)) AS required_qty,
                                   STRING_AGG(ip.machine_model || ' (ID ' || ip.id || ')', ', ' ORDER BY ip.machine_model, ip.id) AS machines
                            FROM in_progress ip
                            JOIN machine_materials mm ON mm.machine_id = ip.machine_id
                            GROUP BY mm.material_id
                        ), reserved_by_material AS (
                            SELECT material_id, SUM(quantity) AS reserved_qty
                            FROM finished_good_material_reservations
                            GROUP BY material_id
                        ), latest_prices AS (
                            SELECT DISTINCT ON (material_id) material_id, price_per_unit
                            FROM purchases
                            WHERE price_per_unit IS NOT NULL
                            ORDER BY material_id, purchase_date DESC NULLS LAST, id DESC
                        )
                        SELECT m.name,
                               COALESCE(m.unit, ''),
                               COALESCE(r.required_qty, 0) AS required_qty,
                               COALESCE(inv.quantity, 0) AS in_stock,
                               GREATEST(COALESCE(r.required_qty, 0) - COALESCE(rb.reserved_qty, 0) - COALESCE(inv.quantity, 0), 0) AS to_buy,
                               COALESCE(lp.price_per_unit, 0) AS price_per_unit,
                               COALESCE(m.source, ''),
                               COALESCE(m.notes, ''),
                               COALESCE(r.machines, '')
                        FROM required_by_material r
                        JOIN materials m ON m.id = r.material_id
                        LEFT JOIN reserved_by_material rb ON rb.material_id = r.material_id
                        LEFT JOIN material_inventory inv ON inv.material_id = r.material_id
                        LEFT JOIN latest_prices lp ON lp.material_id = r.material_id
                        WHERE GREATEST(COALESCE(r.required_qty, 0) - COALESCE(rb.reserved_qty, 0) - COALESCE(inv.quantity, 0), 0) > 0
                        ORDER BY to_buy DESC, m.name
                    """)
                    rows = []
                    for name, unit, required_qty, in_stock, to_buy, price, source, notes, machines in cur.fetchall():
                        required_qty = Decimal(str(required_qty or 0))
                        in_stock = Decimal(str(in_stock or 0))
                        to_buy = Decimal(str(to_buy or 0))
                        price = Decimal(str(price or 0))
                        rows.append([
                            name,
                            unit,
                            float(required_qty),
                            float(in_stock),
                            float(to_buy),
                            float(price),
                            float(to_buy * price),
                            source,
                            notes,
                            machines
                        ])
            return self._write_purchase_materials_excel(rows, "materials_to_buy_all_in_progress")
        except Exception as e:
            print(f"Ошибка выгрузки материалов для всех станков в процессе: {e}")
            import traceback
            traceback.print_exc()
            return ""


    @Slot(int, result=str)
    def getDisassemblePreview(self, finished_good_id):
        """Показывает предпросмотр что вернётся на склад при разборке."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # Получаем информацию о станке
                    cur.execute("""
                        SELECT machine_model, machine_id FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row:
                        return "Станок не найден"
                    
                    model, machine_id = row
                    
                    preview = f"Станок: {model} (ID {finished_good_id})\n\n"
                    preview += "MATERIALS THAT WILL RETURN TO STOCK:\n"
                    preview += "=" * 60 + "\n"
                    
                    # Получаем материалы из спецификации
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
                        preview += "Нет материалов для возврата\n"
                    else:
                        preview += f"{'Материал':<35} {'Вернётся':>10} {'Сейчас':>10} {'Станет':>10}\n"
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
                        preview += f"\nWARNING: labor cost ({labor_cost:.2f} rub.) is not refunded!\n"
                    
                    preview += "\nСтанок будет удалён из базы данных."
                    
                    return preview
                    
        except Exception as e:
            print(f"Ошибка предпросмотра разборки: {e}")
            return f"Ошибка: {str(e)}"

    @Slot(int, result=bool)
    def disassembleMachine(self, finished_good_id):
        """Разбирает станок и возвращает материалы на склад."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # Получаем machine_id
                    cur.execute("""
                        SELECT machine_id FROM finished_goods WHERE id = %s AND status = 'completed'
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row:
                        print("Станок не найден или уже продан")
                        return False
                    
                    machine_id = row[0]
                    
                    # Получаем материалы из спецификации
                    cur.execute("""
                        SELECT material_id, quantity
                        FROM machine_materials
                        WHERE machine_id = %s
                    """, (machine_id,))
                    materials = cur.fetchall()
                    
                    # Возвращаем материалы на склад
                    for material_id, quantity in materials:
                        cur.execute("""
                            INSERT INTO material_inventory (material_id, quantity)
                            VALUES (%s, %s)
                            ON CONFLICT (material_id) 
                            DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
                        """, (material_id, quantity))
                        
                        # Добавляем транзакцию
                        cur.execute("""
                            INSERT INTO material_transactions (material_id, quantity_change, transaction_type, reference_id)
                            VALUES (%s, %s, 'disassembly', %s)
                        """, (material_id, quantity, finished_good_id))
                    
                    # Удаляем связи с амортизацией инструментов
                    cur.execute("DELETE FROM tool_depreciation WHERE finished_good_id = %s", (finished_good_id,))
                    
                    # Удаляем связи с работой
                    cur.execute("DELETE FROM finished_good_labor WHERE finished_good_id = %s", (finished_good_id,))
                    
                    # Удаляем станок
                    cur.execute("DELETE FROM finished_goods WHERE id = %s", (finished_good_id,))
                    
                    conn.commit()
                    print(f"Станок ID {finished_good_id} разобран, материалы возвращены на склад")
                    
            return True
        except Exception as e:
            print(f"Ошибка разборки станка: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, result=bool)
    def deleteMachine(self, finished_good_id):
        """Удаляет станок БЕЗ возврата материалов."""
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    # Проверяем что станок на складе
                    cur.execute("""
                        SELECT status FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    row = cur.fetchone()
                    if not row:
                        print("Станок не найден")
                        return False
                    
                    if row[0] == 'sold':
                        print("Нельзя удалить проданный станок")
                        return False
                    
                    # Удаляем связи с работой
                    cur.execute("""
                        DELETE FROM finished_good_labor WHERE finished_good_id = %s
                    """, (finished_good_id,))
                    
                    # Удаляем станок
                    cur.execute("""
                        DELETE FROM finished_goods WHERE id = %s
                    """, (finished_good_id,))
                    
                    conn.commit()
                    print(f"Станок ID {finished_good_id} удалён")
                    
            return True
        except Exception as e:
            print(f"Ошибка удаления станка: {e}")
            import traceback
            traceback.print_exc()
            return False

    @Slot(int, str, str, str, str, float, float, str, result=bool)
    def updateFinishedGood(self, finished_good_id, machine_model, inventory_number, start_date_str, produced_date_str, cost_price, indirect_cost, notes):
        try:
            from datetime import datetime
            self._ensure_indirect_schema()
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date() if start_date_str else None
            produced_date = datetime.strptime(produced_date_str, "%Y-%m-%d").date() if produced_date_str else None
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE finished_goods
                        SET machine_model = %s,
                            inventory_number = %s,
                            start_date = %s,
                            produced_date = %s,
                            cost_price = %s,
                            indirect_cost = %s,
                            notes = %s
                        WHERE id = %s AND status = 'completed'
                    """, (
                        machine_model.strip() if machine_model else None,
                        inventory_number.strip() if inventory_number else None,
                        start_date,
                        produced_date,
                        Decimal(str(cost_price)),
                        Decimal(str(indirect_cost)),
                        notes.strip() if notes else None,
                        finished_good_id
                    ))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Ошибка обновления готового станка: {e}")
            return False
    @Slot(int, str, str, str, str, float, result=bool)
    def updateSoldMachine(self, finished_good_id, inventory_number, buyer, sale_date_str, produced_date_str, indirect_cost):
        try:
            from datetime import datetime
            self._ensure_indirect_schema()
            sale_date = datetime.strptime(sale_date_str, "%Y-%m-%d").date() if sale_date_str else None
            produced_date = datetime.strptime(produced_date_str, "%Y-%m-%d").date() if produced_date_str else None
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE finished_goods
                        SET inventory_number = %s,
                            buyer = %s,
                            sale_date = %s,
                            produced_date = COALESCE(%s, produced_date),
                            cost_price = GREATEST(cost_price - COALESCE(indirect_cost, 0), 0) + %s,
                            indirect_cost = %s
                        WHERE id = %s AND status = 'sold'
                    """, (
                        inventory_number if inventory_number else None,
                        buyer if buyer else None,
                        sale_date,
                        produced_date,
                        Decimal(str(indirect_cost)),
                        Decimal(str(indirect_cost)),
                        finished_good_id
                    ))
                    cur.execute("""
                        UPDATE sales s
                        SET sale_date = COALESCE(%s, sale_date),
                            profit = sale_price - (
                                SELECT cost_price FROM finished_goods WHERE id = s.finished_good_id
                            )
                        WHERE s.finished_good_id = %s
                    """, (sale_date, finished_good_id))
                    conn.commit()
            return True
        except Exception as e:
            print(f"Error updating sold machine: {e}")
            return False

    @Slot(result="QVariantList")
    def getIndirectCategories(self):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT id, name, monthly_amount, is_active, notes, COALESCE(is_cash, FALSE)
                        FROM indirect_expense_categories
                        ORDER BY name
                    """)
                    rows = cur.fetchall()
            return [
                {
                    "id": r[0],
                    "name": r[1],
                    "monthly_amount": float(r[2]),
                    "is_active": bool(r[3]),
                    "notes": r[4] or "",
                    "is_cash": bool(r[5])
                }
                for r in rows
            ]
        except Exception as e:
            print(f"Error loading indirect categories: {e}")
            return []

    @Slot(str, float, bool, bool, str, result=bool)
    def addIndirectCategory(self, name, amount, is_active, is_cash, notes):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO indirect_expense_categories (name, monthly_amount, is_active, is_cash, notes)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (name, Decimal(str(amount)), is_active, is_cash, notes if notes else None))
                    conn.commit()
            self._log_operation(
                "Indirect costs",
                f"Added category: {name}",
                amount=amount,
                details=f"Active: {'Yes' if is_active else 'No'}, cash: {'Yes' if is_cash else 'No'}"
            )
            return True
        except Exception as e:
            print(f"Error adding indirect category: {e}")
            return False

    @Slot(int, str, float, bool, bool, str, result=bool)
    def updateIndirectCategory(self, category_id, name, amount, is_active, is_cash, notes):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        UPDATE indirect_expense_categories
                        SET name = %s, monthly_amount = %s, is_active = %s, is_cash = %s, notes = %s
                        WHERE id = %s
                    """, (name, Decimal(str(amount)), is_active, is_cash, notes if notes else None, category_id))
                    conn.commit()
            self._log_operation(
                "Indirect costs",
                f"Updated category: {name}",
                amount=amount,
                details=f"ID {category_id}, active: {'Yes' if is_active else 'No'}, cash: {'Yes' if is_cash else 'No'}"
            )
            return True
        except Exception as e:
            print(f"Error updating indirect category: {e}")
            return False


    @Slot(int, result=bool)
    def deleteIndirectCategory(self, category_id):
        try:
            self._ensure_indirect_schema()
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT name FROM indirect_expense_categories WHERE id = %s", (category_id,))
                    row = cur.fetchone()
                    cur.execute("DELETE FROM indirect_expense_categories WHERE id = %s", (category_id,))
                    conn.commit()
            self._log_operation(
                "Косвенные расходы",
                f"Удалена категория: {(row[0] if row else f'ID {category_id}')}"
            )
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

                    cur.execute("DROP TABLE IF EXISTS tmp_finished_goods_base_cost")
                    cur.execute("""
                        CREATE TEMP TABLE tmp_finished_goods_base_cost AS
                        SELECT id,
                               GREATEST(
                                   cost_price
                                   - COALESCE(indirect_cost, 0)
                                   - COALESCE(misc_expense_cost, 0),
                                   0
                               ) AS base_cost
                        FROM finished_goods
                    """)
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
                        SET cost_price = COALESCE(t.base_cost, 0)
                                       + COALESCE(fg.indirect_cost, 0)
                                       + COALESCE(fg.misc_expense_cost, 0)
                        FROM tmp_finished_goods_base_cost t
                        WHERE fg.id = t.id
                    """)
                    cur.execute("DROP TABLE IF EXISTS tmp_finished_goods_base_cost")
                    conn.commit()
            self._log_operation(
                "Indirect costs",
                f"Indirect costs recalculated for {month_str}",
                details=f"Period: {month_start} - {month_end}"
            )
            return True
        except Exception as e:
            print(f"Error recalculating indirect expenses: {e}")
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

    @Slot(str, str, result="QVariantMap")
    def getIndirectIdleSummary(self, date_from_str, date_to_str):
        try:
            import calendar
            from datetime import datetime, date, timedelta

            self._ensure_indirect_schema()
            date_from = datetime.strptime(date_from_str, "%Y-%m-%d").date() if date_from_str else date.today().replace(day=1)
            date_to = datetime.strptime(date_to_str, "%Y-%m-%d").date() if date_to_str else date.today()
            if date_to < date_from:
                date_from, date_to = date_to, date_from

            idle_days = 0
            total_amount = Decimal("0.00")

            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT COUNT(*)
                        FROM indirect_expense_categories
                        WHERE is_active = TRUE
                    """)
                    active_categories = int(cur.fetchone()[0] or 0)

                    day = date_from
                    while day <= date_to:
                        cur.execute("""
                            SELECT COUNT(*)
                            FROM finished_goods
                            WHERE start_date <= %s
                              AND (
                                  (status = 'in_progress' AND %s <= CURRENT_DATE)
                                  OR
                                  (status <> 'in_progress' AND produced_date IS NOT NULL AND produced_date >= %s)
                              )
                        """, (day, day, day))
                        machine_count = int(cur.fetchone()[0] or 0)
                        if machine_count == 0:
                            idle_days += 1
                            cur.execute("""
                                SELECT monthly_amount
                                FROM indirect_expense_categories
                                WHERE is_active = TRUE
                            """)
                            for row in cur.fetchall():
                                monthly_amount = Decimal(str(row[0] or 0))
                                days_in_month = calendar.monthrange(day.year, day.month)[1]
                                total_amount += monthly_amount / Decimal(days_in_month)
                        day += timedelta(days=1)

            return {
                "ok": True,
                "idle_days": idle_days,
                "amount": float(total_amount.quantize(Decimal("0.01"))),
                "date_from": str(date_from),
                "date_to": str(date_to),
                "active_categories": active_categories,
            }
        except Exception as e:
            print(f"Ошибка расчёта простоя по косвенным расходам: {e}")
            return {
                "ok": False,
                "idle_days": 0,
                "amount": 0.0,
                "date_from": date_from_str or "",
                "date_to": date_to_str or "",
                "active_categories": 0,
                "message": f"Ошибка расчёта простоя: {e}",
            }

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
                    df_sales.to_excel(writer, sheet_name="Продажи", index=False)
                    df_production.to_excel(writer, sheet_name="Производство", index=False)
            print(f"Отчёт сохранён в {filename}")
        except Exception as e:
            print(f"Ошибка экспорта: {e}")
