import Foundation

/// One submodule as `git submodule status` reports it.
public struct GitSubmodule: Sendable, Hashable {
    public enum State: Sendable, Hashable {
        /// Checked out at the recorded commit (prefix space).
        case current
        /// Checked out at a commit other than the recorded one (prefix `+`).
        case modified
        /// Not initialized (prefix `-`).
        case uninitialized
        /// Has merge conflicts (prefix `U`).
        case conflicted
    }

    public let path: String
    /// The checked-out commit's sha (the recorded one when uninitialized).
    public let id: String
    public let state: State

    public init(path: String, id: String, state: State) {
        self.path = path
        self.id = id
        self.state = state
    }

    /// Parses `submodule status` lines: a state character, the sha, a space, the path and an
    /// optional ` (<describe>)` suffix. The path may contain spaces; unreadable lines are dropped.
    public static func parse(status output: String) -> [GitSubmodule] {
        output.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            guard let state = state(line.first) else { return nil }
            let rest = line.dropFirst()
            guard let space = rest.firstIndex(of: " ") else { return nil }
            let sha = rest[..<space]
            var path = rest[rest.index(after: space)...]
            if path.last == ")", let open = path.range(of: " (", options: .backwards) {
                path = path[..<open.lowerBound]
            }
            guard !sha.isEmpty, !path.isEmpty else { return nil }
            return GitSubmodule(path: String(path), id: String(sha), state: state)
        }
    }

    private static func state(_ prefix: Character?) -> State? {
        switch prefix {
        case " ": .current
        case "+": .modified
        case "-": .uninitialized
        case "U": .conflicted
        default: nil
        }
    }
}
