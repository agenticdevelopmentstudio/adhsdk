import AppKit
import Combine

import AgenticToolkitCore
import AgenticToolkitCoreMacOS

/// Arrange mode for one pane: the scrim and toolbar over it while the window is
/// arranging, and the keys that drive it — arrows move the selected pane;
/// Return, Enter and Escape leave the mode.
///
/// Any pane on a `ComposableTabsPaneBackgroundView` uses this, whatever holds
/// it: a project window's tree and the Coding Partner's two fixed panes ask
/// different questions about what a pane may do, and answer them through the
/// closures here, while the mode, the overlay and the keys are one thing
/// (`dry`).
@MainActor
final class PaneArrangeOverlayController {

    typealias Direction = ComposableTabsViewController.Direction

    /// The pane's view, which the overlay covers inside its border.
    private weak var paneView: NSView?
    /// The layout node naming this pane to the active-pane tracker; only the
    /// selected pane moves on an arrow key.
    private let nodeID: UUID

    var paneName: () -> String = { "" }
    var canAdd: () -> Bool = { false }
    var canRemove: () -> Bool = { false }
    var availableDirections: () -> Set<Direction> = { [] }
    /// See `ComposableTabsArrangeOverlayView.offersAddRemove`.
    var offersAddRemove = true
    var onAdd: () -> Void = {}
    var onRemove: () -> Void = {}
    var onMove: (Direction) -> Void = { _ in }

    private(set) var overlay: ComposableTabsArrangeOverlayView?
    private var keyMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    init(nodeID: UUID) {
        self.nodeID = nodeID
    }

    /// Starts following the mode for `view`'s window. Call from `viewDidLoad`.
    func attach(to view: NSView) {
        paneView = view
        NotificationCenter.default.publisher(for: ComposableTabsArrangeMode.didChangeNotification)
            .sink { [weak self] notification in
                guard let self, let window = notification.object as? NSWindow,
                      window === self.paneView?.window else { return }
                self.update()
            }
            .store(in: &cancellables)

        // Any pane moving changes what every *other* pane may do, so
        // availability is refreshed from the tree, not from the pane that acted.
        NotificationCenter.default.publisher(for: ComposableTabsViewController.layoutDidChangeNotification)
            .sink { [weak self] _ in self?.refreshAvailability() }
            .store(in: &cancellables)

        // A closing window takes its panes with it without ever leaving arrange
        // mode, and a `deinit` cannot touch the monitor — it is nonisolated.
        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)
            .sink { [weak self] notification in
                guard let self, let window = notification.object as? NSWindow,
                      window === self.paneView?.window else { return }
                self.remove()
            }
            .store(in: &cancellables)
    }

    /// Installs or removes the overlay to match the mode. Also the re-entry
    /// point after a pane is re-hosted (`viewDidAppear`): it comes back with
    /// the scrim it left with.
    func update() {
        if ComposableTabsArrangeMode.shared.isEnabled(in: paneView?.window) {
            install()
        } else {
            remove()
        }
    }

    func refreshAvailability() {
        overlay?.refreshAvailability()
    }

    private func install() {
        guard let view = paneView else { return }
        guard overlay == nil else {
            overlay?.refreshAvailability()
            return
        }

        let overlay = ComposableTabsArrangeOverlayView(frame: view.bounds)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.paneName = paneName()
        overlay.offersAddRemove = offersAddRemove
        overlay.canAdd = { [weak self] in self?.canAdd() ?? false }
        overlay.canRemove = { [weak self] in self?.canRemove() ?? false }
        overlay.availableDirections = { [weak self] in self?.availableDirections() ?? [] }
        overlay.onAdd = { [weak self] in self?.onAdd() }
        overlay.onRemove = { [weak self] in self?.onRemove() }
        overlay.onMove = { [weak self] direction in self?.onMove(direction) }
        overlay.onDone = { [weak self] in
            guard let window = self?.paneView?.window else { return }
            ComposableTabsArrangeMode.shared.setEnabled(false, in: window)
        }

        // Above the content, inside the active-pane border.
        let inset = ComposableTabsPaneBackgroundView.borderInset
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: inset),
            view.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: inset),
            overlay.topAnchor.constraint(equalTo: view.topAnchor, constant: inset),
            view.bottomAnchor.constraint(equalTo: overlay.bottomAnchor, constant: inset)
        ])
        self.overlay = overlay
        overlay.refreshAvailability()
        installKeyMonitor()
    }

    func remove() {
        overlay?.removeFromSuperview()
        overlay = nil
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    /// While arranging, an arrow key moves the selected pane — the fastest way
    /// to push a pane where you want it is to keep pressing the direction.
    ///
    /// A local monitor rather than `keyDown`: the pane's content owns the first
    /// responder (a terminal, an editor), and it would eat the arrow long
    /// before the pane saw it.
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // Only the Bool crosses back out: `assumeIsolated` hands its result
            // across an isolation boundary, and NSEvent is not `Sendable`.
            let consumed = MainActor.assumeIsolated { self.handleKeyDown(event) }
            return consumed ? nil : event
        }
    }

    /// Return, Enter and Escape all mean "done arranging" — the mode is what
    /// they dismiss, and which of the three a person reaches for is a habit,
    /// not a distinction worth honouring.
    private static let exitKeyCodes: Set<UInt16> = [36, 76, 53]

    /// Whether the key was ours to act on, and was.
    private func handleKeyDown(_ event: NSEvent) -> Bool {
        guard let window = paneView?.window,
              // Not the pane's own window means a sheet is up, and Escape
              // there cancels the sheet rather than the mode behind it.
              event.window === window,
              ComposableTabsArrangeMode.shared.isEnabled(in: window) else { return false }

        if Self.exitKeyCodes.contains(event.keyCode) {
            // Every pane in the window has a monitor, so this runs more than
            // once; turning the mode off twice is a no-op.
            ComposableTabsArrangeMode.shared.setEnabled(false, in: window)
            return true
        }

        // One monitor per pane, but only the pane the user selected moves.
        guard ComposableTabsActivePane.shared.activeNodeID(in: window) == nodeID,
              let direction = Direction.allCases.first(where: { $0.arrowKeyCode == event.keyCode })
        else { return false }
        onMove(direction)
        return true
    }
}

/// The arrange-mode toggle in a window's title bar, tinted with the accent
/// while the mode is on. The mode can also be turned on from the Window menu,
/// so the tint follows the mode rather than the click.
@MainActor
public final class ArrangeModeTitlebarButton: NSObject {

    public let button: NSButton
    private weak var window: NSWindow?
    private var cancellable: AnyCancellable?

    /// - Parameter accessibilityID: the button's identifier, which names the
    ///   window it sits in.
    public init(accessibilityID: String) {
        button = WindowTitlebarAccessory.makeButton(
            symbolName: "rectangle.3.group",
            description: "Arrange Panes",
            toolTip: "Arrange panes",
            target: nil,
            action: nil
        )
        super.init()
        button.accessibilityID(accessibilityID)
        button.target = self
        button.action = #selector(toggle(_:))
    }

    /// Starts following the mode for `window`.
    public func attach(to window: NSWindow) {
        self.window = window
        cancellable = NotificationCenter.default.publisher(for: ComposableTabsArrangeMode.didChangeNotification)
            .sink { [weak self] notification in
                guard let self, let changed = notification.object as? NSWindow,
                      changed === self.window else { return }
                self.refresh()
            }
        refresh()
    }

    @objc private func toggle(_ sender: Any?) {
        guard let window else { return }
        ComposableTabsArrangeMode.shared.toggle(in: window)
    }

    public func refresh() {
        let enabled = ComposableTabsArrangeMode.shared.isEnabled(in: window)
        button.contentTintColor = enabled ? button.resolvedThemeScope.palette.nsColor(.accent) : nil
        button.state = enabled ? .on : .off
    }
}

/// The right-aligned buttons a project-style window carries in its integrated
/// title bar, and the title bar itself.
@MainActor
public enum WindowTitlebarAccessory {

    /// A 14pt symbol button sized for the title bar.
    public static func makeButton(
        symbolName: String,
        description: String,
        toolTip: String,
        target: AnyObject?,
        action: Selector?
    ) -> NSButton {
        let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: description)?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .regular))
        let button = NSButton(image: symbol ?? NSImage(), target: target, action: action)
        button.bezelStyle = .texturedRounded
        button.imagePosition = .imageOnly
        button.toolTip = toolTip
        button.frame = NSRect(x: 0, y: 0, width: 36, height: 24)
        return button
    }

    /// Adds `buttons`, right-aligned, to `window`'s title bar.
    @discardableResult
    public static func install(_ buttons: [NSView], in window: NSWindow) -> NSTitlebarAccessoryViewController {
        let stack = NSStackView(views: buttons)
        stack.orientation = .horizontal
        stack.spacing = 4
        stack.frame = NSRect(x: 0, y: 0, width: CGFloat(buttons.count) * 40, height: 24)

        let accessory = NSTitlebarAccessoryViewController()
        accessory.view = stack
        accessory.layoutAttribute = .right
        window.addTitlebarAccessoryViewController(accessory)
        return accessory
    }

    /// Settings' seamless title bar, as a project window wears it: a unified
    /// toolbar, no material of its own and no hairline under it, so the panes'
    /// backdrop runs straight up behind the traffic lights. The window needs
    /// `.fullSizeContentView` in its style mask for the backdrop to reach.
    public static func applyIntegratedTitlebar(to window: NSWindow) {
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor(ThemePaletteObserver.currentPalette.projectPaneBackdrop)
        // A window that is its own tab host: left `.automatic`, AppKit merges
        // a newly opened one into the front window as a native window tab.
        window.tabbingMode = .disallowed
    }
}
