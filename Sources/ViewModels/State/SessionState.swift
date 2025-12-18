import Foundation
import SwiftUI

/// Observable state for session management
@MainActor
final class SessionState: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?

    var currentSessionId: UUID? { currentSession?.id }

    func addSession(_ session: ChatSession) {
        sessions.insert(session, at: 0)
        currentSession = session
    }

    func removeSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
    }

    func selectFirst() {
        currentSession = sessions.first
    }

    func isCurrentSession(_ session: ChatSession) -> Bool {
        currentSession?.id == session.id
    }
}
