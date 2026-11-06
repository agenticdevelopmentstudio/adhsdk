import Foundation

/// Decides whether a path is excluded by a list of `.gitignore`-style patterns.
///
/// The patterns mean what they mean in a `.gitignore`, so a list copied out of
/// one behaves the same here:
///
/// - Blank lines and lines starting with `#` are ignored.
/// - A pattern with no `/` except a trailing one matches a name at any depth:
///   `*.log`, `node_modules`, `build/`.
/// - A pattern with a `/` at its start or in its middle is anchored to the
///   root and matched against the whole relative path: `/dist`, `docs/*.pdf`.
/// - A trailing `/` matches directories only.
/// - `*` matches anything but `/`, `?` one character but `/`, `[abc]` and
///   `[!abc]` a character class; `**` crosses directories, as `**/foo`,
///   `foo/**` and `a/**/b`.
/// - A leading `!` re-includes what an earlier pattern excluded. The last
///   pattern that matches decides, as in git.
///
/// Matching is case-sensitive, as git's is by default.
///
/// It never looks at the file system: a caller that stops descending into an
/// excluded directory gets "everything inside it is excluded" for free, which
/// is also how git behaves — a file inside an excluded directory cannot be
/// re-included by a later `!` pattern.
public struct GitIgnoreMatcher: Sendable, Equatable {

    /// One parsed pattern line.
    struct Rule: Sendable, Equatable {
        let source: String
        let isNegated: Bool
        let directoriesOnly: Bool
        /// Matched against the whole relative path rather than the last name.
        let isAnchored: Bool
        let regex: String
    }

    /// The pattern lines as given, comments and blanks included.
    public let patterns: [String]

    let rules: [Rule]

    /// A matcher that excludes nothing.
    public static let empty = GitIgnoreMatcher(patterns: [])

    public init(patterns: [String]) {
        self.patterns = patterns
        self.rules = patterns.compactMap(Self.parse)
    }

    /// Whether nothing would ever be excluded.
    public var isEmpty: Bool { rules.isEmpty }

    /// Whether `relativePath` — `/`-separated, relative to the root the
    /// patterns are anchored at, with no leading `/` — is excluded.
    public func isExcluded(relativePath: String, isDirectory: Bool) -> Bool {
        let path = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !path.isEmpty else { return false }
        let name = path.split(separator: "/").last.map(String.init) ?? path
        var excluded = false
        for rule in rules {
            if rule.directoriesOnly && !isDirectory { continue }
            let subject = rule.isAnchored ? path : name
            if Self.matches(rule.regex, subject) {
                excluded = !rule.isNegated
            }
        }
        return excluded
    }

    // MARK: - Parsing

    static func parse(_ line: String) -> Rule? {
        var text = line
        // Trailing spaces are dropped unless escaped; leading ones are kept,
        // as git keeps them.
        while text.hasSuffix(" ") && !text.hasSuffix("\\ ") { text.removeLast() }
        guard !text.isEmpty, !text.hasPrefix("#") else { return nil }

        var isNegated = false
        if text.hasPrefix("!") {
            isNegated = true
            text.removeFirst()
        } else if text.hasPrefix("\\!") || text.hasPrefix("\\#") {
            text.removeFirst()
        }

        var directoriesOnly = false
        while text.hasSuffix("/") {
            directoriesOnly = true
            text.removeLast()
        }
        guard !text.isEmpty else { return nil }

        let isAnchored = text.contains("/")
        if text.hasPrefix("/") { text.removeFirst() }
        guard !text.isEmpty else { return nil }

        return Rule(
            source: line,
            isNegated: isNegated,
            directoriesOnly: directoriesOnly,
            isAnchored: isAnchored,
            regex: "^" + regexBody(for: text) + "$")
    }

    /// The glob translated to a regular expression body.
    static func regexBody(for glob: String) -> String {
        let characters = Array(glob)
        var regex = ""
        var index = 0
        while index < characters.count {
            let character = characters[index]
            switch character {
            case "*":
                let isDouble = index + 1 < characters.count && characters[index + 1] == "*"
                if isDouble {
                    let atStart = index == 0 || characters[index - 1] == "/"
                    let followedBySlash = index + 2 < characters.count && characters[index + 2] == "/"
                    let atEnd = index + 2 == characters.count
                    if atStart && followedBySlash {
                        // `**/` — zero or more whole directories.
                        regex += "(?:.*/)?"
                        index += 3
                        continue
                    }
                    if atStart && atEnd {
                        // `/**` at the end — everything inside.
                        regex += ".*"
                        index += 2
                        continue
                    }
                    // `**` anywhere else is two `*`s, as in git.
                    regex += "[^/]*"
                    index += 2
                    continue
                }
                regex += "[^/]*"
            case "?":
                regex += "[^/]"
            case "[":
                if let close = classEnd(in: characters, from: index) {
                    var body = String(characters[(index + 1)..<close])
                    if body.hasPrefix("!") { body = "^" + body.dropFirst() }
                    regex += "[" + body.replacingOccurrences(of: "\\", with: "\\\\") + "]"
                    index = close + 1
                    continue
                }
                regex += "\\["
            case "\\":
                if index + 1 < characters.count {
                    regex += NSRegularExpression.escapedPattern(for: String(characters[index + 1]))
                    index += 2
                    continue
                }
                regex += "\\\\"
            default:
                regex += NSRegularExpression.escapedPattern(for: String(character))
            }
            index += 1
        }
        return regex
    }

    /// The index of the `]` closing the class opened at `start`, or nil when
    /// it is never closed — an unclosed `[` is a literal bracket.
    private static func classEnd(in characters: [Character], from start: Int) -> Int? {
        var index = start + 1
        if index < characters.count, characters[index] == "!" { index += 1 }
        // A `]` straight after the opening is a member, not the close.
        if index < characters.count, characters[index] == "]" { index += 1 }
        while index < characters.count {
            if characters[index] == "]" { return index }
            index += 1
        }
        return nil
    }

    private static func matches(_ pattern: String, _ subject: String) -> Bool {
        subject.range(of: pattern, options: .regularExpression) != nil
    }
}
