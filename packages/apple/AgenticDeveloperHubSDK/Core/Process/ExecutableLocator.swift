import Foundation

/// Finds a command-line tool by name the way a shell would, plus the install
/// locations a GUI app's inherited `PATH` leaves out.
///
/// An app launched from the Dock or by launchd inherits a `PATH` of the system
/// directories only, so a tool installed by Homebrew (`/opt/homebrew/bin`) or into
/// `/usr/local/bin` is invisible to a plain `PATH` walk. The locator walks the
/// inherited `PATH` first, so a user's own ordering wins, then `extraDirectories`,
/// trying each directory once: a directory named twice keeps only its first place.
///
/// It knows nothing about any particular tool. A tool with install locations of its
/// own (Claude Code's `~/.local/bin`, a Node version manager's tree) passes them in
/// `extraDirectories` or keeps them beside its own lookup.
public struct ExecutableLocator: Sendable {

    /// The environment whose `PATH` is walked first.
    public let environment: [String: String]
    /// Searched after `PATH`, in order.
    public let extraDirectories: [String]
    private let isExecutable: @Sendable (String) -> Bool

    public init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        extraDirectories: [String] = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"],
        isExecutable: @escaping @Sendable (String) -> Bool = { ExecutableLocator.isExecutableFile($0) }
    ) {
        self.environment = environment
        self.extraDirectories = extraDirectories
        self.isExecutable = isExecutable
    }

    /// Every directory searched, in order: the `PATH` entries, then `extraDirectories`.
    /// Empty and relative entries are dropped (a relative one would resolve against
    /// the app's current directory), a trailing `/` does not make a directory a different
    /// one, and a repeated directory keeps only its first place.
    public var searchDirectories: [String] {
        let inherited = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
        var seen = Set<String>()
        return (inherited + extraDirectories)
            .map(Self.normalized)
            .filter { $0.hasPrefix("/") && seen.insert($0).inserted }
    }

    /// The first executable file called `name` in `searchDirectories`, or nil when
    /// there is none. `name` is a bare tool name: an empty name, or one holding a `/`,
    /// finds nothing, so a caller cannot be steered to an arbitrary path through it.
    public func find(_ name: String) -> URL? {
        guard !name.isEmpty, !name.contains("/") else { return nil }
        for directory in searchDirectories {
            let path = directory == "/" ? "/\(name)" : "\(directory)/\(name)"
            if isExecutable(path) { return URL(fileURLWithPath: path) }
        }
        return nil
    }

    /// True for an executable regular file; a directory with its x bit set is not one.
    public static func isExecutableFile(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            && !isDirectory.boolValue && FileManager.default.isExecutableFile(atPath: path)
    }

    /// `directory` without trailing slashes, except the root itself.
    private static func normalized(_ directory: String) -> String {
        var trimmed = Substring(directory)
        while trimmed.count > 1, trimmed.hasSuffix("/") { trimmed = trimmed.dropLast() }
        return String(trimmed)
    }
}
