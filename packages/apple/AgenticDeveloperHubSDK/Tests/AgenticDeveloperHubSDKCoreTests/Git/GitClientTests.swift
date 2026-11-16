import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

@Suite("GitClient", .serialized)
struct GitClientTests {
    /// A fresh repository with one commit on `main`, one worktree on `feature`, and a modified file.
    private struct Fixture {
        let repository: GitTestRepository
        var root: URL { repository.root }
        var worktree: URL { repository.url("wt-feature") }

        static func make() async throws -> Fixture {
            let repository = try await GitTestRepository.make(prefix: "git-client-test")
            do {
                try repository.write("one\n", to: "a.txt")
                try await repository.run(["add", "a.txt"])
                try await repository.run(["commit", "-m", "initial"])
                try await repository.run(["worktree", "add", "-b", "feature", repository.url("wt-feature").path])
                try repository.write("two\n", to: "a.txt")
                return Fixture(repository: repository)
            } catch {
                repository.tearDown()
                throw error
            }
        }

        func tearDown() {
            repository.tearDown()
        }
    }

    /// Redirects `--global` reads and writes at a throwaway file for the life of one
    /// test, via `GitClientConfiguration.extraEnvironment` rather than `setenv`.
    ///
    /// This is what makes the three global-config verbs testable without touching the
    /// developer's own `~/.gitconfig`. It works because `GitClient` spawns git with
    /// `SubprocessChannel`'s `.mergeOverParent` policy, which merges the configuration's
    /// own overrides *over* the parent's environment — so `GIT_CONFIG_GLOBAL` set in
    /// `extraEnvironment` reaches the child without ever touching this process's own
    /// `environ`.
    ///
    /// An earlier version of this fixture called `setenv("GIT_CONFIG_GLOBAL", …)`
    /// directly, mutating process-wide state and relying on `.serialized` above to keep
    /// it safe — but `.serialized` only orders the tests *inside this suite*, and
    /// swift-testing runs other suites in this same target (`SubprocessChannelTests`,
    /// `MCPClientRaceTests`) concurrently with this one. Those suites spawn children that
    /// read `ProcessInfo.processInfo.environment`, so a `setenv` here could race a
    /// concurrent read of `environ` (a use-after-free presenting as an intermittent
    /// runner crash) and could leak `GIT_CONFIG_GLOBAL` into an unrelated child pointed at
    /// a directory this fixture's `tearDown()` then deletes (review A M4 / parked Task 1
    /// F10). Carrying the redirect on the `GitClientConfiguration` instance instead makes
    /// it travel with the one client this test owns and invisible to every other suite —
    /// `.serialized` is no longer load-bearing for that reason, though it is left in place
    /// since the tests in this suite still share one real `git` binary and disk fixtures.
    private struct IsolatedGlobalConfig {
        let directory: URL
        let file: URL

        /// Seeds the redirected file with one entry, so a read test does not depend on
        /// a write test having run first.
        static let seededKey = "atkgitclienttest.seeded"
        static let seededValue = "seeded-value"

        init() throws {
            directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("git-client-global-config-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            file = directory.appendingPathComponent("config")
            try "[atkgitclienttest]\n\tseeded = \(Self.seededValue)\n"
                .write(to: file, atomically: true, encoding: .utf8)
        }

        func tearDown() {
            try? FileManager.default.removeItem(at: directory)
        }

        /// A `GitClientConfiguration` whose child processes see this redirected file as
        /// `GIT_CONFIG_GLOBAL`, via `extraEnvironment` rather than a process-wide `setenv`.
        var configuration: GitClientConfiguration {
            GitClientConfiguration(extraEnvironment: ["GIT_CONFIG_GLOBAL": file.path])
        }

        /// The developer's real global config, read only so a test can assert it was
        /// left alone.
        ///
        /// Three outcomes, kept apart on purpose. An earlier version returned
        /// `Data?` and folded "no such file" and "could not be read" together into
        /// `nil`, which made the safety assertion pass by saying `nil == nil` on any
        /// machine where the file was unreadable — the one case where it most needed
        /// to speak up.
        enum RealGlobalConfig: Equatable {
            case absent
            case contents(Data)
            case unreadable(String)

            static func read() -> RealGlobalConfig {
                let url = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".gitconfig")
                guard FileManager.default.fileExists(atPath: url.path) else { return .absent }
                do {
                    return .contents(try Data(contentsOf: url))
                } catch {
                    return .unreadable(error.localizedDescription)
                }
            }
        }
    }

    @Test("the global-config redirect is in effect, so the safety assertions mean something")
    func globalConfigRedirectIsInEffect() async throws {
        let isolated = try IsolatedGlobalConfig()
        defer { isolated.tearDown() }

        // Exactly the seeded entry and nothing else. This is what makes the two
        // "must be untouched" assertions below non-vacuous: the seeded key exists
        // only in the redirected file, and any key from the developer's own
        // `~/.gitconfig` — a `user.name`, an alias — would show up here if git were
        // still reading it.
        let entries = try await GitClient(configuration: isolated.configuration).globalConfig()
        #expect(entries.map(\.key) == [IsolatedGlobalConfig.seededKey])
    }

    @Test("status reports the modified file")
    func status() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        let status = try await client.status(in: fixture.root)
        #expect(status.files["a.txt"] == .modified)
    }

    @Test("run executes a verb no typed method models and returns its output")
    func runUnmodelledVerb() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        let subject = try await client.run("log", ["-1", "--format=%s"], in: fixture.root)
        #expect(subject.trimmingCharacters(in: .whitespacesAndNewlines) == "initial")
    }

    @Test("run reports a non-zero exit as commandFailed with its status")
    func runFailureCarriesStatus() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        do {
            _ = try await client.run("merge-base", ["--is-ancestor", "feature", "HEAD~5"], in: fixture.root)
            Issue.record("expected a failure")
        } catch let error as GitClientError {
            guard case let .commandFailed(verb, status, _) = error else {
                Issue.record("unexpected \(error)")
                return
            }
            #expect(verb == "merge-base")
            #expect(status != 0)
        }
    }

    @Test("a failed call reaches the command log with its standard error; a success without it")
    func commandLogKeepsStandardErrorOfAFailure() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        _ = try? await client.run("rev-parse", ["--verify", "refs/heads/no-such-branch"], in: fixture.root)
        _ = try await client.run("rev-parse", ["HEAD"], in: fixture.root)
        // The shared ring takes every suite's calls; this fixture's directory is its own.
        let mine = GitCommandLog.entries().filter { entry in
            entry.directory == fixture.root.path && entry.arguments.first == "rev-parse"
        }
        let failed = try #require(mine.first { $0.arguments.contains("refs/heads/no-such-branch") })
        #expect(failed.exitStatus != 0)
        #expect(failed.standardError?.isEmpty == false)
        let succeeded = try #require(mine.first { $0.arguments == ["rev-parse", "HEAD"] })
        #expect(succeeded.exitStatus == 0)
        #expect(succeeded.standardError == nil)
    }

    @Test("a write's config overrides are logged ahead of the verb, as spawned, message redacted")
    func commandLogKeepsSpawnOrder() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-client-spawn-order-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let argvLog = directory.appendingPathComponent("argv.log")
        let script = directory.appendingPathComponent("argv-git")
        try "#!/bin/sh\necho \"$*\" >> \"$ARGV_LOG\"\n".write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let client = GitClient(configuration: GitClientConfiguration(
            executableURL: script, timeout: 10, extraEnvironment: ["ARGV_LOG": argvLog.path]))

        // The stand-in prints nothing, so the rebase-helper probe after the commit may throw.
        _ = try? await client.perform(.commit(message: "secret", amend: false), in: directory)

        let spawned = try #require(try String(contentsOf: argvLog, encoding: .utf8)
            .split(separator: "\n").map(String.init).first { $0.contains(" commit ") })
        #expect(spawned.hasPrefix("-c core.editor=true commit "))
        let entry = try #require(GitCommandLog.entries().first { entry in
            entry.directory == directory.path && entry.arguments.contains("commit")
        })
        #expect(Array(entry.arguments.prefix(3)) == ["-c", "core.editor=true", "commit"])
        #expect(entry.commandLine == "git " + spawned.replacingOccurrences(of: "secret", with: "<redacted:6>"))
    }

    @Test("currentBranch names the checked-out branch")
    func currentBranch() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        #expect(try await client.currentBranch(in: fixture.root) == "main")
        #expect(try await client.currentBranch(in: fixture.worktree) == "feature")
    }

    @Test("branches lists both branches and marks the current one")
    func branches() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        let branches = try await client.branches(in: fixture.root)
        #expect(Set(branches.map(\.name)) == ["main", "feature"])
        #expect(branches.first { $0.name == "main" }?.isCurrent == true)
    }

    @Test("worktrees lists the main checkout first, then the worktree")
    func worktrees() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        let trees = try await client.worktrees(in: fixture.root)
        #expect(trees.count == 2)
        #expect(trees[0].isMain)
        #expect(trees[0].branch == "main")
        #expect(trees[1].branch == "feature")
        #expect(trees[1].directory.resolvingSymlinksInPath().path
            == fixture.worktree.resolvingSymlinksInPath().path)
    }

    @Test("resolveCommit names a branch's commit, returns nil for a missing ref, and ignores a same-named tag")
    func resolveCommit() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        let client = GitClient(configuration: .default)
        let main = try await client.resolveCommit("refs/heads/main", in: fixture.root)
        #expect(main?.count == 40)
        #expect(try await client.resolveCommit("refs/heads/nope", in: fixture.root) == nil)
        #expect(try await client.resolveCommit("--nope", in: fixture.root) == nil)
        // A tag named like the branch, on a different commit.
        _ = try await client.run("commit", ["--allow-empty", "-m", "later"], in: fixture.worktree)
        _ = try await client.run("tag", ["feature", "main"], in: fixture.root)
        let branch = try await client.resolveCommit("refs/heads/feature", in: fixture.root)
        #expect(branch != main)
        #expect(try await client.resolveCommit("feature", in: fixture.root) == main)
    }

    @Test("a missing executable throws executableNotFound before spawning")
    func missingExecutable() async {
        let configuration = GitClientConfiguration(executableURL: URL(fileURLWithPath: "/nonexistent/git"))
        let client = GitClient(configuration: configuration)
        await #expect(throws: GitClientError.executableNotFound(path: "/nonexistent/git")) {
            try await client.currentBranch(in: URL(fileURLWithPath: "/"))
        }
    }

    @Test("a failing command throws commandFailed with the verb and status")
    func commandFailed() async {
        let notARepo = FileManager.default.temporaryDirectory
        let client = GitClient(configuration: .default)
        await #expect(throws: GitClientError.self) {
            try await client.status(in: notARepo.appendingPathComponent("does-not-exist-\(UUID().uuidString)"))
        }
    }

    @Test("a timeout throws timedOut")
    func timesOut() async throws {
        let fixture = try await Fixture.make()
        defer { fixture.tearDown() }
        // A one-millisecond budget: the process cannot finish in time.
        let client = GitClient(configuration: GitClientConfiguration(timeout: 0.001))
        await #expect(throws: GitClientError.timedOut(verb: "status")) {
            try await client.status(in: fixture.root)
        }
    }

    @Test("globalConfig reads the redirected global file")
    func globalConfig() async throws {
        let isolated = try IsolatedGlobalConfig()
        defer { isolated.tearDown() }
        let client = GitClient(configuration: isolated.configuration)
        let entries = try await client.globalConfig()
        let seeded = entries.first { $0.key == IsolatedGlobalConfig.seededKey }
        #expect(seeded?.value == IsolatedGlobalConfig.seededValue)
    }

    @Test("setGlobalConfig writes a key the next read sees")
    func setGlobalConfig() async throws {
        let isolated = try IsolatedGlobalConfig()
        defer { isolated.tearDown() }
        let untouchedBefore = IsolatedGlobalConfig.RealGlobalConfig.read()
        let client = GitClient(configuration: isolated.configuration)
        try await client.setGlobalConfig(key: "atkgitclienttest.added", value: "added-value")

        let entries = try await client.globalConfig()
        #expect(entries.first { $0.key == "atkgitclienttest.added" }?.value == "added-value")
        // The write landed in the redirected file, not anywhere else.
        let written = try String(contentsOf: isolated.file, encoding: .utf8)
        #expect(written.contains("added-value"))
        #expect(IsolatedGlobalConfig.RealGlobalConfig.read() == untouchedBefore,
                "the developer's real ~/.gitconfig must be untouched")
    }

    @Test("unsetGlobalConfig removes a key the next read no longer sees")
    func unsetGlobalConfig() async throws {
        let isolated = try IsolatedGlobalConfig()
        defer { isolated.tearDown() }
        let untouchedBefore = IsolatedGlobalConfig.RealGlobalConfig.read()
        let client = GitClient(configuration: isolated.configuration)
        #expect(try await client.globalConfig().contains { $0.key == IsolatedGlobalConfig.seededKey })

        try await client.unsetGlobalConfig(key: IsolatedGlobalConfig.seededKey)

        #expect(try await client.globalConfig().isEmpty)
        #expect(IsolatedGlobalConfig.RealGlobalConfig.read() == untouchedBefore,
                "the developer's real ~/.gitconfig must be untouched")
    }
}

/// Covers `GitClientError.logDescription`, the seam `GitStatusProvider` logs
/// through instead of `errorDescription`/`localizedDescription`. There is no
/// way to assert an OSLog line directly, so this is the testable shape of
/// the fix for review A's BLOCKER B1: git's own stderr must never reach the
/// unified log.
@Suite("GitClientError.logDescription")
struct GitClientErrorLogDescriptionTests {
    @Test("commandFailed's logDescription carries the verb and exit status, never standardError")
    func commandFailedNeverLeaksStandardError() {
        let error = GitClientError.commandFailed(
            verb: "status",
            exitStatus: 128,
            standardError: "fatal: detected dubious ownership in repository at '/Users/secret/repo'"
        )
        #expect(!error.logDescription.contains("secret"))
        #expect(error.logDescription.contains("status"))
        #expect(error.logDescription.contains("128"))
    }

    @Test("timedOut's logDescription carries the verb")
    func timedOutCarriesVerb() {
        let error = GitClientError.timedOut(verb: "worktree")
        #expect(error.logDescription.contains("worktree"))
    }

    @Test("launchFailed's logDescription carries the verb, never the launch reason")
    func launchFailedNeverLeaksReason() {
        let error = GitClientError.launchFailed(verb: "status", reason: "secret-path-in-the-reason")
        #expect(!error.logDescription.contains("secret"))
        #expect(error.logDescription.contains("status"))
    }

    @Test("executableNotFound's logDescription never leaks the configured path")
    func executableNotFoundNeverLeaksPath() {
        let error = GitClientError.executableNotFound(path: "/Users/secret/bin/git")
        #expect(!error.logDescription.contains("secret"))
    }
}

/// Covers review A's M1 (parked Task 1 F9, reproducing): `withWallClockBudget`
/// cancels its loser but never awaits it (`WallClockBudget.swift`'s own doc
/// comment), so a `terminate()` that arrives before `launch()` has reached
/// `process.run()` used to find `hasLaunched == false` and return having done
/// nothing — the cancelled task then went on to spawn a real child that
/// nothing terminated.
///
/// This drives the two actor calls **in the order the race produces**
/// (`terminate()` first, `launch()` second) rather than actually racing
/// `withWallClockBudget` against a real `launch()`: `launch()` is a
/// non-`async` actor method, so once either call reaches the actor it runs
/// to completion before the other can start (see `terminationRequested`'s
/// doc comment on `SubprocessChannel`), which makes "terminate() reaches the
/// actor first" the entire content of the race regardless of how close the
/// wall-clock timing is. Racing the real budget instead proved flaky: a
/// 1 ms budget does not reliably lose to `/bin/sleep 30`'s own
/// `process.run()`, which is just a fork/exec and can complete in well under
/// 1 ms. `GitClientTests.timesOut` keeps the 1 ms wall-clock race, but that
/// one only needs the *whole `status` command* — spawn plus produce output —
/// to outlast 1 ms, which is reliable.
@Suite("SubprocessChannel terminate()/launch() race")
struct SubprocessChannelTerminationRaceTests {
    @Test("a terminate() that arrives before launch() still ends the child")
    func terminateBeforeLaunchStillEndsTheChild() async throws {
        let channel = SubprocessChannel(configuration: .init(
            executableURL: URL(fileURLWithPath: "/bin/sleep"),
            arguments: ["30"]
        ))

        // `hasLaunched` is still false here, so before the fix this returned
        // having done nothing.
        await channel.terminate()

        // Before the fix, nothing had recorded the request above, so this
        // spawned a real `sleep 30` with nothing left to stop it. After the
        // fix, `launch()` finds `terminationRequested` already set and kicks
        // off the catch-up termination itself.
        try await channel.launch()

        // Bounded poll rather than a fixed sleep: the catch-up termination
        // runs on its own `Task`, not ours. 5s is generous against
        // `terminationGraceSeconds` (2s) plus the pump drain grace (0.5s);
        // before the fix this times out with `isRunning == true` — the real
        // child runs for the full 30s with nothing to stop it.
        _ = try? await withWallClockBudget(5) {
            while await channel.isRunning {
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        }
        #expect(await channel.isRunning == false, "the child must not be left running")

        // Cleanup net, independent of the assertion above: if the poll's
        // budget lapsed first, this still ends the child rather than leaving
        // a real `sleep 30` running for the rest of its 30s regardless of
        // whether the assertion just failed.
        await channel.terminate()
    }
}

/// A cancelled caller must end the git process it started, not leave it running: the
/// history search relies on this to stop a superseded `git log` (final review,
/// Important 1). The "git" here is a script that records its pid and sleeps, so the
/// test can see whether the process outlives the cancellation.
@Suite("GitClient cancellation")
struct GitClientCancellationTests {
    @Test("cancelling a running command throws CancellationError and terminates the process")
    func cancellingTerminatesTheProcess() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-client-cancel-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let script = directory.appendingPathComponent("slow-git")
        let pidFile = directory.appendingPathComponent("pid")
        try "#!/bin/sh\necho $$ > \"$SLOW_GIT_PID\"\nexec /bin/sleep 30\n"
            .write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let client = GitClient(configuration: GitClientConfiguration(
            executableURL: script, timeout: 60, extraEnvironment: ["SLOW_GIT_PID": pidFile.path]))

        let call = Task { try await client.run("log", [], in: directory) }
        var pid: pid_t?
        let started = Date()
        while pid == nil, Date().timeIntervalSince(started) < 5 {
            let text = (try? String(contentsOf: pidFile, encoding: .utf8)) ?? ""
            pid = pid_t(text.trimmingCharacters(in: .whitespacesAndNewlines))
            if pid == nil { try await Task.sleep(for: .milliseconds(20)) }
        }
        let running = try #require(pid)

        call.cancel()
        await #expect(throws: CancellationError.self) { try await call.value }

        let cancelled = Date()
        while kill(running, 0) == 0, Date().timeIntervalSince(cancelled) < 5 {
            try await Task.sleep(for: .milliseconds(50))
        }
        let alive = kill(running, 0) == 0
        if alive { kill(running, SIGKILL) }
        #expect(!alive, "the git process must not outlive its cancelled caller")
    }
}

/// git runs with its messages in English whatever the user's locale, so a caller that
/// reads one ("not fully merged") works everywhere; the character set is left alone.
/// The "git" here is a script that prints the two variables it was given.
@Suite("GitClient locale")
struct GitClientLocaleTests {
    @Test("the child gets LC_MESSAGES=C and the parent's LC_CTYPE")
    func messagesAreInEnglish() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-client-locale-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let script = directory.appendingPathComponent("env-git")
        try "#!/bin/sh\necho \"$LC_MESSAGES|$LC_CTYPE\"\n".write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let client = GitClient(configuration: GitClientConfiguration(executableURL: script, timeout: 10))

        let output = try await client.run("status", [], in: directory)

        let parentCType = ProcessInfo.processInfo.environment["LC_CTYPE"] ?? ""
        #expect(output.trimmingCharacters(in: .newlines) == "C|\(parentCType)")
        #expect(GitClient.baseEnvironment["LC_ALL"] == nil)
        #expect(GitClient.baseEnvironment["LC_CTYPE"] == nil)
    }

    /// A background `git status` must not take `index.lock`, or the user's own git fails.
    @Test("every child gets GIT_OPTIONAL_LOCKS=0")
    func optionalLocksAreOff() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-client-locks-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let script = directory.appendingPathComponent("env-git")
        try "#!/bin/sh\necho \"$GIT_OPTIONAL_LOCKS\"\n".write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let client = GitClient(configuration: GitClientConfiguration(executableURL: script, timeout: 10))

        let output = try await client.run("status", [], in: directory)

        #expect(output.trimmingCharacters(in: .newlines) == "0")
    }
}

/// `pushDestination(of:)` is git's own `<branch>@{push}`: it follows `push.default`, refuses
/// what git refuses, and never hands git a dash-led branch.
@Suite("GitClient push destination", .serialized)
struct GitClientPushDestinationTests {
    private let client = GitClient(configuration: GitClientConfiguration(
        extraEnvironment: ["GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
    ))

    @Test("a tracked branch resolves to its remote branch; push.default=upstream follows the upstream")
    func resolves() async throws {
        let remote = try await GitTestRepository.makeBare()
        defer { remote.tearDown() }
        let clone = try await GitTestRepository.clone(of: remote, prefix: "git-push-destination")
        defer { clone.tearDown() }
        try clone.write("a\n", to: "a.txt")
        try await clone.run(["add", "a.txt"])
        try await clone.run(["commit", "-q", "-m", "a"])
        try await clone.run(["push", "--quiet", "-u", "origin", "main"])
        try await clone.run(["push", "--quiet", "origin", "main:feature"])
        try await clone.run(["branch", "--quiet", "--track", "feat", "origin/feature"])

        #expect(try await client.pushDestination(of: "main", in: clone.root) == "origin/main")
        let refused = try? await client.pushDestination(of: "feat", in: clone.root)
        #expect(refused == nil)
        try await clone.run(["config", "push.default", "upstream"])
        #expect(try await client.pushDestination(of: "feat", in: clone.root) == "origin/feature")
    }

    @Test("a branch with no upstream has no destination")
    func failsWithoutUpstream() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-push-destination")
        defer { repository.tearDown() }
        try repository.write("a\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.run(["commit", "-q", "-m", "a"])
        do {
            _ = try await client.pushDestination(of: "main", in: repository.root)
            Issue.record("expected a failure")
        } catch let GitClientError.commandFailed(verb, _, standardError) {
            #expect(verb == "rev-parse")
            #expect(standardError.contains("no upstream"))
        }
    }

    @Test("a dash-led or empty branch is refused before git runs")
    func dashLedRefused() async throws {
        let directory = URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)")
        for name in ["-q", "--all", ""] {
            do {
                _ = try await client.pushDestination(of: name, in: directory)
                Issue.record("expected \(name) to be refused")
            } catch let error as GitClientError {
                #expect(error == .invalidArgument(verb: "rev-parse", argument: name))
            }
        }
    }
}
