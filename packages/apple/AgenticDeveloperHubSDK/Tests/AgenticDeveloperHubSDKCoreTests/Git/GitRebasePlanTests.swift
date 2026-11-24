import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitRebasePlan: validation and the todo it writes")
struct GitRebasePlanTests {
    private func plan(_ actions: [GitRebaseEntry.Action], message: String? = nil) -> GitRebasePlan {
        GitRebasePlan(onto: "aaaa000", entries: actions.enumerated().map { index, action in
            GitRebaseEntry(commit: "bbbb00\(index)", subject: "subject \(index)", action: action, message: message)
        })
    }

    @Test("a plan git would run has no validation error")
    func valid() {
        #expect(plan([.pick, .squash, .fixup, .reword, .edit, .drop], message: "new").validationError == nil)
        #expect(plan([.drop, .pick, .fixup]).validationError == nil)
    }

    @Test("every entry dropped, or none at all, is refused")
    func everythingDropped() {
        #expect(plan([.drop, .drop]).validationError == "Every commit is dropped, so there is nothing to rebase.")
        #expect(plan([]).validationError == "Every commit is dropped, so there is nothing to rebase.")
    }

    @Test("the first kept entry cannot be a squash or a fixup")
    func firstSquashOrFixup() {
        let reason = "The first commit cannot be squashed or fixed up: there is no earlier commit to fold it into."
        #expect(plan([.squash, .pick]).validationError == reason)
        #expect(plan([.fixup]).validationError == reason)
        #expect(plan([.drop, .squash]).validationError == reason)
    }

    @Test("a reword needs a message that is not only whitespace")
    func rewordNeedsAMessage() {
        #expect(plan([.reword]).validationError == "A reworded commit needs a message.")
        #expect(plan([.reword], message: " \n\t").validationError == "A reworded commit needs a message.")
        #expect(plan([.pick, .drop], message: nil).validationError == nil)
    }

    @Test("a commit that is not a hex object name is invalid")
    func invalidCommits() {
        #expect(plan([.pick]).invalidCommit == nil)
        let bad = ["abc", "abcg123", "abc1234\nexec rm -rf /", String(repeating: "a", count: 65), "１２３４"]
        for commit in bad {
            let candidate = GitRebasePlan(onto: "aaaa", entries: [GitRebaseEntry(commit: commit, subject: "s")])
            #expect(candidate.invalidCommit == commit)
        }
    }

    @Test("the todo: one line per entry, a reword as a pick between a HEAD record and a guarded amend")
    func todo() {
        var entries = plan([.pick, .reword, .squash, .fixup, .edit, .drop, .reword], message: "m").entries
        entries[0].subject = "two\nlines"
        let candidate = GitRebasePlan(onto: "aaaa000", entries: entries)
        let todo = candidate.todo { "/tmp/it's/\($0)" }
        let dir = "'/tmp/it'\\''s/"
        let amend = " || git commit --amend --no-edit --allow-empty -F "
        #expect(todo == """
            pick bbbb000 two lines
            exec git rev-parse HEAD > \(dir)head-0'
            pick bbbb001 subject 1
            exec test "$(git rev-parse HEAD)" = "$(cat \(dir)head-0')"\(amend)\(dir)message-0'
            squash bbbb002 subject 2
            fixup bbbb003 subject 3
            edit bbbb004 subject 4
            drop bbbb005 subject 5
            exec git rev-parse HEAD > \(dir)head-1'
            pick bbbb006 subject 6
            exec test "$(git rev-parse HEAD)" = "$(cat \(dir)head-1')"\(amend)\(dir)message-1'

            """)
        #expect(candidate.rewordMessages == ["m", "m"])

        let configured = GitRebasePlan(onto: "aaaa000", entries: [entries[1]])
            .todo(git: "/opt/my git/bin/git") { "/h/\($0)" }
        #expect(configured == """
            exec '/opt/my git/bin/git' rev-parse HEAD > '/h/head-0'
            pick bbbb001 subject 1
            exec test "$('/opt/my git/bin/git' rev-parse HEAD)" = "$(cat '/h/head-0')" \
            || '/opt/my git/bin/git' commit --amend --no-edit --allow-empty -F '/h/message-0'

            """)
    }

    @Test("shell quoting wraps in single quotes and escapes each one")
    func shellQuoting() {
        #expect(GitRebasePlan.shellQuoted("plain") == "'plain'")
        #expect(GitRebasePlan.shellQuoted("a'b c") == "'a'\\''b c'")
    }
}
