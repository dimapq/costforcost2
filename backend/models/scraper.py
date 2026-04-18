# models/scraper.py
import requests
from bs4 import BeautifulSoup
from decimal import Decimal
import re
from backend.db.connection import get_connection

def scrape_vimos_product(url):
    """
    Парсит страницу товара на vimos.ru и возвращает словарь с названием и ценой.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # 1. Название товара
    name = None
    selectors = [
        'h1', 
        '.product-title', 
        '.product-name', 
        '[itemprop="name"]',
        '.product__title'
    ]
    for sel in selectors:
        elem = soup.select_one(sel)
        if elem:
            name = elem.get_text(strip=True)
            break
    
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*купить.*$', '', name, flags=re.IGNORECASE)
    
    # 2. Цена
    price = None
    price_selectors = [
        '.price', 
        '.product-price', 
        '[itemprop="price"]',
        '.product__price',
        '.current-price',
        'meta[itemprop="price"]'
    ]
    for sel in price_selectors:
        elem = soup.select_one(sel)
        if elem:
            if elem.name == 'meta':
                price_str = elem.get('content', '')
            else:
                price_str = elem.get_text(strip=True)
            price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', ''))
            if price_match:
                try:
                    price = Decimal(price_match.group().replace(',', '.'))
                    break
                except:
                    continue
    
    if not name:
        print("Не удалось найти название товара.")
        return None
    if not price:
        print("Не удалось найти цену товара.")
        return None
    
    return {'name': name, 'price': price}

def scrape_vseinstrumenti_product(url):
    """
    Парсит страницу товара на vseinstrumenti.ru и возвращает словарь с названием и ценой.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Название
    name = None
    name_meta = soup.find('meta', {'itemprop': 'name'})
    if name_meta:
        name = name_meta.get('content', '').strip()
    if not name:
        h1 = soup.find('h1')
        if h1:
            name = h1.get_text(strip=True)
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*[–—-]\s*купить.*$', '', name, flags=re.IGNORECASE)
            name = re.sub(r'^Купить\s+', '', name, flags=re.IGNORECASE)
    
    # Цена
    price = None
    script_tags = soup.find_all('script', type='application/ld+json')
    for script in script_tags:
        try:
            import json
            data = json.loads(script.string)
            if '@graph' in data:
                for item in data['@graph']:
                    if item.get('@type') == 'Product':
                        if 'offers' in item:
                            offer = item['offers']
                            if isinstance(offer, list):
                                offer = offer[0]
                            price_str = offer.get('price')
                            if price_str:
                                price = Decimal(price_str)
                                break
        except:
            continue
        if price:
            break
    
    if price is None:
        price_elem = soup.find(attrs={"data-price": True})
        if price_elem:
            price_str = price_elem['data-price']
            try:
                price = Decimal(price_str)
            except:
                pass
    
    if price is None:
        price_selectors = [
            '.product-price__current',
            '.price__current',
            '.price__value',
            '[itemprop="price"]',
            'meta[itemprop="price"]'
        ]
        for sel in price_selectors:
            elem = soup.select_one(sel)
            if elem:
                if elem.name == 'meta':
                    price_str = elem.get('content', '')
                else:
                    price_str = elem.get_text(strip=True)
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('₽', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("Не удалось найти название товара.")
        return None
    if not price:
        print("Не удалось найти цену товара.")
        return None
    
    return {'name': name, 'price': price}

def scrape_technobearing_product(url):
    """
    Парсит страницу товара на technobearing.ru и возвращает словарь с названием и ценой.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Название товара – обычно в <h1> с классом product-title или аналогичным
    name = None
    h1 = soup.find('h1')
    if h1:
        name = h1.get_text(strip=True)
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*[–—-]\s*купить.*$', '', name, flags=re.IGNORECASE)
    
    # Цена – ищем элемент с классом price или атрибутом data-price
    price = None
    # Попробуем найти через data-price
    price_elem = soup.find(attrs={"data-price": True})
    if price_elem:
        price_str = price_elem['data-price']
        try:
            price = Decimal(price_str)
        except:
            pass
    
    if price is None:
        # Селекторы, типичные для technobearing
        price_selectors = [
            '.price',
            '.product-price',
            '.current-price',
            '.ty-price',
            '[itemprop="price"]',
            'meta[itemprop="price"]'
        ]
        for sel in price_selectors:
            elem = soup.select_one(sel)
            if elem:
                if elem.name == 'meta':
                    price_str = elem.get('content', '')
                else:
                    price_str = elem.get_text(strip=True)
                # Извлекаем число (рубли, возможно с копейками)
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('₽', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("Не удалось найти название товара.")
        return None
    if not price:
        print("Не удалось найти цену товара.")
        return None
    
    return {'name': name, 'price': price}

def scrape_industriation_product(url):
    """
    Парсит страницу товара на industriation.ru и возвращает словарь с названием и ценой.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Название товара
    name = None
    # Пробуем найти h1 с классом, характерным для industriation
    h1 = soup.find('h1', class_=re.compile(r'product|title|name', re.I))
    if not h1:
        h1 = soup.find('h1')
    if h1:
        name = h1.get_text(strip=True)
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*[–—-]\s*купить.*$', '', name, flags=re.IGNORECASE)
    
    # Цена
    price = None
    # Ищем микроразметку Schema.org
    script_tags = soup.find_all('script', type='application/ld+json')
    for script in script_tags:
        try:
            import json
            data = json.loads(script.string)
            if '@graph' in data:
                for item in data['@graph']:
                    if item.get('@type') == 'Product':
                        if 'offers' in item:
                            offer = item['offers']
                            if isinstance(offer, list):
                                offer = offer[0]
                            price_str = offer.get('price')
                            if price_str:
                                price = Decimal(price_str)
                                break
        except:
            continue
        if price:
            break
    
    if price is None:
        # Селекторы для industriation
        price_selectors = [
            '.price',
            '.product-price',
            '.current-price',
            '[itemprop="price"]',
            'meta[itemprop="price"]',
            '.price__value',
            '.product__price'
        ]
        for sel in price_selectors:
            elem = soup.select_one(sel)
            if elem:
                if elem.name == 'meta':
                    price_str = elem.get('content', '')
                else:
                    price_str = elem.get_text(strip=True)
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('₽', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("Не удалось найти название товара.")
        return None
    if not price:
        print("Не удалось найти цену товара.")
        return None
    
    return {'name': name, 'price': price}

def scrape_rtiexpress_product(url):
    """
    Парсит страницу товара на rti-express.ru и возвращает словарь с названием и ценой.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Название товара – обычно в <h1>
    name = None
    h1 = soup.find('h1')
    if h1:
        name = h1.get_text(strip=True)
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*[–—-]\s*.*$', '', name, flags=re.IGNORECASE)
    
    # Цена – ищем в элементе с классом price или по микроразметке
    price = None
    # Пробуем найти микроразметку Product
    script_tags = soup.find_all('script', type='application/ld+json')
    for script in script_tags:
        try:
            import json
            data = json.loads(script.string)
            if '@graph' in data:
                for item in data['@graph']:
                    if item.get('@type') == 'Product':
                        if 'offers' in item:
                            offer = item['offers']
                            if isinstance(offer, list):
                                offer = offer[0]
                            price_str = offer.get('price')
                            if price_str:
                                price = Decimal(price_str)
                                break
        except:
            continue
        if price:
            break
    
    if price is None:
        price_selectors = [
            '.price',
            '.product-price',
            '.current-price',
            '[itemprop="price"]',
            'meta[itemprop="price"]',
            '.ty-price'
        ]
        for sel in price_selectors:
            elem = soup.select_one(sel)
            if elem:
                if elem.name == 'meta':
                    price_str = elem.get('content', '')
                else:
                    price_str = elem.get_text(strip=True)
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('₽', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("Не удалось найти название товара.")
        return None
    if not price:
        print("Не удалось найти цену товара.")
        return None
    
    return {'name': name, 'price': price}

def scrape_krepcom_product(url):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    name = None
    h1 = soup.find('h1')
    if h1:
        name = h1.get_text(strip=True)
    if not name:
        title = soup.find('title')
        if title:
            name = title.get_text(strip=True)
            name = re.sub(r'\s*[–—-]\s*.*$', '', name, flags=re.IGNORECASE)

    price = None
    # пробуем через json+ld
    for script in soup.find_all('script', type='application/ld+json'):
        try:
            import json
            data = json.loads(script.string)
            if '@graph' in data:
                for item in data['@graph']:
                    if item.get('@type') == 'Product' and 'offers' in item:
                        offer = item['offers']
                        if isinstance(offer, list):
                            offer = offer[0]
                        if 'price' in offer:
                            price = Decimal(offer['price'])
                            break
        except:
            continue
    if price is None:
        price_selectors = ['.price', '.product-price', '[itemprop="price"]']
        for sel in price_selectors:
            elem = soup.select_one(sel)
            if elem:
                price_str = elem.get_text(strip=True)
                match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('₽', ''))
                if match:
                    try:
                        price = Decimal(match.group().replace(',', '.'))
                        break
                    except:
                        continue
    if not name or not price:
        return None
    return {'name': name, 'price': price}

def scrape_ozon_product(url):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Название товара — из тега <title> (обрежем лишнее)
    name = None
    title_tag = soup.find('title')
    if title_tag:
        title_text = title_tag.get_text(strip=True)
        # Убираем "OZON", "купить", "цена" и т.п.
        name = re.sub(r'\s*[–—-]\s*OZON.*$', '', title_text, flags=re.IGNORECASE)
        name = re.sub(r'^Купить\s+', '', name, flags=re.IGNORECASE)
        name = name.strip()
    if not name:
        h1 = soup.find('h1')
        if h1:
            name = h1.get_text(strip=True)

    # Цена — пробуем найти в микроразметке JSON-LD
    price = None
    script_tags = soup.find_all('script', type='application/ld+json')
    for script in script_tags:
        try:
            import json
            data = json.loads(script.string)
            if '@graph' in data:
                for item in data['@graph']:
                    if item.get('@type') == 'Product':
                        if 'offers' in item:
                            offer = item['offers']
                            if isinstance(offer, list):
                                offer = offer[0]
                            price_str = offer.get('price')
                            if price_str:
                                price = Decimal(price_str)
                                break
        except:
            continue
        if price:
            break
    
    if price is None:
        # Ищем по селекторам Ozon
        price_selectors = [
            '[data-widget="webPrice"]',
            '.yl5',
            '.v5j',
            '[itemprop="price"]',
            'meta[itemprop="price"]'
        ]
        for sel in price_selectors:
            elem = soup.select_one(sel)
            if elem:
                if elem.name == 'meta':
                    price_str = elem.get('content', '')
                else:
                    price_str = elem.get_text(strip=True)
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('₽', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue

    if not name:
        print("Не удалось найти название товара.")
        return None
    if not price:
        print("Не удалось найти цену товара.")
        return None
    
    return {'name': name, 'price': price}

def scrape_aliexpress_product(url):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    }
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"Ошибка при загрузке страницы: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Название товара — из тега <title>
    name = None
    title_tag = soup.find('title')
    if title_tag:
        title_text = title_tag.get_text(strip=True)
        # Убираем "AliExpress" и лишние слова
        name = re.sub(r'\s*[–—-]\s*AliExpress.*$', '', title_text, flags=re.IGNORECASE)
        name = re.sub(r'^Купить\s+', '', name, flags=re.IGNORECASE)
        name = name.strip()
    if not name:
        h1 = soup.find('h1')
        if h1:
            name = h1.get_text(strip=True)

    # Цена — пробуем найти в микроразметке JSON-LD
    price = None
    script_tags = soup.find_all('script', type='application/ld+json')
    for script in script_tags:
        try:
            import json
            data = json.loads(script.string)
            if '@graph' in data:
                for item in data['@graph']:
                    if item.get('@type') == 'Product':
                        if 'offers' in item:
                            offer = item['offers']
                            if isinstance(offer, list):
                                offer = offer[0]
                            price_str = offer.get('price')
                            if price_str:
                                price = Decimal(price_str)
                                break
        except:
            continue
        if price:
            break
    
    if price is None:
        # Альтернативные селекторы для AliExpress
        price_selectors = [
            '[itemprop="price"]',
            'meta[itemprop="price"]',
            '.product-price-value',
            '.price-current'
        ]
        for sel in price_selectors:
            elem = soup.select_one(sel)
            if elem:
                if elem.name == 'meta':
                    price_str = elem.get('content', '')
                else:
                    price_str = elem.get_text(strip=True)
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('₽', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue

    if not name:
        print("Не удалось найти название товара.")
        return None
    if not price:
        print("Не удалось найти цену товара.")
        return None
    
    return {'name': name, 'price': price}

def quick_add_product(url, quantity=None, purchase_date=None, notes=None):
    """
    Парсит страницу товара, добавляет материал в базу (если его нет) и создаёт закупку.
    Поддерживает vimos.ru, vseinstrumenti.ru, technobearing.ru, industriation.ru
    """
    print(f"\nПарсинг страницы: {url}")
    
    # Определяем, какой парсер использовать
    if 'vimos.ru' in url:
        data = scrape_vimos_product(url)
    elif 'vseinstrumenti.ru' in url:
        data = scrape_vseinstrumenti_product(url)
    elif 'technobearing.ru' in url:
        data = scrape_technobearing_product(url)
    elif 'industriation.ru' in url:
        data = scrape_industriation_product(url)
    elif 'rti-express.ru' in url:
        data = scrape_rtiexpress_product(url)
    elif 'krepcom.ru' in url:
        data = scrape_krepcom_product(url)
    elif 'ozon.ru' in url:
        data = scrape_ozon_product(url)
    elif 'aliexpress.ru' in url:
        data = scrape_aliexpress_product(url)
    else:
        print("Поддерживаются только vimos.ru, vseinstrumenti.ru, technobearing.ru и industriation.ru")
        return
    
    if not data:
        return
    
    name = data['name']
    price = data['price']
    
    print(f"Найдено: {name}")
    print(f"Цена: {price} руб.")
    
    # Запрашиваем количество
    if quantity is None:
        try:
            qty = Decimal(input("Введите количество (шт): "))
        except:
            print("Неверное количество.")
            return
    else:
        qty = quantity
    
    # Дата покупки
    if purchase_date is None:
        date_str = input("Дата покупки (ГГГГ-ММ-ДД, Enter - сегодня): ").strip()
        if date_str:
            from datetime import datetime
            try:
                purchase_date = datetime.strptime(date_str, "%Y-%m-%d").date()
            except:
                print("Неверный формат даты.")
                return
        else:
            purchase_date = None
    
    # Сохраняем в базу
    with get_connection() as conn:
        with conn.cursor() as cur:
            # Добавляем материал, если его нет
            cur.execute("""
                INSERT INTO materials (name, unit)
                VALUES (%s, 'шт')
                ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            """, (name,))
            material_id = cur.fetchone()[0]
            
            # Закупка
            if purchase_date:
                cur.execute("""
                    INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, purchase_date, notes)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (material_id, price, qty, qty, purchase_date, notes))
            else:
                cur.execute("""
                    INSERT INTO purchases (material_id, price_per_unit, quantity, remaining_quantity, notes)
                    VALUES (%s, %s, %s, %s, %s)
                """, (material_id, price, qty, qty, notes))
            
            # Обновляем склад
            cur.execute("""
                INSERT INTO material_inventory (material_id, quantity)
                VALUES (%s, %s)
                ON CONFLICT (material_id) DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
            """, (material_id, qty))
            
            conn.commit()
    
    print(f"Товар '{name}' добавлен в базу. Количество: {qty}, цена: {price} руб.")