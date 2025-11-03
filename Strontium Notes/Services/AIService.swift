//
//  AIService.swift
//  Strontium Notes
//
//  Created by Kiro on 03/11/25.
//

import Foundation
import Combine

@MainActor
class AIService: ObservableObject {
    @Published var isProcessing = false
    
    func sendMessage(_ message: String, apiKey: String, context: String? = nil) async throws -> String {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Gemini API endpoint
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build prompt with context if available
        let fullPrompt: String
        if let context = context {
            fullPrompt = """
            Context from current note:
            \(context)
            
            User question: \(message)
            """
        } else {
            fullPrompt = message
        }
        
        // Gemini API request format
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as NSError {
            // Provide more detailed error information
            print("Network error: \(error.localizedDescription)")
            print("Error code: \(error.code)")
            print("Error domain: \(error.domain)")
            throw AIError.networkError(error.localizedDescription)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("Invalid response")
        }
        
        // Log response for debugging
        print("HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("API Error: \(message)")
                
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw AIError.invalidAPIKey
                } else if httpResponse.statusCode == 429 {
                    throw AIError.rateLimitExceeded
                } else {
                    throw AIError.apiError(message)
                }
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw AIError.invalidAPIKey
            } else if httpResponse.statusCode == 429 {
                throw AIError.rateLimitExceeded
            } else {
                throw AIError.apiError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.invalidResponse
        }
        
        // Debug: Print response structure
        print("Response JSON keys: \(json.keys)")
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("Failed to parse response structure")
            throw AIError.invalidResponse
        }
        
        return text
    }
}

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case networkError(String)
    case rateLimitExceeded
    case apiError(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Please enter your Gemini API key in Settings"
        case .invalidAPIKey:
            return "Invalid API key. Please check your key in Settings"
        case .networkError(let details):
            return "Network error: \(details)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .apiError(let message):
            return "API Error: \(message)"
        case .invalidResponse:
            return "Invalid response from AI service"
        }
    }
}
