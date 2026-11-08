import AppKit

/// The Desktop's icon surface for the large and small icon modes. Flipped, so
/// icon origins share `DesktopIconLayout`'s top-left coordinates.
final class DesktopIconGridView: NSView {
    var onOpen: ((String) -> Void)?
    var onSelectionChanged: (() -> Void)?
    /// Called once per drag, with the clamped final origin.
    var onMoveIcon: ((String, CGPoint) -> Void)?

    private(set) var selectedIdentifier: String?
    private var apps: [DesktopApp] = []
    private var iconViews: [String: DesktopIconView] = [:]
    private var metrics: DesktopIconLayout.Metrics = .large
    private var keepArranged = true
    private var savedPositions: [String: CGPoint] = [:]
    private var dragging: (id: String, grabOffset: CGSize)?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    /// Origins of the current icon frames, by App identifier.
    var iconOrigins: [String: CGPoint] {
        iconViews.mapValues { $0.frame.origin }
    }

    /// Where icons would sit if arranged right now.
    var arrangedOrigins: [String: CGPoint] {
        layoutEngine.arrangedOrigins(for: sortedIdentifiers)
    }

    private var layoutEngine: DesktopIconLayout {
        DesktopIconLayout(metrics: metrics, containerSize: bounds.size)
    }

    private var sortedIdentifiers: [String] {
        apps.sorted {
            $0.descriptor.displayName.localizedCaseInsensitiveCompare($1.descriptor.displayName) == .orderedAscending
        }.map { $0.descriptor.identifier }
    }

    func configure(
        apps: [DesktopApp],
        metrics: DesktopIconLayout.Metrics,
        keepArranged: Bool,
        positions: [String: CGPoint]
    ) {
        let appsChanged = apps.map { $0.descriptor.identifier } != self.apps.map { $0.descriptor.identifier }
        let metricsChanged = metrics.iconSize != self.metrics.iconSize
        self.apps = apps
        self.metrics = metrics
        self.keepArranged = keepArranged
        self.savedPositions = positions
        if appsChanged || metricsChanged { rebuildIconViews() }
        needsLayout = true
    }

    private func rebuildIconViews() {
        iconViews.values.forEach { $0.removeFromSuperview() }
        iconViews = [:]
        for app in apps {
            let view = DesktopIconView(app: app, metrics: metrics)
            iconViews[app.descriptor.identifier] = view
            addSubview(view)
        }
        if let selectedIdentifier, iconViews[selectedIdentifier] == nil {
            self.selectedIdentifier = nil
        }
        updateSelection()
    }

    override func layout() {
        super.layout()
        let ids = sortedIdentifiers
        let origins = keepArranged
            ? layoutEngine.arrangedOrigins(for: ids)
            : layoutEngine.freeOrigins(for: ids, saved: savedPositions)
        for (id, view) in iconViews where dragging?.id != id {
            if let origin = origins[id] {
                view.frame = NSRect(origin: origin, size: metrics.cellSize)
            }
        }
    }

    func select(_ identifier: String?) {
        guard identifier != selectedIdentifier else { return }
        selectedIdentifier = identifier
        updateSelection()
        onSelectionChanged?()
    }

    private func updateSelection() {
        for (id, view) in iconViews { view.isSelected = id == selectedIdentifier }
    }

    private func identifier(at point: CGPoint) -> String? {
        // Later subviews draw on top, so test from the end.
        subviews.reversed().compactMap { $0 as? DesktopIconView }.first { $0.frame.contains(point) }?.appIdentifier
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        guard let id = identifier(at: point) else {
            select(nil)
            return
        }
        select(id)
        if event.clickCount >= 2 {
            onOpen?(id)
            return
        }
        if !keepArranged, let view = iconViews[id] {
            dragging = (id, CGSize(width: point.x - view.frame.origin.x, height: point.y - view.frame.origin.y))
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragging, let view = iconViews[dragging.id] else { return }
        let point = convert(event.locationInWindow, from: nil)
        view.frame.origin = layoutEngine.clamp(CGPoint(
            x: point.x - dragging.grabOffset.width,
            y: point.y - dragging.grabOffset.height
        ))
    }

    override func mouseUp(with event: NSEvent) {
        guard let finished = dragging else { return }
        dragging = nil
        guard let view = iconViews[finished.id] else { return }
        onMoveIcon?(finished.id, view.frame.origin)
    }

    override func keyDown(with event: NSEvent) {
        let isReturn = event.keyCode == 36 || event.keyCode == 76
        if isReturn, let selectedIdentifier {
            onOpen?(selectedIdentifier)
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: Test seams

    func simulateDrag(of identifier: String, to origin: CGPoint) {
        guard !keepArranged, let view = iconViews[identifier] else { return }
        view.frame.origin = layoutEngine.clamp(origin)
        onMoveIcon?(identifier, view.frame.origin)
    }
}
