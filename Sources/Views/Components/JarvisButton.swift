import SwiftUI

/// Reusable button with icon and text in Jarvis style
struct JarvisIconButton: View {
    let icon: String
    let text: String
    var color: Color = JarvisTheme.Colors.blue
    var fontSize: CGFloat = 11
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: JarvisTheme.Spacing.sm) {
                Image(systemName: icon)
                Text(text)
            }
            .font(JarvisTheme.Typography.mono(fontSize))
            .foregroundStyle(color.opacity(JarvisTheme.Opacity.solid))
        }
        .buttonStyle(.plain)
    }
}

/// Bordered button with label styling
struct JarvisBorderedButton: View {
    let text: String
    var color: Color = JarvisTheme.Colors.blue
    var fontSize: CGFloat = 12
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(JarvisTheme.Typography.label(fontSize))
                .foregroundStyle(color)
                .padding(.horizontal, JarvisTheme.Spacing.lg)
                .padding(.vertical, JarvisTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: JarvisTheme.CornerRadius.small)
                        .stroke(color.opacity(JarvisTheme.Opacity.strong), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Section label with consistent Jarvis styling
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .jarvisLabel(opacity: JarvisTheme.Opacity.solid)
    }
}
