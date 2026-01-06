import Foundation
import SwiftUI

/// Observable state for user settings
@MainActor
final class SettingsState: ObservableObject {
    @Published var userName: String = ""
    @Published var systemPrompt: String = "You're JARVIS from Iron Man."
    @Published var language: String = "auto"
    @Published var thinkingEnabled: Bool = true
    @Published var mcpEnabled: Bool = true
    @Published var mcpServerPath: String = ""

    func apply(from settings: AppSettingsEntity) {
        userName = settings.userName
        systemPrompt = settings.systemPrompt
        language = settings.language
        thinkingEnabled = settings.thinkingEnabled ?? true
        mcpEnabled = settings.mcpEnabled ?? true
        mcpServerPath = settings.mcpServerPath
    }
}
