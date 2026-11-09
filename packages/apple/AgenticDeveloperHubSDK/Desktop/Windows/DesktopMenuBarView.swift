import AppKit

/// A horizontal strip of menu titles; clicking one pops its menu up underneath.
/// An optional leading menu is titled by an SF Symbol, the way the Apple menu is.
final class DesktopMenuBarView: NSView {
    static let height: CGFloat = 24
    private static let titlePadding: CGFloat = 10
    private static let symbolPadding: CGFloat = 18

    /// Every menu shown, left to right, including a leading symbol menu.
    private(set) var menus: [NSMenu] = []
    /// What fills the bar behind the titles.
    var fillColor: NSColor = .windowBackgroundColor {
        didSet { needsDisplay = true }
    }
    /// How a menu is shown; tests replace it, since tracking a real menu blocks.
    var popUp: (NSMenu, NSPoint, NSView) -> Void = { menu, point, view in
        menu.popUp(positioning: nil, at: point, in: view)
    }
    private var buttons: [MenuTitleView] = []

    override var isFlipped: Bool { true }

    /// Shows `menus`, the first in bold. A `symbolMenu` comes before them, titled by its symbol.
    func configure(menus: [NSMenu], symbolMenu: (symbolName: String, menu: NSMenu)? = nil) {
        let leading = symbolMenu.map { [$0.menu] } ?? []
        self.menus = leading + menus
        buttons.forEach { $0.removeFromSuperview() }
        let boldIndex = leading.count
        buttons = self.menus.enumerated().map { index, menu in
            let button: MenuTitleView
            if let symbolMenu, index == 0 {
                button = MenuTitleView(symbolName: symbolMenu.symbolName, label: menu.title)
            } else {
                button = MenuTitleView(
                    title: menu.title,
                    font: index == boldIndex ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
                )
            }
            button.onPress = { [weak self] in self?.showMenu(at: index) }
            addSubview(button)
            return button
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        var offset: CGFloat = 4
        for button in buttons {
            // From the title's own content width, so repeated layout passes never accumulate.
            let width = button.contentWidth + (button.isSymbol ? Self.symbolPadding : Self.titlePadding)
            button.frame = CGRect(x: offset, y: 0, width: width, height: bounds.height)
            offset += width
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        fillColor.setFill()
        bounds.fill()
        NSColor.separatorColor.setFill()
        CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1).fill()
    }

    /// Pops the menu at `index` up under its title. Tracking runs until the menu closes, so a
    /// press-drag-release that began on the title selects an item.
    func showMenu(at index: Int) {
        guard menus.indices.contains(index), buttons.indices.contains(index) else { return }
        let title = buttons[index]
        popUp(menus[index], NSPoint(x: title.frame.minX, y: title.frame.maxY), self)
    }

    /// The title view of the menu at `index`, for tests.
    func titleView(at index: Int) -> NSView? {
        buttons.indices.contains(index) ? buttons[index] : nil
    }

    /// Whether the title at `index` is drawn as a symbol, for tests.
    func isSymbolTitle(at index: Int) -> Bool {
        buttons.indices.contains(index) && buttons[index].isSymbol
    }
}

/// One menu title, text or symbol. It acts on mouse-down, as a macOS menu bar does.
private final class MenuTitleView: NSView {
    var onPress: (() -> Void)?
    private let text: NSAttributedString?
    private let symbol: NSImage?

    /// The rendered title's width; the menu bar lays the title out from this.
    let contentWidth: CGFloat
    var isSymbol: Bool { symbol != nil }

    init(title: String, font: NSFont) {
        let text = NSAttributedString(string: title, attributes: [
            .font: font, .foregroundColor: NSColor.labelColor
        ])
        self.text = text
        symbol = nil
        let size = text.size()
        contentWidth = ceil(size.width)
        super.init(frame: NSRect(x: 0, y: 0, width: contentWidth, height: ceil(size.height)))
        configureAccessibility(label: title)
    }

    init(symbolName: String, label: String) {
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)
            ?? NSImage(size: NSSize(width: 14, height: 14))
        let configured = image.withSymbolConfiguration(.init(pointSize: 14, weight: .semibold)) ?? image
        symbol = configured
        text = nil
        contentWidth = ceil(configured.size.width)
        super.init(frame: NSRect(x: 0, y: 0, width: contentWidth, height: ceil(configured.size.height)))
        configureAccessibility(label: label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func configureAccessibility(label: String) {
        setAccessibilityElement(true)
        setAccessibilityRole(.menuBarItem)
        setAccessibilityLabel(label)
    }

    override func accessibilityPerformPress() -> Bool {
        onPress?()
        return true
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        if let text {
            let size = text.size()
            text.draw(at: CGPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
        } else if let symbol {
            let size = symbol.size
            let rect = CGRect(
                x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2,
                width: size.width, height: size.height
            )
            // The template symbol, tinted with the label color so it follows light and dark mode.
            symbol.tinted(.labelColor).draw(
                in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil
            )
        }
    }

    override func mouseDown(with event: NSEvent) {
        onPress?()
    }
}
