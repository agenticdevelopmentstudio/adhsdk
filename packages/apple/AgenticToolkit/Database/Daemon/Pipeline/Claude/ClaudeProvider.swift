#if canImport(AgenticToolkitCore)
import Foundation

/// The Claude Code provider's name and the source kinds its records are archived under.
public enum ClaudeProvider {
    /// `RawRecord.provider` for everything Claude Code produces.
    public static let name = "claude"
    /// A hook envelope (`{"event", "timestamp", "hook_data", "context", ...}`) received live.
    public static let hookKind = "hook"
    /// A hook envelope recovered from the legacy `stenographer.db` capture.
    public static let legacyHookKind = "hook-legacy"
    /// One line of a session transcript (`.jsonl`).
    public static let transcriptKind = "transcript"
}
#endif
