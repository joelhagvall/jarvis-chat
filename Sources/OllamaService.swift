import Foundation

actor OllamaService {
    private let baseURL = "http://localhost:11434"

    func listModels() async throws -> [OllamaModel] {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw OllamaError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.serverError
        }

        let modelsResponse = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
        return modelsResponse.models
    }

    func chat(
        model: String,
        messages: [OllamaMessage],
        tools: [OllamaTool]?,
        onChunk: @escaping (String) -> Void,
        onToolCall: @escaping (OllamaToolCall) -> Void
    ) async throws {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw OllamaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let chatRequest = OllamaChatRequest(
            model: model,
            messages: messages,
            stream: true,
            tools: tools
        )

        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.serverError
        }

        for try await line in bytes.lines {
            guard !line.isEmpty else { continue }

            if let data = line.data(using: .utf8),
               let chunk = try? JSONDecoder().decode(OllamaStreamResponse.self, from: data) {

                // Handle content
                if let content = chunk.message?.content, !content.isEmpty {
                    onChunk(content)
                }

                // Handle tool calls
                if let toolCalls = chunk.message?.tool_calls {
                    for toolCall in toolCalls {
                        onToolCall(toolCall)
                    }
                }
            }
        }
    }
}

enum OllamaError: Error, LocalizedError {
    case invalidURL
    case serverError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Ollama server not available. Make sure Ollama is running."
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
