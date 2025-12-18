import Foundation

protocol Tool {
    var name: String { get }
    var description: String { get }
    var parameters: OllamaParameters { get }
    func execute(arguments: [String: String]) async -> String
}

// MARK: - Get Current Time Tool

struct GetCurrentTimeTool: Tool {
    let name = "get_current_time"
    let description = "Get the current date and time. Use this when the user asks what time it is or what today's date is."
    let parameters = OllamaParameters(
        type: "object",
        properties: [:],
        required: []
    )

    func execute(arguments: [String: String]) async -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .long
        formatter.locale = Locale.current

        return """
        === Current Time ===

        Date: \(formatter.string(from: Date()))
        Timezone: \(TimeZone.current.identifier)
        """
    }
}

// MARK: - Get System Info Tool

struct GetSystemInfoTool: Tool {
    let name = "get_system_info"
    let description = "Get current system information including OS version, hardware info, and memory usage. Use this when the user asks about their computer or system."
    let parameters = OllamaParameters(
        type: "object",
        properties: [:],
        required: []
    )

    func execute(arguments: [String: String]) async -> String {
        let processInfo = ProcessInfo.processInfo

        // Get memory info
        let physicalMemory = processInfo.physicalMemory
        let memoryGB = Double(physicalMemory) / 1_073_741_824

        // Get OS info
        let osVersion = processInfo.operatingSystemVersionString

        // Get host info
        let hostName = processInfo.hostName
        let processorCount = processInfo.processorCount
        let activeProcessorCount = processInfo.activeProcessorCount

        // Get uptime
        let uptime = processInfo.systemUptime
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60

        return """
        === System Information ===

        SYSTEM
          macOS: \(osVersion)
          Hostname: \(hostName)

        HARDWARE
          Processors: \(processorCount) cores (\(activeProcessorCount) active)
          Memory: \(String(format: "%.1f", memoryGB)) GB

        UPTIME
          \(hours)h \(minutes)m

        Report time: \(Date().formatted())
        """
    }
}

// MARK: - Tool Registry

class ToolRegistry {
    static let shared = ToolRegistry()

    private let tools: [Tool] = [
        GetCurrentTimeTool(),
        GetSystemInfoTool()
    ]

    var ollamaTools: [OllamaTool] {
        tools.map { tool in
            OllamaTool(
                type: "function",
                function: OllamaFunction(
                    name: tool.name,
                    description: tool.description,
                    parameters: tool.parameters
                )
            )
        }
    }

    func execute(name: String, arguments: [String: String]) async -> String {
        guard let tool = tools.first(where: { $0.name == name }) else {
            return "Unknown tool: \(name)"
        }
        return await tool.execute(arguments: arguments)
    }
}
