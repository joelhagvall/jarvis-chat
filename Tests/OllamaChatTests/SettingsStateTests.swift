import XCTest
import SwiftData
@testable import OllamaChat

final class SettingsStateTests: XCTestCase {
    @MainActor
    func testApplyDefaultsForOptionalSettings() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let entity = AppSettingsEntity()
        context.insert(entity)

        entity.thinkingEnabled = nil
        entity.mcpEnabled = nil

        let state = SettingsState()
        state.apply(from: entity)

        XCTAssertTrue(state.thinkingEnabled)
        XCTAssertTrue(state.mcpEnabled)
    }
}
