import SwiftUI
import SwiftData
import AppKit
import OSLog

@main
struct OllamaChatApp: App {
    let modelContainer: ModelContainer

    init() {
        let logger = Logger(subsystem: "OllamaChat", category: "App")
        // When launched from a SwiftPM executable (or from Terminal), the app can end up
        // without a "regular" activation policy which breaks keyboard focus in text inputs.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        do {
            let schema = Schema([
                ChatSession.self,
                ChatMessageEntity.self,
                AppSettingsEntity.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            logger.error("Failed to create persistent ModelContainer: \(error.localizedDescription)")
            do {
                let schema = Schema([
                    ChatSession.self,
                    ChatMessageEntity.self,
                    AppSettingsEntity.self
                ])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create fallback ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 600)
    }
}
