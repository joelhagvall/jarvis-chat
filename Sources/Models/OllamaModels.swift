import Foundation

// MARK: - Ollama API Models

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

// MARK: - Chat Request/Response

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    let tools: [OllamaTool]?
    let options: OllamaChatOptions?
}

struct OllamaChatOptions: Codable {
    let think: Bool?
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

struct OllamaStreamResponse: Codable {
    let model: String?
    let message: OllamaResponseMessage?
    let done: Bool?
}

struct OllamaResponseMessage: Codable {
    let role: String?
    let content: String?
    let thinking: String?
    let tool_calls: [OllamaToolCall]?
}

// MARK: - Tool Definitions

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

// MARK: - Tool Calls

struct OllamaToolCall: Codable {
    let function: OllamaToolFunction
}

struct OllamaToolFunction: Codable {
    let name: String
    let arguments: [String: String]?
}
