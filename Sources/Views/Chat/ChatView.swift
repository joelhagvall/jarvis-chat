import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var confirmAction: ConfirmAction?
    @FocusState private var isMessageFieldFocused: Bool

    var body: some View {
        ZStack {
            JarvisTheme.Colors.dark
                .ignoresSafeArea()

            GridBackground()

            VStack(spacing: 0) {
                ChatHeader(viewModel: viewModel, confirmAction: $confirmAction)

                if let error = viewModel.chat.errorMessage {
                    ErrorBanner(error: error) {
                        Task { await viewModel.loadModels() }
                    }
                }

                messagesScrollView

                InputArea(
                    viewModel: viewModel,
                    isMessageFieldFocused: $isMessageFieldFocused
                )
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            isMessageFieldFocused = true
        }
        .onChange(of: viewModel.chat.isLoading) { _, isLoading in
            if !isLoading {
                isMessageFieldFocused = true
            }
        }
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: JarvisTheme.Spacing.lg) {
                    ForEach(viewModel.chat.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    streamingBubble
                    statusIndicators

                    Color.clear
                        .frame(height: 1)
                        .id("bottom_anchor")
                }
                .padding(.horizontal, JarvisTheme.Spacing.xxl)
                .padding(.vertical, JarvisTheme.Spacing.xl)
            }
            .onChange(of: viewModel.chat.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.chat.messages.last?.content) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.chat.messages.last?.thinking) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.chat.currentStreamingText) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.chat.currentStreamingThinking) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.chat.isThinking) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
    }

    // MARK: - Streaming Bubble

    @ViewBuilder
    private var streamingBubble: some View {
        if !viewModel.chat.currentStreamingText.isEmpty || !viewModel.chat.currentStreamingThinking.isEmpty {
            MessageBubble(message: ChatMessage(
                id: UUID(),
                role: "assistant",
                content: viewModel.chat.currentStreamingText,
                thinking: viewModel.chat.currentStreamingThinking.isEmpty ? nil : viewModel.chat.currentStreamingThinking,
                timestamp: Date()
            ))
            .id("streaming_message")
        }
    }

    // MARK: - Status Indicators

    @ViewBuilder
    private var statusIndicators: some View {
        if viewModel.chat.isThinking && viewModel.chat.currentStreamingText.isEmpty {
            StatusIndicator(text: "ANALYZING", color: JarvisTheme.Colors.gold)
        }

        if let toolName = viewModel.chat.currentToolName {
            StatusIndicator(text: "EXECUTING: \(toolName.uppercased())", color: JarvisTheme.Colors.blue)
        }
    }

    // MARK: - Scroll Helper

    private func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo("bottom_anchor", anchor: .bottom)
    }
}
