import AppKit
import AgenticDeveloperHubSDKCore

/// The history list's row: the themed row view, so selection follows the palette.
@MainActor
final class GitHistoryRowView: ThemedTableRowView {}

/// One ref badge in a history row: the ref's name and its kind, which fixes the
/// badge's style and colour (recipe `workspace/git/git-views`, history-ref-badges).
public struct GitHistoryRefBadge: Equatable, Sendable {
    public let title: String
    public let kind: GitRef.Kind

    public init(title: String, kind: GitRef.Kind) {
        self.title = title
        self.kind = kind
    }

    /// Local branches are filled; remote branches and tags are outlined.
    public var style: Badge.Style { kind == .localBranch ? .filled : .outlined }

    /// Branches, local or remote, are the accent colour; tags the warning colour.
    public var role: ThemeRole { kind == .tag ? .warning : .accent }

    var accessibilityIdentifier: String {
        switch kind {
        case .localBranch: return "git.history.badge.local"
        case .remoteBranch: return "git.history.badge.remote"
        case .tag: return "git.history.badge.tag"
        }
    }

    /// The badges for `refs`: local branches, then remote branches, then tags,
    /// each kind in the order given.
    static func badges(for refs: [GitRef]) -> [GitHistoryRefBadge] {
        let order: [GitRef.Kind] = [.localBranch, .remoteBranch, .tag]
        return order.flatMap { kind in
            refs.filter { $0.kind == kind }.map { GitHistoryRefBadge(title: $0.name, kind: kind) }
        }
    }
}

/// The subject column: a badge per ref at the commit, then the subject.
@MainActor
final class GitHistorySubjectCellView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier("git.history.subject")

    let subjectLabel = ThemedLabel(role: .primaryText, textRole: .body)
    private(set) var badges: [GitHistoryRefBadge] = []
    private(set) var badgeViews: [Badge] = []
    private let stack = NSStackView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
        accessibilityID("git.history.subject")
        subjectLabel.lineBreakMode = .byTruncatingTail
        subjectLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(subjectLabel)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        observeTheme { cell, palette in cell.paintBadges(palette) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(subject: String, badges: [GitHistoryRefBadge]) {
        subjectLabel.stringValue = subject
        guard badges != self.badges else { return }
        self.badges = badges
        for view in badgeViews { view.removeFromSuperview() }
        let palette = resolvedThemeScope.palette
        badgeViews = badges.enumerated().map { index, badge in
            let view = Badge(text: badge.title, color: palette.nsColor(badge.role), style: badge.style)
            view.accessibilityID(badge.accessibilityIdentifier)
            stack.insertArrangedSubview(view, at: index)
            return view
        }
    }

    private func paintBadges(_ palette: SemanticPalette) {
        for (badge, view) in zip(badges, badgeViews) {
            view.update(text: badge.title, color: palette.nsColor(badge.role), style: badge.style)
        }
    }
}

/// The author column: the author's initials in an 18-point avatar, then the name.
@MainActor
final class GitHistoryAuthorCellView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier("git.history.author")

    /// Initials only: the cell never gives the avatar a picture URL, so it never fetches.
    let avatar = AvatarView(side: 18)
    let nameLabel = ThemedLabel(role: .secondaryText, textRole: .body)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
        accessibilityID("git.history.author")
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let stack = NSStackView(views: [avatar, nameLabel])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(author: GitPerson) {
        nameLabel.stringValue = author.name
        avatar.content = AvatarContent(name: author.name, seed: author.email, imageURL: nil)
    }
}
