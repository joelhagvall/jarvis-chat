import Foundation
import SwiftData

@Model
final class ChatMessageEntity {
    var id: UUID
    var role: String
    var content: String
    var thinking: String?
    var timestamp: Date
    var toolCallName: String?
    var toolCallArguments: String?
    var session: ChatSession?
    var orderIndex: Int

    init(
        id: UUID = UUID(),
        role: String,
        content: String,
        thinking: String? = nil,
        timestamp: Date = Date(),
        toolCallName: String? = nil,
        toolCallArguments: String? = nil,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.thinking = thinking
        self.timestamp = timestamp
        self.toolCallName = toolCallName
        self.toolCallArguments = toolCallArguments
        self.orderIndex = orderIndex
    }

    var toolCall: ToolCall? {
        guard let name = toolCallName else { return nil }
        let args = toolCallArguments.flatMap {
            try? JSONDecoder().decode([String: String].self, from: Data($0.utf8))
        } ?? [:]
        return ToolCall(name: name, arguments: args)
    }

    func setToolCall(_ toolCall: ToolCall?) {
        toolCallName = toolCall?.name
        if let args = toolCall?.arguments {
            toolCallArguments = try? String(data: JSONEncoder().encode(args), encoding: .utf8)
        } else {
            toolCallArguments = nil
        }
    }
}
