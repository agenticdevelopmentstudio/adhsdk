#if canImport(AgenticDeveloperHubSDKCore)
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
    /// A quarantined drop file's exact bytes, kept in the raw archive only: the
    /// normalizer turns it into nothing and no sink reads it, so preserving a
    /// file never applies it to events.db or the session database.
    public static let quarantineKind = "hook-quarantine"
}
#endif
