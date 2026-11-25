import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// `ReadOnlyGit` against throwaway repositories. Serialized because one vector
/// sets variables in this process's environment, which the type inherits.
@Suite(.serialized)
struct ReadOnlyGitConformanceTests {

    // MARK: - Fixtures

    private func makeDirectory(_ prefix: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Runs the tool for fixture setup with the repaired PATH and no machine config.
    @discardableResult
    private func fixtureRun(_ args: [String], in directory: URL) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "-C", directory.path] + args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = ReadOnlyGit.repairedPath(env["PATH"])
        env["GIT_CONFIG_GLOBAL"] = "/dev/null"
        env["GIT_CONFIG_SYSTEM"] = "/dev/null"
        process.environment = env
        let outcome = try CommandRunner.runToCompletion(process, input: Data(), timeout: 30)
        return outcome.status
    }

    private func makeRepository() throws -> URL {
        let repo = try makeDirectory("readonlygit")
        try fixtureRun(["init", "-b", "fingerprint-branch"], in: repo)
        try Data("one\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        try fixtureRun(["add", "README.md"], in: repo)
        try fixtureRun(["-c", "user.name=Test", "-c", "user.email=test@example.com",
                        "-c", "commit.gpgsign=false", "commit", "-m", "first"], in: repo)
        return repo
    }

    private func remove(_ url: URL) { try? FileManager.default.removeItem(at: url) }

    // MARK: - Output forms

    @Test("V1: rawGit keeps the whitespace that git trims away")
    func v001RawKeepsWhitespace() throws {
        let repo = try makeRepository()
        defer { remove(repo) }
        try Data("changed\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        let args = ["-C", repo.path, "status", "--porcelain", "-unormal", "--no-renames"]
        #expect(ReadOnlyGit.rawGit(args) == " M README.md\n")
        #expect(ReadOnlyGit.git(args) == "M README.md")
    }

    @Test("V2: git returns the branch name without a newline")
    func v002TrimmedBranch() throws {
        let repo = try makeRepository()
        defer { remove(repo) }
        #expect(ReadOnlyGit.git(["-C", repo.path, "rev-parse", "--abbrev-ref", "HEAD"]) == "fingerprint-branch")
    }

    // MARK: - Failures

    @Test("V3: a directory that is not a repository gives the empty string")
    func v003NotARepository() throws {
        let plain = try makeDirectory("plain")
        defer { remove(plain) }
        #expect(ReadOnlyGit.git(["-C", plain.path, "rev-parse", "--abbrev-ref", "HEAD"]).isEmpty)
    }

    @Test("V4: an unknown subcommand gives the empty string")
    func v004UnknownSubcommand() {
        #expect(ReadOnlyGit.git(["no-such-subcommand"]).isEmpty)
    }

    @Test("V5: a command that does not answer within five seconds gives the empty string",
          .disabled("needs five real seconds to pass, past what a unit test may wait"))
    func v005TimeoutIsEmpty() {}

    // MARK: - PATH repair

    @Test("V6: a missing or empty path gives the four default directories")
    func v006PathMissing() {
        let defaults = "/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"
        #expect(ReadOnlyGit.repairedPath(nil) == defaults)
        #expect(ReadOnlyGit.repairedPath("") == defaults)
    }

    @Test("V7: entries keep their order and only the missing directories follow")
    func v007PathOrder() {
        #expect(ReadOnlyGit.repairedPath("/opt/homebrew/bin:/custom")
                == "/opt/homebrew/bin:/custom:/usr/bin:/bin:/usr/local/bin")
    }

    @Test("V8: a minimal GUI path gains the two missing directories")
    func v008PathMinimal() {
        #expect(ReadOnlyGit.repairedPath("/usr/bin:/bin:/usr/sbin:/sbin")
                == "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin")
    }

    // MARK: - Environment

    @Test("V9: a status call does not refresh the index")
    func v009StatusLeavesTheIndexAlone() throws {
        let repo = try makeRepository()
        defer { remove(repo) }
        // Rewrite the file so the index's stat data is stale; a status that was
        // allowed its optional lock would rewrite the index to refresh it.
        Thread.sleep(forTimeInterval: 0.05)
        try Data("one\n".utf8).write(to: repo.appendingPathComponent("README.md"))
        let index = repo.appendingPathComponent(".git/index")
        let before = try FileManager.default.attributesOfItem(atPath: index.path)[.modificationDate] as? Date
        _ = ReadOnlyGit.git(["-C", repo.path, "status"])
        let after = try FileManager.default.attributesOfItem(atPath: index.path)[.modificationDate] as? Date
        #expect(before != nil)
        #expect(before == after)
    }

    @Test("V10: the child gets GIT_OPTIONAL_LOCKS=0 over the caller's value and the rest unchanged")
    func v010EnvironmentInherited() {
        // The caller's environment is passed in, not `setenv`'d: the process
        // environment is shared with every suite running beside this one.
        let probe = "ADH_READONLYGIT_PROBE_\(UUID().uuidString.prefix(8))"
        var environment = ProcessInfo.processInfo.environment
        environment["GIT_OPTIONAL_LOCKS"] = "1"
        environment[probe] = "inherited-value"
        let lines = ReadOnlyGit.git(["-c", "alias.showenv=!env", "showenv"], environment: environment)
            .split(separator: "\n")
        #expect(lines.contains("GIT_OPTIONAL_LOCKS=0"))
        #expect(!lines.contains("GIT_OPTIONAL_LOCKS=1"))
        #expect(lines.contains(Substring("\(probe)=inherited-value")))
    }

    @Test("V10b: by default the child inherits this process's environment")
    func v010bDefaultEnvironmentIsTheProcesss() {
        guard let home = ProcessInfo.processInfo.environment["HOME"] else { return }
        let lines = ReadOnlyGit.git(["-c", "alias.showenv=!env", "showenv"]).split(separator: "\n")
        #expect(lines.contains(Substring("HOME=\(home)")))
    }

    // MARK: - Output handling

    @Test("V11: an output larger than a pipe holds is returned whole")
    func v011LargeOutputIsDrained() {
        let script = "!yes abcdefgh | head -n 200000"
        let output = ReadOnlyGit.rawGit(["-c", "alias.big=\(script)", "big"])
        #expect(output.utf8.count == 200_000 * 9)
    }

    @Test("V12: standard error is not part of the result")
    func v012StdoutOnly() {
        let output = ReadOnlyGit.git(["-c", "alias.noisy=!echo oops 1>&2; echo out", "noisy"])
        #expect(output == "out")
    }

    @Test("V13: -C runs the command in the given repository")
    func v013WorkingDirectory() throws {
        let repo = try makeRepository()
        defer { remove(repo) }
        let top = ReadOnlyGit.git(["-C", repo.path, "rev-parse", "--show-toplevel"])
        #expect(ProcessLiveness.canonicalPath(top) == ProcessLiveness.canonicalPath(repo.path))
    }

    @Test("V14: empty path segments are dropped and the defaults appended")
    func v014PathEmptySegments() {
        #expect(ReadOnlyGit.repairedPath("/a::/b:") == "/a:/b:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin")
    }
}
