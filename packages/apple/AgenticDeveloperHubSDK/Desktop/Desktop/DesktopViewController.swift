import AgenticDeveloperHubSDKCoreUI
import AppKit
import Combine

/// The Desktop surface: background, then the icon layer (grid or list), then
/// the container that holds App windows. In the macOS menu style a menu bar runs
/// across the top, showing the front window's menus after an AI-star menu.
@MainActor
public final class DesktopViewController: NSViewController {
    /// The SF Symbol that titles the leading menu of the macOS-style menu bar.
    static let starSymbolName = "sparkle"

    private let registry: DesktopAppRegistry
    private let settings: DesktopSettings
    private let backgroundView = DesktopBackgroundView()
    private let gridView = DesktopIconGridView()
    private let listView = DesktopIconListView()
    let windowLayer = DesktopWindowLayerView()
    /// The macOS-style menu bar; hidden in the Windows style.
    let topMenuBar = DesktopMenuBarView()
    private var appliedMenuStyle: DesktopMenuStyle?
    private var desktopMenuTargets: [ClosureMenuItemTarget] = []
    private var desktopSettingsItems: [NSMenuItem] = []
    /// The AI-star menu; its title is the star's accessibility label.
    private lazy var starMenu = makeDesktopMenu(title: "AI")
    private lazy var desktopMenu = makeDesktopMenu(title: "Desktop")
    private var windowControllers: [String: DesktopAppWindowController] = [:]
    private var subscription: AnyCancellable?
    private var cachedImagePath: String?
    private var cachedImage: NSImage?
    private var appliedBackground: (hex: String, path: String?)?
    private var appliedIconState: IconLayerState?

    public init(registry: DesktopAppRegistry, settings: DesktopSettings = .shared) {
        self.registry = registry
        self.settings = settings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func loadView() {
        let root = DesktopRootView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        root.keyEquivalentHandler = { [weak self] event in
            self?.performWindowKeyEquivalent(with: event) ?? false
        }
        root.onLayout = { [weak self] in self?.layoutSurface() }
        for subview in [backgroundView, gridView, listView, windowLayer] {
            subview.frame = root.bounds
            subview.autoresizingMask = [.width, .height]
            root.addSubview(subview)
        }
        // Translucent over the backdrop, like the macOS menu bar.
        topMenuBar.fillColor = NSColor.windowBackgroundColor.withAlphaComponent(0.82)
        topMenuBar.setAccessibilityLabel("Desktop menu bar")
        root.addSubview(topMenuBar)
        windowLayer.onStackChange = { [weak self] in self?.refreshTopMenuBar() }
        gridView.onOpen = { [weak self] in self?.openApp(identifier: $0) }
        listView.onOpen = { [weak self] in self?.openApp(identifier: $0) }
        gridView.onMoveIcon = { [weak self] in self?.iconMoved(identifier: $0, to: $1) }
        view = root
        subscription = settings.changes.sink { [weak self] in
            MainActor.assumeIsolated { self?.settingsChanged() }
        }
        apply()
    }

    // MARK: Windows

    /// Open window identifiers, back to front, including "about:<id>" and "settings:<id>".
    var openWindowIdentifiers: [String] { windowLayer.identifiers }

    func windowController(_ id: String) -> DesktopAppWindowController? { windowControllers[id] }

    private var frontWindowController: DesktopAppWindowController? {
        windowLayer.stack.frontID.flatMap { windowControllers[$0] }
    }

    /// Offers a key event to the front window's menus, then, for a front About or Settings
    /// window, to its App's menus: the menus the top bar shows, so their keys work too.
    private func performWindowKeyEquivalent(with event: NSEvent) -> Bool {
        guard let front = frontWindowController else { return false }
        if front.performKeyEquivalent(with: event) { return true }
        guard front.kind != .app, let owner = windowControllers[front.app.descriptor.identifier] else {
            return false
        }
        return owner.performKeyEquivalent(with: event)
    }

    /// Opens the App's window, or brings it to the front when already open.
    public func openApp(identifier: String) {
        guard let app = registry.app(withIdentifier: identifier) else { return }
        openWindow(kind: .app, app: app) { app.makeContentViewController(context: $0) }
    }

    public func closeApp(identifier: String) {
        guard windowControllers[identifier]?.kind == .app else { return }
        closeWindow(id: identifier)
    }

    public func isShowingSettings(forApp identifier: String) -> Bool {
        windowLayer.contains(DesktopAppWindowController.Kind.settings.windowID(forApp: identifier))
    }

    /// The content of the App's open Settings window, or nil when none is open.
    public func settingsContent(forApp identifier: String) -> NSViewController? {
        windowControllers[DesktopAppWindowController.Kind.settings.windowID(forApp: identifier)]?
            .contentViewController
    }

    public func showSettings(forApp identifier: String) {
        guard let app = registry.app(withIdentifier: identifier), app.hasSettings else { return }
        let appSettings = settings.appSettings(for: app)
        openWindow(kind: .settings, app: app) { context in
            app.makeSettingsViewController(context: context)
                ?? DesktopSettingsFormViewController(schema: app.descriptor.settingsSchema, settings: appSettings)
        }
    }

    public func showAbout(forApp identifier: String) {
        guard let app = registry.app(withIdentifier: identifier) else { return }
        openWindow(kind: .about, app: app) { _ in DesktopAboutViewController(app: app) }
    }

    private func openWindow(
        kind: DesktopAppWindowController.Kind,
        app: DesktopApp,
        makeContent: (DesktopAppContext) -> NSViewController
    ) {
        let id = kind.windowID(forApp: app.descriptor.identifier)
        guard !windowLayer.contains(id) else {
            windowLayer.bringToFront(id)
            return
        }
        let controller = DesktopAppWindowController(
            kind: kind, app: app, settings: settings.appSettings(for: app), host: self,
            showsOwnMenuBar: settings.menuStyle == .windows, makeContent: makeContent
        )
        controller.chrome.onFrameCommit = { [weak self] in self?.windowFrameCommitted(id: id, frame: $0) }
        windowControllers[id] = controller
        if let content = controller.contentViewController { addChild(content) }
        windowLayer.open(id: id, chrome: controller.chrome, frame: initialFrame(for: controller))
        controller.chrome.needsLayout = true
    }

    /// The saved frame (a whole-window frame) clamped into the Desktop, or the default content size
    /// plus the chrome, centered with a cascade step per open window.
    private func initialFrame(for controller: DesktopAppWindowController) -> CGRect {
        let container = windowLayer.bounds.size
        let chrome = controller.chrome
        let minimum = chrome.minimumWindowSize
        if controller.kind == .app, let saved = settings.windowFrames[controller.app.descriptor.identifier] {
            return DesktopWindowChromeView.clamped(saved, in: container, minimum: minimum)
        }
        let size = chrome.windowSize(forContent: controller.defaultContentSize)
        let cascade = CGFloat(windowLayer.identifiers.count) * Self.cascadeStep
        let origin = CGPoint(
            x: (container.width - size.width) / 2 + cascade,
            y: (container.height - size.height) / 2 + cascade
        )
        return DesktopWindowChromeView.clamped(CGRect(origin: origin, size: size), in: container, minimum: minimum)
    }

    private static let cascadeStep: CGFloat = 24

    /// Opens the Desktop's Settings App, when the registry holds one.
    public func showDesktopSettings() {
        openApp(identifier: DesktopSettingsApp.identifier)
    }

    // MARK: Menu bar

    private var showsTopMenuBar: Bool { settings.menuStyle == .macOS }

    /// Sizes the layers: in the macOS style the icons and windows sit below the top menu bar,
    /// while the backdrop runs under it.
    private func layoutSurface() {
        let bounds = view.bounds
        let barHeight = showsTopMenuBar ? DesktopMenuBarView.height : 0
        backgroundView.frame = bounds
        let surface = CGRect(x: 0, y: 0, width: bounds.width, height: max(0, bounds.height - barHeight))
        for layer in [gridView, listView, windowLayer] as [NSView] where layer.frame != surface {
            layer.frame = surface
            layer.needsLayout = true
        }
        topMenuBar.isHidden = !showsTopMenuBar
        topMenuBar.frame = CGRect(
            x: 0, y: bounds.height - DesktopMenuBarView.height,
            width: bounds.width, height: DesktopMenuBarView.height
        )
    }

    /// The menus the top bar shows after the star: the front App window's, the owning App's
    /// for a front About or Settings window, or the Desktop menu when no window is open.
    var topMenuBarMenus: [NSMenu] {
        guard let front = frontWindowController else { return [desktopMenu] }
        if front.kind != .app, let owner = windowControllers[front.app.descriptor.identifier] {
            return owner.menus
        }
        return front.menus
    }

    private func refreshTopMenuBar() {
        guard isViewLoaded, showsTopMenuBar else { return }
        // Both menus are lazy; build them before hiding their items.
        let star = starMenu
        let menus = topMenuBarMenus
        let hasSettingsApp = registry.app(withIdentifier: DesktopSettingsApp.identifier) != nil
        desktopSettingsItems.forEach { $0.isHidden = !hasSettingsApp }
        // Raising a window re-renders the stack; skip the rebuild when nothing changed.
        guard topMenuBar.menus.count != menus.count + 1
            || !zip(topMenuBar.menus.dropFirst(), menus).allSatisfy({ $0 === $1 }) else { return }
        topMenuBar.configure(menus: menus, symbolMenu: (Self.starSymbolName, star))
    }

    private func makeDesktopMenu(title: String) -> NSMenu {
        let menu = NSMenu(title: title)
        let target = ClosureMenuItemTarget(action: { [weak self] in self?.showDesktopSettings() })
        desktopMenuTargets.append(target)
        let item = NSMenuItem(
            title: "Desktop Settings…",
            action: #selector(ClosureMenuItemTarget.performMenuAction(_:)),
            keyEquivalent: ""
        )
        item.target = target
        desktopSettingsItems.append(item)
        menu.addItem(item)
        return menu
    }

    private func applyMenuStyle() {
        let style = settings.menuStyle
        guard style != appliedMenuStyle else { return }
        appliedMenuStyle = style
        for controller in windowControllers.values {
            controller.showsOwnMenuBar = style == .windows
        }
        layoutSurface()
        if style == .macOS {
            refreshTopMenuBar()
        } else {
            topMenuBar.configure(menus: [])
        }
    }

    override public func viewWillAppear() {
        super.viewWillAppear()
        // Showing the Desktop again picks up a photo that has become readable since.
        apply()
    }

    // MARK: Test seams

    var selectedAppIdentifier: String? {
        settings.iconArrangement == .list ? listView.selectedIdentifier : gridView.selectedIdentifier
    }

    var currentBackgroundImage: NSImage? { backgroundView.image }
    var iconOrigins: [String: CGPoint] { gridView.iconOrigins }

    // MARK: Settings

    private func settingsChanged() {
        apply()
    }

    private static func metrics(for arrangement: DesktopIconArrangement) -> DesktopIconLayout.Metrics {
        arrangement == .smallIcons ? .small : .large
    }

    /// Everything the icon layer shows. When it is unchanged, nothing is redone.
    private struct IconLayerState: Equatable {
        let identifiers: [String]
        let arrangement: DesktopIconArrangement
        let keepArranged: Bool
        /// Only the grid shows positions; list mode ignores them.
        let positions: [String: CGPoint]
    }

    private func apply() {
        guard isViewLoaded else { return }
        applyMenuStyle()
        let hex = settings.backgroundColorHex
        let path = settings.backgroundImagePath
        // A photo that couldn't be read yet (still syncing, say) is tried again on every apply.
        let photoMissing = path != nil && backgroundView.image == nil
        if appliedBackground?.hex != hex || appliedBackground?.path != path || photoMissing {
            appliedBackground = (hex, path)
            backgroundView.color = NSColor(desktopHex: hex) ?? .windowBackgroundColor
            backgroundView.image = backgroundImage(for: path)
        }
        let apps = registry.apps.sortedByName
        let arrangement = settings.iconArrangement
        let showList = arrangement == .list
        let state = IconLayerState(
            identifiers: apps.map { $0.descriptor.identifier },
            arrangement: arrangement,
            keepArranged: settings.keepArranged,
            positions: showList ? [:] : settings.iconPositions
        )
        guard state != appliedIconState else { return }
        appliedIconState = state
        gridView.isHidden = showList
        listView.isHidden = !showList
        if showList {
            listView.configure(apps: apps)
        } else {
            gridView.configure(
                apps: apps,
                metrics: Self.metrics(for: arrangement),
                keepArranged: state.keepArranged,
                positions: state.positions
            )
        }
    }

    /// Loads the photo once per path. A missing or unreadable file is nil, never an error, and
    /// is not remembered: the next call reads the file again.
    private func backgroundImage(for path: String?) -> NSImage? {
        if let path, path == cachedImagePath, let cachedImage { return cachedImage }
        let image = path.flatMap { FileManager.default.isReadableFile(atPath: $0) ? NSImage(contentsOfFile: $0) : nil }
        cachedImagePath = image == nil ? nil : path
        cachedImage = image
        return image
    }

    /// Saves every icon where it now stands, not just the moved one: icons with no saved
    /// position fill the next free cell, so they would shift when the moved one vacates its cell.
    private func iconMoved(identifier: String, to origin: CGPoint) {
        var positions = settings.iconPositions.merging(gridView.iconOrigins) { _, shown in shown }
        positions[identifier] = origin
        guard positions != settings.iconPositions else { return }
        settings.iconPositions = positions
    }
}

extension DesktopViewController: DesktopWindowHost {
    func closeWindow(id: String) {
        guard let controller = windowControllers.removeValue(forKey: id) else { return }
        if controller.kind == .app { controller.app.appWillClose(context: controller.context) }
        controller.contentViewController?.removeFromParent()
        windowLayer.close(id)
        controller.teardown()
    }

    func windowFrameCommitted(id: String, frame: CGRect) {
        // Only App windows remember their frame, and only for registered Apps.
        guard registry.app(withIdentifier: id) != nil else { return }
        var frames = settings.windowFrames
        guard frames[id] != frame else { return }
        frames[id] = frame
        settings.windowFrames = frames
    }

    func presentAlert(_ alert: NSAlert) {
        if let window = view.window {
            alert.beginSheetModal(for: window)
        } else {
            _ = alert.runModal()
        }
    }
}

/// The Desktop's root view: offers key equivalents to the front App window first.
final class DesktopRootView: NSView {
    var keyEquivalentHandler: ((NSEvent) -> Bool)?
    var onLayout: (() -> Void)?

    override func layout() {
        onLayout?()
        super.layout()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if keyEquivalentHandler?(event) == true { return true }
        return super.performKeyEquivalent(with: event)
    }
}

@MainActor
extension Array where Element == DesktopApp {
    /// Case-insensitive by display name: the order the Desktop shows Apps in.
    var sortedByName: [DesktopApp] {
        sorted {
            $0.descriptor.displayName.localizedCaseInsensitiveCompare($1.descriptor.displayName) == .orderedAscending
        }
    }
}
