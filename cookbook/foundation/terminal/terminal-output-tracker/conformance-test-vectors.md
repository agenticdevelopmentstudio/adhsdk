
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
| terminal-output-tracker-009 | resume-lost-trimmed | start at row 1; read a snapshot whose first row is 5 with lines `["p", "q"]` and cursor 6 | `q` only, the read restarting at the cursor row because row 1 is gone |
| terminal-output-tracker-010 | cursor-clamped | read a snapshot of 2 lines starting at row 0 with cursor row 9 | the last line only, with no crash |
| terminal-output-tracker-011 | echo-record | `noteSent("  \n")`, then read a first row of `% x` | the row is kept, because nothing was recorded |
| terminal-output-tracker-012 | echo-removal | `noteSent("LS")`; first row `% ls` | the row is dropped, the match ignoring case |
| terminal-output-tracker-013 | echo-cleared | `noteSent("ls")`; first row `% pwd`; then a later read whose first row is `% ls` | both reads keep their rows, the echo cleared after the first non-blank row |
| terminal-output-tracker-014 | echo-latest-wins | `noteSent("a")` then `noteSent("b")`; first row `% b` | the row is dropped |
| terminal-output-tracker-015 | output-trim, output-nil-when-blank | rows `["", "  ", ""]` | nil |
| terminal-output-tracker-016 | output-trim | rows `["x   ", "", "y  "]` | `x`, a blank line, `y`, with trailing spaces removed |
| terminal-output-tracker-017 | echo-cleared | `noteSent("ls")`; first read has a blank first row and a later row; then the echo row arrives | the echo is still pending after the blank first row |
| terminal-output-tracker-018 | new-output-nil-alternate, state-advance | alternate-screen read, then a normal read of the same text | the alternate read changes nothing; the normal read returns the text |

