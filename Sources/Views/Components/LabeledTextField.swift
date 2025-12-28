import SwiftUI

/// Reusable labeled text field component with Jarvis styling
struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var minHeight: CGFloat? = nil
    var fontSize: CGFloat = 13
    var cornerRadius: CGFloat = JarvisTheme.CornerRadius.small
    var accessibilityId: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: JarvisTheme.Spacing.xs) {
            Text(label)
                .font(JarvisTheme.Typography.mono(11))
                .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.medium))

            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.plain)
                .font(JarvisTheme.Typography.mono(fontSize))
                .foregroundStyle(Color.white)
                .padding(axis == .vertical ? JarvisTheme.Spacing.md : JarvisTheme.Spacing.sm)
                .frame(minHeight: minHeight, alignment: .topLeading)
                .jarvisPanel(
                    cornerRadius: cornerRadius,
                    borderOpacity: JarvisTheme.Opacity.medium
                )
                .accessibilityIdentifier(accessibilityId ?? label.lowercased().replacingOccurrences(of: " ", with: ""))
        }
    }
}

/// Labeled text field with an accessory button (e.g., folder picker)
struct LabeledTextFieldWithAccessory<Accessory: View>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var fontSize: CGFloat = 11
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: JarvisTheme.Spacing.xs) {
            Text(label)
                .font(JarvisTheme.Typography.mono(11))
                .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.medium))

            HStack(spacing: JarvisTheme.Spacing.sm) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(JarvisTheme.Typography.mono(fontSize))
                    .foregroundStyle(Color.white)
                    .padding(JarvisTheme.Spacing.sm)
                    .jarvisPanel(
                        cornerRadius: JarvisTheme.CornerRadius.small,
                        borderOpacity: JarvisTheme.Opacity.medium
                    )

                accessory()
            }
        }
    }
}
