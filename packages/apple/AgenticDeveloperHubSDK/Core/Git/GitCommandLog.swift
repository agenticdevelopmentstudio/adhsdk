import Foundation
import OSLog
import os

/// One recorded invocation of `git` or `gh`, as the in-app command log shows it.
public struct GitCommandLogEntry: Sendable, Hashable, Identifiable {
    /// Increasing in recording order, unique within its book.
    public let id: UInt64
    public let date: Date
    /// The executable run: `"git"` or `"gh"`.
    public let tool: String
    /// What was spawned after the tool, in order and redacted: `-c key=value` per
    /// config override, the verb, then its arguments.
    public let arguments: [String]
    /// The working directory's path, or `""` when there was none.
    public let directory: String
    /// `<file>:<function>` of the caller.
    public let caller: String
    public let duration: Duration
    /// nil when the process produced no exit status: timed out, cancelled, never launched.
    public let exitStatus: Int32?
    /// The first 2 KB of standard error, URL user info redacted, kept only when the
    /// process exited with a status other than 0.
    public let standardError: String?

    public init(id: UInt64, date: Date, tool: String, arguments: [String], directory: String, caller: String,
                duration: Duration, exitStatus: Int32?, standardError: String?) {
        self.id = id
        self.date = date
        self.tool = tool
        self.arguments = arguments
        self.directory = directory
        self.caller = caller
        self.duration = duration
        self.exitStatus = exitStatus
        self.standardError = standardError
    }

    /// The command as it ran: `git -c key=value <verb> <arguments>`, redacted.
    public var commandLine: String { ([tool] + arguments).joined(separator: " ") }

    /// True when the process finished with status 0.
    public var succeeded: Bool { exitStatus == 0 }
}

/// A bounded, thread-safe ring of command log entries with a stream of each new one.
///
/// `GitCommandLog` keeps the process's one book; tests and views make their own so
/// they are not at the mercy of every other git call in the process. Recording takes
/// one unfair lock and never hops to an actor, so `GitClient`'s bottleneck pays for
/// an append and nothing more.
public final class GitCommandLogBook: Sendable {

    public let capacity: Int

    private struct State {
        var ring: [GitCommandLogEntry] = []
        /// Where the oldest entry sits once the ring is full.
        var start = 0
        var nextID: UInt64 = 1
        var nextSubscriber = 0
        var subscribers: [Int: AsyncStream<GitCommandLogEntry>.Continuation] = [:]
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    public init(capacity: Int) {
        precondition(capacity > 0, "a command log holds at least one entry")
        self.capacity = capacity
    }

    /// Appends an entry made from the fields, numbered here, dropping the oldest
    /// when full, and yields it to every `updates()` stream. Returns it.
    @discardableResult
    public func append(
        tool: String, arguments: [String], directory: String, caller: String,
        duration: Duration, exitStatus: Int32?, standardError: String?, date: Date = Date()
    ) -> GitCommandLogEntry {
        let (entry, subscribers) = state.withLock { state in
            let entry = GitCommandLogEntry(
                id: state.nextID, date: date, tool: tool, arguments: arguments, directory: directory,
                caller: caller, duration: duration, exitStatus: exitStatus, standardError: standardError)
            state.nextID += 1
            if state.ring.count < capacity {
                state.ring.append(entry)
            } else {
                state.ring[state.start] = entry
                state.start = (state.start + 1) % capacity
            }
            return (entry, Array(state.subscribers.values))
        }
        // Yielded outside the lock: each continuation guards its own buffer.
        for subscriber in subscribers { subscriber.yield(entry) }
        return entry
    }

    /// Every entry held, oldest first.
    public func entries() -> [GitCommandLogEntry] {
        state.withLock { state in
            Array(state.ring[state.start...]) + Array(state.ring[..<state.start])
        }
    }

    /// Each entry appended from now on, in order, until the stream is dropped.
    public func updates() -> AsyncStream<GitCommandLogEntry> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: GitCommandLogEntry.self, bufferingPolicy: .bufferingNewest(capacity))
        let key = state.withLock { state in
            let key = state.nextSubscriber
            state.nextSubscriber += 1
            state.subscribers[key] = continuation
            return key
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLock { state in _ = state.subscribers.removeValue(forKey: key) }
        }
        return stream
    }
}

/// The one place every git invocation is recorded.
///
/// It records **that** a git call happened and where it came from — verb,
/// arguments, working directory, calling file and function, duration, exit
/// status — twice: as one OSLog line, and as an entry in the in-memory ring the
/// Git window's command log shows (`book`, the last `capacity` calls).
///
/// The OSLog line carries **no command output**: neither stdout nor stderr
/// reaches it. A repository's contents, a diff and a branch listing are the
/// caller's to handle; what belongs in the unified log is the fact of the call,
/// so git usage can be counted, attributed and audited without the log becoming
/// a copy of the repository. The in-memory entry adds one thing: the first 2 KB
/// of standard error of a call that exited non-zero, URL user info redacted, so
/// the command log can say why a call failed. It never leaves the process.
public enum GitCommandLog {

    /// How many entries the shared ring keeps.
    public static let capacity = 500

    /// The bytes of standard error an entry keeps.
    static let standardErrorLimit = 2048

    /// The process's ring.
    public static let book = GitCommandLogBook(capacity: capacity)

    /// Records one invocation. `exitStatus` is `nil` when the process produced
    /// no exit status at all — it timed out, it was cancelled, it never
    /// launched, or its output channel failed. `tool` is the executable
    /// (`"git"`, or `"gh"`); `standardError` is kept, trimmed, only when
    /// `exitStatus` is a status other than 0, and only in the ring.
    /// `configOverrides` are the `key=value` pairs spawned as `-c key=value` ahead of the
    /// verb; they are logged there, in spawn order, so the logged command is the one that ran.
    ///
    /// Arguments are logged at `.public` because they are the feature: a log
    /// that hides `--porcelain=v1 -uall` cannot answer "what did the app
    /// actually ask git to do". They pass through `redactedArguments` first,
    /// which is where the exceptions live.
    public static func record(
        tool: String = "git",
        verb: String,
        arguments: [String],
        configOverrides: [String] = [],
        directory: URL?,
        caller: GitCaller,
        duration: TimeInterval,
        exitStatus: Int32?,
        standardError: String? = nil
    ) {
        record(in: book, tool: tool, verb: verb, arguments: arguments, configOverrides: configOverrides,
               directory: directory, caller: caller, duration: duration, exitStatus: exitStatus,
               standardError: standardError)
    }

    /// `record` into `book` — the shared one, or a test's own.
    static func record(
        in book: GitCommandLogBook, tool: String, verb: String, arguments: [String],
        configOverrides: [String] = [], directory: URL?,
        caller: GitCaller, duration: TimeInterval, exitStatus: Int32?, standardError: String?
    ) {
        let milliseconds = Int((duration * 1000).rounded())
        let status = exitStatus.map(String.init) ?? "unfinished"
        // Spawn order: `-c key=value` for each override, the verb, then its arguments. The
        // positional rules apply to the verb's arguments only; the URL rule to all of them.
        let overrides = configOverrides.flatMap { ["-c", redactedURLUserInfo($0)] }
        let spawned = overrides + [verb] + redactedArguments(tool: tool, verb: verb, arguments: arguments)
        let joinedArguments = spawned.joined(separator: " ")
        let path = directory?.path ?? "-"
        logger.info(
            """
            \(tool, privacy: .public) \(joinedArguments, privacy: .public) \
            cwd=\(path, privacy: .public) \
            from=\(caller.file, privacy: .public):\(caller.function, privacy: .public) \
            \(milliseconds, privacy: .public)ms status=\(status, privacy: .public)
            """
        )
        let failed = exitStatus.map { $0 != 0 } ?? false
        book.append(
            tool: tool, arguments: spawned, directory: directory?.path ?? "",
            caller: "\(caller.file):\(caller.function)",
            duration: .milliseconds(max(milliseconds, 0)), exitStatus: exitStatus,
            standardError: failed ? standardError.map(keptStandardError) : nil)
    }

    /// Every entry the shared ring holds, oldest first.
    public static func entries() -> [GitCommandLogEntry] { book.entries() }

    /// Each entry recorded in the shared ring from now on.
    public static func updates() -> AsyncStream<GitCommandLogEntry> { book.updates() }

    /// `standardError` with URL user info redacted, then cut to its first
    /// `standardErrorLimit` UTF-8 bytes on a character boundary. Redacting first is
    /// the point: a cut inside `user:token@` would leave no `@` for the rule to find.
    static func keptStandardError(_ standardError: String) -> String {
        var kept = ""
        var bytes = 0
        for character in redactedURLUserInfo(standardError) {
            bytes += character.utf8.count
            if bytes > standardErrorLimit { break }
            kept.append(character)
        }
        return kept
    }

    /// `text` with the user info of every URL in it (`https://user:token@host`)
    /// replaced by `***`, so a token embedded in a remote URL never reaches a log.
    /// The authority runs from `://` to the next `/`, `?`, `#`, whitespace or quote; the user
    /// info is everything in it before its last `@`.
    static func redactedURLUserInfo(_ text: String) -> String {
        guard text.contains("://") else { return text }
        var result = ""
        var rest = Substring(text)
        while let scheme = rest.range(of: "://") {
            result += rest[..<scheme.upperBound]
            let authorityEnd = rest[scheme.upperBound...].firstIndex { character in
                "/?#\"'".contains(character) || character.isWhitespace
            } ?? rest.endIndex
            let authority = rest[scheme.upperBound..<authorityEnd]
            if let atSign = authority.lastIndex(of: "@") {
                result += "***" + authority[atSign...]
            } else {
                result += authority
            }
            rest = rest[authorityEnd...]
        }
        return result + rest
    }

    /// Replaces argument positions that carry user data with
    /// `<redacted:<length>>`, keeping the length visible so a log still shows
    /// that *something* was passed and how big it was.
    ///
    /// This lives in the funnel, not at the call sites, on purpose. Redacting
    /// where a verb is written would split the arguments git is spawned with
    /// from the arguments the log is handed — a new way for the two to drift
    /// apart silently — and would make "remember to redact" a rule every
    /// future verb has to independently honour. One rule here is a rule none
    /// of them can forget, which is the whole premise of routing git through a
    /// single client.
    ///
    /// `OSLogPrivacy.private` is the wrong lever for the same job: it collapses
    /// the entire interpolation for every verb, so `--porcelain=v1 -uall` and
    /// `--abbrev-ref HEAD` disappear from Console too. That deletes the feature
    /// to protect one argument position.
    ///
    /// There are three rules. The first: `commit`, `tag` and `stash` carry a message after
    /// `-m` (a commit or amend message, an annotated tag's message, a stash's), which is
    /// the user's own text — a draft, a pasted token — so the argument after each `-m` is
    /// redacted. Only those verbs: cherry-pick's and revert's `-m` is a mainline number.
    ///
    /// The second: `git config`'s arguments are
    /// `[<flags>..., <key>, <value>...]`: the key names a setting and is worth
    /// seeing, everything after it is the user's own data (`user.email`, a
    /// signing key, a URL that may carry a token).
    ///
    /// The key is found by asking what a key *is*
    /// (`GitConfigEntry.isWellFormedKey`), not by taking the first argument
    /// that does not begin with `-`. Those are not the same question, and the
    /// difference leaked secrets: an argument beginning with `-` is not a
    /// well-formed key, so `["--global", "-x.token", "s3cr3t"]` made the old
    /// scan skip straight past it and call the *secret* the key — logging it
    /// at `.public`. Anything that is neither a recognisable key nor a flag is
    /// redacted, so the failure mode of a shape this rule has not met is a
    /// missing argument in the log rather than a leaked one (`fail-fast`).
    /// `--list` and `--unset` forms have nothing after their key and are
    /// untouched.
    ///
    /// The third applies to every verb, after the other two: a URL's user info
    /// is replaced with `***` (`https://***@host/repo`) in any argument, so a
    /// remote added, pushed to or cloned with a token in it shows its host and
    /// never the token.
    ///
    /// For `tool` `"gh"` the positional rule is `gh`'s own: the argument after
    /// `--title`, `--body`, `-t` or `-b` (a pull request's title and body, the user's
    /// own text) is redacted, whatever the verb; git's rules do not apply to it.
    static func redactedArguments(tool: String = "git", verb: String, arguments: [String]) -> [String] {
        let positional = tool == "gh"
            ? redactedAfter(ghTextFlags, in: arguments)
            : positionallyRedacted(verb: verb, arguments: arguments)
        return positional.map(redactedURLUserInfo)
    }

    /// The `gh` flags followed by the user's own text.
    static let ghTextFlags: Set<String> = ["--title", "--body", "-t", "-b"]

    private static func positionallyRedacted(verb: String, arguments: [String]) -> [String] {
        if messageVerbs.contains(verb) { return redactedMessages(arguments) }
        guard verb == "config" else { return arguments }
        // What is tracked is the *position*, not whether a key was recognised.
        // `git config`'s grammar puts the key at the first non-flag argument,
        // so that position is spent whether or not what landed there looks
        // like a key — and an unrecognised key that left the position open
        // sent the value back through the key test, where
        // `someone@example.com` is well formed enough to be kept and logged
        // at `.public`. Passing the position once means the shapes this rule
        // does not model cost a redacted argument, never a leaked one.
        var keyPositionSpent = false
        return arguments.map { argument in
            if keyPositionSpent { return "<redacted:\(argument.count)>" }
            if argument.hasPrefix("-") { return argument }
            keyPositionSpent = true
            return GitConfigEntry.isWellFormedKey(argument) ? argument : "<redacted:\(argument.count)>"
        }
    }

    /// The verbs whose `-m` is followed by the user's message.
    static let messageVerbs: Set<String> = ["commit", "tag", "stash"]

    private static func redactedMessages(_ arguments: [String]) -> [String] {
        var redactNext = false
        return arguments.map { argument in
            if redactNext {
                redactNext = false
                return "<redacted:\(argument.count)>"
            }
            redactNext = argument == "-m"
            return argument
        }
    }

    /// `arguments` with the argument after each of `flags` redacted.
    private static func redactedAfter(_ flags: Set<String>, in arguments: [String]) -> [String] {
        var redactNext = false
        return arguments.map { argument in
            if redactNext {
                redactNext = false
                return "<redacted:\(argument.count)>"
            }
            redactNext = flags.contains(argument)
            return argument
        }
    }
}

extension GitCommandLog: Loggable {
    public static nonisolated let logger = makeLogger()
}
