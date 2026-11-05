import UIKit
import AgenticDeveloperHubSDK

/// UIKit bridge for the Foundation-only typography model — the iOS twin of
/// `ThemeTypography+NSFont.swift`, mirrored role-for-role.
extension FontWeight {
    /// The matching `UIFont.Weight`.
    public var uiWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        case .black:      return .black
        }
    }
}

extension FontStyle {
    /// Resolve to a `UIFont` at `scaledSize`, mirroring `nsFont(scaledSize:)`
    /// exactly: a custom `family` is used when installed (falling back to the
    /// system font otherwise), monospaced roles use the system monospaced
    /// face, and everything else uses the system face at `weight`.
    public func uiFont(scaledSize: CGFloat) -> UIFont {
        // Mirrors the macOS bridge: register the bundled faces before asking
        // whether the theme's family exists.
        ToolkitFonts.registerBundledFonts()
        if let family, let base = UIFont(name: family, size: scaledSize) {
            // Best-effort weight for arbitrary families, mirroring the
            // NSFontManager bold-trait fallback on macOS: apply a bold trait
            // for semibold-and-heavier, since UIKit can't dial arbitrary
            // weights on a named family the way it can for the system font.
            if weight.uiWeight.rawValue >= UIFont.Weight.semibold.rawValue,
               let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) {
                return UIFont(descriptor: descriptor, size: scaledSize)
            }
            return base
        }
        if monospaced {
            return UIFont.monospacedSystemFont(ofSize: scaledSize, weight: weight.uiWeight)
        }
        return UIFont.systemFont(ofSize: scaledSize, weight: weight.uiWeight)
    }
}

extension SemanticPalette {
    /// The resolved `UIFont` for a `TextRole`, mirroring the macOS `font(_:)`
    /// accessor exactly.
    public func font(_ role: TextRole) -> UIFont {
        theme.typography.style(role).uiFont(scaledSize: CGFloat(size(role)))
    }
}

extension SemanticPalette {
    /// `font(_:)` re-weighted — the iOS twin of the macOS accessor of the same
    /// name. For text that needs its own emphasis *within* a role (an all-caps
    /// eyebrow, a bolded pane title) without inventing a point size the theme
    /// does not own: family, size and scale still come from the role; only the
    /// weight is the call site's.
    public func font(_ role: TextRole, weight: FontWeight) -> UIFont {
        var style = theme.typography.style(role)
        style.weight = weight
        return style.uiFont(scaledSize: CGFloat(size(role)))
    }
}
