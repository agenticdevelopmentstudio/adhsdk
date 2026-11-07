//
//  BrowserLogPaneViewController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine
import os
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// A pane showing one browser pane's event log (spec section 12): what it
/// delivered to its page, what it withheld, and what happened around it.
///
/// Registered only in debug builds (`.browserLog`); the log it shows is
/// recorded in every build. The pane remembers one thing, the node id of the
/// browser pane it follows, and looks for that pane in its window when it
/// appears (`viewDidAppear`) and when it is pointed at one (`setTarget`). A
/// target whose content is not loaded yet, in a tab never shown since a
/// relaunch, is found the next time the log pane appears. A target that is
/// discarded is let go, so the list empties and the title drops its name.
@MainActor
public final class BrowserLogPaneViewController: NSViewController {

    /// The pane-state key holding the target's node id. Filed under the
    /// registration's `browser-log.` prefix, so it is `browser-log.target`.
    static let targetKey = "target"

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserLogPane")

    private let store: PaneStateStore
    /// The browser pane this log follows, by its layout node.
    public private(set) var targetNodeID: UUID?
    /// The live pane, when it has been found.
    private(set) weak var target: BrowserPaneViewController?
    private var subscription: AnyCancellable?
    /// The target's page title, followed so the pane title keeps up with it.
    /// Re-made when the target rebuilds its web view.
    private var titleObservation: NSKeyValueObservation?
    private weak var observedWebView: NSView?
    /// The title last announced through `onPaneTitleChange`, so a reload that
    /// changes nothing announces nothing.
    private var announcedTitle: String?

    let tableView = NSTableView()
    private let scrollView = NSScrollView()
    let clearButton = NSButton(title: "Clear", target: nil, action: nil)

    public var onPaneTitleChange: (() -> Void)?

    /// The lines shown: the target's, or none.
    var entries: [BrowserEventLogEntry] { target?.eventLog.entries ?? [] }

    private enum Column: String, CaseIterable {
        case time = "Time", channel = "Channel", event = "Event", decision = "Decision", detail = "Detail"

        var width: CGFloat {
            switch self {
            case .time: 90
            case .channel: 80
            case .event: 150
            case .decision: 80
            case .detail: 240
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    public init(store: PaneStateStore) {
        self.store = store
        self.targetNodeID = store.paneStateValue(forKey: Self.targetKey).flatMap(UUID.init(uuidString:))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - Target

    /// Points the log at the browser pane on `nodeID` and remembers it.
    public func setTarget(_ nodeID: UUID) {
        targetNodeID = nodeID
        store.setPaneStateValue(nodeID.uuidString, forKey: Self.targetKey)
        target = nil
        resolveTarget()
    }

    /// Finds the target in the window when it is not already attached.
    func resolveTarget() {
        guard let nodeID = targetNodeID else { return attach(nil) }
        if let target, target.paneContext.paneNodeID == nodeID, !target.isDiscarded { return }
        attach(Self.browserPane(nodeID: nodeID, in: viewIfLoaded?.window))
    }

    /// The live browser pane on `nodeID` among `window`'s panes.
    static func browserPane(nodeID: UUID, in window: NSWindow?) -> BrowserPaneViewController? {
        guard let controller = window?.windowController as? ComposableTabsWindowController else { return nil }
        return controller.allPanes().lazy
            .compactMap { $0.contentViewController as? BrowserPaneViewController }
            .first { $0.paneContext.paneNodeID == nodeID && !$0.isDiscarded }
    }

    /// Follows `pane`'s log. Internal so a test can attach a pane that is in
    /// no window.
    func attach(_ pane: BrowserPaneViewController?) {
        target = pane
        // A mouse flood records many times a second; the table catches up a
        // few times a second instead of once per event.
        subscription = pane?.eventLog.changes
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in self?.reload() }
        refresh()
    }

    // MARK: - View

    public override func loadView() {
        let root = ThemedBackgroundView(role: .windowBackground)
        view = root

        for column in Column.allCases {
            let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column.rawValue))
            tableColumn.title = column.rawValue
            tableColumn.width = column.width
            tableView.addTableColumn(tableColumn)
        }
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setAccessibilityIdentifier("browser-log.table")

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        clearButton.target = self
        clearButton.action = #selector(clearLog)
        clearButton.bezelStyle = .rounded
        clearButton.controlSize = .small
        clearButton.setAccessibilityIdentifier("browser-log.clear")

        let bar = NSStackView(views: [NSView(), clearButton])
        bar.orientation = .horizontal
        bar.edgeInsets = NSEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        bar.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(bar)
        root.addSubview(scrollView)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor),
            bar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: bar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        resolveTarget()
    }

    /// Whether the newest line is in view, so a reload keeps it there. A
    /// reader who has scrolled up to look at something is left where they are.
    private var isFollowingTail: Bool {
        let visible = scrollView.contentView.bounds
        return visible.maxY >= tableView.bounds.height - tableView.rowHeight - tableView.intercellSpacing.height
    }

    /// Catches up with the target's log: lets go of a discarded target, then
    /// redraws.
    func reload() {
        if target?.isDiscarded == true { return attach(nil) }
        refresh()
    }

    /// Redraws the list and announces the title if it changed.
    private func refresh() {
        followTitle()
        announceTitleIfChanged()
        guard isViewLoaded else { return }
        let follow = isFollowingTail
        tableView.reloadData()
        if follow, tableView.numberOfRows > 0 { tableView.scrollRowToVisible(tableView.numberOfRows - 1) }
    }

    private func announceTitleIfChanged() {
        let title = paneTitle
        guard title != announcedTitle else { return }
        announcedTitle = title
        onPaneTitleChange?()
    }

    /// Re-observes the target's page title whenever its web view changes.
    private func followTitle() {
        guard let webView = target?.webView else {
            titleObservation = nil
            observedWebView = nil
            return
        }
        guard webView !== observedWebView else { return }
        observedWebView = webView
        titleObservation = webView.observe(\.title, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.announceTitleIfChanged() }
        }
    }

    @objc func clearLog() {
        target?.eventLog.clear()
    }

    /// The text a cell shows. Internal for tests.
    func text(row: Int, column identifier: String) -> String {
        guard entries.indices.contains(row), let column = Column(rawValue: identifier) else { return "" }
        let entry = entries[row]
        switch column {
        case .time: return Self.timeFormatter.string(from: entry.date)
        case .channel: return entry.channel
        case .event: return entry.event
        case .decision: return entry.decision.rawValue
        case .detail:
            guard entry.count > 1 else { return entry.detail }
            return entry.detail.isEmpty ? "×\(entry.count)" : "\(entry.detail) ×\(entry.count)"
        }
    }
}

// MARK: - Table

extension BrowserLogPaneViewController: NSTableViewDataSource, NSTableViewDelegate {

    public func numberOfRows(in tableView: NSTableView) -> Int { entries.count }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn else { return nil }
        let identifier = tableColumn.identifier
        let field = (tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField) ?? {
            let field = NSTextField(labelWithString: "")
            field.identifier = identifier
            field.lineBreakMode = .byTruncatingTail
            field.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            return field
        }()
        field.stringValue = text(row: row, column: identifier.rawValue)
        return field
    }
}

// MARK: - Pane capabilities

extension BrowserLogPaneViewController: PaneTitleProviding {

    public var paneTitle: String {
        guard let target else { return "Browser Log" }
        return "Browser Log — \(target.paneTitle)"
    }
}

// MARK: - Opening

extension BrowserLogPaneViewController {

    /// Show Browser Log for `pane`: brings forward the log pane already
    /// following it in its window, or splits one off beside it.
    public static func show(for pane: BrowserPaneViewController) {
        guard let nodeID = pane.paneContext.paneNodeID,
              let window = pane.viewIfLoaded?.window,
              let controller = window.windowController as? ComposableTabsWindowController else {
            logger.info("browser log asked for a pane that is in no project window")
            return
        }
        let panes = controller.allPanes()
        if let existing = panes.first(where: {
            ($0.contentViewController as? BrowserLogPaneViewController)?.targetNodeID == nodeID
        }) {
            if let tab = controller.tabGroup(containing: existing) { controller.selectTab(id: tab.id) }
            ComposableTabsActivePane.shared.activate(nodeID: existing.nodeID, in: window)
            if let log = existing.contentViewController as? BrowserLogPaneViewController {
                window.makeFirstResponder(log.tableView)
            }
            return
        }
        guard let host = panes.first(where: { $0.nodeID == nodeID }),
              let added = controller.splitPane(host, adding: .browserLog, direction: .right),
              let log = added.contentViewController as? BrowserLogPaneViewController else {
            logger.info("browser log pane refused: the layout does not allow one beside this pane")
            return
        }
        log.setTarget(nodeID)
    }
}
