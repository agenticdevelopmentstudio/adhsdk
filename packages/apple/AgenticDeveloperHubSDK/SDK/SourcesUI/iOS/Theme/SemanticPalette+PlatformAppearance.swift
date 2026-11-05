import UIKit
import AgenticDeveloperHubSDK

/// The iOS half of the `PlatformColor`/`PlatformFont` seam: thin forwarders
/// onto `uiColor(_:)`/`font(_:)`, mirroring
/// `SemanticPalette+PlatformAppearance.swift` on macOS so shared code (like
/// `MarkdownRenderer`) never writes `#if os(macOS)`.
extension SemanticPalette {
    public func platformColor(_ role: ThemeRole) -> PlatformColor { uiColor(role) }
    public func platformFont(_ role: TextRole) -> PlatformFont { font(role) }
}

extension PlatformFont {
    /// Applies bold and/or italic to this font via `UIFontDescriptor`,
    /// mirroring the macOS `NSFontManager` version: neither flag set is a
    /// no-op.
    public func applying(bold: Bool, italic: Bool) -> PlatformFont {
        var traits: UIFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        guard !traits.isEmpty else { return self }
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
