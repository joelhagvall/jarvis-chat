import SwiftUI

struct ChatHeader: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var confirmAction: ConfirmAction?

    var body: some View {
        HStack(spacing: JarvisTheme.Spacing.lg) {
            statusSection
            Spacer()
            thinkingToggle
            modelSelector
            clearButton
        }
        .padding(.horizontal, JarvisTheme.Spacing.xl)
        .padding(.vertical, JarvisTheme.Spacing.lg)
        .padding(.top, 28)
        .background(headerBackground)
        .overlay(bottomBorder, alignment: .bottom)
    }

    // MARK: - Status Section

    private var statusSection: some View {
        HStack(spacing: JarvisTheme.Spacing.md) {
            ArcReactorView(size: 32, animated: viewModel.chat.isLoading)

            VStack(alignment: .leading, spacing: 2) {
                Text("NEURAL INTERFACE")
                    .font(JarvisTheme.Typography.label(10, tracking: 3))
                    .foregroundStyle(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.prominent))

                Text(viewModel.chat.isLoading ? "PROCESSING..." : "READY")
                    .font(JarvisTheme.Typography.heading())
                    .foregroundStyle(viewModel.chat.isLoading ? JarvisTheme.Colors.gold : JarvisTheme.Colors.blue)
                    .tracking(2)
                    .accessibilityIdentifier("statusText")
            }
        }
    }

    // MARK: - Thinking Toggle

    private var thinkingToggle: some View {
        Button(action: {
            viewModel.settings.thinkingEnabled.toggle()
            viewModel.saveSettings()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12))
                Text("THINK")
                    .font(JarvisTheme.Typography.label(9, tracking: 1))
            }
            .foregroundStyle(viewModel.settings.thinkingEnabled ? JarvisTheme.Colors.blue : JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.strong))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(viewModel.settings.thinkingEnabled ? JarvisTheme.Colors.blue.opacity(0.15) : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(
                                viewModel.settings.thinkingEnabled ? JarvisTheme.Colors.blue.opacity(0.5) : JarvisTheme.Colors.blue.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("thinkingToggle")
        .help("Enable thinking mode (for Qwen3, DeepSeek, etc.)")
    }

    // MARK: - Model Selector

    @ViewBuilder
    private var modelSelector: some View {
        if !viewModel.model.availableModels.isEmpty {
            HStack(spacing: JarvisTheme.Spacing.sm) {
                Text("MODEL")
                    .font(JarvisTheme.Typography.label(9, tracking: 2))
                    .foregroundStyle(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.strong))

                Picker("", selection: $viewModel.model.selectedModel) {
                    ForEach(viewModel.model.availableModels) { model in
                        Text(model.name)
                            .font(JarvisTheme.Typography.mono(11))
                            .tag(model.name)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)
                .onChange(of: viewModel.model.selectedModel) { _, _ in
                    viewModel.saveSettings()
                }
            }
        }
    }

    // MARK: - Clear Button

    private var clearButton: some View {
        Button(action: requestClearChat) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.prominent))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("clearChatButton")
        .help("Clear session")
        .disabled(viewModel.chat.messages.isEmpty)
        .opacity(viewModel.chat.messages.isEmpty ? 0.3 : 1)
    }

    // MARK: - Background

    private var headerBackground: some View {
        JarvisTheme.Colors.panel
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.subtle), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }

    private var bottomBorder: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.medium))
    }

    // MARK: - Actions

    private func requestClearChat() {
        confirmAction = ConfirmAction(
            title: "Clear Chat",
            message: "Are you sure you want to clear all messages in this session?",
            confirmText: "CLEAR",
            onConfirm: { viewModel.clearChat() }
        )
    }
}
