import Foundation

actor OllamaService {
    private let baseURL = "http://127.0.0.1:11434"

    // MARK: - Lifecycle

    /// Checks if Ollama is running, and starts it if not
    func ensureRunning() async throws {
        if await isRunning() {
            return
        }

        try await startOllama()

        // Wait for Ollama to be ready (max 10 seconds)
        for _ in 0..<20 {
            try await Task.sleep(nanoseconds: 500_000_000)
            if await isRunning() {
                return
            }
        }

        throw OllamaError.failedToStart
    }

    // MARK: - API Methods

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
        thinkingEnabled: Bool = false,
        onChunk: @MainActor @escaping (String) -> Void,
        onThinking: @MainActor @escaping (String) -> Void,
        onToolCall: @MainActor @escaping (OllamaToolCall) -> Void
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
            tools: tools,
            options: thinkingEnabled ? OllamaChatOptions(think: true) : nil
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

                // Handle thinking (separate field from Ollama)
                if let thinking = chunk.message?.thinking, !thinking.isEmpty {
                    await onThinking(thinking)
                }

                // Handle content
                if let content = chunk.message?.content, !content.isEmpty {
                    await onChunk(content)
                }

                // Handle tool calls
                if let toolCalls = chunk.message?.tool_calls {
                    for toolCall in toolCalls {
                        await onToolCall(toolCall)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    private func isRunning() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // Connection failed, Ollama is not running
        }
        return false
    }

    private func startOllama() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["ollama", "serve"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            throw OllamaError.failedToStart
        }
    }
}

// MARK: - Errors

enum OllamaError: Error, LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case failedToStart

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Ollama server not available. Make sure Ollama is running."
        case .decodingError:
            return "Failed to decode response"
        case .failedToStart:
            return "Failed to start Ollama. Make sure Ollama is installed."
        }
    }
}
