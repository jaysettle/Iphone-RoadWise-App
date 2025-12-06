//
//  ClaudeService.swift
//  RoadWise
//
//  Created by Jay on 12/4/25.
//

import Foundation
import CoreLocation

// Response models
struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}

struct ContentBlock: Codable {
    let type: String
    let text: String?
}

// Parsed fact with coordinates
struct RoadWiseFact {
    let text: String
    let nearestCity: String?
    let referencePlace: String?
    let coordinates: CLLocationCoordinate2D?
    let summary: String?
}

class ClaudeService {
    // Your Tailscale proxy URL from web app
    private let proxyURL = "https://jaslinux.tail23d264.ts.net/claude-proxy/v1/messages"

    // Track previous summaries to avoid repetition (like web app)
    private var factHistory: [String] = []
    private let maxHistorySize = 30

    // Session ID for this drive
    private let sessionId = Date().timeIntervalSince1970

    func getFact(
        latitude: Double,
        longitude: Double,
        heading: Double,
        speed: Double
    ) async throws -> RoadWiseFact {
        let prompt = generatePrompt(
            latitude: latitude,
            longitude: longitude,
            heading: heading,
            speed: speed
        )

        let requestBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        guard let url = URL(string: proxyURL) else {
            throw ClaudeError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ClaudeError.httpError(httpResponse.statusCode)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let text = textContent.text else {
            throw ClaudeError.noContent
        }

        // Parse the response
        let fact = parseFactResponse(text)

        // Track summary for anti-repetition
        if let summary = fact.summary {
            addToHistory(summary)
        }

        return fact
    }

    // Generate prompt matching web app's generateRoadWisePrompt()
    private func generatePrompt(
        latitude: Double,
        longitude: Double,
        heading: Double,
        speed: Double
    ) -> String {
        let historyString = factHistory.joined(separator: " | ")

        return """
        You are RoadWise, a fun road trip narrator. Give me ONE interesting fact about a location near these coordinates.

        Current position: \(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude))
        Heading: \(Int(heading))° (0=North, 90=East, 180=South, 270=West)
        Speed: \(String(format: "%.1f", speed)) mph
        Session ID: \(Int(sessionId))

        CRITICAL: Check the "Previously used topics" list carefully.
        DO NOT repeat or closely resemble ANY of those summaries.

        Previously used topics in this drive (AVOID these):
        \(historyString.isEmpty ? "None yet" : historyString)

        Rules for variety:
        - Each summary represents a fact already told in this drive
        - You MUST pick something completely different from ALL previous summaries
        - Different category, different type of location, different subject matter
        - Rotate categories aggressively - no two facts in a row from same category

        Categories to rotate through:
        - Historical sites and events
        - Local businesses and restaurants
        - Natural features (parks, rivers, geology)
        - Quirky/unusual facts
        - Food and cuisine history

        Find something interesting within 3 miles that is AHEAD of me based on my heading.

        Your response MUST follow this EXACT format:

        Nearest city: [City name], [State]
        Reference place: [Name of the specific place this fact is about]
        Reference coordinates: [lat], [lon]
        Summary: [2-5 words describing this fact's topic]

        [Your fun fact here - 2-3 sentences, engaging and informative]
        """
    }

    // Parse response into structured fact (like web app)
    private func parseFactResponse(_ text: String) -> RoadWiseFact {
        var nearestCity: String?
        var referencePlace: String?
        var coordinates: CLLocationCoordinate2D?
        var summary: String?
        var factText = text

        // Extract metadata lines
        let lines = text.components(separatedBy: "\n")
        var metadataEndIndex = 0

        for (index, line) in lines.enumerated() {
            if line.lowercased().hasPrefix("nearest city:") {
                nearestCity = String(line.dropFirst("nearest city:".count)).trimmingCharacters(in: .whitespaces)
                metadataEndIndex = index + 1
            } else if line.lowercased().hasPrefix("reference place:") {
                referencePlace = String(line.dropFirst("reference place:".count)).trimmingCharacters(in: .whitespaces)
                metadataEndIndex = index + 1
            } else if line.lowercased().hasPrefix("reference coordinates:") {
                let coordString = String(line.dropFirst("reference coordinates:".count)).trimmingCharacters(in: .whitespaces)
                coordinates = parseCoordinates(coordString)
                metadataEndIndex = index + 1
            } else if line.lowercased().hasPrefix("summary:") {
                summary = String(line.dropFirst("summary:".count)).trimmingCharacters(in: .whitespaces)
                metadataEndIndex = index + 1
            }
        }

        // Get just the fact text (after metadata)
        if metadataEndIndex < lines.count {
            factText = lines[metadataEndIndex...]
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Fallback summary from first few words if not provided
        if summary == nil && !factText.isEmpty {
            let words = factText.components(separatedBy: " ").prefix(5)
            summary = words.joined(separator: " ")
        }

        return RoadWiseFact(
            text: factText,
            nearestCity: nearestCity,
            referencePlace: referencePlace,
            coordinates: coordinates,
            summary: summary
        )
    }

    // Parse "39.7042, -86.3994" into CLLocationCoordinate2D
    private func parseCoordinates(_ string: String) -> CLLocationCoordinate2D? {
        let parts = string.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // Add summary to history for anti-repetition
    private func addToHistory(_ summary: String) {
        factHistory.append(summary)
        if factHistory.count > maxHistorySize {
            factHistory.removeFirst()
        }
    }

    // Clear history (for new session)
    func clearHistory() {
        factHistory.removeAll()
    }
}

enum ClaudeError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error: \(code)"
        case .noContent:
            return "No content in response"
        }
    }
}
