import AppKit

/// One icon tile and its label. Passive: the grid view handles all mouse input.
final class DesktopIconView: NSView {
    let appIdentifier: String
    private let imageView = NSImageView()
    private let label = NSTextField(labelWithString: "")
    private let metrics: DesktopIconLayout.Metrics

    var isSelected = false {
        didSet {
            guard isSelected != oldValue else { return }
            updateSelectionAppearance()
        }
    }

    init(app: DesktopApp, metrics: DesktopIconLayout.Metrics) {
        self.appIdentifier = app.descriptor.identifier
        self.metrics = metrics
        super.init(frame: NSRect(origin: .zero, size: metrics.cellSize))
        wantsLayer = true
        layer?.cornerRadius = 6
        imageView.image = DesktopAppIconRenderer.image(for: app, pointSize: metrics.iconSize)
        imageView.imageScaling = .scaleProportionallyDown
        label.stringValue = app.descriptor.displayName
        label.alignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 2
        label.font = .systemFont(ofSize: 11)
        label.textColor = .white
        label.drawsBackground = false
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.8)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2
        label.shadow = shadow
        label.cell?.truncatesLastVisibleLine = true
        addSubview(imageView)
        addSubview(label)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(app.descriptor.displayName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    override func layout() {
        super.layout()
        let size = metrics.iconSize
        imageView.frame = NSRect(x: (bounds.width - size) / 2, y: 4, width: size, height: size)
        let labelTop = 4 + size + 2
        label.frame = NSRect(
            x: 2,
            y: labelTop,
            width: bounds.width - 4,
            height: max(0, bounds.height - labelTop)
        )
    }

    private func updateSelectionAppearance() {
        layer?.backgroundColor = isSelected
            ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.55).cgColor
            : nil
    }
}
