import Foundation

/// One Browser pane as the tool set sees it. Title and URL are read live
/// from `automation`, so a handle never goes stale on its own.
@MainActor
public struct BrowserPaneHandle {
    public let id: String
    public let project: String
    public let tab: String
    public let automation: BrowserAutomation
    /// The pane's Agent access setting, as it stood when the handle was made.
    /// The tool set takes a fresh handle once a call is dequeued, so a change
    /// made while the call waited is the one that counts.
    public let access: BrowserAgentAccess
    /// Whether the pane's events are paused **and** its settings pause the
    /// agent too (`agent_while_paused == .paused`). A paused pane whose
    /// settings let the agent keep driving reads `false` here.
    public let isPausedForAgent: Bool

    public init(
        id: String, project: String, tab: String, automation: BrowserAutomation,
        access: BrowserAgentAccess = .full, isPausedForAgent: Bool = false
    ) {
        self.id = id; self.project = project; self.tab = tab; self.automation = automation
        self.access = access; self.isPausedForAgent = isPausedForAgent
    }

    public var title: String { automation.currentTitle }
    public var url: String { automation.currentURL }
}

/// How the tool set finds Browser panes. The app supplies the real one over
/// its windows; tests supply a fake.
///
/// Finding a pane, and opening one, change nothing on screen: the tool set
/// first checks the pane's Agent access, and only a call that passes asks
/// for `revealBrowserPane(id:)`. A refused call must leave no trace.
@MainActor
public protocol BrowserPaneDirectory: AnyObject {
    /// Every open Browser pane, front window first.
    func browserPanes() -> [BrowserPaneHandle]
    func browserPane(id: String) -> BrowserPaneHandle?
    /// A Browser pane in the same tab as the pane with this node id.
    func browserPane(besidePane paneID: String) -> BrowserPaneHandle?
    /// The Browser pane most recently active, if still open.
    func lastUsedBrowserPane() -> BrowserPaneHandle?
    /// Opens a Browser pane beside the caller's pane (or in the front
    /// window when nil / unknown) and returns it.
    func openBrowserPane(besidePane paneID: String?) throws -> BrowserPaneHandle
    /// Puts the pane's project on screen, for a call about to drive it: a
    /// screenshot of an ordered-out window fails, and a pane driven there is
    /// one nobody can see. Called only after the call's access check passed.
    func revealBrowserPane(id: String)
    /// Closes a Browser pane, the way its close button would. Used for a pane
    /// `openBrowserPane` made whose settings refuse the agent, so a refused
    /// open leaves nothing behind. Looks among every pane, hidden ones too.
    func closeBrowserPane(id: String)
}

extension BrowserPaneDirectory {
    /// The handles the agent may know about: every pane but those whose
    /// Agent access is `hidden`. A directory applies it to everything it
    /// lists or finds by id, so a hidden pane is not listed, not the default
    /// target and not reachable by id. The rule lives here rather than in
    /// each app's directory so every directory hides the same panes.
    public static func visible(_ handles: [BrowserPaneHandle]) -> [BrowserPaneHandle] {
        handles.filter { $0.access != .hidden }
    }
}
