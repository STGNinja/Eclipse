//
//  AppleIntelligenceService.swift
//  Eclipse
//
//  Created by Hybrid AI System on 12/17/25.
//

import Foundation
import UIKit
import Combine
import FoundationModels

/// Service for interacting with Apple's on-device Foundation Models (Apple Intelligence)
@MainActor
class AppleIntelligenceService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppleIntelligenceService()
    
    // MARK: - Properties
    
    private let model = SystemLanguageModel.default
    @Published var isAvailable: Bool = false
    @Published var unavailabilityReason: String?
    
    // MARK: - Initialization
    
    private init() {
        checkAvailability()
    }
    
    // MARK: - Availability Check
    
    /// Checks if Apple Intelligence is available on this device
    func checkAvailability() {
        switch model.availability {
        case .available:
            isAvailable = true
            unavailabilityReason = nil
            print("✅ Apple Intelligence is available")
            
        case .unavailable(.deviceNotEligible):
            isAvailable = false
            unavailabilityReason = "Device not eligible for Apple Intelligence (requires iPhone 15 Pro or later, iOS 18.1+)"
            print("❌ Apple Intelligence: Device not eligible")
            
        case .unavailable(.appleIntelligenceNotEnabled):
            isAvailable = false
            unavailabilityReason = "Apple Intelligence is not enabled. Please enable it in Settings > Apple Intelligence & Siri"
            print("⚠️ Apple Intelligence: Not enabled in Settings")
            
        case .unavailable(.modelNotReady):
            isAvailable = false
            unavailabilityReason = "Apple Intelligence model is downloading or not ready. Please try again later."
            print("⏳ Apple Intelligence: Model not ready")
            
        case .unavailable(let other):
            isAvailable = false
            unavailabilityReason = "Apple Intelligence is unavailable: \(other)"
            print("❌ Apple Intelligence: Unavailable - \(other)")
            
        @unknown default:
            isAvailable = false
            unavailabilityReason = "Unknown availability status"
            print("❓ Apple Intelligence: Unknown status")
        }
    }
    
    // MARK: - Text Generation (Streaming)
    
    /// Generate text response with streaming support
    func generateStream(
        prompt: String,
        instructions: String? = nil,
        conversationHistory: [Message] = [],
        userName: String? = nil,
        personalContext: PersonalContext? = nil
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                do {
                    // Check availability
                    guard isAvailable else {
                        throw AppleIntelligenceError.notAvailable(reason: unavailabilityReason ?? "Unknown")
                    }
                    
                    // Build system instructions
                    var systemInstructions = """
                    You are Eclipse, a thoughtfully crafted AI assistant for iOS.
                    
                    Your voice is clean, confident, and intentionally designed. Think like an Apple engineer and product designer combined.
                    
                    Core principles:
                    • Structure responses with clear markdown headers and numbered lists
                    • Keep paragraphs short (2-3 sentences max) and skimmable
                    • Use **bold** for key features and concepts
                    • Maintain strong visual spacing between sections
                    • Speak with calm authority—no filler, no hype, no uncertainty
                    
                    Response style:
                    • Assume SwiftUI, modern iOS patterns, and Apple platform knowledge
                    • Reference native concepts: depth, blur, haptics, liquid-glass surfaces, subtle motion
                    • Prioritize features that feel premium, alive, and purposeful
                    • Avoid generic AI explanations—focus on clarity and usefulness
                    • Every response should be copy-paste ready and quickly scannable
                    • Create at least one "aha" moment that feels intentional and polished
                    
                    Format guidelines:
                    • Never produce walls of text
                    • Use emojis sparingly (only when truly meaningful)
                    • Avoid markdown overuse—keep it clean
                    • Think connection over conversation: treat chat as part of a system for notes, tasks, and ideas
                    
                    Your goal: Make every interaction feel Apple-level refined, reducing friction and building trust through small, thoughtful details.
                    """
                    
                    // Add date context
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .full
                    systemInstructions += " Today's date is \(dateFormatter.string(from: Date()))."
                    
                    // Add user name if available
                    if let name = userName {
                        systemInstructions += " You are speaking with \(name)."
                    }
                    
                    // Add personal context if available
                    if let context = personalContext, !context.isEmpty {
                        systemInstructions += "\n\nPersonal Context:\n\(context.formattedString)"
                    }
                    
                    // Add custom instructions if provided
                    if let customInstructions = instructions {
                        systemInstructions += "\n\n\(customInstructions)"
                    }
                    
                    // Create session with instructions
                    let session = LanguageModelSession(instructions: systemInstructions)
                    
                    // For multi-turn conversations, we'd need to send previous messages
                    // Foundation Models handles context within a session automatically
                    // For now, we'll just send the current prompt
                    
                    // Stream the response
                    let responseStream = session.streamResponse(to: prompt)
                    
                    var accumulatedText = ""
                    var lastYieldTime = Date()
                    let minYieldInterval: TimeInterval = 0.05 // 50ms between yields
                    
                    for try await snapshot in responseStream {
                        // Foundation Models uses snapshots - each snapshot contains the full response so far
                        let fullText = String(snapshot.content)
                        
                        // Calculate what's new
                        if fullText.count > accumulatedText.count {
                            let startIndex = fullText.index(fullText.startIndex, offsetBy: accumulatedText.count)
                            let newText = String(fullText[startIndex...])
                            
                            accumulatedText = fullText
                            
                            // Batch updates - only yield if enough time has passed OR it's substantial text
                            let timeSinceLastYield = Date().timeIntervalSince(lastYieldTime)
                            if timeSinceLastYield >= minYieldInterval || newText.count > 10 {
                                continuation.yield(newText)
                                lastYieldTime = Date()
                            }
                        }
                    }
                    
                    // Make sure we yield any remaining text at the end
                    // (This shouldn't be needed but just in case)
                    
                    continuation.finish()
                    print("✅ Apple Intelligence stream completed")
                    
                } catch {
                    print("❌ Apple Intelligence error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Text Generation (Non-streaming)
    
    /// Generate text response without streaming
    func generate(
        prompt: String,
        instructions: String? = nil,
        conversationHistory: [Message] = [],
        userName: String? = nil,
        personalContext: PersonalContext? = nil
    ) async throws -> String {
        var fullText = ""
        for try await chunk in generateStream(
            prompt: prompt,
            instructions: instructions,
            conversationHistory: conversationHistory,
            userName: userName,
            personalContext: personalContext
        ) {
            fullText += chunk
        }
        return fullText
    }
    
    // MARK: - Text Summarization
    
    /// Summarize long text into a concise summary
    func summarize(text: String, maxLength: Int = 100) async throws -> String {
        guard isAvailable else {
            throw AppleIntelligenceError.notAvailable(reason: unavailabilityReason ?? "Unknown")
        }
        
        let instructions = "You are a summarization assistant. Provide concise, clear summaries."
        let prompt = "Summarize the following text in under \(maxLength) words:\n\n\(text)"
        
        return try await generate(prompt: prompt, instructions: instructions)
    }
    
    // MARK: - Text Rewriting
    
    /// Rewrite text with a specific tone or style
    func rewrite(text: String, tone: WritingTone) async throws -> String {
        guard isAvailable else {
            throw AppleIntelligenceError.notAvailable(reason: unavailabilityReason ?? "Unknown")
        }
        
        let instructions = """
        You are a writing assistant. Rewrite the provided text in a \(tone.rawValue) tone.
        Maintain the core message but adjust the style and wording.
        """
        
        let prompt = "Rewrite this text:\n\n\(text)"
        
        return try await generate(prompt: prompt, instructions: instructions)
    }
    
    // MARK: - Translation
    
    /// Translate text to another language
    func translate(text: String, to language: String) async throws -> String {
        guard isAvailable else {
            throw AppleIntelligenceError.notAvailable(reason: unavailabilityReason ?? "Unknown")
        }
        
        let instructions = "You are a translation assistant. Provide accurate translations."
        let prompt = "Translate the following text to \(language):\n\n\(text)"
        
        return try await generate(prompt: prompt, instructions: instructions)
    }
    
    // MARK: - Structured Data Generation
    
    /// Generate structured data (using Guided Generation)
    func generateStructured<T: Generable>(
        prompt: String,
        generating type: T.Type
    ) async throws -> T {
        guard isAvailable else {
            throw AppleIntelligenceError.notAvailable(reason: unavailabilityReason ?? "Unknown")
        }
        
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: type)
        
        return response.content
    }
    
    // MARK: - Image Analysis (Using Vision + Language Model)
    
    /// Analyze an image using Apple Intelligence
    /// Note: Foundation Models doesn't directly support image input yet (as of iOS 18.1)
    /// This is a placeholder for when multimodal support is added
    func analyzeImage(_ image: UIImage, prompt: String) async throws -> String {
        guard isAvailable else {
            throw AppleIntelligenceError.notAvailable(reason: unavailabilityReason ?? "Unknown")
        }
        
        // For now, return an error indicating this feature requires Gemini
        throw AppleIntelligenceError.featureNotSupported(
            feature: "Image analysis",
            reason: "Apple Intelligence doesn't support image input yet. Using Gemini for this request."
        )
    }
    
    // MARK: - Chat Title Generation
    
    /// Generate a concise title for a conversation
    func generateChatTitle(from messages: [Message]) async throws -> String {
        guard isAvailable else {
            throw AppleIntelligenceError.notAvailable(reason: unavailabilityReason ?? "Unknown")
        }
        
        // Get first few messages for context
        let contextMessages = messages.prefix(4)
        var conversationContext = ""
        
        for msg in contextMessages {
            if msg.isUser {
                conversationContext += "User: \(msg.text)\n"
            } else {
                conversationContext += "AI: \(msg.text.prefix(100))...\n"
            }
        }
        
        let instructions = """
        You are a title generation assistant. Create short, descriptive titles.
        Generate a title of 6 words or less. Only respond with the title, nothing else.
        """
        
        let prompt = "Generate a short title for this conversation:\n\n\(conversationContext)"
        
        let title = try await generate(prompt: prompt, instructions: instructions)
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "Title:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Supporting Types

/// Represents personal context that can be provided to Apple Intelligence
struct PersonalContext {
    var calendarEvents: [String] = []
    var userPreferences: [String: String] = [:]
    var recentActivity: [String] = []
    var customContext: String?
    
    var isEmpty: Bool {
        calendarEvents.isEmpty && 
        userPreferences.isEmpty && 
        recentActivity.isEmpty && 
        customContext == nil
    }
    
    var formattedString: String {
        var parts: [String] = []
        
        if !calendarEvents.isEmpty {
            parts.append("Calendar Events:\n" + calendarEvents.joined(separator: "\n"))
        }
        
        if !userPreferences.isEmpty {
            let prefs = userPreferences.map { "- \($0.key): \($0.value)" }.joined(separator: "\n")
            parts.append("User Preferences:\n\(prefs)")
        }
        
        if !recentActivity.isEmpty {
            parts.append("Recent Activity:\n" + recentActivity.joined(separator: "\n"))
        }
        
        if let custom = customContext {
            parts.append(custom)
        }
        
        return parts.joined(separator: "\n\n")
    }
}

/// Writing tone options for text rewriting
enum WritingTone: String, CaseIterable {
    case professional = "professional"
    case casual = "casual"
    case friendly = "friendly"
    case formal = "formal"
    case concise = "concise"
    case detailed = "detailed"
    case creative = "creative"
    case technical = "technical"
}

// MARK: - Error Types

enum AppleIntelligenceError: LocalizedError {
    case notAvailable(reason: String)
    case featureNotSupported(feature: String, reason: String)
    case sessionError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return "Apple Intelligence is not available: \(reason)"
        case .featureNotSupported(let feature, let reason):
            return "\(feature) is not supported: \(reason)"
        case .sessionError(let message):
            return "Session error: \(message)"
        }
    }
}

// MARK: - Example Generable Types

/// Example: Simple fact extraction
@Generable(description: "Extract key facts from text")
struct ExtractedFacts {
    @Guide(description: "Main facts extracted from the text", .count(1...10))
    var facts: [String]
}

/// Example: Calendar event extraction
@Generable(description: "Extract calendar event information")
struct EventInfo {
    @Guide(description: "Event title")
    var title: String
    
    @Guide(description: "Event date and time description")
    var dateTime: String
    
    @Guide(description: "Event duration in minutes", .range(15...480))
    var durationMinutes: Int?
    
    @Guide(description: "Event notes or description")
    var notes: String?
}
