//
//  BrowserPaneContext.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Which project, worktree and pane node a browser pane belongs to.
///
/// The pane needs it to decide where its session data lives and to label
/// itself; it is handed in rather than looked up so a pane built outside a
/// project window (a test, a preview) says so with `.detached` instead of
/// guessing (`explicit-over-implicit`).
public struct BrowserPaneContext: Sendable {
    /// The layout node the pane occupies; `nil` for a detached pane.
    public let paneNodeID: UUID?
    public let projectID: UUID?
    public let projectName: String
    /// The standardized path of the pane's working directory.
    public let worktreePath: String?

    public init(paneNodeID: UUID?, projectID: UUID?, projectName: String, worktreePath: String?) {
        self.paneNodeID = paneNodeID
        self.projectID = projectID
        self.projectName = projectName
        self.worktreePath = worktreePath
    }

    /// A pane that belongs to no project.
    public static let detached = BrowserPaneContext(
        paneNodeID: nil, projectID: nil, projectName: "", worktreePath: nil
    )
}
