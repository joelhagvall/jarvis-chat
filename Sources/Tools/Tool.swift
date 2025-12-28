import Foundation

// MARK: - Tool Protocol

protocol Tool {
    var name: String { get }
    var description: String { get }
    var parameters: OllamaParameters { get }

    func execute(arguments: [String: String]) async -> String
}

// MARK: - Tool Registry

@MainActor
final class ToolRegistry {
    static let shared = ToolRegistry()

    private let localTools: [Tool] = []

    private var mcpTools: [MCPTool] = []
    private let mcpService = MCPService()

    var isMCPConnected: Bool {
        get async { await mcpService.isConnected }
    }

    // MARK: - MCP Connection

    func connectMCP(serverPath: String? = nil) async throws {
        try await mcpService.connect(customPath: serverPath)
        mcpTools = await mcpService.tools
    }

    func disconnectMCP() async {
        await mcpService.disconnect()
        mcpTools = []
    }

    func refreshMCPTools() async throws {
        try await mcpService.refreshTools()
        mcpTools = await mcpService.tools
    }

    // MARK: - All Tools for Ollama

    var ollamaTools: [OllamaTool] {
        let local = localTools.map { tool in
            OllamaTool(
                type: "function",
                function: OllamaFunction(
                    name: tool.name,
                    description: tool.description,
                    parameters: tool.parameters
                )
            )
        }

        let remote = mcpTools.map { tool in
            OllamaTool(
                type: "function",
                function: OllamaFunction(
                    name: tool.name,
                    description: tool.description,
                    parameters: tool.inputSchema.toOllamaParameters()
                )
            )
        }

        return local + remote
    }

    // MARK: - Tool Execution

    func execute(name: String, arguments: [String: String]) async -> String {
        // Check local tools first
        if let tool = localTools.first(where: { $0.name == name }) {
            return await tool.execute(arguments: arguments)
        }

        // Check MCP tools
        if mcpTools.contains(where: { $0.name == name }) {
            do {
                return try await mcpService.executeTool(name: name, arguments: arguments)
            } catch {
                return "MCP tool error: \(error.localizedDescription)"
            }
        }

        return "Unknown tool: \(name)"
    }

    // MARK: - Tool Lists

    var localToolNames: [String] {
        localTools.map { $0.name }
    }

    var mcpToolNames: [String] {
        mcpTools.map { $0.name }
    }

    var allToolNames: [String] {
        localToolNames + mcpToolNames
    }
}

// MARK: - MCPInputSchema Extension

extension MCPInputSchema {
    func toOllamaParameters() -> OllamaParameters {
        let props = (properties ?? [:]).mapValues { prop in
            PropertySchema(type: prop.type, description: prop.description)
        }

        return OllamaParameters(
            type: type,
            properties: props,
            required: required ?? []
        )
    }
}
