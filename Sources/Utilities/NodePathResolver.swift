import Foundation

/// Utility for resolving Node.js and MCP server paths
enum NodePathResolver {
    /// Common paths where Node.js might be installed
    private static let nodePaths = [
        "/opt/homebrew/bin/node",  // Homebrew Apple Silicon
        "/usr/local/bin/node",     // Homebrew Intel
        "/usr/bin/node"            // System
    ]

    /// Possible default MCP server paths
    static let defaultServerPaths = [
        NSString(string: "~/Documents/GitHub/system-monitor/packages/mcp-server/dist/server.js").expandingTildeInPath,
        Bundle.main.path(forResource: "mcp-server", ofType: "js") ?? "",
        NSString(string: "~/mcp-server/dist/server.js").expandingTildeInPath
    ]

    /// Finds the Node.js executable path
    /// Checks nvm installations first, then common paths
    static func findNodePath() -> String? {
        // Check nvm directory for any node version
        if let nvmNode = findNvmNode() {
            return nvmNode
        }

        // Check other common paths
        for path in nodePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return nil
    }

    /// Finds the first available MCP server path
    static func findServerPath() -> String {
        for path in defaultServerPaths where !path.isEmpty {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return defaultServerPaths.first ?? ""
    }

    /// Resolves a server path, expanding tilde if needed
    static func resolvePath(_ path: String?) -> String? {
        guard let path, !path.isEmpty else { return nil }
        return NSString(string: path).expandingTildeInPath
    }

    /// Validates that a path exists
    static func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Private

    private static func findNvmNode() -> String? {
        let nvmBase = NSString(string: "~/.nvm/versions/node").expandingTildeInPath

        guard let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmBase) else {
            return nil
        }

        // Sort to get latest version first
        let sorted = versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }

        for version in sorted {
            let nodePath = "\(nvmBase)/\(version)/bin/node"
            if FileManager.default.fileExists(atPath: nodePath) {
                return nodePath
            }
        }

        return nil
    }
}
