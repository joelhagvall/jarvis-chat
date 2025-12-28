import XCTest
@testable import OllamaChat

final class ChatViewModelIntegrationTests: XCTestCase {
    @MainActor
    func testSendMessageAppendsResponse() async throws {
        let store = try makeInMemoryStore()
        let handler = StubMessageHandler()
        handler.sendHandler = { _, _, _, _, onChunk, _, _ in
            onChunk("Hello")
        }

        let viewModel = ChatViewModel(sessionService: store.service, messageHandler: handler)
        viewModel.setModelContext(store.container.mainContext)
        viewModel.settings.mcpEnabled = false
        viewModel.settings.thinkingEnabled = false
        viewModel.model.selectedModel = "model"

        viewModel.chat.inputText = "Hi"
        viewModel.sendMessage()
        await waitForLoadingToFinish(viewModel)

        XCTAssertEqual(viewModel.chat.messages.count, 2)
        XCTAssertEqual(viewModel.chat.messages.last?.content, "Hello")
    }

    @MainActor
    func testToolCallFlowCreatesToolMessageAndFollowUp() async throws {
        let store = try makeInMemoryStore()
        let handler = StubMessageHandler()
        handler.sendHandler = { _, _, _, _, _, _, onToolCall in
            onToolCall(OllamaToolCall(function: OllamaToolFunction(name: "tool", arguments: ["a": "b"])))
        }
        handler.sendFollowUpHandler = { _, _, _, toolResult, _, onChunk, _ in
            onChunk("Result: \(toolResult)")
        }

        let viewModel = ChatViewModel(sessionService: store.service, messageHandler: handler)
        viewModel.setModelContext(store.container.mainContext)
        viewModel.settings.mcpEnabled = false
        viewModel.settings.thinkingEnabled = false
        viewModel.model.selectedModel = "model"

        viewModel.chat.inputText = "Use tool"
        viewModel.sendMessage()
        await waitForLoadingToFinish(viewModel)

        XCTAssertEqual(viewModel.chat.messages.count, 3)
        XCTAssertEqual(viewModel.chat.messages[1].toolCall?.name, "tool")
        XCTAssertTrue(viewModel.chat.messages.last?.content.contains("Unknown tool: tool") ?? false)
    }

    @MainActor
    private func waitForLoadingToFinish(_ viewModel: ChatViewModel) async {
        for _ in 0..<50 {
            if !viewModel.chat.isLoading {
                return
            }
            await Task.yield()
        }
        XCTFail("Timed out waiting for send to finish")
    }
}
