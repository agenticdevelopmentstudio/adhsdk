import Foundation

/// Where a privacy word applies among the private terminals: `.gitignore`
/// patterns (``GitIgnoreMatcher``) matched against the directory a private
/// terminal started in — the same pattern language the File Browser's
/// excluded files use, so a list copied out of a `.gitignore` reads the same.
///
/// - `*` is every private terminal.
/// - A pattern with no `/` matches a directory of that name at any depth, and
///   everything under it: `adkitchen` covers `~/Development/adkitchen/App`.
/// - A pattern with a `/` is anchored at the root of the disk, with a leading
///   `~` meaning the home folder: `~/work/**`, `/Volumes/Client`.
/// - `!` re-includes what an earlier pattern matched; the last match decides.
/// - No patterns at all is no private terminal.
///
/// A terminal with no known directory (none was given) has only `*` words.
public enum PrivacyTerminalPattern {

    /// Every private terminal.
    public static let everywhere = "*"

    /// The patterns in a comma-separated cell, trimmed, empties dropped.
    public static func parse(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// The patterns as one comma-separated cell.
    public static func format(_ patterns: [String]) -> String {
        patterns.joined(separator: ", ")
    }

    /// Whether `patterns` cover a private terminal started in `directory`.
    public static func matches(_ patterns: [String], directory: String?) -> Bool {
        guard !patterns.isEmpty else { return false }
        guard let directory, !directory.isEmpty else { return patterns.contains(everywhere) }
        let matcher = GitIgnoreMatcher(patterns: patterns.map(expandingHome))
        let path = (expandingHome(directory) as NSString).standardizingPath
        let components = path.split(separator: "/").map(String.init)
        guard !components.isEmpty else { return patterns.contains(everywhere) }
        // A directory a pattern matches covers everything under it, as an
        // excluded directory does in git: test each ancestor, outermost first.
        for end in 1...components.count {
            let prefix = components[0..<end].joined(separator: "/")
            if matcher.isExcluded(relativePath: prefix, isDirectory: true) { return true }
        }
        return false
    }

    /// `~` and `~/…` (after any `!`) with the home folder spelled out.
    static func expandingHome(_ pattern: String) -> String {
        let negated = pattern.hasPrefix("!")
        let body = negated ? String(pattern.dropFirst()) : pattern
        guard body == "~" || body.hasPrefix("~/") else { return pattern }
        return (negated ? "!" : "") + (body as NSString).expandingTildeInPath
    }
}
