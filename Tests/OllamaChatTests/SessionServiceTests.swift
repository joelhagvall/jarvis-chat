import XCTest
import SwiftData
@testable import OllamaChat

final class SessionServiceTests: XCTestCase {
    @MainActor
    func testCreateSessionAndFetch() async throws {
        let store = try makeInMemoryStore()
        let service = store.service

        XCTAssertTrue(service.fetchAllSessions().isEmpty)

        let session = service.createSession()
        XCTAssertNotNil(session)

        let sessions = service.fetchAllSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.id, session?.id)
    }

    @MainActor
    func testCreateMessagesOrderIndex() async throws {
        let store = try makeInMemoryStore()
        let service = store.service
        let session = try XCTUnwrap(service.createSession())

        let first = service.createMessage(role: "user", content: "Hi", session: session)
        let second = service.createMessage(role: "assistant", content: "Hello", session: session)
        service.save()

        XCTAssertEqual(first.orderIndex, 0)
        XCTAssertEqual(second.orderIndex, 1)
        XCTAssertEqual(session.messages.count, 2)
    }

    @MainActor
    func testAutoUpdateTitleUsesFirstUserMessage() async throws {
        let store = try makeInMemoryStore()
        let service = store.service
        let session = try XCTUnwrap(service.createSession())

        XCTAssertEqual(session.title, "New Chat")
        _ = service.createMessage(role: "user", content: "This is a test title for the chat", session: session)
        service.autoUpdateTitle(session)

        XCTAssertNotEqual(session.title, "New Chat")
        XCTAssertTrue(session.title.hasPrefix("This is a test title"))
    }

    @MainActor
    func testSaveAndFetchSettings() async throws {
        let store = try makeInMemoryStore()
        let service = store.service

        service.saveSettings(
            userName: "Joel",
            systemPrompt: "Be concise",
            language: "sv",
            thinkingEnabled: false,
            mcpEnabled: false,
            selectedModel: "llama3",
            mcpServerPath: "/tmp/server.js"
        )

        let settings = service.fetchSettings()
        XCTAssertEqual(settings?.userName, "Joel")
        XCTAssertEqual(settings?.systemPrompt, "Be concise")
        XCTAssertEqual(settings?.language, "sv")
        XCTAssertEqual(settings?.thinkingEnabled, false)
        XCTAssertEqual(settings?.mcpEnabled, false)
        XCTAssertEqual(settings?.selectedModel, "llama3")
        XCTAssertEqual(settings?.mcpServerPath, "/tmp/server.js")
    }

    @MainActor
    func testClearMessagesRemovesAll() async throws {
        let store = try makeInMemoryStore()
        let service = store.service
        let session = try XCTUnwrap(service.createSession())

        _ = service.createMessage(role: "user", content: "Hi", session: session)
        _ = service.createMessage(role: "assistant", content: "Hello", session: session)
        service.save()

        XCTAssertEqual(session.messages.count, 2)
        service.clearMessages(in: session)
        XCTAssertEqual(session.messages.count, 0)
    }
}
