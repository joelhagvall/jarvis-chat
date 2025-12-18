import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedModel: String = ""
    @Published var availableModels: [OllamaModel] = []
    @Published var errorMessage: String?
    @Published var currentToolName: String?

    private let ollamaService = OllamaService()
    private let toolRegistry = ToolRegistry.shared

    func loadModels() async {
        do {
            let models = try await ollamaService.listModels()
            availableModels = models
            if selectedModel.isEmpty, let first = models.first {
                selectedModel = first.name
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        inputText = ""
        isLoading = true
        errorMessage = nil
        currentToolName = nil

        // Add user message
        let userMessage = ChatMessage(
            role: "user",
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)

        // Add assistant placeholder
        let assistantMessage = ChatMessage(
            role: "assistant",
            content: "",
            timestamp: Date()
        )
        messages.append(assistantMessage)

        do {
            // Convert messages to Ollama format
            let ollamaMessages = messages.dropLast().map { msg in
                OllamaMessage(role: msg.role, content: msg.content)
            }

            var toolCallToProcess: OllamaToolCall?

            // First request with tools
            try await ollamaService.chat(
                model: selectedModel,
                messages: Array(ollamaMessages),
                tools: toolRegistry.ollamaTools,
                onChunk: { [weak self] chunk in
                    Task { @MainActor in
                        guard let self = self,
                              let lastIndex = self.messages.indices.last else { return }
                        self.messages[lastIndex].content += chunk
                    }
                },
                onToolCall: { [weak self] toolCall in
                    Task { @MainActor in
                        self?.currentToolName = toolCall.function.name
                        toolCallToProcess = toolCall
                    }
                }
            )

            // Process tool call if any
            if let toolCall = toolCallToProcess {
                currentToolName = toolCall.function.name

                // Execute the tool
                let toolResult = await toolRegistry.execute(
                    name: toolCall.function.name,
                    arguments: toolCall.function.arguments ?? [:]
                )

                // Clear current message and add tool context
                if let lastIndex = messages.indices.last {
                    messages[lastIndex].content = ""
                    messages[lastIndex].toolCall = ToolCall(
                        name: toolCall.function.name,
                        arguments: toolCall.function.arguments ?? [:]
                    )
                }

                // Build follow-up messages
                var followUpMessages = Array(ollamaMessages)
                followUpMessages.append(OllamaMessage(
                    role: "assistant",
                    content: "I'll use the \(toolCall.function.name) tool to get this information."
                ))
                followUpMessages.append(OllamaMessage(
                    role: "user",
                    content: "[Tool Result from \(toolCall.function.name)]:\n\(toolResult)\n\n---\nPresent this information to me naturally."
                ))

                // Second request with tool result
                try await ollamaService.chat(
                    model: selectedModel,
                    messages: followUpMessages,
                    tools: nil,
                    onChunk: { [weak self] chunk in
                        Task { @MainActor in
                            guard let self = self,
                                  let lastIndex = self.messages.indices.last else { return }
                            self.messages[lastIndex].content += chunk
                        }
                    },
                    onToolCall: { _ in }
                )
            }

            currentToolName = nil

        } catch {
            errorMessage = error.localizedDescription
            // Remove empty assistant message on error
            if let last = messages.last, last.content.isEmpty {
                messages.removeLast()
            }
        }

        isLoading = false
    }

    func clearChat() {
        messages.removeAll()
    }
}
