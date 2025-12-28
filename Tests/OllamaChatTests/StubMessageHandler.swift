import Foundation
@testable import OllamaChat

@MainActor
final class StubMessageHandler: MessageHandling {
    typealias SendHandler = (
        _ model: String,
        _ messages: [OllamaMessage],
        _ tools: [OllamaTool]?,
        _ thinkingEnabled: Bool,
        _ onChunk: @escaping (String) -> Void,
        _ onThinking: @escaping (String) -> Void,
        _ onToolCall: @escaping (OllamaToolCall) -> Void
    ) async throws -> Void

    typealias SendFollowUpHandler = (
        _ model: String,
        _ messages: [OllamaMessage],
        _ toolName: String,
        _ toolResult: String,
        _ thinkingEnabled: Bool,
        _ onChunk: @escaping (String) -> Void,
        _ onThinking: @escaping (String) -> Void
    ) async throws -> Void

    var models: [OllamaModel] = []
    var sendHandler: SendHandler?
    var sendFollowUpHandler: SendFollowUpHandler?

    func buildOllamaMessages(systemPrompt: String, messages: [ChatMessage]) -> [OllamaMessage] {
        var ollamaMessages: [OllamaMessage] = []

        if !systemPrompt.isEmpty {
            ollamaMessages.append(OllamaMessage(role: "system", content: systemPrompt))
        }

        ollamaMessages += messages.map { OllamaMessage(role: $0.role, content: $0.content) }

        return ollamaMessages
    }

    func ensureOllamaRunning() async throws {}

    func send(
        model: String,
        messages: [OllamaMessage],
        tools: [OllamaTool]?,
        thinkingEnabled: Bool,
        onChunk: @escaping (String) -> Void,
        onThinking: @escaping (String) -> Void,
        onToolCall: @escaping (OllamaToolCall) -> Void
    ) async throws {
        if let sendHandler {
            try await sendHandler(model, messages, tools, thinkingEnabled, onChunk, onThinking, onToolCall)
        }
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
        if let sendFollowUpHandler {
            try await sendFollowUpHandler(model, messages, toolName, toolResult, thinkingEnabled, onChunk, onThinking)
        }
    }

    func loadModels() async throws -> [OllamaModel] {
        models
    }
}
