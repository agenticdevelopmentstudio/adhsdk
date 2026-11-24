
Vectors 001 to 006 are the six tests in `TerminalOutputTrackerTests`; the rest follow from the source's logic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-output-tracker-001 | init-starting-at, shown-prefix-stripped | start at `["old", "%"]` cursor 1; read the same snapshot (`startsAtTheCursor`) | nil |
| terminal-output-tracker-002 | echo-removal, output-trim | start at `["%"]` cursor 0; `noteSent("echo hi")`; read `["% echo hi", "hi", "%"]` cursor 2 (`dropsTheEcho`) | `hi` then newline then `%` |
| terminal-output-tracker-003 | shown-prefix-stripped, state-advance | start at `["%"]` cursor 0; read `["%", "a", "%"]` cursor 2; `noteSent("ls")`; read `["%", "a", "% ls", "file", "%"]` cursor 4 (`stripsTheShownPrompt`) | `file` then newline then `%`, the prompt not repeated |
| terminal-output-tracker-004 | snapshot-row-numbering, read-range | start at `["x", "%"]` cursor 1; read `["%", "out", "%"]` cursor 3 with first row 1 (`survivesTrimming`) | `out` then newline then `%` |
| terminal-output-tracker-005 | new-output-nil-alternate | read `["vim stuff"]` on the alternate screen (`ignoresAlternateScreen`) | nil |
| terminal-output-tracker-006 | resume-lost-cursor-back | start at `["a", "b", "c", "%"]` cursor 3; read `["%", "", "", ""]` cursor 0 (`recoversFromAClear`) | `%` |
| terminal-output-tracker-007 | init-from-top | `init(fromTopOf:)` a snapshot `["boot", "%"]` first row 0 cursor 1; read it | `boot` then newline then `%` |
| terminal-output-tracker-008 | new-output-nil-empty | read a snapshot with no lines | nil |
| terminal-output-tracker-009 | resume-lost-trimmed | `init(fromTopOf:)` a snapshot with lines `["a", "b"]`, first row 1, cursor row 2, so the next row is 1; then read a snapshot with lines `["p", "q"]`, first row 5, cursor row 6 | `q`, the read restarting at the cursor row because row 1 is gone |
| terminal-output-tracker-010 | cursor-clamped | `init()`; read a snapshot with lines `["x", "y"]`, first row 0, cursor row 9 | `y`, the cursor clamped to row 1, with no crash |
| terminal-output-tracker-011 | echo-record | `init()`; `noteSent("  \n")`; read lines `["% x"]`, first row 0, cursor row 0 | `% x`, because nothing was recorded |
| terminal-output-tracker-012 | echo-removal | `init()`; `noteSent("LS")`; read lines `["% ls"]`, first row 0, cursor row 0 | nil, the first row dropped as the echo, the match ignoring case |
| terminal-output-tracker-013 | echo-cleared | `init()`; `noteSent("ls")`; read lines `["% pwd"]`, first row 0, cursor row 0; then read lines `["% pwd", "% ls"]`, first row 0, cursor row 1 | `% pwd`, then `% ls`: the first read keeps its row and clears the echo, so the second read's `% ls` is not dropped |
| terminal-output-tracker-014 | echo-latest-wins | `init()`; `noteSent("a")` then `noteSent("b")`; read lines `["% b"]`, first row 0, cursor row 0 | nil, the row dropped |
| terminal-output-tracker-015 | output-trim, output-nil-when-blank | `init()`; read lines `["", "  ", ""]`, first row 0, cursor row 2 | nil |
| terminal-output-tracker-016 | output-trim, output-join | `init(fromTopOf:)` lines `["x   ", "", "y  "]`, first row 0, cursor row 2; read the same snapshot | `x`, a newline, an empty line, a newline, `y`: `"x\n\ny"`, with trailing spaces removed |
| terminal-output-tracker-017 | echo-cleared | `init(fromTopOf:)` lines `["", ""]`, first row 0, cursor row 1; `noteSent("ls")`; read the same snapshot; then read lines `["", "% ls", "done", "%"]`, first row 0, cursor row 3 | nil, then `done` newline `%`: the blank first row left the echo pending, so the second read dropped `% ls` |
| terminal-output-tracker-018 | new-output-nil-alternate, state-advance | `init(startingAt:)` lines `["old", "%"]`, first row 0, cursor row 1; read lines `["zz"]`, first row 0, cursor row 0 on the alternate screen; then read lines `["old", "%", "out", "%"]`, first row 0, cursor row 3 | nil, then `out` newline `%`: the alternate read changed nothing, so the second read resumed at row 1 with `%` shown |
| terminal-output-tracker-019 | state-advance | `init(fromTopOf:)` lines `["% ls"]`, first row 0, cursor row 0; `noteSent("ls")`; read the same snapshot; then read lines `["% ls", "out", "%"]`, first row 0, cursor row 2 | nil, then `out` newline `%`: the first read returned nil because only the echo was left, yet it advanced the next row and the shown text |
| terminal-output-tracker-020 | cursor-clamped, state-advance | `init(fromTopOf:)` lines `["a", "b"]`, first row 0, cursor row 9; read the same snapshot; then read lines `["a", "b", "c", "d"]`, first row 0, cursor row 3 | `a` newline `b`, then `c` newline `d`: the clamped row 1, not 9, is the next row to read |
