import UIKit
import AgenticDeveloperHubSDK

/// The iOS twin of `MessageBubbleView`: a single chat bubble for `any
/// Message`, sized to its measured text and themed from the active
/// `SemanticPalette`. Repaints (color, font, and measured size) live on theme
/// change, exactly as the macOS view does.
///
/// `isLocalUser` — not `message` itself — decides the bubble's side and
/// color roles, mirroring `MessageBubbleView`'s own doc comment: ADT's
/// `Message` protocol carries no semantic role, so the caller
/// (`MobileChatViewController`) resolves it by comparing `message.senderID`
/// against the conversation's local participant id.
///
/// Where the macOS view measures with an `NSLayoutManager` (AppKit's
/// idiomatic off-screen text measurement), this one measures with
/// `NSAttributedString.boundingRect(with:options:context:)` — UIKit's
/// idiomatic equivalent — rather than pulling `NSLayoutManager` in to match
/// line for line; both land on the same "measure once at `applyTheme` time,
/// apply as constraint constants" shape.
@MainActor
public final class MobileMessageBubbleView: UIView, Themeable {

    public let message: any Message
    public let isLocalUser: Bool
    public let maxWidth: CGFloat

    /// How `message.text` becomes an attributed string. Defaulted so callers
    /// need not care, and injectable so a host with a `CodeHighlighter` can
    /// pass one down — that is the only reason the seam exists.
    public let renderer: MarkdownRenderer

    private let label = UILabel()
    private var themeObserver: ThemePaletteObserver?

    private var textWidthConstraint: NSLayoutConstraint!
    private var textHeightConstraint: NSLayoutConstraint!
    private var bubbleWidthConstraint: NSLayoutConstraint!

    private static let horizontalPadding: CGFloat = 12
    private static let verticalPadding: CGFloat = 8
    private static let failureBorderWidth: CGFloat = 1

    /// The block appended while a message is still streaming. Mirrors
    /// `MessageBubbleView.streamingCaret` exactly — same glyph, same
    /// contract: it goes into the same attributed string as the text, so the
    /// measurement pass sizes the bubble to include it.
    static let streamingCaret = "\u{258B}"

    /// The exact attributed string the last `applyTheme` handed to the
    /// label. Internal rather than public: it exists so tests can assert on
    /// what was rendered — fonts and colors included — without
    /// screenshotting, mirroring `MessageBubbleView.renderedText`.
    var renderedText: NSAttributedString { label.attributedText ?? NSAttributedString() }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

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

        layer.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false

        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        let hPad = Self.horizontalPadding
        let vPad = Self.verticalPadding
        textWidthConstraint = label.widthAnchor.constraint(equalToConstant: max(maxWidth - hPad * 2, 1))
        textHeightConstraint = label.heightAnchor.constraint(equalToConstant: 20)
        bubbleWidthConstraint = widthAnchor.constraint(equalToConstant: maxWidth)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hPad),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),
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
        let textColor = palette.uiColor(isLocalUser ? .userText : .personaText)
        backgroundColor = palette.uiColor(bubbleRole)

        let hPad = Self.horizontalPadding
        let textMaxWidth = max(maxWidth - hPad * 2, 1)

        let attrString = NSMutableAttributedString(
            attributedString: renderer.render(message.text, palette: palette, textColor: textColor)
        )
        if message.deliveryStatus == .composing {
            // `MobileChatViewController`'s draft handling reports
            // `.composing` for every live draft, so a streaming reply gets
            // its caret with no extra plumbing, and a committed message
            // never does — mirrors `MessageBubbleView` exactly.
            attrString.append(NSAttributedString(
                string: Self.streamingCaret,
                attributes: [.font: palette.font(.body), .foregroundColor: palette.uiColor(.personaName)]
            ))
        }
        if let timestamp = message.timestamp {
            attrString.append(NSAttributedString(
                string: "  " + Self.timeFormatter.string(from: timestamp),
                attributes: [.font: palette.font(.caption), .foregroundColor: palette.uiColor(.timestampText)]
            ))
        }
        // The reason is spelled out rather than left encoded in the border
        // color: the border says something went wrong, the caption says
        // what, and the message text stays readable either way.
        if case .failed(let reason) = message.deliveryStatus {
            layer.borderWidth = Self.failureBorderWidth
            layer.borderColor = palette.uiColor(.danger).cgColor
            attrString.append(NSAttributedString(
                string: "\n" + reason,
                attributes: [.font: palette.font(.caption), .foregroundColor: palette.uiColor(.danger)]
            ))
        } else {
            layer.borderWidth = 0
            layer.borderColor = nil
        }

        let (textWidth, textHeight) = Self.measure(attrString, maxWidth: textMaxWidth)

        label.attributedText = attrString

        textWidthConstraint.constant = textWidth
        textHeightConstraint.constant = textHeight
        bubbleWidthConstraint.constant = min(textWidth + hPad * 2, maxWidth)
    }

    /// Measures `attrString`'s used size when wrapped at `maxWidth`, via
    /// `NSAttributedString.boundingRect(with:options:context:)` — UIKit's
    /// idiomatic off-screen text measurement, mirroring what
    /// `MessageBubbleView.measure(_:maxWidth:)` does with `NSLayoutManager`
    /// on macOS.
    private static func measure(_ attrString: NSAttributedString, maxWidth: CGFloat) -> (width: CGFloat, height: CGFloat) {
        let bounds = attrString.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil)
        return (min(ceil(bounds.width), maxWidth), ceil(bounds.height))
    }
}
