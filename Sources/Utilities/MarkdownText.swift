import SwiftUI

/// A view that renders markdown text with proper styling
struct MarkdownText: View {
    let content: String
    let color: Color

    init(_ content: String, color: Color = .white) {
        self.content = content
        self.color = color
    }

    var body: some View {
        Text(attributedContent)
            .textSelection(.enabled)
    }

    private var attributedContent: AttributedString {
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
