import sys
from decimal import Decimal
from models.scraper import quick_add_product
from models.material import add_inventory, edit_zero_prices, inventory_adjustment
from models.tools import (
    add_tool, list_tools, depreciate_tool, link_tool_to_machine,
    write_off_tool, show_depreciation_report
)
from models.analytics import quick_balance_analysis
from models.machine import (
    list_machines, select_machine, calculate_machine_cost_from_purchases,
    show_machine_details, add_material_to_machine, remove_material_from_machine,
    edit_material_quantity_in_machine, add_new_machine, show_finished_good_details
)
from models.production import produce_machine, sell_finished_good, plan_purchases
from models.inventory import show_inventory, show_material_transactions
from models.labor import (
    add_employee, list_employees, select_employee,
    add_work_type, list_work_types, select_work_type,
    log_work_hours, calculate_payroll, set_machine_labor_cost)

def main_menu():
    while True:
        print("\n" + "=" * 60)
        print("ГЛАВНОЕ МЕНЮ")
        print("=" * 60)
        print("1. Расчёт стоимости станка")
        print("2. Просмотр спецификации станка")
        print("3. Редактирование спецификации станка")
        print("4. Редактор цен (материалы без цены)")
        print("5. Добавить новый станок (справочник)")
        print("6. Производство станка (списание материалов)")
        print("7. Продажа готового станка")
        print("8. Просмотр остатков материалов")
        print("9. Пополнение склада (приход материалов)")
        print("10. Инвентаризация (корректировка остатков)")
        print("11. Планирование закупок под производство")
        print("12. История движений по материалу")
        print("13. Учёт рабочего времени")
        print("14. Просмотр готового станка (с трудозатратами)")
        print("15. добавление товара по ссылке (парсинг)")
        print("16. Учёт инструментов и оборудования")
        print("17. Быстрый анализ баланса")
        print("0. Выход")
        choice = input("Выберите действие: ").strip()

        if choice == '1':
            machine = select_machine()
            if machine:
                cost = calculate_machine_cost_from_purchases(machine[0])
                print(f"\nСебестоимость станка '{machine[1]}': {cost:.2f} руб.")
        elif choice == '2':
            machine = select_machine()
            if machine:
                show_machine_details(machine[0])
        elif choice == '3':
            machine = select_machine()
            if machine:
                while True:
                    print(f"\n--- Редактирование спецификации станка '{machine[1]}' ---")
                    print("1. Добавить материал")
                    print("2. Удалить материал")
                    print("3. Изменить количество материала")
                    print("0. Назад")
                    sub = input("Выберите: ").strip()
                    if sub == '1':
                        add_material_to_machine(machine[0])
                    elif sub == '2':
                        remove_material_from_machine(machine[0])
                    elif sub == '3':
                        edit_material_quantity_in_machine(machine[0])
                    elif sub == '0':
                        break
                    else:
                        print("Неверный ввод.")
        elif choice == '4':
            edit_zero_prices()
        elif choice == '5':
            add_new_machine()
        elif choice == '6':
            machine = select_machine()
            if machine:
                try:
                    qty = int(input("Количество станков для производства (по умолчанию 1): ") or "1")
                    notes = input("Примечание (необязательно): ")
                    produce_machine(machine[0], qty, notes)
                except ValueError:
                    print("Неверное количество.")
        elif choice == '7':
            sell_finished_good()
        elif choice == '8':
            show_inventory()
        elif choice == '9':
            add_inventory()
        elif choice == '10':
            inventory_adjustment()
        elif choice == '11':
            plan_purchases()
        elif choice == '12':
            show_material_transactions()
        elif choice == '13':
            while True:
                print("\n--- Учёт рабочего времени ---")
                print("1. Добавить работника")
                print("2. Добавить вид работы")
                print("3. Учесть отработанные часы")
                print("4. Расчёт зарплаты за период")
                print("5. Задать трудозатраты для станка")
                print("0. Назад")
                sub = input("Выберите: ").strip()
                if sub == '1':
                    add_employee()
                elif sub == '2':
                    add_work_type()
                elif sub == '3':
                    log_work_hours()
                elif sub == '4':
                    calculate_payroll()
                elif sub == '5':
                    set_machine_labor_cost()
                elif sub == '0':
                    break
                else:
                    print("Неверный ввод.")    
        elif choice == '14':
            try:
                fg_id = int(input("Введите ID готового станка: "))
                show_finished_good_details(fg_id)
            except ValueError:
                print("Неверный ID.")
        elif choice == '15':
            url = input("Введите ссылку на товар: ").strip()
            if url:
                quick_add_product(url)
        elif choice == '16':
            while True:
                print("\n--- Учёт инструментов ---")
                print("1. Добавить инструмент")
                print("2. Просмотреть список инструментов")
                print("3. Начислить амортизацию / списать")
                print("4. Привязать инструмент к модели станка")
                print("5. Отчёт по амортизации за период")
                print("6. Списать инструмент (поломка/утеря)")
                print("0. Назад")
                sub = input("Выберите: ").strip()
                if sub == '1':
                    add_tool()
                elif sub == '2':
                    list_tools()
                elif sub == '3':
                    depreciate_tool()
                elif sub == '4':
                    link_tool_to_machine()
                elif sub == '5':
                    show_depreciation_report()
                elif sub == '6':
                    from models.tools import write_off_tool
                    write_off_tool()
                elif sub == '0':
                    break

                else:
                    print("Неверный ввод.")
        elif choice == '17':
            quick_balance_analysis()
        elif choice == '0':
            print("Выход.")
            sys.exit(0)
        else:
            print("Неверный выбор.")