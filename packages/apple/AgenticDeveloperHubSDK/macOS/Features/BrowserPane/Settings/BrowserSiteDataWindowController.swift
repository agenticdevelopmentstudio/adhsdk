//
//  BrowserSiteDataWindowController.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit

/// Privacy and Security › Site Data › Manage Site Data…: everything WebKit
/// keeps for sites in one store, in a window of its own — the table the
/// Safari topic used to show inline (Site, Data), with −, Remove All…,
/// Refresh and Done.
///
/// A titled, resizable window run application-modal with
/// `NSApp.runModal(for:)`, not a sheet: a sheet is fixed to its parent's
/// width and cannot be moved, and a table of every site's data needs the room
/// a window the user can size gives it (the Web Browser Settings Topics
/// recipe's `site-data-window`). Modal because the settings it was opened
/// from describe the same store, and an edit there while the list is up
/// would leave it describing a jar the pane no longer uses.
///
/// The store is handed in (`dependency-injection`): the global jar's in the
/// Settings window, the pane's own in its sheet (`site-data-window-scope`).
@MainActor
final class BrowserSiteDataWindowController: NSWindowController, NSWindowDelegate {

    private let content: BrowserSiteDataViewController

    /// - Parameters:
    ///   - siteData: the store the window lists and removes from.
    ///   - jarName: the jar that store is, which the title and Remove All…'s
    ///     confirmation name, so neither leaves the person guessing whether
    ///     the shared jar or a pane's own is about to be emptied; `nil` for
    ///     a plain "Site Data".
    ///   - removeAllDetail: what Remove All…'s confirmation says goes, which
    ///     depends on whose jar this is.
    init(siteData: BrowserSiteData, jarName: String? = nil, removeAllDetail: String? = nil) {
        let content = BrowserSiteDataViewController(
            siteData: siteData, jarName: jarName, removeAllDetail: removeAllDetail)
        self.content = content
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: true
        )
        window.title = Self.title(jarName: jarName)
        window.contentMinSize = Self.minimumSize
        window.isReleasedWhenClosed = false
        window.setAccessibilityIdentifier("settings.browser.site-data.window")
        window.contentViewController = content
        window.setContentSize(Self.defaultSize)
        super.init(window: window)
        window.delegate = self
        content.onDone = { [weak self] in self?.window?.close() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// "Site Data — <jar>", or "Site Data" with no jar named.
    static func title(jarName: String?) -> String {
        guard let jarName, !jarName.isEmpty else { return "Site Data" }
        return "Site Data \u{2014} \(jarName)"
    }

    /// Wide enough for both columns and the footer's four buttons.
    static let minimumSize = NSSize(width: 520, height: 320)
    static let defaultSize = NSSize(width: 620, height: 440)

    /// Shows the window centred over `parent` and returns once it closes —
    /// Done, Escape or the close button.
    func runModal(for parent: NSWindow) {
        guard let window else { return }
        let frame = parent.frame
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2))
        content.reload()
        NSApp.runModal(for: window)
        window.orderOut(nil)
    }

    func windowWillClose(_ notification: Notification) {
        content.cancelReload()
        if NSApp.modalWindow === window { NSApp.stopModal() }
    }
}

/// The window's content: the site data card filling it, Done beneath.
@MainActor
final class BrowserSiteDataViewController: NSViewController {

    private let siteData: BrowserSiteData
    /// The jar the store is, named in Remove All…'s confirmation.
    private let jarName: String?
    private let removeAllDetail: String?
    private let table = ComposableSettings.EditableTableCard(
        title: "Site Data",
        columns: [
            .init(id: "site", title: "Site", width: 220),
            .init(id: "kinds", title: "Data", width: 340)
        ],
        visibleRows: 10,
        accessibilityPrefix: "settings.browser.safari.sites"
    )
    private let doneButton = NSButton(title: "Done", target: nil, action: nil)
    private var records: [WKWebsiteDataRecord] = []
    /// The read in flight. One at a time: a Refresh pressed twice, or a
    /// removal landing while a read is out, must not let the older answer
    /// arrive last and show rows that are already gone.
    private var reloadTask: Task<Void, Never>?
    /// The card's height less its table's, measured once laid out, so the
    /// table can take whatever height the window has left.
    private var cardChrome: CGFloat?

    var onDone: (() -> Void)?

    init(siteData: BrowserSiteData, jarName: String? = nil, removeAllDetail: String?) {
        self.siteData = siteData
        self.jarName = jarName
        self.removeAllDetail = removeAllDetail
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static let inset: CGFloat = 20

    override func loadView() {
        let container = NSView(frame: NSRect(origin: .zero, size: BrowserSiteDataWindowController.defaultSize))
        configureTable()

        doneButton.target = self
        doneButton.action = #selector(done)
        doneButton.bezelStyle = .push
        doneButton.keyEquivalent = "\r"
        doneButton.toolTip = "Close the Site Data window"
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        _ = doneButton.accessibilityID("settings.browser.site-data.done")

        table.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(table)
        container.addSubview(doneButton)
        let inset = Self.inset
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            table.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            table.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            doneButton.topAnchor.constraint(greaterThanOrEqualTo: table.bottomAnchor, constant: 12),
            doneButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            doneButton.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset)
        ])
        view = container
    }

    private func configureTable() {
        // Site data is removed from, never added to by hand.
        table.addButton.isHidden = true
        table.removeButton.toolTip = "Remove the selected site's data"
        table.onRemove = { [weak self] rowID in
            guard let self, let record = self.records.first(where: { $0.displayName == rowID }) else { return }
            Task {
                await self.siteData.remove([record])
                self.reload()
            }
        }
        let removeAll = table.addFooterButton(
            title: "Remove All…", identifier: "settings.browser.safari.remove-all"
        ) { [weak self] in
            self?.removeAll()
        }
        removeAll.toolTip = "Remove the data of every site listed"
        let refresh = table.addFooterButton(
            title: "Refresh", identifier: "settings.browser.safari.refresh"
        ) { [weak self] in
            self?.reload()
        }
        refresh.toolTip = "Read the list again"
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(table.tableView)
    }

    /// The table takes the height the window has left over the card's own
    /// caption and footer and the Done row, so resizing the window resizes
    /// the list (`EditableTableCard.tableHeight`).
    override func viewDidLayout() {
        super.viewDidLayout()
        if cardChrome == nil, table.frame.height > 0 {
            cardChrome = table.frame.height - table.tableHeight
        }
        guard let cardChrome else { return }
        let below = doneButton.frame.height + 12 + Self.inset
        let wanted = view.bounds.height - Self.inset - below - cardChrome
        if abs(table.tableHeight - wanted) > 0.5 { table.tableHeight = wanted }
    }

    /// Escape closes the window, as Done does.
    override func cancelOperation(_ sender: Any?) {
        done()
    }

    @objc private func done() {
        onDone?()
    }

    private func removeAll() {
        ComposableSettings.Alerts.confirmDestructive(
            Self.removeAllMessage(jarName: jarName),
            detail: removeAllDetail
                ?? "Cookies, caches and storage for every site listed are removed. History is not affected.",
            actionTitle: "Remove All",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            Task {
                await self.siteData.removeAll()
                self.reload()
            }
        }
    }

    /// Remove All…'s question, naming the jar it empties when there is one.
    static func removeAllMessage(jarName: String?) -> String {
        guard let jarName, !jarName.isEmpty else { return "Remove all Safari site data?" }
        return "Remove all Safari site data in \u{201C}\(jarName)\u{201D}?"
    }

    func reload() {
        reloadTask?.cancel()
        reloadTask = Task { [weak self] in
            guard let siteData = self?.siteData else { return }
            let records = await siteData.records()
            guard let self, !Task.isCancelled else { return }
            self.records = records
            self.table.setRows(records.map { record in
                ComposableSettings.EditableTableRow(id: record.displayName, cells: [
                    "site": .text(record.displayName),
                    "kinds": .text(BrowserSiteData.labels(for: record))
                ])
            })
        }
    }

    /// Closing the window abandons the read in flight.
    func cancelReload() {
        reloadTask?.cancel()
        reloadTask = nil
    }
}
