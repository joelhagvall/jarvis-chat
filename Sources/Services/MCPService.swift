import Foundation
import OSLog

actor MCPService {
    private struct PendingRequest {
        let continuation: CheckedContinuation<JSONRPCResponse, Error>
        let timeoutTask: Task<Void, Never>
    }

    private let logger = Logger(subsystem: "OllamaChat", category: "MCPService")
    private let requestTimeoutNanoseconds: UInt64 = 15_000_000_000

    private var process: Process?
    private var stdin: FileHandle?
    private var stdout: FileHandle?
    private var stderr: FileHandle?
    private var requestId = 0
    private var pendingRequests: [Int: PendingRequest] = [:]
    private var readTask: Task<Void, Never>?
    private var cachedTools: [MCPTool] = []

    private(set) var serverPath: String = NodePathResolver.findServerPath()

    // MARK: - Lifecycle

    var isConnected: Bool {
        process?.isRunning ?? false
    }

    func connect(customPath: String? = nil) async throws {
        guard !isConnected else { return }

        let pathToUse = resolveServerPath(customPath)
        try validateServerPath(pathToUse, isCustom: customPath != nil)

        serverPath = pathToUse

        guard let nodePath = NodePathResolver.findNodePath() else {
            throw MCPError.nodeNotFound
        }

        try await startProcess(nodePath: nodePath)
        try await initialize()
        cachedTools = try await fetchTools()
    }

    func disconnect() {
        readTask?.cancel()
        readTask = nil
        process?.terminate()
        process = nil
        stdin = nil
        stdout = nil
        stderr = nil
        cachedTools = []
        failAllPending(MCPError.notConnected)
    }

    // MARK: - Tool Operations

    var tools: [MCPTool] {
        cachedTools
    }

    func refreshTools() async throws {
        cachedTools = try await fetchTools()
    }

    func executeTool(name: String, arguments: [String: String]) async throws -> String {
        let params: [String: Any] = [
            "name": name,
            "arguments": arguments
        ]

        let response = try await sendRequest(method: "tools/call", params: params)

        if let error = response.error {
            throw MCPError.toolError(error.message)
        }

        return parseToolResult(response)
    }

    // MARK: - Private: Connection

    private func resolveServerPath(_ customPath: String?) -> String {
        if let resolved = NodePathResolver.resolvePath(customPath) {
            return resolved
        }
        return serverPath
    }

    private func validateServerPath(_ path: String, isCustom: Bool) throws {
        guard NodePathResolver.exists(path) else {
            if isCustom {
                throw MCPError.serverNotFound([path])
            } else {
                let checkedPaths = NodePathResolver.defaultServerPaths.filter { !$0.isEmpty }
                throw MCPError.serverNotFound(checkedPaths)
            }
        }
    }

    private func startProcess(nodePath: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: nodePath)
        process.arguments = [serverPath]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        self.process = process
        self.stdin = stdinPipe.fileHandleForWriting
        self.stdout = stdoutPipe.fileHandleForReading
        self.stderr = stderrPipe.fileHandleForReading

        do {
            try process.run()
        } catch {
            throw MCPError.failedToStart(error.localizedDescription)
        }

        startReadingResponses()

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        guard process.isRunning else {
            let stderrOutput = readStderr()
            throw MCPError.processExited(stderrOutput)
        }
    }

    private func readStderr() -> String? {
        guard let stderr else { return nil }
        let data = stderr.availableData
        guard !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private: Protocol

    private func initialize() async throws {
        let initParams: [String: Any] = [
            "protocolVersion": "2024-11-05",
            "capabilities": [:] as [String: Any],
            "clientInfo": [
                "name": "ollama-chat-swift",
                "version": "1.0.0"
            ]
        ]

        let response = try await sendRequest(method: "initialize", params: initParams)

        if let error = response.error {
            throw MCPError.initializationFailed(error.message)
        }

        try await sendNotification(method: "notifications/initialized")
    }

    private func fetchTools() async throws -> [MCPTool] {
        let response = try await sendRequest(method: "tools/list", params: nil)

        if let error = response.error {
            throw MCPError.toolError(error.message)
        }

        return parseTools(from: response)
    }

    private func parseTools(from response: JSONRPCResponse) -> [MCPTool] {
        guard let resultDict = response.result?.value as? [String: Any],
              let toolsArray = resultDict["tools"] as? [[String: Any]] else {
            return []
        }

        return toolsArray.compactMap { dict -> MCPTool? in
            guard let name = dict["name"] as? String,
                  let description = dict["description"] as? String,
                  let inputSchema = dict["inputSchema"] as? [String: Any] else {
                return nil
            }

            let properties = parseProperties(from: inputSchema)
            let required = inputSchema["required"] as? [String] ?? []

            return MCPTool(
                name: name,
                description: description,
                inputSchema: MCPInputSchema(
                    type: inputSchema["type"] as? String ?? "object",
                    properties: properties,
                    required: required
                )
            )
        }
    }

    private func parseProperties(from schema: [String: Any]) -> [String: MCPPropertySchema] {
        guard let props = schema["properties"] as? [String: [String: Any]] else {
            return [:]
        }

        return props.compactMapValues { prop -> MCPPropertySchema? in
            guard let type = prop["type"] as? String else { return nil }
            return MCPPropertySchema(type: type, description: prop["description"] as? String)
        }
    }

    private func parseToolResult(_ response: JSONRPCResponse) -> String {
        if let resultDict = response.result?.value as? [String: Any],
           let content = resultDict["content"] as? [[String: Any]],
           let firstContent = content.first,
           let text = firstContent["text"] as? String {
            return text
        }
        return "Tool executed successfully"
    }

    // MARK: - Private: Communication

    private func sendRequest(method: String, params: [String: Any]?) async throws -> JSONRPCResponse {
        guard isConnected, let stdin = stdin else {
            throw MCPError.notConnected
        }

        requestId += 1
        let id = requestId

        var request: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method
        ]
        if let params {
            request["params"] = params
        }

        var data = try JSONSerialization.data(withJSONObject: request)
        data.append(contentsOf: "\n".utf8)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let timeout = requestTimeoutNanoseconds
                let timeoutTask = Task { [weak self] in
                    do {
                        try await Task.sleep(nanoseconds: timeout)
                    } catch {
                        return
                    }
                    await self?.timeoutRequest(id: id)
                }

                pendingRequests[id] = PendingRequest(continuation: continuation, timeoutTask: timeoutTask)

                do {
                    try stdin.write(contentsOf: data)
                } catch {
                    let pending = pendingRequests.removeValue(forKey: id)
                    pending?.timeoutTask.cancel()
                    continuation.resume(throwing: MCPError.writeFailed(error.localizedDescription))
                }
            }
        } onCancel: { }
    }

    private func sendNotification(method: String) async throws {
        guard isConnected, let stdin = stdin else {
            throw MCPError.notConnected
        }

        let notification: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method
        ]

        var data = try JSONSerialization.data(withJSONObject: notification)
        data.append(contentsOf: "\n".utf8)

        try stdin.write(contentsOf: data)
    }

    private func timeoutRequest(id: Int) {
        guard let pending = pendingRequests.removeValue(forKey: id) else { return }
        pending.timeoutTask.cancel()
        pending.continuation.resume(throwing: MCPError.timeout)
    }

    private func cancelPendingRequest(_ id: Int) {
        guard let pending = pendingRequests.removeValue(forKey: id) else { return }
        pending.timeoutTask.cancel()
        pending.continuation.resume(throwing: CancellationError())
    }

    private func failAllPending(_ error: Error) {
        let pending = pendingRequests
        pendingRequests.removeAll()
        for (_, request) in pending {
            request.timeoutTask.cancel()
            request.continuation.resume(throwing: error)
        }
    }

    private func startReadingResponses() {
        readTask?.cancel()
        guard let stdout else { return }

        readTask = Task { [weak self] in
            do {
                for try await line in stdout.bytes.lines {
                    guard !line.isEmpty else { continue }
                    await self?.handleResponse(line)
                }
            } catch {
                await self?.handleReadError(error)
            }
        }
    }

    private func handleResponse(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }

        do {
            let response = try JSONDecoder().decode(JSONRPCResponse.self, from: data)

            if let id = response.id, let pending = pendingRequests.removeValue(forKey: id) {
                pending.timeoutTask.cancel()
                pending.continuation.resume(returning: response)
            }
        } catch {
            logger.error("Failed to decode response: \(error.localizedDescription)")
        }
    }

    private func handleReadError(_ error: Error) {
        if error is CancellationError { return }
        logger.error("MCP read failed: \(error.localizedDescription)")
    }
}

// MARK: - Errors

enum MCPError: Error, LocalizedError {
    case serverNotFound([String])
    case nodeNotFound
    case failedToStart(String)
    case notConnected
    case processExited(String?)
    case initializationFailed(String)
    case toolError(String)
    case writeFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .serverNotFound(let paths):
            let pathList = paths.map { "• \($0)" }.joined(separator: "\n")
            return "MCP server not found. Checked:\n\(pathList)"
        case .nodeNotFound:
            return "Node.js not found. Install via: brew install node"
        case .failedToStart(let reason):
            return "Failed to start MCP server: \(reason)"
        case .notConnected:
            return "MCP server not connected"
        case .processExited(let stderr):
            if let stderr, !stderr.isEmpty {
                return "MCP server process exited: \(stderr)"
            }
            return "MCP server process exited unexpectedly"
        case .initializationFailed(let reason):
            return "MCP initialization failed: \(reason)"
        case .toolError(let message):
            return "MCP tool error: \(message)"
        case .writeFailed(let reason):
            return "Failed to write to MCP server: \(reason)"
        case .timeout:
            return "MCP request timed out"
        }
    }
}
