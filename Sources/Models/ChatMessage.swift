import Foundation

// MARK: - Domain Model

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: String
    var content: String
    var thinking: String?
    let timestamp: Date
    var toolCall: ToolCall?

    init(
        id: UUID = UUID(),
        role: String,
        content: String,
        thinking: String? = nil,
        timestamp: Date = Date(),
        toolCall: ToolCall? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.thinking = thinking
        self.timestamp = timestamp
        self.toolCall = toolCall
    }

    init(from entity: ChatMessageEntity) {
        self.id = entity.id
        self.role = entity.role
        self.content = entity.content
        self.thinking = entity.thinking
        self.timestamp = entity.timestamp
        self.toolCall = entity.toolCall
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Tool Call

struct ToolCall: Codable {
    let name: String
    let arguments: [String: String]
}
