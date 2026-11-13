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
    static func make(prefix: String = "git-test-repository") async throws -> GitTestRepository {
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
