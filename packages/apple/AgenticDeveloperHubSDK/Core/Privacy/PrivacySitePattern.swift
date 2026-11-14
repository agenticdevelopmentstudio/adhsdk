import Foundation

/// Where a privacy word applies, as site patterns (``PrivacyWord/sites``).
///
/// - `*` alone: everywhere — every web page and every private terminal.
/// - Otherwise `host[/path]`, each part a glob in which `*` matches any run
///   of characters: `google.com/*`, `foo.com/hi/*`, `*.google.com`. A pattern
///   with no path matches every path on its host. Hosts compare without
///   regard to case; paths with it.
///
/// Only `*` applies where there is no address, as in a private terminal.
public enum PrivacySitePattern {

    /// The pattern that applies everywhere.
    public static let everywhere = "*"

    /// Splits the comma-separated text the editor shows into patterns,
    /// trimmed, empties dropped.
    public static func parse(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// The patterns as the editor shows them.
    public static func format(_ patterns: [String]) -> String {
        patterns.joined(separator: ", ")
    }

    /// The pattern a word added on `url`'s page starts with: its host and
    /// every path under it, or `*` for a page with no host.
    public static func defaultPattern(for url: URL?) -> String {
        guard let host = url?.host?.lowercased(), !host.isEmpty else { return everywhere }
        return host + "/*"
    }

    /// Whether `pattern` applies at `url`; `nil` is a place with no address.
    public static func matches(_ pattern: String, url: URL?) -> Bool {
        let pattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if pattern == everywhere { return true }
        guard let url, let host = url.host, !host.isEmpty, !pattern.isEmpty else { return false }
        var hostPattern = Substring(pattern)
        var pathPattern: Substring?
        // A scheme someone typed is ignored: the pattern names a site.
        if let range = hostPattern.range(of: "://") { hostPattern = hostPattern[range.upperBound...] }
        if let slash = hostPattern.firstIndex(of: "/") {
            pathPattern = hostPattern[slash...]
            hostPattern = hostPattern[..<slash]
        }
        guard glob(hostPattern.lowercased(), matches: host.lowercased()) else { return false }
        guard let pathPattern else { return true }
        let path = url.path.isEmpty ? "/" : url.path
        // `foo.com/hi/*` also covers `foo.com/hi` itself.
        if pathPattern.hasSuffix("/*"), path == String(pathPattern.dropLast(2)) { return true }
        return glob(String(pathPattern), matches: path)
    }

    /// `*`-only glob matching: iterative, backtracking to the last star.
    static func glob(_ pattern: String, matches text: String) -> Bool {
        let pattern = Array(pattern)
        let text = Array(text)
        var patternIndex = 0
        var textIndex = 0
        var star: Int?
        var starText = 0
        while textIndex < text.count {
            if patternIndex < pattern.count, pattern[patternIndex] == "*" {
                star = patternIndex
                starText = textIndex
                patternIndex += 1
            } else if patternIndex < pattern.count, pattern[patternIndex] == text[textIndex] {
                patternIndex += 1
                textIndex += 1
            } else if let star {
                patternIndex = star + 1
                starText += 1
                textIndex = starText
            } else {
                return false
            }
        }
        while patternIndex < pattern.count, pattern[patternIndex] == "*" { patternIndex += 1 }
        return patternIndex == pattern.count
    }
}
