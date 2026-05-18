import psycopg2
from backend.db.config import get_db_config

def get_connection():
    """Создаёт подключение к БД используя параметры из config.ini"""
    try:
        db_config = get_db_config()
        
        # Формируем DATABASE_URL
        DATABASE_URL = (
            f"postgresql://{db_config['user']}:{db_config['password']}@"
            f"{db_config['host']}:{db_config['port']}/{db_config['dbname']}"
            f"?client_encoding=utf8"
        )
        
        return psycopg2.connect(DATABASE_URL)
        
    except FileNotFoundError as e:
        print("\n" + "="*70)
        print("ОШИБКА: Файл конфигурации не найден!")
        print("="*70)
        print(str(e))
        print("="*70 + "\n")
        raise
        
    except ValueError as e:
        print("\n" + "="*70)
        print("ОШИБКА: Неверная конфигурация!")
        print("="*70)
        print(str(e))
        print("="*70 + "\n")
        raise
        
    except psycopg2.OperationalError as e:
        print("\n" + "="*70)
        print("ОШИБКА: Не удалось подключиться к базе данных!")
        print("="*70)
        print(f"Проверьте параметры подключения в config.ini:")
        db_config = get_db_config()
        print(f"  Host: {db_config['host']}")
        print(f"  Port: {db_config['port']}")
        print(f"  Database: {db_config['dbname']}")
        print(f"  User: {db_config['user']}")
        print(f"\nОшибка PostgreSQL: {e}")
        print("="*70 + "\n")
        raise