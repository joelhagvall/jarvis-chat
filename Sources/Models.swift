import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String
    var content: String
    let timestamp: Date
    var toolCall: ToolCall?

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToolCall: Codable {
    let name: String
    let arguments: [String: String]
}

struct OllamaModel: Identifiable, Codable {
    var id: String { name }
    let name: String
    let size: Int64?

    enum CodingKeys: String, CodingKey {
        case name, size
    }
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    let tools: [OllamaTool]?
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

struct OllamaTool: Codable {
    let type: String
    let function: OllamaFunction
}

struct OllamaFunction: Codable {
    let name: String
    let description: String
    let parameters: OllamaParameters
}

struct OllamaParameters: Codable {
    let type: String
    let properties: [String: PropertySchema]
    let required: [String]
}

struct PropertySchema: Codable {
    let type: String
    let description: String?
}

struct OllamaStreamResponse: Codable {
    let model: String?
    let message: OllamaResponseMessage?
    let done: Bool?
}

struct OllamaResponseMessage: Codable {
    let role: String?
    let content: String?
    let tool_calls: [OllamaToolCall]?
}

struct OllamaToolCall: Codable {
    let function: OllamaToolFunction
}

struct OllamaToolFunction: Codable {
    let name: String
    let arguments: [String: String]?
}
