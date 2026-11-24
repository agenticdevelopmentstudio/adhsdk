import Foundation

/// What a session is doing right now — distinct from its ``SessionStatus``
/// ("does a process exist"): a session can be alive and idle, alive and working,
/// or alive and blocked on the user.
///
/// The one reading of a session's recorded turn state, shared by the Sessions
/// window's activity icon and `steno conversation status`, so the two can never
/// disagree about what a session is doing.
public enum SessionActivity: String, CaseIterable, Sendable {
    /// Mid-turn: thinking, or running a tool.
    case working
    /// Alive, but nothing in flight.
    case idle
    /// Blocked on the user — a permission prompt, an elicitation, a notification.
    case waiting

    /// Derived from what the daemon recorded rather than stored: the daemon records
    /// what happened, not what it means, so the meaning can be re-read (or re-mapped
    /// for a new event type) without a schema change.
    ///
    /// A live subagent reads as working, because it is — but it never overrides
    /// ``waiting``: a session blocked on a permission prompt still needs the user,
    /// whatever its subagents are doing.
    ///
    /// - Parameters:
    ///   - isActive: whether the session's process is alive; anything else is idle.
    ///   - lastEventType: the last hook event recorded for the main agent's turn.
    ///   - subagentWorking: the daemon's verdict that a subagent was busy just now.
    public static func derive(isActive: Bool, lastEventType: String, subagentWorking: Bool) -> SessionActivity {
        guard isActive else { return .idle }
        let turn = turnActivity(lastEventType: lastEventType)
        guard turn == .idle, subagentWorking else { return turn }
        return .working
    }

    /// The activity the *main agent's turn* alone tells.
    public static func turnActivity(lastEventType: String) -> SessionActivity {
        switch lastEventType {
        // The agent has handed control back to the user and is waiting on them.
        // (The daemon only records a Notification that asks for an answer — not
        // the idle reminder sent after every finished turn.)
        case "Notification", "PermissionRequest", "Elicitation":
            return .waiting
        // The turn is over; nothing is running until the user says something.
        // `StopFailure` ends a turn on an API error. `Interrupted` is the daemon's
        // own record of the user cutting a turn short, which fires no hook.
        // `SessionStart` opens a session at its prompt.
        case "Stop", "StopFailure", "Interrupted", "SessionStart", "SessionEnd", "":
            return .idle
        // UserPromptSubmit, Pre/PostToolUse, everything else: the agent is mid-turn.
        default:
            return .working
        }
    }
}
