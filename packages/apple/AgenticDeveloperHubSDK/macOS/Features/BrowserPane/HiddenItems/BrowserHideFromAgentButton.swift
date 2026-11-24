//
//  BrowserHideFromAgentButton.swift
//  AgenticDeveloperHubSDK
//
//  Recipe: workspace/browser/hide-from-agent (spec section 2.5).
//

import AppKit

/// The privacy toolbar's "Hide elements from agent": the address box's
/// hide-items button with the agent's symbol, tooltip and identifier, plus
/// the two-item menu a click on it shows while not selecting. While agent
/// selecting runs it is the stop control, as the address box's button is.
@MainActor
final class BrowserHideFromAgentButton: BrowserHideItemsButton {

    static let agentIdleSymbol = "person.crop.circle.badge.xmark"
    static let agentIdleToolTip = "Hide elements from agent"
    static let identifierName = "browser.hide-from-agent"
    static let selectTitle = "Select Items to Hide from the Agent"
    static let listTitle = "Hidden from the Agent…"

    init() {
        super.init(idleSymbol: Self.agentIdleSymbol, idleToolTip: Self.agentIdleToolTip,
                   identifier: Self.identifierName)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The menu the button shows: "Select Items to Hide from the Agent",
    /// then "Hidden from the Agent…", each sending its action to `target`.
    static func makeMenu(target: AnyObject, select: Selector, list: Selector) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let selectItem = NSMenuItem(title: selectTitle, action: select, keyEquivalent: "")
        selectItem.target = target
        selectItem.setAccessibilityIdentifier("\(identifierName).select")
        let listItem = NSMenuItem(title: listTitle, action: list, keyEquivalent: "")
        listItem.target = target
        listItem.setAccessibilityIdentifier("\(identifierName).list")
        menu.addItem(selectItem)
        menu.addItem(listItem)
        return menu
    }

    /// Pops `menu` up under the button.
    func popUp(_ menu: NSMenu) {
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: bounds.maxY + 4), in: self)
    }
}
