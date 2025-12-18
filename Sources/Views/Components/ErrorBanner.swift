import SwiftUI

struct ErrorBanner: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: JarvisTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.red)

            Text(error)
                .font(JarvisTheme.Typography.mono(12))
                .foregroundStyle(Color.red.opacity(0.9))

            Spacer()

            Button("RETRY") {
                onRetry()
            }
            .font(JarvisTheme.Typography.label(10))
            .foregroundStyle(JarvisTheme.Colors.blue)
            .buttonStyle(.plain)
        }
        .padding(JarvisTheme.Spacing.md)
        .jarvisPanel(
            cornerRadius: JarvisTheme.CornerRadius.medium,
            borderColor: .red,
            borderOpacity: JarvisTheme.Opacity.medium,
            fillColor: Color.red.opacity(JarvisTheme.Opacity.subtle)
        )
        .padding(.horizontal, JarvisTheme.Spacing.lg)
        .padding(.top, JarvisTheme.Spacing.sm)
    }
}

#Preview {
    ErrorBanner(error: "Ollama server not available") {
        print("Retry tapped")
    }
    .background(JarvisTheme.Colors.dark)
}
