import XCTest
@testable import OllamaChat

final class ToolMappingTests: XCTestCase {
    func testMCPInputSchemaToOllamaParameters() {
        let schema = MCPInputSchema(
            type: "object",
            properties: [
                "name": MCPPropertySchema(type: "string", description: "Name")
            ],
            required: ["name"]
        )

        let parameters = schema.toOllamaParameters()

        XCTAssertEqual(parameters.type, "object")
        XCTAssertEqual(parameters.required, ["name"])
        XCTAssertEqual(parameters.properties["name"]?.type, "string")
        XCTAssertEqual(parameters.properties["name"]?.description, "Name")
    }
}
