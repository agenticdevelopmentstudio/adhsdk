import Foundation

/// Some of one file's changed lines, chosen from a parsed diff: what `GitPatchBuilder`
/// turns into a patch that stages, unstages or discards just those lines.
public struct GitPatchSelection: Sendable, Hashable {
    public var file: GitFileDiff
    /// Hunk index → indices into that hunk's `lines`. Only `.added` and `.removed` lines
    /// count; an index naming a context line or a marker is ignored.
    public var lines: [Int: IndexSet]

    public init(file: GitFileDiff, lines: [Int: IndexSet]) {
        self.file = file
        self.lines = lines
    }

    /// Every changed line of hunk `index` of `file`; nothing when there is no such hunk.
    public static func hunk(_ index: Int, of file: GitFileDiff) -> GitPatchSelection {
        guard file.hunks.indices.contains(index) else { return GitPatchSelection(file: file, lines: [:]) }
        let lines = file.hunks[index].lines
        let changed = lines.indices.filter { GitPatchBuilder.isChange(lines[$0]) }
        return GitPatchSelection(file: file, lines: [index: IndexSet(changed)])
    }
}

/// Which way the built patch is applied.
public enum GitPatchDirection: Sendable {
    /// Applied as written: staging from the unstaged diff. The patch's old side is the
    /// diff's old side (the index).
    case forward
    /// Applied with `--reverse`: unstaging from the staged diff, discarding from the
    /// unstaged diff. The patch's new side is the diff's new side (the target).
    case reverse
}

/// Builds a unified patch holding only the selected lines of one file's diff.
///
/// **Forward:** a selected `+` is kept; an unselected `+` is dropped; a selected `-` is
/// kept; an unselected `-` becomes context. **Reverse:** a selected line is kept; an
/// unselected `+` becomes context; an unselected `-` is dropped. Either way the side the
/// patch is applied to stays exactly what git diffed, so the patch applies cleanly.
///
/// A `\ No newline at end of file` marker follows the last line of each side that ends
/// without one: where git put it, and after the other side's new last line when a dropped
/// change moves that side's end (`placingMarkers`). A hunk with no selected change is left out. Each written
/// hunk's counts are recomputed from its lines; the side being applied to keeps its start,
/// and the other side's start moves by the net change of the hunks written before it.
///
/// The header names one path on both sides: the side being applied to (the old path
/// forward, the new path reversed). For a rename the two differ, and a patch naming both
/// would have `git apply` rename the file as well as change its lines.
public enum GitPatchBuilder {
    /// Whether `file` can have a patch built from some of its lines: a modified file (or a
    /// renamed one that also changed), not binary, with hunks, and with paths that fit on
    /// one header line. Added, deleted, untracked, copied and type-changed files stage,
    /// unstage and discard as whole files.
    public static func canBuild(for file: GitFileDiff) -> Bool {
        guard !file.isBinary, !file.hunks.isEmpty,
              let oldPath = file.oldPath, let newPath = file.newPath,
              isHeaderSafe(oldPath), isHeaderSafe(newPath) else { return false }
        switch file.change {
        case .modified, .renamed: return true
        case .added, .deleted, .copied, .typeChanged: return false
        }
    }

    /// The patch for `selection`, or nil when nothing is selected or the file cannot be
    /// built (`canBuild`). Ends with a newline.
    public static func patch(_ selection: GitPatchSelection, direction: GitPatchDirection) -> String? {
        let file = selection.file
        guard canBuild(for: file), let oldPath = file.oldPath, let newPath = file.newPath else { return nil }
        var body: [String] = []
        var delta = 0
        for (index, hunk) in file.hunks.enumerated() {
            let selected = selection.lines[index] ?? IndexSet()
            guard selected.contains(where: { hunk.lines.indices.contains($0) && isChange(hunk.lines[$0]) }) else {
                continue
            }
            let written = writtenLines(of: hunk, selected: selected, direction: direction)
            let header = header(for: hunk, oldCount: written.oldCount, newCount: written.newCount,
                                delta: delta, direction: direction)
            body.append(header)
            body += written.lines
            delta += written.newCount - written.oldCount
        }
        guard !body.isEmpty else { return nil }
        // One path on both sides: two different ones would make `git apply` rename the file too.
        let path = direction == .forward ? oldPath : newPath
        let head = ["diff --git a/\(path) b/\(path)", "--- a/\(path)", "+++ b/\(path)"]
        return (head + body).joined(separator: "\n") + "\n"
    }

    /// Whether `line` is one a patch can select: an added or a removed line.
    public static func isChange(_ line: GitDiffLine) -> Bool {
        line.kind == .added || line.kind == .removed
    }

    private static func isHeaderSafe(_ path: String) -> Bool {
        !path.isEmpty && !path.contains("\n") && !path.contains("\t") && !path.contains("\r")
    }

    private static let noNewlineMarker = "\\ No newline at end of file"

    /// One written line before markers are placed: its prefix, its text, and whether git
    /// followed it with `\ No newline at end of file` in the diff.
    private struct Entry {
        let prefix: Character
        let text: String
        let endsWithoutNewline: Bool
        var isOld: Bool { prefix != "+" }
        var isNew: Bool { prefix != "-" }
    }

    private static func writtenLines(of hunk: GitDiffHunk, selected: IndexSet, direction: GitPatchDirection)
        -> (lines: [String], oldCount: Int, newCount: Int) {
        var entries: [Entry] = []
        for (index, line) in hunk.lines.enumerated() {
            let prefix: Character?
            switch (line.kind, selected.contains(index), direction) {
            case (.noNewlineAtEnd, _, _): continue
            case (.context, _, _): prefix = " "
            case (.added, true, _): prefix = "+"
            case (.removed, true, _): prefix = "-"
            case (.added, false, .forward), (.removed, false, .reverse): prefix = nil
            case (.added, false, .reverse), (.removed, false, .forward): prefix = " "
            }
            guard let prefix else { continue }
            let next = hunk.lines.indices.contains(index + 1) ? hunk.lines[index + 1] : nil
            entries.append(Entry(prefix: prefix, text: line.text,
                                 endsWithoutNewline: next?.kind == .noNewlineAtEnd))
        }
        return placingMarkers(entries)
    }

    /// Writes `entries`, putting a marker after the last line of each side that git said
    /// ends without a newline. A context line that ends one side without a newline but not
    /// the other is written as a `-` and a `+` of the same text, each with its own marker
    /// or none, which keeps both counts. The side being applied to keeps exactly the
    /// markers git wrote, since its last line is the one git marked.
    private static func placingMarkers(_ entries: [Entry]) -> (lines: [String], oldCount: Int, newCount: Int) {
        let lastOld = entries.lastIndex { $0.isOld }
        let lastNew = entries.lastIndex { $0.isNew }
        var lines: [String] = []
        for (index, entry) in entries.enumerated() {
            let oldEnds = index == lastOld && entry.endsWithoutNewline
            let newEnds = index == lastNew && entry.endsWithoutNewline
            if entry.prefix == " ", oldEnds != newEnds {
                lines.append("-\(entry.text)")
                if oldEnds { lines.append(noNewlineMarker) }
                lines.append("+\(entry.text)")
                if newEnds { lines.append(noNewlineMarker) }
                continue
            }
            lines.append("\(entry.prefix)\(entry.text)")
            if oldEnds || newEnds { lines.append(noNewlineMarker) }
        }
        return (lines, entries.filter(\.isOld).count, entries.filter(\.isNew).count)
    }

    /// `@@ -oldStart,oldCount +newStart,newCount @@`. The side the patch is applied to (old
    /// forward, new reverse) keeps the diff's start; the other is that start moved by
    /// `delta`, the net line change of the hunks already written. A side with no lines
    /// names the line before it, as git writes it.
    private static func header(for hunk: GitDiffHunk, oldCount: Int, newCount: Int, delta: Int,
                               direction: GitPatchDirection) -> String {
        let oldStart: Int
        let newStart: Int
        switch direction {
        case .forward:
            oldStart = hunk.oldStart
            let first = (hunk.oldCount == 0 ? hunk.oldStart + 1 : hunk.oldStart) + delta
            newStart = newCount == 0 ? first - 1 : first
        case .reverse:
            newStart = hunk.newStart
            let first = (hunk.newCount == 0 ? hunk.newStart + 1 : hunk.newStart) - delta
            oldStart = oldCount == 0 ? first - 1 : first
        }
        return "@@ -\(oldStart),\(oldCount) +\(newStart),\(newCount) @@"
    }
}
