import AppKit
import AgenticDeveloperHubSDKUI

/// The Git window's toolbar verbs (recipe `workspace/git/git-window`, "Toolbar"):
/// Fetch, Pull, Push, Branch, Stash and Pop, each a `.targetedButton` aimed at this
/// object, which forwards it to its session's verb.
///
/// The window is the project window's controller, which owns its toolbar delegate and
/// knows nothing of git, so these items are handed to it as extras and answered here.
/// The feature keeps this object beside the session and drops it when the window
/// closes; the buttons hold it weakly, and it holds the session weakly.
@MainActor
final class GitWindowToolbar: NSObject {

    /// The session the buttons act on; nil until the window's session exists, when
    /// every button does nothing.
    weak var session: GitWindowSession?

    /// The six buttons, in order, every one aimed at this object.
    var items: [WindowToolbarItem] {
        let target = WindowToolbarTarget(self)
        return Self.specs.map { spec in
            .targetedButton(
                identifier: NSToolbarItem.Identifier(spec.identifier), symbol: spec.symbol,
                label: spec.label, target: target, action: spec.action)
        }
    }

    private struct Spec {
        let identifier: String
        let label: String
        let symbol: String
        let action: Selector
    }

    private static let specs: [Spec] = [
        Spec(identifier: "git.toolbar.fetch", label: "Fetch", symbol: "arrow.down.circle",
             action: #selector(GitWindowToolbar.fetch(_:))),
        Spec(identifier: "git.toolbar.pull", label: "Pull", symbol: "arrow.down.to.line",
             action: #selector(GitWindowToolbar.pull(_:))),
        Spec(identifier: "git.toolbar.push", label: "Push", symbol: "arrow.up.to.line",
             action: #selector(GitWindowToolbar.push(_:))),
        Spec(identifier: "git.toolbar.branch", label: "Branch", symbol: "arrow.triangle.branch",
             action: #selector(GitWindowToolbar.newBranch(_:))),
        Spec(identifier: "git.toolbar.stash", label: "Stash", symbol: "tray.and.arrow.down",
             action: #selector(GitWindowToolbar.stash(_:))),
        Spec(identifier: "git.toolbar.pop", label: "Pop", symbol: "tray.and.arrow.up",
             action: #selector(GitWindowToolbar.popStash(_:)))
    ]

    @objc func fetch(_ sender: Any?) { session?.fetch() }
    @objc func pull(_ sender: Any?) { session?.pull() }
    @objc func push(_ sender: Any?) { session?.push() }
    @objc func newBranch(_ sender: Any?) { session?.newBranch() }
    @objc func stash(_ sender: Any?) { session?.stash() }
    @objc func popStash(_ sender: Any?) { session?.popStash() }
}
