import random
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path
import re
import sys

import psycopg2
from psycopg2 import Binary

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from backend.db.config import get_db_config


SEED = 20260624
TODAY = date(2026, 6, 24)


def connect():
    cfg = get_db_config()
    return psycopg2.connect(
        host=cfg["host"],
        port=cfg["port"],
        dbname=cfg["dbname"],
        user=cfg["user"],
        password=cfg["password"],
        sslmode=cfg.get("sslmode") or "disable",
    )


def daterange_back(days_back_min, days_back_max):
    return TODAY - timedelta(days=random.randint(days_back_min, days_back_max))


def insert_returning(cur, sql_text, params):
    normalized = " ".join(sql_text.strip().split())
    if "RETURNING ID" in normalized.upper():
        match = re.search(
            r"INSERT INTO\s+([a-zA-Z_]+)\s*\((.+?)\)\s*VALUES\s*\((.+?)\)\s*RETURNING\s+id",
            sql_text,
            flags=re.IGNORECASE | re.DOTALL,
        )
        if match:
            table_name = match.group(1)
            column_list = match.group(2).strip()
            values_list = match.group(3).strip()
            cur.execute(f'SELECT COALESCE(MAX(id), 0) + 1 FROM "{table_name}"')
            next_id = cur.fetchone()[0]
            sql_text = (
                f'INSERT INTO {table_name} (id, {column_list}) '
                f'VALUES (%s, {values_list}) RETURNING id'
            )
            params = (next_id, *params)
            cur.execute(sql_text, params)
            return cur.fetchone()[0]
    cur.execute(sql_text, params)
    return cur.fetchone()[0]


def truncate_all(cur):
    cur.execute(
        """
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name
        """
    )
    tables = [row[0] for row in cur.fetchall()]
    cur.execute(
        "TRUNCATE TABLE "
        + ", ".join(f'public."{table}"' for table in tables)
        + " RESTART IDENTITY CASCADE"
    )


def ensure_id_defaults(cur):
    cur.execute(
        """
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND column_name = 'id'
        ORDER BY table_name
        """
    )
    for (table_name,) in cur.fetchall():
        sequence_name = f"{table_name}_id_seq"
        cur.execute("SELECT to_regclass(%s)", (f"public.{sequence_name}",))
        if cur.fetchone()[0]:
            cur.execute(
                f"""
                ALTER TABLE public."{table_name}"
                ALTER COLUMN id SET DEFAULT nextval('public.{sequence_name}')
                """
            )


def build_material_name(prefix, idx, suffix=""):
    return f"{prefix} {idx:03d}{suffix}".strip()


def main():
    random.seed(SEED)
    conn = connect()
    conn.autocommit = False
    cur = conn.cursor()

    try:
        ensure_id_defaults(cur)
        truncate_all(cur)

        material_type_ids = {}
        for name in ["Металл", "Крепёж", "Электрика", "Пластик", "Дерево", "Упаковка"]:
            material_type_ids[name] = insert_returning(
                cur,
                "INSERT INTO material_types (name) VALUES (%s) RETURNING id",
                (name,),
            )

        supplier_ids = {}
        suppliers = [
            "МеталлСнаб",
            "ПромКрепеж",
            "ЭлектроМаркет",
            "ПластТорг",
            "СтанкоКомплект",
            "ТехИмпорт",
            "ФанераПлюс",
            "СкладПоставка",
            "РесурсЛиния",
            "ПромСервис",
            "ЛогистикТрейд",
            "ТочнаяМеханика",
            "Внутреннее производство",
        ]
        for name in suppliers:
            supplier_ids[name] = insert_returning(
                cur,
                "INSERT INTO suppliers (name) VALUES (%s) RETURNING id",
                (name,),
            )

        plate_type_ids = {}
        for name in ["Алюминий", "Поликарбонат", "Текстолит", "Фанера"]:
            plate_type_ids[name] = insert_returning(
                cur,
                "INSERT INTO plate_material_types (name) VALUES (%s) RETURNING id",
                (name,),
            )

        work_type_ids = {}
        work_types = {
            "Резка": "Подготовка и раскрой материалов",
            "Сборка": "Основная механическая сборка",
            "Электромонтаж": "Подключение электрических компонентов",
            "Настройка": "Настройка узлов и механизмов",
            "Тестирование": "Проверка и тестовый запуск",
            "Упаковка": "Финальная упаковка и подготовка к отгрузке",
            "Общая работа": "Общие производственные работы",
        }
        for name, description in work_types.items():
            work_type_ids[name] = insert_returning(
                cur,
                "INSERT INTO work_types (name, description) VALUES (%s, %s) RETURNING id",
                (name, description),
            )

        employee_ids = []
        employee_rates = {}
        employee_names = [
            ("Илья", "мастер", 850),
            ("Константин", "сборщик", 700),
            ("Евгений", "электрик", 760),
            ("Алексей", "слесарь", 680),
            ("Павел", "оператор ЧПУ", 900),
            ("Дмитрий", "упаковщик", 520),
            ("Андрей", "контролёр ОТК", 780),
            ("Михаил", "техник", 640),
            ("Сергей", "монтажник", 720),
            ("Антон", "кладовщик", 560),
            ("Владимир", "наладчик", 840),
            ("Роман", "универсал", 690),
        ]
        for name, position, rate in employee_names:
            eid = insert_returning(
                cur,
                """
                INSERT INTO employees (name, hourly_rate, position, active)
                VALUES (%s, %s, %s, %s)
                RETURNING id
                """,
                (name, rate, position, True),
            )
            employee_ids.append(eid)
            employee_rates[eid] = rate

        tool_ids = []
        tool_names = [
            "Фреза твердосплавная",
            "Сверло ступенчатое",
            "Ключ динамометрический",
            "Штангенциркуль цифровой",
            "Паяльная станция",
            "Шлифовальный круг",
            "Набор метчиков",
            "Пресс-форма малая",
            "Оснастка для сборки",
            "Резец токарный",
            "Фреза по алюминию",
            "Фреза по пластику",
            "Нож раскройный",
            "Щуп измерительный",
            "Лазерный уровень",
            "Набор шестигранников",
            "Электроотвёртка",
            "Ручной пресс",
            "Ножовка по металлу",
            "Тестер напряжения",
            "Станочная оправка",
            "Прижимной модуль",
            "Калибр резьбовой",
            "Угломер электронный",
        ]
        for idx, name in enumerate(tool_names, start=1):
            cost = round(random.uniform(2500, 42000), 2)
            life = random.choice([12, 18, 24, 36, 48])
            monthly = round(cost / life, 2)
            residual = round(cost * random.uniform(0.25, 0.9), 2)
            status = "written_off" if idx in (6, 18) else "active"
            tool_ids.append(
                insert_returning(
                    cur,
                    """
                    INSERT INTO tools
                    (name, inventory_number, purchase_date, purchase_cost, useful_life_months, monthly_depreciation, residual_value, status, notes)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        name,
                        f"TL-{2024 + idx % 3}-{idx:03d}",
                        TODAY - timedelta(days=random.randint(120, 1200)),
                        cost,
                        life,
                        monthly,
                        residual,
                        status,
                        f"Оснастка участка №{random.randint(1,4)}",
                    ),
                )
            )

        material_ids = {}
        material_info = {}
        all_regular_materials = []
        plate_raw_materials_by_type = defaultdict(list)
        composite_output_materials = []
        plate_output_materials = []

        regular_catalog = [
            ("Профиль алюминиевый", "Металл", "м"),
            ("Лист стальной", "Металл", "кг"),
            ("Винт М6", "Крепёж", "шт"),
            ("Гайка М6", "Крепёж", "шт"),
            ("Шайба усиленная", "Крепёж", "шт"),
            ("Кабель сигнальный", "Электрика", "м"),
            ("Клемма силовая", "Электрика", "шт"),
            ("Разъём модульный", "Электрика", "шт"),
            ("Корпус пластиковый", "Пластик", "шт"),
            ("Втулка пластиковая", "Пластик", "шт"),
            ("Брус берёзовый", "Дерево", "м"),
            ("Уголок фанерный", "Дерево", "шт"),
            ("Короб транспортный", "Упаковка", "шт"),
            ("Плёнка защитная", "Упаковка", "м"),
        ]

        regular_count = 140
        for idx in range(1, regular_count + 1):
            base_name, type_name, unit = regular_catalog[(idx - 1) % len(regular_catalog)]
            name = build_material_name(base_name, idx)
            material_id = insert_returning(
                cur,
                """
                INSERT INTO materials
                (name, unit, type_id, product_url, notes, source, updated_date, is_plate, plate_material_type_id,
                 low_stock_threshold, enough_stock_threshold, category)
                VALUES (%s, %s, %s, %s, %s, %s, %s, FALSE, NULL, %s, %s, %s)
                RETURNING id
                """,
                (
                    name,
                    unit,
                    material_type_ids[type_name],
                    f"https://demo.example.com/materials/{idx:03d}",
                    f"{base_name}, серия {idx:03d}",
                    random.choice(suppliers[:-1]),
                    daterange_back(1, 90),
                    round(random.uniform(1, 5), 2),
                    round(random.uniform(4, 12), 2),
                    "Материалы",
                ),
            )
            material_ids[name] = material_id
            material_info[material_id] = {"name": name, "unit": unit, "category": "Материалы"}
            all_regular_materials.append(material_id)

        plate_raw_specs = [
            ("Алюминий", "Лист алюминиевый 2мм"),
            ("Алюминий", "Лист алюминиевый 4мм"),
            ("Поликарбонат", "Лист поликарбоната прозрачный"),
            ("Поликарбонат", "Лист поликарбоната дымчатый"),
            ("Текстолит", "Лист текстолита FR4"),
            ("Текстолит", "Лист текстолита промышленный"),
            ("Фанера", "Фанера шлифованная"),
            ("Фанера", "Фанера влагостойкая"),
        ]
        for idx in range(1, 17):
            type_name, base_name = plate_raw_specs[(idx - 1) % len(plate_raw_specs)]
            name = f"{base_name} #{idx:02d}"
            material_id = insert_returning(
                cur,
                """
                INSERT INTO materials
                (name, unit, type_id, product_url, notes, source, updated_date, is_plate, plate_material_type_id,
                 low_stock_threshold, enough_stock_threshold, category)
                VALUES (%s, %s, %s, %s, %s, %s, %s, TRUE, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    name,
                    "м²",
                    material_type_ids["Металл" if type_name == "Алюминий" else ("Пластик" if type_name in ("Поликарбонат", "Текстолит") else "Дерево")],
                    f"https://demo.example.com/plates/{idx:02d}",
                    f"Плита для раскроя, материал: {type_name}",
                    random.choice(["МеталлСнаб", "ПластТорг", "ФанераПлюс"]),
                    daterange_back(1, 60),
                    plate_type_ids[type_name],
                    1,
                    3,
                    "Раскрой плит",
                ),
            )
            material_ids[name] = material_id
            material_info[material_id] = {"name": name, "unit": "м²", "category": "Раскрой плит"}
            plate_raw_materials_by_type[type_name].append(material_id)

        for idx in range(1, 25):
            name = f"Составной узел {idx:02d}"
            material_id = insert_returning(
                cur,
                """
                INSERT INTO materials
                (name, unit, type_id, product_url, notes, source, updated_date, is_plate, plate_material_type_id,
                 low_stock_threshold, enough_stock_threshold, category)
                VALUES (%s, %s, %s, NULL, %s, %s, %s, FALSE, NULL, %s, %s, %s)
                RETURNING id
                """,
                (
                    name,
                    "шт",
                    material_type_ids[random.choice(["Металл", "Пластик", "Электрика"])],
                    f"Составная деталь для сборки модели {random.randint(1,18):02d}",
                    "Внутреннее производство",
                    daterange_back(1, 45),
                    1,
                    4,
                    "Составные",
                ),
            )
            material_ids[name] = material_id
            material_info[material_id] = {"name": name, "unit": "шт", "category": "Составные"}
            composite_output_materials.append(material_id)

        plate_output_names = [
            "Панель лицевая",
            "Кронштейн боковой",
            "Защитная крышка",
            "Монтажная пластина",
            "Фигурка декоративная",
            "Шаблон опорный",
            "Пластина крепёжная",
            "Экран прозрачный",
            "Прокладка листовая",
            "Площадка монтажная",
        ]
        template_ids = []
        for idx in range(1, 21):
            base_name = plate_output_names[(idx - 1) % len(plate_output_names)]
            name = f"{base_name} {idx:02d}"
            type_name = random.choice(list(plate_type_ids.keys()))
            material_id = insert_returning(
                cur,
                """
                INSERT INTO materials
                (name, unit, type_id, product_url, notes, source, updated_date, is_plate, plate_material_type_id,
                 low_stock_threshold, enough_stock_threshold, category)
                VALUES (%s, %s, %s, NULL, %s, %s, %s, FALSE, NULL, %s, %s, %s)
                RETURNING id
                """,
                (
                    name,
                    "шт",
                    material_type_ids["Металл" if type_name == "Алюминий" else ("Пластик" if type_name in ("Поликарбонат", "Текстолит") else "Дерево")],
                    f"Деталь из плиты {type_name}",
                    "Внутреннее производство",
                    daterange_back(1, 40),
                    1,
                    3,
                    "Раскрой плит",
                ),
            )
            material_ids[name] = material_id
            material_info[material_id] = {"name": name, "unit": "шт", "category": "Раскрой плит"}
            plate_output_materials.append((material_id, type_name))
            template_ids.append(
                insert_returning(
                    cur,
                    """
                    INSERT INTO plate_part_templates
                    (name, plate_material_type_id, part_unit, production_minutes, drawing_file_path, process_file_path, notes,
                     created_at, updated_at, drawing_file_name, drawing_file_data, process_file_name, process_file_data, is_active)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, TRUE)
                    RETURNING id
                    """,
                    (
                        name,
                        plate_type_ids[type_name],
                        "шт",
                        random.randint(18, 95),
                        f"C:/drawings/{name.replace(' ', '_').lower()}.dxf",
                        f"C:/cnc/{name.replace(' ', '_').lower()}.tap",
                        f"Шаблон для детали {name} из материала {type_name}",
                        datetime.now() - timedelta(days=random.randint(5, 120)),
                        datetime.now() - timedelta(days=random.randint(0, 4)),
                        f"{name.replace(' ', '_').lower()}.dxf",
                        Binary(f"DXF data for {name}".encode("utf-8")),
                        f"{name.replace(' ', '_').lower()}.tap",
                        Binary(f"GCODE data for {name}".encode("utf-8")),
                        ),
                )
            )

        recipe_ids = {}
        for idx, output_material_id in enumerate(composite_output_materials, start=1):
            recipe_id = insert_returning(
                cur,
                """
                INSERT INTO composite_material_recipes
                (output_material_id, output_quantity, notes, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    output_material_id,
                    random.choice([1, 2, 4]),
                    f"Рецепт составного узла {idx:02d}",
                    datetime.now() - timedelta(days=random.randint(20, 120)),
                    datetime.now() - timedelta(days=random.randint(0, 10)),
                ),
            )
            recipe_ids[output_material_id] = recipe_id
            recipe_materials = random.sample(all_regular_materials, random.randint(3, 5))
            for material_id in recipe_materials:
                cur.execute(
                    """
                    INSERT INTO composite_material_recipe_items
                    (recipe_id, material_id, quantity)
                    VALUES (%s, %s, %s)
                    """,
                    (recipe_id, material_id, round(random.uniform(0.5, 6.0), 3)),
                )

        machine_ids = []
        machine_material_map = defaultdict(list)
        machine_tool_map = defaultdict(list)
        machine_names = [
            "МК-101 Compact",
            "МК-102 Drive",
            "МК-103 Linear",
            "МК-104 Turbo",
            "МК-105 Smart",
            "МК-106 CNC",
            "МК-107 Workshop",
            "МК-108 Plus",
            "МК-109 Nano",
            "МК-110 Vector",
            "МК-111 Base",
            "МК-112 Heavy",
            "МК-113 Flex",
            "МК-114 Light",
            "МК-115 Control",
            "МК-116 Frame",
            "МК-117 Panel",
            "МК-118 Expert",
        ]

        for name in machine_names:
            machine_id = insert_returning(
                cur,
                "INSERT INTO machines (model, total_cost) VALUES (%s, %s) RETURNING id",
                (name, 0),
            )
            machine_ids.append(machine_id)
            regular_subset = random.sample(all_regular_materials, 6)
            composite_material = random.choice(composite_output_materials)
            plate_output_material = random.choice(plate_output_materials)[0]
            selected_materials = regular_subset + [composite_material, plate_output_material]
            for material_id in selected_materials:
                qty = round(random.uniform(0.5, 12.0), 3)
                cur.execute(
                    """
                    INSERT INTO machine_materials (machine_id, material_id, quantity)
                    VALUES (%s, %s, %s)
                    """,
                    (machine_id, material_id, qty),
                )
                machine_material_map[machine_id].append((material_id, qty))

            chosen_tools = random.sample(tool_ids, 3)
            for tool_id in chosen_tools:
                usage = round(random.uniform(0.01, 0.09), 4)
                cur.execute(
                    """
                    INSERT INTO machine_tools (machine_id, tool_id, usage_per_unit)
                    VALUES (%s, %s, %s)
                    """,
                    (machine_id, tool_id, usage),
                )
                machine_tool_map[machine_id].append((tool_id, usage))

            for work_name in ["Резка", "Сборка", "Электромонтаж", "Тестирование"]:
                cur.execute(
                    """
                    INSERT INTO machine_labor_costs (machine_id, work_type_id, fixed_cost, estimated_hours)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (
                        machine_id,
                        work_type_ids[work_name],
                        round(random.uniform(250, 1800), 2),
                        round(random.uniform(0.8, 6.0), 2),
                    ),
                )

        purchases_by_material = defaultdict(list)
        latest_price = {}

        def add_purchase(material_id, supplier_id, purchase_date, price, quantity, remaining, notes, is_cash):
            purchase_id = insert_returning(
                cur,
                """
                INSERT INTO purchases
                (material_id, supplier_id, purchase_date, price_per_unit, quantity, remaining_quantity, purchased_by, notes, created_at, is_cash)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    material_id,
                    supplier_id,
                    purchase_date,
                    price,
                    quantity,
                    remaining,
                    random.choice(["Илья", "Антон", "Павел", "Константин"]),
                    notes,
                    datetime.combine(purchase_date, datetime.min.time()) + timedelta(hours=random.randint(8, 18)),
                    is_cash,
                ),
            )
            purchases_by_material[material_id].append(
                {
                    "id": purchase_id,
                    "price": float(price),
                    "remaining": float(remaining),
                    "is_cash": bool(is_cash),
                    "date": purchase_date,
                }
            )
            latest_price[material_id] = float(price)
            return purchase_id

        for material_id in all_regular_materials:
            unit = material_info[material_id]["unit"]
            lots = 2 if random.random() < 0.7 else 1
            for lot_idx in range(lots):
                qty = round(random.uniform(25, 180), 3) if unit in ("шт", "м") else round(random.uniform(8, 90), 3)
                price = round(random.uniform(12, 850), 2)
                purchase_date = daterange_back(10 + lot_idx * 15, 180 + lot_idx * 20)
                add_purchase(
                    material_id,
                    supplier_ids[random.choice(suppliers[:-1])],
                    purchase_date,
                    price,
                    qty,
                    qty,
                    f"Поставка сырья, партия {material_id}-{lot_idx+1}",
                    random.random() < 0.18,
                )

        for material_ids_for_type in plate_raw_materials_by_type.values():
            for material_id in material_ids_for_type:
                lots = 2 if random.random() < 0.5 else 1
                for lot_idx in range(lots):
                    qty = round(random.uniform(2, 14), 3)
                    price = round(random.uniform(900, 4200), 2)
                    purchase_date = daterange_back(5 + lot_idx * 8, 120 + lot_idx * 12)
                    add_purchase(
                        material_id,
                        supplier_ids[random.choice(["МеталлСнаб", "ПластТорг", "ФанераПлюс"])],
                        purchase_date,
                        price,
                        qty,
                        qty,
                        f"Плита под раскрой, партия {material_id}-{lot_idx+1}",
                        random.random() < 0.25,
                    )

        for idx, material_id in enumerate(composite_output_materials, start=1):
            qty = round(random.uniform(8, 40), 3)
            price = round(random.uniform(180, 1400), 2)
            add_purchase(
                material_id,
                supplier_ids["Внутреннее производство"],
                daterange_back(1, 90),
                price,
                qty,
                qty,
                f"Выпуск составного узла {idx:02d}",
                random.random() < 0.1,
            )

        plate_template_by_output_material = {}
        for template_id, (material_id, _type_name) in zip(template_ids, plate_output_materials):
            plate_template_by_output_material[material_id] = template_id
            qty = round(random.uniform(6, 28), 3)
            price = round(random.uniform(120, 2100), 2)
            add_purchase(
                material_id,
                supplier_ids["Внутреннее производство"],
                daterange_back(1, 75),
                price,
                qty,
                qty,
                f"Выпуск детали раскроя для шаблона {template_id}",
                random.random() < 0.1,
            )

        average_price = {}
        for machine_id in machine_ids:
            total_cost = 0.0
            for material_id, qty in machine_material_map[machine_id]:
                total_cost += qty * latest_price.get(material_id, 0)
            cur.execute(
                "SELECT COALESCE(SUM(fixed_cost), 0) FROM machine_labor_costs WHERE machine_id = %s",
                (machine_id,),
            )
            total_cost += float(cur.fetchone()[0] or 0)
            cur.execute("UPDATE machines SET total_cost = %s WHERE id = %s", (round(total_cost, 2), machine_id))

        for material_id, lots in purchases_by_material.items():
            average_price[material_id] = round(
                sum(l["price"] for l in lots) / max(len(lots), 1),
                2,
            )

        def allocate_from_purchases(material_id, required_qty):
            allocations = []
            needed = round(float(required_qty), 4)
            for lot in sorted(purchases_by_material[material_id], key=lambda item: (item["date"], item["id"])):
                if needed <= 0:
                    break
                available = round(float(lot["remaining"]), 4)
                if available <= 0:
                    continue
                take = min(available, needed)
                lot["remaining"] = round(available - take, 4)
                needed = round(needed - take, 4)
                allocations.append((lot["id"], take, lot["price"], lot["is_cash"]))
            if needed > 0.0001:
                category = material_info[material_id]["category"]
                extra_qty = round(needed + random.uniform(3, 15), 3)
                purchase_id = add_purchase(
                    material_id,
                    supplier_ids["Внутреннее производство"] if category in ("Составные", "Раскрой плит") else supplier_ids[random.choice(suppliers[:-1])],
                    TODAY - timedelta(days=random.randint(0, 10)),
                    round(max(latest_price.get(material_id, average_price.get(material_id, 100)), 1), 2),
                    extra_qty,
                    extra_qty,
                    f"Автодополнение остатка для seed: {material_info[material_id]['name']}",
                    False,
                )
                for lot in sorted(purchases_by_material[material_id], key=lambda item: (item["date"], item["id"])):
                    if lot["id"] != purchase_id or needed <= 0:
                        continue
                    take = min(lot["remaining"], needed)
                    lot["remaining"] = round(lot["remaining"] - take, 4)
                    needed = round(needed - take, 4)
                    allocations.append((lot["id"], take, lot["price"], lot["is_cash"]))
            if needed > 0.0001:
                raise RuntimeError(f"Недостаточно остатка для материала {material_info[material_id]['name']} (нужно {required_qty}, не хватило {needed})")
            return allocations

        finished_good_ids = []
        finished_good_data = {}
        machine_by_fg = {}
        fg_status_blocks = (
            [("in_progress", "in_progress")] * 12
            + [("in_stock", "completed")] * 12
            + [("sold", "completed")] * 12
        )

        for idx, (status, production_status) in enumerate(fg_status_blocks, start=1):
            machine_id = random.choice(machine_ids)
            machine_name = machine_names[machine_ids.index(machine_id)]
            start_date = TODAY - timedelta(days=random.randint(8, 110))
            produced_date = None
            sale_date = None
            buyer = None
            if production_status == "completed":
                produced_date = start_date + timedelta(days=random.randint(3, 18))
            if status == "sold":
                sale_date = produced_date + timedelta(days=random.randint(3, 45))
                buyer = random.choice(["ООО ТехПартнёр", "ИП Карпов", "Мастерская Вектор", "Завод Пульс", "ООО Контур"])
            fg_id = insert_returning(
                cur,
                """
                INSERT INTO finished_goods
                (machine_model, machine_id, cost_price, produced_date, status, inventory_number, buyer, sale_date, notes, start_date, indirect_cost, misc_expense_cost, production_status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 0, 0, %s)
                RETURNING id
                """,
                (
                    machine_name,
                    machine_id,
                    0,
                    produced_date,
                    status,
                    f"FG-26-{idx:03d}",
                    buyer,
                    sale_date,
                    f"Демо-станок {idx:03d}",
                    start_date,
                    production_status,
                ),
            )
            finished_good_ids.append(fg_id)
            machine_by_fg[fg_id] = machine_id
            finished_good_data[fg_id] = {
                "machine_id": machine_id,
                "status": status,
                "production_status": production_status,
                "start_date": start_date,
                "produced_date": produced_date,
                "sale_date": sale_date,
                "buyer": buyer,
                "material_cost": 0.0,
                "labor_cost": 0.0,
                "indirect_cost": 0.0,
                "misc_cost": 0.0,
            }

        work_log_ids = []
        fg_work_log_map = defaultdict(list)
        for fg_id in finished_good_ids:
            fg = finished_good_data[fg_id]
            machine_id = fg["machine_id"]
            end_date = fg["produced_date"] or TODAY
            log_count = random.randint(2, 4)
            period_days = max((end_date - fg["start_date"]).days, 1)
            for _ in range(log_count):
                employee_id = random.choice(employee_ids)
                work_name = random.choice(list(work_type_ids.keys()))
                log_date = fg["start_date"] + timedelta(days=random.randint(0, period_days))
                hours = round(random.uniform(1.5, 7.5), 2)
                log_id = insert_returning(
                    cur,
                    """
                    INSERT INTO work_logs (employee_id, work_type_id, machine_id, date, hours, notes)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        employee_id,
                        work_type_ids[work_name],
                        machine_id,
                        log_date,
                        hours,
                        f"{work_name} по станку {machine_names[machine_ids.index(machine_id)]}",
                    ),
                )
                work_log_ids.append(log_id)
                fg_work_log_map[fg_id].append((log_id, employee_id, hours))
                finished_good_data[fg_id]["labor_cost"] += hours * employee_rates[employee_id]

        for _ in range(40):
            employee_id = random.choice(employee_ids)
            work_name = random.choice(list(work_type_ids.keys()))
            log_id = insert_returning(
                cur,
                """
                INSERT INTO work_logs (employee_id, work_type_id, machine_id, date, hours, notes)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    employee_id,
                    work_type_ids[work_name],
                    random.choice(machine_ids) if random.random() < 0.6 else None,
                    daterange_back(1, 120),
                    round(random.uniform(0.5, 6.0), 2),
                    f"Общая работа: {work_name}",
                ),
            )
            work_log_ids.append(log_id)

        for fg_id, links in fg_work_log_map.items():
            for log_id, _employee_id, _hours in links:
                cur.execute(
                    """
                    INSERT INTO finished_good_labor (finished_good_id, work_log_id, created_at)
                    VALUES (%s, %s, %s)
                    """,
                    (fg_id, log_id, datetime.now() - timedelta(days=random.randint(0, 60))),
                )

        for fg_id in finished_good_ids:
            machine_id = machine_by_fg[fg_id]
            materials = machine_material_map[machine_id]
            if finished_good_data[fg_id]["production_status"] == "in_progress":
                target_table = "finished_good_material_reservations"
            else:
                target_table = "finished_good_material_consumptions"

            for material_id, qty in materials:
                allocations = allocate_from_purchases(material_id, qty)
                for purchase_id, alloc_qty, price, is_cash in allocations:
                    amount = round(alloc_qty * price, 2)
                    cur.execute(
                        f"""
                        INSERT INTO {target_table}
                        (finished_good_id, material_id, purchase_id, quantity, amount, is_cash, created_at)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        """,
                        (
                            fg_id,
                            material_id,
                            purchase_id,
                            alloc_qty,
                            amount,
                            is_cash,
                            datetime.now() - timedelta(days=random.randint(0, 45)),
                        ),
                    )
                    finished_good_data[fg_id]["material_cost"] += amount

        indirect_category_ids = []
        indirect_categories = [
            ("Аренда", 145000, False),
            ("Электроэнергия", 82000, False),
            ("Интернет и связь", 9800, False),
            ("Сервер и домен", 5400, False),
            ("Уборка и расходники", 12000, True),
            ("Охрана", 26500, False),
        ]
        for name, amount, is_cash in indirect_categories:
            indirect_category_ids.append(
                insert_returning(
                    cur,
                    """
                    INSERT INTO indirect_expense_categories (name, monthly_amount, is_active, notes, is_cash)
                    VALUES (%s, %s, TRUE, %s, %s)
                    RETURNING id
                    """,
                    (name, amount, f"Автосгенерированная статья: {name}", is_cash),
                )
            )

        for fg_id in finished_good_ids:
            fg = finished_good_data[fg_id]
            prod_end = fg["produced_date"] or TODAY
            for category_id in indirect_category_ids:
                alloc_date = fg["start_date"] + timedelta(days=random.randint(0, max((prod_end - fg["start_date"]).days, 1)))
                amount = round(random.uniform(85, 740), 2)
                cur.execute(
                    """
                    INSERT INTO indirect_cost_allocations (category_id, finished_good_id, allocation_date, amount, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (
                        category_id,
                        fg_id,
                        alloc_date,
                        amount,
                        datetime.combine(alloc_date, datetime.min.time()) + timedelta(hours=random.randint(8, 20)),
                    ),
                )
                fg["indirect_cost"] += amount

        misc_expense_ids = []
        selected_fg_pool = list(dict.fromkeys([fg for fg in finished_good_ids if finished_good_data[fg]["status"] != "sold"] + finished_good_ids[:6]))
        misc_modes = ["none", "all", "selected", "selected", "none"]
        for idx in range(1, 21):
            mode = random.choice(misc_modes)
            amount = round(random.uniform(1200, 24000), 2)
            expense_date = daterange_back(1, 150)
            person_name = random.choice(["Илья", "Константин", "Павел", ""]) or None
            expense_id = insert_returning(
                cur,
                """
                INSERT INTO misc_expenses (expense_date, title, amount, notes, is_cash, person_name, allocation_mode, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
                """,
                (
                    expense_date,
                    f"Прочий расход {idx:02d}",
                    amount,
                    f"Служебный расход для тестового сценария #{idx:02d}",
                    random.random() < 0.22,
                    person_name,
                    mode,
                    datetime.combine(expense_date, datetime.min.time()) + timedelta(hours=random.randint(8, 18)),
                ),
            )
            misc_expense_ids.append(expense_id)
            if mode == "all":
                targets = finished_good_ids
            elif mode == "selected":
                targets = random.sample(selected_fg_pool, random.randint(2, 5))
            else:
                targets = []
            targets = list(dict.fromkeys(targets))
            if targets:
                per_fg = round(amount / len(targets), 2)
                running = 0
                for pos, fg_id in enumerate(targets, start=1):
                    alloc = per_fg if pos < len(targets) else round(amount - running, 2)
                    running += alloc
                    cur.execute(
                        """
                        INSERT INTO misc_expense_machine_links (expense_id, finished_good_id, allocated_amount)
                        VALUES (%s, %s, %s)
                        """,
                        (expense_id, fg_id, alloc),
                    )
                    finished_good_data[fg_id]["misc_cost"] += alloc

        for fg_id in finished_good_ids:
            fg = finished_good_data[fg_id]
            total_cost = round(
                fg["material_cost"] + fg["labor_cost"] + fg["indirect_cost"] + fg["misc_cost"],
                2,
            )
            cur.execute(
                """
                UPDATE finished_goods
                SET cost_price = %s,
                    indirect_cost = %s,
                    misc_expense_cost = %s
                WHERE id = %s
                """,
                (total_cost, round(fg["indirect_cost"], 2), round(fg["misc_cost"], 2), fg_id),
            )

        sold_finished_goods = [fg_id for fg_id in finished_good_ids if finished_good_data[fg_id]["status"] == "sold"]
        for fg_id in sold_finished_goods:
            fg = finished_good_data[fg_id]
            sale_price = round(
                fg["material_cost"] + fg["labor_cost"] + fg["indirect_cost"] + fg["misc_cost"] + random.uniform(4500, 18000),
                2,
            )
            profit = round(sale_price - (fg["material_cost"] + fg["labor_cost"] + fg["indirect_cost"] + fg["misc_cost"]), 2)
            cur.execute(
                """
                INSERT INTO sales (finished_good_id, sale_date, sale_price, profit)
                VALUES (%s, %s, %s, %s)
                """,
                (fg_id, fg["sale_date"], sale_price, profit),
            )

        for idx in range(1, 31):
            material_id = random.choice(list(material_info.keys()))
            old_qty = round(random.uniform(2, 50), 3)
            diff = round(random.uniform(-8, 8), 3)
            new_qty = round(max(old_qty + diff, 0), 3)
            cur.execute(
                """
                INSERT INTO inventory_adjustments (material_id, old_quantity, new_quantity, difference, reason, created_at)
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (
                    material_id,
                    old_qty,
                    new_qty,
                    round(new_qty - old_qty, 3),
                    f"Плановая сверка склада #{idx:02d}",
                    datetime.now() - timedelta(days=random.randint(1, 140)),
                ),
            )

        for idx, output_material_id in enumerate(composite_output_materials, start=1):
            recipe_id = recipe_ids[output_material_id]
            cur.execute(
                """
                SELECT material_id, quantity
                FROM composite_material_recipe_items
                WHERE recipe_id = %s
                ORDER BY id
                """,
                (recipe_id,),
            )
            recipe_rows = cur.fetchall()
            produced_qty = round(random.uniform(4, 18), 3)
            for source_material_id, source_qty in recipe_rows:
                source_purchase_id = purchases_by_material[source_material_id][0]["id"]
                cur.execute(
                    """
                    INSERT INTO material_conversions
                    (source_material_id, source_purchase_id, target_material_id, source_quantity, target_quantity, total_cost, notes, created_at, template_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NULL)
                    """,
                    (
                        source_material_id,
                        source_purchase_id,
                        output_material_id,
                        round(float(source_qty) * produced_qty / max(random.choice([1, 2, 4]), 1), 3),
                        produced_qty,
                        round(average_price.get(source_material_id, 0) * float(source_qty), 2),
                        f"Сборка составного узла {idx:02d}",
                        datetime.now() - timedelta(days=random.randint(1, 90)),
                    ),
                )

        for material_id, type_name in plate_output_materials:
            source_material_id = random.choice(plate_raw_materials_by_type[type_name])
            source_purchase_id = purchases_by_material[source_material_id][0]["id"]
            cur.execute(
                """
                INSERT INTO material_conversions
                (source_material_id, source_purchase_id, target_material_id, source_quantity, target_quantity, total_cost, notes, created_at, template_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    source_material_id,
                    source_purchase_id,
                    material_id,
                    round(random.uniform(0.2, 1.6), 3),
                    round(random.uniform(2, 16), 3),
                    round(random.uniform(320, 1600), 2),
                    f"Раскрой плиты {type_name}",
                    datetime.now() - timedelta(days=random.randint(1, 70)),
                    plate_template_by_output_material[material_id],
                ),
            )

        for tool_id in tool_ids:
            rows = random.randint(1, 3)
            for _ in range(rows):
                fg_id = random.choice(finished_good_ids) if random.random() < 0.65 else None
                cur.execute(
                    """
                    INSERT INTO tool_depreciation (tool_id, depreciation_date, amount, finished_good_id, notes)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (
                        tool_id,
                        daterange_back(1, 180),
                        round(random.uniform(40, 1200), 2),
                        fg_id,
                        "Плановая амортизация инструмента",
                    ),
                )

        for idx in range(1, 4):
            period_end = TODAY - timedelta(days=idx * 28)
            period_start = period_end - timedelta(days=29)
            base_amount = round(random.uniform(120000, 280000), 2)
            bonus_percent = random.choice([5, 7.5, 10, 12.5])
            bonus_amount = round(base_amount * bonus_percent / 100, 2)
            cur.execute(
                """
                INSERT INTO employee_bonus_payments
                (period_start, period_end, bonus_percent, base_amount, bonus_amount, paid_until, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    period_start,
                    period_end,
                    bonus_percent,
                    base_amount,
                    bonus_amount,
                    period_end,
                    datetime.combine(period_end, datetime.min.time()) + timedelta(hours=17),
                ),
            )

        for idx in range(1, 25):
            employee_id = random.choice(employee_ids)
            settlement_type = random.choice(["salary", "service", "service", "salary"])
            amount = round(random.uniform(-18000, 22000), 2)
            cur.execute(
                """
                INSERT INTO employee_settlements
                (employee_id, settlement_type, settlement_date, title, amount, notes, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    employee_id,
                    settlement_type,
                    daterange_back(1, 150),
                    f"{'Услуга' if settlement_type == 'service' else 'Корректировка зарплаты'} #{idx:02d}",
                    amount,
                    "Автосгенерированная запись взаиморасчёта",
                    datetime.now() - timedelta(days=random.randint(1, 150)),
                ),
            )

        tax_rows = []
        for idx in range(4):
            period_end = date(2026, 6, 30) - timedelta(days=idx * 30)
            period_start = period_end - timedelta(days=29)
            tax_base = round(random.uniform(180000, 520000), 2)
            tax_rate = 6
            tax_amount = round(tax_base * tax_rate / 100, 2)
            tax_rows.append((period_start, period_end, tax_base, tax_rate, tax_amount))
            cur.execute(
                """
                INSERT INTO tax_payments
                (payment_date, period_start, period_end, tax_rate, tax_base, tax_amount, notes, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    period_end + timedelta(days=5),
                    period_start,
                    period_end,
                    tax_rate,
                    tax_base,
                    tax_amount,
                    f"Уплата налога за период {period_start} - {period_end}",
                    datetime.combine(period_end + timedelta(days=5), datetime.min.time()) + timedelta(hours=11),
                ),
            )

        for material_id, lots in purchases_by_material.items():
            total_remaining = round(sum(lot["remaining"] for lot in lots), 4)
            cur.execute(
                """
                INSERT INTO material_inventory (material_id, quantity)
                VALUES (%s, %s)
                """,
                (material_id, total_remaining),
            )

        for material_id, lots in purchases_by_material.items():
            for lot in lots:
                cur.execute(
                    """
                    INSERT INTO material_transactions
                    (material_id, quantity_change, transaction_type, reference_id, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (
                        material_id,
                        round(lot["remaining"] + random.uniform(0.2, 2.5), 3),
                        "purchase",
                        lot["id"],
                        datetime.combine(lot["date"], datetime.min.time()) + timedelta(hours=9),
                    ),
                )

        cur.execute(
            """
            SELECT finished_good_id, material_id, quantity, created_at
            FROM finished_good_material_reservations
            UNION ALL
            SELECT finished_good_id, material_id, -quantity, created_at
            FROM finished_good_material_consumptions
            """
        )
        for fg_id, material_id, qty_delta, created_at in cur.fetchall():
            cur.execute(
                """
                INSERT INTO material_transactions
                (material_id, quantity_change, transaction_type, reference_id, created_at)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    material_id,
                    qty_delta,
                    "reservation" if qty_delta > 0 else "consumption",
                    fg_id,
                    created_at,
                ),
            )

        cur.execute(
            "SELECT material_id, difference, created_at FROM inventory_adjustments"
        )
        for material_id, diff, created_at in cur.fetchall():
            cur.execute(
                """
                INSERT INTO material_transactions
                (material_id, quantity_change, transaction_type, reference_id, created_at)
                VALUES (%s, %s, %s, NULL, %s)
                """,
                (material_id, diff, "adjustment", created_at),
            )

        balance_rows = []
        cur.execute(
            """
            SELECT purchase_date, COALESCE(price_per_unit, 0) * COALESCE(quantity, 0), notes, is_cash
            FROM purchases
            ORDER BY purchase_date
            LIMIT 80
            """
        )
        for purchase_date, expense, notes, is_cash in cur.fetchall():
            balance_rows.append((purchase_date, 0, round(float(expense), 2), notes, is_cash))

        cur.execute(
            """
            SELECT sale_date, sale_price, finished_good_id
            FROM sales
            ORDER BY sale_date
            """
        )
        for sale_date, sale_price, fg_id in cur.fetchall():
            balance_rows.append((sale_date, round(float(sale_price), 2), 0, f"Продажа станка #{fg_id}", False))

        cur.execute(
            """
            SELECT expense_date, amount, title, is_cash
            FROM misc_expenses
            ORDER BY expense_date
            """
        )
        for expense_date, amount, title, is_cash in cur.fetchall():
            balance_rows.append((expense_date, 0, round(float(amount), 2), title, is_cash))

        for period_start, period_end, tax_base, tax_rate, tax_amount in tax_rows:
            balance_rows.append((period_end + timedelta(days=5), 0, tax_amount, f"Налог {tax_rate}% за {period_start} - {period_end}", False))

        for balance_date, income, expense, notes, is_cash in balance_rows[:180]:
            cur.execute(
                """
                INSERT INTO balance (date, income, expense, notes, is_cash)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (balance_date, income, expense, notes, is_cash),
            )

        op_types = [
            "material_add",
            "purchase_add",
            "machine_create",
            "production_start",
            "production_complete",
            "sale_create",
            "salary_log",
            "misc_expense",
            "inventory_adjustment",
            "tool_depreciation",
        ]
        for idx in range(1, 201):
            op_type = random.choice(op_types)
            amount = None
            if op_type in {"purchase_add", "sale_create", "misc_expense", "tool_depreciation"}:
                amount = round(random.uniform(120, 24000), 2)
            cur.execute(
                """
                INSERT INTO app_operations_log (created_at, operation_type, description, amount, details)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    datetime.now() - timedelta(days=random.randint(0, 180), hours=random.randint(0, 23)),
                    op_type,
                    f"Автосгенерированная операция {idx:03d}: {op_type}",
                    amount,
                    f"Seed={SEED}, строка {idx:03d}",
                ),
            )

        conn.commit()

        print("SEED_OK")
        print("materials=200")
        print(f"machines={len(machine_ids)}")
        print(f"finished_goods={len(finished_good_ids)}")
        print(f"employees={len(employee_ids)}")
        print(f"tools={len(tool_ids)}")

    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
