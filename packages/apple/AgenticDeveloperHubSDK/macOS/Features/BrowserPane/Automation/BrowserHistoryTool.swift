import Foundation

/// One visit as `browser_history` lists it: a back/forward entry, or a row
/// of the history store. `when` is nil when the source keeps no time (a
/// back/forward entry).
public struct BrowserVisitLine: Sendable, Equatable {
    public var title: String
    public var url: String
    public var when: Date?

    public init(title: String, url: String, when: Date?) {
        self.title = title; self.url = url; self.when = when
    }
}

/// The `browser_history` tool's answer, apart from the pane it is asked
/// about: what the pane's Agent can see history setting allows, concealed
/// field by field with the privacy handed in, the pane's Agent Privacy over
/// every enabled word whatever its sites (the Agent History Tool
/// recipe). It reads nothing on the main actor: the back/forward list is
/// handed in, read there by the caller, and the store is read through
/// `BrowserHistoryStore.perform`, off the caller's thread.
struct BrowserHistoryTool {

    static let defaultLimit = 50
    static let maximumLimit = 200

    static let noneRefusal =
        "History is not shared with the agent for this pane "
        + "(Settings › Web Browser › Privacy and Security › Agent can see history)."
    static let noStoreRefusal = "browser_history failed: the browser's history could not be opened."
    static let emptyReply = "no visits found"

    /// `limit` held to 1…200: above 200 is 200 (`limit-default-and-cap`),
    /// and below 1 is 1, so a mistaken 0 still answers.
    static func clamped(_ limit: Int) -> Int { min(max(limit, 1), maximumLimit) }

    static func run(
        access: BrowserAgentHistoryAccess, query: String?, limit: Int,
        store: BrowserHistoryStore?, backForward: [BrowserVisitLine], privacy: BrowserAgentPrivacy
    ) async throws -> String {
        // `requireAccess` has already refused a closed privacy; refusing here
        // too means this function can never answer through one.
        if let refusal = privacy.closedRefusal() { throw BrowserToolSet.ToolError(sentence: refusal) }
        let limit = clamped(limit)
        let query = query.flatMap { $0.isEmpty ? nil : $0 }
        let visits: [BrowserVisitLine]
        switch access {
        case .none:
            throw BrowserToolSet.ToolError(sentence: noneRefusal)
        case .currentTab:
            visits = Array(backForward.filter { isShareable($0) && matches($0, query) }.prefix(limit))
        case .all:
            guard let store else { throw BrowserToolSet.ToolError(sentence: noStoreRefusal) }
            let rows = try await store.perform { store in
                if let query { return try store.search(query, limit: limit, excludingLocalFiles: true) }
                return try store.recent(limit: limit, excludingLocalFiles: true)
            }
            visits = rows.map { BrowserVisitLine(title: $0.title, url: $0.url.absoluteString, when: $0.visitedAt) }
                .filter(isShareable)
        }
        if visits.isEmpty { return emptyReply }
        return visits.map { line($0, privacy) }.joined(separator: "\n")
    }

    /// Whether a visit may be listed at all: a local file never is, its
    /// address or its title, as no tool drives or names one
    /// (`BrowserAutomation.isDrivable`). The store leaves them out in SQL so
    /// the limit counts only what is listed; this catches the rest.
    private static func isShareable(_ visit: BrowserVisitLine) -> Bool {
        BrowserAutomation.isDrivable(visit.url)
    }

    /// Whether a back/forward entry holds `query` in its title or address,
    /// ignoring case, as the store's search does.
    private static func matches(_ visit: BrowserVisitLine, _ query: String?) -> Bool {
        guard let query else { return true }
        return visit.title.localizedCaseInsensitiveContains(query)
            || visit.url.localizedCaseInsensitiveContains(query)
    }

    /// One visit's line: its time when known, its title, its address. Each
    /// field is concealed on its own before the line is assembled
    /// (`conceal-before-join`), so a privacy word cannot straddle a
    /// separator and slip past the match. Both go through the agent page's
    /// string path (`AgentPageBuilder.conceal`, recipe
    /// `titles-dialogs-focus-through-string-path`), as every page string does.
    private static func line(_ visit: BrowserVisitLine, _ privacy: BrowserAgentPrivacy) -> String {
        let conceal = AgentPageBuilder(privacy: privacy, hideImages: false).conceal
        let title = conceal(visit.title)
        let url = conceal(visit.url)
        var fields: [String] = []
        if let when = visit.when { fields.append(when.formatted(.iso8601)) }
        fields.append(title.isEmpty ? "(untitled)" : title)
        fields.append(url)
        return fields.joined(separator: "  ")
    }
}
