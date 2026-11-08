import AppKit
import AgenticDeveloperHubSDKCoreUI

/// Draws a Desktop App's icon at a requested size.
@MainActor
public enum DesktopAppIconRenderer {
    private static let cornerRadiusFraction: CGFloat = 0.225
    private static let symbolFraction: CGFloat = 0.6

    public static func image(for app: DesktopApp, pointSize: CGFloat) -> NSImage {
        switch app.descriptor.icon {
        case let .symbol(name, tint):
            return symbolImage(name: name, tint: tint, pointSize: pointSize)
        case let .resource(name):
            let image = app.resourceBundle.image(forResource: NSImage.Name(name))
                ?? NSImage(named: NSImage.applicationIconName)
                ?? NSImage(size: NSSize(width: pointSize, height: pointSize))
            // Copy so resizing never mutates a shared cached image.
            let sized = (image.copy() as? NSImage) ?? image
            sized.size = NSSize(width: pointSize, height: pointSize)
            return sized
        }
    }

    private static func symbolImage(name: String, tint: String, pointSize: CGFloat) -> NSImage {
        let size = NSSize(width: pointSize, height: pointSize)
        let fill = NSColor(desktopHex: tint) ?? .systemBlue
        let symbol = NSImage.symbol(named: name, accessibilityDescription: nil)
        return NSImage(size: size, flipped: false) { rect in
            fill.setFill()
            NSBezierPath(
                roundedRect: rect,
                xRadius: pointSize * cornerRadiusFraction,
                yRadius: pointSize * cornerRadiusFraction
            ).fill()
            let configured = symbol.withSymbolConfiguration(
                NSImage.SymbolConfiguration(pointSize: pointSize * symbolFraction, weight: .regular)
            ) ?? symbol
            let tinted = configured.tinted(.white)
            let glyph = tinted.size
            guard glyph.width > 0, glyph.height > 0 else { return true }
            let scale = min(pointSize * symbolFraction / glyph.width, pointSize * symbolFraction / glyph.height, 1)
            let drawSize = NSSize(width: glyph.width * scale, height: glyph.height * scale)
            tinted.draw(in: NSRect(
                x: (rect.width - drawSize.width) / 2,
                y: (rect.height - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            ))
            return true
        }
    }
}

extension NSImage {
    /// A copy of a template image filled with `color`.
    fileprivate func tinted(_ color: NSColor) -> NSImage {
        let source = self
        return NSImage(size: source.size, flipped: false) { rect in
            source.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}

extension NSColor {
    /// Parses `#RRGGBB`; nil when malformed.
    convenience init?(desktopHex hex: String) {
        var text = hex.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        self.init(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
