import Foundation

/// Handles streaming callbacks for chat responses
@MainActor
final class StreamingHandler {
    private weak var viewModel: ChatViewModel?
    private let activeSessionId: UUID?
    private let thinkingEnabled: Bool

    private(set) var rawContent: String = ""
    private(set) var fullThinking: String = ""

    init(viewModel: ChatViewModel, activeSessionId: UUID?, thinkingEnabled: Bool) {
        self.viewModel = viewModel
        self.activeSessionId = activeSessionId
        self.thinkingEnabled = thinkingEnabled
    }

    // MARK: - Callback Handlers

    func handleChunk(_ chunk: String) {
        guard let viewModel, viewModel.session.currentSessionId == activeSessionId else { return }

        rawContent += chunk
        viewModel.chat.currentStreamingText = rawContent
        viewModel.chat.isThinking = false
    }

    func handleThinking(_ thinking: String) {
        guard let viewModel,
              viewModel.session.currentSessionId == activeSessionId,
              thinkingEnabled else { return }

        fullThinking += thinking
        viewModel.chat.currentStreamingThinking = fullThinking
        viewModel.chat.isThinking = true
    }

    var hasThinking: Bool {
        thinkingEnabled && !fullThinking.isEmpty
    }

    // MARK: - Callback Builders

    var onChunk: (String) -> Void {
        { [weak self] chunk in
            self?.handleChunk(chunk)
        }
    }

    var onThinking: (String) -> Void {
        { [weak self] thinking in
            self?.handleThinking(thinking)
        }
    }
}
