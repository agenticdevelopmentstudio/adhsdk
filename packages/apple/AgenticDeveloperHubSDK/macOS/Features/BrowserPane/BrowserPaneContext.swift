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
    /// Where worktree and pane storage jars are found or made; `nil` puts
    /// every jar setting on the shared store, which is what a pane without a
    /// project database can honestly offer.
    public let jars: BrowserJarRegistry?

    public init(
        paneNodeID: UUID?,
        projectID: UUID?,
        projectName: String,
        worktreePath: String?,
        jars: BrowserJarRegistry? = nil
    ) {
        self.paneNodeID = paneNodeID
        self.projectID = projectID
        self.projectName = projectName
        self.worktreePath = worktreePath
        self.jars = jars
    }

    /// A pane that belongs to no project.
    public static let detached = BrowserPaneContext(
        paneNodeID: nil, projectID: nil, projectName: "", worktreePath: nil
    )
}
