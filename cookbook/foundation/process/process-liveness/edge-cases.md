
- **Null and empty input**: A nil environment MUST fall back to `~/.claude` for the session file. An empty `CLAUDE_CONFIG_DIR` MUST be treated as unset. An empty `sessionId` in a session file MUST give nil. An empty launch path MUST count as not Claude.
- **Boundary values**: A pid at or below 0 MUST be dropped by the pid scan and MUST give nil from `terminalAttachment(ofPid:)`. A process with no session and no directory MUST be left out of the live list.
- **Concurrent access**: The type holds no state and takes no lock, so calls may run in parallel. The process table can change under a scan; a process that exits mid-scan is skipped, and the spare pid buffer covers a burst of new processes. A result is a snapshot.
- **Error states**: A failed pid scan MUST give nil, not an empty list. A failed per-process read MUST skip that process. A kernel call that fails inside `terminalAttachment(ofPid:)` MUST give nil. Nothing throws and nothing is logged.
- **Pid reuse**: A session file left by a dead process whose pid was reused MUST name no session, because its own `pid` field differs.
- **Slow file systems**: A real-path lookup on an unreachable network mount blocks; it MUST NOT be run on a process that is not Claude, so a shell parked in an unreachable share cannot stall the hook-ingest path.
- **Ambiguity**: Two `claude` processes in one directory MUST give nil; the caller falls back to the read-time OAuth account.
- **Directory is not the session**: A session that moved into a submodule or a worktree no longer sits where its process was launched, while an older session the same process left still does, so the directory MUST NOT be used to name the session.
- **Offline or disconnected state**: Not applicable — this type reads local kernel data and one local file only.

