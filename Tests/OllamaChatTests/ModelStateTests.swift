import XCTest
@testable import OllamaChat

final class ModelStateTests: XCTestCase {
    @MainActor
    func testSetModelsAssignsFirstWhenEmpty() async {
        let state = ModelState()
        let models = [OllamaModel(name: "m1", size: nil), OllamaModel(name: "m2", size: nil)]

        state.setModels(models)

        XCTAssertEqual(state.selectedModel, "m1")
        XCTAssertEqual(state.availableModels.count, 2)
    }

    @MainActor
    func testSetModelsKeepsExistingSelection() async {
        let state = ModelState()
        state.selectedModel = "m2"
        let models = [OllamaModel(name: "m1", size: nil), OllamaModel(name: "m2", size: nil)]

        state.setModels(models)

        XCTAssertEqual(state.selectedModel, "m2")
    }

    @MainActor
    func testSetModelsResetsWhenMissing() async {
        let state = ModelState()
        state.selectedModel = "missing"
        let models = [OllamaModel(name: "m1", size: nil)]

        state.setModels(models)

        XCTAssertEqual(state.selectedModel, "m1")
    }
}
