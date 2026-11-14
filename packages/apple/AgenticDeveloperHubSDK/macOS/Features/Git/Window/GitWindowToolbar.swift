import AppKit
import AgenticDeveloperHubSDKUI

/// The Git window's toolbar (recipe `workspace/git/git-window`, "Search drives
/// history" and "Refresh button"): a search field whose text goes to the history,
/// and a Refresh button.
///
/// Owned by the window controller: `NSToolbar.delegate` is weak, so the builder's
/// delegate is kept here for as long as the window is. The field's and the button's
/// accessibility identifiers are their item identifiers.
@MainActor
final class GitWindowToolbar: NSObject {

    static let searchIdentifier = NSToolbarItem.Identifier("git.window.search")
    static let refreshIdentifier = NSToolbarItem.Identifier("git.window.refresh")

    /// The search text, on every edit and when the field is cleared.
    var onSearch: ((String) -> Void)?
    var onRefresh: (() -> Void)?

    private var delegate: WindowToolbarBuilder.Delegate?

    /// Puts the toolbar on `window`.
    func install(in window: NSWindow) {
        let delegate = WindowToolbarBuilder.Delegate(
            items: [
                .flexibleSpace,
                .search(identifier: Self.searchIdentifier, placeholder: "Search history"),
                .button(
                    identifier: Self.refreshIdentifier,
                    symbol: "arrow.clockwise",
                    label: "Refresh",
                    action: #selector(refresh(_:)))
            ],
            target: self,
            onSearchFieldCreated: { [weak self] field in
                field.sendsSearchStringImmediately = true
                field.target = self
                field.action = #selector(GitWindowToolbar.searchChanged(_:))
            })
        self.delegate = delegate
        window.toolbar = delegate.makeToolbar(identifier: "git.window.toolbar")
        window.toolbarStyle = .unified
    }

    var searchField: NSSearchField? { delegate?.searchField }

    @objc private func refresh(_ sender: Any?) {
        onRefresh?()
    }

    @objc private func searchChanged(_ sender: NSSearchField) {
        onSearch?(sender.stringValue)
    }
}
