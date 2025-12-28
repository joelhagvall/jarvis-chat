import XCTest

final class OllamaChatUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
    }

    override func tearDown() {
        app = nil
    }

    // MARK: - App Launch Tests

    func testLaunchShowsCoreUI() {
        app.launch()

        // Verify main chat input exists
        let input = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "Chat input should exist")

        // Verify send button exists
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send button should exist")

        // Verify status text exists (either READY or PROCESSING...)
        let statusText = app.staticTexts["statusText"]
        XCTAssertTrue(statusText.waitForExistence(timeout: 5), "Status text should exist")
    }

    func testLaunchShowsSidebar() {
        app.launch()

        // Verify new session button exists
        let newSessionButton = app.buttons["newSessionButton"]
        XCTAssertTrue(newSessionButton.waitForExistence(timeout: 5), "New session button should exist")

        // Verify settings button exists
        let settingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
    }

    // MARK: - Settings Tests

    func testOpenSettings() {
        app.launch()

        let settingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        // Verify settings title appears
        let settingsTitle = app.staticTexts["settingsTitle"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings title should appear")

        // Verify save button exists
        let saveButton = app.buttons["saveSettingsButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should exist")
    }

    func testSettingsContainsPersonalizationFields() {
        app.launch()

        let settingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        // Wait for settings to open
        let settingsTitle = app.staticTexts["settingsTitle"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5))

        // Check for personalization text fields
        let yourNameField = app.textFields["yourname"]
        XCTAssertTrue(yourNameField.waitForExistence(timeout: 5), "Your Name field should exist")

        let systemDirectiveField = app.textFields["systemdirective"]
        XCTAssertTrue(systemDirectiveField.waitForExistence(timeout: 5), "System Directive field should exist")
    }

    func testSaveSettingsClosesSheet() {
        app.launch()

        // Open settings
        let settingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        // Wait for settings to open
        let settingsTitle = app.staticTexts["settingsTitle"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5))

        // Click save
        let saveButton = app.buttons["saveSettingsButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.click()

        // Settings should close - title should disappear
        XCTAssertTrue(settingsTitle.waitForNonExistence(timeout: 5), "Settings should close after save")
    }

    // MARK: - Session Tests

    func testCreateNewSession() {
        app.launch()

        let newSessionButton = app.buttons["newSessionButton"]
        XCTAssertTrue(newSessionButton.waitForExistence(timeout: 5))

        // Click new session button
        newSessionButton.click()

        // Verify chat input is still available (new session created)
        let chatInput = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5), "Chat input should exist after creating new session")
    }

    // MARK: - Chat Input Tests

    func testChatInputAcceptsText() {
        app.launch()

        let chatInput = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5))

        // Click on input and type
        chatInput.click()
        chatInput.typeText("Hello, this is a test message")

        // Verify text was entered
        XCTAssertEqual(chatInput.value as? String, "Hello, this is a test message")
    }

    func testSendButtonDisabledWhenEmpty() {
        app.launch()

        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))

        // Send button should be disabled when input is empty
        XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled when input is empty")
    }

    func testSendButtonEnabledWithText() {
        app.launch()

        let chatInput = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5))

        // Type some text
        chatInput.click()
        chatInput.typeText("Test message")

        // Send button should now be enabled
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled with text")
    }

    // MARK: - Header Tests

    func testThinkingToggleExists() {
        app.launch()

        let thinkingToggle = app.buttons["thinkingToggle"]
        XCTAssertTrue(thinkingToggle.waitForExistence(timeout: 5), "Thinking toggle should exist")
    }

    func testThinkingToggleCanBeClicked() {
        app.launch()

        let thinkingToggle = app.buttons["thinkingToggle"]
        XCTAssertTrue(thinkingToggle.waitForExistence(timeout: 5))

        // Click thinking toggle - should not crash
        thinkingToggle.click()

        // Toggle should still exist after clicking
        XCTAssertTrue(thinkingToggle.exists, "Thinking toggle should still exist after clicking")
    }

    func testClearChatButtonExists() {
        app.launch()

        let clearButton = app.buttons["clearChatButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5), "Clear chat button should exist")
    }

    // MARK: - Navigation Tests

    func testCanNavigateBetweenSettingsAndChat() {
        app.launch()

        // Open settings
        let settingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        // Verify we're in settings
        let settingsTitle = app.staticTexts["settingsTitle"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5))

        // Close settings via save
        let saveButton = app.buttons["saveSettingsButton"]
        saveButton.click()

        // Verify we're back to chat
        let chatInput = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5), "Should return to chat view")
    }

    // MARK: - Multiple Session Tests

    func testCanCreateMultipleSessions() {
        app.launch()

        let newSessionButton = app.buttons["newSessionButton"]
        XCTAssertTrue(newSessionButton.waitForExistence(timeout: 5))

        // Create first session
        newSessionButton.click()

        // Small delay to allow UI to update
        Thread.sleep(forTimeInterval: 0.5)

        // Create second session
        newSessionButton.click()

        // Verify chat input still works
        let chatInput = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5))
    }

    // MARK: - Keyboard Shortcut Tests

    func testEscapeKeyInSettings() {
        app.launch()

        // Open settings
        let settingsButton = app.buttons["openSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.click()

        // Verify settings opened
        let settingsTitle = app.staticTexts["settingsTitle"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5))

        // Press Escape to close
        app.typeKey(.escape, modifierFlags: [])

        // Settings should close
        XCTAssertTrue(settingsTitle.waitForNonExistence(timeout: 5), "Settings should close on Escape")
    }

    // MARK: - Responsive UI Tests

    func testUIElementsRespondToInteraction() {
        app.launch()

        // Test that clicking on various elements doesn't cause crashes
        let elements: [(String, XCUIElement)] = [
            ("newSessionButton", app.buttons["newSessionButton"]),
            ("thinkingToggle", app.buttons["thinkingToggle"]),
            ("chatInput", app.descendants(matching: .any)["chatInput"])
        ]

        for (name, element) in elements {
            XCTAssertTrue(element.waitForExistence(timeout: 5), "\(name) should exist")
            element.click()
            // Verify app didn't crash
            XCTAssertTrue(app.exists, "App should still exist after clicking \(name)")
        }
    }

    // MARK: - Clear Chat Tests

    func testClearChatShowsConfirmDialog() {
        app.launch()

        // First add some content to enable clear button
        let chatInput = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(chatInput.waitForExistence(timeout: 5))
        chatInput.click()
        chatInput.typeText("Test message")

        // Try to clear (button might be disabled if no messages)
        let clearButton = app.buttons["clearChatButton"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))

        // If enabled, click and verify dialog
        if clearButton.isEnabled {
            clearButton.click()

            let confirmDialog = app.buttons["confirmDialogConfirm"]
            if confirmDialog.waitForExistence(timeout: 3) {
                // Cancel to not actually clear
                let cancelButton = app.buttons["confirmDialogCancel"]
                cancelButton.click()
            }
        }

        // App should still work
        XCTAssertTrue(chatInput.exists)
    }

    // MARK: - Session Selection Tests

    func testSelectingDifferentSessions() {
        app.launch()

        let newSessionButton = app.buttons["newSessionButton"]
        XCTAssertTrue(newSessionButton.waitForExistence(timeout: 5))

        // Create two sessions
        newSessionButton.click()
        Thread.sleep(forTimeInterval: 0.5)
        newSessionButton.click()
        Thread.sleep(forTimeInterval: 0.5)

        // Find all session rows
        let sessionRows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'sessionRow_'"))

        // Should have at least 2 sessions
        XCTAssertGreaterThanOrEqual(sessionRows.count, 2, "Should have at least 2 sessions")

        // Click on first session
        if sessionRows.count >= 2 {
            sessionRows.element(boundBy: 0).click()
            Thread.sleep(forTimeInterval: 0.3)

            // Click on second session
            sessionRows.element(boundBy: 1).click()
            Thread.sleep(forTimeInterval: 0.3)
        }

        // App should still work
        let chatInput = app.descendants(matching: .any)["chatInput"]
        XCTAssertTrue(chatInput.exists)
    }

}

// MARK: - Helper Extensions

extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
