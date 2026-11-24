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
    /// the subject on one line. `helperFile(name)` is the path of `name` in the helper folder;
    /// `git` is the executable the `exec` lines run (`GitClientConfiguration.executableURL`),
    /// shell-quoted, so a reword amends with the same git the rebase runs under.
    ///
    /// A reword is three lines, so the rebase never needs an editor: an `exec` that records
    /// HEAD in `head-<n>`, the pick, and an `exec` that amends HEAD with the message in
    /// `message-<n>` (`n` counting rewords from 0) only when HEAD has moved since. A pick that
    /// stops (a conflict, an emptied commit) and is then skipped leaves HEAD where it was, and
    /// git still runs the next line, so an unconditional amend would rewrite the previous
    /// commit, `onto` included. A pick that ran, fast-forwarded or was continued always moves
    /// HEAD. `--allow-empty` keeps an emptied commit amendable.
    func todo(git: String = "git", helperFile: (String) -> String) -> String {
        let git = git == "git" ? git : Self.shellQuoted(git)
        var lines: [String] = []
        var rewords = 0
        for entry in entries {
            let subject = entry.subject.components(separatedBy: .newlines).joined(separator: " ")
            if entry.action == .reword {
                let head = Self.shellQuoted(helperFile("head-\(rewords)"))
                let message = Self.shellQuoted(helperFile(Self.messageFileName(rewords)))
                lines.append("exec \(git) rev-parse HEAD > \(head)")
                lines.append("pick \(entry.commit) \(subject)")
                lines.append("exec test \"$(\(git) rev-parse HEAD)\" = \"$(cat \(head))\""
                             + " || \(git) commit --amend --no-edit --allow-empty -F \(message)")
                rewords += 1
            } else {
                lines.append("\(entry.action.rawValue) \(entry.commit) \(subject)")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// The helper file holding the `index`th reword's message.
    static func messageFileName(_ index: Int) -> String { "message-\(index)" }

    /// Each reword's message, in todo order: what `messageFileName(n)` holds.
    var rewordMessages: [String] {
        entries.filter { $0.action == .reword }.map { $0.message ?? "" }
    }

    /// `text` in single quotes for `sh`, each `'` written `'\''`.
    static func shellQuoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
