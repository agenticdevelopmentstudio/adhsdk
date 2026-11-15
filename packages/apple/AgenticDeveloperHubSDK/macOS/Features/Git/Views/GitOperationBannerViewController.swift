import AppKit
import AgenticDeveloperHubSDKCore

/// What the user asked the operation banner to do with the operation in progress.
public enum GitOperationIntent: Equatable {
    case step(GitOperationStep)
}

/// Told which step of the operation in progress the user chose.
@MainActor public protocol GitOperationBannerDelegate: AnyObject {
    func banner(_ banner: GitOperationBannerViewController, didRequest intent: GitOperationIntent)
}

/// The git window's in-progress operation banner (recipe `workspace/git/git-views`,
/// "Operation banner"): what the working tree is in the middle of, with Continue, Skip
/// (for an operation that takes it) and Abort.
///
/// Its owner sets `state` from the model on every change; `.none` hides the whole view.
/// The banner runs no git: each button reaches the delegate as a `GitOperationIntent`,
/// and the owner decides what confirms.
@MainActor
public final class GitOperationBannerViewController: NSViewController {

    public weak var delegate: GitOperationBannerDelegate?

    /// The operation shown; `.none` hides the view, anything else shows it.
    public var state: GitOperationState = .none {
        didSet { apply() }
    }

    let statusLabel = ThemedLabel(role: .primaryText, textRole: .body, weight: .semibold)
    let continueButton = NSButton(title: "Continue", target: nil, action: nil)
    let skipButton = NSButton(title: "Skip", target: nil, action: nil)
    let abortButton = NSButton(title: "Abort", target: nil, action: nil)

    public init() {
        super.init(nibName: nil, bundle: nil)
        statusLabel.accessibilityID("git.banner.status")
        statusLabel.lineBreakMode = .byTruncatingMiddle
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for (button, name, step) in [
            (continueButton, "continue", GitOperationStep.continue), (skipButton, "skip", .skip),
            (abortButton, "abort", .abort)
        ] {
            button.accessibilityID("git.banner.\(name)")
            button.bezelStyle = .push
            button.controlSize = .small
            button.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
            button.target = self
            button.action = #selector(stepChosen(_:))
            button.tag = Self.tags[step] ?? 0
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static let tags: [GitOperationStep: Int] = [.continue: 1, .skip: 2, .abort: 3]

    public override func loadView() {
        let root = ThemedBackgroundView(role: .elevatedSurface)
        root.accessibilityID("git.banner")

        let buttons = NSStackView(views: [continueButton, skipButton, abortButton])
        buttons.accessibilityID("git.banner.buttons")
        buttons.orientation = .horizontal
        buttons.spacing = 6
        // A hidden Skip takes no room.
        buttons.detachesHiddenViews = true

        for view in [statusLabel, buttons] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -8),
            statusLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 6),
            buttons.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 8),
            buttons.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -8),
            buttons.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            buttons.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -6)
        ])
        view = root
        apply()
    }

    /// What the banner says for `state`: `Merging <sha>`, `Rebasing <branch> (<step>/<total>)`,
    /// `Cherry-picking <sha>` or `Reverting <sha>`, each part left out when git did not
    /// record it; nil for `.none`. A sha is shortened to seven characters.
    public static func statusText(for state: GitOperationState) -> String? {
        switch state {
        case .none:
            return nil
        case .merging(let head):
            return phrase("Merging", short(head))
        case .rebasing(let branch, _, let step, let total, _):
            var text = phrase("Rebasing", branch)
            if let step, let total { text += " (\(step)/\(total))" }
            return text
        case .cherryPicking(let commit):
            return phrase("Cherry-picking", short(commit))
        case .reverting(let commit):
            return phrase("Reverting", short(commit))
        }
    }

    private static func phrase(_ verb: String, _ subject: String?) -> String {
        guard let subject, !subject.isEmpty else { return verb }
        return "\(verb) \(subject)"
    }

    private static func short(_ sha: String?) -> String? {
        sha.map { String($0.prefix(7)) }
    }

    private func apply() {
        guard isViewLoaded else { return }
        let text = Self.statusText(for: state)
        view.isHidden = text == nil
        statusLabel.stringValue = text ?? ""
        skipButton.isHidden = !state.allowsSkip
    }

    @objc private func stepChosen(_ sender: NSButton) {
        guard let step = Self.tags.first(where: { $0.value == sender.tag })?.key else { return }
        delegate?.banner(self, didRequest: .step(step))
    }
}
