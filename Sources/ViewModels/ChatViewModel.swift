import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - State Objects

    var chat = ChatState()
    var session = SessionState()
    var settings = SettingsState()
    var model = ModelState()
    var mcp: MCPCoordinator

    // MARK: - Services

    private let sessionService: SessionService
    private let messageHandler: MessageHandling
    private var currentTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        sessionService: SessionService? = nil,
        messageHandler: MessageHandling? = nil,
        mcpCoordinator: MCPCoordinator? = nil
    ) {
        self.sessionService = sessionService ?? SessionService()
        self.messageHandler = messageHandler ?? MessageHandler()
        self.mcp = mcpCoordinator ?? MCPCoordinator()
        setupBindings()
    }

    private func setupBindings() {
        chat.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
        session.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
        settings.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
        model.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
        mcp.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
    }

    // MARK: - Setup

    func setModelContext(_ context: ModelContext) {
        sessionService.setModelContext(context)
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        session.sessions = sessionService.fetchAllSessions()

        if let appSettings = sessionService.fetchSettings() {
            settings.apply(from: appSettings)
            model.apply(from: appSettings)
        }

        if let first = session.sessions.first {
            selectSession(first)
        }
    }

    func ensureOllamaRunning() async {
        do {
            try await messageHandler.ensureOllamaRunning()
        } catch {
            chat.setError(error)
        }
    }

    func loadModels() async {
        do {
            model.setModels(try await messageHandler.loadModels())
            chat.errorMessage = nil
        } catch {
            chat.setError(error)
        }

        if settings.mcpEnabled {
            await connectMCP()
        }
    }

    // MARK: - MCP

    func connectMCP() async {
        await mcp.connect(serverPath: settings.mcpServerPath)
    }

    func disconnectMCP() async {
        await mcp.disconnect()
    }

    func refreshMCPTools() async {
        await mcp.refreshTools()
    }

    // MARK: - Messaging

    func sendMessage() {
        let text = chat.inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        if chat.isLoading {
            cancelCurrentTask()
            return
        }

        guard !text.isEmpty else { return }
        guard !model.selectedModel.isEmpty else {
            chat.errorMessage = "No model selected. Load models first."
            return
        }

        cancelCurrentTask()
        chat.reset()

        guard let currentSession = ensureActiveSession() else {
            chat.isLoading = false
            return
        }
        let activeSessionId = currentSession.id

        let userEntity = sessionService.createMessage(role: "user", content: text, session: currentSession)
        chat.messages.append(ChatMessage(from: userEntity))
        sessionService.save()

        let assistantEntity = sessionService.createMessage(role: "assistant", content: "", session: currentSession)

        currentTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.chat.isLoading = false
                self.currentTask = nil
            }

            do {
                try await self.processMessage(session: currentSession, activeSessionId: activeSessionId, assistantEntity: assistantEntity)
            } catch is CancellationError {
                self.handleCancellation(assistantEntity)
            } catch {
                self.handleError(error, assistantEntity: assistantEntity)
            }
        }
    }

    // MARK: - Session Management

    func newChat() {
        cancelCurrentTask()
        if let newSession = sessionService.createSession() {
            session.addSession(newSession)
            chat.messages = []
        }
    }

    func selectSession(_ s: ChatSession) {
        cancelCurrentTask()
        session.currentSession = s
        chat.messages = sessionService.loadMessages(from: s)
    }

    func deleteSession(_ s: ChatSession) {
        session.removeSession(s)
        sessionService.deleteSession(s)

        if session.isCurrentSession(s) {
            session.selectFirst()
            chat.messages = session.currentSession.map { sessionService.loadMessages(from: $0) } ?? []
        }
    }

    func renameSession(_ s: ChatSession, title: String) {
        sessionService.updateSessionTitle(s, title: title)
    }

    func clearChat() {
        guard let s = session.currentSession else { return }
        sessionService.clearMessages(in: s)
        chat.messages.removeAll()
    }

    // MARK: - Settings

    func saveSettings() {
        sessionService.saveSettings(
            userName: settings.userName,
            systemPrompt: settings.systemPrompt,
            language: settings.language,
            thinkingEnabled: settings.thinkingEnabled,
            mcpEnabled: settings.mcpEnabled,
            selectedModel: model.selectedModel,
            mcpServerPath: settings.mcpServerPath
        )
    }

    // MARK: - Private

    private func ensureActiveSession() -> ChatSession? {
        if session.currentSession == nil, let newSession = sessionService.createSession() {
            session.addSession(newSession)
        }
        return session.currentSession
    }

    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        chat.isLoading = false
        chat.isThinking = false
        chat.currentToolName = nil
        chat.clearStreaming()
    }

    private func processMessage(session s: ChatSession, activeSessionId: UUID, assistantEntity: ChatMessageEntity) async throws {
        let ollamaMessages = messageHandler.buildOllamaMessages(systemPrompt: settings.systemPrompt, messages: chat.messages)
        let handler = StreamingHandler(viewModel: self, activeSessionId: activeSessionId, thinkingEnabled: settings.thinkingEnabled)

        var toolCallToProcess: OllamaToolCall?

        try await messageHandler.send(
            model: model.selectedModel,
            messages: ollamaMessages,
            tools: mcp.ollamaTools,
            thinkingEnabled: settings.thinkingEnabled,
            onChunk: handler.onChunk,
            onThinking: handler.onThinking,
            onToolCall: { [weak self] toolCall in
                guard self?.session.currentSessionId == activeSessionId else { return }
                self?.chat.currentToolName = toolCall.function.name
                toolCallToProcess = toolCall
            }
        )

        chat.isThinking = false
        try Task.checkCancellation()

        if let toolCall = toolCallToProcess {
            try await processToolCall(toolCall, handler: handler, assistantEntity: assistantEntity, session: s, activeSessionId: activeSessionId, ollamaMessages: ollamaMessages)
        } else {
            finalizeResponse(content: handler.rawContent, thinking: handler.hasThinking ? handler.fullThinking : nil, entity: assistantEntity)
        }

        chat.currentToolName = nil
        sessionService.autoUpdateTitle(s)
        sessionService.updateSessionTimestamp(s)
    }

    private func processToolCall(_ toolCall: OllamaToolCall, handler: StreamingHandler, assistantEntity: ChatMessageEntity, session s: ChatSession, activeSessionId: UUID, ollamaMessages: [OllamaMessage]) async throws {
        chat.currentToolName = toolCall.function.name

        let toolResult = await mcp.execute(name: toolCall.function.name, arguments: toolCall.function.arguments ?? [:])
        try Task.checkCancellation()

        saveToolCallMessage(handler: handler, toolCall: toolCall, entity: assistantEntity)

        let finalEntity = sessionService.createMessage(role: "assistant", content: "", session: s)
        let followUpHandler = StreamingHandler(viewModel: self, activeSessionId: activeSessionId, thinkingEnabled: settings.thinkingEnabled)

        try await messageHandler.sendFollowUp(
            model: model.selectedModel,
            messages: ollamaMessages,
            toolName: toolCall.function.name,
            toolResult: toolResult,
            thinkingEnabled: settings.thinkingEnabled,
            onChunk: followUpHandler.onChunk,
            onThinking: followUpHandler.onThinking
        )

        try Task.checkCancellation()
        finalizeResponse(content: followUpHandler.rawContent, thinking: followUpHandler.hasThinking ? followUpHandler.fullThinking : nil, entity: finalEntity)
    }

    private func saveToolCallMessage(handler: StreamingHandler, toolCall: OllamaToolCall, entity: ChatMessageEntity) {
        if !handler.rawContent.isEmpty {
            entity.content = handler.rawContent
        } else {
            entity.setToolCall(ToolCall(name: toolCall.function.name, arguments: toolCall.function.arguments ?? [:]))
        }
        entity.thinking = handler.hasThinking ? handler.fullThinking : nil
        chat.messages.append(ChatMessage(from: entity))
        chat.clearStreaming()
    }

    private func finalizeResponse(content: String, thinking: String?, entity: ChatMessageEntity) {
        entity.content = content
        entity.thinking = thinking
        chat.messages.append(ChatMessage(from: entity))
        chat.clearStreaming()
    }

    private func handleError(_ error: Error, assistantEntity: ChatMessageEntity) {
        chat.setError(error)
        chat.removeLastEmptyMessage()
        chat.clearStreaming()
        chat.currentToolName = nil
        if shouldDelete(assistantEntity) {
            sessionService.deleteMessage(assistantEntity)
        } else {
            sessionService.save()
        }
    }

    private func handleCancellation(_ assistantEntity: ChatMessageEntity) {
        chat.clearStreaming()
        chat.currentToolName = nil
        if shouldDelete(assistantEntity) {
            sessionService.deleteMessage(assistantEntity)
        } else {
            sessionService.save()
        }
    }

    private func shouldDelete(_ entity: ChatMessageEntity) -> Bool {
        let hasContent = !entity.content.isEmpty
        let hasToolCall = entity.toolCallName != nil
        let hasThinking = !(entity.thinking ?? "").isEmpty
        return !(hasContent || hasToolCall || hasThinking)
    }
}
