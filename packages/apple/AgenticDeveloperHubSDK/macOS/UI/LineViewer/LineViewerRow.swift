import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage

/// A row's (or a run's) background role. The viewer turns each into a palette
/// colour: `added`/`removed` are `.success`/`.danger` at 0.18 alpha, `emphasis`
/// is the row's tone at 0.40, `header` is `.surface`, `filler` is hatched
/// `.surface`, and `none` draws nothing.
public enum LineViewerBackground: Sendable, Hashable {
    case none, added, removed, header, filler, emphasis
}

/// One styled stretch of a row: `range` in UTF-16 units within the row's text.
/// A nil `foreground` draws in the theme's primary text colour; a non-nil
/// `highlight` paints that role behind the run's glyphs.
public struct LineViewerRun: Sendable, Hashable {
    public let range: NSRange
    public let foreground: RGBAColor?
    public let fontStyle: SyntaxFontStyle
    public let highlight: LineViewerBackground?

    public init(range: NSRange, foreground: RGBAColor? = nil, fontStyle: SyntaxFontStyle = [],
                highlight: LineViewerBackground? = nil) {
        self.range = range
        self.foreground = foreground
        self.fontStyle = fontStyle
        self.highlight = highlight
    }

    /// `RGBAColor` is `Equatable` but not `Hashable`; its hex form is its identity.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(range)
        hasher.combine(foreground?.hexString)
        hasher.combine(fontStyle)
        hasher.combine(highlight)
    }
}

/// One row of a `LineViewerViewController`: a text line or a header, its runs,
/// its background role and one optional string per gutter column.
public struct LineViewerRow: Sendable, Hashable {
    public enum Kind: Sendable, Hashable { case text, header }

    public let kind: Kind
    public let text: String
    public let runs: [LineViewerRun]
    public let background: LineViewerBackground
    /// One value per gutter column; a missing or nil entry draws nothing.
    public let gutter: [String?]

    public init(kind: Kind = .text, text: String, runs: [LineViewerRun] = [],
                background: LineViewerBackground = .none, gutter: [String?] = []) {
        self.kind = kind
        self.text = text
        self.runs = runs
        self.background = background
        self.gutter = gutter
    }
}
