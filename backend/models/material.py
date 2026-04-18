from decimal import Decimal
from backend.db.connection import get_connection

def add_inventory():
    """Пополнение склада материалов."""
    print("\n--- Пополнение склада (приход материалов) ---")
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
            print("\nНайденные материалы:")
            for i, (mid, name, unit) in enumerate(mats, 1):
                print(f"{i}. {name} ({unit or 'шт'})")
            try:
                choice = int(input("Выберите номер материала (0 для отмены): "))
                if choice == 0:
                    return
                if choice < 1 or choice > len(mats):
                    print("Неверный номер.")
                    return
                mat_id, mat_name, unit = mats[choice-1]
                qty = Decimal(input("Введите добавляемое количество: "))
                if qty <= 0:
                    print("Количество должно быть положительным.")
                    return
                price_input = input("Цена за единицу (можно оставить пустым): ").strip()
                price = Decimal(price_input) if price_input else None
                # Обновляем остаток
                cur.execute("""
                    INSERT INTO material_inventory (material_id, quantity)
                    VALUES (%s, %s)
                    ON CONFLICT (material_id) DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
                """, (mat_id, qty))
                # Закупка, если цена указана
                if price is not None:
                    cur.execute("""
                        INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date)
                        VALUES (%s, %s, %s, %s, CURRENT_DATE)
                    """, (mat_id, price, qty, qty))
                # Транзакция
                cur.execute("""
                    INSERT INTO material_transactions (material_id, quantity_change, transaction_type)
                    VALUES (%s, %s, 'purchase')
                """, (mat_id, qty))
                conn.commit()
                print(f"Добавлено {qty} единиц материала '{mat_name}'.")
            except ValueError:
                print("Ошибка ввода.")

def edit_zero_prices():
    """Установка цен для материалов без цены."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT m.id, m.name, m.unit
                FROM materials m
                WHERE NOT EXISTS (SELECT 1 FROM purchases p WHERE p.material_id=m.id AND p.price_per_unit IS NOT NULL)
                ORDER BY m.name
            """)
            mats = cur.fetchall()
            if not mats:
                print("Все материалы имеют цены.")
                return
            print(f"Материалов без цены: {len(mats)}")
            for i, (mid, name, unit) in enumerate(mats[:20], 1):
                print(f"{i}. {name}")
            try:
                choice = int(input("Номер для установки цены (0 - отмена): "))
                if choice == 0:
                    return
                mid, name, unit = mats[choice-1]
                price = Decimal(input(f"Цена за единицу '{name}': "))
                cur.execute("""
                    INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date)
                    VALUES (%s, %s, 1, 1, CURRENT_DATE)
                """, (mid, price))
                cur.execute("""
                    INSERT INTO material_inventory (material_id, quantity) VALUES (%s, 1)
                    ON CONFLICT (material_id) DO UPDATE SET quantity = material_inventory.quantity + 1
                """, (mid,))
                conn.commit()
                print("Цена установлена.")
            except ValueError:
                print("Ошибка.")

def inventory_adjustment():
    """Корректировка остатков (инвентаризация)."""
    print("\n--- Инвентаризация (корректировка остатков) ---")
    search = input("Введите часть названия материала: ").strip()
    if not search:
        return
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT m.id, m.name, m.unit, COALESCE(inv.quantity, 0) AS current_qty
                FROM materials m
                LEFT JOIN material_inventory inv ON m.id = inv.material_id
                WHERE m.name ILIKE %s
                ORDER BY m.name
                LIMIT 20
            """, (f"%{search}%",))
            mats = cur.fetchall()
            if not mats:
                print("Материалы не найдены.")
                return
            print("\nНайденные материалы:")
            for i, (mid, name, unit, current) in enumerate(mats, 1):
                print(f"{i}. {name} — текущий остаток: {current} {unit or 'шт'}")
            try:
                choice = int(input("Выберите номер материала (0 для отмены): "))
                if choice == 0:
                    return
                if choice < 1 or choice > len(mats):
                    print("Неверный номер.")
                    return
                mid, name, unit, old_qty = mats[choice-1]
                new_qty = Decimal(input(f"Введите фактический остаток для '{name}': "))
                if new_qty < 0:
                    print("Остаток не может быть отрицательным.")
                    return
                reason = input("Причина корректировки: ").strip()
                diff = new_qty - old_qty
                cur.execute("""
                    INSERT INTO material_inventory (material_id, quantity)
                    VALUES (%s, %s)
                    ON CONFLICT (material_id) DO UPDATE SET quantity = EXCLUDED.quantity
                """, (mid, new_qty))
                cur.execute("""
                    INSERT INTO material_transactions (material_id, quantity_change, transaction_type)
                    VALUES (%s, %s, 'adjustment')
                """, (mid, diff))
                cur.execute("""
                    INSERT INTO inventory_adjustments (material_id, old_quantity, new_quantity, difference, reason)
                    VALUES (%s, %s, %s, %s, %s)
                """, (mid, old_qty, new_qty, diff, reason))
                conn.commit()
                print(f"Остаток материала '{name}' изменён с {old_qty} на {new_qty} (разница {diff}).")
            except ValueError:
                print("Ошибка ввода.")