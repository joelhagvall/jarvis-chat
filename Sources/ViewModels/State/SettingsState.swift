import Foundation
import SwiftUI

/// Observable state for user settings
@MainActor
final class SettingsState: ObservableObject {
    @Published var userName: String = ""
    @Published var systemPrompt: String = ""
    @Published var language: String = "auto"
    @Published var thinkingEnabled: Bool = false
    @Published var mcpEnabled: Bool = true
    @Published var mcpServerPath: String = ""

    func apply(from settings: AppSettingsEntity) {
        userName = settings.userName
        systemPrompt = settings.systemPrompt
        language = settings.language
        mcpServerPath = settings.mcpServerPath
    }
}
