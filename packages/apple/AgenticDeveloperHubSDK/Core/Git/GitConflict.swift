import Foundation

/// How a path is unmerged: the seven `XY` pairs `git status` documents for a conflict, the
/// first letter being our side (stage 2) and the second their side (stage 3).
public enum GitConflictKind: String, Sendable, Hashable, CaseIterable {
    case bothModified = "UU", bothAdded = "AA", deletedByUs = "DU", deletedByThem = "UD"
    case addedByUs = "AU", addedByThem = "UA", bothDeleted = "DD"

    /// Whether our side of the file exists (an index entry at stage 2).
    public var hasOurs: Bool {
        switch self {
        case .bothModified, .bothAdded, .deletedByThem, .addedByUs: true
        case .deletedByUs, .addedByThem, .bothDeleted: false
        }
    }

    /// Whether their side of the file exists (an index entry at stage 3).
    public var hasTheirs: Bool {
        switch self {
        case .bothModified, .bothAdded, .deletedByUs, .addedByThem: true
        case .deletedByThem, .addedByUs, .bothDeleted: false
        }
    }

    /// Whether git wrote conflict markers into the working file: only when both sides exist.
    public var hasMarkers: Bool {
        self == .bothModified || self == .bothAdded
    }
}

/// Which side of a conflict `git checkout --ours|--theirs` takes.
public enum GitConflictSide: String, Sendable, Hashable {
    case ours, theirs
}

/// A conflicted file's text as git leaves it in the working tree: common runs of lines, and
/// between them each conflict's two sides (and, under `merge.conflictStyle=diff3` or
/// `zdiff3`, the base), read from the seven-character markers git writes.
public struct GitConflictDocument: Sendable, Hashable {
    public enum Segment: Sendable, Hashable {
        case common([String])
        case conflict(ours: [String], base: [String]?, theirs: [String], oursLabel: String, theirsLabel: String)
    }

    /// What one conflict resolves to: one side, both in either order, or the base.
    public enum Choice: String, Sendable, Hashable, CaseIterable {
        case ours, theirs, oursThenTheirs, theirsThenOurs, base
    }

    public var segments: [Segment]
    /// Whether the text ended with a newline, so a resolution ends the same way.
    public var endsWithNewline: Bool

    public init(segments: [Segment], endsWithNewline: Bool) {
        self.segments = segments
        self.endsWithNewline = endsWithNewline
    }

    public var conflictCount: Int {
        segments.reduce(0) { count, segment in
            if case .conflict = segment { return count + 1 }
            return count
        }
    }

    /// The marker length git writes unless a `conflict-marker-size` attribute says otherwise.
    static let markerLength = 7

    private enum Marker {
        case start(String), base, separator, end(String)
    }

    /// Where the parser is: in common text, or in one of a conflict's three sections.
    private enum Section {
        case common, ours, base, theirs
    }

    /// The document in `text`, or nil when it holds no complete conflict: no `<<<<<<<` at all,
    /// or one that is never closed by `>>>>>>>`. Lines split on `\n`; a `\r` before it stays
    /// part of the line (and is ignored when reading a marker). A marker is exactly seven of
    /// its character at the start of a line, followed by the end of the line or a space and a
    /// label; `=======` takes no label. Text that looks like a marker where none is expected
    /// (a `=======` outside a conflict, a second `<<<<<<<` inside one) is ordinary text.
    public static func parse(_ text: String) -> GitConflictDocument? {
        var lines = text.components(separatedBy: "\n")
        // By scalar: `"\r\n"` is one `Character`, so `hasSuffix("\n")` would miss it.
        let endsWithNewline = text.unicodeScalars.last == "\n"
        if endsWithNewline { lines.removeLast() }

        var segments: [Segment] = []
        var common: [String] = []
        var ours: [String] = []
        var base: [String]?
        var theirs: [String] = []
        var oursLabel = ""
        var section = Section.common

        for line in lines {
            let marker = Self.marker(in: line)
            switch (section, marker) {
            case (.common, .start(let label)?):
                if !common.isEmpty { segments.append(.common(common)) }
                common = []
                ours = []
                base = nil
                theirs = []
                oursLabel = label
                section = .ours
            case (.common, _):
                common.append(line)
            case (.ours, .base?):
                base = []
                section = .base
            case (.ours, .separator?), (.base, .separator?):
                section = .theirs
            case (.ours, _):
                ours.append(line)
            case (.base, _):
                base?.append(line)
            case (.theirs, .end(let label)?):
                segments.append(.conflict(ours: ours, base: base, theirs: theirs, oursLabel: oursLabel,
                                          theirsLabel: label))
                section = .common
            case (.theirs, _):
                theirs.append(line)
            }
        }
        guard section == .common else { return nil }
        if !common.isEmpty { segments.append(.common(common)) }
        let document = GitConflictDocument(segments: segments, endsWithNewline: endsWithNewline)
        return document.conflictCount > 0 ? document : nil
    }

    /// The text with conflict `n` (counting from 0, in order) replaced by `choices[n]`, or nil
    /// until every conflict has a choice, or when a conflict chosen `.base` has no base.
    public func resolved(_ choices: [Int: Choice]) -> String? {
        var lines: [String] = []
        var index = 0
        for segment in segments {
            switch segment {
            case .common(let common):
                lines += common
            case let .conflict(ours, base, theirs, _, _):
                guard let choice = choices[index] else { return nil }
                index += 1
                switch choice {
                case .ours: lines += ours
                case .theirs: lines += theirs
                case .oursThenTheirs: lines += ours + theirs
                case .theirsThenOurs: lines += theirs + ours
                case .base:
                    guard let base else { return nil }
                    lines += base
                }
            }
        }
        guard !lines.isEmpty else { return "" }
        return lines.joined(separator: "\n") + (endsWithNewline ? "\n" : "")
    }

    private static func marker(in rawLine: String) -> Marker? {
        let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
        guard let first = line.first, "<|=>".contains(first) else { return nil }
        let run = String(repeating: first, count: markerLength)
        guard line.hasPrefix(run) else { return nil }
        let rest = line.dropFirst(markerLength)
        if first == "=" { return rest.isEmpty ? .separator : nil }
        guard rest.isEmpty || rest.first == " " else { return nil }
        let label = String(rest.dropFirst())
        switch first {
        case "<": return .start(label)
        case "|": return .base
        default: return .end(label)
        }
    }
}
