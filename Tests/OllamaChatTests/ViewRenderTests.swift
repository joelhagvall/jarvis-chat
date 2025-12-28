import AppKit
import SwiftUI
import XCTest
@testable import OllamaChat

@MainActor
final class ViewRenderTests: XCTestCase {
    func testChatViewRenders() {
        let viewModel = ChatViewModel()
        viewModel.chat.messages = [
            ChatMessage(role: "user", content: "Hi"),
            ChatMessage(role: "assistant", content: "Hello")
        ]
        let view = ChatView(viewModel: viewModel, confirmAction: .constant(nil))

        XCTAssertNotNil(render(view))
    }

    func testSidebarViewRenders() {
        let viewModel = ChatViewModel()
        let view = SidebarView(
            viewModel: viewModel,
            showSettings: .constant(false),
            confirmAction: .constant(nil)
        )

        XCTAssertNotNil(render(view))
    }

    func testSettingsViewRenders() {
        let viewModel = ChatViewModel()
        let view = SettingsView(viewModel: viewModel)

        XCTAssertNotNil(render(view, size: CGSize(width: 600, height: 500)))
    }

    private func render<V: View>(_ view: V, size: CGSize = CGSize(width: 900, height: 600)) -> NSImage? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 1
        return renderer.nsImage
    }
}
