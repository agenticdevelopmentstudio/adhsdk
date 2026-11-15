import AppKit
import Testing
@testable import AgenticDeveloperHubSDKMacOS

/// Pins the row-menu helpers every table view's `menuNeedsUpdate(_:)` uses:
/// `replaceItems(withItemsOf:)` moves a built menu's items across in order and
/// clears out what was there, and `MenuPayload` round-trips a value through
/// `representedObject`.
@Suite("ContextMenuSupport")
@MainActor
struct ContextMenuSupportTests {

    private func menu(_ titles: String...) -> NSMenu {
        let menu = NSMenu()
        for title in titles { menu.addItem(withTitle: title, action: nil, keyEquivalent: "") }
        return menu
    }

    @Test func replaceItemsMovesTheSourceItemsInOrder() {
        let target = menu("stale")
        let source = menu("one", "two")
        source.insertItem(.separator(), at: 1)
        target.replaceItems(withItemsOf: source)
        #expect(target.items.map(\.title) == ["one", "", "two"])
        #expect(target.items[1].isSeparatorItem)
        #expect(source.items.isEmpty)
    }

    @Test func replaceItemsWithNilEmptiesTheMenu() {
        let target = menu("stale", "older")
        target.replaceItems(withItemsOf: nil)
        #expect(target.items.isEmpty)
    }

    @Test func payloadRoundTripsItsValue() {
        let item = NSMenuItem(title: "x", action: nil, keyEquivalent: "")
        item.representedObject = MenuPayload((name: "checkout", row: 2))
        let value = item.payload((name: String, row: Int).self)
        #expect(value?.name == "checkout")
        #expect(value?.row == 2)
    }

    @Test func payloadOfAnotherTypeIsNil() {
        let item = NSMenuItem(title: "x", action: nil, keyEquivalent: "")
        item.representedObject = MenuPayload("text")
        #expect(item.payload(Int.self) == nil)
        item.representedObject = "not a payload"
        #expect(item.payload(String.self) == nil)
    }
}
