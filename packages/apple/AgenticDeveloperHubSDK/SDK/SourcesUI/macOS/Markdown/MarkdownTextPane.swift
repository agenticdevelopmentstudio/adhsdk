import AppKit
import AgenticDeveloperHubSDK

/// A scrolling text pane with the same API on both platforms, so the markdown
/// controllers above it never branch.
@MainActor
public final class MarkdownTextPane: NSView {

    private let scrollView = NSScrollView()
    private let textView = NSTextView()

    public var onTextChange: ((String) -> Void)?

    public init(editable: Bool) {
        super.init(frame: .zero)

        textView.isEditable = editable
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        // The find bar is `NSTextView`'s own, and it stays off unless asked
        // for: `usesFindBar` defaults to false, which makes
        // `performTextFinderAction(.showFindInterface)` a silent no-op.
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        // 8×8 rather than Quick Note's 6×6, deliberately: this is a document
        // surface a reader stays in, and it wants the wider gutter. Do not
        // "fix" the difference by matching the smaller one.
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.delegate = self

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        // Match the chrome the toolkit's other scrolling lists use: an
        // overlay scroller that hides itself, and no frame of its own — the
        // pane is edge to edge inside whatever splits or tabs contain it.
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public var isEditable: Bool {
        get { textView.isEditable }
        set { textView.isEditable = newValue }
    }

    /// Moves the keyboard focus into the text view itself.
    ///
    /// The text view is private, and a caller that makes *the pane* first
    /// responder gets a container that does not accept keystrokes — so a
    /// window that wants a ready caret has to ask for it by name.
    @discardableResult
    public func focus() -> Bool {
        window?.makeFirstResponder(textView) ?? false
    }

    /// The pane's plain-text contents.
    ///
    /// Setting this does **not** fire `onTextChange` — `NSTextViewDelegate.textDidChange`
    /// only fires from user editing, never from a programmatic assignment to
    /// `NSTextView.string`. This is load-bearing: a caller (such as an editor
    /// controller) that re-renders from `onTextChange` and writes the result
    /// back via this setter must not re-enter its own callback, or it loops.
    public var text: String {
        get { textView.string }
        set {
            textView.string = newValue
            // A replaced document is a different document: its predecessor's
            // undo steps would apply to the wrong text (or out of range).
            textView.undoManager?.removeAllActions(withTarget: textView)
            if let storage = textView.textStorage {
                textView.undoManager?.removeAllActions(withTarget: storage)
            }
        }
    }

    public var attributedText: NSAttributedString {
        textView.attributedString()
    }

    public func setAttributedText(_ text: NSAttributedString) {
        textView.textStorage?.setAttributedString(text)
    }

    public func applyTheme(_ palette: SemanticPalette) {
        let background = palette.nsColor(.windowBackground)
        scrollView.backgroundColor = background
        textView.backgroundColor = background
        textView.textColor = palette.nsColor(.primaryText)
        textView.insertionPointColor = palette.nsColor(.cursor)
        textView.font = palette.font(.code)
        textView.selectedTextAttributes = [
            .backgroundColor: palette.nsColor(.selection),
            .foregroundColor: palette.nsColor(.selectionText)
        ]
    }
}

extension MarkdownTextPane: NSTextViewDelegate {
    public func textDidChange(_ notification: Notification) {
        onTextChange?(textView.string)
    }
}
