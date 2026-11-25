import Foundation
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A temp git repo for the review git tests; commits carry explicit dates so ordering is deterministic.
///
/// The fixture builds its repo with the system git directly, so it never depends on the code under test;
/// `review` is the facade under test, over a `GitClient` with an explicit `/usr/bin/git` configuration.
final class PartnerGitFixture {
    let directory: URL
    let review = ReviewGit(client: GitClient(configuration: GitClientConfiguration(
        executableURL: URL(fileURLWithPath: "/usr/bin/git"), timeout: 30, submoduleHandling: .include)))

    /// Each fixture is a copy of one empty, configured repo built once per process, so a test pays for a
    /// file copy (an APFS clone) rather than `git init` and three `git config` processes. The copy is the
    /// test's own: nothing in a plain repo's `.git` names its absolute path.
    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerGitFixture-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: try Self.template.get(), to: directory)
    }

    /// The empty repo every fixture copies: `main`, Ann's identity, unsigned commits. Built on first use
    /// (a `static let` initialises exactly once, thread-safely) and removed when the process exits.
    /// `nonisolated(unsafe)` because `any Error` is not `Sendable`; the value is never mutated.
    private nonisolated(unsafe) static let template: Result<URL, any Error> = Result {
        let template = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerGitFixture-template-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: template, withIntermediateDirectories: true)
        atexit {
            if case .success(let url) = PartnerGitFixture.template { try? FileManager.default.removeItem(at: url) }
        }
        try exec(["init", "-b", "main"], day: nil, in: template)
        try exec(["config", "user.name", "Ann"], day: nil, in: template)
        try exec(["config", "user.email", "ann@example.com"], day: nil, in: template)
        try exec(["config", "commit.gpgsign", "false"], day: nil, in: template)
        return template
    }

    deinit { try? FileManager.default.removeItem(at: directory) }

    @discardableResult
    func git(_ arguments: String...) throws -> String {
        try exec(arguments, day: nil, in: directory)
    }

    /// Runs git inside `subdirectory` of the repo (a submodule's working tree, say).
    @discardableResult
    func git(in subdirectory: String, _ arguments: String...) throws -> String {
        try exec(arguments, day: nil, in: directory.appendingPathComponent(subdirectory))
    }

    /// Writes `file`, commits it dated `day` of January 2026, and returns the sha.
    @discardableResult
    func commit(file: String, day: Int, message: String, content: String? = nil) throws -> String {
        try (content ?? "\(message)\n")
            .write(to: directory.appendingPathComponent(file), atomically: true, encoding: .utf8)
        try git("add", file)
        try exec(["commit", "-m", message], day: day, in: directory)
        return try headSHA()
    }

    /// HEAD's sha, read from the files a commit has just written (a commit always writes its branch's ref
    /// loose) rather than by a `git rev-parse` process; falls back to `rev-parse` for anything else.
    private func headSHA() throws -> String {
        let gitDirectory = directory.appendingPathComponent(".git")
        if let head = try? String(contentsOf: gitDirectory.appendingPathComponent("HEAD"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines) {
            if head.hasPrefix("ref: "),
               let sha = try? String(contentsOf: gitDirectory.appendingPathComponent(String(head.dropFirst(5))),
                                     encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
               sha.count == 40 {
                return sha
            }
            if head.count == 40, !head.hasPrefix("ref: ") { return head }
        }
        return try git("rev-parse", "HEAD").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func merge(branch: String, day: Int) throws {
        try exec(["merge", "--no-ff", "-m", "merge \(branch)", branch], day: day, in: directory)
    }

    @discardableResult
    private func exec(_ arguments: [String], day: Int?, in directory: URL) throws -> String {
        try Self.exec(arguments, day: day, in: directory)
    }

    @discardableResult
    private static func exec(_ arguments: [String], day: Int?, in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        var environment = ProcessInfo.processInfo.environment
        if let day {
            let date = String(format: "2026-01-%02dT12:00:00Z", day)
            environment["GIT_COMMITTER_DATE"] = date
            environment["GIT_AUTHOR_DATE"] = date
        }
        process.environment = environment
        let out = Pipe()
        process.standardOutput = out
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw GitClientError.commandFailed(verb: arguments.first ?? "", exitStatus: process.terminationStatus,
                                               standardError: "")
        }
        return String(bytes: data, encoding: .utf8) ?? ""
    }
}
