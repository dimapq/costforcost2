from decimal import Decimal
from datetime import datetime
import re

def parse_excel_formula(val):
    if isinstance(val, str) and val.startswith('='):
        m = re.match(r'=(\d+\.?\d*)/(\d+\.?\d*)', val)
        if m:
            return Decimal(m.group(1)) / Decimal(m.group(2))
    return val

def safe_decimal(val, default=None):
    if val is None or val == '':
        return default
    try:
        return Decimal(str(val).replace(',', '.').replace(' ', ''))
    except:
        return default

def safe_date(val):
    if val is None or val == '':
        return None
    if isinstance(val, datetime):
        return val.date()
    try:
        from pandas import to_datetime
        return to_datetime(val).date()
    except:
        return None