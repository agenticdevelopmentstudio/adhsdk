import Foundation

/// Collapses a burst of notices from one source into a single summary, so a
/// chatty script cannot bury the screen.
public struct FloodFolder: Sendable {

    public struct Configuration: Codable, Sendable, Equatable {
        /// Notices from one source shown individually before folding starts.
        public var threshold: Int
        /// Seconds of quiet after which a source's count starts over.
        public var window: TimeInterval

        public init(threshold: Int = 5, window: TimeInterval = 10) {
            self.threshold = threshold
            self.window = window
        }
    }

    public enum Decision: Equatable {
        case show
        /// Fold into a summary: `count` notices so far from `source`.
        case fold(source: String, count: Int)
    }

    private struct Run {
        var count: Int
        var lastSeen: Date
    }

    public var configuration: Configuration
    private var runs: [String: Run] = [:]

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    /// Notices of urgency `now` or above always show and are not counted.
    public mutating func admit(_ notice: Notice, at now: Date) -> Decision {
        guard notice.urgency.rank < Notice.Urgency.now.rank else { return .show }

        var run = runs[notice.source] ?? Run(count: 0, lastSeen: now)
        if now.timeIntervalSince(run.lastSeen) >= configuration.window {
            run.count = 0
        }
        run.count += 1
        run.lastSeen = now
        runs[notice.source] = run

        return run.count > configuration.threshold
            ? .fold(source: notice.source, count: run.count)
            : .show
    }
}
