import Foundation
import SwiftData
@testable import OllamaChat

@MainActor
struct InMemoryStore {
    let container: ModelContainer
    let service: SessionService
}

@MainActor
func makeInMemoryStore() throws -> InMemoryStore {
    let schema = Schema([
        ChatSession.self,
        ChatMessageEntity.self,
        AppSettingsEntity.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    let service = SessionService()
    service.setModelContext(container.mainContext)
    return InMemoryStore(container: container, service: service)
}

@MainActor
func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([
        ChatSession.self,
        ChatMessageEntity.self,
        AppSettingsEntity.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}
