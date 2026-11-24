//
//  BrowserMenuCommands.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import KeyboardShortcuts
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The Browser menu: Reload, Stop, Back and Forward for the browser pane in
/// the key window, then Show History and Show / Hide Privacy Toolbar.
///
/// Reload, Stop and the privacy toolbar toggle act on one pane, the one
/// `keyPane` answers — by default `WebBrowserPaneViewController.keyPane()`,
/// the key window's. Back and Forward act on the one `focusedPane` answers —
/// by default `focusedKeyPane()`, that pane only while it has keyboard focus —
/// because their items carry ⌘[ and ⌘]: an item enabled for a pane merely
/// focused last would take those keys from an editor or terminal beside it.
/// Each disables when its pane is missing rather than reaching into a window the person
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
    /// key window has no pane that can go that way, or when the browser pane
    /// is not the one with keyboard focus, so ⌘[ and ⌘] still reach an editor
    /// or terminal beside it.
    public static let keySection = KeyCommandSection(
        title: keySectionTitle,
        scope: .app,
        commands: [
            KeyCommandDescriptor(
                id: ItemID.back, title: "Back",
                defaultShortcut: KeyboardShortcuts.Shortcut(.leftBracket, modifiers: .command),
                perform: { navigate(WebBrowserPaneViewController.focusedKeyPane(), back: true) }),
            KeyCommandDescriptor(
                id: ItemID.forward, title: "Forward",
                defaultShortcut: KeyboardShortcuts.Shortcut(.rightBracket, modifiers: .command),
                perform: { navigate(WebBrowserPaneViewController.focusedKeyPane(), back: false) })
        ])

    private let keyPane: () -> WebBrowserPaneViewController?
    private let focusedPane: () -> WebBrowserPaneViewController?
    private let canShowHistory: () -> Bool
    private let showHistory: () -> Void

    /// - Parameters:
    ///   - keyPane: The pane the page commands act on, asked each time an
    ///     item is validated or chosen; `nil` disables them.
    ///   - focusedPane: The pane Back and Forward act on, asked the same way:
    ///     the key pane only while it has keyboard focus; `nil` disables them.
    ///   - canShowHistory: Whether there is a history to show; Show History
    ///     is disabled while there is not.
    ///   - showHistory: What Show History does — open the History window.
    public init(
        keyPane: @escaping () -> WebBrowserPaneViewController? = { WebBrowserPaneViewController.keyPane() },
        focusedPane: @escaping () -> WebBrowserPaneViewController? = {
            WebBrowserPaneViewController.focusedKeyPane()
        },
        canShowHistory: @escaping () -> Bool = { BrowserHistoryWindowController.canShow },
        showHistory: @escaping () -> Void = { BrowserHistoryWindowController.show() }
    ) {
        self.keyPane = keyPane
        self.focusedPane = focusedPane
        self.canShowHistory = canShowHistory
        self.showHistory = showHistory
    }

    /// The Browser menu's items, in menu order, all in `.browser`.
    public func contributions() -> [MenuContribution] {
        let keyPane = self.keyPane
        let focusedPane = self.focusedPane
        let showHistory = self.showHistory
        let canShowHistory = self.canShowHistory
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
                isEnabled: { focusedPane()?.engine.canGoBack == true },
                identifier: ItemID.back,
                keyCommandID: ItemID.back,
                action: { _ = Self.navigate(focusedPane(), back: true) }),
            MenuContribution(
                slot: .browser, title: "Forward", order: 3,
                isEnabled: { focusedPane()?.engine.canGoForward == true },
                identifier: ItemID.forward,
                keyCommandID: ItemID.forward,
                action: { _ = Self.navigate(focusedPane(), back: false) }),
            // Enabled whatever the key window is — the History window opens
            // a visit in a new browser window when no pane is in front — but
            // only while the host has given it a history to show.
            MenuContribution(
                slot: .browser, title: "Show History", order: Self.showSectionOrder,
                isEnabled: canShowHistory,
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
        pane?.settings.get(UserSettings.browserPrivacyShowToolbar) == true
            ? "Hide Privacy Toolbar" : "Show Privacy Toolbar"
    }

    /// Flips the pane's own value — a write to its layered store, the same one
    /// the checkbox in its privacy popover makes — never the global one.
    static func togglePrivacyToolbar(on pane: WebBrowserPaneViewController?) {
        guard let pane else { return }
        let shown = pane.settings.get(UserSettings.browserPrivacyShowToolbar)
        pane.settings.set(!shown, for: UserSettings.browserPrivacyShowToolbar)
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

    /// ``keyPane()`` only while that pane has keyboard focus — what ⌘[ and ⌘]
    /// act on, as key commands and as the Back and Forward items that carry
    /// them, where Reload, Stop and the toolbar toggle act on the last focused
    /// pane.
    static func focusedKeyPane() -> WebBrowserPaneViewController? {
        focusedKeyPane(in: KeyCommandRegistry.shared.commandWindow)
    }

    /// ``focusedKeyPane()`` for `window` rather than the key window: a
    /// standalone browser window's pane, or a pane whose view holds the
    /// window's first responder. A child window (a Chrome pane's page) is
    /// focus inside the pane it belongs to.
    static func focusedKeyPane(in window: NSWindow?) -> WebBrowserPaneViewController? {
        guard let window, let pane = keyPane(in: window) else { return nil }
        let owner = window.commandOwner
        if owner.windowController is WebBrowserWindowController { return pane }
        if owner !== window { return pane }
        guard let responder = window.firstResponder as? NSView,
              let paneView = pane.viewIfLoaded else { return nil }
        return responder.isDescendant(of: paneView) ? pane : nil
    }
}
