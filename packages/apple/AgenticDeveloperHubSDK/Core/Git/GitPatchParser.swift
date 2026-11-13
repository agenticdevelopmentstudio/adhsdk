import Foundation

/// The line-by-line state machine behind `GitDiff.parse(patch:)`.
///
/// A file starts at every `diff --git` line. Header lines (modes, similarity,
/// rename/copy, `---`/`+++`, binary markers) are read until the first `@@`;
/// a hunk then consumes exactly as many lines as its header counts, plus any
/// `\ No newline at end of file` markers, so a removed line that happens to
/// read `-- a/x` is never mistaken for a header.
struct GitPatchParser {
    private var files: [GitFileDiff] = []
    private var file: FileBuilder?
    private var hunk: HunkBuilder?

    static func parse(_ patch: String) -> [GitFileDiff] {
        var parser = GitPatchParser()
        // "\r\n" is one Character in Swift, so it has to be named as a separator of its own.
        var lines = patch.split(omittingEmptySubsequences: false) { $0 == "\n" || $0 == "\r\n" }
        if lines.last?.isEmpty == true { lines.removeLast() }
        for line in lines {
            parser.consume(line)
        }
        parser.flushFile()
        return parser.files
    }

    private mutating func consume(_ line: Substring) {
        // The hunk is mutated through the optional, in place, and never bound to a
        // local: a second reference would make every append copy its lines.
        if let accepted = hunk?.accepts(line) {
            if accepted {
                hunk?.append(line)
                return
            }
            flushHunk()
        }
        if line.hasPrefix("diff --git ") {
            flushFile()
            file = FileBuilder(diffGitLine: line.dropFirst("diff --git ".count))
            return
        }
        guard file != nil else { return }
        if line.hasPrefix("@@ ") {
            hunk = HunkBuilder(header: line)
            return
        }
        file?.readHeader(line)
    }

    private mutating func flushHunk() {
        if let built = hunk?.build() { file?.hunks.append(built) }
        hunk = nil
    }

    private mutating func flushFile() {
        flushHunk()
        if let built = file?.build() { files.append(built) }
        file = nil
    }
}

// MARK: - File header

private struct FileBuilder {
    var oldPath: String?
    var newPath: String?
    var oldMode: String?
    var newMode: String?
    var isNew = false
    var isDeleted = false
    var renamed = false
    var copied = false
    var similarity = 0
    var isBinary = false
    var hunks: [GitDiffHunk] = []

    init(diffGitLine rest: Substring) {
        let (old, new) = Self.splitPaths(rest)
        oldPath = old.map { Self.stripPrefix($0, "a/") }
        newPath = new.map { Self.stripPrefix($0, "b/") }
    }

    mutating func readHeader(_ line: Substring) {
        if let value = line.value(after: "old mode ") {
            oldMode = String(value)
        } else if let value = line.value(after: "new mode ") {
            newMode = String(value)
        } else if line.hasPrefix("new file mode ") {
            isNew = true
        } else if line.hasPrefix("deleted file mode ") {
            isDeleted = true
        } else if let value = line.value(after: "similarity index ") {
            similarity = Int(value.trimmingCharacters(in: CharacterSet(charactersIn: "%"))) ?? 0
        } else if let value = line.value(after: "rename from ") {
            renamed = true
            oldPath = GitPathUnquoting.unquote(String(value))
        } else if let value = line.value(after: "rename to ") {
            renamed = true
            newPath = GitPathUnquoting.unquote(String(value))
        } else if let value = line.value(after: "copy from ") {
            copied = true
            oldPath = GitPathUnquoting.unquote(String(value))
        } else if let value = line.value(after: "copy to ") {
            copied = true
            newPath = GitPathUnquoting.unquote(String(value))
        } else if let value = line.value(after: "--- ") {
            oldPath = Self.sidePath(value, prefix: "a/")
        } else if let value = line.value(after: "+++ ") {
            newPath = Self.sidePath(value, prefix: "b/")
        } else if line.hasPrefix("Binary files ") || line == "GIT binary patch" {
            isBinary = true
        }
    }

    func build() -> GitFileDiff? {
        var old = oldPath
        var new = newPath
        let change: GitFileDiff.Change
        if isNew || old == nil {
            change = .added
            old = nil
        } else if isDeleted || new == nil {
            change = .deleted
            new = nil
        } else if renamed {
            change = .renamed(similarity: similarity)
        } else if copied {
            change = .copied(similarity: similarity)
        } else if let oldMode, let newMode, oldMode.prefix(3) != newMode.prefix(3) {
            change = .typeChanged
        } else {
            change = .modified
        }
        guard old != nil || new != nil else { return nil }
        return GitFileDiff(oldPath: old, newPath: new, change: change,
                           isBinary: isBinary, hunks: isBinary ? [] : hunks)
    }

    /// A `---`/`+++` operand: `/dev/null` is no path; git appends a tab to an
    /// unquoted path that contains a space.
    private static func sidePath(_ value: Substring, prefix: String) -> String? {
        var raw = value
        if raw.last == "\t" { raw = raw.dropLast() }
        if raw == "/dev/null" { return nil }
        return stripPrefix(GitPathUnquoting.unquote(String(raw)), prefix)
    }

    private static func stripPrefix(_ path: String, _ prefix: String) -> String {
        path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
    }

    /// Splits `a/x b/y` (either side possibly C-quoted) into its two unquoted operands.
    /// An unquoted pair is ambiguous when the paths contain ` b/`; the `---`/`+++`
    /// and rename lines that follow override it whenever the file has them.
    private static func splitPaths(_ rest: Substring) -> (String?, String?) {
        if rest.first == "\"", let close = closingQuote(in: rest) {
            let first = rest[...close]
            let second = rest[rest.index(after: close)...].drop { $0 == " " }
            return (GitPathUnquoting.unquote(String(first)), GitPathUnquoting.unquote(String(second)))
        }
        if let quoted = rest.range(of: " \"b/") {
            return (String(rest[..<quoted.lowerBound]),
                    GitPathUnquoting.unquote(String(rest[rest.index(after: quoted.lowerBound)...])))
        }
        // Same path on both sides: `a/<p> b/<p>`, split exactly in the middle.
        let characters = Array(rest)
        if characters.count % 2 == 1 {
            let half = characters.count / 2
            let left = String(characters[..<half])
            let right = String(characters[(half + 1)...])
            if characters[half] == " ", left.hasPrefix("a/"), right.hasPrefix("b/"),
               left.dropFirst(2) == right.dropFirst(2) {
                return (left, right)
            }
        }
        if let split = rest.range(of: " b/") {
            return (String(rest[..<split.lowerBound]), String(rest[rest.index(after: split.lowerBound)...]))
        }
        return (String(rest), String(rest))
    }

    private static func closingQuote(in text: Substring) -> Substring.Index? {
        var index = text.index(after: text.startIndex)
        while index < text.endIndex {
            switch text[index] {
            case "\\":
                index = text.index(after: index)
                if index < text.endIndex { index = text.index(after: index) }
            case "\"":
                return index
            default:
                index = text.index(after: index)
            }
        }
        return nil
    }
}

// MARK: - Hunk body

private struct HunkBuilder {
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let section: String
    private(set) var lines: [GitDiffLine] = []
    private var oldNext: Int
    private var newNext: Int
    private var oldLeft: Int
    private var newLeft: Int
    private let valid: Bool

    init(header: Substring) {
        // @@ -o[,c] +n[,c] @@ section
        let body = header.dropFirst(3)
        let close = body.range(of: " @@")
        let ranges = close.map { body[..<$0.lowerBound] } ?? body
        var section = close.map { body[$0.upperBound...] } ?? ""
        section = section.drop { $0 == " " }
        self.section = section.trimmingCharacters(in: .whitespaces)
        let parts = ranges.split(separator: " ")
        let old = parts.first.flatMap { Self.range($0, sign: "-") }
        let new = parts.count > 1 ? Self.range(parts[1], sign: "+") : nil
        valid = old != nil && new != nil
        oldStart = old?.start ?? 0
        oldCount = old?.count ?? 0
        newStart = new?.start ?? 0
        newCount = new?.count ?? 0
        oldNext = oldStart
        newNext = newStart
        oldLeft = oldCount
        newLeft = newCount
    }

    /// Whether `line` still belongs to this hunk.
    func accepts(_ line: Substring) -> Bool {
        guard valid else { return false }
        // Prefixes are read as scalars: a combining mark after `+` would make one Character of both.
        let prefix = line.unicodeScalars.first
        if prefix == "\\" { return !lines.isEmpty }
        guard oldLeft > 0 || newLeft > 0 else { return false }
        switch prefix {
        case " ", nil: return oldLeft > 0 && newLeft > 0
        case "-": return oldLeft > 0
        case "+": return newLeft > 0
        default: return false
        }
    }

    mutating func append(_ line: Substring) {
        let text = String(line.unicodeScalars.dropFirst())
        switch line.unicodeScalars.first {
        case "\\":
            lines.append(GitDiffLine(kind: .noNewlineAtEnd, text: text, oldNumber: nil, newNumber: nil))
        case "-":
            lines.append(GitDiffLine(kind: .removed, text: text, oldNumber: oldNext, newNumber: nil))
            oldNext += 1
            oldLeft -= 1
        case "+":
            lines.append(GitDiffLine(kind: .added, text: text, oldNumber: nil, newNumber: newNext))
            newNext += 1
            newLeft -= 1
        default: // a context line, or an empty line some tools leave for one
            lines.append(GitDiffLine(kind: .context, text: text, oldNumber: oldNext, newNumber: newNext))
            oldNext += 1
            newNext += 1
            oldLeft -= 1
            newLeft -= 1
        }
    }

    func build() -> GitDiffHunk? {
        guard valid else { return nil }
        return GitDiffHunk(oldStart: oldStart, oldCount: oldCount, newStart: newStart,
                           newCount: newCount, section: section, lines: lines)
    }

    /// `-3,4` → (3, 4); `-3` → (3, 1).
    private static func range(_ token: Substring, sign: Character) -> (start: Int, count: Int)? {
        guard token.first == sign else { return nil }
        let numbers = token.dropFirst().split(separator: ",", omittingEmptySubsequences: false)
        guard let start = numbers.first.flatMap({ Int($0) }) else { return nil }
        if numbers.count == 1 { return (start, 1) }
        guard numbers.count == 2, let count = Int(numbers[1]) else { return nil }
        return (start, count)
    }
}

private extension Substring {
    /// The rest of the line after `prefix`, or `nil` when it does not start with it.
    func value(after prefix: String) -> Substring? {
        hasPrefix(prefix) ? dropFirst(prefix.count) : nil
    }
}
