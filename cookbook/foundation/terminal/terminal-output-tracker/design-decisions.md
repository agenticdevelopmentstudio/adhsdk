
**Decision**: The tracker reads the rendered screen and not the byte stream.
**Rationale**: This is what makes the problem tractable (the type's doc comment says so): the terminal has already applied every cursor move, carriage return and colour code, so a row is the text a person would read.
**Approved**: pending

**Decision**: Rows are numbered from the first line the terminal ever had.
**Rationale**: A row number is scroll-invariant (the `TerminalScreenSnapshot` doc comment): it names the same line before and after output scrolls the oldest lines away, so the tracker can keep its place across trimming.
**Approved**: pending

**Decision**: The cursor's row is shown and remembered, and only what is added to it later is shown again.
**Rationale**: The cursor row is usually an unfinished prompt, and remembering what was shown keeps a prompt from appearing at the end of one reply and again at the start of the next.
**Approved**: pending

**Decision**: The tracker starts at the cursor's row for a chat that connects to a running terminal, and from the top for one that wants startup text.
**Rationale**: Each initializer has its own purpose: `init(startingAt:)` keeps history from before the chat connected from being replayed as a reply, and `init(fromTopOf:)` shows what the terminal printed before anyone was listening.
**Approved**: pending

**Decision**: The command's echo is removed by matching the end of the first non-blank row, ignoring case.
**Rationale**: The shell's echo is the command reappearing on the prompt row (the doc comment on `noteSent`), so only the first non-blank row can be it; a suffix match survives whatever prompt text sits before it.
**Approved**: pending

**Decision**: Lost position restarts at the cursor's row and does not replay.
**Rationale**: A trimmed row or a cursor sent back above the resume row leaves nothing to resume from, so reading starts again at what is on hand, trading some lost lines for no stale text.
**Approved**: pending

**Decision**: Alternate-screen snapshots report nothing.
**Rationale**: A full-screen program's rows are a canvas, not a record of output, and they vanish when it exits (the doc comment on `isAlternateScreen`).
**Approved**: pending

**Decision**: A command long enough to wrap leaves its wrapped echo in the reply, as a known limitation.
**Rationale**: The echo test looks only at the first row, because a row-based match cannot tell a wrapped continuation from output. Revisit if callers send commands longer than the terminal's width and the doubled text proves noisy, for example by matching the echo across the first several rows.
**Approved**: pending

**Decision**: The echo test is a case-insensitive suffix match, so first-row output that happens to end with the command's text is dropped with it, as a known limitation.
**Rationale**: A suffix match survives whatever prompt text sits before the command, which an exact match would not. For example, after `noteSent("ls")` a first row of `pls` is dropped. Revisit if prompts become predictable enough to match the prompt and the command together.
**Approved**: pending
