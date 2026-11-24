import AppKit
import AgenticDeveloperHubSDKCore

/// The local branch menu's "Agent Sessions" submenu (recipe `workspace/git/git-views`,
/// "Agent sessions"): the sessions that ran on the branch, newest first, at most
/// `maximumAgentSessions`; absent when there are none or no provider. Choosing one opens
/// it through `onOpenAgentSession`; while that is nil the items are disabled.
extension GitRefsSidebarViewController {
    /// The most sessions the submenu lists.
    static let maximumAgentSessions = 20

    func addAgentSessionsSubmenu(to menu: NSMenu, for ref: GitRef) {
        guard let sessions = agentSessionsOnBranch?(ref), !sessions.isEmpty else { return }
        let submenu = NSMenu(title: "Agent Sessions")
        // Without a target and action the menu disables the item; with them it is enabled.
        let opens = onOpenAgentSession != nil
        for session in sessions.prefix(Self.maximumAgentSessions) {
            let item = NSMenuItem(
                title: GitAgentSessionsView.rowTitle(session),
                action: opens ? #selector(openAgentSession(_:)) : nil, keyEquivalent: "")
            item.target = opens ? self : nil
            item.representedObject = MenuPayload(session.id)
            item.toolTip = session.cwd
            item.accessibilityID("git.sidebar.menu.sessions.item")
            submenu.addItem(item)
        }
        let parent = NSMenuItem(title: "Agent Sessions", action: nil, keyEquivalent: "")
        parent.submenu = submenu
        parent.accessibilityID("git.sidebar.menu.sessions")
        menu.addItem(.separator())
        menu.addItem(parent)
    }

    @objc private func openAgentSession(_ sender: NSMenuItem) {
        guard let id = sender.payload(String.self) else { return }
        onOpenAgentSession?(id)
    }
}
