import XCTest
@testable import OllamaChat

final class ChatStateTests: XCTestCase {
    @MainActor
    func testRemoveLastEmptyMessage() async {
        let state = ChatState()
        state.messages = [
            ChatMessage(role: "user", content: "Hi"),
            ChatMessage(role: "assistant", content: "")
        ]

        state.removeLastEmptyMessage()

        XCTAssertEqual(state.messages.count, 1)
        XCTAssertEqual(state.messages.first?.role, "user")
    }

    @MainActor
    func testRemoveLastEmptyMessageKeepsToolCall() async {
        let state = ChatState()
        let toolCall = ToolCall(name: "tool", arguments: ["a": "b"])
        state.messages = [
            ChatMessage(role: "assistant", content: "", toolCall: toolCall)
        ]

        state.removeLastEmptyMessage()

        XCTAssertEqual(state.messages.count, 1)
        XCTAssertEqual(state.messages.first?.toolCall?.name, "tool")
    }

    @MainActor
    func testResetClearsState() async {
        let state = ChatState()
        state.inputText = "Hello"
        state.isLoading = false
        state.errorMessage = "Err"
        state.currentStreamingText = "stream"

        state.reset()

        XCTAssertEqual(state.inputText, "")
        XCTAssertTrue(state.isLoading)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(state.currentStreamingText, "")
    }
}
