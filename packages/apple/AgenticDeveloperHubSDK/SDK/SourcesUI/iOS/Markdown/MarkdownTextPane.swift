import UIKit
import AgenticDeveloperHubSDK

/// The iOS half of the pane. Its API matches the macOS file exactly — that
/// equality is what lets `MarkdownViewerController` and
/// `MarkdownEditorController` live in `Shared/` with no branching.
@MainActor
public final class MarkdownTextPane: UIView {

    private let textView = UITextView()

    public var onTextChange: ((String) -> Void)?

    public init(editable: Bool) {
        super.init(frame: .zero)

        textView.isEditable = editable
        textView.isSelectable = true
        textView.alwaysBounceVertical = true
        textView.autocorrectionType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        // 8 on every edge, matching the macOS pane and deliberately wider than
        // Quick Note's 6 — this is a document surface, not a scratch field.
        // (UIKit has no scroller chrome to configure here; `UITextView` scrolls
        // itself with an indicator that already hides on its own.)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = self

        textView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
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
        textView.becomeFirstResponder()
    }

    /// The pane's plain-text contents.
    ///
    /// Setting this does **not** fire `onTextChange` — `UITextViewDelegate.textViewDidChange`
    /// only fires from user editing, never from a programmatic assignment to
    /// `UITextView.text`. This is load-bearing: a caller (such as an editor
    /// controller) that re-renders from `onTextChange` and writes the result
    /// back via this setter must not re-enter its own callback, or it loops.
    public var text: String {
        get { textView.text ?? "" }
        set { textView.text = newValue }
    }

    public var attributedText: NSAttributedString {
        textView.attributedText ?? NSAttributedString()
    }

    public func setAttributedText(_ text: NSAttributedString) {
        textView.attributedText = text
    }

    public func applyTheme(_ palette: SemanticPalette) {
        let background = palette.uiColor(.windowBackground)
        backgroundColor = background
        textView.backgroundColor = background
        textView.textColor = palette.uiColor(.primaryText)
        textView.tintColor = palette.uiColor(.cursor)
        textView.font = palette.font(.code)
    }
}

extension MarkdownTextPane: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        onTextChange?(textView.text ?? "")
    }
}
