import SwiftUI

struct PersonalizationSection: View {
    @Binding var userName: String
    @Binding var systemPrompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: JarvisTheme.Spacing.md) {
            SectionLabel(text: "PERSONALIZATION")

            LabeledTextField(
                label: "Your Name",
                placeholder: "Enter your name...",
                text: $userName
            )

            LabeledTextField(
                label: "System Directive",
                placeholder: "Enter system prompt...",
                text: $systemPrompt,
                axis: .vertical,
                minHeight: 100,
                cornerRadius: JarvisTheme.CornerRadius.medium
            )
        }
    }
}
