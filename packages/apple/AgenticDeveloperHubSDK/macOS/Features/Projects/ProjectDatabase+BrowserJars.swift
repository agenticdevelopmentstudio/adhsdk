import Foundation
import SQLite3

/// One browser storage jar: a `WKWebsiteDataStore` identifier and what it
/// belongs to.
///
/// `id` *is* the WebKit identifier, so the row and the store on disk are
/// named by one value and cannot drift apart (`dry`).
public struct BrowserJarRecord: Sendable, Equatable {

    /// What a jar is shared by. The raw values are stored in
    /// `browser_jars.kind` and checked by its `CHECK` constraint.
    public enum Kind: String, Sendable, CaseIterable {
        /// Every browser pane in one worktree's tabs.
        case worktree
        /// One pane alone.
        case pane
    }

    public let id: UUID
    public let kind: Kind
    public let repoID: UUID
    /// The standardized path of the worktree the jar was made in.
    public let worktreePath: String
    /// The pane a `.pane` jar belongs to; `nil` for a worktree jar.
    public let paneNodeID: UUID?
    /// The last name the jar was shown under, for a list that outlives the
    /// pane that named it.
    public var label: String

    public init(
        id: UUID = UUID(),
        kind: Kind,
        repoID: UUID,
        worktreePath: String,
        paneNodeID: UUID?,
        label: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.repoID = repoID
        self.worktreePath = worktreePath
        self.paneNodeID = paneNodeID
        self.label = label
    }
}

/// A browser pane that is still in a saved layout, and the worktree it works
/// in — what the jar reconciler needs to tell a jar in use from a leftover.
public struct LiveBrowserPane: Sendable, Hashable {
    /// The pane's own id — what its pane jar is keyed by.
    public let nodeID: UUID
    public let repoID: UUID
    /// Standardized the way `registerBrowser` standardizes a pane's working
    /// directory, so the two compare equal for the same worktree.
    public let worktreePath: String
    /// The layout node a nested pane files its state rows under
    /// (`ProjectPaneStateStore.ownerNodeID`); `nil` for a pane that is a
    /// layout node itself.
    public let ownerNodeID: UUID?

    public init(nodeID: UUID, repoID: UUID, worktreePath: String, ownerNodeID: UUID? = nil) {
        self.nodeID = nodeID
        self.repoID = repoID
        self.worktreePath = worktreePath
        self.ownerNodeID = ownerNodeID
    }

    /// The `pane_state.node_id` this pane's rows live under.
    public var stateNodeID: UUID { ownerNodeID ?? nodeID }

    /// What this pane's state keys start with under `stateNodeID`, for a
    /// store whose own prefix is `prefix`: `ProjectPaneStateStore.storageKey(for:)`
    /// spelled from outside, so a reader with no live store finds the rows
    /// the pane wrote.
    public func stateKeyPrefix(_ prefix: String) -> String {
        ownerNodeID == nil ? prefix : "\(prefix)\(nodeID.uuidString)."
    }

    /// The one spelling of a worktree path a jar is keyed by. Both sides —
    /// the pane at construction and the reconciler reading the layout — go
    /// through here, or a trailing slash would make one worktree two jars.
    public static func standardizedPath(_ path: String) -> String {
        URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.path
    }
}

/// The browser jar registry half of the project database (`browser_jars`,
/// migration 5).
extension ProjectDatabase {

    private static let jarColumns = "id, kind, repo_id, worktree_path, pane_node_id, label"

    /// The worktree jar of `repoID` at `path`, if one was made.
    public func browserJar(worktreeOf repoID: UUID, path: String) throws -> BrowserJarRecord? {
        try queryJars("""
            SELECT \(Self.jarColumns) FROM browser_jars
            WHERE kind = 'worktree' AND repo_id = ? AND worktree_path = ?
        """) { stmt in
            self.bindText(stmt, 1, repoID.uuidString)
            self.bindText(stmt, 2, path)
        }.first
    }

    /// The jar of the pane at `nodeID`, if one was made.
    public func browserJar(pane nodeID: UUID) throws -> BrowserJarRecord? {
        try queryJars("""
            SELECT \(Self.jarColumns) FROM browser_jars
            WHERE kind = 'pane' AND pane_node_id = ?
        """) { stmt in
            self.bindText(stmt, 1, nodeID.uuidString)
        }.first
    }

    /// Records a new jar. Throws on a second worktree jar for one worktree or
    /// a second jar for one pane — the unique indexes refuse it, which is what
    /// lets a caller that lost a race read the winner's row instead.
    public func insertBrowserJar(_ record: BrowserJarRecord) throws {
        try executeBound("""
            INSERT INTO browser_jars (\(Self.jarColumns), created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """) { stmt in
            bindText(stmt, 1, record.id.uuidString)
            bindText(stmt, 2, record.kind.rawValue)
            bindText(stmt, 3, record.repoID.uuidString)
            bindText(stmt, 4, record.worktreePath)
            bindOptionalText(stmt, 5, record.paneNodeID?.uuidString)
            bindText(stmt, 6, record.label)
            sqlite3_bind_double(stmt, 7, Date().timeIntervalSince1970)
        }
    }

    public func updateBrowserJarLabel(id: UUID, label: String) throws {
        try executeBound("UPDATE browser_jars SET label = ? WHERE id = ?") { stmt in
            bindText(stmt, 1, label)
            bindText(stmt, 2, id.uuidString)
        }
    }

    /// Every jar of one project: worktree jars first, then pane jars, each in
    /// the order they were made.
    public func browserJars(repoID: UUID) throws -> [BrowserJarRecord] {
        try queryJars("""
            SELECT \(Self.jarColumns) FROM browser_jars
            WHERE repo_id = ? ORDER BY kind DESC, created_at
        """) { stmt in
            self.bindText(stmt, 1, repoID.uuidString)
        }
    }

    public func allBrowserJars() throws -> [BrowserJarRecord] {
        try queryJars("SELECT \(Self.jarColumns) FROM browser_jars ORDER BY created_at")
    }

    public func deleteBrowserJar(id: UUID) throws {
        try executeBound("DELETE FROM browser_jars WHERE id = ?") { stmt in
            bindText(stmt, 1, id.uuidString)
        }
    }

    /// The ids of every pane a pane jar may belong to that is still in a
    /// saved layout: every browser leaf, and every pane nested inside a live
    /// layout node that has written a state row.
    ///
    /// A nested pane — one inside another pane's own content — is no layout
    /// node; it files its rows under the enclosing node and spells its own id
    /// into the key (`ProjectPaneStateStore.storageKey(for:)`). Its id is only
    /// ever found there, so every UUID in a key under a live node counts, of
    /// any pane type: keeping a jar a little longer than needed is cheap, and
    /// deleting one a live pane holds signs the user out.
    public func livePaneNodeIDs() throws -> Set<UUID> {
        var ids = Set(try liveBrowserPanes().map(\.nodeID))
        try forEachLiveStateKey { key, _, _, _ in
            ids.formUnion(key.split(separator: ".").compactMap { UUID(uuidString: String($0)) })
        }
        return ids
    }

    /// Every browser pane still in a saved layout, with its worktree.
    ///
    /// `layout_nodes` is the authority, not `pane_state`: `saveTabs` rewrites
    /// it to exactly the panes that exist and prunes `pane_state` *by* it, and
    /// a pane that has never written a state row — a fresh one that has not
    /// committed a page yet — is still a pane. Only leaves that show the
    /// browser count; a leaf whose content changed to something else keeps
    /// its node id and is not a browser pane any more.
    ///
    /// A browser nested inside another pane is no leaf, so it is found by its
    /// state rows instead: a key under a live node that reads
    /// `<statePrefix><UUID>.…` is one, owned by that node. Such a pane that
    /// has written nothing yet is not listed; while it is open the registry's
    /// in-use set covers it.
    ///
    /// The worktree is the tab's: a leaf is walked up to its tab's root, and
    /// the tab's `working_directory` names it, or the repository's own path
    /// when the tab names none — the same fallback the window uses when it
    /// builds the pane's context.
    public func liveBrowserPanes(
        contentType: String = ComposableTabsViewID.browser.rawValue,
        statePrefix: String = ComposableTabsViewRegistry.browserStatePrefix
    ) throws -> [LiveBrowserPane] {
        let sql = Self.liveNodesCTE + """
            SELECT DISTINCT id, repo_id, worktree FROM live
            WHERE kind = 'leaf' AND content_type = ?
            """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw ProjectDatabaseError.prepareFailed(lastErrorMessage)
        }
        bindText(stmt, 1, contentType)
        var panes: [LiveBrowserPane] = []
        var seen: Set<UUID> = []
        try forEachRow(stmt) {
            guard let nodeText = columnText(stmt, 0), let nodeID = UUID(uuidString: nodeText),
                  let repoText = columnText(stmt, 1), let repoID = UUID(uuidString: repoText),
                  let path = columnText(stmt, 2) else { return }
            seen.insert(nodeID)
            panes.append(LiveBrowserPane(
                nodeID: nodeID, repoID: repoID, worktreePath: LiveBrowserPane.standardizedPath(path)
            ))
        }
        try forEachLiveStateKey { key, ownerID, repoID, path in
            guard key.hasPrefix(statePrefix),
                  let first = key.dropFirst(statePrefix.count).split(separator: ".", maxSplits: 1).first,
                  let nestedID = UUID(uuidString: String(first)),
                  nestedID != ownerID, seen.insert(nestedID).inserted else { return }
            panes.append(LiveBrowserPane(
                nodeID: nestedID,
                repoID: repoID,
                worktreePath: LiveBrowserPane.standardizedPath(path),
                ownerNodeID: ownerID
            ))
        }
        return panes
    }

    /// Every node of every saved tab, with the worktree its tab names.
    private static let liveNodesCTE = """
        WITH RECURSIVE tree(node_id, root_id) AS (
            SELECT root_node_id, root_node_id FROM project_tabs
            WHERE root_node_id IS NOT NULL
            UNION ALL
            SELECT n.id, tree.root_id FROM layout_nodes n
            JOIN tree ON n.parent_id = tree.node_id
        ),
        live AS (
            SELECT n.id, n.repo_id, n.kind, n.content_type,
                   COALESCE(NULLIF(t.working_directory, ''), g.path) AS worktree
            FROM tree
            JOIN layout_nodes n ON n.id = tree.node_id
            JOIN project_tabs t ON t.root_node_id = tree.root_id AND t.repo_id = n.repo_id
            JOIN git_repo g ON g.id = n.repo_id
        )

        """

    /// Calls `body` with each `pane_state` key filed under a live layout
    /// node, with that node, its project and its tab's worktree.
    private func forEachLiveStateKey(_ body: (String, UUID, UUID, String) -> Void) throws {
        let sql = Self.liveNodesCTE + """
            SELECT DISTINCT s.key, live.id, live.repo_id, live.worktree
            FROM pane_state s
            JOIN live ON s.node_id = live.id AND s.repo_id = live.repo_id
            """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw ProjectDatabaseError.prepareFailed(lastErrorMessage)
        }
        try forEachRow(stmt) {
            guard let key = columnText(stmt, 0),
                  let nodeText = columnText(stmt, 1), let nodeID = UUID(uuidString: nodeText),
                  let repoText = columnText(stmt, 2), let repoID = UUID(uuidString: repoText),
                  let path = columnText(stmt, 3) else { return }
            body(key, nodeID, repoID, path)
        }
    }

    private func queryJars(
        _ sql: String,
        bind: ((OpaquePointer?) -> Void)? = nil
    ) throws -> [BrowserJarRecord] {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw ProjectDatabaseError.prepareFailed(lastErrorMessage)
        }
        bind?(stmt)
        var records: [BrowserJarRecord] = []
        try forEachRow(stmt) {
            guard let idText = columnText(stmt, 0), let id = UUID(uuidString: idText),
                  let kind = columnText(stmt, 1).flatMap(BrowserJarRecord.Kind.init(rawValue:)),
                  let repoText = columnText(stmt, 2), let repoID = UUID(uuidString: repoText),
                  let path = columnText(stmt, 3) else { return }
            records.append(BrowserJarRecord(
                id: id,
                kind: kind,
                repoID: repoID,
                worktreePath: path,
                paneNodeID: columnText(stmt, 4).flatMap { UUID(uuidString: $0) },
                label: columnText(stmt, 5) ?? ""
            ))
        }
        return records
    }
}
