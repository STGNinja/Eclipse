//
//  ShoppingService.swift
//  Eclipse
//
//  Enhanced with retry logic, health checks, and better error handling
//

import Foundation

// MARK: - Product Model

struct ShoppingProduct: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let price: Double
    let currency: String
    let imageUrl: String?
    let link: String
    let source: String
    let merchant: String?
    let rating: Double?
    let reviewCount: Int?
    let availability: String?
    let shipping: String?
    let discount: Double?
    let originalPrice: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, price, currency, imageUrl, link, source, merchant, rating, reviewCount
        case shipping = "delivery"
        case availability, discount, originalPrice
    }

    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }

    var formattedOriginalPrice: String? {
        guard let originalPrice = originalPrice else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: originalPrice))
    }

    var displaySource: String {
        return merchant ?? source
    }

    var hasDiscount: Bool {
        return discount != nil && discount! > 0
    }

    var discountText: String? {
        guard let discount = discount else { return nil }
        return "-\(Int(discount))%"
    }
}

// MARK: - Cache Model

private struct CachedProducts {
    let products: [ShoppingProduct]
    let timestamp: Date
}

// MARK: - Shopping Service

class ShoppingService {
    static let shared = ShoppingService()

    // Backend configuration
    // TODO: [DEPLOYMENT] Replace this URL with your production URL from Render/Railway
    // e.g., "https://eclipse-backend.onrender.com/api/shopping"
    private let backendUrl = "https://YOUR_APP_NAME.onrender.com/api/shopping" 

    // Cache with expiration
    private var memoryCache: [String: CachedProducts] = [:]
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    // Connection health tracking
    private var lastSuccessfulConnection: Date?
    private var consecutiveFailures = 0

    private init() {
        // Test connection on init
        Task {
            await checkBackendHealth()
        }
    }

    /// Check if backend is reachable
    private func checkBackendHealth() async {
        print("🏥 [ShoppingService] Checking backend health...")
        do {
            guard let url = URL(string: backendUrl.replacingOccurrences(of: "/api/shopping", with: "/health")) else { return }

            var request = URLRequest(url: url)
            request.timeoutInterval = 3

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ [ShoppingService] Backend is healthy")
                lastSuccessfulConnection = Date()
                consecutiveFailures = 0
            }
        } catch {
            print("⚠️ [ShoppingService] Backend health check failed: \(error.localizedDescription)")
            print("   Make sure the backend is running on: \(backendUrl)")
            consecutiveFailures += 1
        }
    }

    /// Performs a shopping-focused search via the Eclipse Backend
    func searchProducts(query: String) async throws -> [ShoppingProduct] {
        print("🛒 [ShoppingService] Searching for: '\(query)'")

        // Check memory cache first
        if let cached = memoryCache[query] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheExpirationSeconds {
                print("💾 [ShoppingService] Using cached results (age: \(Int(age))s)")
                return cached.products
            } else {
                print("🗑️ [ShoppingService] Cache expired, fetching fresh data")
            }
        }

        // Try with retries
        let maxRetries = 2
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                let products = try await performSearch(query: query)

                // Success! Reset failure counter
                consecutiveFailures = 0
                lastSuccessfulConnection = Date()

                // Cache the results
                memoryCache[query] = CachedProducts(products: products, timestamp: Date())

                // Clean old cache entries
                cleanCache()

                return products

            } catch let error as URLError {
                lastError = error
                print("⚠️ [ShoppingService] Attempt \(attempt + 1)/\(maxRetries) failed: \(error.localizedDescription)")

                if error.code == .timedOut || error.code == .cannotConnectToHost {
                    consecutiveFailures += 1

                    if consecutiveFailures >= 3 {
                        print("❌ [ShoppingService] Multiple consecutive failures. Backend may be down.")
                        print("   Please check:")
                        print("   1. Backend is running: cd Backend && node server.js")
                        print("   2. Correct IP address: \(backendUrl)")
                        print("   3. Firewall allows connections on port 3000")
                    }

                    // Wait before retry
                    if attempt < maxRetries - 1 {
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    }
                } else {
                    throw error // Don't retry on other errors
                }
            } catch {
                lastError = error
                print("❌ [ShoppingService] Non-recoverable error: \(error)")
                throw error
            }
        }

        // All retries failed
        throw lastError ?? NSError(domain: "ShoppingService", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Failed to connect to shopping backend after \(maxRetries) attempts. Make sure the backend server is running."
        ])
    }

    private func performSearch(query: String) async throws -> [ShoppingProduct] {
        // Build URL
        guard let url = URL(string: backendUrl) else {
            throw URLError(.badURL)
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]

        guard let finalUrl = components.url else {
            throw URLError(.badURL)
        }

        print("🌐 [ShoppingService] GET \(finalUrl.absoluteString)")

        var request = URLRequest(url: finalUrl)
        request.timeoutInterval = 15 // Increased timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData

        // Call Backend
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        print("📡 [ShoppingService] Response: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorJson = try? JSONDecoder().decode(BackendErrorResponse.self, from: data) {
                print("❌ [ShoppingService] Backend error: \(errorJson.error)")
                throw NSError(domain: "ShoppingService", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorJson.error
                ])
            }
            throw URLError(.badServerResponse)
        }

        // Parse Response
        let backendResponse = try JSONDecoder().decode(ShoppingBackendResponse.self, from: data)
        print("✅ [ShoppingService] Received \(backendResponse.products.count) products (cached: \(backendResponse.cached))")

        return backendResponse.products
    }

    private func cleanCache() {
        let now = Date()
        memoryCache = memoryCache.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) < cacheExpirationSeconds
        }
    }
}

// MARK: - Backend Response Models

struct ShoppingBackendResponse: Codable {
    let cached: Bool
    let total_found: Int
    let products: [ShoppingProduct]
}

struct BackendErrorResponse: Codable {
    let error: String
}
