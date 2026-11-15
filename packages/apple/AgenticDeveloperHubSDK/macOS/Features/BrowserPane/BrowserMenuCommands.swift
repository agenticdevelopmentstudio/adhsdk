//
//  BrowserMenuCommands.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import KeyboardShortcuts
import AgenticDeveloperHubSDKCoreUI

/// The Browser menu: Reload, Stop, Back and Forward for the browser pane in
/// the key window, then Show History and Show / Hide Privacy Toolbar.
///
/// Every page command acts on one pane, the one `keyPane` answers — by
/// default `WebBrowserPaneViewController.keyPane()`, the key window's — and
/// disables when there is none rather than reaching into a window the person
/// is not looking at (`principle-of-least-astonishment`). The provider is
/// injected so the rules can be tested without a key window
/// (`dependency-injection`).
///
/// Reload and Stop keep fixed keys. Back and Forward are commands in the
/// Keyboard Shortcuts registry (``keySection``), and their items name those
/// commands (`MenuContribution.keyCommandID`), so the host shows whatever the
/// person has bound them to.
@MainActor
public final class BrowserMenuCommands {

    /// The items' stable ids, which are also their accessibility identifiers
    /// under the host's menu prefix. They do not change with a title.
    public enum ItemID {
        public static let reload = "browser.reload"
        public static let stop = "browser.stop"
        public static let back = "browser.back"
        public static let forward = "browser.forward"
        public static let showHistory = "browser.show-history"
        public static let togglePrivacyToolbar = "browser.toggle-privacy-toolbar"
    }

    /// The section title Back and Forward are listed under in Settings ›
    /// Keyboard.
    public static let keySectionTitle = "Web Browser"

    /// Where the Show section starts: the host draws a separator between the
    /// items ordered below this and the rest.
    public static let showSectionOrder = 100

    /// Back and Forward as bindable commands, shipped as ⌘[ and ⌘]. Only
    /// these two: Reload and Stop keep fixed keys and are not the
    /// registry's, so the registry cannot report them as clashing with
    /// these (`back-forward-in-registry`, `fixed-keys-not-conflicts`).
    ///
    /// A keystroke reaches the registry's monitor before the menu, so each
    /// command performs itself; it declines — passing the key on — when the
    /// key window has no pane that can go that way.
    public static let keySection = KeyCommandSection(
        title: keySectionTitle,
        scope: .app,
        commands: [
            KeyCommandDescriptor(
                id: ItemID.back, title: "Back",
                defaultShortcut: KeyboardShortcuts.Shortcut(.leftBracket, modifiers: .command),
                perform: { navigate(WebBrowserPaneViewController.keyPane(), back: true) }),
            KeyCommandDescriptor(
                id: ItemID.forward, title: "Forward",
                defaultShortcut: KeyboardShortcuts.Shortcut(.rightBracket, modifiers: .command),
                perform: { navigate(WebBrowserPaneViewController.keyPane(), back: false) })
        ])

    private let keyPane: () -> WebBrowserPaneViewController?
    private let showHistory: () -> Void

    /// - Parameters:
    ///   - keyPane: The pane the page commands act on, asked each time an
    ///     item is validated or chosen; `nil` disables them.
    ///   - showHistory: What Show History does — open the History window.
    public init(
        keyPane: @escaping () -> WebBrowserPaneViewController? = { WebBrowserPaneViewController.keyPane() },
        showHistory: @escaping () -> Void = { BrowserHistoryWindowController.show() }
    ) {
        self.keyPane = keyPane
        self.showHistory = showHistory
    }

    /// The Browser menu's items, in menu order, all in `.browser`.
    public func contributions() -> [MenuContribution] {
        let keyPane = self.keyPane
        let showHistory = self.showHistory
        return [
            MenuContribution(
                slot: .browser, title: "Reload", order: 0, key: "r",
                isEnabled: { keyPane() != nil },
                identifier: ItemID.reload,
                action: { keyPane()?.engine.reload() }),
            MenuContribution(
                slot: .browser, title: "Stop", order: 1, key: ".",
                isEnabled: { keyPane()?.engine.isLoading == true },
                identifier: ItemID.stop,
                action: { keyPane()?.engine.stopLoading() }),
            MenuContribution(
                slot: .browser, title: "Back", order: 2,
                isEnabled: { keyPane()?.engine.canGoBack == true },
                identifier: ItemID.back,
                keyCommandID: ItemID.back,
                action: { _ = Self.navigate(keyPane(), back: true) }),
            MenuContribution(
                slot: .browser, title: "Forward", order: 3,
                isEnabled: { keyPane()?.engine.canGoForward == true },
                identifier: ItemID.forward,
                keyCommandID: ItemID.forward,
                action: { _ = Self.navigate(keyPane(), back: false) }),
            // Enabled whatever the key window is: the History window opens a
            // visit in a new browser window when no pane is in front.
            MenuContribution(
                slot: .browser, title: "Show History", order: Self.showSectionOrder,
                identifier: ItemID.showHistory,
                action: showHistory),
            MenuContribution(
                slot: .browser, title: Self.privacyToolbarTitle(for: keyPane()),
                order: Self.showSectionOrder + 1,
                isEnabled: { keyPane() != nil },
                identifier: ItemID.togglePrivacyToolbar,
                dynamicTitle: { Self.privacyToolbarTitle(for: keyPane()) },
                action: { Self.togglePrivacyToolbar(on: keyPane()) })
        ]
    }

    /// "Hide Privacy Toolbar" while the pane's effective value is on, "Show
    /// Privacy Toolbar" while it is off or there is no pane.
    static func privacyToolbarTitle(for pane: WebBrowserPaneViewController?) -> String {
        pane?.isPrivacyStripShown == true ? "Hide Privacy Toolbar" : "Show Privacy Toolbar"
    }

    /// Flips the pane's own value — a write to its layered store, the same one
    /// the checkbox in its privacy popover makes — never the global one.
    static func togglePrivacyToolbar(on pane: WebBrowserPaneViewController?) {
        guard let pane else { return }
        pane.isPrivacyStripShown.toggle()
    }

    /// Goes back or forward in `pane`, and says whether it could. The target
    /// is re-resolved by the caller each time, so a pane that closed between
    /// the menu opening and the choice is simply not there.
    @discardableResult
    static func navigate(_ pane: WebBrowserPaneViewController?, back: Bool) -> Bool {
        guard let engine = pane?.engine else { return false }
        if back {
            guard engine.canGoBack else { return false }
            engine.goBack()
        } else {
            guard engine.canGoForward else { return false }
            engine.goForward()
        }
        return true
    }
}

public extension WebBrowserPaneViewController {

    /// The browser pane the Browser menu acts on: the key window's standalone
    /// browser pane, else the most recently focused pane when it is in the key
    /// window, else `nil` — never a pane in a window that is not key.
    ///
    /// "The key window" is the registry's ``KeyCommandRegistry/commandWindow``:
    /// the window a keystroke being performed was sent to, otherwise the key
    /// window, and for a child window (a Chrome pane's page) the window it is
    /// attached to.
    static func keyPane() -> WebBrowserPaneViewController? {
        keyPane(in: KeyCommandRegistry.shared.commandWindow)
    }

    /// ``keyPane()`` for `window` rather than the key window.
    static func keyPane(in window: NSWindow?) -> WebBrowserPaneViewController? {
        guard let window = window?.commandOwner else { return nil }
        if let standalone = window.windowController as? WebBrowserWindowController {
            return standalone.pane
        }
        if let focused = BrowserPaneFocus.shared.lastFocused,
           focused.viewIfLoaded?.window?.commandOwner === window {
            return focused
        }
        return nil
    }
}
