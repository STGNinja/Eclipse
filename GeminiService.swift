//
//  GeminiService.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/14/25.
//

import Foundation

class GeminiService {
    private let apiKey = "AIzaSyB15ga2_2OF9a6_vIpiKhhHJZLow_F17Ms"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:streamGenerateContent"
    
    // Streaming response
    func sendMessageStream(_ message: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                guard let url = URL(string: "\(baseURL)?key=\(apiKey)&alt=sse") else {
                    continuation.finish(throwing: GeminiError.invalidURL)
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let requestBody: [String: Any] = [
                    "contents": [
                        [
                            "parts": [
                                ["text": message]
                            ]
                        ]
                    ],
                    "generationConfig": [
                        "temperature": 0.9,
                        "topK": 1,
                        "topP": 1,
                        "maxOutputTokens": 2048
                    ]
                ]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    print("🚀 Sending request to: \(url)")

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("❌ Invalid response type")
                        continuation.finish(throwing: GeminiError.invalidResponse)
                        return
                    }

                    print("📡 Response status code: \(httpResponse.statusCode)")

                    guard httpResponse.statusCode == 200 else {
                        print("❌ HTTP Error: \(httpResponse.statusCode)")
                        continuation.finish(throwing: GeminiError.httpError(statusCode: httpResponse.statusCode))
                        return
                    }
                    
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonText = String(line.dropFirst(6))
                            
                            if let data = jsonText.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(GeminiStreamResponse.self, from: data),
                               let text = chunk.candidates.first?.content.parts.first?.text {
                                continuation.yield(text)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Non-streaming fallback
    func sendMessage(_ message: String) async throws -> String {
        var fullText = ""
        for try await chunk in sendMessageStream(message) {
            fullText += chunk
        }
        return fullText
    }
}

// MARK: - Response Models

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

// MARK: - Error Types

enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noResponse
    case httpError(statusCode: Int)
    
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
        }
    }
}
