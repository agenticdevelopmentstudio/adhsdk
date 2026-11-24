import AppKit

public extension NSMenu {
    /// Empties this menu and moves `source`'s items into it, in order, leaving `source`
    /// empty (an item can belong to only one menu). With a nil `source` the menu is
    /// left empty, which AppKit does not show.
    ///
    /// This is the body of a row-menu `menuNeedsUpdate(_:)`: a view keeps one menu on
    /// its table, builds a fresh menu for the clicked row, and moves that menu's items
    /// across as the table's menu opens.
    func replaceItems(withItemsOf source: NSMenu?) {
        removeAllItems()
        guard let source else { return }
        let items = source.items
        source.removeAllItems()
        for item in items { addItem(item) }
    }
}

/// Carries a value of any type as an `NSMenuItem.representedObject`, which must be an object.
public final class MenuPayload<Value>: NSObject {
    public let value: Value
    public init(_ value: Value) { self.value = value }
}

public extension NSMenuItem {
    /// The value a `MenuPayload<Value>` carries as this item's represented object,
    /// or nil when it carries none or another type.
    func payload<Value>(_ type: Value.Type = Value.self) -> Value? {
        (representedObject as? MenuPayload<Value>)?.value
    }
}
