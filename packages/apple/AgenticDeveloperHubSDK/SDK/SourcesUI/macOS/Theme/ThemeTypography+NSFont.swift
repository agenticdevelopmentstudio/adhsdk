import AppKit
import AgenticDeveloperHubSDK

/// AppKit bridge for the Foundation-only typography model. Lives in
/// `AgenticDeveloperHubSDKUI` so the Foundation-only `AgenticDeveloperHubSDK`
/// module stays AppKit-free.
extension FontWeight {
    /// The matching `NSFont.Weight`.
    public var nsWeight: NSFont.Weight {
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
    /// Bold on `NSFontManager`'s own 0–15 weight scale, where 5 is book weight
    /// and 9 is bold. It is not `NSFont.Weight`, which is a `-1...1` float, and
    /// the two are not interchangeable at the family-lookup call.
    private static let appKitBoldWeight = 9

    /// Resolve to an `NSFont` at `scaledSize` (the size *after* the theme's global
    /// scale has been applied). A custom `family` is used when installed (falling
    /// back to the system font otherwise), monospaced roles use the system
    /// monospaced face, and everything else uses the system face at `weight`.
    public func nsFont(scaledSize: CGFloat) -> NSFont {
        // Before the lookup, never after: a theme's family is only "installed"
        // for VT323 and friends because the toolkit registers its own copy.
        ToolkitFonts.registerBundledFonts()
        if let family, let base = NSFont(name: family, size: scaledSize) {
            // Best-effort weight for arbitrary families: apply a bold trait for
            // semibold-and-heavier (AppKit can't dial arbitrary weights on a
            // named family the way it can for the system font).
            //
            // Asked through `font(withFamily:traits:weight:size:)` rather than
            // `convert(_:toHaveTrait:)`, because the two answer "this family has
            // no bold face" differently. `convert` is declared returning a
            // non-optional `NSFont` and returns nil anyway — a nil that no Swift
            // check can see, since binding it to an `NSFont?` wraps it as
            // `.some(nil)` and every `??` after that takes the left-hand side.
            // It then travels as a real font until it reaches a text-attributes
            // dictionary, where CoreText raises `attempt to insert nil object`
            // and takes the process with it. This spelling returns a true
            // `NSFont?`, so the miss is visible here and the base face stands in.
            if weight.nsWeight.rawValue >= NSFont.Weight.semibold.rawValue {
                return NSFontManager.shared.font(
                    withFamily: base.familyName ?? family,
                    traits: .boldFontMask,
                    weight: Self.appKitBoldWeight,
                    size: scaledSize
                ) ?? base
            }
            return base
        }
        if monospaced {
            return NSFont.monospacedSystemFont(ofSize: scaledSize, weight: weight.nsWeight)
        }
        return NSFont.systemFont(ofSize: scaledSize, weight: weight.nsWeight)
    }
}

extension SemanticPalette {
    /// The resolved `NSFont` for a `TextRole` (family / size×scale / weight /
    /// monospaced), per the theme's typography.
    public func font(_ role: TextRole) -> NSFont {
        theme.typography.style(role).nsFont(scaledSize: CGFloat(size(role)))
    }

    /// `font(_:)` re-weighted. For text that needs its own emphasis *within* a
    /// role — an all-caps eyebrow, a bolded pane title — without inventing a
    /// point size the theme doesn't own: the family, size and scale still come
    /// from the role, only the weight is the call site's.
    public func font(_ role: TextRole, weight: FontWeight) -> NSFont {
        var style = theme.typography.style(role)
        style.weight = weight
        return style.nsFont(scaledSize: CGFloat(size(role)))
    }
}
