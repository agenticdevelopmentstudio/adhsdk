import Foundation

/// Word-level highlighting inside a changed line, computed client-side so one
/// `git diff` call serves both the line view and the word view.
public enum GitWordDiff {
    /// Above this many cells (old tokens × new tokens, after the common prefix and
    /// suffix are trimmed) the middle is marked changed as a whole instead of running
    /// the quadratic LCS, so a minified line cannot stall the caller.
    static let maximumTableCells = 1_000_000

    /// Character ranges (UTF-16 NSRange) that differ between a removed and an added line,
    /// by an LCS over word tokens (runs of letters/digits/_ , runs of whitespace, single punctuation).
    public static func changedRanges(old: String, new: String) -> (old: [NSRange], new: [NSRange]) {
        if old == new { return ([], []) }
        let oldTokens = tokens(of: old)
        let newTokens = tokens(of: new)
        // Tokens are compared as interned integers, which keeps the LCS table loop cheap.
        var ids: [Substring: Int] = [:]
        func intern(_ token: Token) -> Int {
            if let id = ids[token.text] { return id }
            let id = ids.count
            ids[token.text] = id
            return id
        }
        let (oldChanged, newChanged) = changedTokens(oldTokens.map(intern), newTokens.map(intern))
        return (ranges(oldTokens, changed: oldChanged), ranges(newTokens, changed: newChanged))
    }

    /// Pairs the removed and added lines of each change block in a hunk, in order
    /// (the i-th removed with the i-th added). Indices are into `hunk.lines`.
    public static func pairs(in hunk: GitDiffHunk) -> [(removed: Int, added: Int)] {
        var result: [(removed: Int, added: Int)] = []
        var removed: [Int] = []
        var added: [Int] = []
        func flush() {
            for (old, new) in zip(removed, added) { result.append((removed: old, added: new)) }
            removed.removeAll()
            added.removeAll()
        }
        for (index, line) in hunk.lines.enumerated() {
            switch line.kind {
            case .removed:
                if !added.isEmpty { flush() }
                removed.append(index)
            case .added:
                added.append(index)
            case .context:
                flush()
            case .noNewlineAtEnd:
                continue
            }
        }
        flush()
        return result
    }

    // MARK: - Tokens

    struct Token {
        let text: Substring
        let range: NSRange
    }

    private enum TokenClass {
        case word, space, punctuation
    }

    static func tokens(of line: String) -> [Token] {
        var result: [Token] = []
        var start = line.startIndex
        var offset = 0
        var startOffset = 0
        var current: TokenClass?
        for index in line.indices {
            let character = line[index]
            let kind = tokenClass(character)
            if let running = current, running != kind || kind == .punctuation {
                let range = NSRange(location: startOffset, length: offset - startOffset)
                result.append(Token(text: line[start..<index], range: range))
                start = index
                startOffset = offset
            }
            current = kind
            offset += character.utf16.count
        }
        if current != nil {
            let range = NSRange(location: startOffset, length: offset - startOffset)
            result.append(Token(text: line[start...], range: range))
        }
        return result
    }

    private static func tokenClass(_ character: Character) -> TokenClass {
        if character == "_" || character.isLetter || character.isNumber { return .word }
        if character.isWhitespace { return .space }
        return .punctuation
    }

    // MARK: - LCS

    /// Flags, per token, whether it is outside the longest common subsequence.
    static func changedTokens(_ old: [Int], _ new: [Int]) -> ([Bool], [Bool]) {
        var oldChanged = Array(repeating: true, count: old.count)
        var newChanged = Array(repeating: true, count: new.count)
        var prefix = 0
        while prefix < old.count, prefix < new.count, old[prefix] == new[prefix] {
            oldChanged[prefix] = false
            newChanged[prefix] = false
            prefix += 1
        }
        var suffix = 0
        while suffix < old.count - prefix, suffix < new.count - prefix,
              old[old.count - 1 - suffix] == new[new.count - 1 - suffix] {
            oldChanged[old.count - 1 - suffix] = false
            newChanged[new.count - 1 - suffix] = false
            suffix += 1
        }
        let oldMiddle = Array(old[prefix..<(old.count - suffix)])
        let newMiddle = Array(new[prefix..<(new.count - suffix)])
        let rows = oldMiddle.count
        let columns = newMiddle.count
        guard rows > 0, columns > 0, rows * columns <= maximumTableCells else { return (oldChanged, newChanged) }

        // table[row * width + column] = LCS length of oldMiddle[row...] and newMiddle[column...].
        let width = columns + 1
        var table = Array(repeating: 0, count: (rows + 1) * width)
        for row in stride(from: rows - 1, through: 0, by: -1) {
            for column in stride(from: columns - 1, through: 0, by: -1) {
                table[row * width + column] = oldMiddle[row] == newMiddle[column]
                    ? table[(row + 1) * width + column + 1] + 1
                    : max(table[(row + 1) * width + column], table[row * width + column + 1])
            }
        }
        var row = 0
        var column = 0
        while row < rows, column < columns {
            if oldMiddle[row] == newMiddle[column] {
                oldChanged[prefix + row] = false
                newChanged[prefix + column] = false
                row += 1
                column += 1
            } else if table[(row + 1) * width + column] >= table[row * width + column + 1] {
                row += 1
            } else {
                column += 1
            }
        }
        return (oldChanged, newChanged)
    }

    /// Merges the ranges of adjacent changed tokens.
    private static func ranges(_ tokens: [Token], changed: [Bool]) -> [NSRange] {
        var result: [NSRange] = []
        for (token, isChanged) in zip(tokens, changed) where isChanged {
            if let last = result.last, NSMaxRange(last) == token.range.location {
                result[result.count - 1].length += token.range.length
            } else {
                result.append(token.range)
            }
        }
        return result
    }
}
