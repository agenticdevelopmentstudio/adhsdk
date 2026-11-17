import Foundation

/// A Git LFS pointer file (recipe `foundation/git/git-client`, "LFS"): the three-line text
/// git stores in place of a large file, naming the object LFS keeps for it.
///
/// ```
/// version https://git-lfs.github.com/spec/v1
/// oid sha256:4d7a2146…
/// size 12345
/// ```
public struct GitLFSPointer: Sendable, Hashable {
    /// The object's SHA-256, as 64 lowercase hex digits, without the `sha256:` prefix.
    public let oid: String
    /// The object's size in bytes.
    public let size: Int64

    public init(oid: String, size: Int64) {
        self.oid = oid
        self.size = size
    }

    /// The first line every pointer starts with.
    public static let versionLine = "version https://git-lfs.github.com/spec/v1"

    /// The most a pointer file can be; anything longer is file content, not a pointer.
    public static let maximumBytes = 1024

    /// The first seven digits of `oid`, as a commit id is shortened.
    public var shortOID: String { String(oid.prefix(7)) }

    /// The pointer `text` holds, or nil when it is not one: longer than `maximumBytes`, a
    /// first line other than `versionLine`, or no `oid sha256:<64 hex>` or `size <N>` line.
    /// Lines may end in CRLF; blank lines are ignored.
    public static func parse(_ text: String) -> GitLFSPointer? {
        parse(text, requiresVersionLine: true)
    }

    /// `parse(_:)`, except that with `requiresVersionLine` false the version line may be
    /// missing, as it is from a diff side whose context was trimmed (`-U0`). Without it,
    /// every line must be a pointer's own (`oid`, `size` or `ext-…`), so ordinary text
    /// never reads as a pointer.
    static func parse(_ text: String, requiresVersionLine: Bool) -> GitLFSPointer? {
        guard text.utf8.count <= maximumBytes else { return nil }
        let lines = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if requiresVersionLine || lines.first == versionLine {
            guard lines.first == versionLine else { return nil }
        } else {
            let ownPrefixes = ["oid sha256:", "size ", "ext-"]
            guard lines.allSatisfy({ line in ownPrefixes.contains { line.hasPrefix($0) } }) else { return nil }
        }
        var oid: String?
        var size: Int64?
        for line in lines where line != versionLine {
            if line.hasPrefix("oid sha256:") {
                let hex = String(line.dropFirst("oid sha256:".count)).lowercased()
                guard hex.count == 64, hex.allSatisfy(\.isHexDigit) else { return nil }
                oid = hex
            } else if line.hasPrefix("size ") {
                guard let value = Int64(line.dropFirst("size ".count)), value >= 0 else { return nil }
                size = value
            }
        }
        guard let oid, let size else { return nil }
        return GitLFSPointer(oid: oid, size: size)
    }
}

/// What a file diff between two LFS pointers says: the old and new object, either nil when
/// that side of the file does not exist.
public struct GitLFSDiffSummary: Sendable, Hashable {
    public let old: GitLFSPointer?
    public let new: GitLFSPointer?

    public init(old: GitLFSPointer?, new: GitLFSPointer?) {
        self.old = old
        self.new = new
    }

    /// The summary of `diff`, or nil unless it is a pointer diff: both sides parse as a
    /// `GitLFSPointer`, or one does and the other side is missing (an added or deleted
    /// file). A binary diff is never one. The old side is the context and removed lines,
    /// the new side the context and added lines. A side may lack the version line, which
    /// is unchanged and so dropped from a diff with no context (`-U0`).
    public static func of(_ diff: GitFileDiff) -> GitLFSDiffSummary? {
        guard !diff.isBinary, !diff.hunks.isEmpty else { return nil }
        let lines = diff.hunks.flatMap(\.lines)
        let oldLines = lines.filter { $0.kind == .context || $0.kind == .removed }.map(\.displayText)
        let newLines = lines.filter { $0.kind == .context || $0.kind == .added }.map(\.displayText)
        let old = side(oldLines)
        let new = side(newLines)
        switch (old, new) {
        case let (.pointer(oldPointer), .pointer(newPointer)):
            return GitLFSDiffSummary(old: oldPointer, new: newPointer)
        case let (.pointer(oldPointer), .missing):
            return GitLFSDiffSummary(old: oldPointer, new: nil)
        case let (.missing, .pointer(newPointer)):
            return GitLFSDiffSummary(old: nil, new: newPointer)
        default:
            return nil
        }
    }

    /// "LFS object <short oid> · <size>", or "LFS object <old> · <size> → <new> · <size>"
    /// when both sides exist; sizes are `ByteCountFormatter`'s file style.
    public var text: String {
        let parts = [old, new].compactMap { $0 }.map { "\($0.shortOID) · \(Self.format($0.size))" }
        return "LFS object " + parts.joined(separator: " → ")
    }

    private enum Side {
        case missing
        case pointer(GitLFSPointer)
        case other
    }

    private static func side(_ lines: [String]) -> Side {
        guard !lines.isEmpty else { return .missing }
        let text = lines.joined(separator: "\n")
        return GitLFSPointer.parse(text, requiresVersionLine: false).map(Side.pointer) ?? .other
    }

    private static func format(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

/// Whether a repository uses Git LFS, and for what (recipe `foundation/git/git-client`, "LFS").
public struct GitLFSState: Sendable, Hashable {
    /// `git lfs version` exited 0.
    public let isInstalled: Bool
    /// The patterns `git lfs track` lists, in its order; `[]` when none.
    public let trackedPatterns: [String]
    /// Each path `git lfs ls-files` lists, and whether its object is downloaded (`*`)
    /// rather than only its pointer (`-`).
    public let files: [String: Bool]

    public init(isInstalled: Bool, trackedPatterns: [String], files: [String: Bool]) {
        self.isInstalled = isInstalled
        self.trackedPatterns = trackedPatterns
        self.files = files
    }

    /// The state of a machine without git-lfs.
    public static let notInstalled = GitLFSState(isInstalled: false, trackedPatterns: [], files: [:])

    /// Installed, and the repository tracks a pattern or holds an LFS file.
    public var isInUse: Bool { isInstalled && (!trackedPatterns.isEmpty || !files.isEmpty) }

    /// Whether `path` (relative to the repository root) is stored in LFS: `ls-files` lists
    /// it, or a tracked pattern matches it. A pattern without a slash matches the file name
    /// in any directory, as in `.gitattributes`; one with a slash matches the whole path.
    public func isTracked(_ path: String) -> Bool {
        guard isInUse else { return false }
        if files[path] != nil { return true }
        let name = (path as NSString).lastPathComponent
        return trackedPatterns.contains { pattern in
            let trimmed = pattern.hasPrefix("/") ? String(pattern.dropFirst()) : pattern
            let subject = trimmed.contains("/") ? path : name
            return fnmatch(trimmed, subject, 0) == 0
        }
    }

    /// The patterns in `git lfs track`'s output: the lines under "Listing tracked
    /// patterns", each without its trailing ` (<attributes file>)`, stopping at "Listing
    /// excluded patterns".
    public static func parseTrackedPatterns(_ output: String) -> [String] {
        var patterns: [String] = []
        var isListing = false
        for rawLine in output.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("Listing tracked patterns") {
                isListing = true
                continue
            }
            if line.hasPrefix("Listing excluded patterns") { break }
            guard isListing, !line.isEmpty else { continue }
            if line.hasSuffix(")"), let open = line.range(of: " (", options: .backwards) {
                patterns.append(String(line[..<open.lowerBound]))
            } else {
                patterns.append(line)
            }
        }
        return patterns
    }

    /// The files in `git lfs ls-files`'s output, each line `<oid> <*|-> <path>`: `*` is a
    /// downloaded object, `-` a pointer only. Lines of any other shape are skipped.
    public static func parseFiles(_ output: String) -> [String: Bool] {
        var files: [String: Bool] = [:]
        for rawLine in output.split(whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let fields = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: false)
            guard fields.count == 3, !fields[0].isEmpty, fields[1] == "*" || fields[1] == "-",
                  !fields[2].isEmpty else { continue }
            files[String(fields[2])] = fields[1] == "*"
        }
        return files
    }
}
