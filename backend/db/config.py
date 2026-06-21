import configparser
import sys
import ipaddress
from pathlib import Path

PROFILE_SECTION_BY_MODE = {
    "local": "database_local",
    "online": "database_online",
}
DEFAULT_MODE = "local"
ACTIVE_SECTION = "database"
APP_SECTION = "app"
DEFAULT_ONLINE_NAME = "cost_online_demo"
DEFAULT_ONLINE_USER = "cost_client_app"
DEFAULT_ONLINE_PASSWORD = "CostClientApp_2026!"


def _default_sslmode_for_host(host):
    value = str(host or "").strip().lower()
    if value in ("", "localhost", "127.0.0.1", "::1"):
        return "disable"
    try:
        ip_value = ipaddress.ip_address(value)
        if ip_value in ipaddress.ip_network("100.64.0.0/10"):
            return "disable"
    except ValueError:
        pass
    return "require"


def _normalize_mode(mode):
    value = str(mode or DEFAULT_MODE).strip().lower()
    return value if value in PROFILE_SECTION_BY_MODE else DEFAULT_MODE


def _section_for_mode(mode):
    return PROFILE_SECTION_BY_MODE[_normalize_mode(mode)]


def _default_profile(mode):
    normalized = _normalize_mode(mode)
    if normalized == "online":
        host = "localhost"
        name = DEFAULT_ONLINE_NAME
        user = DEFAULT_ONLINE_USER
        password = DEFAULT_ONLINE_PASSWORD
    else:
        host = "localhost"
        name = "cost"
        user = "postgres"
        password = "dbcost1"
    return {
        "host": host,
        "port": "5432",
        "name": name,
        "user": user,
        "password": password,
        "sslmode": _default_sslmode_for_host(host),
        "sslrootcert": "",
    }


def _copy_section(config, source_section, target_section):
    if target_section not in config:
        config[target_section] = {}
    config[target_section].clear()
    if source_section not in config:
        return
    for key, value in config[source_section].items():
        config[target_section][key] = str(value)


def _ensure_config_shape(config):
    if ACTIVE_SECTION not in config:
        config[ACTIVE_SECTION] = {}

    for mode, section_name in PROFILE_SECTION_BY_MODE.items():
        if section_name not in config:
            config[section_name] = {}
        defaults = _default_profile(mode)
        if not config[section_name] and mode == "local" and config[ACTIVE_SECTION]:
            for key, value in config[ACTIVE_SECTION].items():
                config[section_name][key] = str(value)
        for key, value in defaults.items():
            if key not in config[section_name] or config[section_name].get(key, "") == "":
                config[section_name][key] = str(value)

    if APP_SECTION not in config:
        config[APP_SECTION] = {}
    app = config[APP_SECTION]
    if "selected_connection_mode" not in app:
        app["selected_connection_mode"] = DEFAULT_MODE
    if "connection_confirmed" not in app:
        app["connection_confirmed"] = "false"
    for mode in PROFILE_SECTION_BY_MODE:
        key = f"connection_confirmed_{mode}"
        if key not in app:
            app[key] = app.get("connection_confirmed", "false") if mode == DEFAULT_MODE else "false"

    selected_mode = _normalize_mode(app.get("selected_connection_mode", DEFAULT_MODE))
    _copy_section(config, _section_for_mode(selected_mode), ACTIVE_SECTION)



def get_config_path():
    cwd_config = Path.cwd() / "config.ini"
    if cwd_config.exists():
        return cwd_config
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent / "config.ini"
    return Path(__file__).resolve().parent.parent.parent / "config.ini"



def create_default_config(path=None):
    config_path = Path(path) if path else get_config_path()
    config = configparser.ConfigParser()
    config[ACTIVE_SECTION] = dict(_default_profile(DEFAULT_MODE))
    config[_section_for_mode("local")] = dict(_default_profile("local"))
    config[_section_for_mode("online")] = dict(_default_profile("online"))
    config[APP_SECTION] = {
        "selected_connection_mode": DEFAULT_MODE,
        "connection_confirmed": "false",
        "connection_confirmed_local": "false",
        "connection_confirmed_online": "false",
    }
    with open(config_path, "w", encoding="utf-8") as file:
        config.write(file)
    return config_path



def get_config(create_if_missing=False):
    config = configparser.ConfigParser()
    config_path = get_config_path()

    if not config_path.exists():
        if create_if_missing:
            create_default_config(config_path)
        else:
            raise FileNotFoundError(f"Config file not found: {config_path}")

    config.read(config_path, encoding="utf-8")
    _ensure_config_shape(config)
    return config



def save_config(config):
    config_path = get_config_path()
    with open(config_path, "w", encoding="utf-8") as file:
        config.write(file)
    return config_path



def get_selected_connection_mode():
    try:
        config = get_config(create_if_missing=True)
        return _normalize_mode(config.get(APP_SECTION, "selected_connection_mode", fallback=DEFAULT_MODE))
    except Exception:
        return DEFAULT_MODE



def set_selected_connection_mode(mode):
    config = get_config(create_if_missing=True)
    normalized = _normalize_mode(mode)
    config[APP_SECTION]["selected_connection_mode"] = normalized
    _copy_section(config, _section_for_mode(normalized), ACTIVE_SECTION)
    return save_config(config)



def get_db_profile(mode=None):
    config = get_config(create_if_missing=True)
    normalized = _normalize_mode(mode)
    section = config[_section_for_mode(normalized)]
    defaults = _default_profile(normalized)
    return {
        "host": section.get("host", defaults["host"]),
        "port": section.get("port", defaults["port"]),
        "name": section.get("name", defaults["name"]),
        "user": section.get("user", defaults["user"]),
        "password": section.get("password", defaults["password"]),
        "sslmode": str(section.get("sslmode", "") or _default_sslmode_for_host(section.get("host", defaults["host"]))).strip(),
        "sslrootcert": str(section.get("sslrootcert", "") or "").strip(),
    }



def save_db_config(host, port, name, user, password, confirmed=True, mode=None):
    config = get_config(create_if_missing=True)
    normalized_mode = _normalize_mode(mode)
    section_name = _section_for_mode(normalized_mode)
    if section_name not in config:
        config[section_name] = {}
    normalized_host = str(host or "localhost").strip()
    section = config[section_name]
    defaults = _default_profile(normalized_mode)
    section["host"] = normalized_host
    section["port"] = str(port or defaults["port"]).strip()
    section["name"] = str(name or defaults["name"]).strip()
    section["user"] = str(user or defaults["user"]).strip()
    section["password"] = str(password or "")
    existing_sslmode = str(section.get("sslmode", "") or "").strip()
    section["sslmode"] = existing_sslmode or _default_sslmode_for_host(normalized_host)
    section["sslrootcert"] = str(section.get("sslrootcert", "") or "").strip()

    config[APP_SECTION]["selected_connection_mode"] = normalized_mode
    config[APP_SECTION][f"connection_confirmed_{normalized_mode}"] = "true" if confirmed else "false"
    config[APP_SECTION]["connection_confirmed"] = "true" if confirmed else "false"
    _copy_section(config, section_name, ACTIVE_SECTION)
    return save_config(config)



def get_db_config(mode=None):
    if mode:
        profile = get_db_profile(mode)
        return {
            "host": profile["host"],
            "port": int(profile["port"]),
            "dbname": profile["name"],
            "user": profile["user"],
            "password": profile["password"],
            "sslmode": profile["sslmode"],
            "sslrootcert": profile["sslrootcert"],
        }

    config = get_config(create_if_missing=True)
    db_config = config[ACTIVE_SECTION]
    required_keys = ["host", "port", "name", "user", "password"]
    for key in required_keys:
        if key not in db_config:
            raise ValueError(f"Parameter '{key}' not found in config.ini [database]")

    return {
        "host": db_config["host"],
        "port": int(db_config["port"]),
        "dbname": db_config["name"],
        "user": db_config["user"],
        "password": db_config["password"],
        "sslmode": str(db_config.get("sslmode", "") or _default_sslmode_for_host(db_config["host"])).strip(),
        "sslrootcert": str(db_config.get("sslrootcert", "") or "").strip(),
    }



def is_connection_confirmed(mode=None):
    try:
        config = get_config(create_if_missing=False)
        normalized = _normalize_mode(mode or get_selected_connection_mode())
        return config.getboolean(APP_SECTION, f"connection_confirmed_{normalized}", fallback=config.getboolean(APP_SECTION, "connection_confirmed", fallback=False))
    except Exception:
        return False
