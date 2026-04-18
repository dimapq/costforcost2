from decimal import Decimal
from backend.db.connection import get_connection

def get_materials_summary():
    """Возвращает суммарную стоимость материалов на складе по последним ценам."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                WITH latest_prices AS (
                    SELECT DISTINCT ON (material_id) material_id, price_per_unit
                    FROM purchases WHERE price_per_unit IS NOT NULL
                    ORDER BY material_id, purchase_date DESC
                )
                SELECT COALESCE(SUM(lp.price_per_unit * inv.quantity), 0)
                FROM material_inventory inv
                JOIN materials m ON inv.material_id = m.id
                LEFT JOIN latest_prices lp ON inv.material_id = lp.material_id
                WHERE inv.quantity > 0
            """)
            return cur.fetchone()[0] or Decimal('0')
    search = input("Введите часть названия материала: ").strip()
    if not search:
        return
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT m.name, mt.quantity_change, mt.transaction_type, mt.created_at::date
                FROM material_transactions mt
                JOIN materials m ON mt.material_id = m.id
                WHERE m.name ILIKE %s
                ORDER BY mt.created_at DESC
                LIMIT 30
            """, (f"%{search}%",))
            rows = cur.fetchall()
            if not rows:
                print("Движений не найдено.")
                return
            print(f"\n=== История движений по материалу (последние 30 записей) ===")
            print(f"{'Дата':<12} {'Тип':<12} {'Изменение':>12} {'Материал':<30}")
            print("-" * 70)
            for name, change, ttype, dt in rows:
                print(f"{str(dt):<12} {ttype or '—':<12} {change:>12.2f} {name:<30}")