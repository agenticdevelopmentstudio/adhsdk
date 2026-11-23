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
///
/// Only a pid that names one other process can own the slot: `kill(0, 0)`
/// signals the caller's process group and `kill(-1, 0)` every process the
/// daemon may signal, so 0 and a negative pid would read as alive forever, and
/// so would the daemon's own pid. Those are refused (`invalidPid`) and never
/// stored.
public actor SessionAppRegistry {
    public enum RegisterResult: Sendable, Equatable {
        case registered
        case alreadyRegistered(ownerPid: Int32)
        /// The pid names no single other process; nothing was stored.
        case invalidPid
    }

    private var ownerPid: Int32?
    private let daemonPid: Int32

    /// - Parameter daemonPid: this daemon's own pid, which can never own the
    ///   slot. Injected for tests; defaults to the running process.
    public init(daemonPid: Int32 = ProcessInfo.processInfo.processIdentifier) {
        self.daemonPid = daemonPid
    }

    /// True when `pid` can own the slot: positive and not the daemon's own.
    public nonisolated func isValidOwner(pid: Int32) -> Bool {
        pid > 0 && pid != daemonPid
    }

    public func register(pid: Int32) -> RegisterResult {
        guard isValidOwner(pid: pid) else {
            Self.logger.info("Register refused for invalid pid \(pid, privacy: .public)")
            return .invalidPid
        }
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

    /// Releases the slot if `pid` owns it; false otherwise, including for a
    /// pid that could never own it.
    public func unregister(pid: Int32) -> Bool {
        guard isValidOwner(pid: pid), ownerPid == pid else { return false }
        ownerPid = nil
        Self.logger.info("Unregistered owner pid \(pid, privacy: .public)")
        return true
    }

    /// Releases the slot if `pid` owns it and reports the state afterwards, in
    /// one isolation hop: no register can run between the release and the
    /// owner read, so the reply describes exactly what this release left.
    /// `released` is true only when this call gave up the slot.
    public func unregisterAndReport(pid: Int32) -> (released: Bool, owner: Int32?) {
        let released = unregister(pid: pid)
        return (released, currentOwner())
    }

    public func currentOwner() -> Int32? {
        guard let pid = ownerPid else { return nil }
        if Self.isAlive(pid: pid) { return pid }
        ownerPid = nil
        return nil
    }

    private static func isAlive(pid: Int32) -> Bool {
        // 0 and negatives address process groups, which "exist" forever.
        guard pid > 0 else { return false }
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
