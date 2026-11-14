
**Decision**: The agent is a field fixed to `claude` rather than assumed.
**Rationale**: The source states every recorded session is a Claude Code session because Claude Code's hooks record it, and a field means a second agent is a new value and not a new shape.
**Approved**: pending

**Decision**: A `waiting` conversation is refused for send, not just an `ended` one.
**Rationale**: The source states the pane holds a permission or question prompt that ignores typed letters and takes the Return as picking its highlighted choice, approving a tool nobody approved.
**Approved**: pending

**Decision**: A session whose pane another live session also resolves to is refused, and so is the other.
**Rationale**: The source states a headless or nested `claude` inherits its parent's `TERM_SESSION_ID` and TTY, nothing recorded tells the two apart, so neither is sent to while both are live.
**Approved**: pending

**Decision**: A sharer confirmed to have no controlling terminal does not block, while one whose process cannot be read still does; the detached session is itself refused.
**Rationale**: The source states a headless `claude -p` reads a pipe so typing cannot reach it and the pane is the interactive session's alone; only a confirmed `detached` is excused.
**Approved**: pending

**Decision**: Work in progress is a feature branch or a worktree path, with `main`, `master`, `HEAD` and empty as base branches.
**Rationale**: The source defines it as a session on a feature branch or inside a `.claude/worktrees/<name>` directory; a path ending at `worktrees` with no name is not a worktree.
**Approved**: pending


**Decision**: Refusal sentences are English text built in the type, not reason codes.
**Rationale**: The only callers are the `steno conversation send` and `info` verbs, which print the sentence as is, so a code-to-text mapping would add a layer nothing needs yet; a second audience would call for returning a code.
**Approved**: pending
