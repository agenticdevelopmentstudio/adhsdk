//
//  ProjectBrowserJarsSettingsPanel.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import WebKit

import AgenticDeveloperHubSDKCore

/// Where the project settings sheet finds a project's browser jars and the
/// store behind each.
///
/// A protocol rather than `BrowserJarRegistry` itself so the sheet can be
/// shown, and tested, over jars whose stores are not the user's: a test hands
/// in non-persistent stores, and the registry hands in the real named ones
/// (`dependency-inversion`).
@MainActor
public protocol ProjectBrowserJarsProviding: AnyObject {
    /// Every jar of one project, worktree jars first.
    func records(repoID: UUID) -> [BrowserJarRecord]
    /// The site data of one jar — the same store its panes are built on.
    func siteData(for record: BrowserJarRecord) -> BrowserSiteData
}

extension ProjectBrowserJarsProviding {
    /// A jar's id *is* its WebKit identifier, so naming the store needs
    /// nothing else. WebKit hands back the store a live pane already holds,
    /// so what is read and cleared here is what that pane sees.
    public func siteData(for record: BrowserJarRecord) -> BrowserSiteData {
        BrowserSiteData(dataStore: WKWebsiteDataStore(forIdentifier: record.id))
    }
}

extension BrowserJarRegistry: ProjectBrowserJarsProviding {}

/// One project's jars, as the project window hands them to its settings
/// sheet: the provider and which project in its database to list. Kept
/// together because one without the other names nothing — a project database
/// holds rows for every project.
@MainActor
public struct ProjectBrowserJars {
    public let provider: any ProjectBrowserJarsProviding
    public let repoID: UUID

    public init(provider: any ProjectBrowserJarsProviding, repoID: UUID) {
        self.provider = provider
        self.repoID = repoID
    }
}

/// The project settings sheet's Cookies and Site Data topic (spec section 3):
/// every jar of the project — one per worktree, one per pane that keeps its
/// own — each expandable to the sites it holds data for, with Remove for a
/// site and Clear for a whole jar.
///
/// Clearing a jar a live pane is using does not rebuild or reload that pane.
/// WebKit allows a store's data to be removed while a web view holds it; only
/// deleting the store itself needs the web view gone, and that is the
/// reconciler's job, not this topic's. The page on screen keeps what it holds
/// in memory until its next request or navigation — exactly what Remove All
/// in the global topic does to every pane on the global jar — and a reload
/// forced on the user would throw away whatever a page had half filled in
/// (`principle-of-least-astonishment`).
@MainActor
final class ProjectBrowserJarsSettingsPanel: ComposableSettings.SettingsPanelViewController {

    /// A jar row. A class, because an outline view tells items apart by
    /// identity and keeps its expansion state against them.
    final class JarItem {
        let record: BrowserJarRecord
        let siteData: BrowserSiteData
        var sites: [SiteItem] = []
        var hasLoadedSites = false

        init(record: BrowserJarRecord, siteData: BrowserSiteData) {
            self.record = record
            self.siteData = siteData
        }
    }

    /// A site row under its jar.
    final class SiteItem {
        let record: WKWebsiteDataRecord
        unowned let jar: JarItem

        init(record: WKWebsiteDataRecord, jar: JarItem) {
            self.record = record
            self.jar = jar
        }
    }

    private let jars: ProjectBrowserJars
    private(set) var jarItems: [JarItem] = []

    let outlineView = ThemedOutlineView(role: .card)
    private let scrollView = ThemedScrollView()
    let removeButton = NSButton(title: "Remove", target: nil, action: nil)
    let clearButton = NSButton(title: "Clear…", target: nil, action: nil)
    private let refreshButton = NSButton(title: "Refresh", target: nil, action: nil)

    /// How the panel reads one jar's sites. A seam so a test can hold a read
    /// open and decide when, and with what, it answers.
    var readSites: @MainActor (BrowserSiteData) async -> [WKWebsiteDataRecord] = { await $0.records() }

    /// The newest read asked for, per jar id. A read whose answer arrives
    /// after a newer one was asked for is dropped, so an older answer can
    /// never land last and show sites that are already gone. Per jar, so a
    /// read of one jar — after a Remove or a Clear — never stops a read of
    /// every jar from reaching the others.
    private var readGenerations: [UUID: Int] = [:]

    /// The read of every jar in flight. Only a newer read of every jar
    /// cancels it; a read of one jar leaves it running.
    private var fullLoadTask: Task<Void, Never>?

    private static let nameColumn = NSUserInterfaceItemIdentifier("name")
    private static let dataColumn = NSUserInterfaceItemIdentifier("data")

    init(jars: ProjectBrowserJars) {
        self.jars = jars
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "Cookies and Site Data",
            icon: NSImage(systemSymbolName: "tray.full", accessibilityDescription: "Cookies and Site Data")
        ))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Labels

    /// What a jar is called in the list: a worktree jar by its worktree, a
    /// pane jar by the title its pane last showed and the worktree it is in.
    /// Pure, so the wording is tested without a sheet.
    static func label(for record: BrowserJarRecord) -> String {
        let worktree = URL(fileURLWithPath: record.worktreePath).lastPathComponent
        switch record.kind {
        case .worktree:
            return "\(worktree) — worktree"
        case .pane:
            let name = record.label.isEmpty ? WebBrowserPaneViewController.untitledLabel : record.label
            return "\(name) — \(worktree)"
        }
    }

    /// A jar row's Data column once its sites are read.
    static func siteCount(_ count: Int) -> String {
        count == 1 ? "1 site" : "\(count) sites"
    }

    // MARK: - Help

    override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "Jars",
                body: "A jar is where browser panes keep cookies, local storage, caches and "
                    + "the rest of what sites store. This list holds every jar of this "
                    + "project: one per worktree whose panes share a jar, named after the "
                    + "worktree, and one per pane that keeps a jar of its own, named after "
                    + "the page that pane last showed and its worktree. The global jar, "
                    + "shared by every browser pane in every project, is listed in the "
                    + "Settings window under Browser > Global Cookies and Site Data. Which "
                    + "jar a pane uses is its Cookie jar setting, under Session Privacy."
            ),
            .init(
                title: "Sites",
                body: "Expand a jar to see the sites it holds data for, with the kinds of "
                    + "data in the second column. Select a site and press Remove to forget "
                    + "what it kept in that jar, which signs you out of it there and "
                    + "nowhere else. Clear empties the selected jar of every site, after "
                    + "asking. Refresh re-reads the list, since pages write while it is "
                    + "open. Browsing history is separate."
            ),
            .init(
                title: "Open Panes",
                body: "A pane using a jar you clear keeps running and is not reloaded: the "
                    + "page on screen keeps what it already holds until it next talks to "
                    + "its site or you navigate, and then finds the jar empty — though a "
                    + "page still open may store new data straight away. "
                    + "A jar goes away by itself when the last pane using it is removed "
                    + "from the project; closing the window removes nothing."
            )
        ])
    }

    override var searchKeywords: [String] {
        ["cookies", "site data", "jar", "local storage", "cache", "sign out", "worktree"]
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.addGroup(makeJarsGroup())
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reload()
    }

    private func makeJarsGroup() -> ComposableSettings.GroupView {
        let group = ComposableSettings.GroupView(withTitle: "Jars")

        let name = NSTableColumn(identifier: Self.nameColumn)
        name.title = "Jar or Site"
        name.width = 260
        name.minWidth = 120
        let data = NSTableColumn(identifier: Self.dataColumn)
        data.title = "Data"
        data.width = 300
        data.minWidth = 80
        outlineView.addTableColumn(name)
        outlineView.addTableColumn(data)
        outlineView.outlineTableColumn = name
        outlineView.headerView = ThemedTableHeaderView(role: .card)
        outlineView.columnAutoresizingStyle = .sequentialColumnAutoresizingStyle
        outlineView.allowsMultipleSelection = false
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.accessibilityID("project-settings.browser-jars.outline")

        scrollView.documentView = outlineView
        scrollView.backgroundRole = .card
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        for (button, action, id) in [
            (removeButton, #selector(removeSite(_:)), "remove"),
            (clearButton, #selector(clearJar(_:)), "clear"),
            (refreshButton, #selector(refresh(_:)), "refresh")
        ] {
            button.target = self
            button.action = action
            button.bezelStyle = .rounded
            button.controlSize = .small
            button.accessibilityID("project-settings.browser-jars.\(id)")
        }
        let buttons = NSStackView(views: [removeButton, clearButton, refreshButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        let stack = NSStackView(views: [scrollView, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            scrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 300)
        ])
        group.addSettingSubview(container)
        updateButtons()
        return group
    }

    // MARK: - Loading

    /// Re-reads the project's jars, then each jar's sites.
    private func reload() {
        reloadJars()
        loadSites()
    }

    /// The jar rows, from the registry, keeping whatever was expanded.
    /// Separate from reading sites so the list of jars — a database read —
    /// is there at once, and so a test can check it without touching WebKit.
    func reloadJars() {
        let selection = selectedSiteKey
        let expanded = Set(jarItems.filter { outlineView.isItemExpanded($0) }.map(\.record.id))
        let previous = Dictionary(uniqueKeysWithValues: jarItems.map { ($0.record.id, $0) })
        jarItems = jars.provider.records(repoID: jars.repoID).map { record in
            // The same store object as before, so a read in flight lands on
            // the item still on screen.
            let siteData = previous[record.id]?.siteData ?? jars.provider.siteData(for: record)
            let item = JarItem(record: record, siteData: siteData)
            item.sites = previous[record.id]?.sites.map { SiteItem(record: $0.record, jar: item) } ?? []
            item.hasLoadedSites = previous[record.id]?.hasLoadedSites ?? false
            return item
        }
        outlineView.reloadData()
        for item in jarItems where expanded.contains(item.record.id) {
            outlineView.expandItem(item)
        }
        restoreSelection(selection)
    }

    /// Reads the sites of one jar, or of every jar one after another, and
    /// returns the task so a caller — a test — can wait for it.
    ///
    /// Reads compose rather than cancel each other: each jar's answer is
    /// applied only if no newer read of that jar was asked for meanwhile,
    /// and it lands on whichever row carries that jar's id now — a Refresh
    /// while a read was out rebuilds the rows, and the answer still belongs
    /// on screen.
    @discardableResult
    func loadSites(of only: JarItem? = nil) -> Task<Void, Never> {
        let targets = only.map { [$0] } ?? jarItems
        let reads = targets.map { item -> (BrowserSiteData, UUID, Int) in
            let generation = (readGenerations[item.record.id] ?? 0) + 1
            readGenerations[item.record.id] = generation
            return (item.siteData, item.record.id, generation)
        }
        if only == nil { fullLoadTask?.cancel() }
        let task = Task { [weak self] in
            for (siteData, jarID, generation) in reads {
                guard !Task.isCancelled, let self else { return }
                let records = await self.readSites(siteData)
                guard !Task.isCancelled else { return }
                guard self.readGenerations[jarID] == generation else { continue }
                self.apply(records, toJar: jarID)
            }
        }
        if only == nil { fullLoadTask = task }
        return task
    }

    private func apply(_ records: [WKWebsiteDataRecord], toJar jarID: UUID) {
        guard let item = jarItems.first(where: { $0.record.id == jarID }) else { return }
        let selection = selectedSiteKey
        item.sites = records.map { SiteItem(record: $0, jar: item) }
        item.hasLoadedSites = true
        outlineView.reloadItem(item, reloadChildren: true)
        restoreSelection(selection)
    }

    // MARK: - Selection

    /// A selected site, named by its jar as well as its name: two jars can
    /// both hold `github.com`, and Remove — which does not ask — must act on
    /// the one the user picked.
    struct SiteKey: Equatable {
        let jarID: UUID
        let displayName: String
    }

    var selectedSiteKey: SiteKey? {
        guard let site = selectedItem as? SiteItem else { return nil }
        return SiteKey(jarID: site.jar.record.id, displayName: site.record.displayName)
    }

    /// Puts the selection back on the same site of the same jar after a
    /// reload, or clears it when that pair is gone — never onto a namesake
    /// in another jar. A selected jar row is left to the outline.
    private func restoreSelection(_ key: SiteKey?) {
        defer { updateButtons() }
        guard let key else { return }
        let site = jarItems.first { $0.record.id == key.jarID }?
            .sites.first { $0.record.displayName == key.displayName }
        let row = site.map { outlineView.row(forItem: $0) } ?? -1
        if row >= 0 {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        } else {
            outlineView.deselectAll(nil)
        }
    }

    // MARK: - Actions

    var selectedItem: Any? {
        let row = outlineView.selectedRow
        return row >= 0 ? outlineView.item(atRow: row) : nil
    }

    /// The jar a Clear acts on: the selected jar, or the jar of the selected
    /// site.
    private var selectedJar: JarItem? {
        switch selectedItem {
        case let jar as JarItem: jar
        case let site as SiteItem: site.jar
        default: nil
        }
    }

    private func updateButtons() {
        removeButton.isEnabled = selectedItem is SiteItem
        clearButton.isEnabled = selectedJar != nil
    }

    /// Removes one site's data from its jar. Not confirmed, like − on a site
    /// in the global topic: it is one site, and the row says which.
    @objc private func removeSite(_ sender: Any?) {
        guard let site = selectedItem as? SiteItem else { return }
        let jar = site.jar
        Task {
            await removeSite(site.record, from: jar)
        }
    }

    func removeSite(_ record: WKWebsiteDataRecord, from jar: JarItem) async {
        await jar.siteData.remove([record])
        await loadSites(of: jar).value
    }

    /// Empties a whole jar, after asking — as Remove All does in the global
    /// topic.
    @objc private func clearJar(_ sender: Any?) {
        guard let jar = selectedJar else { return }
        ComposableSettings.Alerts.confirmDestructive(
            "Clear all site data in “\(Self.label(for: jar.record))”?",
            detail: "Cookies, caches and storage for every site in this jar are removed, and you "
                + "are signed out of them in every pane that uses it. History is not affected.",
            actionTitle: "Clear",
            on: view.window
        ) { [weak self] confirmed in
            guard let self, confirmed else { return }
            Task { await self.clear(jar) }
        }
    }

    func clear(_ jar: JarItem) async {
        await jar.siteData.removeAll()
        await loadSites(of: jar).value
    }

    @objc private func refresh(_ sender: Any?) {
        reload()
    }
}

// MARK: - Outline

extension ProjectBrowserJarsSettingsPanel: NSOutlineViewDataSource, NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        switch item {
        case nil: jarItems.count
        case let jar as JarItem: jar.sites.count
        default: 0
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        switch item {
        case let jar as JarItem: jar.sites[index]
        default: jarItems[index]
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? JarItem).map { !$0.sites.isEmpty } ?? false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let column = tableColumn?.identifier else { return nil }
        let text: String
        switch (item, column) {
        case (let jar as JarItem, Self.nameColumn):
            text = Self.label(for: jar.record)
        case (let jar as JarItem, _):
            text = jar.hasLoadedSites ? Self.siteCount(jar.sites.count) : ""
        case (let site as SiteItem, Self.nameColumn):
            text = site.record.displayName
        case (let site as SiteItem, _):
            text = BrowserSiteData.labels(for: site.record)
        default:
            return nil
        }
        let cell = (outlineView.makeView(withIdentifier: column, owner: self) as? NSTableCellView)
            ?? Self.makeCell(identifier: column)
        cell.textField?.stringValue = text
        cell.toolTip = text
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }

    private static func makeCell(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = identifier
        let label = ThemedLabel(role: .primaryText, textRole: .body)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        cell.textField = label
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            cell.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 2),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
}
