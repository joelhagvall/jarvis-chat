import Foundation

/// Coordinates MCP connection and tool operations
/// Provides a simplified interface for the view model
@MainActor
final class MCPCoordinator: ObservableObject {
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var toolCount: Int = 0
    @Published private(set) var toolNames: [String] = []
    @Published private(set) var error: String?

    private let toolRegistry = ToolRegistry.shared

    var ollamaTools: [OllamaTool]? {
        toolRegistry.ollamaTools
    }

    // MARK: - Connection

    func connect(serverPath: String?) async {
        error = nil
        do {
            let path = serverPath?.isEmpty == false ? serverPath : nil
            try await toolRegistry.connectMCP(serverPath: path)
            isConnected = await toolRegistry.isMCPConnected
            toolNames = toolRegistry.mcpToolNames
            toolCount = toolNames.count
        } catch {
            self.error = error.localizedDescription
            isConnected = false
            toolCount = 0
        }
    }

    func disconnect() async {
        await toolRegistry.disconnectMCP()
        isConnected = false
        toolCount = 0
        toolNames = []
    }

    func refreshTools() async {
        guard isConnected else { return }
        do {
            try await toolRegistry.refreshMCPTools()
            toolNames = toolRegistry.mcpToolNames
            toolCount = toolNames.count
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Tool Execution

    func execute(name: String, arguments: [String: Any]) async -> String {
        let stringArgs = arguments.compactMapValues { $0 as? String }
        return await toolRegistry.execute(name: name, arguments: stringArgs)
    }
}
