//
//  StandaloneBrowserPaneDirectory.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import AgenticDeveloperHubSDKCore

/// A window holding one browser and nothing else, as the pane directory sees
/// it. `WebBrowserWindowController` is the real one; tests supply fakes.
@MainActor
public protocol StandaloneBrowserWindow: AnyObject {
    /// Unique to the window for as long as it is open; the pane's id.
    var browserWindowID: String { get }
    var browserWindowTitle: String { get }
    /// The browser the window shows.
    var pane: WebBrowserPaneViewController { get }
    /// The window on screen, for ordering front to back; nil before it is
    /// first shown.
    var browserWindow: NSWindow? { get }
    /// Puts the window on screen without bringing the app forward.
    func revealBrowserWindow()
    /// Closes the window the way its close button would.
    func closeBrowserWindow()
}

extension BrowserPaneHandle {
    /// The handle for `pane`, its agent settings as they stand now. The one
    /// way every directory makes a handle from a pane, so the settings the
    /// tools see are read the same way wherever the pane lives.
    public init(pane: WebBrowserPaneViewController, id: String, project: String, tab: String) {
        self.init(
            id: id, project: project, tab: tab,
            automation: pane.automation,
            engine: pane.engineKind,
            access: pane.agentAccess,
            isPausedForAgent: pane.isPausedForAgent,
            agentPrivacy: pane.agentPrivacy(),
            historyPrivacy: pane.agentHistoryPrivacy(),
            historyAccess: pane.agentHistoryAccess,
            historyStore: pane.historyStore,
            hidesImages: pane.agentHidesImages)
    }
}

/// The Browser panes of the standalone browser windows
/// (`WebBrowserWindowController.openWindows`): the directory of an app whose
/// browsers are windows of their own (ADBrowser), and the second half of the
/// Kitchen's, behind its project windows' panes (`CompositeBrowserPaneDirectory`).
///
/// A window is one pane, so a pane's id is its window's, its project is
/// `projectName` and its tab the window's title. There are no tabs to share,
/// so the pane "beside" a caller is the caller itself when it is one of these
/// browsers, and otherwise the browser in front. Opening a pane opens a new
/// window.
@MainActor
public final class StandaloneBrowserPaneDirectory: BrowserPaneDirectory {

    /// What every pane here reports as its project.
    public static let projectName = "Web Browser"

    private let windows: () -> [any StandaloneBrowserWindow]
    private let open: (BrowserEngineKind) -> (any StandaloneBrowserWindow)?
    private let focus: BrowserPaneFocus

    /// A directory over `windows` (the open browser windows, in any order),
    /// opening new ones with `open`. The defaults are the app's real
    /// browser windows.
    public init(
        windows: @escaping () -> [any StandaloneBrowserWindow] = { WebBrowserWindowController.openWindows },
        open: @escaping (BrowserEngineKind) -> (any StandaloneBrowserWindow)? = {
            WebBrowserWindowController.openNew(engine: $0)
        },
        focus: BrowserPaneFocus = .shared
    ) {
        self.windows = windows
        self.open = open
        self.focus = focus
    }

    /// The windows front to back, as the window server stacks them; any not
    /// on screen (minimized, or not yet shown) follow, newest first.
    private func windowsFrontToBack() -> [any StandaloneBrowserWindow] {
        let all = windows()
        let stacked = NSApp.orderedWindows.filter(\.isVisible).compactMap { window in
            all.first { $0.browserWindow === window }
        }
        let rest = all.reversed().filter { candidate in !stacked.contains { $0 === candidate } }
        return stacked + rest
    }

    private func handle(_ window: any StandaloneBrowserWindow) -> BrowserPaneHandle {
        BrowserPaneHandle(
            pane: window.pane, id: window.browserWindowID, project: Self.projectName,
            tab: window.browserWindowTitle)
    }

    /// Every window's pane the agent may know about, front first, with the
    /// handle made once for each. A hidden pane is left out here, the one
    /// place every lookup starts.
    private func located() -> [(window: any StandaloneBrowserWindow, handle: BrowserPaneHandle)] {
        let all = windowsFrontToBack().map { (window: $0, handle: handle($0)) }
        let shown = Set(Self.visible(all.map(\.handle)).map(\.id))
        return all.filter { shown.contains($0.handle.id) }
    }

    public func browserPanes() -> [BrowserPaneHandle] { located().map(\.handle) }

    public func browserPane(id: String) -> BrowserPaneHandle? {
        located().first { $0.handle.id == id }?.handle
    }

    /// The caller's own browser when it is one of these windows, else the
    /// browser in front.
    public func browserPane(besidePane paneID: String) -> BrowserPaneHandle? {
        let all = located()
        return (all.first { $0.handle.id == paneID } ?? all.first)?.handle
    }

    /// The browser last focused, appeared or driven while its window is
    /// open; else the one in front.
    public func lastUsedBrowserPane() -> BrowserPaneHandle? {
        let all = located()
        if let focused = focus.lastFocused, let item = all.first(where: { $0.window.pane === focused }) {
            return item.handle
        }
        return all.first?.handle
    }

    /// Opens a new browser window on `engine`, wherever the caller is.
    public func openBrowserPane(besidePane paneID: String?, engine: BrowserEngineKind) throws -> BrowserPaneHandle {
        guard let window = open(engine) else { throw BrowserAutomationError.openRefused }
        return handle(window)
    }

    public func revealBrowserPane(id: String) {
        located().first { $0.handle.id == id }?.window.revealBrowserWindow()
    }

    /// Closes the pane's window. Searches every window, hidden panes too,
    /// since a window just opened on a hidden pane is the one this exists
    /// to close.
    public func closeBrowserPane(id: String) {
        windows().first { $0.browserWindowID == id }?.closeBrowserWindow()
    }
}
