import Foundation

extension RGBAColor {
    /// WCAG relative luminance in sRGB (0 = black, 1 = white). Used to classify
    /// a theme as dark/light and to derive readable secondary/tertiary tones.
    public var relativeLuminance: Double {
        func linear(_ component: Double) -> Double {
            component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// True when the color is dark enough to host light text on top.
    public var isDark: Bool { relativeLuminance < 0.5 }

    /// `"#rrggbb"` (lowercase, no alpha). Matches the terminal palette's color
    /// string format, so `ColorTheme` can project onto `TerminalSessionColorPalette`.
    public var hexStringRGB: String {
        func byte(_ value: Double) -> Int { Int((Swift.min(1, Swift.max(0, value)) * 255).rounded()) }
        return String(format: "#%02x%02x%02x", byte(red), byte(green), byte(blue))
    }

    /// Linear blend from `self` toward `other` by `fraction` (clamped 0…1).
    /// `fraction == 0` returns `self`; `fraction == 1` returns `other`. Alpha is
    /// blended too. Used to derive surface/secondary-text tones from the palette.
    public func blended(withFraction fraction: Double, of other: RGBAColor) -> RGBAColor {
        let amount = Swift.min(1, Swift.max(0, fraction))
        let inverse = 1 - amount
        return RGBAColor(
            red: red * inverse + other.red * amount,
            green: green * inverse + other.green * amount,
            blue: blue * inverse + other.blue * amount,
            alpha: alpha * inverse + other.alpha * amount
        )
    }

    /// Source-over composite of `self` onto `backdrop`. A translucent colour has
    /// no meaningful luminance or contrast on its own — it has one only against
    /// the thing behind it, so resolve it here before measuring.
    public func composited(over backdrop: RGBAColor) -> RGBAColor {
        let outAlpha = alpha + backdrop.alpha * (1 - alpha)
        guard outAlpha > 0 else { return RGBAColor(red: 0, green: 0, blue: 0, alpha: 0) }
        func channel(_ source: Double, _ under: Double) -> Double {
            (source * alpha + under * backdrop.alpha * (1 - alpha)) / outAlpha
        }
        return RGBAColor(
            red: channel(red, backdrop.red),
            green: channel(green, backdrop.green),
            blue: channel(blue, backdrop.blue),
            alpha: outAlpha
        )
    }

    /// WCAG contrast ratio between two colors (1 = identical … 21 = black/white).
    /// Symmetric. Used to keep derived text legible against its backdrop.
    ///
    /// Assumes both operands are opaque. A translucent operand's channel values
    /// alone don't determine what a viewer sees — composite it over its real
    /// backdrop with `composited(over:)` first, then compare the result.
    public func contrastRatio(against other: RGBAColor) -> Double {
        let lighter = Swift.max(relativeLuminance, other.relativeLuminance)
        let darker = Swift.min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Opaque black or white — whichever reads better on top of `self`.
    public func bestTextColor(black: RGBAColor = .opaqueBlack, white: RGBAColor = .opaqueWhite) -> RGBAColor {
        contrastRatio(against: white) >= contrastRatio(against: black) ? white : black
    }

    /// Blend `self` toward `background` by up to `fraction`, but stop short if
    /// the result would drop below `minContrast` against `background`. Lets
    /// secondary/tertiary text dim toward the backdrop while staying legible.
    public func dimmed(
        towards background: RGBAColor, by fraction: Double, minContrast: Double
    ) -> RGBAColor {
        var amount = Swift.min(1, Swift.max(0, fraction))
        while amount > 0 {
            let candidate = blended(withFraction: amount, of: background)
            if candidate.contrastRatio(against: background) >= minContrast { return candidate }
            amount -= 0.05
        }
        return self
    }

    /// Blend `self` toward the grey of the same apparent lightness. `amount`
    /// of 1 leaves a pure neutral; 0 leaves the color untouched.
    ///
    /// Rec. 601 luma over the *encoded* sRGB components rather than
    /// `relativeLuminance`, which is linear-light: feeding a linearized value
    /// back into a display-encoded channel would darken every color it
    /// touched. Luma keeps a bright phosphor green and its grey looking about
    /// equally bright, which is the whole point — the result has to read as
    /// the same ink with the color drained out of it, not as a dimmer one.
    public func desaturated(by amount: Double = 1) -> RGBAColor {
        let fraction = Swift.min(1, Swift.max(0, amount))
        let luma = 0.299 * red + 0.587 * green + 0.114 * blue
        return blended(
            withFraction: fraction,
            of: RGBAColor(red: luma, green: luma, blue: luma, alpha: alpha))
    }

    /// Opaque pure black / white constants for contrast picking.
    public static let opaqueBlack = RGBAColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let opaqueWhite = RGBAColor(red: 1, green: 1, blue: 1, alpha: 1)
}
