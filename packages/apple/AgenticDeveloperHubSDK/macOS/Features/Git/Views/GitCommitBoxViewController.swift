import AppKit
import AgenticDeveloperHubSDKCore

/// The working copy's commit box (recipe `workspace/git/git-views`, "Working copy"): a
/// plain-text message, an Amend checkbox and a Commit button. It runs nothing: pressing
/// Commit calls `onCommit` with the message as typed, and ticking Amend `onAmendChanged`.
///
/// Commit is enabled when the message trimmed of whitespace is not empty and there are
/// staged changes or Amend is on. Used on the main thread.
@MainActor
public final class GitCommitBoxViewController: NSViewController {

    /// Called with the message exactly as typed and whether Amend is on.
    public var onCommit: ((String, Bool) -> Void)?
    /// Called with Amend's new state when the user ticks or unticks it.
    public var onAmendChanged: ((Bool) -> Void)?

    /// The message. Setting it does not call anything.
    public var message: String {
        get { messageView.string }
        set {
            messageView.string = newValue
            updateCommitEnabled()
        }
    }

    /// Whether Amend is ticked. Setting it does not call `onAmendChanged`, and it stays
    /// false while `canAmend` is.
    public var isAmend: Bool {
        get { amendBox.state == .on }
        set {
            amendBox.state = newValue && canAmend ? .on : .off
            updateCommitEnabled()
        }
    }

    /// Whether there is a commit to amend; false disables Amend and unticks it.
    public var canAmend = false {
        didSet {
            amendBox.isEnabled = canAmend
            if !canAmend { isAmend = false }
        }
    }

    /// Whether anything is staged; with `isAmend`, decides whether Commit is enabled.
    public var hasStagedChanges = false {
        didSet { updateCommitEnabled() }
    }

    let headerLabel = ThemedLabel(role: .secondaryText, textRole: .caption, weight: .semibold)
    let messageView = NSTextView()
    let amendBox = NSButton(checkboxWithTitle: "Amend", target: nil, action: nil)
    let commitButton = NSButton(title: "Commit", target: nil, action: nil)
    private let scrollView = ThemedScrollView()

    public init() {
        super.init(nibName: nil, bundle: nil)
        headerLabel.stringValue = "Commit Message"
        headerLabel.accessibilityID("git.commitBox.header")

        messageView.accessibilityID("git.commitBox.message")
        messageView.isRichText = false
        messageView.importsGraphics = false
        messageView.allowsUndo = true
        messageView.isAutomaticQuoteSubstitutionEnabled = false
        messageView.isAutomaticDashSubstitutionEnabled = false
        messageView.isAutomaticTextReplacementEnabled = false
        messageView.isVerticallyResizable = true
        messageView.isHorizontallyResizable = false
        messageView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        // As tall as the scroll view at least, so a click anywhere in the box lands in the text.
        messageView.autoresizingMask = [.width, .height]
        messageView.textContainer?.widthTracksTextView = true
        messageView.textContainerInset = NSSize(width: 4, height: 4)
        messageView.delegate = self
        messageView.observeTheme { view, palette in
            view.font = palette.font(.body)
            view.textColor = palette.nsColor(.primaryText)
            view.insertionPointColor = palette.nsColor(.primaryText)
            view.drawsBackground = false
        }

        amendBox.accessibilityID("git.commitBox.amend")
        amendBox.target = self
        amendBox.action = #selector(amendToggled(_:))
        amendBox.isEnabled = false

        commitButton.accessibilityID("git.commitBox.commit")
        commitButton.bezelStyle = .push
        commitButton.keyEquivalent = "\r"
        commitButton.keyEquivalentModifierMask = .command
        commitButton.target = self
        commitButton.action = #selector(commit(_:))
        commitButton.isEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.commitBox")

        scrollView.accessibilityID("git.commitBox.scroll")
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = messageView

        let buttonRow = NSStackView(views: [amendBox, commitButton])
        buttonRow.accessibilityID("git.commitBox.buttons")
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 12

        for view in [headerLabel, scrollView, buttonRow] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            headerLabel.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -8),
            headerLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            buttonRow.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 6),
            buttonRow.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            buttonRow.leadingAnchor.constraint(greaterThanOrEqualTo: root.leadingAnchor, constant: 8),
            buttonRow.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -8)
        ])
        view = root
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        let height = scrollView.contentSize.height
        guard messageView.minSize.height != height else { return }
        messageView.minSize = NSSize(width: 0, height: height)
        if messageView.frame.height < height {
            messageView.setFrameSize(NSSize(width: scrollView.contentSize.width, height: height))
        }
    }

    /// The message's own undo stack, so clearing it after a commit touches nothing else
    /// in the window.
    let messageUndoManager = UndoManager()

    /// Forgets every edit the message can undo, after the owner's commit succeeded.
    public func clearUndoHistory() {
        messageUndoManager.removeAllActions()
    }

    private var canCommit: Bool {
        let hasMessage = !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasMessage && (hasStagedChanges || isAmend)
    }

    private func updateCommitEnabled() {
        commitButton.isEnabled = canCommit
    }

    @objc private func amendToggled(_ sender: NSButton) {
        updateCommitEnabled()
        onAmendChanged?(isAmend)
    }

    @objc private func commit(_ sender: NSButton) {
        guard canCommit else { return }
        onCommit?(message, isAmend)
    }
}

extension GitCommitBoxViewController: NSTextViewDelegate {
    public func textDidChange(_ notification: Notification) {
        updateCommitEnabled()
    }

    public func undoManager(for view: NSTextView) -> UndoManager? {
        messageUndoManager
    }
}
