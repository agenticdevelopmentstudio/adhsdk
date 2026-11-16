import AppKit
import AgenticDeveloperHubSDKCore

/// The commit detail's "Signature" line (recipe `workspace/git/git-views`, "Signing
/// badges"): a caption, the history's signing badge symbol, then the status and signer.
@MainActor
final class GitCommitDetailSignatureRow: NSStackView {
    let caption = ThemedLabel(string: "Signature", role: .secondaryText, textRole: .caption)
    let symbolView = ThemedSymbolImageView(symbolName: nil, role: .secondaryText)
    let textLabel = ThemedLabel(role: .primaryText, textRole: .body)
    /// The badge shown; nil while the line is hidden.
    private(set) var badge: GitHistorySignatureBadge?

    init() {
        super.init(frame: .zero)
        accessibilityID("git.commit.signature")
        orientation = .horizontal
        alignment = .centerY
        spacing = 6
        caption.accessibilityID("git.commit.signature.caption")
        symbolView.accessibilityID("git.commit.signature.symbol")
        textLabel.accessibilityID("git.commit.signature.text")
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.isSelectable = true
        textLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for view in [caption, symbolView, textLabel] { addArrangedSubview(view) }
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Shows `signature`; nil or `.unsigned` hides the line.
    func configure(_ signature: GitSignature?) {
        let badge = GitHistorySignatureBadge(signature)
        self.badge = badge
        isHidden = badge == nil
        symbolView.symbolName = badge?.symbolName
        symbolView.role = badge?.role ?? .secondaryText
        textLabel.stringValue = badge?.text ?? ""
        toolTip = badge?.signature.key.map { "Key \($0)" }
        setAccessibilityLabel(badge.map { "Signature: \($0.text)" })
    }
}

extension GitCommitDetailViewController {
    /// Reads the shown commit's signature again: after `show(commit:)`, and when the owner
    /// hears that signatures landed. Nil from the lookup, or no lookup, hides the line.
    public func reloadSignature() {
        guard let commit, let signatureLookup else {
            signatureRow.configure(nil)
            return
        }
        signatureRow.configure(signatureLookup(commit))
    }
}
