import SwiftUI

struct ConfirmDialog: View {
    let title: String
    let message: String
    let confirmText: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: JarvisTheme.Spacing.lg) {
            header
            messageText
            buttons
        }
        .padding(JarvisTheme.Spacing.xl)
        .frame(width: 300)
        .background(JarvisTheme.Colors.panel)
        .jarvisPanel(cornerRadius: JarvisTheme.CornerRadius.medium, borderOpacity: JarvisTheme.Opacity.strong)
    }

    private var header: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color.red.opacity(0.8))
            Text(title.uppercased())
                .font(JarvisTheme.Typography.label(11))
                .foregroundStyle(Color.red.opacity(0.8))
                .tracking(2)
            Spacer()
        }
    }

    private var messageText: some View {
        Text(message)
            .font(JarvisTheme.Typography.mono(12))
            .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.prominent))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var buttons: some View {
        HStack(spacing: JarvisTheme.Spacing.md) {
            Button("Cancel") {
                onCancel()
            }
            .font(JarvisTheme.Typography.mono(11))
            .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.prominent))
            .buttonStyle(.plain)

            Spacer()

            Button(confirmText) {
                onConfirm()
            }
            .font(JarvisTheme.Typography.label(10))
            .foregroundStyle(Color.red)
            .padding(.horizontal, JarvisTheme.Spacing.lg)
            .padding(.vertical, JarvisTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: JarvisTheme.CornerRadius.small)
                    .stroke(Color.red.opacity(JarvisTheme.Opacity.strong), lineWidth: 1)
            )
            .buttonStyle(.plain)
        }
    }
}
