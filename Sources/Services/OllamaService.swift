import Foundation

// MARK: - Process Launching Protocol

protocol ProcessLaunching: Sendable {
    func launchOllamaServe() throws
}

final class SystemProcessLauncher: ProcessLaunching {
    func launchOllamaServe() throws {
        let process = Process()
        
        // Common paths for Ollama
        let paths = [
            "/usr/local/bin/ollama",
            "/opt/homebrew/bin/ollama",
            "/usr/bin/ollama"
        ]
        
        // Try to find executable in common paths
        if let path = paths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = ["serve"]
        } else {
            // Fallback to env which relies on PATH
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["ollama", "serve"]
        }

        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        
        try process.run()
    }
}

// MARK: - Health Checking Protocol

protocol HealthChecking: Sendable {
    func checkOllamaHealth() async -> Bool
}

final class HTTPHealthChecker: HealthChecking {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://127.0.0.1:11434", session: URLSession? = nil) {
        self.baseURL = baseURL
        self.session = session ?? {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 5
            return URLSession(configuration: config)
        }()
    }

    func checkOllamaHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            return false
        }

        do {
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // Connection failed, Ollama is not running
        }
        return false
    }
}

// MARK: - OllamaService

actor OllamaService {
    private let baseURL = "http://127.0.0.1:11434"
    private let session: URLSession
    private let processLauncher: ProcessLaunching
    private let healthChecker: HealthChecking

    init(
        processLauncher: ProcessLaunching = SystemProcessLauncher(),
        healthChecker: HealthChecking? = nil
    ) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.processLauncher = processLauncher
        self.healthChecker = healthChecker ?? HTTPHealthChecker(baseURL: "http://127.0.0.1:11434")
    }

    // MARK: - Lifecycle

    /// Checks if Ollama is running, and starts it if not
    func ensureRunning() async throws {
        if await isRunning() {
            return
        }

        try startOllama()

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

        let (data, response) = try await session.data(from: url)

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

        let (bytes, response) = try await session.bytes(for: request)

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

                if chunk.done == true {
                    break
                }
            }
        }
    }

    // MARK: - Private Methods

    private func isRunning() async -> Bool {
        await healthChecker.checkOllamaHealth()
    }

    private func startOllama() throws {
        do {
            try processLauncher.launchOllamaServe()
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
