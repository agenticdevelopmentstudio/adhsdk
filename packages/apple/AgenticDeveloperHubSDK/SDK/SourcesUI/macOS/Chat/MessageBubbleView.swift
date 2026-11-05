import AppKit
import AgenticDeveloperHubSDK

/// A single chat bubble for `any Message`, sized to its measured text and
/// themed from the active `SemanticPalette`. Repaints (color, font, and
/// measured size — the theme's typography size scale can change the fit)
/// live on theme change.
///
/// `isLocalUser` — not `message` itself — decides the bubble's side and
/// color roles, because ADT's `Message` protocol carries no semantic role
/// (unlike AgenticDeveloperHubSDK's `ChatMessage.role`); the caller (`InlineChatView`)
/// resolves that by comparing `message.senderID` against the conversation's
/// local participant id.
///
/// The attributed-string build in `applyTheme` is the whole rendering
/// contract: `MarkdownRenderer` turns `message.text` into themed spans (and
/// offers fenced blocks to an injected `CodeHighlighter`), a `.composing`
/// message gets a streaming caret, and a `.failed` one gets a `.danger`
/// border plus its reason spelled out beneath the text.
@MainActor
public final class MessageBubbleView: NSView, Themeable {

    public let message: any Message
    public let isLocalUser: Bool
    public let maxWidth: CGFloat

    /// How `message.text` becomes an attributed string. Defaulted so callers
    /// need not care, and injectable so a host with a `CodeHighlighter` can
    /// pass one down — that is the only reason the seam exists.
    public let renderer: MarkdownRenderer

    private let textView = NSTextView(frame: .zero)
    private var themeObserver: ThemePaletteObserver?

    private var textWidthConstraint: NSLayoutConstraint!
    private var textHeightConstraint: NSLayoutConstraint!
    private var bubbleWidthConstraint: NSLayoutConstraint!
    private var textLeading: NSLayoutConstraint!
    private var textTrailing: NSLayoutConstraint!
    private var textTop: NSLayoutConstraint!
    private var textBottom: NSLayoutConstraint!

    private static let horizontalPadding: CGFloat = 12
    private static let verticalPadding: CGFloat = 8
    private static let cornerRadius: CGFloat = 12
    private static let failureBorderWidth: CGFloat = 1

    /// Whether the active theme asked for no bubble fill, so this message is
    /// drawn as a flat transcript line. Internal so tests can assert on the
    /// geometry rule without reading back a layer.
    private(set) var isFlat = false

    /// The block appended while a message is still streaming. A character
    /// rather than a blinking sublayer: it goes into the same attributed
    /// string as the text, so the measurement pass below sizes the bubble to
    /// include it and the caret can never overhang the bubble it belongs to.
    static let streamingCaret = "\u{258B}"

    /// The exact attributed string the last `applyTheme` handed to the text
    /// view. Internal rather than public: it exists so tests can assert on
    /// what was rendered — fonts and colors included — without
    /// screenshotting, and a host has `message` for everything else.
    var renderedText: NSAttributedString { textView.attributedString() }

    /// Hour and minute in the user's own locale, zero-padded.
    ///
    /// Web's `formatTime` asks for exactly this —
    /// `toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })`: the
    /// locale decides the hour cycle and the ordering, the caller insists only
    /// on two digits. The hard-coded `"HH:mm"` this replaces forced a 24-hour
    /// clock on every reader, which is a decision neither the theme nor the
    /// website ever made.
    ///
    /// So: take the locale's own `j`-pattern (`j` = "hour, however this locale
    /// writes one") and widen a single-digit hour field to two, leaving the
    /// separator, the ordering and any AM/PM marker as the locale wrote them.
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        let pattern = DateFormatter.dateFormat(
            fromTemplate: "jmm", options: 0, locale: Locale.current) ?? "HH:mm"
        formatter.dateFormat = pattern
            .replacingOccurrences(of: "(?<!h)h(?!h)", with: "hh", options: .regularExpression)
            .replacingOccurrences(of: "(?<!H)H(?!H)", with: "HH", options: .regularExpression)
        return formatter
    }()

    /// The timestamp line's own paragraph style: web's `.pc-time` is a block
    /// element under the message text, aligned to the sender's side
    /// (`text-align: left` on a persona bubble, `right` on the user's).
    private static func timeParagraphStyle(isLocalUser: Bool) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = isLocalUser ? .right : .left
        return style
    }

    public init(
        message: any Message,
        maxWidth: CGFloat,
        isLocalUser: Bool,
        renderer: MarkdownRenderer = MarkdownRenderer()
    ) {
        self.message = message
        self.maxWidth = maxWidth
        self.isLocalUser = isLocalUser
        self.renderer = renderer
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = Self.cornerRadius
        translatesAutoresizingMaskIntoConstraints = false

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)

        let hPad = Self.horizontalPadding
        let vPad = Self.verticalPadding
        textWidthConstraint = textView.widthAnchor.constraint(equalToConstant: max(maxWidth - hPad * 2, 1))
        textHeightConstraint = textView.heightAnchor.constraint(equalToConstant: 20)
        bubbleWidthConstraint = widthAnchor.constraint(equalToConstant: maxWidth)

        textTop = textView.topAnchor.constraint(equalTo: topAnchor, constant: vPad)
        textLeading = textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hPad)
        textTrailing = textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -hPad)
        textBottom = textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad)

        NSLayoutConstraint.activate([
            textTop,
            textLeading,
            textTrailing,
            textBottom,
            textWidthConstraint,
            textHeightConstraint,
            bubbleWidthConstraint
        ])

        themeObserver = ThemePaletteObserver(host: self) { [weak self] palette in self?.applyTheme(palette) }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public func applyTheme(_ palette: SemanticPalette) {
        let bubbleRole: ThemeRole = isLocalUser ? .userBubble : .personaBubble
        let borderRole: ThemeRole = isLocalUser ? .userBubbleBorder : .personaBubbleBorder
        let textColor = palette.nsColor(isLocalUser ? .userText : .personaText)
        let fill = palette.color(bubbleRole)
        layer?.backgroundColor = palette.nsColor(bubbleRole).cgColor

        // A theme that asks for no fill is asking for no bubble, and the
        // padding and the corner radius are part of the bubble. Web says the
        // same thing by omission: `.pc-bubble` in `chat/src/css/base.css` sets
        // width, wrapping and position and *nothing else* — no background, no
        // padding, no radius — so a theme that declares no `--pc-persona-bg`
        // (`old-school-terminal`, `terminal`, `crt-monitor`) renders a flat
        // transcript. Keeping the geometry here would leave those themes with
        // an invisible box holding their text 12 points off the edge that
        // every other line aligns to.
        isFlat = fill.alpha <= 0.001
        let hPad = isFlat ? 0 : Self.horizontalPadding
        let vPad = isFlat ? 0 : Self.verticalPadding
        layer?.cornerRadius = isFlat ? 0 : Self.cornerRadius
        textLeading.constant = hPad
        textTrailing.constant = -hPad
        textTop.constant = vPad
        textBottom.constant = -vPad

        let textMaxWidth = max(maxWidth - hPad * 2, 1)

        let attrString = NSMutableAttributedString(
            attributedString: renderer.render(message.text, palette: palette, textColor: textColor)
        )
        if message.deliveryStatus == .composing {
            // `InlineChatView`'s `DraftMessageAdapter` reports `.composing`
            // for every live draft, so a streaming reply gets its caret with
            // no extra plumbing, and a committed message never does.
            attrString.append(NSAttributedString(
                string: Self.streamingCaret,
                attributes: [.font: palette.font(.body), .foregroundColor: palette.nsColor(.personaName)]
            ))
        }
        // The reason is spelled out rather than left encoded in the border
        // color: the border says something went wrong, the caption says what,
        // and the message text stays readable either way.
        if case .failed(let reason) = message.deliveryStatus {
            layer?.borderWidth = Self.failureBorderWidth
            layer?.borderColor = palette.nsColor(.danger).cgColor
            attrString.append(NSAttributedString(
                string: "\n" + reason,
                attributes: [.font: palette.font(.caption), .foregroundColor: palette.nsColor(.danger)]
            ))
        } else if !isFlat, palette.declares(borderRole), palette.color(borderRole).alpha > 0.001 {
            // Themes that draw an outlined bubble *declare* `*BubbleBorder`
            // (`charcoal`, `techy`, `fishlamp`, `mikefullerton` …). It was
            // ported for all of them and read by nothing.
            //
            // `declares`, not merely "resolves to something visible": every
            // role derives an opaque colour when a theme leaves it out, so
            // reading the resolved colour would put a hairline around every
            // bubble in every theme — including the fifteen that say nothing
            // about one and, on the website, draw none.
            layer?.borderWidth = 1
            layer?.borderColor = palette.nsColor(borderRole).cgColor
        } else {
            layer?.borderWidth = 0
            layer?.borderColor = nil
        }

        // Last, and on a line of its own: web puts `.pc-time` beneath the
        // message as the bubble's final child, not trailing the sentence. It
        // went in mid-string here — two spaces and a clock jammed onto the end
        // of whatever the persona said — which reads as part of the message
        // rather than as a note about it.
        if let timestamp = message.timestamp {
            attrString.append(NSAttributedString(
                string: "\n" + Self.timeFormatter.string(from: timestamp),
                attributes: [
                    .font: palette.font(.caption),
                    .foregroundColor: palette.nsColor(.timestampText),
                    .paragraphStyle: Self.timeParagraphStyle(isLocalUser: isLocalUser)
                ]
            ))
        }

        let (textWidth, textHeight) = Self.measure(attrString, maxWidth: textMaxWidth)

        textView.textContainer?.size = NSSize(width: textWidth, height: .greatestFiniteMagnitude)
        textView.textStorage?.setAttributedString(attrString)

        textWidthConstraint.constant = textWidth
        textHeightConstraint.constant = textHeight
        bubbleWidthConstraint.constant = min(textWidth + hPad * 2, maxWidth)
    }

    /// Measures `attrString`'s used size when wrapped at `maxWidth`, via a
    /// throwaway layout manager — the same approach AppKit text views use
    /// internally, kept out-of-line so `applyTheme` reads as "build the
    /// string, measure it, apply the measurement."
    private static func measure(_ attrString: NSAttributedString, maxWidth: CGFloat) -> (width: CGFloat, height: CGFloat) {
        let textStorage = NSTextStorage(attributedString: attrString)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: maxWidth, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        return (min(ceil(usedRect.width), maxWidth), ceil(usedRect.height))
    }
}
