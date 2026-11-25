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

    static let budget: TimeInterval = 10

    let root: URL

    /// `git init -b main` with an identity and signing off.
    ///
    /// A copy of one such repository built once per process (`empty`), so a test pays for
    /// a directory clone rather than five git commands.
    static func make(prefix: String = "git-test-repository") async throws -> GitTestRepository {
        try await copy(of: empty.value, prefix: prefix)
    }

    /// The repository `make` copies, built by `makeFresh` on first use and kept, never
    /// handed to a test, for the life of the process.
    private static let empty = Task { try await makeFresh(prefix: "git-test-repository-template") }

    /// `git init -b main` with an identity and signing off, run afresh.
    private static func makeFresh(prefix: String) async throws -> GitTestRepository {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let repository = GitTestRepository(root: root)
        // A throw here never reaches a caller's tearDown, so the half-built
        // repository is removed before the error propagates.
        do {
            try await repository.run(["init", "-b", "main"])
            try await repository.run(["config", "user.email", "test@example.com"])
            try await repository.run(["config", "user.name", "Test"])
            try await repository.run(["config", "commit.gpgsign", "false"])
            try await repository.run(["config", "tag.gpgsign", "false"])
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
            try await repository.run(["clone", "--quiet", remote.root.path, root.path],
                                     in: FileManager.default.temporaryDirectory)
            try await repository.run(["symbolic-ref", "HEAD", "refs/heads/main"])
            try await repository.run(["config", "branch.main.remote", "origin"])
            try await repository.run(["config", "branch.main.merge", "refs/heads/main"])
            try await repository.run(["config", "user.email", "test@example.com"])
            try await repository.run(["config", "user.name", "Test"])
            try await repository.run(["config", "commit.gpgsign", "false"])
            try await repository.run(["config", "tag.gpgsign", "false"])
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
    }

    /// A copy of `template` in a new temp directory, its index refreshed so the copy's own
    /// stat data (new inodes and change times) reads as the unchanged files they are.
    ///
    /// Only a plain repository copies safely: its `.git` names no absolute path to itself.
    /// A worktree, a submodule, or a remote pointing back into the repository records one,
    /// so a fixture holding any of those is built per test (or has the path rewritten).
    static func copy(of template: GitTestRepository, prefix: String) async throws -> GitTestRepository {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: template.root, to: root)
        let repository = GitTestRepository(root: root)
        // An unborn repository has no index, and refreshing would write an empty one.
        guard FileManager.default.fileExists(atPath: repository.url(".git/index").path) else { return repository }
        do {
            try await repository.run(["update-index", "-q", "--refresh"])
            return repository
        } catch {
            repository.tearDown()
            throw error
        }
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
            executableURL: URL(fileURLWithPath: "/usr/bin/git"),
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

/// A fixture repository built once, on first use, and handed to each test as a fresh copy,
/// so a suite whose tests all start from the same history runs its git commands once.
///
/// `build` sets up the template and returns whatever the tests need to know about it (the
/// shas it made, say); a copy has the same objects and refs, so that value holds for every
/// copy. The template itself is never handed out, so no test can change what the next one
/// copies; it stays in the temp directory for the life of the process. The rule
/// `GitTestRepository.copy(of:prefix:)` states applies: a template may not hold a worktree,
/// a submodule or anything else that names its own absolute path.
final class GitTestTemplate<Fixture: Sendable>: Sendable {
    private let built: Task<(GitTestRepository, Fixture), any Error>

    init(prefix: String, build: @escaping @Sendable (GitTestRepository) async throws -> Fixture) {
        built = Task {
            let repository = try await GitTestRepository.make(prefix: "\(prefix)-template")
            do {
                return (repository, try await build(repository))
            } catch {
                repository.tearDown()
                throw error
            }
        }
    }

    /// A copy of the template in its own temp directory, and the value `build` returned.
    /// The caller tears the copy down.
    func copy(prefix: String) async throws -> (repository: GitTestRepository, fixture: Fixture) {
        let (template, fixture) = try await built.value
        return (try await GitTestRepository.copy(of: template, prefix: prefix), fixture)
    }
}

extension GitTestTemplate where Fixture == Void {
    /// A copy of the template in its own temp directory. The caller tears it down.
    func copy(prefix: String) async throws -> GitTestRepository {
        try await copy(prefix: prefix).repository
    }
}
