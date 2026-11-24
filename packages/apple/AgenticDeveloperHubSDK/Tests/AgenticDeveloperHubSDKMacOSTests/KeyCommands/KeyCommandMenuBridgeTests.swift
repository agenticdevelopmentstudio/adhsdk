import AppKit
import XCTest
@preconcurrency import KeyboardShortcuts
@testable import AgenticDeveloperHubSDKMacOS

/// A menu item bound to a registered key command shows that command's current
/// chord, follows a rebind without the menu being rebuilt, and shows nothing
/// for a cleared or switched-off binding.
///
/// Bindings persist through `UserSettings`, which every registry shares, so
/// each test resets the ids it touched.
@MainActor
final class KeyCommandMenuBridgeTests: XCTestCase {

    private let registry = KeyCommandRegistry()
    private let touched = [BrowserMenuCommands.ItemID.back, BrowserMenuCommands.ItemID.forward]

    override func setUp() async throws {
        try await super.setUp()
        touched.forEach(registry.resetBinding(for:))
        registry.install(BrowserMenuCommands.keySection)
    }

    override func tearDown() async throws {
        touched.forEach(registry.resetBinding(for:))
        try await super.tearDown()
    }

    private func boundItem(_ id: String) -> NSMenuItem {
        let item = NSMenuItem(title: id, action: nil, keyEquivalent: "")
        KeyCommandMenuBridge.bind(item, toCommand: id, registry: registry)
        return item
    }

    // browser-menu-015, browser-menu-016
    func test_rebindUpdatesMenuItem() throws {
        let back = boundItem(BrowserMenuCommands.ItemID.back)
        XCTAssertEqual(back.keyEquivalent, "[")
        XCTAssertEqual(back.keyEquivalentModifierMask.intersection(.deviceIndependentFlagsMask), .command)

        let chord = KeyboardShortcuts.Shortcut(.leftArrow, modifiers: [.command, .option])
        registry.setBinding(KeyCommandBinding(shortcut: chord, isEnabled: true),
                            for: BrowserMenuCommands.ItemID.back)

        XCTAssertEqual(back.keyEquivalent, try XCTUnwrap(chord.nsMenuItemKeyEquivalent))
        XCTAssertEqual(back.keyEquivalentModifierMask.intersection(.deviceIndependentFlagsMask),
                       [.command, .option])
    }

    // browser-menu-017
    func test_clearedBindingRemovesMenuKey() {
        let back = boundItem(BrowserMenuCommands.ItemID.back)
        let forward = boundItem(BrowserMenuCommands.ItemID.forward)
        XCTAssertEqual(forward.keyEquivalent, "]")

        registry.setBinding(
            KeyCommandBinding(shortcut: KeyboardShortcuts.Shortcut(.leftBracket, modifiers: .command),
                              isEnabled: false),
            for: BrowserMenuCommands.ItemID.back)
        registry.setBinding(KeyCommandBinding(shortcut: nil, isEnabled: true),
                            for: BrowserMenuCommands.ItemID.forward)

        XCTAssertEqual(back.keyEquivalent, "")
        XCTAssertEqual(forward.keyEquivalent, "")
    }
}
