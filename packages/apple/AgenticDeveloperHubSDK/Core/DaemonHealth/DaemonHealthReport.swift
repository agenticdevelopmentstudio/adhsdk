import Foundation

// A client-side mirror of the `GET /health` wire format every DaemonKit daemon
// serves (`DaemonHealthRouter`). Kept here, Foundation only, so a menu bar app
// or any other client can read a daemon's health without linking DaemonKit —
// the same arrangement `StenographerHTTPClient` uses for stenographerd. The
// JSON keys are the contract; the Swift names are distinct from DaemonKit's
// (`HealthStatus`, `StrategySnapshot`, `WorkUnitSnapshot`) so a file that
// imports both never meets an ambiguity.

/// The body of a daemon's `GET /health` response.
public struct DaemonHealthReport: Codable, Sendable, Equatable {
    public let status: String
    public let version: String
    public let uptimeSeconds: TimeInterval
    public let strategy: DaemonStrategyReport

    public init(status: String, version: String, uptimeSeconds: TimeInterval, strategy: DaemonStrategyReport) {
        self.status = status
        self.version = version
        self.uptimeSeconds = uptimeSeconds
        self.strategy = strategy
    }

    /// Decodes a `/health` body, dates as ISO-8601 (what DaemonKit encodes).
    /// `nil` for a body in some other schema: a daemon may answer `/health`
    /// in its own shape and still be up.
    public static func decode(_ data: Data) -> DaemonHealthReport? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(DaemonHealthReport.self, from: data)
    }
}

/// One strategy in the report, with its work units and, for a composite, its
/// children.
public struct DaemonStrategyReport: Codable, Sendable, Equatable {
    /// The kind DaemonKit's `TimingStrategy` reports.
    public static let timingKind = "timing"
    /// The kind DaemonKit's `EventStrategy` reports.
    public static let eventKind = "event"
    /// The kind DaemonKit's `CompositeStrategy` reports.
    public static let compositeKind = "composite"

    public let name: String
    /// `timing`, `event`, `composite`, or a daemon's own value; treat unknown
    /// kinds as opaque.
    public let kind: String
    public let workUnits: [DaemonWorkUnitReport]
    /// Empty for a leaf strategy.
    public let children: [DaemonStrategyReport]

    public init(
        name: String,
        kind: String,
        workUnits: [DaemonWorkUnitReport],
        children: [DaemonStrategyReport] = []
    ) {
        self.name = name
        self.kind = kind
        self.workUnits = workUnits
        self.children = children
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        kind = try container.decode(String.self, forKey: .kind)
        workUnits = try container.decode([DaemonWorkUnitReport].self, forKey: .workUnits)
        children = try container.decodeIfPresent([DaemonStrategyReport].self, forKey: .children) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case name, kind, workUnits, children
    }

    /// The first strategy of `kind` in this tree, depth first, this one included.
    public func first(ofKind kind: String) -> DaemonStrategyReport? {
        if self.kind == kind { return self }
        for child in children {
            if let found = child.first(ofKind: kind) { return found }
        }
        return nil
    }
}

/// One unit of work: a scheduled task for a timing strategy, a handler for an
/// event strategy. Fields that do not apply are `nil`.
public struct DaemonWorkUnitReport: Codable, Sendable, Equatable {
    public enum State: String, Codable, Sendable {
        case idle
        case running
        case disabled
        case blocklisted
    }

    public let name: String
    public let state: State
    public let nextActivation: Date?
    public let consecutiveFailures: Int
    public let isBlocklisted: Bool
    public let lastMessage: String?

    public init(
        name: String,
        state: State,
        nextActivation: Date? = nil,
        consecutiveFailures: Int = 0,
        isBlocklisted: Bool = false,
        lastMessage: String? = nil
    ) {
        self.name = name
        self.state = state
        self.nextActivation = nextActivation
        self.consecutiveFailures = consecutiveFailures
        self.isBlocklisted = isBlocklisted
        self.lastMessage = lastMessage
    }
}

/// Builds the `/health` probe a menu bar app polls.
public enum DaemonHealthProbe {
    /// A probe that GETs `<baseURL>/health` and hands back the body on a 200,
    /// `nil` on any other status, a transport error or a timeout.
    public static func http(baseURL: String, timeout: TimeInterval = 2) -> @Sendable () async -> Data? {
        let url = URL(string: baseURL)?.appendingPathComponent("health")
        let session = URLSession(configuration: .ephemeral)
        return {
            guard let url else { return nil }
            var request = URLRequest(url: url, timeoutInterval: timeout)
            request.httpMethod = "GET"
            guard let (data, response) = try? await session.data(for: request),
                  (response as? HTTPURLResponse)?.statusCode == 200
            else { return nil }
            return data
        }
    }
}
