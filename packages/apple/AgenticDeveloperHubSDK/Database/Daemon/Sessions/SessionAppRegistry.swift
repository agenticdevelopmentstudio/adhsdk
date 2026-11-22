#if canImport(AgenticDeveloperHubSDKCore)
import Foundation
import OSLog
import AgenticDeveloperHubSDKCore

/// Single-instance coordinator for a session daemon's menu bar app.
///
/// The daemon is the only process that exists "always" and runs as a
/// singleton under launchd, so it's the natural source of truth for "which
/// menubar PID is currently the owner." An actor gives us atomic
/// register/unregister with no locks and no TOCTOU race.
///
/// Liveness: `kill(pid, 0)` returns 0 if the process exists and we have
/// permission to signal it. It sends no signal. If the recorded owner has
/// died without unregistering (crash, SIGKILL), the next register attempt
/// transparently takes over.
public actor SessionAppRegistry {
    public enum RegisterResult: Sendable {
        case registered
        case alreadyRegistered(ownerPid: Int32)
    }

    private var ownerPid: Int32?

    public init() {}

    public func register(pid: Int32) -> RegisterResult {
        if let current = ownerPid, current != pid, Self.isAlive(pid: current) {
            Self.logger.info(
                "Register denied for pid \(pid, privacy: .public): owner \(current, privacy: .public) is alive"
            )
            return .alreadyRegistered(ownerPid: current)
        }
        if let stale = ownerPid, stale != pid {
            Self.logger.info(
                "Reaping stale owner pid \(stale, privacy: .public); replacing with \(pid, privacy: .public)"
            )
        }
        ownerPid = pid
        Self.logger.info("Registered owner pid \(pid, privacy: .public)")
        return .registered
    }

    public func unregister(pid: Int32) -> Bool {
        guard ownerPid == pid else { return false }
        ownerPid = nil
        Self.logger.info("Unregistered owner pid \(pid, privacy: .public)")
        return true
    }

    public func currentOwner() -> Int32? {
        guard let pid = ownerPid else { return nil }
        if Self.isAlive(pid: pid) { return pid }
        ownerPid = nil
        return nil
    }

    private static func isAlive(pid: Int32) -> Bool {
        // kill(pid, 0) sends no signal — it only verifies the process exists
        // and we can signal it. errno ESRCH ⇒ dead; EPERM ⇒ alive but ours
        // is wrong user (treat as alive — not our problem).
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }
}

extension SessionAppRegistry: Loggable {
    public static nonisolated let logger = makeLogger()
}
#endif
