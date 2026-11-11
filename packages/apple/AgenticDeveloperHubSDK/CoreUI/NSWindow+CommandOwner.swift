import AppKit

public extension NSWindow {

    /// The window a command typed or chosen in this one is about: this
    /// window, or for a child window the window it is attached to, at the
    /// top of the chain.
    ///
    /// A child window is part of its parent rather than a window of its own —
    /// a Chrome pane's page, kept over the pane, takes the keys by being key
    /// itself, and so do its bubbles and menus above it. A command that
    /// finds its target through the key window (or the window of a key
    /// event) and stops at the child would act on a window that has no panes,
    /// no notes and no project.
    var commandOwner: NSWindow {
        var window = self
        while let parent = window.parent { window = parent }
        return window
    }
}
