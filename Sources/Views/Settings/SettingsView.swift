import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            JarvisTheme.Colors.dark.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                HexDivider()
                settingsContent
            }
        }
        .frame(minWidth: 450, minHeight: 400)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(JarvisTheme.Colors.blue)
                Text("CONFIGURATION")
                    .font(JarvisTheme.Typography.title())
                    .foregroundStyle(JarvisTheme.Colors.blue)
                    .tracking(3)
                    .accessibilityIdentifier("settingsTitle")
            }

            Spacer()

            JarvisBorderedButton(text: "SAVE") {
                viewModel.saveSettings()
                dismiss()
            }
            .accessibilityIdentifier("saveSettingsButton")
        }
        .padding(JarvisTheme.Spacing.xl)
    }

    // MARK: - Settings Content

    private var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JarvisTheme.Spacing.xxl) {
                PersonalizationSection(
                    userName: $viewModel.settings.userName,
                    systemPrompt: $viewModel.settings.systemPrompt
                )
                HexDivider()
                LanguageSection(language: $viewModel.settings.language)
                HexDivider()
                MCPSection(viewModel: viewModel)
                HexDivider()
                SystemInfoSection()
            }
            .padding(JarvisTheme.Spacing.xl)
        }
    }
}
