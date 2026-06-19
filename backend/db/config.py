import configparser
import os
import sys
from pathlib import Path


def _default_sslmode_for_host(host):
    value = str(host or "").strip().lower()
    if value in ("", "localhost", "127.0.0.1", "::1"):
        return "disable"
    return "require"


def get_config_path():
    """Returns the editable config.ini path for both source and packaged runs."""
    cwd_config = Path.cwd() / 'config.ini'
    if cwd_config.exists():
        return cwd_config
    if getattr(sys, 'frozen', False):
        return Path(sys.executable).resolve().parent / 'config.ini'
    return Path(__file__).resolve().parent.parent.parent / 'config.ini'


def create_default_config(path=None):
    config_path = Path(path) if path else get_config_path()
    config = configparser.ConfigParser()
    config['database'] = {
        'host': 'localhost',
        'port': '5432',
        'name': 'cost',
        'user': 'postgres',
        'password': '',
        'sslmode': 'disable',
        'sslrootcert': ''
    }
    config['app'] = {'connection_confirmed': 'false'}
    with open(config_path, 'w', encoding='utf-8') as file:
        config.write(file)
    return config_path


def get_config(create_if_missing=False):
    """Reads config.ini with database connection settings."""
    config = configparser.ConfigParser()
    config_path = get_config_path()

    if not config_path.exists():
        if create_if_missing:
            create_default_config(config_path)
        else:
            raise FileNotFoundError(
                f"Файл config.ini не найден: {config_path}\n"
                "Создайте config.ini рядом с приложением или заполните подключение в стартовом окне."
            )

    config.read(config_path, encoding='utf-8')
    if 'database' not in config:
        if create_if_missing:
            config['database'] = {}
        else:
            raise ValueError("Секция [database] не найдена в config.ini")
    return config


def save_db_config(host, port, name, user, password, confirmed=True):
    config = get_config(create_if_missing=True)
    if 'database' not in config:
        config['database'] = {}
    normalized_host = str(host or 'localhost').strip()
    config['database']['host'] = normalized_host
    config['database']['port'] = str(port or '5432').strip()
    config['database']['name'] = str(name or 'cost').strip()
    config['database']['user'] = str(user or 'postgres').strip()
    config['database']['password'] = str(password or '')
    existing_sslmode = str(config['database'].get('sslmode', '') or '').strip()
    if not existing_sslmode:
        config['database']['sslmode'] = _default_sslmode_for_host(normalized_host)
    config['database']['sslrootcert'] = str(config['database'].get('sslrootcert', '') or '').strip()
    if 'app' not in config:
        config['app'] = {}
    config['app']['connection_confirmed'] = 'true' if confirmed else 'false'

    config_path = get_config_path()
    with open(config_path, 'w', encoding='utf-8') as file:
        config.write(file)
    return config_path


def get_db_config():
    """Returns normalized database connection settings from config.ini."""
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
        'password': db_config['password'],
        'sslmode': str(db_config.get('sslmode', '') or _default_sslmode_for_host(db_config['host'])).strip(),
        'sslrootcert': str(db_config.get('sslrootcert', '') or '').strip()
    }


def is_connection_confirmed():
    try:
        config = get_config(create_if_missing=False)
        return config.getboolean('app', 'connection_confirmed', fallback=False)
    except Exception:
        return False
