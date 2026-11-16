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
        let conceal = AgentPageBuilder(privacy: privacy, hideImages: false).conceal
        let visits: [BrowserVisitLine]
        switch access {
        case .none:
            throw BrowserToolSet.ToolError(sentence: noneRefusal)
        case .currentTab:
            visits = Array(backForward.lazy.filter(isShareable).map { concealed($0, conceal) }
                .filter { matches($0, query) }.prefix(limit))
        case .all:
            guard let store else { throw BrowserToolSet.ToolError(sentence: noStoreRefusal) }
            if let query, privacy.isOn {
                visits = try await concealedMatches(query, limit: limit, store: store, conceal: conceal)
            } else {
                let rows = try await store.perform { store in
                    if let query { return try store.search(query, limit: limit, excludingLocalFiles: true) }
                    return try store.recent(limit: limit, excludingLocalFiles: true)
                }
                visits = rows.map(visitLine).filter(isShareable).map { concealed($0, conceal) }
            }
        }
        if visits.isEmpty { return emptyReply }
        return visits.map(line).joined(separator: "\n")
    }

    /// How many store rows `concealedMatches` reads at a time.
    static let matchPageSize = 500

    /// The newest `limit` visits whose concealed title or address holds
    /// `query`, read from the store a page at a time, newest first. Under
    /// Agent Privacy the query is matched against what the agent sees, never
    /// the real text: the store's SQL search would match a concealed word, so
    /// "visits" versus "no visits found" would confirm a guess at it
    /// (`query-matches-concealed-text`), and it would miss a stand-in the
    /// agent was shown.
    private static func concealedMatches(
        _ query: String, limit: Int, store: BrowserHistoryStore,
        conceal: (String) -> String
    ) async throws -> [BrowserVisitLine] {
        var found: [BrowserVisitLine] = []
        var cursor: BrowserVisit?
        while found.count < limit {
            let after = cursor
            let page = try await store.perform { store in
                try store.recent(limit: matchPageSize, before: after, excludingLocalFiles: true)
            }
            for row in page {
                let visit = visitLine(row)
                guard isShareable(visit) else { continue }
                let shown = concealed(visit, conceal)
                if matches(shown, query) { found.append(shown) }
                if found.count == limit { break }
            }
            guard page.count == matchPageSize, let last = page.last else { break }
            cursor = last
        }
        return found
    }

    private static func visitLine(_ row: BrowserVisit) -> BrowserVisitLine {
        BrowserVisitLine(title: row.title, url: row.url.absoluteString, when: row.visitedAt)
    }

    /// `visit` as the agent sees it. Each field is concealed on its own
    /// before the line is assembled (`conceal-before-join`), so a privacy
    /// word cannot straddle a separator and slip past the match. Both go
    /// through the agent page's string path (`AgentPageBuilder.conceal`,
    /// recipe `titles-dialogs-focus-through-string-path`), as every page
    /// string does.
    private static func concealed(
        _ visit: BrowserVisitLine, _ conceal: (String) -> String
    ) -> BrowserVisitLine {
        BrowserVisitLine(title: conceal(visit.title), url: conceal(visit.url), when: visit.when)
    }

    /// Whether a visit may be listed at all: a local file never is, its
    /// address or its title, as no tool drives or names one
    /// (`BrowserAutomation.isDrivable`). The store leaves them out in SQL so
    /// the limit counts only what is listed; this catches the rest.
    private static func isShareable(_ visit: BrowserVisitLine) -> Bool {
        BrowserAutomation.isDrivable(visit.url)
    }

    /// Whether a concealed visit holds `query` in its title or address,
    /// ignoring case, as the store's search does.
    private static func matches(_ visit: BrowserVisitLine, _ query: String?) -> Bool {
        guard let query else { return true }
        return visit.title.localizedCaseInsensitiveContains(query)
            || visit.url.localizedCaseInsensitiveContains(query)
    }

    /// One concealed visit's line: its time when known, its title, its address.
    private static func line(_ visit: BrowserVisitLine) -> String {
        var fields: [String] = []
        if let when = visit.when { fields.append(when.formatted(.iso8601)) }
        fields.append(visit.title.isEmpty ? "(untitled)" : visit.title)
        fields.append(visit.url)
        return fields.joined(separator: "  ")
    }
}
