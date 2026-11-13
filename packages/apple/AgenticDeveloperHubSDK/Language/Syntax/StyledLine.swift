import Foundation

import AgenticDeveloperHubSDKCore

/// A run's font style, the highlighter's bits.
public struct SyntaxFontStyle: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let italic = SyntaxFontStyle(rawValue: 1)
    public static let bold = SyntaxFontStyle(rawValue: 2)
    public static let underline = SyntaxFontStyle(rawValue: 4)
    public static let strikethrough = SyntaxFontStyle(rawValue: 8)
}

/// One coloured stretch of a line: `range` in UTF-16 units within the line.
public struct SyntaxRun: Sendable, Hashable {
    public let range: NSRange
    public let foreground: RGBAColor
    public let fontStyle: SyntaxFontStyle

    public init(range: NSRange, foreground: RGBAColor, fontStyle: SyntaxFontStyle) {
        self.range = range
        self.foreground = foreground
        self.fontStyle = fontStyle
    }

    /// `RGBAColor` is `Equatable` but not `Hashable`; its hex form is its identity.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(range)
        hasher.combine(foreground.hexString)
        hasher.combine(fontStyle)
    }

    /// Parses the only two forms the highlighter emits: uppercase `#RRGGBB`
    /// (opaque) and `#RRGGBBAA`.
    ///
    /// - Throws: `SyntaxHighlighterError.unexpectedColor` for anything else; a
    ///   colour the bundle should never produce is a broken invariant, not a
    ///   value to default.
    static func color(highlighterHex text: String) throws -> RGBAColor {
        let digits = text.utf8.dropFirst()
        guard text.utf8.first == UInt8(ascii: "#"),
              digits.count == 6 || digits.count == 8,
              digits.allSatisfy({ (0x30...0x39).contains($0) || (0x41...0x46).contains($0) }),
              let color = RGBAColor(hexString: digits.count == 6 ? text + "FF" : text) else {
            throw SyntaxHighlighterError.unexpectedColor(text)
        }
        return color
    }
}

/// One line's runs, in order. A line with no runs draws in the theme's foreground.
public struct StyledLine: Sendable, Hashable {
    public let runs: [SyntaxRun]

    public init(runs: [SyntaxRun]) {
        self.runs = runs
    }
}
