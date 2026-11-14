import Foundation

/// The history search box's text as a `GitLogQuery` (recipe `workspace/git/git-views`,
/// history-search-parse). Pure: one form per search, read from the text trimmed of whitespace.
///
/// - `author:<x>` (prefix in any case) → `author`
/// - `sha:<x>` (prefix in any case) → no filter; the view selects the loaded commit (`shaPrefix`)
/// - `-S <x>` or `-S<x>` → `pickaxe`
/// - anything else → `messageGrep`, the whole text
///
/// Empty text, or a prefix with nothing after it, is no filter.
public enum GitHistorySearch {

    /// The query for `text`: the default revisions, limit and skip, with at most one filter.
    public static func parse(_ text: String) -> GitLogQuery {
        var query = GitLogQuery()
        switch form(of: text) {
        case .none, .sha: break
        case .author(let author): query.author = author
        case .pickaxe(let needle): query.pickaxe = needle
        case .message(let grep): query.messageGrep = grep
        }
        return query
    }

    /// The lowercased prefix of a `sha:` search; nil for every other form.
    public static func shaPrefix(_ text: String) -> String? {
        if case .sha(let prefix) = form(of: text) { return prefix }
        return nil
    }

    private enum Form {
        case none
        case author(String)
        case sha(String)
        case pickaxe(String)
        case message(String)
    }

    private static func form(of text: String) -> Form {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }
        if let author = value(after: "author:", in: trimmed, caseInsensitive: true) {
            return author.isEmpty ? .none : .author(author)
        }
        if let sha = value(after: "sha:", in: trimmed, caseInsensitive: true) {
            return sha.isEmpty ? .none : .sha(sha.lowercased())
        }
        if let needle = value(after: "-S", in: trimmed, caseInsensitive: false) {
            return needle.isEmpty ? .none : .pickaxe(needle)
        }
        return .message(trimmed)
    }

    /// The trimmed text after `prefix`, or nil when `text` does not start with it.
    private static func value(after prefix: String, in text: String, caseInsensitive: Bool) -> String? {
        let head = text.prefix(prefix.count)
        let matches = caseInsensitive ? head.lowercased() == prefix : head == prefix
        guard matches else { return nil }
        return text.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
