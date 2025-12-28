import XCTest
@testable import OllamaChat

final class ThinkingParserTests: XCTestCase {
    func testThinkTagParsing() {
        let input = "<think>Reasoning</think>Answer"
        let parsed = ThinkingParser.parse(input)

        XCTAssertEqual(parsed.thinking, "Reasoning")
        XCTAssertEqual(parsed.content, "Answer")
    }

    func testResponseTagParsing() {
        let input = "Thoughts before<response>Final answer</response>"
        let parsed = ThinkingParser.parse(input)

        XCTAssertEqual(parsed.thinking, "Thoughts before")
        XCTAssertEqual(parsed.content, "Final answer")
    }

    func testHeuristicParsing() {
        let input = "I need to check something"
        let parsed = ThinkingParser.parse(input)

        XCTAssertEqual(parsed.thinking, input)
        XCTAssertEqual(parsed.content, "")
    }

    func testFallbackParsing() {
        let input = "Just a normal response."
        let parsed = ThinkingParser.parse(input)

        XCTAssertNil(parsed.thinking)
        XCTAssertEqual(parsed.content, input)
    }
}
