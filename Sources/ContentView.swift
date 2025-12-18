import SwiftUI
import SwiftData
import AppKit

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showSettings = false
    @State private var confirmAction: ConfirmAction?

    var body: some View {
        ZStack {
            NavigationSplitView {
                SidebarView(viewModel: viewModel, showSettings: $showSettings, confirmAction: $confirmAction)
            } detail: {
                ChatView(viewModel: viewModel, confirmAction: $confirmAction)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.mainWindow?.makeKeyAndOrderFront(nil)
                viewModel.setModelContext(modelContext)
            }
            .task {
                await viewModel.loadModels()
            }

            // Global centered confirm dialog
            if let action = confirmAction {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { confirmAction = nil }

                ConfirmDialog(
                    title: action.title,
                    message: action.message,
                    confirmText: action.confirmText,
                    onConfirm: {
                        action.onConfirm()
                        confirmAction = nil
                    },
                    onCancel: { confirmAction = nil }
                )
            }
        }
    }
}

// MARK: - Confirm Action Model

struct ConfirmAction {
    let title: String
    let message: String
    let confirmText: String
    let onConfirm: () -> Void
}
