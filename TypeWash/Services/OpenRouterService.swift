import Foundation

// MARK: - Service

struct OpenRouterService {
    private let apiKey: String
    private let model: String
    private static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }

    struct RegexSuggestion {
        let findPattern: String
        let replacePattern: String
        let explanation: String
    }

    func generateRegex(from description: String) async throws -> RegexSuggestion {
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ServiceError.invalidDescription
        }

        let systemPrompt = """
        You are a regex expert. The user will describe a text transformation in natural language. \
        You must return a JSON object with exactly three fields:
        - "find": an ICU-flavored regular expression pattern compatible with NSRegularExpression
        - "replace": the replacement template using $1, $2, etc. for capture group back-references
        - "explanation": a brief, one-to-two sentence explanation of what the pattern does

        Rules:
        - Use ICU regex syntax (compatible with Apple's NSRegularExpression).
        - Use \\p{...} for Unicode properties where appropriate.
        - Escape backslashes properly for JSON (e.g., \\\\d for the digit shorthand \\d).
        - Respond ONLY with valid JSON -- no markdown, no explanation outside the JSON.

        Example response:
        {"find": "[ ]{2,}", "replace": " ", "explanation": "Collapses runs of two or more spaces into a single space."}
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": description
                ]
            ]
        ]

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)",       forHTTPHeaderField: "Authorization")
        request.setValue("application/json",        forHTTPHeaderField: "Content-Type")
        request.setValue("TypeWash",                forHTTPHeaderField: "X-Title")
        request.setValue("https://typewash.app",    forHTTPHeaderField: "HTTP-Referer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            break
        case 401:
            throw ServiceError.unauthorized
        case 402:
            throw ServiceError.insufficientCredits
        case 429:
            throw ServiceError.rateLimited
        default:
            let msg = String(data: data, encoding: .utf8) ?? "(no body)"
            throw ServiceError.apiError(statusCode: http.statusCode, body: msg)
        }

        let decoded = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw ServiceError.emptyResponse
        }

        return try parseRegexSuggestion(from: content)
    }

    // MARK: - JSON Parsing (tolerant)

    private func parseRegexSuggestion(from content: String) throws -> RegexSuggestion {
        // Strip markdown code fences if the model wrapped the JSON
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```",     with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
              let find = json["find"],
              let replace = json["replace"],
              let explanation = json["explanation"] else {
            throw ServiceError.parseError(raw: content)
        }

        return RegexSuggestion(
            findPattern: find,
            replacePattern: replace,
            explanation: explanation
        )
    }
}

// MARK: - Error

extension OpenRouterService {
    enum ServiceError: LocalizedError {
        case invalidDescription
        case invalidResponse
        case unauthorized
        case insufficientCredits
        case rateLimited
        case apiError(statusCode: Int, body: String)
        case emptyResponse
        case parseError(raw: String)

        var errorDescription: String? {
            switch self {
            case .invalidDescription:
                return "Please enter a description of the text transformation you need."
            case .invalidResponse:
                return "Received an invalid response from OpenRouter."
            case .unauthorized:
                return "Invalid API key. Please check your OpenRouter key in Settings (\u{2318},)."
            case .insufficientCredits:
                return "Your OpenRouter account has insufficient credits."
            case .rateLimited:
                return "Rate limit reached. Please wait a moment and try again."
            case .apiError(let code, let body):
                return "API error \(code): \(body)"
            case .emptyResponse:
                return "The model returned an empty response."
            case .parseError(let raw):
                return "Could not parse the regex suggestion from: \(raw)"
            }
        }
    }
}

// MARK: - Response Models

private struct OpenRouterResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}
