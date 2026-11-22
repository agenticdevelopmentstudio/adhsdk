#if canImport(AgenticDeveloperHubSDKCore)
import Foundation

// MARK: - The session daemon's scheduled work
//
// The toolkit has no DaemonKit (that is the agenticdaemon repo's, a tier above),
// so the session tasks conform to this protocol instead: a field-for-field mirror
// of DaemonKit's `DaemonTask`, `TaskSchedule`, `TaskContext` and `TaskResult`,
// with the same defaults and clamps. A daemon that schedules with DaemonKit wraps
// each task in one adapter that copies the schedule in and the result out; nothing
// else changes shape.
//
// Every task takes what it works on by its initializer (the database, a pipeline
// slot, a closure), so a daemon builds as many as it needs. None is a singleton.

/// A unit of scheduled session work.
public protocol SessionDaemonTask: Sendable {
    /// Unique identifier for this task.
    var name: String { get }
    /// How and how often the task runs.
    var schedule: SessionTaskSchedule { get }
    /// Runs the task once; the result can move its next run.
    func execute(context: SessionTaskContext) async throws -> SessionTaskResult
}

/// A task's schedule. Mirrors DaemonKit's `TaskSchedule`.
public struct SessionTaskSchedule: Sendable, Equatable {
    /// How often to run, in seconds. Clamped to 1...86400.
    public let intervalSeconds: TimeInterval
    /// Whether the task is currently enabled.
    public let enabled: Bool
    /// Maximum execution time in seconds. Clamped to 1...3600.
    public let timeout: TimeInterval
    /// Whether to back off exponentially on consecutive failures.
    public let backoffOnFailure: Bool

    public init(
        intervalSeconds: TimeInterval = 60,
        enabled: Bool = true,
        timeout: TimeInterval = 30,
        backoffOnFailure: Bool = true
    ) {
        self.intervalSeconds = min(max(intervalSeconds, 1), 86400)
        self.enabled = enabled
        self.timeout = min(max(timeout, 1), 3600)
        self.backoffOnFailure = backoffOnFailure
    }

    public static let `default` = SessionTaskSchedule()
}

/// What a task is told when it runs. Mirrors DaemonKit's `TaskContext`.
public struct SessionTaskContext: Sendable {
    /// The task's name.
    public let taskName: String
    /// How many times this task has failed in a row.
    public let consecutiveFailures: Int
    /// Why this run happened.
    public let runReason: RunReason

    public enum RunReason: String, Sendable, Codable {
        case scheduled
        case triggered
    }

    public init(taskName: String, consecutiveFailures: Int = 0, runReason: RunReason = .scheduled) {
        self.taskName = taskName
        self.consecutiveFailures = consecutiveFailures
        self.runReason = runReason
    }
}

/// What a task returns. Every field is optional: nil keeps the default.
/// Mirrors DaemonKit's `TaskResult`.
public struct SessionTaskResult: Sendable, Equatable {
    /// Overrides the next interval, in seconds.
    public var nextRunSeconds: TimeInterval?
    /// Overrides the next run with an absolute time.
    public var nextRunAt: Date?
    /// Names of other tasks to run as soon as this one finishes.
    public var trigger: [String]?
    /// False stops the task from being scheduled again.
    public var enabled: Bool?
    /// A line the scheduler logs for the task.
    public var message: String?

    public init(
        nextRunSeconds: TimeInterval? = nil,
        nextRunAt: Date? = nil,
        trigger: [String]? = nil,
        enabled: Bool? = nil,
        message: String? = nil
    ) {
        self.nextRunSeconds = nextRunSeconds
        self.nextRunAt = nextRunAt
        self.trigger = trigger
        self.enabled = enabled
        self.message = message
    }

    public static let empty = SessionTaskResult()

    /// Run again on the next scheduler tick rather than after the interval: a
    /// task draining a backlog in bounded batches returns this while work remains.
    public static let rerunImmediately = SessionTaskResult(nextRunSeconds: 0)
}
#endif
