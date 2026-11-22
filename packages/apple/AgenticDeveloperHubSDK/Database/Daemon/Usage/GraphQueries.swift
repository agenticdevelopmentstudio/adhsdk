#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import GRDB
import OSLog
import Foundation

// The relationship-graph snapshot.
extension DaemonDatabase {

    // MARK: - Graph snapshot (Visualization window)

    /// Build a 3-partite graph over recent sessions. Nodes are sessions,
    /// tools, and projects; links connect each session to the tools it
    /// used (weighted) and to its project (weight 1).
    ///
    /// - Parameters:
    ///   - limit: Maximum number of sessions to include, newest first.
    ///     Capped at 200 to keep the client-side force simulation
    ///     interactive.
    func graphSnapshot(limit: Int = 100) throws -> Sessions.GraphSnapshotDTO {
        let capped = min(max(limit, 1), 200)

        struct SessionRow {
            let id: String
            let cwd: String
            let status: String
        }
        var sessionRows: [SessionRow] = []
        // Choose the sessions first, count their events second — and the counts
        // live in the event store, so they are a second read there for exactly
        // these sessions, never a join across the two files. Counting before the
        // LIMIT is what once made this endpoint miss its deadline at any limit.
        try query("""
            SELECT session_id, cwd, status
            FROM sessions
            ORDER BY last_activity_at DESC
            LIMIT ?
            """, params: [capped]) { row in
            sessionRows.append(SessionRow(
                id: string(row, 0),
                cwd: string(row, 1),
                status: string(row, 2)
            ))
        }
        guard !sessionRows.isEmpty else {
            return Sessions.GraphSnapshotDTO(nodes: [], links: [])
        }

        let sessionIds = sessionRows.map(\.id)
        let eventCounts = try claudeEventCounts(sessionIds: sessionIds)
        let sessionIdSet = Set(sessionIds)
        var toolCounts: [String: Int] = [:]                    // tool -> total uses
        var sessionToolLinks: [String: [String: Int]] = [:]    // sessionId -> (tool -> uses)

        for use in try claudeToolUseCounts(sessionIds: sessionIds) {
            guard sessionIdSet.contains(use.sessionId), !use.toolName.isEmpty else { continue }
            toolCounts[use.toolName, default: 0] += use.count
            sessionToolLinks[use.sessionId, default: [:]][use.toolName] = use.count
        }

        var projectCounts: [String: Int] = [:]                 // project -> sessions
        var sessionProject: [String: String] = [:]             // sessionId -> project
        for row in sessionRows {
            let project = Self.lastPathComponent(row.cwd)
            guard !project.isEmpty, project != "/" else { continue }
            sessionProject[row.id] = project
            projectCounts[project, default: 0] += 1
        }

        var nodes: [Sessions.GraphNodeDTO] = []
        nodes.reserveCapacity(sessionRows.count + toolCounts.count + projectCounts.count)

        for row in sessionRows {
            nodes.append(Sessions.GraphNodeDTO(
                id: "session:\(row.id)",
                kind: "session",
                label: String(row.id.prefix(8)),
                status: row.status,
                weight: eventCounts[row.id] ?? 0
            ))
        }
        for (tool, count) in toolCounts {
            nodes.append(Sessions.GraphNodeDTO(
                id: "tool:\(tool)",
                kind: "tool",
                label: tool,
                status: nil,
                weight: count
            ))
        }
        for (project, count) in projectCounts {
            nodes.append(Sessions.GraphNodeDTO(
                id: "project:\(project)",
                kind: "project",
                label: project,
                status: nil,
                weight: count
            ))
        }

        var links: [Sessions.GraphLinkDTO] = []
        for (sid, toolMap) in sessionToolLinks {
            for (tool, count) in toolMap {
                links.append(Sessions.GraphLinkDTO(
                    source: "session:\(sid)",
                    target: "tool:\(tool)",
                    value: count
                ))
            }
        }
        for (sid, project) in sessionProject {
            links.append(Sessions.GraphLinkDTO(
                source: "session:\(sid)",
                target: "project:\(project)",
                value: 1
            ))
        }

        return Sessions.GraphSnapshotDTO(nodes: nodes, links: links)
    }
}
#endif
