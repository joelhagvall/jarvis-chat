import Foundation

// MARK: - Thinking Parser

/// Utility for parsing thinking/reasoning blocks from LLM responses
enum ThinkingParser {
    struct ParsedContent {
        let thinking: String?
        let content: String
    }

    /// Parses thinking blocks from raw LLM content
    /// Supports <think>...</think> and <response>...</response> formats
    static func parse(_ rawContent: String) -> ParsedContent {
        let lower = rawContent.lowercased()

        // Try <think>...</think> format
        if let result = parseThinkTag(rawContent: rawContent, lower: lower) {
            return result
        }

        // Try <response>...</response> format
        if let result = parseResponseTag(rawContent: rawContent, lower: lower) {
            return result
        }

        // Heuristic: detect reasoning patterns
        if let result = parseHeuristic(rawContent: rawContent) {
            return result
        }

        // Fallback: treat all as content
        return ParsedContent(thinking: nil, content: rawContent)
    }

    // MARK: - Private Parsing Methods

    private static func parseThinkTag(rawContent: String, lower: String) -> ParsedContent? {
        guard let thinkStart = lower.range(of: "<think>") else { return nil }

        if let thinkEnd = lower.range(of: "</think>") {
            let thinkingRaw = String(rawContent[thinkStart.upperBound..<thinkEnd.lowerBound])
            var content = rawContent
            content.removeSubrange(thinkStart.lowerBound..<thinkEnd.upperBound)
            return ParsedContent(
                thinking: thinkingRaw.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else {
            // Still streaming inside <think>
            let thinking = String(rawContent[thinkStart.upperBound...])
            return ParsedContent(thinking: thinking, content: "")
        }
    }

    private static func parseResponseTag(rawContent: String, lower: String) -> ParsedContent? {
        guard let responseStart = lower.range(of: "<response>") else { return nil }

        if let responseEnd = lower.range(of: "</response>") {
            let thinking = String(rawContent[..<responseStart.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let content = String(rawContent[responseStart.upperBound..<responseEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return ParsedContent(
                thinking: thinking.isEmpty ? nil : thinking,
                content: content
            )
        } else {
            // Response started but not finished
            let thinking = String(rawContent[..<responseStart.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let partialContent = String(rawContent[responseStart.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return ParsedContent(
                thinking: thinking.isEmpty ? nil : thinking,
                content: partialContent
            )
        }
    }

    private static func parseHeuristic(rawContent: String) -> ParsedContent? {
        let trimmed = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)

        let reasoningPatterns = [
            "The user",
            "I need to",
            "Let me",
            "I'll ",
            "I should",
            "Since ",
            "First,",
            "Okay,"
        ]

        for pattern in reasoningPatterns {
            if trimmed.hasPrefix(pattern) && !trimmed.contains("\n\n") {
                return ParsedContent(thinking: trimmed, content: "")
            }
        }

        return nil
    }
}
