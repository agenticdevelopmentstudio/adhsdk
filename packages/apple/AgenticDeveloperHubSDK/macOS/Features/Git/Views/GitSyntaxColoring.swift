import Foundation
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKLanguage
import os

/// Syntax colour for the git views (recipe `workspace/git/git-views`, "Diff"): a file
/// version's bytes as one `StyledLine` per line, through the shared TextMate highlighter,
/// with the language taken from the path.
///
/// Decoding runs off the main thread and highlighting on the highlighter's own actor, so
/// the main thread only waits. Used on the main thread.
@MainActor
public final class GitSyntaxColoring {

    /// Where one side of a diff is read from: nowhere (an untracked file has no old side),
    /// a revision spec handed to `GitContentSource.contents(path:at:)` (`":0"` is the
    /// index), or the working file.
    public enum Revision: Sendable, Hashable {
        case absent
        case at(String) // swiftlint:disable:this identifier_name
        case workingFile
    }

    private let highlighter: SyntaxHighlighter
    private let resolver: LanguageResolver
    private let registry: GrammarRegistry
    private let theme: @MainActor () -> CodeTheme

    public init(highlighter: SyntaxHighlighter, resolver: LanguageResolver, registry: GrammarRegistry,
                theme: @escaping @MainActor () -> CodeTheme) {
        self.highlighter = highlighter
        self.resolver = resolver
        self.registry = registry
        self.theme = theme
    }

    /// `data` as styled lines, or nil for nil data, data over the highlighter's limits, a
    /// path whose language is unknown or has no grammar, or a highlighter error (logged).
    /// Bytes that are not UTF-8 are decoded as ISO Latin-1, so they are coloured rather
    /// than dropped.
    public func lines(for data: Data?, path: String) async -> [StyledLine]? {
        guard let data, data.count <= SyntaxHighlighter.maximumBytes,
              let languageID = resolver.languageID(for: URL(fileURLWithPath: path)),
              let scopeName = registry.scopeName(languageID: languageID),
              registry.hasGrammar(scopeName: scopeName) else { return nil }
        let text = await Task.detached(priority: .userInitiated) { Self.decode(data) }.value
        let theme = self.theme()
        do {
            return try await highlighter.highlight(text, scopeName: scopeName, theme: theme)
        } catch {
            Self.logger.error("Syntax colouring failed: \(String(describing: type(of: error)), privacy: .public)")
            return nil
        }
    }

    /// UTF-8 when the bytes are UTF-8, otherwise ISO Latin-1, which decodes any bytes.
    nonisolated static func decode(_ data: Data) -> String {
        String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
    }

    /// Where a diff target's old and new sides are read from: the working copy's unstaged
    /// change is the index against the working file, a staged one `HEAD` against the index,
    /// an untracked file only the working file, a commit its first parent against itself,
    /// and a range its two ends.
    public static func revisions(for target: GitDiffTarget) -> (old: Revision, new: Revision) {
        switch target {
        case .unstaged: (.at(":0"), .workingFile)
        case .staged: (.at("HEAD"), .at(":0"))
        case .untracked: (.absent, .workingFile)
        case .commit(let id, _): (.at(id + "^1"), .at(id))
        case .range(let from, let until, _): (.at(from), .at(until))
        }
    }

    /// Both sides of `diff` read from `source` per `target` and coloured, old first. A side
    /// with no path (an added file's old side, a deleted file's new side) is not read; a
    /// read that fails is logged and that side is nil.
    public func sides(of diff: GitFileDiff, target: GitDiffTarget,
                      source: GitContentSource) async -> (old: [StyledLine]?, new: [StyledLine]?) {
        let revisions = Self.revisions(for: target)
        let old = await side(path: diff.oldPath, revision: revisions.old, source: source)
        // A caller that has moved on cancels its task; the second read would be wasted.
        if Task.isCancelled { return (old, nil) }
        let new = await side(path: diff.newPath, revision: revisions.new, source: source)
        return (old, new)
    }

    private func side(path: String?, revision: Revision, source: GitContentSource) async -> [StyledLine]? {
        guard let path else { return nil }
        let spec: String?
        switch revision {
        case .absent: return nil
        case .at(let value): spec = value
        case .workingFile: spec = nil
        }
        let data: Data?
        do {
            data = try await source.contents(path: path, at: spec)
        } catch {
            let description = (error as? GitClientError)?.logDescription ?? String(describing: type(of: error))
            Self.logger.error("Git contents for colouring failed: \(description, privacy: .public)")
            return nil
        }
        return await lines(for: data, path: path)
    }
}

extension GitSyntaxColoring: Loggable {
    public static nonisolated let logger = makeLogger()
}
