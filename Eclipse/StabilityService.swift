import Foundation
import UIKit

enum StabilityError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case noData
}

class StabilityService {
    static let shared = StabilityService()
    
    private let apiKey = "sk-MNfzalfvOUJD0k1GCENMQWFCQyERMiHwgzCe4avxYBp7zarK"
    private let apiURL = "https://api.stability.ai/v2beta/stable-image/generate/core"
    
    // Valid aspect ratios: 16:9, 1:1, 21:9, 2:3, 3:2, 4:5, 5:4, 9:16, 9:21
    func generateImage(prompt: String, aspectRatio: String = "1:1", negativePrompt: String? = nil, stylePreset: String? = nil) async throws -> Data {
        guard let url = URL(string: apiURL) else {
            throw StabilityError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        func append(_ string: String) {
            if let data = string.data(using: .utf8) {
                body.append(data)
            }
        }
        
        // Prompt
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
        append("\(prompt)\r\n")
        
        // Aspect Ratio
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"aspect_ratio\"\r\n\r\n")
        append("\(aspectRatio)\r\n")
        
        // Negative Prompt (Optional)
        if let negative = negativePrompt {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"negative_prompt\"\r\n\r\n")
            append("\(negative)\r\n")
        }

        // Style Preset (Optional)
        if let style = stylePreset {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"style_preset\"\r\n\r\n")
            append("\(style)\r\n")
        }
        
        // Output Format
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"output_format\"\r\n\r\n")
        append("png\r\n")
        
        append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        print("🎨 Sending Stability AI Core generation request")
        print("📝 Prompt: \(prompt)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StabilityError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            print("✅ Successfully generated image with Stability AI")
            return data
        } else {
            var errorMessage = "Unknown error"
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = errorJson["errors"] as? [[String: Any]],
               let msg = errors.first?["message"] as? String {
                errorMessage = msg
            } else if let str = String(data: data, encoding: .utf8) {
                errorMessage = str
            }
            
            print("❌ Stability API Error: \(httpResponse.statusCode) - \(errorMessage)")
            throw StabilityError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
    }
}
