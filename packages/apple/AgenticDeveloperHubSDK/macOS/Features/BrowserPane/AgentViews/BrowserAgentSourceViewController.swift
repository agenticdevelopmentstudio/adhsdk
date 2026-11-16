//
//  BrowserAgentSourceViewController.swift
//  AgenticDeveloperHubSDK
//
//  Recipe: workspace/browser/agent-views (spec section 2.4).
//

import AgenticDeveloperHubSDKUI
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKCoreUI
import AppKit
import CodeEditSourceEditor

/// Agent source: the agent's page as the HTML it is (`AgentPage.html()`,
/// byte for byte), read-only, monospaced and highlighted in the theme's
/// source-editor colors.
@MainActor
final class BrowserAgentSourceViewController: NSViewController {

    /// The source text view: selectable, never editable.
    let textView: NSTextView

    private let scrollView: NSScrollView
    private var html = ""
    /// The runs of `html`, lexed off the main thread; empty until they land,
    /// when the source shows in the text color alone.
    private var tokens: [(NSRange, BrowserAgentSourceHighlighter.Kind)] = []
    /// The lex of the HTML showing, while it runs.
    private(set) var highlighting: Task<Void, Never>?
    private var paletteObserver: ThemePaletteObserver?

    init() {
        scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            preconditionFailure("scrollableTextView() always holds an NSTextView")
        }
        self.textView = textView
        super.init(nibName: nil, bundle: nil)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.setAccessibilityIdentifier("browser.agent-source")
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        // Painted in the scope of the window the source sits in, so a window
        // that runs its type larger shows the source larger too.
        paletteObserver = ThemePaletteObserver(host: scrollView) { [weak self] palette in
            self?.apply(palette)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func loadView() { view = scrollView }

    /// The scope resolves through the window, which the view may have joined
    /// since the last paint.
    override func viewWillAppear() {
        super.viewWillAppear()
        apply(scopedPalette)
    }

    /// Shows `page` as its HTML at once, then highlights it when the lex,
    /// which runs off the main thread, lands. The same HTML again is a no-op.
    func show(_ page: AgentPage) {
        let newHTML = page.html()
        guard newHTML != html else { return }
        html = newHTML
        tokens = []
        apply(scopedPalette)
        highlighting?.cancel()
        highlighting = Task { [weak self] in
            let runs = await Task.detached(priority: .userInitiated) {
                BrowserAgentSourceHighlighter.tokens(in: newHTML)
            }.value
            guard let self, !Task.isCancelled, self.html == newHTML else { return }
            self.tokens = runs
            self.apply(self.scopedPalette)
        }
    }

    /// The palette of the scope the source view sits in (the app's until it
    /// is in a window).
    private var scopedPalette: SemanticPalette { scrollView.resolvedThemeScope.palette }

    private func apply(_ palette: SemanticPalette) {
        let theme = palette.editorTheme
        let colors = BrowserAgentSourceHighlighter.Colors(
            tag: theme.keywords.color, attributeName: theme.attributes.color,
            attributeValue: theme.strings.color, text: theme.text.color)
        let styled = BrowserAgentSourceHighlighter.highlight(
            html, tokens: tokens, font: palette.font(.code), colors: colors)
        textView.backgroundColor = theme.background
        scrollView.backgroundColor = theme.background
        textView.textStorage?.setAttributedString(styled)
    }
}

/// A small HTML highlighter for the agent's own markup: tags, attribute
/// names, attribute values and text. Not a parser — `AgentPage.html()` is
/// regular, escaped output — so it only has to tell the four apart.
enum BrowserAgentSourceHighlighter {

    enum Kind: Equatable, Sendable { case tag, attributeName, attributeValue, text }

    struct Colors {
        let tag: NSColor
        let attributeName: NSColor
        let attributeValue: NSColor
        let text: NSColor

        func color(for kind: Kind) -> NSColor {
            switch kind {
            case .tag: return tag
            case .attributeName: return attributeName
            case .attributeValue: return attributeValue
            case .text: return text
            }
        }
    }

    /// `source` styled: every character in `font`, colored by its kind.
    static func highlight(_ source: String, font: NSFont, colors: Colors) -> NSAttributedString {
        highlight(source, tokens: tokens(in: source), font: font, colors: colors)
    }

    /// `source` styled by runs already lexed (`tokens(in:)`); no runs leaves
    /// it all in the text color.
    static func highlight(_ source: String, tokens runs: [(NSRange, Kind)], font: NSFont,
                          colors: Colors) -> NSAttributedString {
        let styled = NSMutableAttributedString(
            string: source, attributes: [.font: font, .foregroundColor: colors.text])
        for (range, kind) in runs where kind != .text {
            styled.addAttribute(.foregroundColor, value: colors.color(for: kind), range: range)
        }
        return styled
    }

    /// The runs of `source`, in order, covering every UTF-16 unit once.
    static func tokens(in source: String) -> [(NSRange, Kind)] {
        var lexer = Lexer(units: Array(source.utf16))
        return lexer.run()
    }

    private struct Lexer {
        let units: [UInt16]
        var index = 0
        var runs: [(NSRange, Kind)] = []

        init(units: [UInt16]) { self.units = units }

        private static let lessThan = UInt16(UInt8(ascii: "<"))
        private static let greaterThan = UInt16(UInt8(ascii: ">"))
        private static let equals = UInt16(UInt8(ascii: "="))
        private static let slash = UInt16(UInt8(ascii: "/"))
        private static let doubleQuote = UInt16(UInt8(ascii: "\""))
        private static let singleQuote = UInt16(UInt8(ascii: "'"))

        mutating func run() -> [(NSRange, Kind)] {
            while index < units.count {
                if units[index] == Self.lessThan { lexTag() } else { lexText() }
            }
            return runs
        }

        private mutating func emit(_ start: Int, _ kind: Kind) {
            guard index > start else { return }
            if let last = runs.last, last.1 == kind, NSMaxRange(last.0) == start {
                runs[runs.count - 1].0.length += index - start
            } else {
                runs.append((NSRange(location: start, length: index - start), kind))
            }
        }

        private static func isSpace(_ unit: UInt16) -> Bool {
            unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D || unit == 0x0C
        }

        private mutating func lexText() {
            let start = index
            while index < units.count, units[index] != Self.lessThan { index += 1 }
            emit(start, .text)
        }

        /// `<name`, then attributes, then `>` or `/>`. An unterminated tag
        /// runs to the end of the source.
        private mutating func lexTag() {
            var start = index
            index += 1
            while index < units.count, !Self.isSpace(units[index]), units[index] != Self.greaterThan {
                index += 1
            }
            emit(start, .tag)
            while index < units.count {
                let unit = units[index]
                if Self.isSpace(unit) {
                    start = index
                    while index < units.count, Self.isSpace(units[index]) { index += 1 }
                    emit(start, .text)
                } else if unit == Self.greaterThan || unit == Self.slash {
                    start = index
                    index += 1
                    emit(start, .tag)
                    if unit == Self.greaterThan { return }
                } else if unit == Self.equals {
                    start = index
                    index += 1
                    emit(start, .tag)
                    lexValue()
                } else {
                    start = index
                    while index < units.count, !Self.isSpace(units[index]), units[index] != Self.equals,
                          units[index] != Self.greaterThan, units[index] != Self.slash {
                        index += 1
                    }
                    emit(start, .attributeName)
                }
            }
        }

        private mutating func lexValue() {
            guard index < units.count else { return }
            let start = index
            let quote = units[index]
            if quote == Self.doubleQuote || quote == Self.singleQuote {
                index += 1
                while index < units.count, units[index] != quote { index += 1 }
                if index < units.count { index += 1 }
            } else {
                while index < units.count, !Self.isSpace(units[index]), units[index] != Self.greaterThan {
                    index += 1
                }
            }
            emit(start, .attributeValue)
        }
    }
}
