import Foundation

/// Which Stenographer this process belongs to.
///
/// The **default** instance is the one a person installs. It is unnamed and
/// resolves every value exactly as Stenographer always has. A **named**
/// instance (`dev-trimming`) is a development copy that runs beside the
/// installed one. It has its own data root, label, Mach service, port, socket
/// and drop directory, and it never touches what the installed copy owns (see
/// the passive gates in the daemon's `InstancePolicy` and the app's
/// `StenographerInstances`).
///
/// A named instance exists only if its definition file does:
/// `~/Library/Application Support/com.agenticdevelopmentstudio.stenographer.instances/<name>.json`,
/// written by `scripts/stenographer_instance.py`. Asking for a name with no
/// definition is a hard error. Creating an empty store for a typo would look
/// like data loss.
public struct StenographerInstance: Sendable, Equatable {

    public struct Definition: Codable, Sendable, Equatable {
        public let name: String
        public let dataRoot: String
        public let httpPort: Int

        public init(name: String, dataRoot: String, httpPort: Int) {
            self.name = name
            self.dataRoot = dataRoot
            self.httpPort = httpPort
        }
    }

    public enum ResolutionError: Error, Equatable, CustomStringConvertible {
        case invalidName(String)
        case reservedName(String)
        case undefined(name: String, expectedAt: String)
        case unreadable(path: String, reason: String)
        case nameMismatch(file: String, declared: String)
        case relativeDataRoot(String)
        case invalidPort(Int)
        case overlapsInstalledState(dataRoot: String, protected: String)
        case socketPathTooLong(path: String, limit: Int)

        public var description: String {
            switch self {
            case .invalidName(let name):
                return "instance name '\(name)' must match [a-z0-9][a-z0-9-]{0,31}"
            case .reservedName(let name):
                return "instance name '\(name)' is reserved: \(baseLabel).\(name) already names something else"
            case .undefined(let name, let path):
                return "instance '\(name)' is not defined (no \(path)); "
                    + "create it with scripts/stenographer_instance.py create"
            case .unreadable(let path, let reason):
                return "instance definition \(path) is unreadable: \(reason)"
            case .nameMismatch(let file, let declared):
                return "instance definition \(file).json declares name '\(declared)'"
            case .relativeDataRoot(let root):
                return "instance dataRoot '\(root)' must be an absolute path"
            case .invalidPort(let port):
                let reserved = StenographerInstance.reservedHTTPPorts.sorted().map(String.init).joined(separator: ", ")
                return "instance httpPort \(port) must be 1024-65535 and not one of \(reserved)"
            case .overlapsInstalledState(let root, let protected):
                return "instance dataRoot '\(root)' overlaps \(protected), which the installed Stenographer owns"
            case .socketPathTooLong(let path, let limit):
                return "instance socket path \(path) is \(path.utf8.count) bytes; the limit is under \(limit)"
            }
        }
    }

    public static let baseLabel = "com.agenticdevelopmentstudio.stenographer"
    public static let defaultHTTPPort = 22847
    /// Ports a named instance may never take: the installed daemon's HTTP port,
    /// the installed account router's (the obvious "next port"), and adkd's.
    public static let reservedHTTPPorts: Set<Int> = [
        defaultHTTPPort, StenographerIdentifiers.routerPort, ADKDIdentifiers.httpPort
    ]
    /// Names whose label `<baseLabel>.<name>` is already taken: the usage
    /// widget's bundle id, the directory that holds the definitions, and the
    /// installed daemon's launch-throttle identifier (`<baseLabel>.daemon`),
    /// whose `/tmp/<identifier>.launches` an instance's app guard would share.
    public static let reservedNames: Set<String> = ["usagewidget", "instances", "daemon"]
    public static let environmentKey = "STENOGRAPHER_INSTANCE"
    public static let argumentFlag = "-instance"
    /// `sockaddr_un.sun_path` is 104 bytes on Darwin, including the NUL.
    public static let socketPathLimit = 104
    public static let socketFileName = "stenographer.sock"

    public static let `default` = StenographerInstance(definition: nil)

    /// nil for the default instance.
    public let definition: Definition?

    init(definition: Definition?) { self.definition = definition }

    public var isDefault: Bool { definition == nil }
    public var name: String? { definition?.name }
    public var label: String { definition.map { "\(Self.baseLabel).\($0.name)" } ?? Self.baseLabel }
    public var httpPort: Int { definition?.httpPort ?? Self.defaultHTTPPort }
    public var dataRoot: URL? { definition.map { URL(fileURLWithPath: $0.dataRoot, isDirectory: true) } }

    public static func definitionsDirectory(home: URL) -> URL {
        home.appendingPathComponent("Library/Application Support/\(baseLabel).instances", isDirectory: true)
    }

    /// The name this process was asked to be, or nil for the default. The
    /// environment wins over the argument: the daemon and the CLI are selected
    /// by environment, and an app passes its own selection to the daemon the
    /// same way.
    public static func requestedName(environment: [String: String], arguments: [String]) -> String? {
        if let value = environment[environmentKey] {
            return value.isEmpty ? nil : value
        }
        guard let flag = arguments.firstIndex(of: argumentFlag), flag + 1 < arguments.count else { return nil }
        let value = arguments[flag + 1]
        return value.isEmpty ? nil : value
    }

    public static func resolve(name: String?, home: URL) throws -> StenographerInstance {
        guard let name else { return .default }
        guard name.wholeMatch(of: /[a-z0-9][a-z0-9-]{0,31}/) != nil else { throw ResolutionError.invalidName(name) }
        let file = definitionsDirectory(home: home).appendingPathComponent("\(name).json")
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw ResolutionError.undefined(name: name, expectedAt: file.path)
        }
        let definition: Definition
        do {
            definition = try JSONDecoder().decode(Definition.self, from: Data(contentsOf: file))
        } catch {
            throw ResolutionError.unreadable(path: file.path, reason: String(describing: error))
        }
        try validate(definition, fileName: name, home: home)
        return StenographerInstance(definition: definition)
    }

    /// The rules a definition must satisfy. `scripts/stenographer_instance.py`
    /// (`check_definition`) enforces the same ones when it writes a definition,
    /// and `tests/fixtures/instance_definition_cases.json` holds the cases both
    /// sides are tested against.
    public static func validate(_ definition: Definition, fileName: String, home: URL) throws {
        guard definition.name == fileName else {
            throw ResolutionError.nameMismatch(file: fileName, declared: definition.name)
        }
        guard !reservedNames.contains(definition.name) else { throw ResolutionError.reservedName(definition.name) }
        guard definition.dataRoot.hasPrefix("/") else { throw ResolutionError.relativeDataRoot(definition.dataRoot) }
        guard (1024...65535).contains(definition.httpPort), !reservedHTTPPorts.contains(definition.httpPort) else {
            throw ResolutionError.invalidPort(definition.httpPort)
        }
        let root = canonicalComponents(definition.dataRoot)
        for protected in protectedRoots(home: home) {
            let other = canonicalComponents(protected.path)
            if root.starts(with: other) || other.starts(with: root) {
                throw ResolutionError.overlapsInstalledState(dataRoot: definition.dataRoot, protected: protected.path)
            }
        }
        let socket = URL(fileURLWithPath: definition.dataRoot, isDirectory: true)
            .appendingPathComponent(socketFileName).path
        guard socket.utf8.count < socketPathLimit else {
            throw ResolutionError.socketPathTooLong(path: socket, limit: socketPathLimit)
        }
    }

    /// What the installed copy owns on disk, whatever instance asks: the
    /// current and legacy data roots, the current and legacy logs, and
    /// `~/.claude` (the hook socket, the drop directory, `settings.json`). A
    /// named instance's data root may not equal, contain or sit inside any of them.
    public static func protectedRoots(home: URL) -> [URL] {
        let library = home.appendingPathComponent("Library", isDirectory: true)
        return [baseLabel, StenographerIdentifiers.legacyLabel].flatMap { label in
            [library.appendingPathComponent("Application Support/\(label)", isDirectory: true),
             library.appendingPathComponent("Logs/\(label)", isDirectory: true)]
        } + [home.appendingPathComponent(".claude", isDirectory: true)]
    }

    /// `path`'s components after the rules Python's `os.path.realpath` applies
    /// (`check_definition` uses it): `.` dropped, `..` taken against what is
    /// resolved so far, every symlink that exists followed, missing components
    /// kept as written. Lowercased, because the default APFS volume is case
    /// insensitive and `~/library/logs` is `~/Library/Logs` there. A leading
    /// `/System/Volumes/Data` is dropped before and after resolving: that
    /// firmlink reaches the same files, and realpath keeps it as written.
    static func canonicalComponents(_ path: String) -> [String] {
        let resolved = canonicalPath(withoutDataVolume(path.split(separator: "/").map(String.init)), depth: 0)
        return withoutDataVolume(resolved.split(separator: "/").map { $0.lowercased() })
            .split(separator: "/").map(String.init)
    }

    private static let dataVolume = ["system", "volumes", "data"]

    private static func withoutDataVolume(_ components: [String]) -> String {
        let firm = components.prefix(dataVolume.count).map { $0.lowercased() } == dataVolume
        return "/" + (firm ? components.dropFirst(dataVolume.count) : components[...]).joined(separator: "/")
    }

    private static func canonicalPath(_ path: String, depth: Int) -> String {
        var parts: [String] = []
        let components = path.split(separator: "/").map(String.init)
        for (index, component) in components.enumerated() {
            switch component {
            case ".":
                continue
            case "..":
                if !parts.isEmpty { parts.removeLast() }
            default:
                let candidate = "/" + (parts + [component]).joined(separator: "/")
                if let real = realPath(candidate) {
                    parts = real.split(separator: "/").map(String.init)
                } else if depth < 32,
                          let target = try? FileManager.default.destinationOfSymbolicLink(atPath: candidate) {
                    // A dangling link: realpath(3) fails, os.path.realpath follows it anyway.
                    let base = target.hasPrefix("/") ? target : "/" + (parts + [target]).joined(separator: "/")
                    let rest = components[(index + 1)...].joined(separator: "/")
                    return canonicalPath(rest.isEmpty ? base : base + "/" + rest, depth: depth + 1)
                } else {
                    parts.append(component)
                }
            }
        }
        return "/" + parts.joined(separator: "/")
    }

    private static func realPath(_ path: String) -> String? {
        guard let resolved = realpath(path, nil) else { return nil }
        defer { free(resolved) }
        return String(cString: resolved)
    }

    /// This process's instance, resolved once. A process asked to be an
    /// instance that cannot be resolved exits 78 (EX_CONFIG) with the reason on
    /// stderr. That is a normal exit, so launchd's `KeepAlive: {Crashed: true}`
    /// does not relaunch it into the same failure.
    public static let current: StenographerInstance = {
        let info = ProcessInfo.processInfo
        let name = requestedName(environment: info.environment, arguments: info.arguments)
        do {
            return try resolve(name: name, home: FileManager.default.homeDirectoryForCurrentUser)
        } catch {
            FileHandle.standardError.write(Data("stenographer: \(error)\n".utf8))
            exit(78)
        }
    }()
}
