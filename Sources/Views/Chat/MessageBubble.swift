import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var isUser: Bool { message.role == "user" }

    private var formattedTime: String {
        MessageBubble.timeFormatter.string(from: message.timestamp)
    }

    var body: some View {
        HStack(alignment: .top, spacing: JarvisTheme.Spacing.md) {
            if !isUser {
                ArcReactorView(size: 28)
            }

            messageContent

            if isUser {
                userAvatar
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    // MARK: - Message Content

    private var messageContent: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: JarvisTheme.Spacing.sm) {
            roleLabel
            toolBadge
            thinkingBlock
            contentBubble
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    // MARK: - Role Label

    private var roleLabel: some View {
        HStack(spacing: JarvisTheme.Spacing.sm) {
            Text(isUser ? "USER" : "J.A.R.V.I.S")
                .font(JarvisTheme.Typography.label(9, tracking: 2))
                .foregroundStyle((isUser ? JarvisTheme.Colors.gold : JarvisTheme.Colors.blue).opacity(JarvisTheme.Opacity.solid))

            Text(formattedTime)
                .font(JarvisTheme.Typography.mono(9))
                .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.medium))
        }
    }

    // MARK: - Tool Badge

    @ViewBuilder
    private var toolBadge: some View {
        if let toolCall = message.toolCall {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .font(.system(size: 10))
                Text(toolCall.name.uppercased())
                    .font(JarvisTheme.Typography.label(10, tracking: 1))
            }
            .foregroundStyle(JarvisTheme.Colors.blue)
            .jarvisCapsule()
        }
    }

    // MARK: - Thinking Block

    @ViewBuilder
    private var thinkingBlock: some View {
        if let thinking = message.thinking, !thinking.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10))
                    Text("ANALYSIS LOG")
                        .font(JarvisTheme.Typography.label(10, tracking: 1))
                }
                .foregroundStyle(JarvisTheme.Colors.blue.opacity(0.7))

                // Scrollable thinking content
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(thinking)
                            .font(JarvisTheme.Typography.mono(11))
                            .foregroundStyle(JarvisTheme.Colors.blue.opacity(0.6))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("thinking_end")
                    }
                    .frame(maxHeight: 120)
                    .onChange(of: thinking) { _, _ in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("thinking_end", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo("thinking_end", anchor: .bottom)
                    }
                }
            }
            .padding(10)
            .jarvisPanel(
                cornerRadius: JarvisTheme.CornerRadius.medium,
                borderColor: JarvisTheme.Colors.blue,
                borderOpacity: JarvisTheme.Opacity.light,
                fillColor: JarvisTheme.Colors.blue.opacity(0.03)
            )
        }
    }

    // MARK: - Content Bubble

    @ViewBuilder
    private var contentBubble: some View {
        if !message.content.isEmpty {
            MarkdownText(
                message.content,
                color: isUser ? .white : .white.opacity(0.9)
            )
            .font(JarvisTheme.Typography.body())
            .padding(14)
            .jarvisPanel(
                borderColor: isUser ? JarvisTheme.Colors.gold : JarvisTheme.Colors.blue,
                borderOpacity: isUser ? JarvisTheme.Opacity.medium : JarvisTheme.Opacity.light,
                fillColor: isUser ? JarvisTheme.Colors.gold.opacity(0.15) : JarvisTheme.Colors.panel
            )
        }
    }

    // MARK: - User Avatar

    private var userAvatar: some View {
        Circle()
            .fill(JarvisTheme.Colors.gold.opacity(JarvisTheme.Opacity.light))
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(JarvisTheme.Colors.gold)
            )
            .overlay(
                Circle()
                    .stroke(JarvisTheme.Colors.gold.opacity(0.4), lineWidth: 1)
            )
    }

}
