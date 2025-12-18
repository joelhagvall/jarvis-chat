import Foundation

// MARK: - JSON-RPC 2.0 Base Types

struct JSONRPCRequest: Codable {
    let jsonrpc: String = "2.0"
    let id: Int
    let method: String
    let params: JSONRPCParams?

    private enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }

    init(id: Int, method: String, params: JSONRPCParams? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }
}

struct JSONRPCParams: Codable {
    let name: String?
    let arguments: [String: AnyCodable]?

    init(name: String? = nil, arguments: [String: AnyCodable]? = nil) {
        self.name = name
        self.arguments = arguments
    }
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String
    let id: Int?
    let result: AnyCodable?
    let error: JSONRPCError?
}

struct JSONRPCError: Codable {
    let code: Int
    let message: String
}

// MARK: - MCP Tool Types

struct MCPToolsListResult: Codable {
    let tools: [MCPTool]
}

struct MCPTool: Codable {
    let name: String
    let description: String
    let inputSchema: MCPInputSchema
}

struct MCPInputSchema: Codable {
    let type: String
    let properties: [String: MCPPropertySchema]?
    let required: [String]?
}

struct MCPPropertySchema: Codable {
    let type: String
    let description: String?
}

struct MCPToolCallResult: Codable {
    let content: [MCPContent]
}

struct MCPContent: Codable {
    let type: String
    let text: String?
}

// MARK: - MCP Initialize

struct MCPInitializeParams: Codable {
    let protocolVersion: String
    let capabilities: MCPCapabilities
    let clientInfo: MCPClientInfo
}

struct MCPCapabilities: Codable {
    // Empty for now, client doesn't need special capabilities
}

struct MCPClientInfo: Codable {
    let name: String
    let version: String
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    var stringValue: String? {
        value as? String
    }

    var intValue: Int? {
        value as? Int
    }

    var doubleValue: Double? {
        value as? Double
    }

    var boolValue: Bool? {
        value as? Bool
    }
}
