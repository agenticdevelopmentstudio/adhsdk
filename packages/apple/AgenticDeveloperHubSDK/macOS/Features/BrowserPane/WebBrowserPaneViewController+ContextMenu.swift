//
//  WebBrowserPaneViewController+ContextMenu.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import os
import WebKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKDatabase

/// The pane's items in a page's context menu, on the live page and in the
/// Agent preview:
///
/// - **Hide Distracting Item** (live page): the user list's dialog for the
///   element under the click, as if the picker had picked it.
/// - **Hide Item from Agents** (live page or Agent preview, while the agent
///   can see the browser): the agent list's dialog for that element.
/// - **Replace Private Word…** (a click on text): the Secrets window with the
///   clicked word's row, made if it has none, open for its alias once it is
///   unlocked.
///
/// What the click was on is read from the page when an item is chosen, at
/// the point the menu opened at (`BrowserElementPicker.contextTarget`).
extension WebBrowserPaneViewController {

    enum ContextMenuID {
        static let hideItem = "browser.context.hide-item"
        static let hideFromAgents = "browser.context.hide-from-agents"
        static let replaceWord = "browser.context.replace-private-word"
    }

    private static let contextLogger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    /// The items for a menu opening at `point` in `webView`; `preview` is
    /// the Agent preview the web view belongs to, `nil` for the live page.
    func contextMenuItems(
        _ menu: NSMenu, at point: NSPoint, in webView: WKWebView, preview: BrowserAgentPreviewViewController?
    ) -> [NSMenuItem] {
        var items: [NSMenuItem] = []
        let canHide = engine is WebKitBrowserEngine && BrowserSelectingMode.canSelect(on: engine.url)
        if canHide, preview == nil {
            let hide = { [weak self, weak webView] in
                guard let webView else { return }
                self?.hideFromContextMenu(at: point, in: webView, list: .user, preview: nil)
            }
            items.append(Self.contextItem("Hide Distracting Item", id: ContextMenuID.hideItem, action: hide))
        }
        if canHide, agentAccess != .hidden {
            let hide = { [weak self, weak webView, weak preview] in
                guard let webView else { return }
                self?.hideFromContextMenu(at: point, in: webView, list: .agent, preview: preview)
            }
            items.append(Self.contextItem("Hide Item from Agents", id: ContextMenuID.hideFromAgents, action: hide))
        }
        if privacyVault != nil, BrowserMenuWebView.menuIsForText(menu) {
            let replace = { [weak self, weak webView] in
                guard let webView else { return }
                self?.replaceWordFromContextMenu(at: point, in: webView)
            }
            items.append(Self.contextItem("Replace Private Word…", id: ContextMenuID.replaceWord, action: replace))
        }
        return items
    }

    /// An item running `action`, its target kept alive by the item itself
    /// (`NSMenuItem.target` is weak).
    private static func contextItem(_ title: String, id: String, action: @escaping () -> Void) -> NSMenuItem {
        let target = ClosureMenuItemTarget(action: action)
        let item = NSMenuItem(
            title: title, action: #selector(ClosureMenuItemTarget.performMenuAction(_:)), keyEquivalent: "")
        item.target = target
        item.representedObject = target
        item.identifier = NSUserInterfaceItemIdentifier(id)
        return item
    }

    private func hideFromContextMenu(
        at point: NSPoint, in webView: WKWebView, list: BrowserHiddenItemList,
        preview: BrowserAgentPreviewViewController?
    ) {
        Task { [weak self] in
            guard let self else { return }
            guard let target = await BrowserElementPicker.contextTarget(at: point, in: webView),
                  let store = await self.openHiddenItemsStore() else {
                NSSound.beep()
                return
            }
            self.pickOnceForHiding(target.candidate, list: list, store: store, preview: preview)
        }
    }

    /// Opens the Secrets window on the clicked word: its row, or a new one on
    /// this page's site. The window shows hidden and asks for authentication
    /// itself, so nothing is shown to someone who could not unlock it.
    private func replaceWordFromContextMenu(at point: NSPoint, in webView: WKWebView) {
        Task { [weak self] in
            guard let self, let vault = self.privacyVault else { return }
            let word = await BrowserElementPicker.contextTarget(at: point, in: webView)?.selectedText ?? ""
            guard !word.isEmpty else {
                NSSound.beep()
                return
            }
            SecretsWindowController.show(
                vault: vault,
                newWordSite: PrivacySitePattern.defaultPattern(for: self.privacyWordsURL),
                startingWord: word)
        }
    }
}
