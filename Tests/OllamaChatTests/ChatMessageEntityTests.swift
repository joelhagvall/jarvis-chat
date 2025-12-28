import XCTest
@testable import OllamaChat

final class ChatMessageEntityTests: XCTestCase {
    func testToolCallRoundTrip() {
        let entity = ChatMessageEntity(role: "assistant", content: "result")
        let toolCall = ToolCall(name: "myTool", arguments: ["key": "value"])

        entity.setToolCall(toolCall)

        let decoded = entity.toolCall
        XCTAssertEqual(decoded?.name, "myTool")
        XCTAssertEqual(decoded?.arguments["key"], "value")
    }

    func testToolCallNilWhenMissing() {
        let entity = ChatMessageEntity(role: "assistant", content: "result")
        XCTAssertNil(entity.toolCall)
    }
}
