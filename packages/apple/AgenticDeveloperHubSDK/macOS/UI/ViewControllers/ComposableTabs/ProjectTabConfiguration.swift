import Foundation

/// The tab configuration every project window shares: which edges carry tabs,
/// and the panes' arrangement — their shape and their sizes.
///
/// It is the configuration of the project window the user last worked in, so
/// switching to another project brings the same tab sides and the same pane
/// sizes with it rather than each project remembering its own
/// (`principle-of-least-astonishment`). A value, so the window manager can
/// read it out of one window and hand it to another without either knowing
/// the other (`dependency-injection`).
public struct ProjectTabConfiguration: Sendable {
    /// The front tab's split tree; `nil` when there is none to copy.
    public let arrangement: LayoutNode?
    /// The edges that carry tabs. Empty means "leave the edges as they are".
    public let enabledEdges: [Edge]

    public init(arrangement: LayoutNode?, enabledEdges: [Edge]) {
        self.arrangement = arrangement
        self.enabledEdges = enabledEdges
    }
}
