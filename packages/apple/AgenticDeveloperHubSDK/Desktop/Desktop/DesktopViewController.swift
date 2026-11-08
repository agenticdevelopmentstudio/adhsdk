import AppKit
import Combine

/// The Desktop surface: background, then the icon layer (grid or list), then
/// the container that holds App windows.
@MainActor
public final class DesktopViewController: NSViewController {
    private let registry: DesktopAppRegistry
    private let settings: DesktopSettings
    private let backgroundView = DesktopBackgroundView()
    private let gridView = DesktopIconGridView()
    private let listView = DesktopIconListView()
    let windowLayer = DesktopWindowLayerView()
    private var windowControllers: [String: DesktopAppWindowController] = [:]
    private var subscription: AnyCancellable?
    private var lastKeepArranged: Bool
    private var cachedImagePath: String?
    private var cachedImage: NSImage?
    private var appliedBackground: (hex: String, path: String?)?
    private var appliedIconState: IconLayerState?

    public init(registry: DesktopAppRegistry, settings: DesktopSettings = .shared) {
        self.registry = registry
        self.settings = settings
        self.lastKeepArranged = settings.keepArranged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func loadView() {
        let root = DesktopRootView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        root.keyEquivalentHandler = { [weak self] event in
            self?.frontWindowController?.performKeyEquivalent(with: event) ?? false
        }
        for subview in [backgroundView, gridView, listView, windowLayer] {
            subview.frame = root.bounds
            subview.autoresizingMask = [.width, .height]
            root.addSubview(subview)
        }
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

    /// Opens the App's window, or brings it to the front when already open.
    public func openApp(identifier: String) {
        guard let app = registry.app(withIdentifier: identifier) else { return }
        openWindow(kind: .app, app: app) { app.makeContentViewController(context: $0) }
    }

    public func closeApp(identifier: String) {
        closeWindow(id: identifier)
    }

    public func isShowingSettings(forApp identifier: String) -> Bool {
        windowLayer.contains(DesktopAppWindowController.Kind.settings.windowID(forApp: identifier))
    }

    public func showSettings(forApp identifier: String) {
        guard let app = registry.app(withIdentifier: identifier) else { return }
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
            kind: kind, app: app, settings: settings.appSettings(for: app), host: self, makeContent: makeContent
        )
        controller.chrome.onFrameCommit = { [weak self] in self?.windowFrameCommitted(id: id, frame: $0) }
        windowControllers[id] = controller
        addChild(controller.contentViewController)
        windowLayer.open(id: id, chrome: controller.chrome, frame: initialFrame(kind: kind, app: app))
        controller.chrome.needsLayout = true
    }

    private func initialFrame(kind: DesktopAppWindowController.Kind, app: DesktopApp) -> CGRect {
        let container = windowLayer.bounds.size
        let descriptor = app.descriptor
        let minimum = descriptor.minimumWindowSize
        if kind == .app, let saved = settings.windowFrames[descriptor.identifier] {
            return DesktopWindowChromeView.clamped(saved, in: container, minimum: minimum)
        }
        let size = kind == .app ? descriptor.defaultWindowSize : Self.panelSize(for: kind)
        let cascade = CGFloat(windowLayer.identifiers.count) * Self.cascadeStep
        let origin = CGPoint(
            x: (container.width - size.width) / 2 + cascade,
            y: (container.height - size.height) / 2 + cascade
        )
        return DesktopWindowChromeView.clamped(CGRect(origin: origin, size: size), in: container, minimum: minimum)
    }

    private static let cascadeStep: CGFloat = 24

    private static func panelSize(for kind: DesktopAppWindowController.Kind) -> CGSize {
        kind == .about ? CGSize(width: 360, height: 430) : CGSize(width: 440, height: 300)
    }

    // MARK: Test seams

    var selectedAppIdentifier: String? {
        settings.iconArrangement == .list ? listView.selectedIdentifier : gridView.selectedIdentifier
    }

    var currentBackgroundImage: NSImage? { backgroundView.image }
    var iconOrigins: [String: CGPoint] { gridView.iconOrigins }

    // MARK: Settings

    private func settingsChanged() {
        let keep = settings.keepArranged
        if lastKeepArranged, !keep {
            // Freeze the arranged positions before the layout switches to free mode.
            lastKeepArranged = keep
            let origins = DesktopIconLayout(
                metrics: Self.metrics(for: settings.iconArrangement),
                containerSize: view.bounds.size
            ).arrangedOrigins(for: registry.apps.sortedByName.map { $0.descriptor.identifier })
            if origins != settings.iconPositions { settings.iconPositions = origins }
        }
        lastKeepArranged = keep
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
        let hex = settings.backgroundColorHex
        let path = settings.backgroundImagePath
        if appliedBackground?.hex != hex || appliedBackground?.path != path {
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

    /// Loads the photo once per path. A missing or unreadable file is nil, never an error.
    private func backgroundImage(for path: String?) -> NSImage? {
        guard let path else {
            cachedImagePath = nil
            cachedImage = nil
            return nil
        }
        if path != cachedImagePath {
            cachedImagePath = path
            cachedImage = FileManager.default.isReadableFile(atPath: path) ? NSImage(contentsOfFile: path) : nil
        }
        return cachedImage
    }

    private func iconMoved(identifier: String, to origin: CGPoint) {
        var positions = settings.iconPositions
        guard positions[identifier] != origin else { return }
        positions[identifier] = origin
        settings.iconPositions = positions
    }
}

extension DesktopViewController: DesktopWindowHost {
    func closeWindow(id: String) {
        guard let controller = windowControllers.removeValue(forKey: id) else { return }
        if controller.kind == .app { controller.app.appWillClose(context: controller) }
        controller.contentViewController.view.removeFromSuperview()
        controller.contentViewController.removeFromParent()
        windowLayer.close(id)
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
