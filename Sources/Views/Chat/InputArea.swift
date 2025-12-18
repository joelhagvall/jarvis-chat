import SwiftUI

struct InputArea: View {
    @ObservedObject var viewModel: ChatViewModel
    var isMessageFieldFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .bottom, spacing: JarvisTheme.Spacing.md) {
            inputField
            sendButton
        }
        .padding(.horizontal, JarvisTheme.Spacing.lg)
        .padding(.vertical, 10)
        .background(inputBackground)
    }

    // MARK: - Input Field

    private var inputField: some View {
        TextField("Enter command...", text: $viewModel.chat.inputText, axis: .vertical)
            .jarvisTextField(isFocused: isMessageFieldFocused.wrappedValue)
            .frame(minHeight: 32, maxHeight: 80)
            .focused(isMessageFieldFocused)
            .onSubmit {
                sendMessage()
            }
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button(action: sendMessage) {
            ZStack {
                Circle()
                    .fill(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.light))
                    .frame(width: 32, height: 32)

                Circle()
                    .stroke(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.prominent), lineWidth: 1)
                    .frame(width: 32, height: 32)

                Image(systemName: viewModel.chat.isLoading ? "stop.fill" : "arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(JarvisTheme.Colors.blue)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
    }

    // MARK: - Background

    private var inputBackground: some View {
        JarvisTheme.Colors.panel
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.light)),
                alignment: .top
            )
    }

    // MARK: - Helpers

    private var isDisabled: Bool {
        viewModel.chat.inputText.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.chat.isLoading
    }

    private func sendMessage() {
        guard !viewModel.chat.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.chat.isLoading else { return }
        Task { await viewModel.sendMessage() }
    }
}
