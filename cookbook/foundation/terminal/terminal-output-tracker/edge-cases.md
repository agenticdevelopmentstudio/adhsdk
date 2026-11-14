
- **Empty or missing input**: a snapshot with no lines returns nil and leaves the tracker as it was.
- **Alternate screen**: a read while a full-screen program (vim, less) is up returns nil and leaves the tracker as it was, so the reply picks up from where it stopped after the program exits.
- **Cursor outside the lines**: the cursor row is clamped into the snapshot's rows, so a snapshot whose cursor lies beyond the last line reads to the last line.
- **Output scrolled away**: when the row to resume from has been trimmed off the top, the tracker restarts at the cursor's row, so the lines that scrolled away unread are lost; the tracker accepts this over replaying stale text.
- **Clear or reset**: a cursor above the resume row restarts at the cursor's row with the shown text forgotten.
- **Prompt that changed**: when the first row does not start with the shown text, the row is returned whole.
- **Echo that does not match**: the first non-blank row is kept and the pending echo is dropped.
- **Wrapped echo**: a command long enough to wrap across rows is a row-based match against only the first row; a first row that does not end with the echo is kept as output. A caller that sends long commands sees the wrapped echo in the reply (a recorded Design Decision).
- **Blank first row**: a read whose first row is blank leaves the echo pending for the next read.
- **Echo as substring**: the echo test is a suffix match ignoring case, so output that happens to end with the command's text on the first row is dropped with it (a recorded Design Decision); for example, after `noteSent("ls")` a first row of `pls` is dropped.
- **Empty send**: `noteSent` with text that is only whitespace records nothing, and a previously pending echo is cleared by it.
- **Nothing non-blank left**: a read whose rows are all blank, or whose only non-blank row was the echo, returns nil but still advances the next row and the shown text.
- **Concurrent access**: the type is a value with mutating methods; one owner reads and writes it, and a copy carries its own position.
- **Error and offline states**: the tracker does no I/O and has no error path; a terminal that has exited simply stops producing new rows.

