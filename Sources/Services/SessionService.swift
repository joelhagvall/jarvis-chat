import Foundation
import SwiftData

/// Service responsible for managing chat sessions
@MainActor
final class SessionService {
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Fetch Operations

    func fetchAllSessions() -> [ChatSession] {
        guard let modelContext else { return [] }

        let descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchSettings() -> AppSettingsEntity? {
        guard let modelContext else { return nil }

        let descriptor = FetchDescriptor<AppSettingsEntity>()
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Session Operations

    func createSession() -> ChatSession? {
        guard let modelContext else { return nil }

        let newSession = ChatSession()
        modelContext.insert(newSession)
        save()
        return newSession
    }

    func deleteSession(_ session: ChatSession) {
        guard let modelContext else { return }

        modelContext.delete(session)
        save()
    }

    func updateSessionTitle(_ session: ChatSession, title: String) {
        session.title = title
        session.updatedAt = Date()
        save()
    }

    func updateSessionTimestamp(_ session: ChatSession) {
        session.updatedAt = Date()
        save()
    }

    func autoUpdateTitle(_ session: ChatSession) {
        if session.title == "New Chat",
           let firstUserMessage = session.messages.first(where: { $0.role == "user" }) {
            let title = String(firstUserMessage.content.prefix(40))
            session.title = title + (firstUserMessage.content.count > 40 ? "..." : "")
        }
    }

    // MARK: - Message Operations

    func createMessage(
        role: String,
        content: String,
        session: ChatSession
    ) -> ChatMessageEntity {
        let entity = ChatMessageEntity(
            role: role,
            content: content,
            orderIndex: session.messages.count
        )
        entity.session = session
        session.messages.append(entity)
        return entity
    }

    func deleteMessage(_ entity: ChatMessageEntity) {
        modelContext?.delete(entity)
    }

    func clearMessages(in session: ChatSession) {
        guard let modelContext else { return }

        for message in session.messages {
            modelContext.delete(message)
        }
        session.messages.removeAll()
        save()
    }

    func loadMessages(from session: ChatSession) -> [ChatMessage] {
        session.messages
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { ChatMessage(from: $0) }
    }

    // MARK: - Settings Operations

    func saveSettings(
        userName: String,
        systemPrompt: String,
        language: String,
        selectedModel: String,
        mcpServerPath: String
    ) {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<AppSettingsEntity>()
        let settings: AppSettingsEntity

        if let existing = try? modelContext.fetch(descriptor).first {
            settings = existing
        } else {
            settings = AppSettingsEntity()
            modelContext.insert(settings)
        }

        settings.userName = userName
        settings.systemPrompt = systemPrompt
        settings.language = language
        settings.selectedModel = selectedModel
        settings.mcpServerPath = mcpServerPath

        save()
    }

    // MARK: - Private

    func save() {
        try? modelContext?.save()
    }
}
