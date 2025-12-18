import Foundation
import SwiftUI

/// Observable state for model selection
@MainActor
final class ModelState: ObservableObject {
    @Published var selectedModel: String = ""
    @Published var availableModels: [OllamaModel] = []

    func setModels(_ models: [OllamaModel]) {
        availableModels = models
        if selectedModel.isEmpty, let first = models.first {
            selectedModel = first.name
        }
    }

    func apply(from settings: AppSettingsEntity) {
        if !settings.selectedModel.isEmpty {
            selectedModel = settings.selectedModel
        }
    }
}
