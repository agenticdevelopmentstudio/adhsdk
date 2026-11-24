import Foundation

/// The Git window's agent sessions, read from a session daemon (adkd, or whichever
/// daemon the app's client points at): one read-only `sessions` call per root, merged by
/// id. A daemon that cannot be reached answers no sessions.
public struct GitDaemonSessions: GitSessionsProviding {
    /// The most `sinceHours` a request asks for: 90 days.
    public static let maximumHours = 24 * 90

    private let service: any StenographerDaemonService
    private let now: @Sendable () -> Date

    public init(service: any StenographerDaemonService, now: @escaping @Sendable () -> Date = { Date() }) {
        self.service = service
        self.now = now
    }

    public func sessions(under roots: [String], since: Date) async -> [GitAgentSession] {
        let hours = Self.hours(since: since, now: now())
        var merged: [String: GitAgentSession] = [:]
        var order: [String] = []
        for root in roots {
            let found = await service.sessions(status: nil, project: root, sinceHours: hours, includeCounts: false)
            for session in (found ?? []).compactMap(Self.session(from:)) where merged[session.id] == nil {
                merged[session.id] = session
                order.append(session.id)
            }
        }
        return order.compactMap { merged[$0] }
    }

    /// The whole hours from `since` to `now`, rounded up, at least 1 and at most
    /// `maximumHours`.
    static func hours(since: Date, now: Date) -> Int {
        let hours = (now.timeIntervalSince(since) / 3600).rounded(.up)
        guard hours.isFinite else { return maximumHours }
        return Int(min(max(hours, 1), Double(maximumHours)))
    }

    /// A daemon row as a session; nil when its start cannot be read. The daemon's
    /// SQLite datetimes are UTC. A last activity that cannot be read is the start.
    static func session(from dto: SessionDTO) -> GitAgentSession? {
        guard !dto.sessionId.isEmpty, let started = TimestampParsing.parse(dto.startedAt) else { return nil }
        let last = TimestampParsing.parse(dto.lastActivityAt) ?? started
        return GitAgentSession(
            id: dto.sessionId,
            title: dto.transcriptTitle.isEmpty ? nil : dto.transcriptTitle,
            cwd: dto.cwd,
            branch: dto.gitBranch.isEmpty ? nil : dto.gitBranch,
            startedAt: started,
            lastActivityAt: max(last, started))
    }
}
