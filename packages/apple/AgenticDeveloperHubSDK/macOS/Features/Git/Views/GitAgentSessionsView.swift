import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreUI

/// The commit detail's "Agent Sessions" section (recipe `workspace/git/git-views`,
/// "Agent sessions"): a caption over one row per session, each showing its title (or the
/// first eight characters of its id), its branch and its time span. Hidden while it has
/// no sessions. A row is a button that calls `onOpen` with the session's id; while
/// `onOpen` is nil the rows are not clickable.
@MainActor
final class GitAgentSessionsView: NSStackView {
    let caption = ThemedLabel(string: "Agent Sessions", role: .secondaryText, textRole: .caption)
    /// One per session, in the order shown.
    private(set) var rowButtons: [NSButton] = []
    /// The sessions shown, newest start first.
    private(set) var sessions: [GitAgentSession] = []

    /// Opens a session by id; nil leaves the rows unclickable.
    var onOpen: ((String) -> Void)? {
        didSet {
            guard (oldValue != nil) != (onOpen != nil) else { return }
            // Rebuilt rather than toggled: a row's colour follows whether it is
            // clickable, and the theme closure reads that when it builds the title.
            let shown = sessions
            sessions = []
            show(shown)
        }
    }

    init() {
        super.init(frame: .zero)
        accessibilityID("git.commit.sessions")
        orientation = .vertical
        alignment = .leading
        spacing = 4
        caption.accessibilityID("git.commit.sessions.caption")
        addArrangedSubview(caption)
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Shows `sessions`, or hides the section when there are none.
    func show(_ sessions: [GitAgentSession]) {
        guard sessions != self.sessions else { return }
        self.sessions = sessions
        for button in rowButtons { button.removeFromSuperview() }
        rowButtons = sessions.enumerated().map { index, session in
            let button = NSButton(title: Self.rowTitle(session), target: self, action: #selector(open(_:)))
            button.isBordered = false
            button.bezelStyle = .regularSquare
            button.alignment = .left
            button.lineBreakMode = .byTruncatingTail
            button.tag = index
            button.toolTip = session.cwd
            button.isEnabled = onOpen != nil
            button.accessibilityID("git.commit.sessions.row")
            button.observeTheme { button, palette in
                button.attributedTitle = NSAttributedString(string: button.title, attributes: [
                    .foregroundColor: palette.nsColor(button.isEnabled ? .accent : .primaryText),
                    .font: palette.font(.body)
                ])
            }
            addArrangedSubview(button)
            return button
        }
        isHidden = sessions.isEmpty
    }

    /// `<title> · <branch> · <span>`, the branch only when known.
    static func rowTitle(_ session: GitAgentSession) -> String {
        var parts = [session.displayTitle]
        if let branch = session.branch, !branch.isEmpty { parts.append(branch) }
        parts.append(spanText(from: session.startedAt, to: session.lastActivityAt))
        return parts.joined(separator: " · ")
    }

    /// The session's time span, from its start to its last activity.
    static func spanText(from start: Date, to end: Date) -> String {
        spanFormatter.string(from: start, to: max(start, end))
    }

    /// One formatter for every row and submenu item, rather than one built per row.
    private static let spanFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    @objc private func open(_ sender: NSButton) {
        guard let onOpen, sessions.indices.contains(sender.tag) else { return }
        onOpen(sessions[sender.tag].id)
    }
}

extension GitCommitDetailViewController {
    /// Shows the agent sessions `agentSessionMatches` finds for the commit shown, or
    /// hides the section; called whenever the commit changes and when the sessions do.
    func reloadAgentSessions() {
        guard let commit, let agentSessionMatches else {
            agentSessionsView.show([])
            return
        }
        agentSessionsView.show(agentSessionMatches(commit))
    }
}
