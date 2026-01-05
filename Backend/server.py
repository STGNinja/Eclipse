import os
import json
import time
import hashlib
import base64
from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

PORT = int(os.getenv("PORT", 3000))
SERPAPI_KEY = os.getenv("SERPAPI_KEY")

# Simple in-memory cache: { "query_hash": { "data": ..., "timestamp": ... } }
# TTL: 30 minutes
CACHE = {}
CACHE_TTL = 1800 

def get_stable_id(text):
    """Generates a stable ID based on text content."""
    return base64.b64encode(hashlib.sha256(text.encode()).digest()).decode('utf-8')

def normalize_product(item):
    """Normalizes a SerpAPI result into our internal schema."""
    title = item.get("title", "")

    # Link extraction with fallback
    link = item.get("link") or item.get("product_link") or ""

    # If link is empty, generate a Google Shopping search link
    if not link or link.strip() == "":
        from urllib.parse import quote_plus
        encoded_title = quote_plus(title or "product")
        link = f"https://www.google.com/search?tbm=shop&q={encoded_title}"
        print(f"⚠️  Empty link for \"{title}\" - using fallback: {link}")
    else:
        print(f"✅ Valid link for \"{title}\": {link}")

    source = item.get("source") or item.get("merchant", {}).get("name") or "Unknown Merchant"
    
    # Price extraction
    price = 0.0
    currency = "USD"
    
    # SerpAPI often gives extracted_price
    if "extracted_price" in item:
        price = float(item["extracted_price"])
    elif "price" in item:
        # Fallback cleanup "$1,299.00" -> 1299.00
        try:
            clean_price = item["price"].replace("$", "").replace(",", "")
            price = float(clean_price)
        except:
            price = 0.0
            
    # Image
    image_url = item.get("thumbnail")
    
    # Rating / Reviews
    rating = item.get("rating")
    review_count = item.get("reviews")
    
    # Delivery
    delivery = None
    extensions = item.get("extensions", [])
    for ext in extensions:
        if "shipping" in ext.lower():
            delivery = ext
            break
            
    # Generate ID
    product_id = get_stable_id(link + title)
    
    return {
        "id": product_id,
        "title": title,
        "price": price,
        "currency": currency,
        "imageUrl": image_url,
        "link": link,
        "source": "serpapi",
        "merchant": source,
        "rating": rating,
        "reviewCount": review_count,
        "delivery": delivery,
        "original_data": {
            "price_str": item.get("price")
        }
    }

from concurrent.futures import ThreadPoolExecutor

def normalize_amazon_product(item):
    """Normalizes an Amazon result into our internal schema."""
    title = item.get("title", "")

    # Link extraction with fallback
    link = item.get("link") or item.get("product_link") or ""

    # If link is empty, generate a Google Shopping search link
    if not link or link.strip() == "":
        from urllib.parse import quote_plus
        encoded_title = quote_plus(title or "product")
        link = f"https://www.google.com/search?tbm=shop&q={encoded_title}"
        print(f"⚠️  Empty Amazon link for \"{title}\" - using fallback: {link}")
    else:
        print(f"✅ Valid Amazon link for \"{title}\": {link}")

    # Amazon uses 'asin' as ID usually, but we'll stick to our hash for consistency or use ASIN if valid
    merchant = "Amazon"
    
    # Price
    price = 0.0
    currency = "USD"
    if "price" in item:
        price = item["price"].get("value", 0.0)
        currency = item["price"].get("currency", "USD")
    elif "extracted_price" in item:
        price = float(item["extracted_price"])
        
    image_url = item.get("thumbnail")
    rating = item.get("rating")
    review_count = item.get("reviews")
    
    delivery = item.get("delivery")
    
    product_id = get_stable_id(link + title)
    
    return {
        "id": product_id,
        "title": title,
        "price": price,
        "currency": currency,
        "imageUrl": image_url,
        "link": link,
        "source": "amazon",
        "merchant": merchant,
        "rating": rating,
        "reviewCount": review_count,
        "delivery": delivery,
        "original_data": {
            "asin": item.get("asin")
        }
    }

def fetch_search(engine, query, api_key):
    """Helper to fetch from a specific SerpAPI engine."""
    params = {
        "engine": engine,
        "q": query,
        "api_key": api_key,
        "google_domain": "google.com" if engine == "google_shopping" else None,
        "gl": "us",
        "hl": "en",
        "num": 20
    }
    
    # Amazon specific tweaks
    if engine == "amazon":
         params["type"] = "search"
         # Remove google_domain for amazon
         if "google_domain" in params: del params["google_domain"]

    try:
        print(f"[{engine.upper()} FETCH] {query}")
        resp = requests.get("https://serpapi.com/search.json", params=params)
        data = resp.json()
        if "error" in data:
            print(f"❌ {engine} Error: {data['error']}")
            return []
            
        if engine == "google_shopping":
            return [normalize_product(i) for i in data.get("shopping_results", [])]
        elif engine == "amazon":
            return [normalize_amazon_product(i) for i in data.get("organic_results", [])]
            
        return []
    except Exception as e:
        print(f"❌ {engine} Exception: {e}")
        return []

@app.route('/api/shopping', methods=['GET'])
def search_shopping():
    query = request.args.get('q')
    if not query:
        return jsonify({"error": "Query parameter 'q' is required"}), 400
        
    query_lower = query.lower().strip()
    
    # Check Cache
    if query_lower in CACHE:
        cached_item = CACHE[query_lower]
        if time.time() - cached_item["timestamp"] < CACHE_TTL:
            print(f"[CACHE HIT] {query}")
            response = cached_item["data"]
            response["cached"] = True
            return jsonify(response)
        else:
            del CACHE[query_lower] # Expired
            
    if not SERPAPI_KEY:
        print("❌ Error: SERPAPI_KEY missing")
        return jsonify({"error": "Server configuration error: Missing API Key"}), 500
        
    # Parallel Fetch
    products = []
    with ThreadPoolExecutor(max_workers=2) as executor:
        future_google = executor.submit(fetch_search, "google_shopping", query, SERPAPI_KEY)
        future_amazon = executor.submit(fetch_search, "amazon", query, SERPAPI_KEY)
        
        google_results = future_google.result()
        amazon_results = future_amazon.result()
        
        # Interleave results: 2 Google, 1 Amazon, Repeat
        # This gives variety but prioritizes Google Shopping which usually has better images/prices
        g_idx, a_idx = 0, 0
        while g_idx < len(google_results) or a_idx < len(amazon_results):
            # Take 2 from Google
            for _ in range(2):
                if g_idx < len(google_results):
                    products.append(google_results[g_idx])
                    g_idx += 1
            
            # Take 1 from Amazon
            if a_idx < len(amazon_results):
                products.append(amazon_results[a_idx])
                a_idx += 1

    # Final Deduplication & Cleanup
    unique_products = []
    seen_keys = set()
    
    for p in products:
        if p["price"] > 0:
            # Simple dedup key
            key = f"{p['title']}_{p['price']}"
            if key not in seen_keys:
                seen_keys.add(key)
                unique_products.append(p)

    result = {
        "cached": False,
        "total_found": len(unique_products),
        "products": unique_products
    }

    # Log product links for debugging
    print(f"\n📦 Returning {len(unique_products)} products for \"{query}\":")
    for i, p in enumerate(unique_products[:3]):
        print(f"  {i + 1}. \"{p['title'][:50]}...\" - Link: {p['link']}")
    print("")

    # Cache it
    CACHE[query_lower] = {
        "data": result,
        "timestamp": time.time()
    }

    return jsonify(result)

if __name__ == '__main__':
    print(f"Eclipse Backend (Python) running on http://0.0.0.0:{PORT}")
    print(f"- Shopping Endpoint: http://0.0.0.0:{PORT}/api/shopping")
    app.run(host='0.0.0.0', port=PORT)
