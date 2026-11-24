import AppKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKNotifications

/// One toast stack — a position on a screen — in one window: its cards and
/// the "+N more" pill. The window is clear and non-opaque, so the gaps between
/// cards stay click-through, and it always reserves room for its chrome (a
/// margin and a title bar strip) so the chrome appearing never moves a card.
///
/// The chrome — an outline and a title bar — fades in while the pointer is in
/// the window. Dragging the bar moves the stack; the distance from the
/// position's anchor is saved per position, so it holds on every screen and
/// after a relaunch. A hover anywhere in the window holds every card's
/// countdown.
@MainActor
final class ToastStackWindow: NoticePanel {

    let position: NoticeProfile.Position
    let chrome: ToastStackChromeView

    /// Called after the saved offset for this window's position changed, so a
    /// presenter can lay out the position's other stacks to match.
    var onOffsetChange: (() -> Void)?

    private let store: SettingsStore
    private let content = ToastStackContentView()
    private(set) var views: [NSView] = []
    private(set) var anchoredFrame: CGRect = .zero
    private(set) var isChromeVisible = false
    private(set) var isHovered = false
    private var lastVisible: CGRect = .zero
    private var dragOrigin: NSPoint?
    private var dragMouse: NSPoint = .zero
    /// A layout that arrived mid-drag, applied when the drag ends so it never
    /// snaps the window out from under the pointer.
    private var pendingArrangement: (views: [NSView], visible: CGRect)?
    private var pendingHide: Task<Void, Never>?

    /// How long after the pointer leaves before the chrome starts to fade.
    var hideDelay: TimeInterval = 0.4

    /// Where the pointer is, in screen coordinates. A seam, so tests place it.
    var mouseLocation: () -> NSPoint = { NSEvent.mouseLocation }

    init(
        position: NoticeProfile.Position,
        layer: NoticeProfile.Layer,
        hideFromSharing: Bool,
        store: SettingsStore
    ) {
        self.position = position
        self.store = store
        chrome = ToastStackChromeView(position: position)
        super.init(layer: layer, hideFromSharing: hideFromSharing)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        contentView = content
        content.addSubview(chrome)
        chrome.frame = content.bounds
        chrome.autoresizingMask = [.width, .height]
        chrome.bar.onDragBegan = { [weak self] mouse in self?.beginDrag(at: mouse) }
        chrome.bar.onDragged = { [weak self] mouse in self?.drag(to: mouse) }
        chrome.bar.onDragEnded = { [weak self] in self?.finishDrag() }
        chrome.onReset = { [weak self] in self?.resetOffset() }
        content.onHoverChange = { [weak self] hovered in self?.setHovered(hovered) }
    }

    /// The saved offset for this window's position.
    private var savedOffset: NoticeStackOffset {
        store.get(NoticeSettings.toastStackOffsets)[position.rawValue] ?? .zero
    }

    /// Which level the window floats at: above other windows, or with them.
    func apply(layer: NoticeProfile.Layer) {
        isFloatingPanel = layer == .floating
        level = layer == .floating ? .statusBar : .normal
    }

    // MARK: Layout

    /// Puts `views` (newest first) in the window and sizes it to them,
    /// anchored at its position on `visible` and moved by the saved offset.
    func arrange(views: [NSView], visible: CGRect) {
        guard dragOrigin == nil else {
            pendingArrangement = (views, visible)
            return
        }
        pendingArrangement = nil
        for view in self.views where !views.contains(where: { $0 === view }) {
            view.removeFromSuperview()
        }
        self.views = views
        lastVisible = visible

        let sizes = views.map { view -> CGSize in
            view.translatesAutoresizingMaskIntoConstraints = true
            view.layoutSubtreeIfNeeded()
            return view.fittingSize
        }
        let spacing = ToastStackGeometry.cardSpacing
        let stackSize = CGSize(
            width: sizes.map(\.width).max() ?? 0,
            height: sizes.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, sizes.count - 1)))
        let size = ToastStackGeometry.windowFrame(
            stackSize: stackSize, position: position, visible: visible, offset: .zero)
        anchoredFrame = size
        let offset = savedOffset
        let frame = ToastStackGeometry.windowFrame(
            stackSize: stackSize, position: position, visible: visible, offset: offset)
        setFrame(frame, display: false)

        let area = ToastStackGeometry.cardArea(inWindowSize: frame.size, position: position)
            .offsetBy(dx: frame.minX, dy: frame.minY)
        let frames = ToastStackLayout.frames(
            sizes: sizes, in: area, position: position, spacing: spacing, margin: 0)
        for (view, cardFrame) in zip(views, frames) {
            if view.superview !== content {
                content.addSubview(view)
            }
            view.frame = cardFrame.offsetBy(dx: -frame.minX, dy: -frame.minY)
        }
        chrome.setResetAvailable(!ToastStackGeometry.offset(of: frame, from: anchoredFrame).isZero)
        applyHover()
        display()
        syncHover()
    }

    // MARK: Hover

    /// The pointer entered or left the window: the chrome comes at once and
    /// goes `hideDelay` later, and every card's countdown holds or carries on.
    func setHovered(_ hovered: Bool) {
        isHovered = hovered
        applyHover()
        pendingHide?.cancel()
        pendingHide = nil
        if hovered {
            setChromeVisible(true, animated: true)
        } else {
            let delay = hideDelay
            pendingHide = Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                self?.pendingHide = nil
                self?.setChromeVisible(false, animated: true)
            }
        }
    }

    /// A window that moved or resized under a still pointer gets no enter or
    /// exit event: compare the pointer with the frame instead.
    private func syncHover() {
        let inside = frame.contains(mouseLocation())
        if inside != isHovered {
            setHovered(inside)
        }
    }

    private func applyHover() {
        for case let card as NoticeCardView in views {
            card.setStackHovered(isHovered)
        }
    }

    func setChromeVisible(_ visible: Bool, animated: Bool = true) {
        // A direct call overrides a fade that was waiting its turn.
        pendingHide?.cancel()
        pendingHide = nil
        isChromeVisible = visible
        chrome.setVisible(visible, animated: animated)
    }

    // MARK: Drag

    private func beginDrag(at mouse: NSPoint) {
        dragOrigin = frame.origin
        dragMouse = mouse
    }

    private func drag(to mouse: NSPoint) {
        guard let dragOrigin else { return }
        var moved = frame
        moved.origin = NSPoint(x: dragOrigin.x + mouse.x - dragMouse.x, y: dragOrigin.y + mouse.y - dragMouse.y)
        setFrame(ToastStackGeometry.clamp(moved, to: lastVisible), display: true)
    }

    /// Saves where the stack now sits as an offset from its anchor.
    func finishDrag() {
        dragOrigin = nil
        let offset = ToastStackGeometry.offset(of: frame, from: anchoredFrame)
        var offsets = store.get(NoticeSettings.toastStackOffsets)
        offsets[position.rawValue] = offset.isZero ? nil : offset
        store.set(offsets, for: NoticeSettings.toastStackOffsets)
        chrome.setResetAvailable(!offset.isZero)
        if let pending = pendingArrangement {
            arrange(views: pending.views, visible: pending.visible)
        }
        syncHover()
        onOffsetChange?()
    }

    /// Puts the stack back at its anchor and forgets the offset.
    func resetOffset() {
        var offsets = store.get(NoticeSettings.toastStackOffsets)
        offsets[position.rawValue] = nil
        store.set(offsets, for: NoticeSettings.toastStackOffsets)
        arrange(views: views, visible: lastVisible)
        onOffsetChange?()
    }
}

/// The window's content: the cards, over the chrome, with a tracking area on
/// the whole window so a hover anywhere in it counts.
@MainActor
final class ToastStackContentView: NSView {

    var onHoverChange: ((Bool) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { onHoverChange?(true) }

    override func mouseExited(with event: NSEvent) { onHoverChange?(false) }

    /// Nothing here is the content view itself, so a click in a gap goes on to
    /// whatever is underneath.
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}

/// The outline and title bar, under the cards. Hidden until a hover, and
/// hit-testable only in the bar, so the margin never catches a click.
@MainActor
final class ToastStackChromeView: NSView {

    let bar = ToastStackBarView()
    let resetButton = NSButton()
    var onReset: (() -> Void)?

    private let position: NoticeProfile.Position
    private let border = ToastStackBorderView()
    private let barFill = ThemedBox(fill: .elevatedSurface, stroke: nil, cornerRadius: 9)
    private let caption = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    private var wantsVisible = false

    init(position: NoticeProfile.Position) {
        self.position = position
        super.init(frame: .zero)
        alphaValue = 0
        isHidden = true
        caption.stringValue = "Notifications"
        resetButton.image = NSImage(
            systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "Reset position")
        resetButton.imagePosition = .imageOnly
        resetButton.isBordered = false
        resetButton.toolTip = "Reset position"
        resetButton.setAccessibilityLabel("Reset position")
        resetButton.target = self
        resetButton.action = #selector(resetClicked)
        resetButton.isHidden = true
        addSubview(border)
        addSubview(bar)
        bar.addSubview(barFill)
        bar.addSubview(caption)
        bar.addSubview(resetButton)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        border.frame = bounds
        bar.frame = ToastStackGeometry.barArea(inWindowSize: bounds.size, position: position)
        barFill.frame = bar.bounds.insetBy(dx: 1, dy: 1)
        let captionSize = caption.fittingSize
        caption.frame = CGRect(
            x: 12, y: (bar.bounds.height - captionSize.height) / 2,
            width: max(0, bar.bounds.width - 48), height: captionSize.height)
        resetButton.frame = CGRect(x: bar.bounds.width - 28, y: (bar.bounds.height - 18) / 2, width: 18, height: 18)
    }

    func setResetAvailable(_ available: Bool) {
        resetButton.isHidden = !available
    }

    /// Fades over 0.15 s either way. Fully out, it stops drawing,
    /// so it stops receiving the mouse.
    func setVisible(_ visible: Bool, animated: Bool) {
        wantsVisible = visible
        if visible {
            isHidden = false
        }
        guard animated else {
            alphaValue = visible ? 1 : 0
            isHidden = !visible
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            animator().alphaValue = visible ? 1 : 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.wantsVisible else { return }
                self.isHidden = true
            }
        })
    }

    @objc private func resetClicked(_ sender: NSButton) { onReset?() }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, let hit = super.hitTest(point), hit.isDescendant(of: bar) else { return nil }
        return hit
    }
}

/// The title bar's strip: dragging it moves the stack.
@MainActor
final class ToastStackBarView: NSView {

    var onDragBegan: ((NSPoint) -> Void)?
    var onDragged: ((NSPoint) -> Void)?
    var onDragEnded: (() -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Where the event is on screen, from the bar's own window so the point
    /// stays right while that window moves under the drag.
    private func screenPoint(of event: NSEvent) -> NSPoint {
        window?.convertPoint(toScreen: event.locationInWindow) ?? NSEvent.mouseLocation
    }

    override func mouseDown(with event: NSEvent) { onDragBegan?(screenPoint(of: event)) }

    override func mouseDragged(with event: NSEvent) { onDragged?(screenPoint(of: event)) }

    override func mouseUp(with event: NSEvent) { onDragEnded?() }
}

/// The chrome's outline: a 1 pt `.outline` border with a 10 pt corner radius
/// and no fill, so nothing but the line itself is drawn, and it never takes
/// the mouse.
@MainActor
final class ToastStackBorderView: NSView, Themeable {

    private var observer: ThemePaletteObserver?

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        observer = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func applyTheme(_ palette: SemanticPalette) {
        layer?.borderColor = palette.nsColor(.outline).cgColor
    }

    /// A light/dark flip repaints the border even when no theme notification
    /// follows it.
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            applyTheme(resolvedThemeScope.palette)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
