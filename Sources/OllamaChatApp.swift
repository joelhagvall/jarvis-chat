import SwiftUI
import SwiftData
import AppKit

@main
struct OllamaChatApp: App {
    let modelContainer: ModelContainer

    init() {
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
            fatalError("Failed to create ModelContainer: \(error)")
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
