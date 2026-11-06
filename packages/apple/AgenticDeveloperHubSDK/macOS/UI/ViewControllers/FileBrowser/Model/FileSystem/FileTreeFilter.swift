import AgenticDeveloperHubSDKCore
import Foundation

/// What a file tree leaves out: a `.gitignore`-style matcher, and the root its
/// anchored patterns (`/dist`, `docs/*.pdf`) are anchored to.
///
/// A value, so a background read can carry the filter it started with and a
/// change on main never races it.
public struct FileTreeFilter: Sendable, Equatable {

    /// The directory the patterns are relative to — the browser root.
    public let rootPath: String

    public let matcher: GitIgnoreMatcher

    /// A filter that leaves nothing out.
    public static let none = FileTreeFilter(rootURL: URL(fileURLWithPath: "/"), matcher: .empty)

    public init(rootURL: URL, matcher: GitIgnoreMatcher) {
        self.rootPath = rootURL.standardizedFileURL.path
        self.matcher = matcher
    }

    /// Whether `url` is left out of the tree.
    public func excludes(_ url: URL, isDirectory: Bool) -> Bool {
        guard !matcher.isEmpty else { return false }
        return matcher.isExcluded(relativePath: relativePath(of: url), isDirectory: isDirectory)
    }

    /// `url`'s path below the root. A URL outside the root is matched by its
    /// name alone, which is what an unanchored pattern wants and what an
    /// anchored one can never match by accident.
    func relativePath(of url: URL) -> String {
        let path = url.standardizedFileURL.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        if path.hasPrefix(prefix) { return String(path.dropFirst(prefix.count)) }
        return url.lastPathComponent
    }
}
