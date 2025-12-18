import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MCPSection: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: JarvisTheme.Spacing.md) {
            SectionLabel(text: "MCP SERVER")

            serverPathField
            enableToggle
            connectionStatus
            toolsList
            errorMessage
            refreshButton
        }
    }

    // MARK: - Subviews

    private var serverPathField: some View {
        LabeledTextFieldWithAccessory(
            label: "Server Path",
            placeholder: "~/path/to/server.js",
            text: $viewModel.settings.mcpServerPath
        ) {
            Button(action: selectServerFile) {
                Image(systemName: "folder")
                    .foregroundStyle(JarvisTheme.Colors.blue)
            }
            .buttonStyle(.plain)
        }
    }

    private var enableToggle: some View {
        Toggle(isOn: $viewModel.settings.mcpEnabled) {
            Text("Enable MCP Tools")
                .font(JarvisTheme.Typography.mono(12))
                .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.prominent))
        }
        .toggleStyle(.switch)
        .tint(JarvisTheme.Colors.blue)
        .onChange(of: viewModel.settings.mcpEnabled) { _, enabled in
            Task {
                if enabled {
                    await viewModel.connectMCP()
                } else {
                    await viewModel.disconnectMCP()
                }
            }
        }
    }

    private var connectionStatus: some View {
        StatusBadge(
            isActive: viewModel.mcp.isConnected,
            activeText: "Connected",
            inactiveText: "Disconnected"
        )
    }

    @ViewBuilder
    private var toolsList: some View {
        if viewModel.mcp.isConnected && !viewModel.mcp.toolNames.isEmpty {
            VStack(alignment: .leading, spacing: JarvisTheme.Spacing.xs) {
                Text("\(viewModel.mcp.toolCount) tools")
                    .font(JarvisTheme.Typography.mono(10))
                    .foregroundStyle(Color.white.opacity(JarvisTheme.Opacity.medium))

                FlowLayout(spacing: 6) {
                    ForEach(viewModel.mcp.toolNames, id: \.self) { name in
                        ToolBadge(name: name)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var errorMessage: some View {
        if let error = viewModel.mcp.error {
            Text(error)
                .font(JarvisTheme.Typography.mono(10))
                .foregroundStyle(Color.red.opacity(0.8))
                .lineLimit(4)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var refreshButton: some View {
        if viewModel.mcp.isConnected {
            JarvisIconButton(
                icon: "arrow.clockwise",
                text: "Refresh Tools"
            ) {
                Task { await viewModel.refreshMCPTools() }
            }
        }
    }

    // MARK: - Actions

    private func selectServerFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.javaScript, .item]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select MCP server JavaScript file"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.settings.mcpServerPath = url.path
        }
    }
}
