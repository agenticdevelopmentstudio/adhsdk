//
//  BrowserMenuWebView.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit

/// A browser pane's web view with the pane's own items in its context menu:
/// the live page's (`BrowserWebView`) and the Agent preview's. When the menu
/// opens, `contextMenuItems` is given WebKit's menu and the click's point in
/// the view's coordinates, and what it returns goes under WebKit's items,
/// behind a separator.
///
/// Not `final`, so `BrowserWebView` keeps it while it gates input; not
/// `open`, because nothing outside the module subclasses it.
public class BrowserMenuWebView: LiveResizingWebView {

    /// The pane's items for a menu opening at a point.
    public var contextMenuItems: ((NSMenu, NSPoint) -> [NSMenuItem])?

    public override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        let point = convert(event.locationInWindow, from: nil)
        guard let items = contextMenuItems?(menu, point), !items.isEmpty else { return }
        menu.addItem(.separator())
        items.forEach(menu.addItem)
    }

    /// Whether WebKit's menu is for selected text: it offers Copy or Look Up
    /// only then, and a right-click on a word selects the word.
    public static func menuIsForText(_ menu: NSMenu) -> Bool {
        let textItems: Set<String> = ["WKMenuItemIdentifierCopy", "WKMenuItemIdentifierLookUp"]
        return menu.items.contains { textItems.contains($0.identifier?.rawValue ?? "") }
    }
}
