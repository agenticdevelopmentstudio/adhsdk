import AppKit
import AgenticDeveloperHubSDKUI

/// The Git window's toolbar verbs (recipe `workspace/git/git-window`, "Toolbar"):
/// Fetch, Pull, Push, Branch, Stash, Pop and Undo, then the Command Log toggle, each a
/// `.targetedButton` aimed at this object, which forwards it to its session.
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

    /// The window whose toolbar holds these items, where Undo's button is found to enable
    /// and retitle (`GitWindowToolbar+Undo`); nil until the feature sets it.
    weak var window: NSWindow?
    /// The model observation that keeps Undo current; held for as long as this object.
    var undoObservation: AnyObject?

    /// Whether the Command Log toggle is offered: only a layout with a terminal region
    /// has somewhere to put the Command Log, so a window built without terminals leaves
    /// the button out rather than showing one that can do nothing.
    let showsCommandLog: Bool

    init(showsCommandLog: Bool = true) {
        self.showsCommandLog = showsCommandLog
        super.init()
    }

    /// The buttons, in order, every one aimed at this object: eight, or seven without the
    /// Command Log toggle.
    var items: [WindowToolbarItem] {
        let target = WindowToolbarTarget(self)
        let specs = showsCommandLog ? Self.specs : Self.specs.filter { $0.identifier != Self.commandLogIdentifier }
        return specs.map { spec in
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

    static let commandLogIdentifier = "git.toolbar.commandLog"

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
             action: #selector(GitWindowToolbar.popStash(_:))),
        Spec(identifier: undoIdentifier, label: "Undo", symbol: "arrow.uturn.backward",
             action: #selector(GitWindowToolbar.undo(_:))),
        Spec(identifier: commandLogIdentifier, label: "Command Log", symbol: "list.bullet.rectangle",
             action: #selector(GitWindowToolbar.toggleCommandLog(_:)))
    ]

    /// Fetches, or while the repository uses LFS shows the Fetch menu (`GitWindowToolbar+LFS`).
    @objc func fetch(_ sender: Any?) { fetchPressed(sender) }
    @objc func pull(_ sender: Any?) { session?.pull() }
    @objc func push(_ sender: Any?) { session?.push() }
    @objc func newBranch(_ sender: Any?) { session?.newBranch() }
    @objc func stash(_ sender: Any?) { session?.stash() }
    @objc func popStash(_ sender: Any?) { session?.popStash() }
    @objc func undo(_ sender: Any?) { session?.undo() }
    @objc func toggleCommandLog(_ sender: Any?) { session?.toggleCommandLog() }
}
