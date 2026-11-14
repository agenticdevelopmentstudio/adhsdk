
- **Unparsable timestamps**: a `lastActivityAt` or `startedAt` that `UTCTimestamp.canonical` rejects MUST pass through unchanged; no error is raised.
- **Unknown terminal**: an empty or unrecognised `TERM_PROGRAM` yields the raw value as `terminal`; for send it is refused with `an unknown terminal` when empty.
- **Unnamed session**: `sessionName` and `gitBranch` are empty strings for a session with no title or repo (see **summary-session-name** and **summary-git-branch**).
- **Home directory of `/`**: dropping its one trailing slash leaves an empty home, so `homeRelative` returns the path unchanged.
- **Path equal to home with a trailing slash in the path**: only the home directory's trailing slash is stripped; a path `/Users/me/` against `/Users/me` starts with the home and a slash, so it returns `~/`.
- **Detached checkout**: `HEAD` is a base branch, so a detached checkout outside a worktree is not work in progress.
- **Process cannot be read**: the probe returns nil; the session itself is not refused for it, but as a sharer it blocks the other session.
- **Session with pid 0**: `processAttachment` passes it to `ProcessLiveness.terminalAttachment(ofPid:)`, which answers nil for any pid that is not above 0 or whose process is not a Claude Code CLI process, without reading its terminal (`testTerminalAttachmentIsUnknownForAProcessThatIsNotClaude`).
- **Concurrent access**: the DTOs are immutable `Sendable` values and `ConversationSendability` has no state; the probe is `@Sendable`. The sharer check reads a snapshot of `liveSessions` taken by the caller, so a session that starts after the snapshot is not seen. The source defines no ordering beyond that.
- **Offline and error states**: no network is used; the only outside read is the process probe, and its failure is nil, which this code treats as unknown, never as an error.
- **Unrecognised last event**: `SessionActivity` reads an empty `lastEventType`, `Stop`, `StopFailure`, `Interrupted`, `SessionStart` and `SessionEnd` as idle, `Notification`, `PermissionRequest` and `Elicitation` as waiting, and every other value as working, so an active session whose last event is unknown reads as `busy`.
- **Mid-turn and subagent**: a live subagent reads as `busy` even when the main turn's last event is `Stop`, except that it never overrides `waiting`; that precedence is `SessionActivity.derive`'s.

