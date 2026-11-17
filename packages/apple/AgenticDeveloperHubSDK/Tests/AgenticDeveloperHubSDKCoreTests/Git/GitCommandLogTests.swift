import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// Covers `GitCommandLog.redactedArguments`, the pure function that decides what
/// an argument list looks like once it reaches the log.
///
/// It is tested directly rather than through `GitClient`: the redaction rule is
/// about a list of strings, and asserting it by spawning git and then reading
/// the unified log back would test OSLog's delivery rather than the rule. The
/// argument lists below are copied from `GitClient`'s own call sites, so a verb
/// that changes its arguments breaks a test here rather than leaking quietly.
@Suite("GitCommandLog.redactedArguments")
struct GitCommandLogTests {
    @Test("a non-config verb is passed through untouched")
    func nonConfigVerbUntouched() {
        let arguments = ["status", "--porcelain=v1", "-uall", "--ignore-submodules"]
        #expect(GitCommandLog.redactedArguments(verb: "status", arguments: arguments) == arguments)
    }

    @Test("a config verb that only names a key keeps every argument")
    func configReadsKeepTheirArguments() {
        // `globalConfig()` — all flags, so there is no key and nothing follows one.
        let list = ["--global", "--list", "--null"]
        #expect(GitCommandLog.redactedArguments(verb: "config", arguments: list) == list)

        // `unsetGlobalConfig(key:)` — the key is last, so nothing follows it.
        let unset = ["--global", "--unset", "user.email"]
        #expect(GitCommandLog.redactedArguments(verb: "config", arguments: unset) == unset)
    }

    @Test("a config write redacts the value and keeps its length")
    func configWriteRedactsTheValue() {
        // `setGlobalConfig(key:value:)`.
        let redacted = GitCommandLog.redactedArguments(
            verb: "config",
            arguments: ["--global", "user.email", "someone@example.com"]
        )
        #expect(redacted == ["--global", "user.email", "<redacted:19>"])
    }

    @Test("everything after the key is redacted, flag-shaped or not")
    func redactionIsPositionalNotShapeBased() {
        let redacted = GitCommandLog.redactedArguments(
            verb: "config",
            arguments: ["--global", "core.pager", "--dash-leading-value", "trailing"]
        )
        #expect(redacted == ["--global", "core.pager", "<redacted:20>", "<redacted:8>"])
    }

    @Test("a dash-leading key does not hand the log the secret that follows it")
    func aDashLeadingKeyDoesNotLeakItsValue() {
        // The old scan took the first argument that did not begin with `-` to
        // be the key. A key beginning with `-` is not a key at all, so that
        // scan walked past it and landed on the *value* — which was then kept
        // and logged at `.public`, in clear text.
        let redacted = GitCommandLog.redactedArguments(
            verb: "config",
            arguments: ["--global", "-x.token", "s3cr3t"]
        )
        #expect(redacted == ["--global", "-x.token", "<redacted:6>"])
    }

    @Test("an argument that is neither a flag nor a key is redacted, not kept")
    func anUnrecognisedArgumentIsRedacted() {
        // A bare word is not a well-formed config key, so this parser has met
        // a shape it does not model. The safe reading is that it is data.
        let redacted = GitCommandLog.redactedArguments(
            verb: "config",
            arguments: ["--global", "email", "someone@example.com"]
        )
        #expect(redacted == ["--global", "<redacted:5>", "<redacted:19>"])
    }

    @Test("commit, tag and stash messages after -m are redacted; other arguments kept")
    func messagesAreRedacted() {
        #expect(GitCommandLog.redactedArguments(
            verb: "commit", arguments: ["--cleanup=whitespace", "-m", "secret token", "--amend"]
        ) == ["--cleanup=whitespace", "-m", "<redacted:12>", "--amend"])
        #expect(GitCommandLog.redactedArguments(
            verb: "tag", arguments: ["-a", "v1", "-m", "notes", "abc123"]
        ) == ["-a", "v1", "-m", "<redacted:5>", "abc123"])
        #expect(GitCommandLog.redactedArguments(
            verb: "stash", arguments: ["push", "--include-untracked", "-m", "wip"]
        ) == ["push", "--include-untracked", "-m", "<redacted:3>"])
        #expect(GitCommandLog.redactedArguments(verb: "tag", arguments: ["v1", "abc123"]) == ["v1", "abc123"])
    }

    @Test("cherry-pick's and revert's -m is a mainline number and is kept")
    func mainlineIsKept() {
        let arguments = ["-m", "1", "abc123"]
        #expect(GitCommandLog.redactedArguments(verb: "cherry-pick", arguments: arguments) == arguments)
        #expect(GitCommandLog.redactedArguments(verb: "revert", arguments: ["--no-edit"] + arguments)
                == ["--no-edit"] + arguments)
    }

    @Test("an empty argument list is returned as-is")
    func emptyArguments() {
        #expect(GitCommandLog.redactedArguments(verb: "config", arguments: []).isEmpty)
    }
}

/// The command log's ring, its stream, the URL user-info rule and the standard-error
/// rule. Each test keeps its own `GitCommandLogBook`, so the git calls every other
/// suite makes into the shared one cannot land in the middle of an assertion.
@Suite("GitCommandLog ring")
struct GitCommandLogRingTests {
    private static let caller = GitCaller(file: "Tests.swift", function: "test()")

    private static func record(
        in book: GitCommandLogBook, verb: String = "status", arguments: [String] = [],
        exitStatus: Int32? = 0, standardError: String? = nil
    ) {
        GitCommandLog.record(
            in: book, tool: "git", verb: verb, arguments: arguments,
            directory: URL(fileURLWithPath: "/tmp/repo"), caller: caller,
            duration: 0.012, exitStatus: exitStatus, standardError: standardError)
    }

    @Test("the shared ring holds 500")
    func sharedCapacity() {
        #expect(GitCommandLog.capacity == 500)
        #expect(GitCommandLog.book.capacity == 500)
    }

    @Test("the ring keeps the last capacity entries, oldest first")
    func ringKeepsTheLast() {
        let book = GitCommandLogBook(capacity: 500)
        for index in 0..<520 {
            Self.record(in: book, arguments: ["\(index)"])
        }
        let entries = book.entries()
        #expect(entries.count == 500)
        #expect(entries.first?.arguments == ["status", "20"])
        #expect(entries.last?.arguments == ["status", "519"])
        #expect(entries.map(\.id) == entries.map(\.id).sorted())
    }

    @Test("an entry carries the tool, verb first, directory, caller, duration and status")
    func entryFields() throws {
        let book = GitCommandLogBook(capacity: 4)
        GitCommandLog.record(
            in: book, tool: "gh", verb: "pr", arguments: ["list"], directory: URL(fileURLWithPath: "/tmp/repo"),
            caller: Self.caller, duration: 0.25, exitStatus: 0, standardError: nil)
        let entry = try #require(book.entries().first)
        #expect(entry.tool == "gh")
        #expect(entry.arguments == ["pr", "list"])
        #expect(entry.commandLine == "gh pr list")
        #expect(entry.directory == "/tmp/repo")
        #expect(entry.caller == "Tests.swift:test()")
        #expect(entry.duration == .milliseconds(250))
        #expect(entry.exitStatus == 0)
    }

    @Test("updates yields each new entry in order")
    func updatesYieldEachEntry() async {
        let book = GitCommandLogBook(capacity: 10)
        Self.record(in: book, arguments: ["before"])
        let stream = book.updates()
        Self.record(in: book, arguments: ["one"])
        Self.record(in: book, arguments: ["two"])
        var seen: [[String]] = []
        for await entry in stream {
            seen.append(entry.arguments)
            if seen.count == 2 { break }
        }
        #expect(seen == [["status", "one"], ["status", "two"]])
    }

    @Test("a push URL's user info is redacted, its host kept")
    func pushURLUserInfoRedacted() throws {
        let book = GitCommandLogBook(capacity: 4)
        Self.record(in: book, verb: "push", arguments: ["https://someone:ghp_s3cr3t@github.com/o/r.git", "main"])
        let entry = try #require(book.entries().first)
        #expect(entry.arguments == ["push", "https://***@github.com/o/r.git", "main"])
        #expect(!entry.commandLine.contains("s3cr3t"))
        #expect(GitCommandLog.redactedArguments(verb: "remote", arguments: ["add", "o", "ssh://u@h/r"])
                == ["add", "o", "ssh://***@h/r"])
        #expect(GitCommandLog.redactedArguments(verb: "fetch", arguments: ["https://github.com/o/r"])
                == ["https://github.com/o/r"])
    }

    @Test("the authority ends at ? and #, so an @ in a query or fragment is not user info")
    func urlAuthorityEndsAtQueryAndFragment() {
        #expect(GitCommandLog.redactedURLUserInfo("https://host/?a=b@c") == "https://host/?a=b@c")
        #expect(GitCommandLog.redactedURLUserInfo("https://host?a=b@c") == "https://host?a=b@c")
        #expect(GitCommandLog.redactedURLUserInfo("https://host#x@y") == "https://host#x@y")
        #expect(GitCommandLog.redactedURLUserInfo("https://u:t@host?q=1@2") == "https://***@host?q=1@2")
    }

    @Test("standard error is kept only when the exit status is not 0")
    func standardErrorOnlyOnFailure() {
        let book = GitCommandLogBook(capacity: 4)
        Self.record(in: book, exitStatus: 0, standardError: "warning: ignored")
        Self.record(in: book, exitStatus: nil, standardError: "timed out")
        Self.record(in: book, exitStatus: 128, standardError: "fatal: https://u:tok@host/r not found")
        let entries = book.entries()
        #expect(entries[0].standardError == nil)
        #expect(entries[1].standardError == nil)
        #expect(entries[2].standardError == "fatal: https://***@host/r not found")
    }

    @Test("kept standard error is cut to the first 2 KB on a character boundary")
    func standardErrorTruncated() throws {
        let book = GitCommandLogBook(capacity: 4)
        Self.record(in: book, exitStatus: 1, standardError: String(repeating: "é", count: 3000))
        let kept = try #require(book.entries().first?.standardError)
        #expect(kept.utf8.count == 2048)
    }

    @Test("standard error is redacted before it is cut, so a token across the cut never survives")
    func standardErrorRedactedBeforeTruncating() throws {
        let book = GitCommandLogBook(capacity: 4)
        let url = "https://user:ghp_secrettoken@example.com/repo.git"
        // The cut at 2048 bytes lands inside the user info, between "ghp_sec" and "rettoken".
        let filler = String(repeating: "x", count: 2048 - "https://user:ghp_sec".utf8.count)
        Self.record(in: book, exitStatus: 128, standardError: filler + url + "\nfatal: denied")
        let kept = try #require(book.entries().first?.standardError)
        #expect(kept.utf8.count <= 2048)
        #expect(!kept.contains("user:"))
        #expect(!kept.contains("ghp_"))
        #expect(kept.hasPrefix(filler + "https://"))
    }
}
