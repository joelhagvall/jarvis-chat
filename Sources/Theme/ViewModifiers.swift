import SwiftUI

// MARK: - Panel Style Modifier

struct JarvisPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = JarvisTheme.CornerRadius.large
    var borderColor: Color = JarvisTheme.Colors.blue
    var borderOpacity: Double = JarvisTheme.Opacity.light
    var fillColor: Color = JarvisTheme.Colors.panel
    var showGlow: Bool = false
    var glowRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor.opacity(borderOpacity), lineWidth: 1)
                    )
                    .shadow(color: showGlow ? borderColor.opacity(JarvisTheme.Opacity.light) : .clear, radius: glowRadius)
            )
    }
}

// MARK: - Capsule Button Style Modifier

struct JarvisCapsuleModifier: ViewModifier {
    var color: Color = JarvisTheme.Colors.blue
    var filled: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, JarvisTheme.Spacing.md)
            .padding(.vertical, JarvisTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(filled ? color.opacity(JarvisTheme.Opacity.subtle) : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(JarvisTheme.Opacity.medium), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Label Style Modifier

struct JarvisLabelModifier: ViewModifier {
    var color: Color = JarvisTheme.Colors.blue
    var opacity: Double = JarvisTheme.Opacity.solid

    func body(content: Content) -> some View {
        content
            .font(JarvisTheme.Typography.label())
            .foregroundStyle(color.opacity(opacity))
            .tracking(2)
    }
}

// MARK: - Text Field Style Modifier

struct JarvisTextFieldModifier: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(JarvisTheme.Typography.mono())
            .foregroundStyle(Color.white)
            .padding(.horizontal, JarvisTheme.Spacing.md)
            .padding(.vertical, JarvisTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: JarvisTheme.CornerRadius.large)
                    .fill(JarvisTheme.Colors.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: JarvisTheme.CornerRadius.large)
                            .stroke(
                                JarvisTheme.Colors.blue.opacity(isFocused ? JarvisTheme.Opacity.prominent : JarvisTheme.Opacity.light),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: isFocused ? JarvisTheme.Colors.glow.opacity(JarvisTheme.Opacity.light) : .clear, radius: 8)
            )
    }
}

// MARK: - View Extensions

extension View {
    func jarvisPanel(
        cornerRadius: CGFloat = JarvisTheme.CornerRadius.large,
        borderColor: Color = JarvisTheme.Colors.blue,
        borderOpacity: Double = JarvisTheme.Opacity.light,
        fillColor: Color = JarvisTheme.Colors.panel,
        showGlow: Bool = false
    ) -> some View {
        modifier(JarvisPanelModifier(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderOpacity: borderOpacity,
            fillColor: fillColor,
            showGlow: showGlow
        ))
    }

    func jarvisCapsule(color: Color = JarvisTheme.Colors.blue, filled: Bool = false) -> some View {
        modifier(JarvisCapsuleModifier(color: color, filled: filled))
    }

    func jarvisLabel(color: Color = JarvisTheme.Colors.blue, opacity: Double = JarvisTheme.Opacity.solid) -> some View {
        modifier(JarvisLabelModifier(color: color, opacity: opacity))
    }

    func jarvisTextField(isFocused: Bool = false) -> some View {
        modifier(JarvisTextFieldModifier(isFocused: isFocused))
    }
}
