
**Decision**: Target the exact pane (iTerm session id, else TTY; Terminal.app TTY) and fail with `unsupportedTerminal` or `paneUnresolvable` rather than guess.
**Rationale**: The source calls typing into the wrong session "the whole hazard this guards".
**Approved**: pending

**Decision**: Press Return as a second, separate script after a 300 ms `await`, not in the typing script and not through an AppleScript `delay`.
**Rationale**: Handed in one write, the newline arrives inside the paste and Claude Code's input box keeps it as part of the paste, so the line is typed but never submitted. A `delay` inside one script froze the caller's UI, so the wait is an `await` on the main actor.
**Approved**: pending

**Decision**: Terminal.app also gets a separate `do script ""` for Return even though its own newline exists.
**Rationale**: Seen live: a short line submits, a line of about 200 characters sat in the input until a separate Return. After a line that did submit, the extra Return meets an empty prompt and is ignored.
**Approved**: pending

**Decision**: `escape` turns every line break and tab into a space and drops every other control character.
**Rationale**: `write text` and `do script` press Return at the end of what they are handed, so an embedded newline would submit half the message. Deleting breaks glued words ("the fileare you sure"). A tab is a completion key, and ESC, ^C and ^D are interrupt, clear and exit keystrokes that script-supplied text carries by accident.
**Approved**: pending

**Decision**: `inject` does not raise the terminal by default (`raising: false`); the select-and-raise variant is `script` with `raising: true` and `text: nil`.
**Rationale**: Sending a line is not a request to watch the session, and a terminal jumping forward takes away the window the sender was reading. Raising does not change delivery.
**Approved**: pending

**Decision**: The pane lookup uses `proc_pidinfo` rather than a forked `ps`.
**Rationale**: It is a syscall, near-instant, and safe on the main thread, whereas a forked process with `waitUntilExit` blocks the caller.
**Approved**: pending

**Decision**: The pane-script builders and `escape` are public pure functions, and only `run` executes AppleScript.
**Rationale**: The string assembly and escaping are the risky part and are unit-tested without a real terminal; the app, the CLI and the session click actions share one copy.
**Approved**: pending

**Decision**: Address iTerm2 by its bundle id `com.googlecode.iterm2`, not by the application name.
**Rationale**: The application's name has varied across versions, while the bundle id has not.
**Approved**: pending

**Decision**: Error descriptions are English literals; callers localise by matching the `InjectionError` case, and a later version may move the texts to string keys.
**Rationale**: This is a Foundation-tier helper with no localization bundle, and the typed cases give an app everything it needs to show its own text.
**Approved**: pending
