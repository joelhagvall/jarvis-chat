import Foundation

@MainActor
protocol MessageHandling {
    func buildOllamaMessages(systemPrompt: String, messages: [ChatMessage]) -> [OllamaMessage]
    func ensureOllamaRunning() async throws
    func send(
        model: String,
        messages: [OllamaMessage],
        tools: [OllamaTool]?,
        thinkingEnabled: Bool,
        onChunk: @escaping (String) -> Void,
        onThinking: @escaping (String) -> Void,
        onToolCall: @escaping (OllamaToolCall) -> Void
    ) async throws
    func sendFollowUp(
        model: String,
        messages: [OllamaMessage],
        toolName: String,
        toolResult: String,
        thinkingEnabled: Bool,
        onChunk: @escaping (String) -> Void,
        onThinking: @escaping (String) -> Void
    ) async throws
    func loadModels() async throws -> [OllamaModel]
}

/// Handles message sending and tool call processing
@MainActor
final class MessageHandler: MessageHandling {
    private let ollamaService = OllamaService()

    // MARK: - Message Building

    func buildOllamaMessages(systemPrompt: String, messages: [ChatMessage]) -> [OllamaMessage] {
        var ollamaMessages: [OllamaMessage] = []

        if !systemPrompt.isEmpty {
            ollamaMessages.append(OllamaMessage(role: "system", content: systemPrompt))
        }

        ollamaMessages += messages.map { OllamaMessage(role: $0.role, content: $0.content) }

        return ollamaMessages
    }

    func ensureOllamaRunning() async throws {
        try await ollamaService.ensureRunning()
    }

    // MARK: - Sending

    func send(
        model: String,
        messages: [OllamaMessage],
        tools: [OllamaTool]?,
        thinkingEnabled: Bool,
        onChunk: @escaping (String) -> Void,
        onThinking: @escaping (String) -> Void,
        onToolCall: @escaping (OllamaToolCall) -> Void
    ) async throws {
        try await ollamaService.chat(
            model: model,
            messages: messages,
            tools: tools,
            thinkingEnabled: thinkingEnabled,
            onChunk: onChunk,
            onThinking: onThinking,
            onToolCall: onToolCall
        )
    }

    func sendFollowUp(
        model: String,
        messages: [OllamaMessage],
        toolName: String,
        toolResult: String,
        thinkingEnabled: Bool,
        onChunk: @escaping (String) -> Void,
        onThinking: @escaping (String) -> Void
    ) async throws {
        var followUpMessages = messages
        followUpMessages.append(OllamaMessage(role: "assistant", content: ""))
        followUpMessages.append(OllamaMessage(
            role: "user",
            content: "[Tool Result from \(toolName)]:\n\(toolResult)\n\n---\nPresent this information to me naturally."
        ))

        try await ollamaService.chat(
            model: model,
            messages: followUpMessages,
            tools: nil,
            thinkingEnabled: thinkingEnabled,
            onChunk: onChunk,
            onThinking: onThinking,
            onToolCall: { _ in }
        )
    }

    // MARK: - Model Loading

    func loadModels() async throws -> [OllamaModel] {
        try await ollamaService.ensureRunning()
        return try await ollamaService.listModels()
    }
}
