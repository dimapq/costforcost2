import os
import configparser
from pathlib import Path

def get_config():
    """Читает конфигурацию из config.ini"""
    config = configparser.ConfigParser()
    
    # Ищем config.ini в корне проекта
    base_dir = Path(__file__).resolve().parent.parent.parent
    config_path = base_dir / 'config.ini'
    
    if not config_path.exists():
        raise FileNotFoundError(
            f"Файл конфигурации не найден: {config_path}\n"
            "Создайте файл config.ini в корне проекта со следующим содержимым:\n"
            "[database]\n"
            "host = localhost\n"
            "port = 5432\n"
            "name = cost\n"
            "user = postgres\n"
            "password = your_password"
        )
    
    config.read(config_path, encoding='utf-8')
    
    if 'database' not in config:
        raise ValueError("Секция [database] не найдена в config.ini")
    
    return config

def get_db_config():
    """Возвращает параметры подключения к БД из config.ini"""
    config = get_config()
    db_config = config['database']
    
    required_keys = ['host', 'port', 'name', 'user', 'password']
    for key in required_keys:
        if key not in db_config:
            raise ValueError(f"Параметр '{key}' не найден в секции [database] файла config.ini")
    
    return {
        'host': db_config['host'],
        'port': int(db_config['port']),
        'dbname': db_config['name'],
        'user': db_config['user'],
        'password': db_config['password']
    }