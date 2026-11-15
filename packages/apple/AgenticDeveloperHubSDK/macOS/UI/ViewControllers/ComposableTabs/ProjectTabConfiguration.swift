import Foundation

/// The tab configuration every project window shares: the panes'
/// arrangement — their shape and their sizes.
///
/// It is the configuration of the project window the user last worked in, so
/// switching to another project brings the same pane sizes with it rather than
/// each project remembering its own (`principle-of-least-astonishment`). The
/// tab edges are not part of it: a project's edges are its own Tab Bars
/// choice, or the app-wide tab positions when it has made none, and copying
/// one project's choice into another would make that choice for it. A value,
/// so the window manager can read it out of one window and hand it to another
/// without either knowing the other (`dependency-injection`).
public struct ProjectTabConfiguration: Sendable {
    /// The front tab's split tree; `nil` when there is none to copy.
    public let arrangement: LayoutNode?

    public init(arrangement: LayoutNode?) {
        self.arrangement = arrangement
    }
}
