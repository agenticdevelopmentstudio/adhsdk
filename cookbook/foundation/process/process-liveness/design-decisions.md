
**Decision**: A process is a Claude Code CLI by its launched executable path from the argument read, not by `proc_pidpath`.
**Rationale**: The type's doc comment on `ProcessLiveness` and the `isClaudeProcess(_:)` comment say the CLI's real image is a version-named binary whose basename is the version, and `proc_pidpath` fails once an update removes an old version's file. The launch path is recorded at exec time, so it is stable and present for every process.
**Approved**: pending

**Decision**: The pid scan is limited to the current user's processes and the buffer has 256 spare entries.
**Rationale**: A live `claude` is always the same user, so the narrower scan avoids a launch-data probe of every root and other-user process each tick. The spare room covers a burst of new processes between the sizing and the fill call, which would otherwise truncate the list.
**Approved**: pending

**Decision**: An unreadable directory does not drop a process that names its session.
**Rationale**: The doc comment on `liveClaudeProcesses()` says the directory lookup fails durably for a revoked vnode or an unmounted volume (a deleted worktree, an ejected disk), and dropping the whole process hid a live `claude` from liveness on every tick, which ended its session while it was still running.
**Approved**: pending

**Decision**: A failed pid scan returns nil, not an empty list.
**Rationale**: A Mac always has processes, so an empty pid list means the scan failed; the caller skips reconciliation rather than ending every session on a bad scan.
**Approved**: pending

**Decision**: The session comes from the CLI's own session file, never from the directory.
**Rationale**: The directory is not a link: a session records wherever its agent last ran a command, so one that moved into a submodule or a worktree no longer sits where its process was launched, while an older session the same process left still does. The file's `pid` check guards against a reused pid.
**Approved**: pending

**Decision**: Ambiguity in a directory is a refusal, not a guess.
**Rationale**: The recovered pid's environment decides which account an event is billed to; choosing a first match among two sessions could bill session B's event to session A's account. Returning nil makes the caller use the read-time OAuth account, the safe fallback, so an ambiguous event is never attributed to the wrong account.
**Approved**: pending

**Decision**: The directory match is two passes, cheapest first, and the real-path lookup only runs on `claude` processes.
**Rationale**: The kernel path is answered from kernel state and is already physical, and the launch-data read pages in the process's memory, so it runs only for the few processes in the directory. A real-path lookup walks the file system and blocks as long as a dead network mount does; a shell parked in an unreachable share must not stall the hook-ingest path.
**Approved**: pending

**Decision**: `canonicalPath` uses `realpath`, not `URL.resolvingSymlinksInPath`.
**Rationale**: The doc comment on `canonicalPath(_:)` says the URL form deliberately leaves `/tmp`, `/var` and `/etc` unresolved, so a stored logical `$PWD` would not equal the physical path the kernel reports (`/private/tmp/x`).
**Approved**: pending

**Decision**: Headless detection trusts the session file's `entrypoint` first, then the arguments, and ignores `kind`.
**Rationale**: The doc comment on `isHeadless(argv:sessionFile:)` says every scripted entry starts with `sdk` (`claude -p` is `sdk-cli`) where a terminal session is `cli`, while `kind` reads `interactive` for both. Without an entrypoint (an older CLI, or the moment before the file is written) `-p` or `--print` decides.
**Approved**: pending

**Decision**: A headless `claude` is detached even when it has a terminal, and an unknown attachment is nil.
**Rationale**: A `claude -p` started from an interactive shell inherits the shell's tty yet takes its prompt from its arguments, so typed keystrokes reach the shell or another claude in the pane. Callers read nil as "might be attached", never as "detached".
**Approved**: pending

**Decision**: The directory string is read within the field width.
**Rationale**: The comment on the directory read in `ProcessLiveness.swift` says a path field with no end marker (a kernel bug) must not make the string read run into adjacent struct memory.
**Approved**: pending

**Decision**: Whether a parent that is itself a live `claude` marks a process as that CLI's helper is the caller's reading of `parentPid`, not something this type decides.
**Rationale**: The doc comment on `LiveClaudeProcess.parentPid` says such a process is that CLI's helper, not a session. The type only reports the parent; a session reconciler applies the interpretation.
**Approved**: pending
