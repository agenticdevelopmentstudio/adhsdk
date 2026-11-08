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
    /// Task 6 fills this layer with App windows.
    let windowLayer = NSView()
    private var subscription: AnyCancellable?
    private var lastKeepArranged: Bool
    private var cachedImagePath: String?
    private var cachedImage: NSImage?

    /// Internal seam until the window layer opens windows.
    var onOpenApp: ((String) -> Void)?

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
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
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

    public func openApp(identifier: String) {
        onOpenApp?(identifier)
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
            let origins = gridView.arrangedOrigins
            if origins != settings.iconPositions { settings.iconPositions = origins }
        }
        lastKeepArranged = keep
        apply()
    }

    private func apply() {
        guard isViewLoaded else { return }
        backgroundView.color = NSColor(desktopHex: settings.backgroundColorHex) ?? .windowBackgroundColor
        backgroundView.image = backgroundImage(for: settings.backgroundImagePath)
        let apps = registry.apps
        let arrangement = settings.iconArrangement
        let showList = arrangement == .list
        gridView.isHidden = showList
        listView.isHidden = !showList
        if showList {
            listView.configure(apps: apps)
        } else {
            gridView.configure(
                apps: apps,
                metrics: arrangement == .smallIcons ? .small : .large,
                keepArranged: settings.keepArranged,
                positions: settings.iconPositions
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
