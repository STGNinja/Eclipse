//
//  HybridAIRouter.swift
//  Eclipse
//
//  Created by Hybrid AI System on 12/17/25.
//

import Foundation
import UIKit
import Combine
internal import EventKit

/// Intelligent routing system that decides whether to use Apple Intelligence or Google Gemini
@MainActor
class HybridAIRouter: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = HybridAIRouter()
    
    // MARK: - Services
    
    private let appleService = AppleIntelligenceService.shared
    private let geminiService = GeminiService()
    
    // MARK: - Published Properties
    
    @Published var currentAI: AIProvider = .automatic
    @Published var lastUsedProvider: AIProvider?
    
    // MARK: - User Preferences (from UserDefaults/AppStorage)
    
    var privacyMode: Bool {
        get { UserDefaults.standard.bool(forKey: "privacyModeEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "privacyModeEnabled") }
    }
    
    var aiPreference: AIPreference {
        get {
            let rawValue = UserDefaults.standard.string(forKey: "aiPreference") ?? "automatic"
            return AIPreference(rawValue: rawValue) ?? .automatic
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "aiPreference")
        }
    }
    
    var isOffline: Bool {
        // Simple reachability check
        // In production, you'd use NWPathMonitor for better accuracy
        return false // Placeholder
    }
    
    // MARK: - Initialization
    
    private init() {
        // Check Apple Intelligence availability on init
        appleService.checkAvailability()
    }
    
    // MARK: - Main Routing Methods
    
    /// Send a text message and get a streaming response
    func chat(
        message: String,
        conversationHistory: [Message] = [],
        userName: String? = nil,
        selectedImage: UIImage? = nil
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                do {
                    // Determine which AI to use
                    let provider = self.determineProvider(
                        for: message,
                        hasImage: selectedImage != nil,
                        conversationHistory: conversationHistory
                    )
                    
                    self.lastUsedProvider = provider
                    
                    print("🤖 Using \(provider.displayName) for query")
                    
                    // Route to appropriate service
                    switch provider {
                    case .appleIntelligence:
                        let personalContext = await self.getPersonalContext()
                        
                        for try await chunk in self.appleService.generateStream(
                            prompt: message,
                            conversationHistory: conversationHistory,
                            userName: userName,
                            personalContext: personalContext
                        ) {
                            continuation.yield(chunk)
                        }
                        
                    case .gemini:
                        for try await chunk in self.geminiService.sendMessageStream(
                            message,
                            conversationHistory: conversationHistory,
                            userName: userName
                        ) {
                            continuation.yield(chunk)
                        }
                        
                    case .automatic:
                        // This shouldn't happen, but fallback to Gemini
                        for try await chunk in self.geminiService.sendMessageStream(
                            message,
                            conversationHistory: conversationHistory,
                            userName: userName
                        ) {
                            continuation.yield(chunk)
                        }
                    }
                    
                    continuation.finish()
                    
                } catch {
                    print("❌ Router error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Analyze an image with a prompt
    func analyzeImage(
        _ image: UIImage,
        prompt: String,
        conversationHistory: [Message] = []
    ) -> AsyncThrowingStream<String, Error> {
        // Image analysis always uses Gemini (Apple Intelligence doesn't support it yet)
        return geminiService.analyzeImageStream(image, prompt: prompt, conversationHistory: conversationHistory)
    }
    
    /// Generate an image from a prompt
    func generateImage(prompt: String) async throws -> [Data] {
        // Image generation always uses Gemini
        // Apple Intelligence's Image Playground API isn't available yet
        lastUsedProvider = .gemini
        return try await geminiService.generateImage(prompt: prompt, numberOfImages: 1)
    }
    
    /// Generate a chat title
    func generateChatTitle(from messages: [Message]) async throws -> String {
        // Use Apple Intelligence if available for cost savings
        if appleService.isAvailable && !privacyMode {
            lastUsedProvider = .appleIntelligence
            return try await appleService.generateChatTitle(from: messages)
        } else {
            lastUsedProvider = .gemini
            return try await geminiService.generateChatTitle(from: messages)
        }
    }
    
    // MARK: - Provider Determination Logic
    
    /// Determines which AI provider to use based on query characteristics and user preferences
    private func determineProvider(
        for query: String,
        hasImage: Bool,
        conversationHistory: [Message]
    ) -> AIProvider {
        
        // 1. Check user preference first
        switch aiPreference {
        case .appleIntelligence:
            // User wants Apple Intelligence only
            if appleService.isAvailable && !hasImage {
                return .appleIntelligence
            } else {
                // Fallback to Gemini if Apple Intelligence can't handle it
                print("⚠️ Apple Intelligence preferred but not available for this request, using Gemini")
                return .gemini
            }
            
        case .gemini:
            // User wants Gemini only
            return .gemini
            
        case .automatic:
            // Smart routing
            break
        }
        
        // 2. Privacy Mode: Always use Apple Intelligence if available
        if privacyMode {
            if appleService.isAvailable && !hasImage {
                return .appleIntelligence
            } else {
                print("⚠️ Privacy mode enabled but Apple Intelligence unavailable, using Gemini")
                return .gemini
            }
        }
        
        // 3. Image handling: Must use Gemini
        if hasImage {
            return .gemini
        }
        
        // 4. Offline mode: Must use Apple Intelligence
        if isOffline {
            if appleService.isAvailable {
                return .appleIntelligence
            } else {
                print("⚠️ Offline but Apple Intelligence unavailable")
                return .gemini // Will fail, but let it try
            }
        }
        
        // 5. Check if Apple Intelligence is available
        guard appleService.isAvailable else {
            return .gemini
        }
        
        // 6. Analyze query characteristics
        let queryAnalysis = analyzeQuery(query)
        
        // 7. Decision tree based on query characteristics
        
        // Complex queries -> Gemini
        if queryAnalysis.isComplex {
            return .gemini
        }
        
        // Web search required -> Gemini
        if queryAnalysis.needsWebSearch {
            return .gemini
        }
        
        // Sensitive information -> Apple Intelligence
        if queryAnalysis.containsSensitiveInfo {
            return .appleIntelligence
        }
        
        // Simple queries -> Apple Intelligence (free, fast)
        if queryAnalysis.isSimple {
            return .appleIntelligence
        }
        
        // Very long queries -> Gemini (larger context window)
        if queryAnalysis.isVeryLong {
            return .gemini
        }
        
        // Technical/specialized -> Gemini
        if queryAnalysis.isTechnical {
            return .gemini
        }
        
        // Text editing/rewriting -> Apple Intelligence
        if queryAnalysis.isTextEditing {
            return .appleIntelligence
        }
        
        // Default: Prefer Apple Intelligence for cost savings
        return .appleIntelligence
    }
    
    /// Analyzes query to determine its characteristics
    private func analyzeQuery(_ query: String) -> QueryAnalysis {
        let lowerQuery = query.lowercased()
        let wordCount = query.split(separator: " ").count
        
        // Simple query indicators
        let isSimple = wordCount < 20 && (
            lowerQuery.hasPrefix("what is") ||
            lowerQuery.hasPrefix("who is") ||
            lowerQuery.hasPrefix("when is") ||
            lowerQuery.hasPrefix("where is") ||
            lowerQuery.hasPrefix("how to") ||
            lowerQuery.contains("define") ||
            lowerQuery.contains("explain")
        )
        
        // Complex query indicators
        let isComplex = wordCount > 50 || (
            lowerQuery.contains("explain in detail") ||
            lowerQuery.contains("compare") ||
            lowerQuery.contains("analyze") ||
            lowerQuery.contains("evaluate") ||
            lowerQuery.contains("discuss") ||
            lowerQuery.contains("argue") ||
            lowerQuery.contains("consider multiple")
        )
        
        // Web search indicators
        let needsWebSearch = (
            lowerQuery.contains("latest") ||
            lowerQuery.contains("current") ||
            lowerQuery.contains("recent") ||
            lowerQuery.contains("today") ||
            lowerQuery.contains("news") ||
            lowerQuery.contains("weather") ||
            lowerQuery.contains("stock") ||
            lowerQuery.contains("search") ||
            lowerQuery.contains("find information")
        )
        
        // Sensitive information indicators
        let containsSensitiveInfo = (
            lowerQuery.contains("password") ||
            lowerQuery.contains("private") ||
            lowerQuery.contains("personal") ||
            lowerQuery.contains("health") ||
            lowerQuery.contains("medical") ||
            lowerQuery.contains("financial") ||
            lowerQuery.contains("bank") ||
            lowerQuery.contains("credit card") ||
            lowerQuery.contains("ssn") ||
            lowerQuery.contains("confidential")
        )
        
        // Technical indicators
        let isTechnical = (
            lowerQuery.contains("code") ||
            lowerQuery.contains("programming") ||
            lowerQuery.contains("algorithm") ||
            lowerQuery.contains("quantum") ||
            lowerQuery.contains("machine learning") ||
            lowerQuery.contains("neural network") ||
            lowerQuery.contains("api") ||
            lowerQuery.contains("database")
        )
        
        // Text editing indicators
        let isTextEditing = (
            lowerQuery.hasPrefix("rewrite") ||
            lowerQuery.hasPrefix("rephrase") ||
            lowerQuery.hasPrefix("improve") ||
            lowerQuery.hasPrefix("edit") ||
            lowerQuery.hasPrefix("fix") ||
            lowerQuery.contains("make it") ||
            lowerQuery.contains("change the tone")
        )
        
        // Very long query
        let isVeryLong = wordCount > 100
        
        return QueryAnalysis(
            isSimple: isSimple,
            isComplex: isComplex,
            needsWebSearch: needsWebSearch,
            containsSensitiveInfo: containsSensitiveInfo,
            isTechnical: isTechnical,
            isTextEditing: isTextEditing,
            isVeryLong: isVeryLong,
            wordCount: wordCount
        )
    }
    
    // MARK: - Personal Context Gathering
    
    /// Gathers personal context for Apple Intelligence
    private func getPersonalContext() async -> PersonalContext {
        var context = PersonalContext()
        
        // Get calendar events if enabled
        if UserDefaults.standard.bool(forKey: "isCalendarEnabled") {
            let events = CalendarManager.shared.getUpcomingEvents()
            context.calendarEvents = events.map { 
                "\($0.title ?? "Event"): \($0.startDate.formatted())" 
            }
        }
        
        // Get user artifacts/preferences
        let artifactsContext = await ArtifactsManager.shared.getArtifactsContext()
        if !artifactsContext.isEmpty {
            context.customContext = artifactsContext
        }
        
        return context
    }
    
    // MARK: - Utility Methods
    
    /// Check if a query should use image generation
    func isImageGenerationRequest(_ query: String) -> Bool {
        let lowerQuery = query.lowercased()
        let imageTriggers = [
            "generate image", "create image", "make an image", 
            "draw", "/image", "generate an image", "create an image",
            "picture of", "show me", "visualize"
        ]
        return imageTriggers.contains(where: { lowerQuery.hasPrefix($0) || lowerQuery.contains($0) })
    }
    
    /// Get current provider info for display
    func getCurrentProviderInfo() -> String {
        if let provider = lastUsedProvider {
            return "Using \(provider.displayName)"
        }
        return "Ready"
    }
    
    /// Get cost savings estimate
    func getCostSavingsInfo() async -> CostSavings {
        // This is a simplified calculation
        // In production, you'd track actual usage
        let totalQueries = 100 // Placeholder
        let appleQueries = 70 // Placeholder
        let costPerGeminiQuery = 0.001 // $0.001 per query (example)
        
        let savedMoney = Double(appleQueries) * costPerGeminiQuery
        let savingsPercent = (Double(appleQueries) / Double(totalQueries)) * 100
        
        return CostSavings(
            totalQueries: totalQueries,
            appleIntelligenceQueries: appleQueries,
            geminiQueries: totalQueries - appleQueries,
            estimatedSavings: savedMoney,
            savingsPercent: savingsPercent
        )
    }
}

// MARK: - Supporting Types

/// AI Provider options
enum AIProvider {
    case appleIntelligence
    case gemini
    case automatic
    
    var displayName: String {
        switch self {
        case .appleIntelligence:
            return "Apple Intelligence"
        case .gemini:
            return "Google Gemini"
        case .automatic:
            return "Automatic"
        }
    }
    
    var icon: String {
        switch self {
        case .appleIntelligence:
            return "apple.logo"
        case .gemini:
            return "sparkles"
        case .automatic:
            return "wand.and.stars"
        }
    }
}

/// User preference for AI selection
enum AIPreference: String, CaseIterable {
    case automatic = "automatic"
    case appleIntelligence = "apple"
    case gemini = "gemini"
    
    var displayName: String {
        switch self {
        case .automatic:
            return "Automatic (Recommended)"
        case .appleIntelligence:
            return "Privacy First (Apple Intelligence)"
        case .gemini:
            return "Performance First (Google Gemini)"
        }
    }
    
    var description: String {
        switch self {
        case .automatic:
            return "Smart routing based on query type. Uses Apple Intelligence when possible for privacy and cost savings."
        case .appleIntelligence:
            return "Always use on-device Apple Intelligence. Falls back to Gemini only when necessary."
        case .gemini:
            return "Always use Google Gemini for maximum capabilities and advanced features."
        }
    }
}

/// Query analysis result
struct QueryAnalysis {
    let isSimple: Bool
    let isComplex: Bool
    let needsWebSearch: Bool
    let containsSensitiveInfo: Bool
    let isTechnical: Bool
    let isTextEditing: Bool
    let isVeryLong: Bool
    let wordCount: Int
}

/// Cost savings information
struct CostSavings {
    let totalQueries: Int
    let appleIntelligenceQueries: Int
    let geminiQueries: Int
    let estimatedSavings: Double
    let savingsPercent: Double
}

/// AI Provider indicator info for UI
struct AIProviderInfo {
    let provider: AIProvider
    let color: String
    let reason: String
}
