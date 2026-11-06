import Foundation
@testable import AgenticDeveloperHubSDKIntegrations

/// An in-memory `GmailAPI`. State is lock-protected so it is `Sendable`; tests configure it
/// through the properties and read what was called through the recorded ones.
final class FakeGmailAPI: GmailAPI, @unchecked Sendable {
    struct BatchModifyCall: Equatable {
        var ids: [String]
        var add: [String]
        var remove: [String]
    }

    struct ListCall: Equatable {
        var query: String
        var includeSpamTrash: Bool
    }

    private let lock = NSLock()
    private var state = State()

    private struct State {
        var emailAddress = "me@example.com"
        var historyId = "100"
        var messages: [String: GmailMessageDTO] = [:]
        var labels: [GmailLabelDTO] = []
        var listPages: [[String]]?
        var historyPages: [GmailHistoryPage] = []
        var historyError: (any Error)?
        var messageErrors: [String: any Error] = [:]
        var batchModifyError: (any Error)?
        var onListMessageIds: (@Sendable (FakeGmailAPI) -> Void)?
        var listCalls: [ListCall] = []
        var historyCalls: [String] = []
        var batchModifyCalls: [BatchModifyCall] = []
    }

    private func with<T>(_ body: (inout State) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body(&state)
    }

    // MARK: Configuration

    var historyId: String {
        get { with { $0.historyId } }
        set { with { $0.historyId = newValue } }
    }
    var messages: [String: GmailMessageDTO] {
        get { with { $0.messages } }
        set { with { $0.messages = newValue } }
    }
    var labels: [GmailLabelDTO] {
        get { with { $0.labels } }
        set { with { $0.labels = newValue } }
    }
    /// Pages `listMessageIds` returns; `nil` means one page with every message id, sorted.
    var listPages: [[String]]? {
        get { with { $0.listPages } }
        set { with { $0.listPages = newValue } }
    }
    var historyPages: [GmailHistoryPage] {
        get { with { $0.historyPages } }
        set { with { $0.historyPages = newValue } }
    }
    /// Thrown by `history` when set (for example `GmailCursorExpired()`); cleared with `nil`.
    var historyError: (any Error)? {
        get { with { $0.historyError } }
        set { with { $0.historyError = newValue } }
    }
    var messageErrors: [String: any Error] {
        get { with { $0.messageErrors } }
        set { with { $0.messageErrors = newValue } }
    }
    var batchModifyError: (any Error)? {
        get { with { $0.batchModifyError } }
        set { with { $0.batchModifyError = newValue } }
    }
    /// Runs on every `listMessageIds`, outside the lock, so it may mutate the fake.
    var onListMessageIds: (@Sendable (FakeGmailAPI) -> Void)? {
        get { with { $0.onListMessageIds } }
        set { with { $0.onListMessageIds = newValue } }
    }

    // MARK: Recorded calls

    var listCalls: [ListCall] { with { $0.listCalls } }
    var historyCalls: [String] { with { $0.historyCalls } }
    var batchModifyCalls: [BatchModifyCall] { with { $0.batchModifyCalls } }

    func setMessage(_ message: GmailMessageDTO) {
        with { $0.messages[message.id] = message }
    }

    // MARK: GmailAPI

    func profile() async throws -> GmailProfile {
        with { GmailProfile(emailAddress: $0.emailAddress, historyId: $0.historyId) }
    }

    func listMessageIds(query: String, includeSpamTrash: Bool, pageToken: String?) async throws -> GmailIdPage {
        let hook = with { state -> (@Sendable (FakeGmailAPI) -> Void)? in
            state.listCalls.append(ListCall(query: query, includeSpamTrash: includeSpamTrash))
            return state.onListMessageIds
        }
        hook?(self)
        let pages = with { $0.listPages ?? [$0.messages.keys.sorted()] }
        let index = pageToken.flatMap(Int.init) ?? 0
        guard index < pages.count else { return GmailIdPage(ids: [], nextPageToken: nil) }
        return GmailIdPage(ids: pages[index], nextPageToken: index + 1 < pages.count ? String(index + 1) : nil)
    }

    func message(id: String) async throws -> GmailMessageDTO {
        let (message, error) = with { ($0.messages[id], $0.messageErrors[id]) }
        if let error { throw error }
        guard let message else { throw IntegrationError.gmail(status: 404, message: "Not Found") }
        return message
    }

    func history(startHistoryId: String, pageToken: String?) async throws -> GmailHistoryPage {
        let (pages, error) = with { state -> ([GmailHistoryPage], (any Error)?) in
            state.historyCalls.append(startHistoryId)
            return (state.historyPages, state.historyError)
        }
        if let error { throw error }
        let index = pageToken.flatMap(Int.init) ?? 0
        guard index < pages.count else {
            return GmailHistoryPage(changedIds: [], deletedIds: [], historyId: startHistoryId, nextPageToken: nil)
        }
        let page = pages[index]
        return GmailHistoryPage(
            changedIds: page.changedIds, deletedIds: page.deletedIds, historyId: page.historyId,
            nextPageToken: index + 1 < pages.count ? String(index + 1) : nil)
    }

    func labels() async throws -> [GmailLabelDTO] {
        with { $0.labels }
    }

    func batchModify(ids: [String], add: [String], remove: [String]) async throws {
        let error = with { state -> (any Error)? in
            state.batchModifyCalls.append(BatchModifyCall(ids: ids, add: add, remove: remove))
            return state.batchModifyError
        }
        if let error { throw error }
    }
}
