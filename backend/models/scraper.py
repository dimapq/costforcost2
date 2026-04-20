# models/scraper.py
import requests
from bs4 import BeautifulSoup
from decimal import Decimal
import re
from backend.db.connection import get_connection

def scrape_vimos_product(url):
    """
    РџР°СЂСЃРёС‚ СЃС‚СЂР°РЅРёС†Сѓ С‚РѕРІР°СЂР° РЅР° vimos.ru Рё РІРѕР·РІСЂР°С‰Р°РµС‚ СЃР»РѕРІР°СЂСЊ СЃ РЅР°Р·РІР°РЅРёРµРј Рё С†РµРЅРѕР№.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
    except Exception as e:
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # 1. РќР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°
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
            name = re.sub(r'\s*РєСѓРїРёС‚СЊ.*$', '', name, flags=re.IGNORECASE)
    
    # 2. Р¦РµРЅР°
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
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°.")
        return None
    if not price:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё С†РµРЅСѓ С‚РѕРІР°СЂР°.")
        return None
    
    return {'name': name, 'price': price}

def scrape_vseinstrumenti_product(url):
    """
    РџР°СЂСЃРёС‚ СЃС‚СЂР°РЅРёС†Сѓ С‚РѕРІР°СЂР° РЅР° vseinstrumenti.ru Рё РІРѕР·РІСЂР°С‰Р°РµС‚ СЃР»РѕРІР°СЂСЊ СЃ РЅР°Р·РІР°РЅРёРµРј Рё С†РµРЅРѕР№.
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
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # РќР°Р·РІР°РЅРёРµ
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
            name = re.sub(r'\s*[вЂ“вЂ”-]\s*РєСѓРїРёС‚СЊ.*$', '', name, flags=re.IGNORECASE)
            name = re.sub(r'^РљСѓРїРёС‚СЊ\s+', '', name, flags=re.IGNORECASE)
    
    # Р¦РµРЅР°
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
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('в‚Ѕ', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°.")
        return None
    if not price:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё С†РµРЅСѓ С‚РѕРІР°СЂР°.")
        return None
    
    return {'name': name, 'price': price}

def scrape_technobearing_product(url):
    """
    РџР°СЂСЃРёС‚ СЃС‚СЂР°РЅРёС†Сѓ С‚РѕРІР°СЂР° РЅР° technobearing.ru Рё РІРѕР·РІСЂР°С‰Р°РµС‚ СЃР»РѕРІР°СЂСЊ СЃ РЅР°Р·РІР°РЅРёРµРј Рё С†РµРЅРѕР№.
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
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # РќР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР° вЂ“ РѕР±С‹С‡РЅРѕ РІ <h1> СЃ РєР»Р°СЃСЃРѕРј product-title РёР»Рё Р°РЅР°Р»РѕРіРёС‡РЅС‹Рј
    name = None
    h1 = soup.find('h1')
    if h1:
        name = h1.get_text(strip=True)
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*[вЂ“вЂ”-]\s*РєСѓРїРёС‚СЊ.*$', '', name, flags=re.IGNORECASE)
    
    # Р¦РµРЅР° вЂ“ РёС‰РµРј СЌР»РµРјРµРЅС‚ СЃ РєР»Р°СЃСЃРѕРј price РёР»Рё Р°С‚СЂРёР±СѓС‚РѕРј data-price
    price = None
    # РџРѕРїСЂРѕР±СѓРµРј РЅР°Р№С‚Рё С‡РµСЂРµР· data-price
    price_elem = soup.find(attrs={"data-price": True})
    if price_elem:
        price_str = price_elem['data-price']
        try:
            price = Decimal(price_str)
        except:
            pass
    
    if price is None:
        # РЎРµР»РµРєС‚РѕСЂС‹, С‚РёРїРёС‡РЅС‹Рµ РґР»СЏ technobearing
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
                # РР·РІР»РµРєР°РµРј С‡РёСЃР»Рѕ (СЂСѓР±Р»Рё, РІРѕР·РјРѕР¶РЅРѕ СЃ РєРѕРїРµР№РєР°РјРё)
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('в‚Ѕ', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°.")
        return None
    if not price:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё С†РµРЅСѓ С‚РѕРІР°СЂР°.")
        return None
    
    return {'name': name, 'price': price}

def scrape_industriation_product(url):
    """
    РџР°СЂСЃРёС‚ СЃС‚СЂР°РЅРёС†Сѓ С‚РѕРІР°СЂР° РЅР° industriation.ru Рё РІРѕР·РІСЂР°С‰Р°РµС‚ СЃР»РѕРІР°СЂСЊ СЃ РЅР°Р·РІР°РЅРёРµРј Рё С†РµРЅРѕР№.
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
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # РќР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°
    name = None
    # РџСЂРѕР±СѓРµРј РЅР°Р№С‚Рё h1 СЃ РєР»Р°СЃСЃРѕРј, С…Р°СЂР°РєС‚РµСЂРЅС‹Рј РґР»СЏ industriation
    h1 = soup.find('h1', class_=re.compile(r'product|title|name', re.I))
    if not h1:
        h1 = soup.find('h1')
    if h1:
        name = h1.get_text(strip=True)
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*[вЂ“вЂ”-]\s*РєСѓРїРёС‚СЊ.*$', '', name, flags=re.IGNORECASE)
    
    # Р¦РµРЅР°
    price = None
    # РС‰РµРј РјРёРєСЂРѕСЂР°Р·РјРµС‚РєСѓ Schema.org
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
        # РЎРµР»РµРєС‚РѕСЂС‹ РґР»СЏ industriation
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
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('в‚Ѕ', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°.")
        return None
    if not price:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё С†РµРЅСѓ С‚РѕРІР°СЂР°.")
        return None
    
    return {'name': name, 'price': price}

def scrape_rtiexpress_product(url):
    """
    РџР°СЂСЃРёС‚ СЃС‚СЂР°РЅРёС†Сѓ С‚РѕРІР°СЂР° РЅР° rti-express.ru Рё РІРѕР·РІСЂР°С‰Р°РµС‚ СЃР»РѕРІР°СЂСЊ СЃ РЅР°Р·РІР°РЅРёРµРј Рё С†РµРЅРѕР№.
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
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # РќР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР° вЂ“ РѕР±С‹С‡РЅРѕ РІ <h1>
    name = None
    h1 = soup.find('h1')
    if h1:
        name = h1.get_text(strip=True)
    if not name:
        title_tag = soup.find('title')
        if title_tag:
            name = title_tag.get_text(strip=True)
            name = re.sub(r'\s*[вЂ“вЂ”-]\s*.*$', '', name, flags=re.IGNORECASE)
    
    # Р¦РµРЅР° вЂ“ РёС‰РµРј РІ СЌР»РµРјРµРЅС‚Рµ СЃ РєР»Р°СЃСЃРѕРј price РёР»Рё РїРѕ РјРёРєСЂРѕСЂР°Р·РјРµС‚РєРµ
    price = None
    # РџСЂРѕР±СѓРµРј РЅР°Р№С‚Рё РјРёРєСЂРѕСЂР°Р·РјРµС‚РєСѓ Product
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
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('в‚Ѕ', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue
    
    if not name:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°.")
        return None
    if not price:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё С†РµРЅСѓ С‚РѕРІР°СЂР°.")
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
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
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
            name = re.sub(r'\s*[вЂ“вЂ”-]\s*.*$', '', name, flags=re.IGNORECASE)

    price = None
    # РїСЂРѕР±СѓРµРј С‡РµСЂРµР· json+ld
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
                match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('в‚Ѕ', ''))
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
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # РќР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР° вЂ” РёР· С‚РµРіР° <title> (РѕР±СЂРµР¶РµРј Р»РёС€РЅРµРµ)
    name = None
    title_tag = soup.find('title')
    if title_tag:
        title_text = title_tag.get_text(strip=True)
        # РЈР±РёСЂР°РµРј "OZON", "РєСѓРїРёС‚СЊ", "С†РµРЅР°" Рё С‚.Рї.
        name = re.sub(r'\s*[вЂ“вЂ”-]\s*OZON.*$', '', title_text, flags=re.IGNORECASE)
        name = re.sub(r'^РљСѓРїРёС‚СЊ\s+', '', name, flags=re.IGNORECASE)
        name = name.strip()
    if not name:
        h1 = soup.find('h1')
        if h1:
            name = h1.get_text(strip=True)

    # Р¦РµРЅР° вЂ” РїСЂРѕР±СѓРµРј РЅР°Р№С‚Рё РІ РјРёРєСЂРѕСЂР°Р·РјРµС‚РєРµ JSON-LD
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
        # РС‰РµРј РїРѕ СЃРµР»РµРєС‚РѕСЂР°Рј Ozon
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
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('в‚Ѕ', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue

    if not name:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°.")
        return None
    if not price:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё С†РµРЅСѓ С‚РѕРІР°СЂР°.")
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
        print(f"РћС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ СЃС‚СЂР°РЅРёС†С‹: {e}")
        return None

    soup = BeautifulSoup(response.text, 'html.parser')
    
    # РќР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР° вЂ” РёР· С‚РµРіР° <title>
    name = None
    title_tag = soup.find('title')
    if title_tag:
        title_text = title_tag.get_text(strip=True)
        # РЈР±РёСЂР°РµРј "AliExpress" Рё Р»РёС€РЅРёРµ СЃР»РѕРІР°
        name = re.sub(r'\s*[вЂ“вЂ”-]\s*AliExpress.*$', '', title_text, flags=re.IGNORECASE)
        name = re.sub(r'^РљСѓРїРёС‚СЊ\s+', '', name, flags=re.IGNORECASE)
        name = name.strip()
    if not name:
        h1 = soup.find('h1')
        if h1:
            name = h1.get_text(strip=True)

    # Р¦РµРЅР° вЂ” РїСЂРѕР±СѓРµРј РЅР°Р№С‚Рё РІ РјРёРєСЂРѕСЂР°Р·РјРµС‚РєРµ JSON-LD
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
        # РђР»СЊС‚РµСЂРЅР°С‚РёРІРЅС‹Рµ СЃРµР»РµРєС‚РѕСЂС‹ РґР»СЏ AliExpress
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
                price_match = re.search(r'[\d\s]+[.,]?\d*', price_str.replace(' ', '').replace('в‚Ѕ', ''))
                if price_match:
                    try:
                        price = Decimal(price_match.group().replace(',', '.'))
                        break
                    except:
                        continue

    if not name:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё РЅР°Р·РІР°РЅРёРµ С‚РѕРІР°СЂР°.")
        return None
    if not price:
        print("РќРµ СѓРґР°Р»РѕСЃСЊ РЅР°Р№С‚Рё С†РµРЅСѓ С‚РѕРІР°СЂР°.")
        return None
    
    return {'name': name, 'price': price}

def quick_add_product(url, quantity=None, purchase_date=None, notes=None):
    """
    РџР°СЂСЃРёС‚ СЃС‚СЂР°РЅРёС†Сѓ С‚РѕРІР°СЂР°, РґРѕР±Р°РІР»СЏРµС‚ РјР°С‚РµСЂРёР°Р» РІ Р±Р°Р·Сѓ (РµСЃР»Рё РµРіРѕ РЅРµС‚) Рё СЃРѕР·РґР°С‘С‚ Р·Р°РєСѓРїРєСѓ.
    РџРѕРґРґРµСЂР¶РёРІР°РµС‚ vimos.ru, vseinstrumenti.ru, technobearing.ru, industriation.ru
    """
    print(f"\nРџР°СЂСЃРёРЅРі СЃС‚СЂР°РЅРёС†С‹: {url}")
    
    # РћРїСЂРµРґРµР»СЏРµРј, РєР°РєРѕР№ РїР°СЂСЃРµСЂ РёСЃРїРѕР»СЊР·РѕРІР°С‚СЊ
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
        print("РџРѕРґРґРµСЂР¶РёРІР°СЋС‚СЃСЏ С‚РѕР»СЊРєРѕ vimos.ru, vseinstrumenti.ru, technobearing.ru Рё industriation.ru")
        return
    
    if not data:
        return
    
    name = data['name']
    price = data['price']
    
    print(f"РќР°Р№РґРµРЅРѕ: {name}")
    print(f"Р¦РµРЅР°: {price} СЂСѓР±.")
    
    # Р—Р°РїСЂР°С€РёРІР°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ
    if quantity is None:
        try:
            qty = Decimal(input("Р’РІРµРґРёС‚Рµ РєРѕР»РёС‡РµСЃС‚РІРѕ (С€С‚): "))
        except:
            print("РќРµРІРµСЂРЅРѕРµ РєРѕР»РёС‡РµСЃС‚РІРѕ.")
            return
    else:
        qty = quantity
    
    # Р”Р°С‚Р° РїРѕРєСѓРїРєРё
    if purchase_date is None:
        date_str = input("Р”Р°С‚Р° РїРѕРєСѓРїРєРё (Р“Р“Р“Р“-РњРњ-Р”Р”, Enter - СЃРµРіРѕРґРЅСЏ): ").strip()
        if date_str:
            from datetime import datetime
            try:
                purchase_date = datetime.strptime(date_str, "%Y-%m-%d").date()
            except:
                print("РќРµРІРµСЂРЅС‹Р№ С„РѕСЂРјР°С‚ РґР°С‚С‹.")
                return
        else:
            purchase_date = None
    
    # РЎРѕС…СЂР°РЅСЏРµРј РІ Р±Р°Р·Сѓ
    with get_connection() as conn:
        with conn.cursor() as cur:
            # Р”РѕР±Р°РІР»СЏРµРј РјР°С‚РµСЂРёР°Р», РµСЃР»Рё РµРіРѕ РЅРµС‚
            cur.execute("""
                INSERT INTO materials (name, unit)
                VALUES (%s, 'С€С‚')
                ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
                RETURNING id
            """, (name,))
            material_id = cur.fetchone()[0]
            
            # Р—Р°РєСѓРїРєР°
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
            
            # РћР±РЅРѕРІР»СЏРµРј СЃРєР»Р°Рґ
            cur.execute("""
                INSERT INTO material_inventory (material_id, quantity)
                VALUES (%s, %s)
                ON CONFLICT (material_id) DO UPDATE SET quantity = material_inventory.quantity + EXCLUDED.quantity
            """, (material_id, qty))
            
            conn.commit()
    
    print(f"РўРѕРІР°СЂ '{name}' РґРѕР±Р°РІР»РµРЅ РІ Р±Р°Р·Сѓ. РљРѕР»РёС‡РµСЃС‚РІРѕ: {qty}, С†РµРЅР°: {price} СЂСѓР±.")
