import Foundation

/// One line of an interactive rebase's todo: a commit and what to do with it.
public struct GitRebaseEntry: Sendable, Hashable, Identifiable {
    public enum Action: String, Sendable, Hashable, CaseIterable {
        case pick, reword, edit, squash, fixup, drop
    }

    /// The full sha.
    public var commit: String
    public var subject: String
    public var action: Action
    /// The new message, for `.reword` only; ignored for every other action.
    public var message: String?

    public var id: String { commit }

    public init(commit: String, subject: String, action: Action = .pick, message: String? = nil) {
        self.commit = commit
        self.subject = subject
        self.action = action
        self.message = message
    }
}

/// An interactive rebase as a value: the commit the branch is replayed onto and the commits
/// after it, oldest first as git lists them, each with its action. `GitClient.rebasePlan`
/// builds one with every entry picked; `GitAction.interactiveRebase` runs it.
public struct GitRebasePlan: Sendable, Hashable {
    public var onto: String
    public var entries: [GitRebaseEntry]

    public init(onto: String, entries: [GitRebaseEntry]) {
        self.onto = onto
        self.entries = entries
    }

    /// Why git would refuse the plan, or nil when it can run: every entry dropped (an empty
    /// plan included), the first entry that is kept being a squash or fixup (there is no
    /// earlier commit to fold it into), or a reword whose message is empty or only whitespace.
    public var validationError: String? {
        let kept = entries.filter { $0.action != .drop }
        guard let first = kept.first else {
            return "Every commit is dropped, so there is nothing to rebase."
        }
        if first.action == .squash || first.action == .fixup {
            return "The first commit cannot be squashed or fixed up: there is no earlier commit to fold it into."
        }
        if kept.contains(where: { entry in
            entry.action == .reword && (entry.message ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) {
            return "A reworded commit needs a message."
        }
        return nil
    }

    /// The first entry's commit that is not a hex object name, or nil. A commit is written into
    /// the todo as is, so anything else (a newline above all) could add a line of its own.
    var invalidCommit: String? {
        entries.first { entry in
            !(4...64).contains(entry.commit.count) || !entry.commit.allSatisfy(Self.hexDigits.contains)
        }?.commit
    }

    /// ASCII only: `Character.isHexDigit` also accepts the fullwidth forms.
    private static let hexDigits = Set("0123456789abcdefABCDEF")

    /// The todo `GIT_SEQUENCE_EDITOR` copies over git's: `<action> <sha> <subject>` per entry,
    /// the subject on one line. A reword is a pick followed by an `exec` that amends the commit
    /// with the message in `messageFile(n)` (`n` counting rewords from 0), so the rebase never
    /// needs an editor; `--allow-empty` keeps an emptied commit amendable.
    func todo(messageFile: (Int) -> String) -> String {
        var lines: [String] = []
        var rewords = 0
        for entry in entries {
            let subject = entry.subject.components(separatedBy: .newlines).joined(separator: " ")
            if entry.action == .reword {
                lines.append("pick \(entry.commit) \(subject)")
                lines.append("exec git commit --amend --no-edit --allow-empty -F "
                             + Self.shellQuoted(messageFile(rewords)))
                rewords += 1
            } else {
                lines.append("\(entry.action.rawValue) \(entry.commit) \(subject)")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Each reword's message, in todo order: what `messageFile(n)` holds.
    var rewordMessages: [String] {
        entries.filter { $0.action == .reword }.map { $0.message ?? "" }
    }

    /// `text` in single quotes for `sh`, each `'` written `'\''`.
    static func shellQuoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
