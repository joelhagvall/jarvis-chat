import Foundation
import SwiftData

@Model
final class AppSettingsEntity {
    @Attribute(.unique) var id: String
    var userName: String
    var systemPrompt: String
    var language: String
    var thinkingEnabled: Bool?
    var mcpEnabled: Bool?
    var selectedModel: String
    var mcpServerPath: String

    init(
        id: String = "default",
        userName: String = "",
        systemPrompt: String = "",
        language: String = "auto",
        thinkingEnabled: Bool = true,
        mcpEnabled: Bool = true,
        selectedModel: String = "",
        mcpServerPath: String = ""
    ) {
        self.id = id
        self.userName = userName
        self.systemPrompt = systemPrompt
        self.language = language
        self.thinkingEnabled = thinkingEnabled
        self.mcpEnabled = mcpEnabled
        self.selectedModel = selectedModel
        self.mcpServerPath = mcpServerPath
    }
}
