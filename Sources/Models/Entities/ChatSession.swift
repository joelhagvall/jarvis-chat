import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \ChatMessageEntity.session)
    var messages: [ChatMessageEntity]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = []
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
