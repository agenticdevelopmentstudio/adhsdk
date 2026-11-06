import AppKit
import AgenticDeveloperHubSDKMacOS
import AgenticDeveloperHubSDKNotifications

/// The snooze choices as a menu, one item per `SnoozeOption` in its declared
/// order. Each item's target is retained by the item itself (as its
/// `representedObject`), since `NSMenuItem.target` is weak.
@MainActor
public enum SnoozeMenu {

    public static func make(_ onSelect: @escaping @MainActor (SnoozeOption) -> Void) -> NSMenu {
        let menu = NSMenu(title: "Snooze")
        menu.autoenablesItems = false
        for option in SnoozeOption.allCases {
            let target = ClosureMenuItemTarget(action: { onSelect(option) })
            let item = NSMenuItem(
                title: option.title,
                action: #selector(ClosureMenuItemTarget.performMenuAction(_:)),
                keyEquivalent: "")
            item.target = target
            item.representedObject = target
            item.isEnabled = true
            menu.addItem(item)
        }
        return menu
    }

    /// Runs an item the way choosing it would. For tests and keyboard paths.
    public static func perform(_ item: NSMenuItem) {
        (item.representedObject as? ClosureMenuItemTarget)?.performMenuAction(item)
    }
}
