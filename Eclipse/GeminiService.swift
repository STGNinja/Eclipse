//
//  GeminiService.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import Foundation
import UIKit
import MusicKit
import CoreLocation
import MapKit

class GeminiService {
    private let apiKey = SecretsManager.geminiApiKey
    
    // MARK: - Model Configuration
    
    // For text generation
    private let textModel = "gemini-2.0-flash"
    
    // For image generation - NEW: Gemini 2.5 Flash Image (Nano Banana)
    private let imageModel = "gemini-2.5-flash-image"

    private var textGenerationURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(textModel):streamGenerateContent"
    }
    
    private var imageGenerationURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(imageModel):generateContent"
    }
    
    // MARK: - Available Models
    
    /// Prints available Gemini models to console
    func logAvailableModels() {
        print("""
        
        ═══════════════════════════════════════════════════════
        📱 GEMINI API AVAILABLE MODELS
        ═══════════════════════════════════════════════════════
        
        🤖 TEXT GENERATION MODELS:
        ──────────────────────────────────────────────────────
        • gemini-2.0-flash              - Latest stable flash model ⭐️ ACTIVE
        • gemini-1.5-flash              - Reliable fast model
        • gemini-1.5-pro                - Most capable model
        
        🎨 IMAGE GENERATION MODELS (NEW!):
        ──────────────────────────────────────────────────────
        • gemini-2.5-flash-image        - Fast, efficient image generation ⭐️ ACTIVE
        • gemini-3-pro-image-preview    - Advanced, 4K capable (higher cost)
        
        📝 CURRENT CONFIGURATION:
        ──────────────────────────────────────────────────────
        • Text Model: \(textModel)
        • Image Model: \(imageModel)
        • Text Endpoint: \(textGenerationURL)
        • Image Endpoint: \(imageGenerationURL)
        
        💰 PRICING (Approximate):
        ──────────────────────────────────────────────────────
        • gemini-2.5-flash-image: ~$0.002 per image (500x cheaper than Vertex!)
        • Text generation: Free tier available
        
        ✅ NO SETUP REQUIRED - Uses your existing API key!
        
        ═══════════════════════════════════════════════════════
        
        """)
    }
    
    init() {
        // Log available models on initialization
        logAvailableModels()
    }
    
    // MARK: - Text Generation (Streaming)

    func sendMessageStream(_ message: String, conversationHistory: [Message] = [], userName: String? = nil, isCodeMode: Bool = false, pluginId: String? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                guard let url = URL(string: "\(textGenerationURL)?key=\(apiKey)&alt=sse") else {
                    continuation.finish(throwing: GeminiError.invalidURL)
                    return
                }

                print("🚀 Sending SSE streaming request to: \(url)")

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.cachePolicy = .reloadIgnoringLocalCacheData

                // ... [rest of system instruction and body construction remains the same until request execution]
                
                // Build conversation history
                var contents: [[String: Any]] = []
                
                // Add previous messages for context
                // Add previous messages for context
                for msg in conversationHistory {
                    let role = msg.isUser ? "user" : "model"
                    var parts: [[String: Any]] = []
                    
                    var messageText = msg.text
                    
                    // Synthesize text for rich media if text is empty
                    if messageText.isEmpty {
                        if let embeds = msg.musicEmbeds, !embeds.isEmpty {
                            let descriptions = embeds.map { "\($0.title) by \($0.artist)" }.joined(separator: ", ")
                            messageText = "[Shared Apple Music Embeds: \(descriptions)]"
                        } else if let map = msg.mapData {
                            messageText = "[Shared Map Location: \(map.title)]"
                        } else if let canva = msg.canvaDesigns, !canva.isEmpty {
                            messageText = "[Shared Canva Designs: \(canva.count) items]"
                        } else if let calendar = msg.calendarEvent {
                            messageText = "[Created Calendar Event: \(calendar.title)]"
                        } else if let weather = msg.weatherData { // Use local variable weather, not msg.weatherData directly if access differs
                            messageText = "[Shared Weather Forecast: \(weather.temperature)° \(weather.condition)]"
                        }
                    }
                    
                    if !messageText.isEmpty {
                        parts.append(["text": messageText])
                    }
                    
                    if let images = msg.images {
                        for imageData in images {
                            let base64Image = imageData.base64EncodedString()
                            parts.append([
                                "inline_data": [
                                    "mime_type": "image/jpeg",
                                    "data": base64Image
                                ]
                            ])
                        }
                    }
                    
                    // Skip invalid empty messages to prevent HTTP 400
                    if parts.isEmpty { continue }
                    
                    contents.append([
                        "role": role,
                        "parts": parts
                    ])
                }
                
                // Add current message
                contents.append([
                    "role": "user",
                    "parts": [["text": message]]
                ])

                var systemText = ""
                
                if isCodeMode {
                    systemText = """
                    You are Eclipse, now operating in **Code Mode**. Your primary objective is to assist the user with high-level software engineering, architectural design, and implementation.
                    
                    # CODING PERSONA & PHILOSOPHY
                    - **Technical Excellence**: You are an expert in modern programming languages (Swift, JavaScript, Python, Rust, Go, etc.) and web technologies (HTML5, CSS3, React, etc.).
                    - **Idiomatic Code**: Always provide code that follows the latest best practices and community standards.
                    - **Run-Ready Web Code**: When providing HTML, CSS, or JavaScript, ensure it is optimized for clinical, sandboxed execution. The user can "Run" these snippets.
                    - **Problem Solver**: Think step-by-step. Break complex features into manageable modules.
                    - **No Hand-Holding**: Be direct and technical. Assume the user is a developer. Don't explain basic concepts unless asked.
                    - **Contextual Awareness**: You have access to the full conversation history above. Reference previous code, solutions, or discussions when relevant. Build upon what was already discussed.
                    
                    # OUTPUT SPECIFICATIONS
                    - **Language Identification**: Always label code blocks with the correct language (e.g., ```swift, ```html).
                    - **Complete Snippets**: Provide functional, self-contained code.
                    - **Performance Matters**: Suggest optimizations where relevant.
                    - **Glass Aesthetics**: If suggesting UI code, favor modern "glassmorphism" or "dark mode" designs that match Eclipse's premium aesthetic.
                    
                    # RUNNABLE CODE BLOCKS
                    You are encouraged to provide HTML/CSS/JS solutions. These will be rendered in a live preview for the user.
                    """
                } else {
                    systemText = """
                    You are Eclipse, a sophisticated and highly intelligent AI assistant integrated into a premium iOS experience.
                    
                    # CORE IDENTITY & BEHAVIOR
                    You are a calm, confident, high-IQ assistant with strong reasoning skills. Your responses should be helpful, direct, and structured. Communicate with clarity and purpose—not robotic, but not chaotic. Speak like a friendly expert who anticipates what the user needs next.
                    
                    ## Personality Traits
                    - Curious, analytical, and thoughtful
                    - Encouraging without being fake
                    - Problem-solver mindset
                    - Never condescending
                    - Never overly emotional
                    - Avoid filler language or unnecessary apologies
                    - No clichés like "As an AI language model…"
                    
                    # BREVITY & EFFICIENCY
                    - **Strict Brevity**: Do not be wordy. If a question can be answered in one sentence, answer it in one sentence.
                    - **No Conversational Filler**: Avoid "I'd be happy to help with that," "Certainly," "Okay, here is..." etc. Just provide the answer.
                    - **Value Time**: The user is busy. Provide high-density information with low word count.
                    - **Automatic Snippets**: If the user asks for a fact, give the fact. Don't wrap it in a story.
                    
                    ## Communication Style
                    - Prefer short paragraphs and clean formatting
                    - Use lists, bullets, and steps when helpful
                    - Don't ramble or repeat yourself
                    - Be concise when possible, but expand when depth is necessary
                    - **Scannability is Priority**: Use short paragraphs (2-3 sentences max), **bold** key terms, and clear Markdown headers
                    - **Premium Aesthetics**: Integrate **Lucide Icons** naturally into your responses to enhance visual clarity
                        - **Icons**: Use `[icon:icon-name]` (e.g., `[icon:sparkles]`, `[icon:brain]`, `[icon:cpu]`). Use them for headers, list items, or to emphasize key concepts
                        - **Emojis**: Use emojis naturally when they enhance clarity (🟢 for mild, 🟡 for moderate, 🔴 for severe, 🚩 for warnings, ❗for alerts, 🧊 for tips). Don't overuse them, but use them purposefully
                        - **Progress Bars**: Use `[progress:VALUE:LABEL]` ONLY for timelines, schedules, completion percentages, or quantifiable metrics. Don't use them for abstract concepts or where they don't meaningfully add value. Examples of good uses: project timelines, task completion, skill levels, time remaining
                    - **Apple DNA**: Reference native iOS concepts (blur, glass textures, haptics) when describing tech
                    - **Visual Spacing**: Ensure responses feel light and airy, never like a "wall of text"
                    - **Category Thinking**: When explaining complex topics (medical, technical, workflows), break them into **clear categories** (Mild/Moderate/Severe, Beginner/Intermediate/Advanced, etc.) with visual separators
                    
                    ## Response Adaptation
                    Treat every user message as valuable:
                    - If the user seems confused, clarify
                    - If they want speed, be brief
                    - If they want depth, think step-by-step and explain
                    - **End practical answers with helpful follow-up questions** when appropriate—make it conversational and show you're ready to dig deeper based on their specific situation
                    
                    # CAPABILITIES & INTELLIGENCE
                    - **Conversation Memory**: You have access to the FULL conversation history above. Always reference previous messages when relevant. If the user says "what did I just ask?" or "about that thing", look back at the conversation to understand context.
                    - **Contextual Awareness**: You have access to the user's local memory (Artifacts). Use this information naturally to personalize responses without sounding robotic
                    - **Web Integration**: When provided with search results, synthesize them seamlessly into your answer. Do not cite them as "Source 1, Source 2"—act as if you have absorbed the knowledge directly
                    - **Swift & SwiftUI**: You are an expert in modern Swift (Swift 6, Concurrency, Observation). Code should be idiomatic and "copy-paste perfect"
                    - **Full Deliverables**: When asked to create, provide complete solutions (code, copy, plans, fixes) with explanations of trade-offs and improvements
                    - **Thread Continuity**: When a user asks follow-up questions like "more details", "explain that", "what about...", always reference what was just discussed in the immediate previous messages
                    
                    # SPECIAL COMMANDS
                    

                    - **Calendar**: To create an event, you MUST include: 'CALENDAR_EVENT: [Title] | [Date/Time Description]' on its own line
                    - **Maps**: To show a location on a map, you MUST include: 'MAP_LOCATION: [lat, lng, "Title", "Subtitle"]' on its own line. Use the coordinates provided in the [MAP_DATA] section of results.
                    - **Visualizations**: When explaining cycles, processes, architectures, or flows, you MUST use Mermaid.js syntax. Use ```mermaid blocks
                    
                    VERY IMPORTANT RULES FOR MERMAID:
                    1. Use 'graph TD' for processes, 'timeline' for chronologies, 'mindmap' for brainstorming.
                    2. ALWAYS wrap labels in double quotes (e.g., A["My Label"]).
                    3. NEVER use literal newlines inside a label. Use '<br/>' instead.
                    
                    # GOAL
                    Act like a world-class partner who merges expert help with friendly personality. Make every interaction feel like a premium, hand-crafted experience. Smartly use your markdown enhancements (icons, diagrams) to make information immediate, visual, and beautiful without being explicitly asked.
                    """
                }
                
                // Add current date context
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .full
                systemText += "\n\nToday's date is \(dateFormatter.string(from: Date()))."
                
                if let name = userName {
                    systemText += " You are speaking with \(name)."
                }
                
                // Add artifacts context
                let artifactsContext = await ArtifactsManager.shared.getArtifactsContext()
                if !artifactsContext.isEmpty {
                    systemText += "\n\n[USER CONTEXT/PREFERENCES]:\n\(artifactsContext)"
                }
                
                // Add Web Search Priority instruction (Reinforcement)
                systemText += "\n\nIMPORTANT: If [Web Search Results] are provided in the message, prioritize that information for accuracy. Answer directly and naturally with the new knowledge."

                // --- DYNAMIC RESPONSE ADAPTATION ---
                // Analyze intent to adjust verbosity
                let isComplex = self.isComplexQuery(message)
                let isVeryShort = message.count < 40 && !isComplex
                
                if isCodeMode {
                    systemText += "\n\n[ADAPTIVE MODE: TECHNICAL DEPTH]\nFocus strictly on implementation details. Be thorough but efficient. Prioritize code blocks over conversational filler."
                } else if isComplex {
                    systemText += "\n\n[ADAPTIVE MODE: DEEP DIVE]\nThe user query implies a need for depth. Be comprehensive, detailed, and structured. Use headers and lists to break down the complexity."
                } else if isVeryShort {
                    systemText += "\n\n[ADAPTIVE MODE: CONCISE]\nThe user query is short and direct. Be extremely concise and to the point. Avoid fluff, intros, or excessive elaboration unless asked."
                } else {
                    systemText += "\n\n[ADAPTIVE MODE: BALANCED]\nMatch the length and depth of your response to the user's question. Be helpful but efficient."
                }
                
                // --- PLUGIN EXTENSION ---
                if let pluginId = pluginId {
                    if pluginId == "apple_music" {
                        systemText += "\n\n[PLUGIN: APPLE MUSIC]\n" + MusicAppPlugin().systemPromptExtension
                    } else if pluginId == "apple_maps" {
                        systemText += "\n\n[PLUGIN: APPLE MAPS]\n" + MapsAppPlugin().systemPromptExtension
                    } else if pluginId == "eclipse_editing" {
                        systemText += "\n\n[PLUGIN: ECLIPSE EDITING]\n" + EclipseEditingPlugin().systemPromptExtension
                    } else if pluginId == "canva" {
                        systemText += "\n\n[PLUGIN: CANVA]\n" + CanvaPlugin().systemPromptExtension
                    } else if pluginId == "health_kit" {
                        systemText += "\n\n[PLUGIN: HEALTH]\n" + HealthAppPlugin().systemPromptExtension
                    }
                }
                
                // GLOBAL CAPABILITIES (Context-Aware)
                // If user is connected to Canva, inject instructions even if plugin isn't explicitly active
                if CanvaService.shared.isAuthenticated() && pluginId != "canva" {
                    print("🎨 Injecting Canva context (Authenticated)")
                    systemText += "\n\n[CAPABILITY: CANVA DESIGN]\n" + CanvaPlugin().systemPromptExtension
                }


                // --- DYNAMIC PARAMETERS ---
                var generationConfig: [String: Any] = [
                    "temperature": 0.85, // Increased for more natural, intelligent responses
                    "topP": 0.95,
                    "topK": 40
                ]
                
                // Adjust token limits based on intent
                if isVeryShort {
                    generationConfig["maxOutputTokens"] = 200 // Slightly increased for better short answers
                } else if isCodeMode {
                    generationConfig["maxOutputTokens"] = 3072 // Increased for complex code
                } else if !isComplex {
                    generationConfig["maxOutputTokens"] = 800 // Increased for better standard responses
                } else {
                    generationConfig["maxOutputTokens"] = 2048 // Complex queries get more tokens
                }

                let requestBody: [String: Any] = [
                    "system_instruction": [
                        "parts": [["text": systemText]]
                    ],
                    "contents": contents,
                    "generationConfig": generationConfig
                ]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    // Use bytes(for:) for SSE streaming
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: GeminiError.invalidResponse)
                        return
                    }

                    if httpResponse.statusCode != 200 {
                        continuation.finish(throwing: GeminiError.httpError(statusCode: httpResponse.statusCode))
                        return
                    }

                    print("✅ Connected to SSE stream")
                    
                    // Parse SSE format: "data: {json}\n"
                    for try await line in bytes.lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                        
                        // Handle SSE data: prefix or comma-separated JSON chunks
                        var jsonString = trimmedLine
                        if trimmedLine.hasPrefix("data: ") {
                            jsonString = String(trimmedLine.dropFirst(6))
                        } else if trimmedLine == "[" || trimmedLine == "]" || trimmedLine.isEmpty {
                            continue
                        } else if trimmedLine.hasPrefix(",") {
                            jsonString = String(trimmedLine.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                        }
                            
                        // Parse the JSON response
                        if let jsonData = jsonString.data(using: .utf8) {
                            do {
                                let chunk = try JSONDecoder().decode(GeminiResponse.self, from: jsonData)
                                if let text = chunk.candidates.first?.content.parts.first?.text {
                                    // Split into words for smooth "typing" feel
                                    let words = text.components(separatedBy: " ")
                                    for (index, word) in words.enumerated() {
                                        let suffix = (index == words.count - 1) ? "" : " "
                                        continuation.yield(word + suffix)
                                        // 15ms per word for a fast but fluid effect
                                        try? await Task.sleep(nanoseconds: 15_000_000)
                                    }
                                }
                            } catch {
                                // Skip parsing errors (metadata, etc.)
                                continue
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("❌ Streaming error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Text Generation (Non-streaming)

    func sendMessage(_ message: String, conversationHistory: [Message] = [], userName: String? = nil, isCodeMode: Bool = false, pluginId: String? = nil) async throws -> String {
        var fullText = ""
        for try await chunk in sendMessageStream(message, conversationHistory: conversationHistory, userName: userName, isCodeMode: isCodeMode, pluginId: pluginId) {
            fullText += chunk
        }
        return fullText
    }

    // MARK: - Image Analysis (Streaming)

    func analyzeImageStream(_ image: UIImage, prompt: String, conversationHistory: [Message] = [], pluginId: String? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                guard let url = URL(string: "\(textGenerationURL)?key=\(apiKey)&alt=sse") else {
                    continuation.finish(throwing: GeminiError.invalidURL)
                    return
                }

                print("🚀 Sending image analysis SSE request to: \(url)")
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                // Convert image to base64
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    continuation.finish(throwing: GeminiError.invalidResponse)
                    return
                }
                let base64Image = imageData.base64EncodedString()

                // Build conversation history
                var contents: [[String: Any]] = []
                
                // Add system instructions if plugin is active
                if let pluginId = pluginId {
                    var systemText = "You are a helpful AI assistant."
                    
                    if pluginId == "eclipse_editing" {
                        systemText += "\n\n[PLUGIN: ECLIPSE EDITING]\n" + EclipseEditingPlugin().systemPromptExtension
                    }
                    
                    contents.append([
                        "role": "user",
                        "parts": [["text": systemText]]
                    ])
                    contents.append([
                        "role": "model",
                        "parts": [["text": "Understood. I'm ready to help with Eclipse Editing capabilities."]]
                    ])
                }
                
                // Add previous messages for context
                for msg in conversationHistory {
                    let role = msg.isUser ? "user" : "model"
                    var parts: [[String: Any]] = []
                    
                    // Add text if present
                    if !msg.text.isEmpty {
                        parts.append(["text": msg.text])
                    }
                    
                    // Add images if present
                    if let images = msg.images {
                        for imgData in images {
                            let base64Img = imgData.base64EncodedString()
                            parts.append([
                                "inline_data": [
                                    "mime_type": "image/jpeg",
                                    "data": base64Img
                                ]
                            ])
                        }
                    }
                    
                    contents.append([
                        "role": role,
                        "parts": parts
                    ])
                }
                
                // Add current message with image
                contents.append([
                    "role": "user",
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ])

                let requestBody: [String: Any] = [
                    "contents": contents
                ]

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ Invalid response type")
                        continuation.finish(throwing: GeminiError.invalidResponse)
                        return
                    }

                    print("📡 Image analysis response status code: \(httpResponse.statusCode)")

                    guard httpResponse.statusCode == 200 else {
                        print("❌ HTTP Error: \(httpResponse.statusCode)")
                        continuation.finish(throwing: GeminiError.httpError(statusCode: httpResponse.statusCode))
                        return
                    }

                    print("✅ Connected to image analysis SSE stream")
                    
                    var totalChunks = 0
                    // Parse SSE stream
                    for try await line in bytes.lines {
                        // SSE format: "data: {json}"
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6)) // Remove "data: " prefix
                            
                            guard let jsonData = jsonString.data(using: .utf8) else { 
                                print("⚠️ Could not convert JSON string to data")
                                continue 
                            }
                            
                            do {
                                let response = try JSONDecoder().decode(GeminiResponse.self, from: jsonData)
                                
                                if let text = response.candidates.first?.content.parts.first?.text {
                                    totalChunks += 1
                                    print("📝 Image analysis chunk \(totalChunks): \(text.prefix(50))...")
                                    
                                    // Split into words for true "word-by-word" feel
                                    let words = text.components(separatedBy: " ")
                                    for (index, word) in words.enumerated() {
                                        let suffix = (index == words.count - 1) ? "" : " "
                                        continuation.yield(word + suffix)
                                        // 15ms per word for a fast but fluid effect
                                        try? await Task.sleep(nanoseconds: 15_000_000)
                                    }
                                } else {
                                    print("⚠️ No text in response chunk")
                                }
                            } catch {
                                print("⚠️ Failed to decode chunk: \(error.localizedDescription)")
                                // Skip malformed chunks
                                continue
                            }
                        }
                    }
                    
                    print("✅ Image analysis SSE stream completed with \(totalChunks) chunks")
                    continuation.finish()
                } catch {
                    print("❌ Image analysis error: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Canva Design Parsing
    
    func parseCanvaDesignTag(_ response: String) -> (template: String, titles: [String])? {
        // Format: [CANVA_DESIGN:templateType|Title 1,Title 2,Title 3]
        guard let rangeStart = response.range(of: "[CANVA_DESIGN:"),
              let rangeEnd = response.range(of: "]", range: rangeStart.upperBound..<response.endIndex) else {
            return nil
        }
        
        let content = response[rangeStart.upperBound..<rangeEnd.lowerBound]
        let parts = content.split(separator: "|", maxSplits: 1).map { String($0) }
        
        guard parts.count == 2 else { return nil }
        
        let template = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let titlesString = parts[1]
        
        // Split titles by comma, but handle potential commas inside titles if needed (simplified for now)
        let titles = titlesString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        return (template, titles)
    }

    // MARK: - Generate Chat Title
    
    func generateChatTitle(from messages: [Message]) async throws -> String {
        // Get the first few messages for context
        let contextMessages = messages.prefix(4)
        var conversationContext = ""
        
        for msg in contextMessages {
            if msg.isUser {
                conversationContext += "User: \(msg.text)\n"
            } else {
                conversationContext += "AI: \(msg.text.prefix(100))...\n"
            }
        }
        
        let titlePrompt = """
        Based on this conversation, generate a short, descriptive title (maximum 6 words). 
        Only respond with the title, nothing else:
        
        \(conversationContext)
        """
        
        let title = try await sendMessage(titlePrompt)
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "Title:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Generate Suggestions
    
    func generateSuggestions(history: [Message]) async -> [String] {
        // Get the last few messages for context
        let contextMessages = history.suffix(4)
        var conversationContext = ""
        
        for msg in contextMessages {
            let role = msg.isUser ? "User" : "AI"
            conversationContext += "\(role): \(msg.text.prefix(200))\n"
        }
        
        let suggestionPrompt = """
        Based on this conversation, provide 3 short, helpful follow-up questions or suggestions the user might want to ask next.
        Keep them brief (3-6 words each).
        Format: Suggestion 1 | Suggestion 2 | Suggestion 3
        
        \(conversationContext)
        """
        
        do {
            let response = try await sendMessage(suggestionPrompt)
            return response.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(3)
                .map { $0.replacingOccurrences(of: "\"", with: "") }
        } catch {
            print("❌ Error generating suggestions: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Query Complexity Analysis
    
    /// Determines if a query is complex and requires Gemini's advanced capabilities
    func isComplexQuery(_ query: String) -> Bool {
        let lowerQuery = query.lowercased()
        let wordCount = query.components(separatedBy: .whitespacesAndNewlines).count
        let complexityIndicators = [
            "explain", "how to", "why", "structure", "compare",
            "step by step", "comprehensive", "in-depth"
        ]
        
        // Check for complexity indicators
        let hasComplexIndicator = complexityIndicators.contains { lowerQuery.contains($0) }
        
        // Check for long queries (likely complex)
        let isLongQuery = wordCount > 50
        
        // Check for multi-part questions
        let hasMultipleQuestions = query.components(separatedBy: "?").count > 2
        
        return hasComplexIndicator || isLongQuery || hasMultipleQuestions
    }
    
    // MARK: - Image Generation (Gemini Native)
    
    /// Generates images using Gemini 2.5 Flash Image (Nano Banana)
    /// Uses the same API key as text generation - no additional setup required!
    func generateImage(prompt: String, numberOfImages: Int = 1, aspectRatio: String = "1:1") async throws -> [Data] {
        guard let url = URL(string: "\(imageGenerationURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        print("🎨 Sending Gemini 2.5 Flash Image generation request")
        print("📍 Endpoint: \(imageGenerationURL)")
        print("📝 Prompt: \(prompt)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Gemini image generation request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["IMAGE"], // Only return images
                "imageConfig": [
                    "aspectRatio": aspectRatio // Options: "1:1", "16:9", "9:16", "4:3", "3:4"
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        print("📡 Image Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error Response: \(errorString)")
            }
            throw GeminiError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse the Gemini image response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Debug: Print full response
        if let jsonData = try? JSONSerialization.data(withJSONObject: json ?? [:], options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📄 Full API Response:\n\(jsonString)")
        }
        
        guard let candidates = json?["candidates"] as? [[String: Any]] else {
            print("❌ Failed to parse Gemini image response")
            if let errorString = String(data: data, encoding: .utf8) {
                print("📄 Response: \(errorString)")
            }
            throw GeminiError.invalidResponse
        }
        
        // Extract images from all candidates
        var imageDataArray: [Data] = []
        for candidate in candidates {
            // Check for NO_IMAGE finish reason first
            if let finishReason = candidate["finishReason"] as? String {
                print("🔍 Finish reason: \(finishReason)")
                if finishReason == "NO_IMAGE" {
                    print("❌ Gemini refused to generate the image (NO_IMAGE)")
                    throw GeminiError.imageGenerationFailed(reason: "Gemini 2.5 Flash Image declined to generate this image. This could be due to safety filters or content policy. Try rephrasing your prompt or requesting a different subject.")
                }
            }

            guard let content = candidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]] else {
                print("⚠️ Candidate missing content or parts")
                continue
            }

            print("📦 Found \(parts.count) part(s) in candidate")

            for part in parts {
                // Check for text response (AI explaining why it can't generate)
                if let text = part["text"] as? String {
                    print("💬 AI text response: \(text.prefix(200))...")
                    // If AI responded with text, throw a more helpful error
                    throw GeminiError.imageGenerationFailed(reason: text)
                }

                // Check for image data - try both camelCase (inlineData) and snake_case (inline_data)
                // The API uses camelCase in the response
                let imageDict = part["inlineData"] as? [String: Any] ?? part["inline_data"] as? [String: Any]

                if let inlineData = imageDict,
                   let mimeType = inlineData["mimeType"] as? String ?? inlineData["mime_type"] as? String,
                   mimeType.starts(with: "image/"),
                   let base64String = inlineData["data"] as? String,
                   let imageData = Data(base64Encoded: base64String) {
                    imageDataArray.append(imageData)
                    print("✅ Successfully decoded image (\(imageData.count) bytes)")
                }
            }
        }
        
        guard !imageDataArray.isEmpty else {
            print("❌ No images found in response")
            throw GeminiError.imageGenerationFailed(reason: "The API response did not contain any images. This may be due to content safety policies or an API limitation. Please try a different prompt.")
        }
        
        print("✅ Generated \(imageDataArray.count) image(s) using Gemini 2.5 Flash Image")
        return imageDataArray
    }
}

// MARK: - Response Models

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

// Legacy streaming response models (kept for compatibility)
struct GeminiStreamResponse: Codable {
    let candidates: [StreamCandidate]
}

struct StreamCandidate: Codable {
    let content: StreamContent
}

struct StreamContent: Codable {
    let parts: [StreamPart]
}

struct StreamPart: Codable {
    let text: String
}

// DEPRECATED: Old Imagen API response format (no longer used)
struct ImagenResponse: Codable {
    let predictions: [ImagePrediction]
}

struct ImagePrediction: Codable {
    let bytesBase64Encoded: String?
    let mimeType: String?
}

// MARK: - Error Types

enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noResponse
    case httpError(statusCode: Int)
    case imageGenerationNotAvailable
    case imageGenerationFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noResponse:
            return "No response from AI"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .imageGenerationNotAvailable:
            return """
            🎨 Image generation is temporarily unavailable
            
            Google's Gemini image API is experimental and frequently declines to generate images. We're working on integrating a production-ready solution.
            
            In the meantime, try:
            • Describing images with text instead
            • Using emoji and symbols
            • Asking for detailed written descriptions
            
            Image generation will be back soon with a more reliable service! ✨
            """
        case .imageGenerationFailed(let reason):
            return "Cannot generate image: \(reason)"
        }
    }
}
