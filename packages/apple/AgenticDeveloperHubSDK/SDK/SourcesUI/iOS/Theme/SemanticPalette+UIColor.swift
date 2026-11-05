import UIKit
import AgenticDeveloperHubSDK

/// UIKit accessors for a `SemanticPalette` — the iOS twin of
/// `SemanticPalette+NSColor.swift`, mirrored role-for-role so a shared
/// consumer sees the same shape on both platforms.
extension SemanticPalette {

    /// The `UIColor` for `role`, in the sRGB color space.
    public func uiColor(_ role: ThemeRole) -> UIColor {
        UIColor(color(role))
    }

    public var windowBackgroundColor: UIColor { uiColor(.windowBackground) }
    public var surfaceColor: UIColor { uiColor(.surface) }
    public var elevatedSurfaceColor: UIColor { uiColor(.elevatedSurface) }
    public var controlBackgroundColor: UIColor { uiColor(.controlBackground) }
    public var primaryTextColor: UIColor { uiColor(.primaryText) }
    public var secondaryTextColor: UIColor { uiColor(.secondaryText) }
    public var tertiaryTextColor: UIColor { uiColor(.tertiaryText) }
    public var placeholderTextColor: UIColor { uiColor(.placeholderText) }
    public var onAccentTextColor: UIColor { uiColor(.onAccentText) }
    public var accentColor: UIColor { uiColor(.accent) }
    public var successColor: UIColor { uiColor(.success) }
    public var warningColor: UIColor { uiColor(.warning) }
    public var dangerColor: UIColor { uiColor(.danger) }
    public var infoColor: UIColor { uiColor(.info) }
    public var borderColor: UIColor { uiColor(.border) }
    public var outlineColor: UIColor { uiColor(.outline) }
    public var dividerColor: UIColor { uiColor(.divider) }
    public var selectionColor: UIColor { uiColor(.selection) }
    public var selectionTextColor: UIColor { uiColor(.selectionText) }
    public var cursorColor: UIColor { uiColor(.cursor) }

    /// The 16 ANSI colors as `UIColor`s (for chart series, terminal previews, etc.).
    public var ansiColors: [UIColor] {
        theme.ansi.map { UIColor($0) }
    }

    /// Maps a server-supplied color *name* onto a themed semantic color.
    /// Mirrors `SemanticPalette.color(named:)` on macOS exactly.
    public func color(named name: String?) -> UIColor? {
        switch name {
        case "red":               return dangerColor
        case "yellow":            return warningColor
        case "green":             return successColor
        case "orange":            return warningColor
        case "blue":              return accentColor
        case "purple":            return infoColor
        case "gray", "secondary": return secondaryTextColor
        default:                  return nil
        }
    }
}

/// A same-module-only `RGBAColor`→`UIColor` bridge, mirroring the `NSColor`
/// one in `SemanticPalette+NSColor.swift`.
extension UIColor {
    convenience init(_ rgba: RGBAColor) {
        self.init(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
    }
}
