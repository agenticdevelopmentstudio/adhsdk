import AppKit
import AgenticDeveloperHubSDKCore

/// The sidebar's Pull Requests section (recipe `workspace/git/git-views`, "Pull
/// requests"): present while `gh` answers (`pullRequests` not nil), one row per open
/// pull request, `#<number> <title>` with its draft or status symbol as the icon and its
/// check-state symbol as the badge, the checked-out branch's in bold.
extension GitRefsSidebarViewController {

    static let pullRequestsTitle = "Pull Requests"

    /// Every row, and every menu item, of the section is under this id.
    static let pullRequestsID = "git.sidebar.pullRequests"

    static func pullRequestRowID(_ number: Int) -> String { "\(pullRequestsID).\(number)" }

    /// The section's rows, in `gh`'s order (newest first), bold where the row is
    /// `headPullRequest`, the checked-out branch's own open pull request as `gh`'s
    /// per-branch lookup found it — never by branch name, which a fork's PR can share.
    func pullRequestRows(_ pullRequests: [GitPullRequest], headPullRequest: GitPullRequest?)
        -> [(item: TopicListItem, pullRequest: GitPullRequest)] {
        pullRequests.map { pullRequest in
            let symbol = GitPullRequestPresentation.statusSymbolName(pullRequest)
            let item = TopicListItem(
                id: Self.pullRequestRowID(pullRequest.number),
                title: "#\(pullRequest.number) \(pullRequest.title)",
                icon: NSImage(systemSymbolName: symbol, accessibilityDescription: nil),
                badge: GitPullRequestPresentation.checkSymbol(pullRequest.checks),
                isEmphasized: headPullRequest?.number == pullRequest.number)
            return (item, pullRequest)
        }
    }

    /// A row's menu: Check Out, Open in Browser and Copy URL.
    func pullRequestMenu(_ pullRequest: GitPullRequest) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(pullRequestItem("Check Out", "checkout", .checkout(pullRequest)))
        menu.addItem(pullRequestItem("Open in Browser", "open", .openInBrowser(pullRequest)))
        let copy = NSMenuItem(title: "Copy URL", action: #selector(copyPullRequestURL(_:)), keyEquivalent: "")
        copy.target = self
        copy.representedObject = MenuPayload(pullRequest.url)
        copy.accessibilityID("\(Self.pullRequestsID).menu.copyURL")
        menu.addItem(copy)
        return menu
    }

    /// The header's menu: `Create Pull Request for <head>…`; nil on a detached HEAD or
    /// when the branch already has its own open pull request (`headPullRequest`).
    func pullRequestsHeaderMenu(head: GitRef?, headPullRequest: GitPullRequest?) -> NSMenu? {
        guard let head, headPullRequest == nil else { return nil }
        let menu = NSMenu()
        menu.addItem(pullRequestItem("Create Pull Request for \(head.name)…", "create", .create))
        return menu
    }

    private func pullRequestItem(_ title: String, _ name: String, _ intent: GitPullRequestIntent) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(performPullRequestIntent(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = MenuPayload(intent)
        item.accessibilityID("\(Self.pullRequestsID).menu.\(name)")
        return item
    }

    @objc private func performPullRequestIntent(_ sender: NSMenuItem) {
        guard let intent = sender.payload(GitPullRequestIntent.self) else { return }
        delegate?.sidebar(self, didRequestPullRequest: intent)
    }

    /// Puts the pull request's URL on the general pasteboard; runs no `gh`.
    @objc private func copyPullRequestURL(_ sender: NSMenuItem) {
        guard let url = sender.payload(URL.self) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.absoluteString, forType: .string)
    }
}
