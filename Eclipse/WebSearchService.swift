//
//  WebSearchService.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/15/25.
//

import Foundation

class WebSearchService {
    static let shared = WebSearchService()
    
    // Google Custom Search API credentials
    // You'll need to set these up at: https://developers.google.com/custom-search/v1/overview
    private let apiKey = SecretsManager.googleSearchApiKey
    private let searchEngineId = SecretsManager.googleSearchEngineId
    
    private init() {}
    
    /// Performs a Google search and returns formatted results and found image URLs
    func search(query: String) async throws -> (String, [String]) {
        // Advanced Query Refinement
        var refinedQuery = query
        let lowerQuery = query.lowercased()
        
        // Boost relevance for news/current events
        let isTimeSensitive = lowerQuery.contains("latest") || lowerQuery.contains("recent") || 
                            lowerQuery.contains("news") || lowerQuery.contains("today") || 
                            lowerQuery.contains("new") || lowerQuery.contains("2025")
        
        // Remove common filler words to focus search
        let fillers = ["what is", "who is", "tell me about", "look up", "can you", "please"]
        for filler in fillers {
            refinedQuery = refinedQuery.replacingOccurrences(of: filler, with: "", options: [.caseInsensitive, .regularExpression])
        }
        
        let encodedQuery = refinedQuery.trimmingCharacters(in: .whitespaces).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? refinedQuery
        
        var urlString = "https://www.googleapis.com/customsearch/v1?key=\(apiKey)&cx=\(searchEngineId)&q=\(encodedQuery)&num=8"
        
        if isTimeSensitive {
            // Priority for fresh content
            urlString += "&sort=date&dateRestrict=m1" // Past month for current relevance
        }
        
        guard let url = URL(string: urlString) else {
            throw WebSearchError.invalidURL
        }
        
        print("🔍 Refined Google search for: \(refinedQuery)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Search API error: \(httpResponse.statusCode)")
            throw WebSearchError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let searchResults = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
        
        // Format results for AI consumption
        let formattedText = formatResults(searchResults)
        
        // Extract images
        let images = extractImages(searchResults)
        
        return (formattedText, images)
    }
    
    /// Performs a Google search and returns raw items (for programmatic use)
    func searchItems(query: String) async throws -> [SearchItem] {
        let encodedQuery = query.trimmingCharacters(in: .whitespaces).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.googleapis.com/customsearch/v1?key=\(apiKey)&cx=\(searchEngineId)&q=\(encodedQuery)&num=8"
        
        guard let url = URL(string: urlString) else {
            throw WebSearchError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WebSearchError.invalidResponse
        }
        
        let searchResults = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
        return searchResults.items ?? []
    }
    
    /// Formats search results into a readable string for the AI
    private func formatResults(_ response: GoogleSearchResponse) -> String {
        var formattedText = "Web Search Results:\n\n"
        
        guard let items = response.items, !items.isEmpty else {
            return "No results found."
        }
        
        for (index, item) in items.enumerated() {
            formattedText += "<result index=\"\(index + 1)\">\n"
            formattedText += "  <title>\(item.title)</title>\n"
            formattedText += "  <source>\(item.link)</source>\n"
            formattedText += "  <content>\(item.snippet)</content>\n"
            formattedText += "</result>\n\n"
        }
        
        return formattedText
    }
    
    /// Extracts image URLs from search results
    private func extractImages(_ response: GoogleSearchResponse) -> [String] {
        var imageUrls: [String] = []
        
        guard let items = response.items else { return [] }
        
        for item in items {
            if let pagemap = item.pagemap, let cseImages = pagemap.cse_image {
                for image in cseImages {
                    if let src = image.src, src.hasPrefix("http") {
                        imageUrls.append(src)
                        // Limit to top 3 valid images to avoid overwhelming the message
                        if imageUrls.count >= 3 {
                            return imageUrls
                        }
                    }
                }
            }
        }
        
        return imageUrls
    }
    
    /// Determines if a query would benefit from web search
    func shouldPerformWebSearch(for query: String) -> Bool {
        let lowerQuery = query.lowercased()
        
        // Keywords and phrases that suggest web search is needed
        let webSearchKeywords = [
            // Direct search requests
            "search", "google", "look up", "find", "search for",
            
            // Question words (typically indicate need for current info)
            "what is", "what's", "what are", "who is", "who's",
            "when did", "when was", "where is", "where's", "how to",
            "how do", "why is", "why did", "which is", "which are",
            
            // Time-sensitive keywords
            "latest", "recent", "current", "today", "now", "this week",
            "this month", "this year", "new", "updated", "update",
            "right now", "at the moment", "currently", "present",
            
            // News and information
            "news", "report", "announcement", "article", "story",
            "breaking", "headline", "trending",
            
            // Specific requests for information
            "tell me about", "information about", "details about",
            "facts about", "data about", "statistics", "stats",
            "explain", "describe", "definition of",
            
            // Research-oriented
            "research", "study", "findings", "discover", "analysis",
            
            // Specific topics that often need current data
            "weather", "stock", "price", "cost", "market",
            "schedule", "hours", "location", "address", "map",
            "directions", "near me", "nearby",
            
            // Comparison and reviews
            "compare", "review", "rating", "best", "top", "worst",
            "versus", "vs", "difference between", "better than",
            
            // Events and dates
            "when is", "what time", "schedule", "calendar", "event",
            "date of", "happening", "occurred",
            
            // Real-world data that changes
            "live", "score", "result", "outcome", "winner",
            "election", "vote", "poll", "survey",
            
            // Technical/specific queries likely needing web data
            "download", "install", "setup", "tutorial", "guide",
            "documentation", "manual", "instructions",
            
            // Business/commercial
            "buy", "purchase", "shop", "store", "available",
            "in stock", "shipping", "delivery", "order"
        ]
        
        // Check if query contains any of these keywords
        for keyword in webSearchKeywords {
            if lowerQuery.contains(keyword) {
                print("🎯 Web search triggered by keyword: '\(keyword)'")
                return true
            }
        }
        
        // Additional heuristic: Questions about specific things often need web search
        // Examples: "iphone news", "tesla stock", "bitcoin price"
        let queryWords = lowerQuery.components(separatedBy: .whitespaces)
        
        // Check for pattern: [proper noun/brand] + [info word]
        let infoWords = ["news", "price", "stock", "update", "release", "launch", 
                         "specs", "review", "features", "details", "info", "information"]
        for infoWord in infoWords {
            if queryWords.contains(infoWord) {
                print("🎯 Web search triggered by info word: '\(infoWord)'")
                return true
            }
        }
        
        // Check for queries that might need real-time/recent data
        // Pattern: asking about things after 2023 (AI's knowledge cutoff)
        let currentYearIndicators = ["2024", "2025", "this year", "last month"]
        for indicator in currentYearIndicators {
            if lowerQuery.contains(indicator) {
                print("🎯 Web search triggered by temporal indicator: '\(indicator)'")
                return true
            }
        }
        
        // Check for specific question patterns that often need web search
        // "what happened to...", "is ... still...", "did ... announce..."
        let questionPatterns = [
            "what happened", "is there", "has there been", "did anyone",
            "is still", "are still", "was there", "were there",
            "did announce", "has announced", "have announced"
        ]
        for pattern in questionPatterns {
            if lowerQuery.contains(pattern) {
                print("🎯 Web search triggered by question pattern: '\(pattern)'")
                return true
            }
        }
        
        return false
    }
}

// MARK: - Models

struct GoogleSearchResponse: Codable {
    let items: [SearchItem]?
}

struct SearchItem: Codable {
    let title: String
    let link: String
    let snippet: String
    let pagemap: Pagemap?
}

struct Pagemap: Codable {
    let cse_image: [CSEImage]?
    
    enum CodingKeys: String, CodingKey {
        case cse_image = "cse_image"
    }
}

struct CSEImage: Codable {
    let src: String?
}

// MARK: - Errors

enum WebSearchError: Error {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noResults
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .invalidResponse:
            return "Invalid response from search API"
        case .apiError(let code):
            return "Search API error: \(code)"
        case .noResults:
            return "No search results found"
        }
    }
}
