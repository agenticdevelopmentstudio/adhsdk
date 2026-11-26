import Foundation
@testable import AgenticDeveloperHubSDKCore

/// A throwaway git repository in a temp directory, built by driving `/usr/bin/git`
/// directly, so a fixture never depends on the `GitClient` it is used to test.
///
/// Only ever points git at a directory it made itself, and `tearDown()` removes it.
/// The fixture's own git calls see no global or system configuration
/// (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM`), so a developer's signing,
/// hooks path or default-branch settings cannot hang or reshape the setup; the
/// client under test still reads them, which is what its own flags must defend
/// against.
struct GitTestRepository {
    struct CommandFailed: Error, CustomStringConvertible {
        let arguments: [String]
        let exitStatus: Int32
        let standardError: String

        var description: String { "git \(arguments.joined(separator: " ")) exited \(exitStatus): \(standardError)" }
    }

    /// The same budget as `GitClientConfiguration.tests`, for the same reason: a
    /// suite of git tests runs every test at once, and a fixture call that is not
    /// about the timeout must not fail on it. A real hang still fails, a minute in.
    static let budget: TimeInterval = 60

    /// The git binary itself, not `/usr/bin/git`.
    ///
    /// `/usr/bin/git` is the xcrun shim: every call looks the developer directory
    /// up before it execs the real git, which costs about 30 ms a call on an idle
    /// machine and far more when a suite's tests spawn git all at once. Resolved
    /// once with `xcrun --find git`; `/usr/bin/git` when that fails.
    static let gitURL: URL = {
        let shim = URL(fileURLWithPath: "/usr/bin/git")
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--find", "git"]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return shim }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let path = (String(bytes: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard process.terminationStatus == 0, FileManager.default.isExecutableFile(atPath: path) else { return shim }
        return URL(fileURLWithPath: path)
    }()

    /// Housekeeping off: with `maintenance.auto` and `gc.auto` on, every commit,
    /// fetch and push starts a detached `git maintenance run --auto`, a spawn the
    /// test never asked for, and a git still running in the directory `tearDown`
    /// removes.
    static let housekeepingOff: KeyValuePairs<String, String> = [
        "maintenance.auto": "false",
        "gc.auto": "0"
    ]

    /// What `make` and `clone` set in every working repository: an identity, signing
    /// off, and housekeeping off.
    static let settings: KeyValuePairs<String, String> = [
        "user.email": "test@example.com",
        "user.name": "Test",
        "commit.gpgsign": "false",
        "tag.gpgsign": "false",
        "maintenance.auto": "false",
        "gc.auto": "0"
    ]

    let root: URL

    /// `git init -b main` with `settings`: an identity, signing off, housekeeping off.
    static func make(prefix: String = "git-test-repository") async throws -> GitTestRepository {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repository = GitTestRepository(root: root)
        // A throw here never reaches a caller's tearDown, so the half-built
        // repository is removed before the error propagates.
        do {
            try await repository.run(["init", "-b", "main"])
            try repository.appendConfiguration(Self.settings)
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    /// `git init --bare -b main`: a remote that lives in the temp directory, so push,
    /// fetch and pull run against it with no network.
    static func makeBare(prefix: String = "git-test-remote") async throws -> GitTestRepository {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString).git")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repository = GitTestRepository(root: root)
        do {
            try await repository.run(["init", "--bare", "-b", "main"])
            try repository.appendConfiguration(Self.housekeepingOff)
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    /// A clone of `remote` (named `origin`) with the same identity and signing settings as
    /// `make`. HEAD is pointed at `main` and `main` set to track `origin/main` whatever the
    /// installed git does when it clones an empty repository, so a pull works from the start.
    static func clone(of remote: GitTestRepository, prefix: String = "git-test-clone") async throws
        -> GitTestRepository {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        let repository = GitTestRepository(root: root)
        do {
            let tracking = ["branch.main.remote=origin", "branch.main.merge=refs/heads/main"]
            let settings = (tracking + Self.settings.map { "\($0.key)=\($0.value)" }).flatMap { ["--config", $0] }
            try await repository.run(["clone", "--quiet"] + settings + [remote.root.path, root.path],
                                     in: FileManager.default.temporaryDirectory)
            try await repository.run(["symbolic-ref", "HEAD", "refs/heads/main"])
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    /// Appends `pairs` to the repository's own config file, which is what one
    /// `git config <key> <value>` per pair would write, without a spawn per pair.
    /// Keys are `section.name` or `section.subsection.name` with no quoting needed.
    func appendConfiguration(_ pairs: KeyValuePairs<String, String>) throws {
        let gitDirectory = FileManager.default.fileExists(atPath: url(".git").path) ? url(".git") : root
        let file = gitDirectory.appendingPathComponent("config")
        var text = ""
        for (key, value) in pairs {
            var parts = key.split(separator: ".").map(String.init)
            let name = parts.removeLast()
            let section = parts.count == 1 ? parts[0] : "\(parts[0]) \"\(parts.dropFirst().joined(separator: "."))\""
            text += "[\(section)]\n\t\(name) = \(value)\n"
        }
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(text.utf8))
    }

    func tearDown() {
        try? FileManager.default.removeItem(at: root)
    }

    func url(_ path: String) -> URL {
        root.appendingPathComponent(path)
    }

    /// Runs `git <arguments>` in `directory` (the root by default) and returns its
    /// standard output, decoded the way `GitClient` decodes (UTF-8, Latin-1 fallback).
    /// Throws `CommandFailed` on a non-zero exit.
    @discardableResult
    func run(_ arguments: [String], in directory: URL? = nil, environment: [String: String] = [:]) async throws
        -> String {
        let configuration = SubprocessChannel.Configuration(
            executableURL: Self.gitURL,
            arguments: arguments,
            environment: ["GIT_TERMINAL_PROMPT": "0", "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1"]
                .merging(environment) { _, override in override },
            environmentPolicy: .mergeOverParent,
            currentDirectoryURL: directory ?? root
        )
        let result = try await SubprocessChannel.run(configuration, budget: Self.budget)
        guard result.exitStatus == 0 else {
            throw CommandFailed(arguments: arguments, exitStatus: result.exitStatus,
                                standardError: result.standardError)
        }
        return GitOutputDecoding.string(result.standardOutput)
    }

    func write(_ text: String, to path: String) throws {
        try write(Data(text.utf8), to: path)
    }

    func write(_ data: Data, to path: String) throws {
        let file = url(path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: file)
    }

    /// Commits what is staged with author and committer dated `epoch`, so a test can
    /// fix the order `--date-order` walks in.
    func commit(_ message: String, at epoch: Int, author: String? = nil, options: [String] = []) async throws {
        var arguments = options + ["commit", "-m", message]
        if let author { arguments.append("--author=\(author)") }
        try await run(arguments, environment: Self.dated(epoch))
    }

    /// The full sha `revision` names.
    func sha(_ revision: String) async throws -> String {
        try await run(["rev-parse", "--verify", revision]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func dated(_ epoch: Int) -> [String: String] {
        ["GIT_AUTHOR_DATE": "@\(epoch) +0000", "GIT_COMMITTER_DATE": "@\(epoch) +0000"]
    }
}

extension GitClientConfiguration {
    /// The default configuration with a timeout a loaded test run can afford.
    ///
    /// Five seconds is the app's budget for an interactive refresh. A parallel
    /// test run keeps every core busy, and `git submodule status` (a shell
    /// script) then outlasts it, so a test that is not about the timeout would
    /// fail on `.timedOut` instead of on what it checks. Tests of the timeout
    /// itself set their own.
    ///
    /// The developer's own git setup is hidden from the client too, as it is
    /// from the fixture: `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM`
    /// drop `~/.gitconfig` and the system config (a `core.abbrev`, a
    /// `color.ui=always`), and `XDG_CONFIG_HOME` at an empty directory drops
    /// `~/.config/git/attributes` and `ignore`, which `GIT_CONFIG_GLOBAL` leaves
    /// in force: a global `*.psd filter=lfs` there would otherwise reach every
    /// LFS test's repository. `GIT_ATTR_NOSYSTEM` drops the system attributes
    /// file, which `GIT_CONFIG_NOSYSTEM` does not, for the same reason.
    static let tests = GitClientConfiguration(
        executableURL: GitTestRepository.gitURL, timeout: 60,
        extraEnvironment: isolatedEnvironment
    )

    /// The overrides `.tests` applies, for a test that builds its own
    /// configuration and wants the same isolation.
    static let isolatedEnvironment: [String: String] = [
        "GIT_CONFIG_GLOBAL": "/dev/null",
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_ATTR_NOSYSTEM": "1",
        "XDG_CONFIG_HOME": emptyConfigHome.path
    ]

    /// An empty directory, made once per test process, for `XDG_CONFIG_HOME`.
    private static let emptyConfigHome: URL = {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-tests-xdg-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()
}
