import SwiftUI

struct LanguageSection: View {
    @Binding var language: String

    private let languages: [(label: String, code: String)] = [
        ("Auto-detect", "auto"),
        ("English", "en"),
        ("Swedish", "sv"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("German", "de")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: JarvisTheme.Spacing.sm) {
            SectionLabel(text: "LANGUAGE PROTOCOL")

            Picker("", selection: $language) {
                ForEach(languages, id: \.code) { lang in
                    Text(lang.label).tag(lang.code)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
