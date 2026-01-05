const express = require('express');
const axios = require('axios');
const cors = require('cors');
const NodeCache = require('node-cache');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Enable CORS/JSON
app.use(cors());
app.use(express.json());

// Cache setup (TTL: 1 minute = 60 seconds)
const searchCache = new NodeCache({ stdTTL: 60 });

// Helper: Normalize SerpAPI Result
const normalizeProduct = (item) => {
    // Basic fields
    const title = item.title;

    // Link extraction with fallback
    let link = item.link || item.product_link || "";

    // If link is still empty, generate a Google Shopping search link
    if (!link || link.trim() === "") {
        const encodedTitle = encodeURIComponent(title || "product");
        link = `https://www.google.com/search?tbm=shop&q=${encodedTitle}`;
        console.log(`⚠️  Empty link for "${title}" - using fallback: ${link}`);
    } else {
        console.log(`✅ Valid link for "${title}": ${link}`);
    }

    const source = item.source || item.merchant?.name || "Unknown Merchant";

    // Price extraction logic
    let price = 0;
    let currency = "USD";

    // SerpAPI usually provides extracted_price, but sometimes just price string
    if (item.extracted_price) {
        price = item.extracted_price;
    } else if (item.price) {
        // Fallback parsing: "$1,299.00" -> 1299.00
        const numericPrice = parseFloat(item.price.replace(/[^0-9.]/g, ''));
        if (!isNaN(numericPrice)) price = numericPrice;
    }

    // Image: Prefer highest quality
    const imageUrl = item.thumbnail;

    // Reviews
    const rating = item.rating;
    const reviewCount = item.reviews;

    // Generate a stable ID
    const id = Buffer.from(link + title).toString('base64');

    // Extract Extensions (often contains shipping info)
    const extensions = item.extensions || [];
    const shipping = extensions.find(e => e.toLowerCase().includes('shipping')) || null;

    return {
        id,
        title,
        price,
        currency,
        imageUrl,
        link,
        source: "serpapi", // Internal marker
        merchant: source,
        rating,
        reviewCount,
        delivery: shipping,
        original_data: {
            price_str: item.price
        }
    };
};

app.get('/api/shopping', async (req, res) => {
    const query = req.query.q;

    if (!query) {
        return res.status(400).json({ error: 'Query parameter "q" is required' });
    }

    const cacheKey = `search_${query.toLowerCase().trim()}`;

    // 1. Check Cache
    const cachedResult = searchCache.get(cacheKey);
    if (cachedResult) {
        console.log(`[CACHE HIT] ${query}`);
        return res.json(cachedResult);
    }

    // 2. Fetch from SerpAPI
    try {
        if (!process.env.SERPAPI_KEY) {
            console.error("SERPAPI_KEY is missing in .env");
            return res.status(500).json({ error: "Server configuration error: Missing API Key" });
        }

        console.log(`[API FETCH] ${query}`);
        const response = await axios.get('https://serpapi.com/search.json', {
            params: {
                engine: "google_shopping",
                q: query,
                api_key: process.env.SERPAPI_KEY,
                google_domain: "google.com",
                gl: "us",
                hl: "en",
                num: 20 // Fetch top 20 to allow for filtering
            }
        });

        if (response.data.error) {
            console.error("SerpAPI Error:", response.data.error);
            return res.status(500).json({ error: response.data.error });
        }

        const rawResults = response.data.shopping_results || [];

        // 3. Normalize & Filter
        const products = rawResults
            .map(normalizeProduct)
            .filter(p => p.price > 0) // Remove invalid prices
            // Simple Deduplication by name/price
            .filter((product, index, self) =>
                index === self.findIndex((p) => (
                    p.title === product.title && p.price === product.price
                ))
            )
            // Sort to prioritize Amazon results
            .sort((a, b) => {
                const aIsAmazon = (a.merchant?.toLowerCase().includes('amazon') || a.link?.toLowerCase().includes('amazon')) ? 1 : 0;
                const bIsAmazon = (b.merchant?.toLowerCase().includes('amazon') || b.link?.toLowerCase().includes('amazon')) ? 1 : 0;
                return bIsAmazon - aIsAmazon; // Amazon first
            });

        const result = {
            cached: false,
            timestamp: new Date().toISOString(),
            total_found: products.length,
            products: products
        };

        // Log product links for debugging
        console.log(`\n📦 Returning ${products.length} products for "${query}":`);
        products.slice(0, 3).forEach((p, i) => {
            console.log(`  ${i + 1}. "${p.title.substring(0, 50)}..." - Link: ${p.link}`);
        });
        console.log('');

        // 4. Store in Cache
        searchCache.set(cacheKey, { ...result, cached: true });

        res.json(result);

    } catch (error) {
        console.error("Search failed:", error.message);
        res.status(500).json({ error: 'Failed to fetch shopping results' });
    }
});

app.listen(port, () => {
    console.log(`Eclipse Backend running on http://localhost:${port}`);
    console.log(`- Shopping Endpoint: http://localhost:${port}/api/shopping`);
});
