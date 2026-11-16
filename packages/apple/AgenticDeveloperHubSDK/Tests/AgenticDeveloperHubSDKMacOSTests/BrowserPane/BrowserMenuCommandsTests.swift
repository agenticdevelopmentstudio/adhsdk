import AppKit
import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The Browser menu's items: their order, fixed keys, ids, enablement against
/// the key pane's engine, and the privacy toolbar toggle's per-pane write.
@MainActor
final class BrowserMenuCommandsTests: XCTestCase {

    private var global: UserSettings!
    private var layered: LayeredSettingsStore!
    private var engine: StubBrowserEngine?

    override func setUp() async throws {
        try await super.setUp()
        global = UserSettings(
            with: InMemorySettingsStorageProvider(),
            secureSettingsProvider: InMemorySecureSettingsStorageProvider())
        layered = LayeredSettingsStore(
            overrides: PaneStateSettingsStorageProvider(store: EphemeralPaneStateStore()),
            fallback: global)
    }

    private func makePane() -> WebBrowserPaneViewController {
        let pane = WebBrowserPaneViewController(
            makeEngine: { [weak self] configuration in
                let made = StubBrowserEngine(consoleLog: configuration.consoleLog)
                self?.engine = made
                return made
            },
            engineKind: .safari, minimizedSymbol: "globe",
            store: EphemeralPaneStateStore(), settings: layered, history: nil,
            homeURL: WebBrowserPaneViewController.blankPage)
        _ = pane.view
        return pane
    }

    private func contributions(
        pane: WebBrowserPaneViewController?,
        paneFocused: Bool = true,
        canShowHistory: Bool = true,
        showHistory: @escaping () -> Void = {}
    ) -> [MenuContribution] {
        BrowserMenuCommands(
            keyPane: { pane }, focusedPane: { paneFocused ? pane : nil },
            canShowHistory: { canShowHistory }, showHistory: showHistory
        ).contributions()
    }

    /// Show History is disabled while the host has set no history store
    /// (final review C-M2).
    func test_showHistoryDisabledWithoutAStore() throws {
        let items = contributions(pane: nil, canShowHistory: false)
        XCTAssertFalse(try item(BrowserMenuCommands.ItemID.showHistory, in: items).isEnabled())
    }

    private func item(_ id: String, in items: [MenuContribution]) throws -> MenuContribution {
        try XCTUnwrap(items.first { $0.identifier == id }, "no item \(id)")
    }

    // browser-menu-002, browser-menu-003
    func test_itemOrderAndKeys() throws {
        let items = contributions(pane: nil)
        XCTAssertEqual(items.map { $0.dynamicTitle?() ?? $0.title },
                       ["Reload", "Stop", "Back", "Forward", "Show History", "Show Privacy Toolbar"])
        XCTAssertEqual(items.map(\.identifier), [
            "browser.reload", "browser.stop", "browser.back", "browser.forward",
            "browser.show-history", "browser.toggle-privacy-toolbar"
        ])
        XCTAssertTrue(items.allSatisfy { $0.slot == .browser })
        // The Show section starts a separator's worth of order after the page
        // commands.
        XCTAssertTrue(items.prefix(4).allSatisfy { $0.order < BrowserMenuCommands.showSectionOrder })
        XCTAssertTrue(items.suffix(2).allSatisfy { $0.order >= BrowserMenuCommands.showSectionOrder })

        let reload = try item(BrowserMenuCommands.ItemID.reload, in: items)
        let stop = try item(BrowserMenuCommands.ItemID.stop, in: items)
        XCTAssertEqual(reload.key, "r")
        XCTAssertEqual(reload.modifiers, .command)
        XCTAssertNil(reload.keyCommandID)
        XCTAssertEqual(stop.key, ".")
        XCTAssertEqual(stop.modifiers, .command)
        XCTAssertNil(stop.keyCommandID)
        XCTAssertEqual(try item(BrowserMenuCommands.ItemID.back, in: items).keyCommandID, "browser.back")
        XCTAssertEqual(try item(BrowserMenuCommands.ItemID.forward, in: items).keyCommandID, "browser.forward")

        // Reload and Stop are not the registry's; Back and Forward are, alone.
        let section = BrowserMenuCommands.keySection
        XCTAssertEqual(section.title, "Web Browser")
        XCTAssertEqual(section.allCommands.map(\.id), ["browser.back", "browser.forward"])
    }

    // browser-menu-008, browser-menu-012
    func test_itemsDisableWithoutKeyPane() throws {
        var historyShown = 0
        let items = contributions(pane: nil, showHistory: { historyShown += 1 })
        for contribution in items where contribution.identifier != BrowserMenuCommands.ItemID.showHistory {
            XCTAssertFalse(contribution.isEnabled(), "\(contribution.title) enabled with no key pane")
            contribution.action()   // must not crash
        }
        let showHistory = try item(BrowserMenuCommands.ItemID.showHistory, in: items)
        XCTAssertTrue(showHistory.isEnabled())
        showHistory.action()
        XCTAssertEqual(historyShown, 1)
    }

    // browser-menu-009, browser-menu-010, browser-menu-004
    func test_backDisabledWhenCannotGoBack() throws {
        let pane = makePane()
        let stub = try XCTUnwrap(engine)
        stub.canGoBack = false
        stub.canGoForward = true
        let items = contributions(pane: pane)
        let back = try item(BrowserMenuCommands.ItemID.back, in: items)
        let forward = try item(BrowserMenuCommands.ItemID.forward, in: items)
        XCTAssertFalse(back.isEnabled())
        XCTAssertTrue(forward.isEnabled())

        stub.canGoBack = true
        XCTAssertTrue(back.isEnabled())
        back.action()
        forward.action()
        try item(BrowserMenuCommands.ItemID.reload, in: items).action()
        XCTAssertEqual(stub.navigationCalls, ["back", "forward", "reload"])
    }

    // browser-menu-011
    func test_stopDisabledWhenNotLoading() throws {
        let pane = makePane()
        let stub = try XCTUnwrap(engine)
        let stop = try item(BrowserMenuCommands.ItemID.stop, in: contributions(pane: pane))
        stub.isLoading = false
        XCTAssertFalse(stop.isEnabled())
        stub.isLoading = true
        XCTAssertTrue(stop.isEnabled())
        stop.action()
        XCTAssertEqual(stub.navigationCalls, ["stop"])
    }

    // browser-menu-013, browser-menu-014
    func test_togglePrivacyToolbarWritesPaneOverride() throws {
        global.set(false, for: UserSettings.browserPrivacyShowToolbar)
        let pane = makePane()
        XCTAssertFalse(layered.hasOverride(UserSettings.browserPrivacyShowToolbar))
        let toggle = try item(BrowserMenuCommands.ItemID.togglePrivacyToolbar, in: contributions(pane: pane))
        XCTAssertTrue(toggle.isEnabled())
        XCTAssertEqual(toggle.dynamicTitle?(), "Show Privacy Toolbar")

        toggle.action()

        XCTAssertTrue(layered.hasOverride(UserSettings.browserPrivacyShowToolbar))
        XCTAssertTrue(layered.get(UserSettings.browserPrivacyShowToolbar))
        XCTAssertFalse(global.get(UserSettings.browserPrivacyShowToolbar), "the global value moved")
        XCTAssertEqual(toggle.dynamicTitle?(), "Hide Privacy Toolbar")
    }

    /// The Back and Forward items carry ⌘[ and ⌘], so with the key pane not
    /// focused — an editor or terminal beside it has the first responder —
    /// they are disabled and do nothing, and the keys reach that view; the
    /// other page items keep acting on the key pane (review f15).
    func test_backAndForwardItemsNeedThePaneFocused() throws {
        let pane = makePane()
        let stub = try XCTUnwrap(engine)
        stub.canGoBack = true
        stub.canGoForward = true
        let items = contributions(pane: pane, paneFocused: false)
        let back = try item(BrowserMenuCommands.ItemID.back, in: items)
        let forward = try item(BrowserMenuCommands.ItemID.forward, in: items)
        XCTAssertFalse(back.isEnabled())
        XCTAssertFalse(forward.isEnabled())
        back.action()
        forward.action()
        XCTAssertEqual(stub.navigationCalls, [])

        let reload = try item(BrowserMenuCommands.ItemID.reload, in: items)
        XCTAssertTrue(reload.isEnabled())
        reload.action()
        XCTAssertEqual(stub.navigationCalls, ["reload"])
    }

    /// ⌘[ and ⌘] act on a browser pane only while it has keyboard focus, so
    /// the keys reach an editor or terminal beside it (final review C-M1).
    func test_keyCommandsNeedThePaneFocused() throws {
        final class Focusable: NSView {
            override var acceptsFirstResponder: Bool { true }
        }
        let pane = makePane()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let content = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = content
        pane.view.frame = NSRect(x: 0, y: 0, width: 200, height: 300)
        content.addSubview(pane.view)
        let inside = Focusable(frame: NSRect(x: 0, y: 0, width: 10, height: 10))
        pane.view.addSubview(inside)
        let beside = Focusable(frame: NSRect(x: 210, y: 0, width: 10, height: 10))
        content.addSubview(beside)
        BrowserPaneFocus.shared.note(pane)

        XCTAssertTrue(window.makeFirstResponder(beside))
        XCTAssertTrue(WebBrowserPaneViewController.keyPane(in: window) === pane, "the menu still finds it")
        XCTAssertNil(WebBrowserPaneViewController.focusedKeyPane(in: window))

        XCTAssertTrue(window.makeFirstResponder(inside))
        XCTAssertTrue(WebBrowserPaneViewController.focusedKeyPane(in: window) === pane)
    }
}
