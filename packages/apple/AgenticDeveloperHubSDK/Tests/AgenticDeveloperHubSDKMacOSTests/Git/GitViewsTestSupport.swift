import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

/// The toolkit's committed `Resources/TextMate/` tree and one shared highlighter, for the
/// diff, blame and coloring tests. Creating the engine interprets the WASM Oniguruma, the
/// slow part, so every test shares one.
@MainActor
enum GitTextMateFixture {
    static let directory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // Git
        .deletingLastPathComponent()  // AgenticDeveloperHubSDKMacOSTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // AgenticDeveloperHubSDK
        .appendingPathComponent("Resources/TextMate", isDirectory: true)

    /// Kept as a `Result` so a failed init is reported by every test as the error it was.
    private static let shared = Result { () throws -> (SyntaxHighlighter, GrammarRegistry, CodeTheme) in
        let resources = try TextMateResources(directory: directory)
        let registry = GrammarRegistry(sources: [try BundledGrammarSource(resources: resources)])
        let theme = try CodeTheme(vscodeThemeData: Data(contentsOf: directory.appendingPathComponent(
            "themes/dark-plus.json")))
        return (try SyntaxHighlighter(resources: resources, registry: registry), registry, theme)
    }

    static func coloring() throws -> GitSyntaxColoring {
        let (highlighter, registry, theme) = try shared.get()
        return GitSyntaxColoring(highlighter: highlighter, resolver: LanguageResolver(registry: registry),
                                 registry: registry, theme: { theme })
    }
}

/// The error the fake source throws: a real git failure, with git's own message.
let gitViewsFailure = GitClientError.commandFailed(verb: "diff", exitStatus: 128, standardError: "fatal: bad object")

/// A content source that behaves like the model: each call records its request, then
/// awaits. A call whose key is in `holding` waits until a test releases it, in any order;
/// one in `failing` throws `gitViewsFailure`. Keys: `diff:<target key>`,
/// `contents:<path>@<revision or "">`, `blame:<path>@<revision or "">`, `history:<path>`.
@MainActor
final class GitViewsFakeContentSource: GitContentSource {
    var diffs: [String: GitDiff] = [:]
    var files: [String: Data] = [:]
    var blames: [String: GitBlame] = [:]
    var histories: [String: [GitCommit]] = [:]
    var holding: Set<String> = []
    var failing: Set<String> = []
    private(set) var diffRequests: [(target: GitDiffTarget, options: GitDiffOptions)] = []
    private(set) var contentsRequests: [String] = []
    private(set) var blameRequests: [String] = []
    private(set) var historyRequests: [String] = []
    private(set) var held: [String: CheckedContinuation<Void, Never>] = [:]

    /// A target's key: the commit id, `from..to`, `unstaged`, `staged` or `untracked:<path>`.
    static func key(_ target: GitDiffTarget) -> String {
        switch target {
        case .commit(let id, _): id
        case .range(let from, let until, _): "\(from)..\(until)"
        case .unstaged: "unstaged"
        case .staged: "staged"
        case .untracked(let path): "untracked:\(path)"
        }
    }

    static func revisionKey(_ path: String, _ revision: String?) -> String {
        "\(path)@\(revision ?? "")"
    }

    func diff(_ target: GitDiffTarget, options: GitDiffOptions) async throws -> GitDiff {
        diffRequests.append((target, options))
        let key = Self.key(target)
        try await gate("diff:\(key)")
        return diffs[key] ?? GitDiff(files: [])
    }

    func contents(path: String, at revision: String?) async throws -> Data? {
        let key = Self.revisionKey(path, revision)
        contentsRequests.append(key)
        try await gate("contents:\(key)")
        return files[key]
    }

    func blame(path: String, at revision: String?) async throws -> GitBlame {
        let key = Self.revisionKey(path, revision)
        blameRequests.append(key)
        try await gate("blame:\(key)")
        return blames[key] ?? GitBlame(lines: [], commits: [:])
    }

    func fileHistory(path: String) async throws -> [GitCommit] {
        historyRequests.append(path)
        try await gate("history:\(path)")
        return histories[path] ?? []
    }

    func commit(_ id: String) -> GitCommit? { nil }

    private func gate(_ key: String) async throws {
        if holding.contains(key) {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                MainActor.assumeIsolated { self.held[key] = continuation }
            }
        }
        if failing.contains(key) { throw gitViewsFailure }
    }

    func release(_ key: String) {
        held.removeValue(forKey: key)?.resume()
    }

    /// Waits until `key`'s call is suspended; records an issue rather than hanging when it
    /// never is.
    func waitUntilHeld(_ key: String, sourceLocation: SourceLocation = #_sourceLocation) async {
        for _ in 0..<10_000 where held[key] == nil { await Task.yield() }
        if held[key] == nil { Issue.record("\(key) was never held", sourceLocation: sourceLocation) }
    }
}
