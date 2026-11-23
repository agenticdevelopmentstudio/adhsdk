
**Decision**: Report output once it has been quiet for a period, and also at a maximum latency.
**Rationale**: The source says a shell prints in bursts and that without the pause one command's output would arrive as a dozen fragments, while a stream that never pauses, such as `yes` or `tail -f`, must still reach the transcript and whoever waits on it.
**Approved**: pending

**Decision**: Write Return as a separate write after a pause rather than inside the text.
**Rationale**: The source says a program reading keystrokes, Claude Code among them, takes a long line in one write for a paste and keeps the Return as pasted text, so the message sits unsent; a Return on its own after a pause reads as a key press.
**Approved**: pending

**Decision**: Measure quiet from the terminal's output activity, not from the replies.
**Rationale**: The source says a stream that never pauses is reported only once per maximum latency, so a settle shorter than that would judge it finished between two reports.
**Approved**: pending

**Decision**: Hold a wait's settle to half its timeout.
**Rationale**: The source says output that stops early is always judged finished before the deadline judges it still running; a settle as long as the timeout would lose every race.
**Approved**: pending

**Decision**: Keep unclaimed output, capped at the latest 64 KiB.
**Rationale**: The source says output a slow command prints after its wait gave up is not lost, but a chat left connected to a busy log would otherwise hold all of it.
**Approved**: pending

**Decision**: Do not start a run's settle or timeout until its Return is written.
**Rationale**: The source says the echo of the text alone would settle a short wait before the command starts, and its output would go to whichever wait came next; a command's time is counted from the Return.
**Approved**: pending

**Decision**: Let text already typed get its Return in its own terminal, and only Control-C drops it.
**Rationale**: The source says closing a pane must never leave a command typed but not run.
**Approved**: pending

**Decision**: Never report a responding state.
**Rationale**: The source says a shell has no turns, so the composer is never locked waiting for one to end.
**Approved**: pending

