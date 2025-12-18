import Foundation
import SwiftUI

/// Observable state for chat UI
@MainActor
final class ChatState: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentToolName: String?
    @Published var isThinking: Bool = false
    @Published var currentStreamingText: String = ""
    @Published var currentStreamingThinking: String = ""

    func reset() {
        inputText = ""
        isLoading = true
        errorMessage = nil
        currentToolName = nil
    }

    func clearStreaming() {
        currentStreamingText = ""
        currentStreamingThinking = ""
        isThinking = false
    }

    func setError(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    func removeLastEmptyMessage() {
        if let last = messages.last, last.content.isEmpty {
            messages.removeLast()
        }
    }
}
