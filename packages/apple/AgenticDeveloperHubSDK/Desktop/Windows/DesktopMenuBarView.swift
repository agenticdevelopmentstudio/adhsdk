import AppKit

/// A horizontal strip of menu titles; clicking one pops its menu up underneath.
final class DesktopMenuBarView: NSView {
    static let height: CGFloat = 24
    private static let titlePadding: CGFloat = 10

    private(set) var menus: [NSMenu] = []
    /// How a menu is shown; tests replace it, since tracking a real menu blocks.
    var popUp: (NSMenu, NSPoint, NSView) -> Void = { menu, point, view in
        menu.popUp(positioning: nil, at: point, in: view)
    }
    private var buttons: [MenuTitleView] = []

    override var isFlipped: Bool { true }

    func configure(menus: [NSMenu]) {
        self.menus = menus
        buttons.forEach { $0.removeFromSuperview() }
        buttons = menus.enumerated().map { index, menu in
            let button = MenuTitleView(
                title: menu.title,
                font: index == 0 ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
            )
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
            // From the title's own text width, so repeated layout passes never accumulate.
            let width = button.textWidth + Self.titlePadding
            button.frame = CGRect(x: offset, y: 0, width: width, height: bounds.height)
            offset += width
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
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
}

/// One menu title. It acts on mouse-down, as a macOS menu bar does.
private final class MenuTitleView: NSView {
    var onPress: (() -> Void)?
    private let text: NSAttributedString

    /// The rendered title's width; the menu bar lays the title out from this.
    let textWidth: CGFloat

    init(title: String, font: NSFont) {
        text = NSAttributedString(string: title, attributes: [
            .font: font, .foregroundColor: NSColor.labelColor
        ])
        let size = text.size()
        textWidth = ceil(size.width)
        super.init(frame: NSRect(x: 0, y: 0, width: textWidth, height: ceil(size.height)))
        setAccessibilityElement(true)
        setAccessibilityRole(.menuBarItem)
        setAccessibilityLabel(title)
    }

    override func accessibilityPerformPress() -> Bool {
        onPress?()
        return true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let size = text.size()
        text.draw(at: CGPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
    }

    override func mouseDown(with event: NSEvent) {
        onPress?()
    }
}
