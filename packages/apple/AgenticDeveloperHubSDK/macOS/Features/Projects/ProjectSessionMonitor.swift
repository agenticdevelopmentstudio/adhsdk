import AgenticDeveloperHubSDKCore
import Foundation

/// The Claude Code sessions running in each project checkout, for the project
/// window's tab cards: a card names its checkout's session and shows what it is
/// doing.
///
/// The host attaches a session source once (`dependency-injection`); until it
/// does, no checkout has a session and the cards show only their branch.
@MainActor
public final class ProjectSessionMonitor {
    public static let shared = ProjectSessionMonitor()

    /// Posted on the main actor whenever the sessions it knows change.
    public static let didChangeNotification = Notification.Name("ProjectSessionMonitorDidChange")

    /// Whether AI summaries are switched on, asked by the cards that hold a
    /// place for one.
    public private(set) var summariesEnabled: @MainActor () -> Bool = { false }

    private var source: SessionWatcher.SessionListSource?
    private var sessions: [SessionWatcher.SessionWatcherSession] = []

    public func attach(
        _ source: SessionWatcher.SessionListSource,
        summariesEnabled: @escaping @MainActor () -> Bool
    ) {
        self.source?.stopObserving()
        self.source = source
        self.summariesEnabled = summariesEnabled
        source.startObserving { [weak self] in
            Task { @MainActor in await self?.reload() }
        }
        Task { await reload() }
    }

    /// The live session working in `directory` or below it, the most recently
    /// active first; `nil` when there is none.
    public func session(forDirectory directory: URL) -> SessionWatcher.SessionWatcherSession? {
        let path = directory.standardizedFileURL.path
        return sessions
            .filter { $0.status == .active && ($0.cwd == path || $0.cwd.hasPrefix(path + "/")) }
            .max { $0.lastActivityAt < $1.lastActivityAt }
    }

    private func reload() async {
        guard let source else { return }
        let fetched = (try? await source.fetchSessions()) ?? []
        guard fetched != sessions else { return }
        sessions = fetched
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
