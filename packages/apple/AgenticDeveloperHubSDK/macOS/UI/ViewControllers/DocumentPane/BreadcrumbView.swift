import AppKit

import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI

/// A breadcrumb strip like Xcode's jump bar: the open file's path laid out as
/// a row of icon-and-name buttons separated by chevrons.
///
/// Clicking a crumb shows a menu of that crumb's directory, built by
/// `BreadcrumbMenu`: its files and folders, each folder a submenu of its own,
/// so the reader can walk down into any subfolder from there. Choosing a file
/// reports it through `onSelect`. The menu leaves out what the file browser
/// leaves out (`filter`).
///
/// The path arithmetic here touches no filesystem (see `titles(for:)`); only
/// the menu reads a directory, and only when it opens.
@MainActor
public final class BreadcrumbView: NSView {

    /// How the crumbs spell the path.
    public enum Style: Sendable {
        /// Below the root: `Sources › App › Main.swift`.
        case rootRelative
        /// From the home folder: `~ › Development › app › Main.swift`. A path
        /// outside the home folder starts at `/`.
        case homeRelative
    }

    private let rootURL: URL
    private let style: Style
    private let homeURL: URL
    private let stack = NSStackView()

    /// The file the strip currently describes. `nil` clears the strip.
    public var fileURL: URL? {
        didSet { rebuild() }
    }

    /// Fires with the file a crumb's menu chose, or with a crumb's own
    /// directory when `selectCrumb(at:)` is called directly. The owner routes
    /// this straight to whatever opens files in the document view — choosing
    /// in the breadcrumb is the same as clicking in the tree.
    public var onSelect: ((URL) -> Void)?

    /// What a crumb's menu leaves out, asked each time a menu opens so it
    /// follows the file browser's content filter as it changes. The default
    /// applies Settings > File Browser > Excluded, anchored at the root.
    public lazy var filter: () -> FileTreeFilter = { [rootURL] in
        FileTreeFilter(
            rootURL: rootURL,
            matcher: GitIgnoreMatcher(patterns: UserSettings.fileBrowserExcludedPatterns.currentValue)
        )
    }

    /// Directories the strip may not leave: a crumb above the one of these
    /// that holds the file is disabled, so a project's breadcrumb only moves
    /// within the project. Empty (the default) leaves every crumb enabled.
    public var confiningRoots: [URL] = [] {
        didSet { rebuild() }
    }

    /// When set, every directory menu starts with a "Browse" item that reports
    /// its directory here — a File Browser window switching to another folder.
    /// Nil (the default) leaves directories as places to walk through only.
    public var onSelectDirectory: ((URL) -> Void)?

    /// The crumb labels, first to last. Empty when there is no file.
    public private(set) var crumbTitles: [String] = []

    /// The directory each crumb's menu lists, parallel to `crumbTitles`. The
    /// last entry (the file's own crumb) is the file's *containing* directory
    /// — its menu lists the file's siblings.
    private(set) var crumbDirectories: [URL] = []

    /// The path each crumb names, parallel to `crumbTitles`, for its icon.
    private var crumbURLs: [URL] = []

    /// Kept while a crumb's menu is up: `NSMenu` holds its delegate weakly.
    private var activeMenu: BreadcrumbMenu?

    /// One button per crumb, parallel to `crumbTitles`.
    private var crumbButtons: [NSButton] = []
    /// How many leading crumbs are collapsed to "…" to fit the width.
    public private(set) var collapsedCount = 0
    /// Whether the strip is showing less than the whole path.
    public var isTruncated: Bool { collapsedCount > 0 }
    /// The full-width copy shown over the neighbours while the pointer is on
    /// a truncated strip.
    private var expansion: BreadcrumbExpansionWindow?
    private var hoverArea: NSTrackingArea?
    /// Set on the copy inside an expansion, which never truncates or expands.
    var expandsOnHover = true

    public init(
        rootURL: URL,
        style: Style = .rootRelative,
        homeURL: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.rootURL = rootURL
        self.style = style
        self.homeURL = homeURL
        super.init(frame: .zero)
        stack.orientation = .horizontal
        stack.spacing = 2
        stack.alignment = .centerY
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Reports crumb `index`'s directory through `onSelect`. Exists so the
    /// index-to-directory mapping is testable without showing a menu — the
    /// real click handler (`crumbClicked(_:)`) pops the menu instead.
    public func selectCrumb(at index: Int) {
        guard index >= 0, index < crumbDirectories.count else { return }
        onSelect?(crumbDirectories[index])
    }

    /// The menu crumb `index` shows, built but not shown. For tests.
    func menu(forCrumbAt index: Int) -> NSMenu? {
        guard index >= 0, index < crumbDirectories.count else { return nil }
        let builder = BreadcrumbMenu(filter: filter(), palette: resolvedThemeScope.palette) { [weak self] url in
            self?.onSelect?(url)
        }
        if let onSelectDirectory {
            builder.onChooseDirectory = { [weak self] url in
                self?.dismissExpansion()
                onSelectDirectory(url)
            }
        }
        activeMenu = builder
        return builder.menu(for: crumbDirectories[index], marking: crumbURLs[index])
    }

    // MARK: - Layout

    private func rebuild() {
        let path = Self.path(for: fileURL, rootURL: rootURL, style: style, homeURL: homeURL)
        crumbTitles = path.map(\.title)
        crumbURLs = path.map(\.url)
        crumbDirectories = path.indices.map { index in
            index == path.count - 1 ? path[index].url.deletingLastPathComponent() : path[index].url
        }

        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        crumbButtons = []
        collapsedCount = 0
        for index in path.indices {
            if index > 0 {
                stack.addArrangedSubview(Self.chevron())
            }
            let button = crumbButton(index: index, isLast: index == path.count - 1)
            button.isEnabled = !isOutsideConfiningRoot(path[index].url)
            crumbButtons.append(button)
            stack.addArrangedSubview(button)
        }
        needsLayout = true
    }

    public override func layout() {
        super.layout()
        fitCrumbs()
    }

    /// A strip too narrow for its path keeps the file's own crumb whole and
    /// collapses the crumbs before it to "…", leftmost first, until it fits.
    private func fitCrumbs() {
        guard expandsOnHover, !crumbButtons.isEmpty, bounds.width > 0 else { return }
        let available = bounds.width - 16
        var collapse = 0
        restoreCrumbs(collapsing: 0)
        while stack.fittingSize.width > available, collapse < crumbButtons.count - 1 {
            collapse += 1
            restoreCrumbs(collapsing: collapse)
        }
        collapsedCount = collapse
        if collapse == 0 { dismissExpansion() }
    }

    private func restoreCrumbs(collapsing count: Int) {
        for (index, button) in crumbButtons.enumerated() {
            let collapsed = index < count
            let title = collapsed ? "…" : crumbTitles[index]
            if button.title != title { button.title = title }
            // The whole collapsed run is the first crumb's one "…".
            button.isHidden = collapsed && index > 0
            let isLast = index == crumbButtons.count - 1
            let isDirectory = !isLast || (fileURL.map(Self.isDirectory) ?? false)
            button.image = collapsed ? nil : BreadcrumbMenu.icon(
                for: crumbURLs[index], isDirectory: isDirectory, palette: resolvedThemeScope.palette)
        }
        // A collapsed run reads as one "…": the chevrons between them go.
        for (offset, view) in stack.arrangedSubviews.enumerated() where view is NSImageView {
            let crumbAfter = (offset + 1) / 2
            view.isHidden = crumbAfter < count
        }
    }

    // MARK: - Hover expansion

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        guard expandsOnHover else { return }
        let area = NSTrackingArea(
            rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverArea = area
    }

    public override func mouseEntered(with event: NSEvent) {
        guard isTruncated, expansion == nil, let window else { return }
        let copy = BreadcrumbView(rootURL: rootURL, style: style, homeURL: homeURL)
        copy.expandsOnHover = false
        copy.filter = filter
        copy.confiningRoots = confiningRoots
        copy.onSelectDirectory = onSelectDirectory
        copy.onSelect = { [weak self] url in
            self?.dismissExpansion()
            self?.onSelect?(url)
        }
        copy.fileURL = fileURL
        let width = max(bounds.width, copy.stack.fittingSize.width + 16)
        var frame = window.convertToScreen(convert(bounds, to: nil))
        frame.size.width = width
        if let screen = window.screen, frame.maxX > screen.visibleFrame.maxX {
            frame.origin.x = max(screen.visibleFrame.minX, screen.visibleFrame.maxX - width)
        }
        let panel = BreadcrumbExpansionWindow(frame: frame, content: copy) { [weak self] in
            self?.dismissExpansion()
        }
        window.addChildWindow(panel, ordered: .above)
        expansion = panel
    }

    private func dismissExpansion() {
        guard let expansion else { return }
        expansion.parent?.removeChildWindow(expansion)
        expansion.orderOut(nil)
        self.expansion = nil
    }

    public override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow == nil { dismissExpansion() }
        super.viewWillMove(toWindow: newWindow)
    }

    private func crumbButton(index: Int, isLast: Bool) -> NSButton {
        let url = crumbURLs[index]
        let isDirectory = !isLast || (fileURL.map(Self.isDirectory) ?? false)
        let button = NSButton(title: crumbTitles[index], target: self, action: #selector(crumbClicked(_:)))
        button.tag = index
        button.bezelStyle = .inline
        button.isBordered = false
        button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        button.image = BreadcrumbMenu.icon(for: url, isDirectory: isDirectory, palette: resolvedThemeScope.palette)
        button.imagePosition = .imageLeading
        button.imageHugsTitle = true
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.lineBreakMode = .byTruncatingMiddle
        button.toolTip = url.path
        button.accessibilityID("breadcrumb.crumb.\(index)")
        return button
    }

    private static func chevron() -> NSImageView {
        let image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil)
        let imageView = NSImageView(image: image ?? NSImage())
        imageView.symbolConfiguration = .init(pointSize: 9, weight: .regular)
        imageView.contentTintColor = .secondaryLabelColor
        return imageView
    }

    @objc private func crumbClicked(_ sender: NSButton) {
        guard let menu = menu(forCrumbAt: sender.tag) else { return }
        // Below the crumb, left edges aligned, the way a pull-down opens.
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY + 4), in: sender)
        activeMenu = nil
    }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    /// Whether `crumb` lies above the confining root that holds the file.
    private func isOutsideConfiningRoot(_ crumb: URL) -> Bool {
        guard let file = fileURL?.standardizedFileURL.pathComponents else { return false }
        let holding = confiningRoots
            .map { $0.standardizedFileURL.pathComponents }
            .filter { file.starts(with: $0) }
            .max { $0.count < $1.count }
        guard let root = holding else { return false }
        let components = crumb.standardizedFileURL.pathComponents
        return components.count < root.count && root.starts(with: components)
    }

    // MARK: - Path arithmetic

    /// One crumb: what it says and the path it names.
    struct Crumb: Equatable {
        let title: String
        let url: URL
    }

    /// The crumbs for `url`. Root-relative, a file three levels under the
    /// root is `["Sources", "App", "Main.swift"]`, and a file outside the root
    /// falls back to its own name alone, so the strip is never empty for a
    /// file that merely lives somewhere unexpected. Home-relative, the path
    /// starts at `~` under the home folder and at `/` anywhere else.
    static func path(for url: URL?, rootURL: URL, style: Style, homeURL: URL) -> [Crumb] {
        guard let url else { return [] }
        let file = url.standardizedFileURL
        let fileComponents = file.pathComponents

        func crumbs(below base: URL, firstTitle: String?) -> [Crumb]? {
            let baseComponents = base.standardizedFileURL.pathComponents
            guard fileComponents.count >= baseComponents.count,
                  Array(fileComponents.prefix(baseComponents.count)) == baseComponents
            else { return nil }
            var result: [Crumb] = []
            var current = base.standardizedFileURL
            if let firstTitle { result.append(Crumb(title: firstTitle, url: current)) }
            for component in fileComponents.dropFirst(baseComponents.count) {
                current.appendPathComponent(component)
                result.append(Crumb(title: component, url: current))
            }
            return result
        }

        switch style {
        case .rootRelative:
            if let below = crumbs(below: rootURL, firstTitle: nil), !below.isEmpty { return below }
            return [Crumb(title: file.lastPathComponent, url: file)]
        case .homeRelative:
            if let below = crumbs(below: homeURL, firstTitle: "~") { return below }
            return crumbs(below: URL(fileURLWithPath: "/"), firstTitle: "/") ?? []
        }
    }
}

/// Builds the menu a breadcrumb crumb shows: one directory's files and
/// folders, folders first, each folder a submenu filled when it opens — one
/// level at a time, like the tree, so a crumb over a big checkout never walks
/// it. Choosing a file calls `onChoose`; folders are only for walking into.
@MainActor
final class BreadcrumbMenu: NSObject, NSMenuDelegate {

    private let filter: FileTreeFilter
    private let palette: SemanticPalette
    private let onChoose: (URL) -> Void

    /// The directory each not-yet-filled submenu lists.
    private var pending: [ObjectIdentifier: URL] = [:]

    init(filter: FileTreeFilter, palette: SemanticPalette, onChoose: @escaping (URL) -> Void) {
        self.filter = filter
        self.palette = palette
        self.onChoose = onChoose
    }

    /// The menu for `directory`, with `marked` (the crumb's own path) checked.
    func menu(for directory: URL, marking marked: URL? = nil) -> NSMenu {
        let menu = NSMenu(title: directory.lastPathComponent)
        menu.autoenablesItems = false
        fill(menu, with: directory, marking: marked)
        return menu
    }

    /// Set to offer each directory menu's own folder as a choice ("Browse").
    var onChooseDirectory: ((URL) -> Void)?

    private func fill(_ menu: NSMenu, with directory: URL, marking marked: URL?) {
        if onChooseDirectory != nil {
            let browse = NSMenuItem(
                title: "Browse “\(directory.lastPathComponent)”",
                action: #selector(chooseDirectory(_:)), keyEquivalent: "")
            browse.target = self
            browse.representedObject = directory
            menu.addItem(browse)
            menu.addItem(.separator())
        }
        let entries = FileTreeNode.loadChildren(for: directory, filter: filter)
        guard !entries.isEmpty else {
            let empty = NSMenuItem(title: "Empty", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            return
        }
        for node in entries {
            let item = NSMenuItem(title: node.name, action: nil, keyEquivalent: "")
            item.image = Self.icon(for: node, palette: palette)
            item.representedObject = node.url
            if node.url.standardizedFileURL == marked?.standardizedFileURL { item.state = .on }
            if node.isDirectory && !node.isPackage {
                let submenu = NSMenu(title: node.name)
                submenu.autoenablesItems = false
                submenu.delegate = self
                pending[ObjectIdentifier(submenu)] = node.url
                item.submenu = submenu
            } else {
                item.target = self
                item.action = #selector(choose(_:))
            }
            menu.addItem(item)
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let directory = pending.removeValue(forKey: ObjectIdentifier(menu)) else { return }
        menu.removeAllItems()
        fill(menu, with: directory, marking: nil)
    }

    @objc private func chooseDirectory(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        onChooseDirectory?(url)
    }

    @objc private func choose(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        onChoose(url)
    }

    // MARK: - Icons

    /// The icon the file tree draws for `node`: the same symbol, the same
    /// tint, at menu size.
    static func icon(for node: FileTreeNode, palette: SemanticPalette) -> NSImage? {
        tinted(node.systemImageName, color: node.iconColor(palette: palette), description: node.name)
    }

    static func icon(for url: URL, isDirectory: Bool, palette: SemanticPalette) -> NSImage? {
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL
        if url.path == "/" || url.standardizedFileURL == home {
            let name = url.path == "/" ? "internaldrive" : "house"
            return tinted(name, color: palette.nsColor(.accent), description: url.lastPathComponent)
        }
        return icon(for: FileTreeNode(url: url, isDirectory: isDirectory, loadChildren: false), palette: palette)
    }

    private static func tinted(_ symbol: String, color: NSColor, description: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: 11, weight: .regular)
            .applying(.init(paletteColors: [color]))
        return NSImage(systemSymbolName: symbol, accessibilityDescription: description)?
            .withSymbolConfiguration(configuration)
    }
}

/// The borderless window a truncated breadcrumb shows its whole path in, laid
/// over the views beside it, gone when the pointer leaves it.
@MainActor
final class BreadcrumbExpansionWindow: NSPanel {
    private let onExit: () -> Void

    init(frame: NSRect, content: BreadcrumbView, onExit: @escaping () -> Void) {
        self.onExit = onExit
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        hasShadow = true
        backgroundColor = .clear
        let host = HoverExitView(onExit: onExit)
        host.wantsLayer = true
        host.layer?.cornerRadius = 4
        host.layer?.backgroundColor = NSColor(ThemePaletteObserver.currentPalette.projectPaneBackdrop).cgColor
        content.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            content.topAnchor.constraint(equalTo: host.topAnchor),
            content.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
        contentView = host
    }

    override var canBecomeKey: Bool { false }
}

@MainActor
private final class HoverExitView: NSView {
    private let onExit: () -> Void
    init(onExit: @escaping () -> Void) {
        self.onExit = onExit
        super.init(frame: .zero)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    override func mouseExited(with event: NSEvent) { onExit() }
}
