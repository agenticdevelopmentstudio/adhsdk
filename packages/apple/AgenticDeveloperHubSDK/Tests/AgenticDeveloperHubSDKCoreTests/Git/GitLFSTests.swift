import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore

/// Git LFS (recipe `foundation/git/git-client`, "LFS"): pointer files, the `lfs track` and
/// `lfs ls-files` parsers, and the client's not-installed answer. Pure; nothing reaches
/// the network.
@Suite("GitLFS")
struct GitLFSTests {

    static let oid = "4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393"

    static func pointerText(oid: String = oid, size: Int64 = 12345) -> String {
        "version https://git-lfs.github.com/spec/v1\noid sha256:\(oid)\nsize \(size)\n"
    }

    // MARK: Pointer parse

    @Test("a valid pointer parses to its oid and size")
    func validPointer() throws {
        let pointer = try #require(GitLFSPointer.parse(Self.pointerText()))
        #expect(pointer.oid == Self.oid)
        #expect(pointer.size == 12345)
        #expect(pointer.shortOID == "4d7a214")
    }

    @Test("a pointer with CRLF line endings parses")
    func crlfPointer() {
        let text = Self.pointerText().replacingOccurrences(of: "\n", with: "\r\n")
        #expect(GitLFSPointer.parse(text) == GitLFSPointer(oid: Self.oid, size: 12345))
    }

    @Test("a wrong version line is not a pointer")
    func wrongVersion() {
        let text = "version https://hawser.github.com/spec/v1\noid sha256:\(Self.oid)\nsize 12345\n"
        #expect(GitLFSPointer.parse(text) == nil)
    }

    @Test("text longer than 1024 bytes is not a pointer")
    func tooLong() {
        let text = Self.pointerText() + "x-padding " + String(repeating: "a", count: 1024) + "\n"
        #expect(text.utf8.count > 1024)
        #expect(GitLFSPointer.parse(text) == nil)
    }

    @Test("a pointer without a size line is not a pointer")
    func missingSize() {
        let text = "version https://git-lfs.github.com/spec/v1\noid sha256:\(Self.oid)\n"
        #expect(GitLFSPointer.parse(text) == nil)
    }

    @Test("an oid that is not 64 hex digits is not a pointer")
    func badOID() {
        #expect(GitLFSPointer.parse(Self.pointerText(oid: "abc123")) == nil)
    }

    // MARK: Output parsers

    @Test("lfs ls-files lines map each path to whether its object is downloaded")
    func parsesLsFiles() {
        let output = """
        4d7a214614 * assets/logo.png
        9f86d08188 - videos/intro movie.mov
        not a line
        """
        #expect(GitLFSState.parseFiles(output) == ["assets/logo.png": true, "videos/intro movie.mov": false])
        #expect(GitLFSState.parseFiles("") == [:])
    }

    @Test("lfs track lists the tracked patterns without their attributes file, not the excluded ones")
    func parsesTrack() {
        let output = """
        Listing tracked patterns
            *.psd (.gitattributes)
            assets/** (assets/.gitattributes)
        Listing excluded patterns
            *.txt (.gitattributes)
        """
        #expect(GitLFSState.parseTrackedPatterns(output) == ["*.psd", "assets/**"])
        #expect(GitLFSState.parseTrackedPatterns("Listing tracked patterns\nListing excluded patterns\n") == [])
    }

    @Test("isInUse needs git-lfs installed and a tracked pattern or an LFS file")
    func isInUse() {
        #expect(!GitLFSState.notInstalled.isInUse)
        #expect(!GitLFSState(isInstalled: true, trackedPatterns: [], files: [:]).isInUse)
        #expect(GitLFSState(isInstalled: true, trackedPatterns: ["*.psd"], files: [:]).isInUse)
        #expect(GitLFSState(isInstalled: true, trackedPatterns: [], files: ["a.bin": true]).isInUse)
        #expect(!GitLFSState(isInstalled: false, trackedPatterns: ["*.psd"], files: ["a.bin": true]).isInUse)
    }

    @Test("a path is tracked when ls-files lists it or a pattern matches it")
    func isTracked() {
        let state = GitLFSState(isInstalled: true, trackedPatterns: ["*.psd", "assets/*.png"],
                                files: ["data/blob.bin": true])
        #expect(state.isTracked("data/blob.bin"))
        #expect(state.isTracked("art/deep/cover.psd"))
        #expect(state.isTracked("assets/logo.png"))
        #expect(!state.isTracked("logo.png"))
        #expect(!state.isTracked("README.md"))
    }

    // MARK: Diff summary

    @Test("a diff between two pointers summarises as old → new")
    func pointerDiffSummary() throws {
        let newOID = String(repeating: "b", count: 64)
        let hunk = GitDiffHunk(oldStart: 1, oldCount: 3, newStart: 1, newCount: 3, section: "", lines: [
            GitDiffLine(kind: .context, text: "version https://git-lfs.github.com/spec/v1", oldNumber: 1, newNumber: 1),
            GitDiffLine(kind: .removed, text: "oid sha256:\(Self.oid)", oldNumber: 2, newNumber: nil),
            GitDiffLine(kind: .removed, text: "size 2048", oldNumber: 3, newNumber: nil),
            GitDiffLine(kind: .added, text: "oid sha256:\(newOID)", oldNumber: nil, newNumber: 2),
            GitDiffLine(kind: .added, text: "size 4096", oldNumber: nil, newNumber: 3)
        ])
        let diff = GitFileDiff(oldPath: "a.bin", newPath: "a.bin", change: .modified, isBinary: false, hunks: [hunk])
        let summary = try #require(GitLFSDiffSummary.of(diff))
        #expect(summary.old == GitLFSPointer(oid: Self.oid, size: 2048))
        #expect(summary.new == GitLFSPointer(oid: newOID, size: 4096))
        let oldSize = ByteCountFormatter.string(fromByteCount: 2048, countStyle: .file)
        let newSize = ByteCountFormatter.string(fromByteCount: 4096, countStyle: .file)
        #expect(summary.text == "LFS object 4d7a214 · \(oldSize) → bbbbbbb · \(newSize)")
    }

    @Test("a pointer diff with no context lines (-U0) still summarises; stray text does not")
    func pointerDiffWithoutContext() throws {
        let newOID = String(repeating: "b", count: 64)
        let hunk = GitDiffHunk(oldStart: 2, oldCount: 2, newStart: 2, newCount: 2, section: "", lines: [
            GitDiffLine(kind: .removed, text: "oid sha256:\(Self.oid)", oldNumber: 2, newNumber: nil),
            GitDiffLine(kind: .removed, text: "size 2048", oldNumber: 3, newNumber: nil),
            GitDiffLine(kind: .added, text: "oid sha256:\(newOID)", oldNumber: nil, newNumber: 2),
            GitDiffLine(kind: .added, text: "size 4096", oldNumber: nil, newNumber: 3)
        ])
        let diff = GitFileDiff(oldPath: "a.bin", newPath: "a.bin", change: .modified, isBinary: false, hunks: [hunk])
        let summary = try #require(GitLFSDiffSummary.of(diff))
        #expect(summary.old == GitLFSPointer(oid: Self.oid, size: 2048))
        #expect(summary.new == GitLFSPointer(oid: newOID, size: 4096))

        let stray = GitDiffHunk(oldStart: 1, oldCount: 2, newStart: 1, newCount: 2, section: "", lines: [
            GitDiffLine(kind: .removed, text: "oid sha256:\(Self.oid)", oldNumber: 1, newNumber: nil),
            GitDiffLine(kind: .removed, text: "size 2048 and more", oldNumber: 2, newNumber: nil),
            GitDiffLine(kind: .added, text: "notes: oid sha256:\(newOID)", oldNumber: nil, newNumber: 1),
            GitDiffLine(kind: .added, text: "size 4096", oldNumber: nil, newNumber: 2)
        ])
        let notes = GitFileDiff(oldPath: "a.txt", newPath: "a.txt", change: .modified, isBinary: false,
                                hunks: [stray])
        #expect(GitLFSDiffSummary.of(notes) == nil)
        // A whole file still needs its version line.
        #expect(GitLFSPointer.parse("oid sha256:\(Self.oid)\nsize 1") == nil)
    }

    @Test("an added pointer summarises its one side; an ordinary diff does not summarise")
    func addedPointerSummary() throws {
        let lines = Self.pointerText().split(separator: "\n").enumerated().map { index, text in
            GitDiffLine(kind: .added, text: String(text), oldNumber: nil, newNumber: index + 1)
        }
        let hunk = GitDiffHunk(oldStart: 0, oldCount: 0, newStart: 1, newCount: 3, section: "", lines: lines)
        let added = GitFileDiff(oldPath: nil, newPath: "a.bin", change: .added, isBinary: false, hunks: [hunk])
        let summary = try #require(GitLFSDiffSummary.of(added))
        #expect(summary.old == nil)
        let size = ByteCountFormatter.string(fromByteCount: 12345, countStyle: .file)
        #expect(summary.text == "LFS object 4d7a214 · \(size)")

        let plain = GitDiffHunk(oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, section: "", lines: [
            GitDiffLine(kind: .removed, text: "let a = 1", oldNumber: 1, newNumber: nil),
            GitDiffLine(kind: .added, text: "let a = 2", oldNumber: nil, newNumber: 1)
        ])
        let ordinary = GitFileDiff(oldPath: "a.swift", newPath: "a.swift", change: .modified, isBinary: false,
                                   hunks: [plain])
        #expect(GitLFSDiffSummary.of(ordinary) == nil)
    }

    // MARK: Not installed

    @Test("isInstalled is false when git answers that lfs is not a git command")
    func notInstalled() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("git-lfs-not-installed-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let script = directory.appendingPathComponent("no-lfs-git")
        try "#!/bin/sh\necho \"git: 'lfs' is not a git command. See 'git --help'.\" >&2\nexit 1\n"
            .write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script.path)
        let client = GitClient(configuration: GitClientConfiguration(executableURL: script, timeout: 10))

        let state = try await client.lfsState(in: directory)
        #expect(!state.isInstalled)
        #expect(state.trackedPatterns.isEmpty)
        #expect(state.files.isEmpty)
        #expect(!state.isInUse)
    }

    @Test("a git child's PATH adds Homebrew's bin to a Finder-launched app's system PATH")
    func childPathIsRepaired() {
        let environment = GitClient.childEnvironment(
            configuration: .default, environment: [:], parent: ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
        )
        let path = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
        #expect(path.contains("/opt/homebrew/bin"))
        #expect(path.contains("/usr/local/bin"))
        #expect(Array(path.prefix(4)) == ["/usr/bin", "/bin", "/usr/sbin", "/sbin"])
        #expect(environment["GIT_TERMINAL_PROMPT"] == "0")
    }

    @Test("a configuration's PATH still outranks the repaired one")
    func configurationPathWins() {
        let configuration = GitClientConfiguration(
            executableURL: GitClientConfiguration.default.executableURL, timeout: 10,
            extraEnvironment: ["PATH": "/custom"]
        )
        let environment = GitClient.childEnvironment(configuration: configuration, environment: [:], parent: [:])
        #expect(environment["PATH"] == "/custom")
    }
}

/// Whether `/usr/bin/git lfs version` succeeds here, with the PATH a `GitClient` child gets.
private let gitLFSInstalled: Bool = {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = ["lfs", "version"]
    process.environment = ProcessInfo.processInfo.environment
        .merging(GitClient.childEnvironment(configuration: .default, environment: [:])) { _, new in new }
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}()

/// The client against a real repository using LFS, in the temp directory; skipped on a
/// machine without git-lfs.
@Suite("GitLFS fixture", .disabled(if: !gitLFSInstalled, "git-lfs not installed"))
struct GitLFSFixtureTests {
    @Test("a repository tracking *.bin reports the pattern and its downloaded file")
    func trackedRepository() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-lfs-fixture")
        defer { repository.tearDown() }
        try await repository.run(["lfs", "install", "--local"])
        try await repository.run(["lfs", "track", "*.bin"])
        try repository.write(Data([0, 1, 2, 3, 4, 5, 6, 7]), to: "blob.bin")
        try await repository.run(["add", "--", ".gitattributes", "blob.bin"])
        try await repository.commit("lfs", at: 1_767_268_800)

        let state = try await GitClient(configuration: .tests).lfsState(in: repository.root)
        #expect(state.isInstalled)
        #expect(state.trackedPatterns == ["*.bin"])
        #expect(state.files == ["blob.bin": true])
        #expect(state.isInUse)
    }
}
