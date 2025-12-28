import XCTest
@testable import OllamaChat

final class OllamaModelsTests: XCTestCase {
    func testDecodeModelsResponse() throws {
        let json = """
        {
          "models": [
            { "name": "llama3", "size": 1234 },
            { "name": "qwen", "size": 5678 }
          ]
        }
        """

        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)

        XCTAssertEqual(decoded.models.count, 2)
        XCTAssertEqual(decoded.models.first?.name, "llama3")
    }

    func testDecodeStreamResponseWithToolCall() throws {
        let json = """
        {
          "model": "llama3",
          "message": {
            "role": "assistant",
            "content": "Hello",
            "thinking": "Thinking",
            "tool_calls": [
              { "function": { "name": "tool", "arguments": { "a": "b" } } }
            ]
          },
          "done": false
        }
        """

        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(OllamaStreamResponse.self, from: data)

        XCTAssertEqual(decoded.model, "llama3")
        XCTAssertEqual(decoded.message?.content, "Hello")
        XCTAssertEqual(decoded.message?.tool_calls?.first?.function.name, "tool")
        XCTAssertEqual(decoded.message?.tool_calls?.first?.function.arguments?["a"], "b")
    }
}
