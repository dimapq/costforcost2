from decimal import Decimal
from datetime import date, datetime
from backend.db.connection import get_connection
from backend.models.inventory import get_materials_summary
from backend.models.tools import get_tools_summary
from backend.models.production import get_finished_goods_summary

def get_recent_transactions(limit=10):
    """Возвращает список последних операций (приход, производство, продажа)."""
    transactions = []
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                (SELECT 'Приход' as type, m.name as description, p.quantity, p.price_per_unit as amount, p.purchase_date as date
                 FROM purchases p JOIN materials m ON p.material_id = m.id
                 ORDER BY p.purchase_date DESC LIMIT %s)
                UNION ALL
                (SELECT 'Производство' as type, fg.machine_model as description, 1 as quantity, fg.cost_price as amount, fg.produced_date as date
                 FROM finished_goods fg ORDER BY fg.produced_date DESC LIMIT %s)
                UNION ALL
                (SELECT 'Продажа' as type, fg.machine_model as description, 1 as quantity, s.sale_price as amount, s.sale_date as date
                 FROM sales s JOIN finished_goods fg ON s.finished_good_id = fg.id
                 ORDER BY s.sale_date DESC LIMIT %s)
                ORDER BY date DESC LIMIT %s
            """, (limit, limit, limit, limit))
            rows = cur.fetchall()
            for row in rows:
                transactions.append({
                    'type': row[0],
                    'description': row[1],
                    'quantity': row[2],
                    'amount': row[3],
                    'date': row[4]
                })
    return transactions

def quick_balance_analysis():
    """Быстрый анализ баланса: активы, затраты, выручка, прибыль."""
    today = date.today()
    month_start = today.replace(day=1)
    
    with get_connection() as conn:
        with conn.cursor() as cur:
            # 1. Стоимость материалов на складе (по последним ценам закупок)
            cur.execute("""
                WITH latest_prices AS (
                    SELECT DISTINCT ON (material_id) material_id, price_per_unit
                    FROM purchases
                    WHERE price_per_unit IS NOT NULL
                    ORDER BY material_id, purchase_date DESC
                )
                SELECT COALESCE(SUM(lp.price_per_unit * inv.quantity), 0)
                FROM material_inventory inv
                JOIN materials m ON inv.material_id = m.id
                LEFT JOIN latest_prices lp ON inv.material_id = lp.material_id
                WHERE inv.quantity > 0
            """)
            materials_value = cur.fetchone()[0] or Decimal('0')
            
            # 2. Остаточная стоимость активных инструментов
            cur.execute("SELECT COALESCE(SUM(residual_value), 0) FROM tools WHERE status = 'active'")
            tools_value = cur.fetchone()[0] or Decimal('0')
            
            # 3. Стоимость готовой продукции в наличии
            cur.execute("SELECT COALESCE(SUM(cost_price), 0) FROM finished_goods WHERE status = 'in_stock'")
            finished_value = cur.fetchone()[0] or Decimal('0')
            cur.execute("SELECT COUNT(*) FROM finished_goods WHERE status = 'in_stock'")
            finished_count = cur.fetchone()[0]
            
            # 4. Затраты на производство за текущий месяц
            cur.execute("""
                SELECT COALESCE(SUM(cost_price), 0)
                FROM finished_goods
                WHERE produced_date BETWEEN %s AND %s
            """, (month_start, today))
            production_cost_month = cur.fetchone()[0] or Decimal('0')
            
            # 5. Выручка от продаж за текущий месяц
            cur.execute("""
                SELECT COALESCE(SUM(sale_price), 0)
                FROM sales
                WHERE sale_date BETWEEN %s AND %s
            """, (month_start, today))
            revenue_month = cur.fetchone()[0] or Decimal('0')
            
            profit_month = revenue_month - production_cost_month
            
            # 6. Общий баланс (нарастающим итогом)
            cur.execute("SELECT COALESCE(SUM(income), 0), COALESCE(SUM(expense), 0) FROM balance")
            total_income, total_expense = cur.fetchone()
            total_balance = total_income - total_expense
    
    # Вывод
    print("\n" + "=" * 60)
    print("БЫСТРЫЙ АНАЛИЗ БАЛАНСА")
    print("=" * 60)
    print(f"Дата отчёта: {today}")
    print("\n--- Активы ---")
    print(f"Материалы на складе (по последним ценам): {materials_value:>15.2f} руб.")
    print(f"Инструменты (остаточная стоимость):        {tools_value:>15.2f} руб.")
    print(f"Готовая продукция в наличии ({finished_count} шт.):     {finished_value:>15.2f} руб.")
    total_assets = materials_value + tools_value + finished_value
    print(f"{'Итого активов:':<42} {total_assets:>15.2f} руб.")
    
    print("\n--- Финансовые показатели за текущий месяц ---")
    print(f"Затраты на производство:                  {production_cost_month:>15.2f} руб.")
    print(f"Выручка от продаж:                        {revenue_month:>15.2f} руб.")
    print(f"Прибыль (месяц):                          {profit_month:>15.2f} руб.")
    
    print("\n--- Общий баланс (нарастающим итогом) ---")
    print(f"Доходы всего:                             {total_income:>15.2f} руб.")
    print(f"Расходы всего:                            {total_expense:>15.2f} руб.")
    print(f"Чистый баланс:                            {total_balance:>15.2f} руб.")
    print("=" * 60)

def get_total_assets():
    """Возвращает суммарную стоимость всех активов."""
    return get_materials_summary() + get_tools_summary() + get_finished_goods_summary()