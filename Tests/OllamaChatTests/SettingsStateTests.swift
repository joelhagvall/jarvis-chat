import XCTest
@testable import OllamaChat

final class SettingsStateTests: XCTestCase {
    @MainActor
    func testApplyDefaultsForOptionalSettings() async {
        let entity = AppSettingsEntity()
        entity.thinkingEnabled = nil
        entity.mcpEnabled = nil

        let state = SettingsState()
        state.apply(from: entity)

        XCTAssertTrue(state.thinkingEnabled)
        XCTAssertTrue(state.mcpEnabled)
    }
}
