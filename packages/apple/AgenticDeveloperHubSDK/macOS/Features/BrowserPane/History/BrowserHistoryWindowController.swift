//
//  BrowserHistoryWindowController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import os
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKCoreMacOS

/// Browser ▸ Show History: the History panel in a window of its own, shaped
/// like the projects window — a bordered shelf card with a bar of panel
/// buttons along its top (one, "History") and the panel beneath it.
///
/// One window, under the fixed id ``windowID``: showing it again brings it
/// up, and `SingleWindowController` saves and restores its frame and
/// visibility under that id. It works with no browser open — a visit opens
/// in the frontmost window's browser pane as a new tab when there is one,
/// else in a new browser window.
@MainActor
public final class BrowserHistoryWindowController: SingleWindowController {

    public static let windowID = "web-history"

    /// The history the window lists. The host sets it once, before the
    /// window can be shown; with none, there is nothing to show and
    /// ``show()`` logs and returns.
    public static var store: BrowserHistoryStore?

    /// Whether ``show()`` has a history to show.
    public static var canShow: Bool { store != nil }

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserHistory")
    private static var current: BrowserHistoryWindowController?

    /// Shows the History window, bringing it up when it is already open.
    public static func show() {
        guard let controller = shared() else {
            logger.info("history window not shown: no history store")
            return
        }
        // `showWindow()` already makes it key and brings it forward.
        controller.showWindow()
        controller.panel.focusList()
    }

    /// The one controller, built on first use without showing it — the
    /// launch restore's factory as well as ``show()``'s.
    @discardableResult
    static func shared() -> BrowserHistoryWindowController? {
        if let current { return current }
        guard let store else { return nil }
        let controller = BrowserHistoryWindowController(store: store)
        current = controller
        return controller
    }

    private let panel: BrowserHistoryPanelViewController

    private init(store: BrowserHistoryStore) {
        var openVisit: (URL) -> Void = { _ in }
        let panel = BrowserHistoryPanelViewController(
            model: BrowserHistoryListModel(store: store),
            open: { openVisit($0) })
        self.panel = panel
        super.init(windowID: Self.windowID, contentViewController: BrowserHistoryShelfViewController(panel: panel))
        openVisit = { [weak self] url in Self.open(url, excluding: self?.window) }
        windowTitle = "History"
        windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]
        windowSpec = WindowSpec(
            defaultSize: NSSize(width: 520, height: 640),
            minSize: NSSize(width: 360, height: 300),
            defaultPosition: .center
        )
        accessibilityIdentifier = "browser-history.window"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Opening a visit

    /// Opens `url` as a new tab of the frontmost window's browser pane — the
    /// window that was key before this one — or, when that window has none,
    /// in a new browser window.
    private static func open(_ url: URL, excluding historyWindow: NSWindow?) {
        if let pane = frontBrowserPane(excluding: historyWindow) {
            pane.openInNewTab(url)
            pane.view.window?.makeKeyAndOrderFront(nil)
        } else {
            WebBrowserWindowController.openNew(url: url)
        }
    }

    private static func frontBrowserPane(excluding historyWindow: NSWindow?) -> WebBrowserPaneViewController? {
        let front = NSApp.orderedWindows.first { window in
            window !== historyWindow && window.isVisible && window.canBecomeMain
        }
        guard let window = front?.commandOwner else { return nil }
        if let browser = window.windowController as? WebBrowserWindowController {
            return browser.pane.isDiscarded ? nil : browser.pane
        }
        guard let project = window.windowController as? ComposableTabsWindowController,
              let responder = window.firstResponder as? NSView else { return nil }
        return project.allPanes().lazy
            .compactMap { $0.contentViewController as? WebBrowserPaneViewController }
            .first { !$0.isDiscarded && responder.isDescendant(of: $0.view) }
    }
}

/// The History window's shelf, after `ProjectShelfViewController`: a
/// `ThemedBox` card with an `IconTabBar` of panel buttons across its top and
/// the chosen panel beneath. It has one panel today, the History panel.
@MainActor
private final class BrowserHistoryShelfViewController: NSViewController {

    private enum Panel: String { case history }

    private let panel: BrowserHistoryPanelViewController
    private let panelBar = IconTabBar(
        items: [.init(id: Panel.history.rawValue, symbol: "clock", title: "History")],
        accessibilityID: "browser-history.panels")

    init(panel: BrowserHistoryPanelViewController) {
        self.panel = panel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() {
        let container = NSView()
        let backdrop = ThemedBackgroundView(role: .windowBackground)
        backdrop.setAccessibilityElement(false)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(backdrop)

        // `outline`, as the projects window's shelf strokes its card.
        let card = ThemedBox(fill: .windowBackground, stroke: .outline, cornerRadius: 12)
        card.layer?.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(card)

        panelBar.selectedID = Panel.history.rawValue
        panelBar.onSelect = { [weak self] _ in self?.panel.focusList() }
        let topRule = ThemedSeparatorView(role: .border)

        let panelHost = NSView()
        panelHost.translatesAutoresizingMaskIntoConstraints = false
        addChild(panel)
        panel.view.translatesAutoresizingMaskIntoConstraints = false
        panelHost.addSubview(panel.view)

        for view in [panelBar, topRule, panelHost] {
            view.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(view)
        }

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: container.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            card.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),

            panelBar.topAnchor.constraint(equalTo: card.topAnchor, constant: 6),
            panelBar.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            panelBar.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 8),

            topRule.topAnchor.constraint(equalTo: panelBar.bottomAnchor, constant: 6),
            topRule.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            topRule.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            panelHost.topAnchor.constraint(equalTo: topRule.bottomAnchor),
            panelHost.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            panelHost.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            panelHost.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            panel.view.topAnchor.constraint(equalTo: panelHost.topAnchor),
            panel.view.leadingAnchor.constraint(equalTo: panelHost.leadingAnchor),
            panel.view.trailingAnchor.constraint(equalTo: panelHost.trailingAnchor),
            panel.view.bottomAnchor.constraint(equalTo: panelHost.bottomAnchor)
        ])
        view = container
    }
}
