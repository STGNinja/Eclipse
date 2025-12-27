//
//  CanvaService.swift
//  Eclipse
//
//  Created by Antigravity on 12/18/25.
//

import Foundation
import UIKit
import CryptoKit

class CanvaService {
    static let shared = CanvaService()
    
    private let clientId = SecretsManager.canvaClientId
    private let clientSecret = SecretsManager.canvaClientSecret
    private let redirectUri = "https://eclipse-2a42b.web.app/canva-auth.html"
    private let baseURL = "https://api.canva.com/rest/v1"
    
    private var accessToken: String?
    
    // MARK: - PKCE Helpers
    
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
    
    // MARK: - OAuth Authentication
    
    func getAuthorizationURL() -> URL? {
        let state = UUID().uuidString
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)
        
        UserDefaults.standard.set(state, forKey: "canva_oauth_state")
        UserDefaults.standard.set(verifier, forKey: "canva_code_verifier")
        
        var components = URLComponents(string: "https://www.canva.com/api/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: "design:content:read design:content:write profile:read"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        
        if let url = components?.url {
            print("🕵️ [Debugger] CanvaService: OAuth URL Generated: \(url.absoluteString)")
        } else {
            print("🕵️ [Debugger] CanvaService: ❌ Failed to generate OAuth URL")
        }
        
        return components?.url
    }
    
    func exchangeCodeForToken(code: String) async throws -> String {
        guard let verifier = UserDefaults.standard.string(forKey: "canva_code_verifier") else {
            print("❌ Service: Missing code verifier")
            throw CanvaError.invalidResponse
        }
        
        let url = URL(string: "https://api.canva.com/rest/v1/oauth/token")!
        print("📡 Service: Starting token exchange...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientId,
            "client_secret": clientSecret,
            "redirect_uri": redirectUri,
            "code_verifier": verifier
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("🕵️ [Debugger] CanvaService: Token exchange HTTP status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                print("❌ Service: Token exchange error body: \(errorBody)")
            }
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        self.accessToken = tokenResponse.access_token
        UserDefaults.standard.set(tokenResponse.access_token, forKey: "canva_access_token")
        
        return tokenResponse.access_token
    }
    
    // MARK: - Design Creation
    
    func createDesign(template: String, title: String, content: String) async throws -> DesignResponse {
        guard let token = accessToken ?? UserDefaults.standard.string(forKey: "canva_access_token") else {
            throw CanvaError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/designs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Note: The API strictly limits presets to: doc, whiteboard, presentation
        // For other types like social media, we should likely use 'presentation' or 'custom' dimensions in a future update.
        // For now, mapping everything to 'presentation' ensures reliability.
        let validPresets = ["doc", "whiteboard", "presentation"]
        let safeTemplate = validPresets.contains(template) ? template : "presentation"
        
        let body: [String: Any] = [
            "design_type": [
                "type": "preset",
                "name": safeTemplate
            ],
            "title": title
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CanvaError.apiError
        }
        
        let designResponse = try JSONDecoder().decode(DesignResponse.self, from: data)
        return designResponse
    }
    
    // MARK: - Template Search
    
    /// Generates a deep link to search for templates on Canva
    /// This mimics the "ChatGPT Plugin" behavior by letting users choose from real templates
    func searchTemplatesURL(query: String, type: String) -> String {
        let encodedQuery = "\(type) \(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return "https://www.canva.com/search/templates?q=\(encodedQuery)"
    }
    
    /// Searches for real templates for a given prompt using Web Search
    /// This retrieves meaningful thumbnails and links, mimicking the standard Canva Search experience
    /// Searches for real templates for a given prompt using Web Search
    /// This retrieves meaningful thumbnails and links, mimicking the standard Canva Search experience
    func findTemplates(from prompt: String) async throws -> [CanvaDesignData] {
        // Construct a targeted query
        // "site:canva.com/templates" ensures we land on template pages
        let searchQuery = "site:canva.com/templates \(prompt) template"
        
        // Get raw items from WebSearchService
        let items = try await WebSearchService.shared.searchItems(query: searchQuery)
        
        // Convert to CanvaDesignData
        return items.prefix(4).map { item in
            // Extract thumbnail from PageMap data
            let thumbnail = item.pagemap?.cse_image?.first?.src
            
            return CanvaDesignData(
                designId: extractDesignId(from: item.link),
                title: item.title.replacingOccurrences(of: " - Canva", with: ""),
                editUrl: item.link, // For templates, the "link" is the view/edit page
                viewUrl: item.link,
                thumbnailUrl: thumbnail
            )
        }
    }
    
    // Helper to extract ID from URL
    private func extractDesignId(from url: String) -> String {
        // URL is typically .../templates/EAF...-title/
        // We extract the EAF... part or just return a UUID if not found
        if let range = url.range(of: "/templates/"), let endRange = url.range(of: "-", range: range.upperBound..<url.endIndex) {
            return String(url[range.upperBound..<endRange.lowerBound])
        }
        return UUID().uuidString
    }
    
    func getDesignEditURL(designId: String) -> String {
        return "https://www.canva.com/design/\(designId)/edit"
    }
    
    // MARK: - User Profile
    
    func getUserProfile() async throws -> UserProfile {
        guard let token = accessToken ?? UserDefaults.standard.string(forKey: "canva_access_token") else {
            throw CanvaError.notAuthenticated
        }
        
        // Note: Actual Canva API endpoint for user profile containing display_name
        let url = URL(string: "\(baseURL)/users/me/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Log error for debug
            if let str = String(data: data, encoding: .utf8) {
                print("❌ Service: Profile fetch error: \(str)")
            }
            throw CanvaError.apiError
        }
        
        let profile = try JSONDecoder().decode(UserProfile.self, from: data)
        if let name = profile.display_name {
            UserDefaults.standard.set(name, forKey: "canva_user_name")
        }
        return profile
    }
    
    func getStoredUserName() -> String? {
        return UserDefaults.standard.string(forKey: "canva_user_name")
    }
    
    // MARK: - Thumbnail Fetching
    
    /// Fetches a fresh thumbnail URL for a design (URLs expire after 15 minutes)
    func getDesignThumbnail(designId: String) async throws -> String? {
        guard let token = accessToken ?? UserDefaults.standard.string(forKey: "canva_access_token") else {
            throw CanvaError.notAuthenticated
        }
        
        let url = URL(string: "\(baseURL)/designs/\(designId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let str = String(data: data, encoding: .utf8) {
                print("❌ Failed to fetch design thumbnail: \(str)")
            }
            throw CanvaError.apiError
        }
        
        let designResponse = try JSONDecoder().decode(DesignResponse.self, from: data)
        return designResponse.design.thumbnail?.url
    }
    
    // MARK: - Helper Methods
    
    func isAuthenticated() -> Bool {
        return UserDefaults.standard.string(forKey: "canva_access_token") != nil
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "canva_access_token")
        UserDefaults.standard.removeObject(forKey: "canva_user_name")
        accessToken = nil
    }
}

// MARK: - Models

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct UserProfile: Codable {
    let display_name: String?
    let id: String?
}

struct DesignResponse: Codable {
    let design: Design
    
    struct Design: Codable {
        let id: String
        let title: String
        let urls: URLs
        let thumbnail: Thumbnail?
        
        struct URLs: Codable {
            let edit_url: String
            let view_url: String
        }
        
        struct Thumbnail: Codable {
            let url: String
            let width: Int
            let height: Int
        }
    }
}

enum CanvaError: Error {
    case notAuthenticated
    case apiError
    case invalidResponse
}
