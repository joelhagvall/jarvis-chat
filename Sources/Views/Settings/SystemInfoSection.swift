import SwiftUI
import AppKit

struct SystemInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: JarvisTheme.Spacing.md) {
            SectionLabel(text: "SYSTEM INFO")

            InfoRow(label: "Storage Format", value: "SwiftData")
            InfoRow(label: "Version", value: "1.0.0")

            JarvisIconButton(
                icon: "folder",
                text: "Open Storage Directory"
            ) {
                openStorageDirectory()
            }
            .padding(.top, JarvisTheme.Spacing.xs)
        }
    }

    private func openStorageDirectory() {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        NSWorkspace.shared.open(url)
    }
}

/// Reusable info row for key-value display
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(JarvisTheme.Typography.mono(12))
                .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.prominent))
            Spacer()
            Text(value)
                .font(JarvisTheme.Typography.mono(12))
                .foregroundStyle(JarvisTheme.Colors.blue)
        }
    }
}
