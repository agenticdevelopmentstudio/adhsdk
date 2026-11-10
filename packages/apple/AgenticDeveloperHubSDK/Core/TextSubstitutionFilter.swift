import Foundation

/// Two-way word substitution between what the user sees and what a program is
/// given: the user writes an alias and the program receives the real text; the
/// program prints the real text and the user reads the alias.
///
/// Matching is case-insensitive, because a program prints a name however it
/// likes ("Mike", "mike", "MIKE") and every one of those is the same leak. The
/// replacement is written as given.
///
/// A single left-to-right pass rather than one `replacingOccurrences` per pair,
/// so a replacement is never itself rewritten by a later pair — "a = b; b = c"
/// sends "a" as "b", not as "c" (`principle-of-least-astonishment`). At each
/// position the longest pattern wins, so "mike fullerton" is replaced whole
/// before a shorter "mike" pair can split it.
public struct TextSubstitutionFilter: Sendable, Equatable {

    public struct Pair: Sendable, Equatable, Hashable, Codable {
        /// What the user writes and reads.
        public let alias: String
        /// What the program is given and prints.
        public let real: String

        public init(alias: String, real: String) {
            self.alias = alias
            self.real = real
        }
    }

    public let pairs: [Pair]

    /// Pairs with an empty side are dropped: an empty pattern matches
    /// everywhere, and an empty replacement silently deletes text.
    public init(pairs: [Pair]) {
        self.pairs = pairs.filter { !$0.alias.isEmpty && !$0.real.isEmpty }
    }

    /// A filter that changes nothing.
    public static let identity = TextSubstitutionFilter(pairs: [])

    /// Parses `alias = real` entries separated by `;` or newlines — the shape
    /// one text field can hold. An entry with no `=`, or with an empty side, is
    /// skipped rather than refused: this is typed by hand, a field at a time,
    /// and half an entry is the normal state of one being written.
    public init(parsing text: String) {
        let entries = text.split(whereSeparator: { $0 == ";" || $0.isNewline })
        let pairs = entries.compactMap { entry -> Pair? in
            guard let equals = entry.firstIndex(of: "=") else { return nil }
            let alias = entry[..<equals].trimmingCharacters(in: .whitespaces)
            let real = entry[entry.index(after: equals)...].trimmingCharacters(in: .whitespaces)
            return Pair(alias: alias, real: real)
        }
        self.init(pairs: pairs)
    }

    /// The text form `init(parsing:)` reads back.
    public var serialized: String {
        pairs.map { "\($0.alias) = \($0.real)" }.joined(separator: "; ")
    }

    /// Aliases replaced by the real text — for what goes *to* the program.
    /// `matchingCase` writes each replacement in the case of the text it
    /// replaces (`casing(_:like:)`) rather than as given.
    public func revealing(_ text: String, matchingCase: Bool = false) -> String {
        Self.substitute(in: text, pairs.map { ($0.alias, $0.real) }, matchingCase: matchingCase)
    }

    /// Real text replaced by aliases — for what comes *back* to the user.
    public func concealing(_ text: String, matchingCase: Bool = false) -> String {
        Self.substitute(in: text, pairs.map { ($0.real, $0.alias) }, matchingCase: matchingCase)
    }

    /// `replacement` in the case of `match`: all capitals, all lower case, or
    /// a capital and then lower case; anything else (mixed, or no letters)
    /// keeps `replacement` as given. "BLUEBIRD", "bluebird" and "Bluebird"
    /// become "REDBIRD", "redbird" and "Redbird" whatever case the pair was
    /// written in. `BrowserPageWordFilter.js` applies the same rule.
    public static func casing(_ replacement: String, like match: String) -> String {
        let upper = match.uppercased(), lower = match.lowercased()
        if match == upper && match != lower { return replacement.uppercased() }
        if match == lower && match != upper { return replacement.lowercased() }
        let first = String(match.prefix(1)), rest = String(match.dropFirst())
        if first == first.uppercased() && first != first.lowercased() && rest == rest.lowercased() {
            return replacement.prefix(1).uppercased() + replacement.dropFirst().lowercased()
        }
        return replacement
    }

    private static func substitute(
        in text: String, _ mapping: [(String, String)], matchingCase: Bool
    ) -> String {
        guard !mapping.isEmpty else { return text }
        let longestFirst = mapping.sorted { $0.0.count > $1.0.count }

        var result = ""
        var index = text.startIndex
        scanning: while index < text.endIndex {
            for (pattern, replacement) in longestFirst {
                if let match = text.range(
                    of: pattern,
                    options: [.caseInsensitive, .anchored],
                    range: index..<text.endIndex
                ) {
                    result += matchingCase ? casing(replacement, like: String(text[match])) : replacement
                    index = match.upperBound
                    continue scanning
                }
            }
            result.append(text[index])
            index = text.index(after: index)
        }
        return result
    }
}
