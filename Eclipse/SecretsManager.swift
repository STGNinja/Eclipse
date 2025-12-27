//
//  SecretsManager.swift
//  Eclipse
//
//  Created by Antigravity on 12/26/25.
//

import Foundation

class SecretsManager {
    static let shared = SecretsManager()
    
    // Cache for loaded secrets
    private var secrets: [String: String] = [:]
    
    private init() {
        loadSecrets()
    }
    
    private func loadSecrets() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            print("⚠️ SecretsManager: Could not find or parse Secrets.plist")
            return
        }
        self.secrets = dict
    }
    
    // MARK: - Accessors
    
    static var geminiApiKey: String {
        return shared.secrets["GEMINI_API_KEY"] ?? ""
    }
    
    static var googleSearchApiKey: String {
        return shared.secrets["GOOGLE_SEARCH_API_KEY"] ?? ""
    }
    
    static var googleSearchEngineId: String {
        return shared.secrets["GOOGLE_SEARCH_ENGINE_ID"] ?? ""
    }
    
    static var canvaClientId: String {
        return shared.secrets["CANVA_CLIENT_ID"] ?? ""
    }
    
    static var canvaClientSecret: String {
        return shared.secrets["CANVA_CLIENT_SECRET"] ?? ""
    }
}
