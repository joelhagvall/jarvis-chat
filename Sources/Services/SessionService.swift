import Foundation
import OSLog
import SwiftData

/// Service responsible for managing chat sessions
@MainActor
final class SessionService {
    private let logger = Logger(subsystem: "OllamaChat", category: "SessionService")
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
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            logger.error("Failed to fetch sessions: \(error.localizedDescription)")
            return []
        }
    }

    func fetchSettings() -> AppSettingsEntity? {
        guard let modelContext else { return nil }

        var descriptor = FetchDescriptor<AppSettingsEntity>()
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            logger.error("Failed to fetch settings: \(error.localizedDescription)")
            return nil
        }
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
        let nextIndex = (session.messages.map(\.orderIndex).max() ?? -1) + 1
        let entity = ChatMessageEntity(
            role: role,
            content: content,
            orderIndex: nextIndex
        )
        entity.session = session
        session.messages.append(entity)
        return entity
    }

    func deleteMessage(_ entity: ChatMessageEntity) {
        modelContext?.delete(entity)
        save()
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
        thinkingEnabled: Bool,
        mcpEnabled: Bool,
        selectedModel: String,
        mcpServerPath: String
    ) {
        guard let modelContext else { return }

        var descriptor = FetchDescriptor<AppSettingsEntity>()
        descriptor.fetchLimit = 1
        let settings: AppSettingsEntity
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                settings = existing
            } else {
                settings = AppSettingsEntity()
                modelContext.insert(settings)
            }
        } catch {
            logger.error("Failed to fetch settings for save: \(error.localizedDescription)")
            return
        }

        settings.userName = userName
        settings.systemPrompt = systemPrompt
        settings.language = language
        settings.thinkingEnabled = thinkingEnabled
        settings.mcpEnabled = mcpEnabled
        settings.selectedModel = selectedModel
        settings.mcpServerPath = mcpServerPath

        save()
    }

    // MARK: - Private

    @discardableResult
    func save() -> Bool {
        guard let modelContext else { return false }
        do {
            try modelContext.save()
            return true
        } catch {
            logger.error("Failed to save SwiftData context: \(error.localizedDescription)")
            return false
        }
    }
}
