import SwiftUI

/// A view that renders markdown text with proper styling
struct MarkdownText: View {
    let content: String
    let color: Color
    @State private var renderedContent: AttributedString = AttributedString("")

    init(_ content: String, color: Color = .white) {
        self.content = content
        self.color = color
    }

    var body: some View {
        Text(renderedContent)
            .textSelection(.enabled)
            .onAppear {
                renderedContent = render(content: content)
            }
            .onChange(of: content) { _, _ in
                renderedContent = render(content: content)
            }
    }

    private func render(content: String) -> AttributedString {
        do {
            var attributed = try AttributedString(markdown: content, options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))

            // Apply base color to entire string
            attributed.foregroundColor = color

            return attributed
        } catch {
            // Fallback to plain text if markdown parsing fails
            var plain = AttributedString(content)
            plain.foregroundColor = color
            return plain
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        MarkdownText("This is **bold** and *italic* text", color: .white)
        MarkdownText("Here's some `inline code` example", color: .white)
        MarkdownText("Regular text without formatting", color: .white)
    }
    .padding()
    .background(JarvisTheme.Colors.dark)
}
