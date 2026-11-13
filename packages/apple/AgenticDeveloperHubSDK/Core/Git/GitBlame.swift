import Foundation

/// A file's blame, parsed from `git blame --porcelain`.
public struct GitBlame: Sendable, Hashable {
    public struct Commit: Sendable, Hashable {
        /// The commit and path this line came from before `id` changed it.
        public struct Previous: Sendable, Hashable {
            public let id: String
            public let path: String

            public init(id: String, path: String) {
                self.id = id
                self.path = path
            }
        }

        public let id: String
        public let author: GitPerson
        public let summary: String
        public let previous: Previous?

        public init(id: String, author: GitPerson, summary: String, previous: Previous?) {
            self.id = id
            self.author = author
            self.summary = summary
            self.previous = previous
        }
    }

    public struct Line: Sendable, Hashable {
        public let commitID: String
        public let originalLine: Int
        public let finalLine: Int
        public let text: String

        public init(commitID: String, originalLine: Int, finalLine: Int, text: String) {
            self.commitID = commitID
            self.originalLine = originalLine
            self.finalLine = finalLine
            self.text = text
        }
    }

    /// Consecutive final lines that belong to one commit.
    public struct Run: Sendable, Hashable {
        public let commitID: String
        public let finalLines: ClosedRange<Int>

        public init(commitID: String, finalLines: ClosedRange<Int>) {
            self.commitID = commitID
            self.finalLines = finalLines
        }
    }

    public let lines: [Line]
    public let commits: [String: Commit]

    public init(lines: [Line], commits: [String: Commit]) {
        self.lines = lines
        self.commits = commits
    }

    /// Maximal runs of consecutive final lines of one commit, in final-line order.
    public var runs: [Run] {
        var result: [Run] = []
        for line in lines {
            if let last = result.last, last.commitID == line.commitID,
               last.finalLines.upperBound + 1 == line.finalLine {
                result[result.count - 1] = Run(commitID: last.commitID,
                                               finalLines: last.finalLines.lowerBound...line.finalLine)
            } else {
                result.append(Run(commitID: line.commitID, finalLines: line.finalLine...line.finalLine))
            }
        }
        return result
    }

    /// Parses already-decoded `blame --porcelain` output. Metadata comes only the
    /// first time a commit appears; `boundary`, `filename`, the committer fields and
    /// anything unknown are skipped.
    public static func parse(porcelain: String) -> GitBlame {
        var lines: [Line] = []
        var details: [String: Details] = [:]
        var header: (id: String, original: Int, finalLine: Int)?

        for raw in porcelain.split(omittingEmptySubsequences: true, whereSeparator: { $0 == "\n" || $0 == "\r\n" }) {
            if raw.unicodeScalars.first == "\t" {
                if let current = header {
                    lines.append(Line(commitID: current.id, originalLine: current.original,
                                      finalLine: current.finalLine, text: String(raw.unicodeScalars.dropFirst())))
                }
                header = nil
                continue
            }
            if let parsed = parseHeader(raw) {
                header = parsed
                continue
            }
            guard let id = header?.id else { continue }
            let (key, value) = split(raw)
            var entry = details[id] ?? Details()
            switch key {
            case "author": entry.name = value
            case "author-mail": entry.email = value.trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
            case "author-time": entry.time = Int64(value)
            case "summary": entry.summary = value
            case "previous":
                let parts = value.split(separator: " ", maxSplits: 1)
                if parts.count == 2 { entry.previous = Commit.Previous(id: String(parts[0]),
                                                                     path: GitPathUnquoting.unquote(String(parts[1]))) }
            default: continue
            }
            details[id] = entry
        }

        let commits = details.reduce(into: [String: Commit]()) { result, pair in
            let entry = pair.value
            result[pair.key] = Commit(
                id: pair.key,
                author: GitPerson(name: entry.name, email: entry.email,
                                  date: Date(timeIntervalSince1970: TimeInterval(entry.time ?? 0))),
                summary: entry.summary,
                previous: entry.previous
            )
        }
        return GitBlame(lines: lines, commits: commits)
    }

    private struct Details {
        var name = ""
        var email = ""
        var time: Int64?
        var summary = ""
        var previous: Commit.Previous?
    }

    /// `<sha> <original> <final>[ <group size>]`, the sha 40 or 64 hex digits.
    private static func parseHeader(_ line: Substring) -> (id: String, original: Int, finalLine: Int)? {
        let parts = line.split(separator: " ")
        guard parts.count == 3 || parts.count == 4,
              parts[0].count == 40 || parts[0].count == 64,
              parts[0].allSatisfy(\.isHexDigit),
              let original = Int(parts[1]), let finalLine = Int(parts[2]) else { return nil }
        return (String(parts[0]), original, finalLine)
    }

    private static func split(_ line: Substring) -> (key: Substring, value: String) {
        guard let space = line.firstIndex(of: " ") else { return (line, "") }
        return (line[..<space], String(line[line.index(after: space)...]))
    }
}
