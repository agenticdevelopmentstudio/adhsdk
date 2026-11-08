import AppKit

/// The frame around an in-desktop window: title bar with traffic lights, drag by
/// the title bar, resize from the edges and corners, and a content area.
/// Flipped, so its geometry and its superview's share a top-left origin.
final class DesktopWindowChromeView: NSView {
    static let titleBarHeight: CGFloat = 28
    /// How much of the title bar must stay inside the Desktop.
    static let visibleTitleBarWidth: CGFloat = 40
    private static let resizeBand: CGFloat = 5
    private static let lightDiameter: CGFloat = 12
    private static let lightSpacing: CGFloat = 20
    private static let lightInset: CGFloat = 14

    struct Edges: OptionSet {
        let rawValue: Int
        static let left = Edges(rawValue: 1)
        static let right = Edges(rawValue: 2)
        static let top = Edges(rawValue: 4)
        static let bottom = Edges(rawValue: 8)
    }

    private enum Light: Int, CaseIterable {
        case close, minimize, zoom
    }

    private enum Interaction {
        case move(startFrame: CGRect, startMouse: CGPoint)
        case resize(Edges, startFrame: CGRect, startMouse: CGPoint)
        case light(Light)
    }

    let contentContainer = NSView()
    var minimumSize = CGSize(width: 200, height: 120)
    var onClose: (() -> Void)?
    var onActivate: (() -> Void)?
    /// Called on every frame change while moving or resizing.
    var onFrameChange: ((CGRect) -> Void)?
    /// Called once when a move, resize, or zoom ends with a different frame.
    var onFrameCommit: ((CGRect) -> Void)?

    var title = "" {
        didSet { needsDisplay = true }
    }
    var isActive = false {
        didSet { needsDisplay = true }
    }
    /// Height reserved under the title bar (the menu bar strip), 0 for none.
    var accessoryHeight: CGFloat = 0 {
        didSet { needsLayout = true }
    }
    /// The strip shown under the title bar, sized to `accessoryHeight`.
    var accessoryView: NSView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let accessoryView { addSubview(accessoryView) }
            needsLayout = true
        }
    }
    private var interaction: Interaction?
    private var restoreFrame: CGRect?

    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        addSubview(contentContainer)
        let press = NSPressGestureRecognizer(target: self, action: #selector(contentPressed(_:)))
        press.minimumPressDuration = 0
        press.allowableMovement = .greatestFiniteMagnitude
        addGestureRecognizer(press)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Geometry

    /// Pulls `frame` to at least `minimum` in size and keeps at least
    /// `visibleTitleBarWidth` of its title bar inside `container`.
    static func clamped(_ frame: CGRect, in container: CGSize, minimum: CGSize) -> CGRect {
        var result = frame
        result.size.width = max(frame.width, minimum.width)
        result.size.height = max(frame.height, minimum.height)
        let visible = min(visibleTitleBarWidth, result.width)
        result.origin.x = min(max(result.origin.x, visible - result.width), container.width - visible)
        result.origin.y = min(max(result.origin.y, 0), max(0, container.height - titleBarHeight))
        return result
    }

    private var titleBarRect: CGRect {
        CGRect(x: 0, y: 0, width: bounds.width, height: Self.titleBarHeight)
    }

    private func lightRect(_ light: Light) -> CGRect {
        let diameter = Self.lightDiameter
        return CGRect(
            x: Self.lightInset + CGFloat(light.rawValue) * Self.lightSpacing - diameter / 2,
            y: (Self.titleBarHeight - diameter) / 2,
            width: diameter,
            height: diameter
        )
    }

    func edges(at point: CGPoint) -> Edges {
        guard bounds.contains(point) else { return [] }
        var edges: Edges = []
        if point.x < Self.resizeBand { edges.insert(.left) }
        if point.x > bounds.width - Self.resizeBand { edges.insert(.right) }
        if point.y < Self.resizeBand { edges.insert(.top) }
        if point.y > bounds.height - Self.resizeBand { edges.insert(.bottom) }
        return edges
    }

    override func layout() {
        super.layout()
        let top = Self.titleBarHeight + accessoryHeight
        accessoryView?.frame = CGRect(
            x: 0, y: Self.titleBarHeight, width: bounds.width, height: accessoryHeight
        )
        contentContainer.frame = CGRect(x: 0, y: top, width: bounds.width, height: max(0, bounds.height - top))
        for subview in contentContainer.subviews {
            subview.frame = contentContainer.bounds
        }
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        (isActive ? NSColor.controlBackgroundColor : NSColor.windowBackgroundColor).setFill()
        titleBarRect.fill()
        NSColor.separatorColor.setFill()
        CGRect(x: 0, y: Self.titleBarHeight - 1, width: bounds.width, height: 1).fill()
        for light in Light.allCases {
            lightColor(light).setFill()
            NSBezierPath(ovalIn: lightRect(light)).fill()
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: isActive ? NSColor.labelColor : NSColor.secondaryLabelColor
        ]
        let text = NSAttributedString(string: title, attributes: attributes)
        let size = text.size()
        text.draw(at: CGPoint(x: (bounds.width - size.width) / 2, y: (Self.titleBarHeight - size.height) / 2))
        NSColor.separatorColor.setStroke()
        NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
    }

    private func lightColor(_ light: Light) -> NSColor {
        guard isActive else { return .quaternaryLabelColor }
        switch light {
        case .close: return .systemRed
        case .minimize: return .quaternaryLabelColor
        case .zoom: return .systemGreen
        }
    }

    // MARK: Mouse

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let superview else { return super.hitTest(point) }
        let local = convert(point, from: superview)
        guard bounds.contains(local) else { return nil }
        if !edges(at: local).isEmpty || titleBarRect.contains(local) { return self }
        return super.hitTest(point)
    }

    @objc private func contentPressed(_ recognizer: NSPressGestureRecognizer) {
        if recognizer.state == .began { onActivate?() }
    }

    private func superviewPoint(_ event: NSEvent) -> CGPoint {
        superview?.convert(event.locationInWindow, from: nil) ?? event.locationInWindow
    }

    private func light(at point: CGPoint) -> Light? {
        Light.allCases.first { lightRect($0).insetBy(dx: -2, dy: -2).contains(point) }
    }

    override func mouseDown(with event: NSEvent) {
        onActivate?()
        let point = convert(event.locationInWindow, from: nil)
        let edges = edges(at: point)
        if !edges.isEmpty {
            interaction = .resize(edges, startFrame: frame, startMouse: superviewPoint(event))
        } else if let light = light(at: point) {
            interaction = .light(light)
        } else if titleBarRect.contains(point) {
            interaction = .move(startFrame: frame, startMouse: superviewPoint(event))
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let mouse = superviewPoint(event)
        switch interaction {
        case let .move(start, startMouse):
            var moved = start
            moved.origin.x += mouse.x - startMouse.x
            moved.origin.y += mouse.y - startMouse.y
            setFrameClamped(moved)
        case let .resize(edges, start, startMouse):
            setFrameClamped(Self.resized(
                start, edges: edges, deltaX: mouse.x - startMouse.x, deltaY: mouse.y - startMouse.y,
                minimum: minimumSize
            ))
        case .light, .none:
            break
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer { interaction = nil }
        switch interaction {
        case let .move(start, _), let .resize(_, start, _):
            if frame != start { onFrameCommit?(frame) }
        case let .light(pressed):
            guard light(at: convert(event.locationInWindow, from: nil)) == pressed else { return }
            switch pressed {
            case .close: onClose?()
            case .minimize: break
            case .zoom: toggleZoom()
            }
        case .none:
            break
        }
    }

    static func resized(_ start: CGRect, edges: Edges, deltaX: CGFloat, deltaY: CGFloat, minimum: CGSize) -> CGRect {
        var result = start
        if edges.contains(.right) { result.size.width = max(minimum.width, start.width + deltaX) }
        if edges.contains(.left) {
            result.size.width = max(minimum.width, start.width - deltaX)
            result.origin.x = start.maxX - result.width
        }
        if edges.contains(.bottom) { result.size.height = max(minimum.height, start.height + deltaY) }
        if edges.contains(.top) {
            result.size.height = max(minimum.height, start.height - deltaY)
            result.origin.y = start.maxY - result.height
        }
        return result
    }

    private func setFrameClamped(_ proposed: CGRect) {
        let container = superview?.bounds.size ?? .zero
        let result = container == .zero ? proposed : Self.clamped(proposed, in: container, minimum: minimumSize)
        guard result != frame else { return }
        frame = result
        onFrameChange?(result)
    }

    /// Fills the Desktop, or restores the frame from before filling.
    func toggleZoom() {
        let before = frame
        if let restoreFrame {
            self.restoreFrame = nil
            setFrameClamped(restoreFrame)
        } else if let container = superview?.bounds {
            restoreFrame = frame
            setFrameClamped(container)
        }
        if frame != before { onFrameCommit?(frame) }
    }
}
