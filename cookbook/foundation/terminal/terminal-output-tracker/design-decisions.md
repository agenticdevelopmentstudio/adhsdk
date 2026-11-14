
**Decision**: The tracker reads the rendered screen and not the byte stream.
**Rationale**: The source says this is what makes the problem tractable: the terminal has already applied every cursor move, carriage return and colour code, so a row is the text a person would read.
**Approved**: pending

**Decision**: Rows are numbered from the first line the terminal ever had.
**Rationale**: The source calls this scroll-invariant: a row number names the same line before and after output scrolls the oldest lines away, so the tracker can keep its place across trimming.
**Approved**: pending

**Decision**: The cursor's row is shown and remembered, and only what is added to it later is shown again.
**Rationale**: The source says the cursor row is usually an unfinished prompt, and this keeps a prompt from appearing at the end of one reply and again at the start of the next.
**Approved**: pending

**Decision**: The tracker starts at the cursor's row for a chat that connects to a running terminal, and from the top for one that wants startup text.
**Rationale**: The source gives each initializer a purpose: `init(startingAt:)` keeps history from before the chat connected from being replayed as a reply, and `init(fromTopOf:)` shows what the terminal printed before anyone was listening.
**Approved**: pending

**Decision**: The command's echo is removed by matching the end of the first non-blank row, ignoring case.
**Rationale**: The source says the shell's echo is the command reappearing on the prompt row, so only the first non-blank row can be it; a suffix match survives whatever prompt text sits before it.
**Approved**: pending

**Decision**: Lost position restarts at the cursor's row and does not replay.
**Rationale**: The source says a trimmed row or a cursor sent back above the resume row leaves nothing to resume from, so reading starts again at what is on hand, trading some lost lines for no stale text.
**Approved**: pending

**Decision**: Alternate-screen snapshots report nothing.
**Rationale**: The source says a full-screen program's rows are a canvas, not a record of output, and they vanish when it exits.
**Approved**: pending

