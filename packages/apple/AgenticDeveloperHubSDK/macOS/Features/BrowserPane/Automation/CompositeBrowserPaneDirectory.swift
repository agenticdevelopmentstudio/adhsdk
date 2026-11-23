//
//  CompositeBrowserPaneDirectory.swift
//  AgenticDeveloperHubSDK
//

import Foundation

/// Several pane directories as one: the Kitchen's project windows' panes
/// followed by its standalone browser windows, say. Every list is the
/// directories' lists in order, and a lookup asks each in order and takes
/// the first answer, so the first directory wins a tie.
///
/// Each directory hides what it must (`visible(_:)`) and owns its own ids;
/// two directories must not hand out the same id.
@MainActor
public final class CompositeBrowserPaneDirectory: BrowserPaneDirectory {

    public let directories: [any BrowserPaneDirectory]
    private let focus: BrowserPaneFocus

    public init(_ directories: [any BrowserPaneDirectory], focus: BrowserPaneFocus = .shared) {
        self.directories = directories
        self.focus = focus
    }

    public func browserPanes() -> [BrowserPaneHandle] {
        directories.flatMap { $0.browserPanes() }
    }

    public func browserPane(id: String) -> BrowserPaneHandle? {
        for directory in directories {
            if let found = directory.browserPane(id: id) { return found }
        }
        return nil
    }

    public func browserPane(besidePane paneID: String) -> BrowserPaneHandle? {
        for directory in directories {
            if let found = directory.browserPane(besidePane: paneID) { return found }
        }
        return nil
    }

    /// The pane last focused, appeared or driven, in whichever directory has
    /// it; else the first directory's answer. Asking each directory in turn
    /// would let the first one's fallback (its front pane) win over a pane
    /// the person just used in the second.
    public func lastUsedBrowserPane() -> BrowserPaneHandle? {
        if let focused = focus.lastFocused {
            let automation = focused.automation
            if let found = browserPanes().first(where: { $0.automation === automation }) { return found }
        }
        for directory in directories {
            if let found = directory.lastUsedBrowserPane() { return found }
        }
        return nil
    }

    /// Opens the pane in the first directory that has a window to open it in:
    /// one that answers `noWindow` passes the call on, and any other refusal
    /// is the answer.
    public func openBrowserPane(besidePane paneID: String?, engine: BrowserEngineKind) throws -> BrowserPaneHandle {
        var lastError: Error = BrowserAutomationError.noWindow
        for directory in directories {
            do {
                return try directory.openBrowserPane(besidePane: paneID, engine: engine)
            } catch BrowserAutomationError.noWindow {
                lastError = BrowserAutomationError.noWindow
                continue
            }
        }
        throw lastError
    }

    /// Each directory ignores an id that is not its own.
    public func revealBrowserPane(id: String) {
        for directory in directories { directory.revealBrowserPane(id: id) }
    }

    public func closeBrowserPane(id: String) {
        for directory in directories { directory.closeBrowserPane(id: id) }
    }
}
