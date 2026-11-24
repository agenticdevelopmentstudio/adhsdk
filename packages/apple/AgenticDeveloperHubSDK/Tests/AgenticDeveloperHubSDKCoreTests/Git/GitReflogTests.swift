import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `GitReflogEntry.parse(reflog:)` (recipe `foundation/git/git-client`, "Reflog"): each
/// `-z` record is selector, sha, subject and epoch; the subject splits at its first ": ".
@Suite("GitReflogEntry parsing")
struct GitReflogTests {
    private static let unit = "\u{1F}"

    private static func record(_ selector: String, _ sha: Character, _ subject: String, _ epoch: Int) -> String {
        [selector, String(repeating: sha, count: 40), subject, "\(epoch)"].joined(separator: unit) + "\0"
    }

    private static let output = [
        record("HEAD@{0}", "e", "rebase (finish): returning to refs/heads/feature", 1_767_268_805),
        record("HEAD@{1}", "d", "checkout: moving from main to feature", 1_767_268_804),
        record("HEAD@{2}", "c", "commit (amend): fix: the typo", 1_767_268_803),
        record("HEAD@{3}", "b", "commit: two", 1_767_268_802),
        record("HEAD@{4}", "a", "commit (initial): one", 1_767_268_801)
    ].joined()

    @Test("a commit, an amend, a checkout and a rebase finish, newest first")
    func actionsAndMessages() {
        let entries = GitReflogEntry.parse(reflog: Self.output)
        #expect(entries.map(\.selector) == ["HEAD@{0}", "HEAD@{1}", "HEAD@{2}", "HEAD@{3}", "HEAD@{4}"])
        #expect(entries.map(\.action) == [
            "rebase (finish)", "checkout", "commit (amend)", "commit", "commit (initial)"
        ])
        #expect(entries.map(\.message) == [
            "returning to refs/heads/feature", "moving from main to feature", "fix: the typo", "two", "one"
        ])
        #expect(entries[0].date == Date(timeIntervalSince1970: 1_767_268_805))
        #expect(entries[0].id == "HEAD@{0}")
        #expect(entries[3].shortSha == "bbbbbbbb")
    }

    @Test("a message holding \": \" keeps everything after the first one")
    func messageWithColon() {
        let entries = GitReflogEntry.parse(reflog: Self.record("HEAD@{0}", "a", "commit: fix: a: b", 1))
        #expect(entries.first?.action == "commit")
        #expect(entries.first?.message == "fix: a: b")
    }

    @Test("each entry's previous sha is the next record's, and the oldest has none")
    func previousSha() {
        let entries = GitReflogEntry.parse(reflog: Self.output)
        #expect(entries[0].previousSha == String(repeating: "d", count: 40))
        #expect(entries[3].previousSha == String(repeating: "a", count: 40))
        #expect(entries[4].previousSha == nil)
    }

    @Test("a subject with no \": \" is all action and no message")
    func subjectWithoutSeparator() {
        let entries = GitReflogEntry.parse(reflog: Self.record("HEAD@{0}", "a", "reset", 1))
        #expect(entries.first?.action == "reset")
        #expect(entries.first?.message == "")
    }

    @Test("a record that cannot be read is dropped; empty output is no entries")
    func unreadable() {
        #expect(GitReflogEntry.parse(reflog: "").isEmpty)
        let broken = "HEAD@{0}\(Self.unit)abc\0" + Self.record("HEAD@{1}", "b", "commit: two", 2)
        #expect(GitReflogEntry.parse(reflog: broken).map(\.selector) == ["HEAD@{1}"])
    }

    @Test("the undo target is the first entry whose commit differs from the tip")
    func undoTargetSkipsSameSha() {
        let raw = Self.record("main@{0}", "e", "reset: moving to HEAD", 3)
            + Self.record("main@{1}", "e", "commit: three", 2)
            + Self.record("main@{2}", "d", "commit: two", 1)
        let entries = GitReflogEntry.parse(reflog: raw)
        let tip = String(repeating: "e", count: 40)
        let state = GitUndoState(ref: "refs/heads/main", tip: tip, entries: entries)
        #expect(state.last?.selector == "main@{0}")
        #expect(state.target?.selector == "main@{2}")
        #expect(GitUndoState(ref: "refs/heads/main", tip: nil, entries: entries).target == nil)
        #expect(GitUndoState(ref: "HEAD", tip: tip, entries: Array(entries.prefix(2))).target == nil)
        #expect(GitUndoState.empty.target == nil)
        let preflight = GitUndoPreflight(state: state, operation: .none, isDirty: false)
        #expect(preflight.target?.selector == "main@{2}")
        let conflicted = GitUndoPreflight(state: state, operation: .none, isDirty: true, hasConflicts: true)
        #expect(conflicted.target == nil)
    }
}
