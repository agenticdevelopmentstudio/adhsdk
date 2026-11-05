import AppKit
import AgenticDeveloperHubSDK

/// The macOS half of the `PlatformColor`/`PlatformFont` seam: thin forwarders
/// onto the existing `nsColor(_:)`/`font(_:)` accessors, so shared code (like
/// `MarkdownRenderer`, moved here from `SourcesUI/macOS` in Task 8b) can read
/// a palette without ever writing `#if os(macOS)`. Deliberately a separate
/// file from `SemanticPalette+NSColor.swift`/`ThemeTypography+NSFont.swift`:
/// those accessors are untouched, per Task 8b's amendment — nothing here
/// renames or changes them, only adds alongside.
extension SemanticPalette {
    public func platformColor(_ role: ThemeRole) -> PlatformColor { nsColor(role) }
    public func platformFont(_ role: TextRole) -> PlatformFont { font(role) }
}

extension PlatformFont {
    /// Applies bold and/or italic to this font, mirroring
    /// `MarkdownRenderer`'s old inline `NSFontManager.convert(_:toHaveTrait:)`
    /// call exactly: neither flag set is a no-op (returns `self` unchanged,
    /// not a "convert to no traits" font), matching the original's
    /// `if !traits.isEmpty` guard.
    public func applying(bold: Bool, italic: Bool) -> PlatformFont {
        var traits: NSFontTraitMask = []
        if bold { traits.insert(.boldFontMask) }
        if italic { traits.insert(.italicFontMask) }
        guard !traits.isEmpty else { return self }
        return NSFontManager.shared.convert(self, toHaveTrait: traits)
    }
}
