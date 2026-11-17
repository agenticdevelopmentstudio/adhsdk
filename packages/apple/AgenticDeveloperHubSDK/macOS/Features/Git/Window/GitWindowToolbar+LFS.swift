import AppKit

/// The Fetch menu (recipe `workspace/git/git-views`, "LFS"): while the repository uses
/// Git LFS, the Fetch button opens a menu of Fetch, Fetch LFS Objects and Pull LFS Objects
/// under itself; otherwise it fetches, as it always has. The toolbar's items are the same
/// either way.
extension GitWindowToolbar {

    static let lfsFetchIdentifier = "git.toolbar.lfsFetch"
    static let lfsPullIdentifier = "git.toolbar.lfsPull"

    /// The Fetch menu: Fetch, then the two LFS items only when `lfsInUse`. Every item is
    /// aimed at this object.
    func fetchMenu(lfsInUse: Bool) -> NSMenu {
        let menu = NSMenu(title: "Fetch")
        menu.autoenablesItems = false
        menu.addItem(item("Fetch", identifier: "git.toolbar.fetchMenu.fetch", action: #selector(fetchNow(_:))))
        if lfsInUse {
            menu.addItem(item("Fetch LFS Objects", identifier: Self.lfsFetchIdentifier,
                              action: #selector(lfsFetch(_:))))
            menu.addItem(item("Pull LFS Objects", identifier: Self.lfsPullIdentifier,
                              action: #selector(lfsPull(_:))))
        }
        return menu
    }

    /// The Fetch button: the Fetch menu under the button while the session's repository
    /// uses LFS, a fetch otherwise (and always from the overflow menu, which has no button
    /// to open a menu under).
    func fetchPressed(_ sender: Any?) {
        guard let session else { return }
        guard session.usesLFS, let button = sender as? NSView else {
            session.fetch()
            return
        }
        let menu = fetchMenu(lfsInUse: true)
        let below = button.isFlipped ? button.bounds.maxY + 4 : button.bounds.minY - 4
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: below), in: button)
    }

    @objc func fetchNow(_ sender: Any?) { session?.fetch() }
    @objc func lfsFetch(_ sender: Any?) { session?.lfsFetch() }
    @objc func lfsPull(_ sender: Any?) { session?.lfsPull() }

    private func item(_ title: String, identifier: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.identifier = NSUserInterfaceItemIdentifier(identifier)
        item.accessibilityID(identifier)
        return item
    }
}
