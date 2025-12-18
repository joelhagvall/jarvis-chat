import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var showSettings: Bool
    @Binding var confirmAction: ConfirmAction?

    var body: some View {
        VStack(spacing: 0) {
            header
            newChatButton
            HexDivider()
            sessionsList
            HexDivider()
            settingsButton
        }
        .frame(minWidth: 220)
        .background(JarvisTheme.Colors.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            ArcReactorView(size: 24)
            Text("J.A.R.V.I.S")
                .font(JarvisTheme.Typography.title())
                .foregroundStyle(JarvisTheme.Colors.blue)
                .tracking(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, JarvisTheme.Spacing.lg)
        .padding(.top, 28)
        .background(JarvisTheme.Colors.dark)
    }

    // MARK: - New Chat Button

    private var newChatButton: some View {
        Button(action: { viewModel.newChat() }) {
            HStack(spacing: JarvisTheme.Spacing.sm) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 14, weight: .light))
                Text("NEW SESSION")
                    .font(JarvisTheme.Typography.label(11))
                    .tracking(2)
            }
            .foregroundStyle(JarvisTheme.Colors.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, JarvisTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: JarvisTheme.CornerRadius.small)
                    .stroke(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.strong), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, JarvisTheme.Spacing.md)
        .padding(.vertical, JarvisTheme.Spacing.sm)
    }

    // MARK: - Sessions List

    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: JarvisTheme.Spacing.xs) {
                ForEach(viewModel.session.sessions) { session in
                    SessionRow(
                        session: session,
                        isSelected: viewModel.session.currentSession?.id == session.id,
                        onDelete: { requestDeleteSession(session) },
                        onRename: { newTitle in viewModel.renameSession(session, title: newTitle) }
                    )
                    .onTapGesture {
                        viewModel.selectSession(session)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            requestDeleteSession(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(JarvisTheme.Spacing.sm)
        }
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button(action: { showSettings = true }) {
            HStack(spacing: JarvisTheme.Spacing.sm) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .light))
                Text("CONFIGURE")
                    .font(JarvisTheme.Typography.label(10))
                    .tracking(2)
            }
            .foregroundStyle(JarvisTheme.Colors.blue.opacity(JarvisTheme.Opacity.solid))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, JarvisTheme.Spacing.md)
        .padding(.bottom, JarvisTheme.Spacing.sm)
    }

    // MARK: - Actions

    private func requestDeleteSession(_ session: ChatSession) {
        confirmAction = ConfirmAction(
            title: "Delete Session",
            message: "Are you sure you want to delete \"\(session.title)\"? This cannot be undone.",
            confirmText: "DELETE",
            onConfirm: { viewModel.deleteSession(session) }
        )
    }
}
