import XCTest
import SwiftData
@testable import OllamaChat

final class ChatMessageEntityTests: XCTestCase {
    @MainActor
    func testToolCallRoundTrip() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let entity = ChatMessageEntity(role: "assistant", content: "result")
        context.insert(entity)

        let toolCall = ToolCall(name: "myTool", arguments: ["key": "value"])
        entity.setToolCall(toolCall)

        let decoded = entity.toolCall
        XCTAssertEqual(decoded?.name, "myTool")
        XCTAssertEqual(decoded?.arguments["key"], "value")
    }

    @MainActor
    func testToolCallNilWhenMissing() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let entity = ChatMessageEntity(role: "assistant", content: "result")
        context.insert(entity)

        XCTAssertNil(entity.toolCall)
    }
}
