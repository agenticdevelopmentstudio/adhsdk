import AppKit
import AgenticDeveloperHubSDKCore

/// What the user asked of a pull request, from the sidebar's section or the detail's
/// buttons. The views run none of it; the session does.
public enum GitPullRequestIntent: Equatable {
    /// Show it in the centre pane.
    case show(GitPullRequest)
    /// `gh pr checkout <number>`.
    case checkout(GitPullRequest)
    /// Its page, in the user's browser.
    case openInBrowser(GitPullRequest)
    /// A new pull request for the checked-out branch, through the create form.
    case create
}

/// How a pull request reads in the sidebar and the detail.
enum GitPullRequestPresentation {

    /// `Draft`, or the state in words: `Open`, `Closed`, `Merged`.
    static func stateText(_ pullRequest: GitPullRequest) -> String {
        if pullRequest.isDraft { return "Draft" }
        switch pullRequest.state.uppercased() {
        case "OPEN": return "Open"
        case "CLOSED": return "Closed"
        case "MERGED": return "Merged"
        default: return pullRequest.state.capitalized
        }
    }

    /// The draft or status symbol a row shows.
    static func statusSymbolName(_ pullRequest: GitPullRequest) -> String {
        if pullRequest.isDraft { return "circle.dashed" }
        switch pullRequest.state.uppercased() {
        case "MERGED": return "arrow.triangle.merge"
        case "CLOSED": return "xmark.circle"
        default: return "arrow.triangle.pull"
        }
    }

    /// The check state as one symbol: `✗` when any check failed, `●` while any is
    /// pending, `✓` when every one passed; nil with no checks.
    static func checkSymbol(_ checks: GitPullRequestChecks?) -> String? {
        guard let checks, checks.total > 0 else { return nil }
        if checks.failing > 0 { return "✗" }
        if checks.pending > 0 { return "●" }
        return "✓"
    }

    /// `3 passing, 1 failing, 0 pending`, or `None` with no checks.
    static func checksText(_ checks: GitPullRequestChecks?) -> String {
        guard let checks, checks.total > 0 else { return "None" }
        return "\(checks.passing) passing, \(checks.failing) failing, \(checks.pending) pending"
    }

    /// `Approved`, `Changes requested`, `Review required`, or `None`.
    static func reviewText(_ decision: String?) -> String {
        switch decision?.uppercased() {
        case "APPROVED": return "Approved"
        case "CHANGES_REQUESTED": return "Changes requested"
        case "REVIEW_REQUIRED": return "Review required"
        case nil, "": return "None"
        default: return decision?.capitalized ?? "None"
        }
    }

    /// `head → base`.
    static func branchesText(_ pullRequest: GitPullRequest) -> String {
        "\(pullRequest.headRefName) → \(pullRequest.baseRefName)"
    }
}

/// One pull request in the Git window's centre pane (recipe `workspace/git/git-views`,
/// "Pull requests"): its title, number, state, author, `head → base`, review decision,
/// check counts and updated date, with Open in Browser and Check Out. The body is not
/// fetched; it opens in the browser. Check Out is off for the checked-out branch's own
/// pull request, and both buttons are off with nothing shown. Used on the main thread.
@MainActor
public final class GitPullRequestViewController: NSViewController {

    /// Called with the button the user pressed.
    var onIntent: ((GitPullRequestIntent) -> Void)?

    /// The pull request shown; nil before the first `show(_:)`, and after `show(nil)`.
    public private(set) var pullRequest: GitPullRequest?

    /// The branch HEAD is on, set by the session; a pull request from it is already
    /// checked out, so Check Out is off for it.
    public var checkedOutBranch: String? {
        didSet { if checkedOutBranch != oldValue { apply() } }
    }

    let titleLabel = ThemedLabel.wrapping("", width: 480, role: .primaryText, textRole: .heading, weight: .bold)
    let numberLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let stateLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let authorLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let branchesLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let reviewLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let checksLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let updatedLabel = ThemedLabel(role: .primaryText, textRole: .body)
    let openButton = NSButton(title: "Open in Browser", target: nil, action: nil)
    let checkoutButton = NSButton(title: "Check Out", target: nil, action: nil)

    /// The updated date as the detail shows it.
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func loadView() {
        let root = NSView()
        root.accessibilityID("git.pullRequest")

        titleLabel.isSelectable = true
        titleLabel.accessibilityID("git.pullRequest.title")
        let fields: [(String, ThemedLabel, String)] = [
            ("Number", numberLabel, "number"), ("State", stateLabel, "state"),
            ("Author", authorLabel, "author"), ("Branches", branchesLabel, "branches"),
            ("Review", reviewLabel, "review"), ("Checks", checksLabel, "checks"),
            ("Updated", updatedLabel, "updated")
        ]
        for (_, label, name) in fields {
            label.isSelectable = true
            label.accessibilityID("git.pullRequest.\(name)")
        }
        let grid = NSGridView(views: fields.map { title, label, name in
            let caption = ThemedLabel(string: title, role: .secondaryText, textRole: .body)
            caption.accessibilityID("git.pullRequest.caption.\(name)")
            return [caption, label]
        })
        grid.accessibilityID("git.pullRequest.fields")
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.columnSpacing = 8
        grid.rowSpacing = 6

        openButton.target = self
        openButton.action = #selector(openPressed(_:))
        openButton.accessibilityID("git.pullRequest.open")
        checkoutButton.target = self
        checkoutButton.action = #selector(checkoutPressed(_:))
        checkoutButton.accessibilityID("git.pullRequest.checkout")
        let buttons = NSStackView(views: [openButton, checkoutButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.accessibilityID("git.pullRequest.buttons")

        let stack = NSStackView(views: [titleLabel, grid, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: root.widthAnchor, constant: -32)
        ])
        view = root
        apply()
    }

    /// Shows `pullRequest`'s fields; nil empties them and turns both buttons off, for a
    /// selected pull request the list no longer has.
    public func show(_ pullRequest: GitPullRequest?) {
        self.pullRequest = pullRequest
        apply()
    }

    private func apply() {
        guard isViewLoaded else { return }
        guard let pullRequest else {
            for label in [titleLabel, numberLabel, stateLabel, authorLabel, branchesLabel, reviewLabel,
                          checksLabel, updatedLabel] {
                label.stringValue = ""
            }
            openButton.isEnabled = false
            checkoutButton.isEnabled = false
            return
        }
        titleLabel.stringValue = pullRequest.title
        numberLabel.stringValue = "#\(pullRequest.number)"
        stateLabel.stringValue = GitPullRequestPresentation.stateText(pullRequest)
        authorLabel.stringValue = pullRequest.author
        branchesLabel.stringValue = GitPullRequestPresentation.branchesText(pullRequest)
        reviewLabel.stringValue = GitPullRequestPresentation.reviewText(pullRequest.reviewDecision)
        checksLabel.stringValue = GitPullRequestPresentation.checksText(pullRequest.checks)
        updatedLabel.stringValue = Self.dateFormatter.string(from: pullRequest.updatedAt)
        openButton.isEnabled = true
        checkoutButton.isEnabled = pullRequest.isCrossRepository || pullRequest.headRefName != checkedOutBranch
    }

    @objc private func openPressed(_ sender: NSButton) {
        guard let pullRequest else { return }
        onIntent?(.openInBrowser(pullRequest))
    }

    @objc private func checkoutPressed(_ sender: NSButton) {
        guard let pullRequest else { return }
        onIntent?(.checkout(pullRequest))
    }
}
