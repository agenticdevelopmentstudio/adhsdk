import AppKit

/// A horizontal strip of menu titles; clicking one pops its menu up underneath.
final class DesktopMenuBarView: NSView {
    static let height: CGFloat = 24
    private static let titlePadding: CGFloat = 10

    private(set) var menus: [NSMenu] = []
    private var buttons: [NSButton] = []

    override var isFlipped: Bool { true }

    func configure(menus: [NSMenu]) {
        self.menus = menus
        buttons.forEach { $0.removeFromSuperview() }
        buttons = menus.enumerated().map { index, menu in
            let button = NSButton(title: menu.title, target: self, action: #selector(titleClicked(_:)))
            button.isBordered = false
            button.tag = index
            button.font = index == 0 ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
            button.sizeToFit()
            addSubview(button)
            return button
        }
        needsLayout = true
    }

    override func layout() {
        super.layout()
        var offset: CGFloat = 4
        for button in buttons {
            let width = button.frame.width + Self.titlePadding
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

    @objc private func titleClicked(_ sender: NSButton) {
        guard menus.indices.contains(sender.tag) else { return }
        menus[sender.tag].popUp(
            positioning: nil,
            at: NSPoint(x: sender.frame.minX, y: sender.frame.maxY),
            in: self
        )
    }
}
