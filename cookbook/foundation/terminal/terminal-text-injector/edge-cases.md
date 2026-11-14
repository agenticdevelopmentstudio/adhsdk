
- **Null / empty input**: An empty `termProgram` is unsupported and reports the name `an unknown terminal` (MUST). An empty `text` (non-nil) produces a script that writes an empty string: for Terminal.app `do script "" in t` is a Return, while for iTerm `write text "" newline no` types nothing. Through `inject` the Return half still runs on both terminals, so an empty `text` presses Return once and submits whatever the pane's prompt holds; `escape("")` is empty. A `termSessionId` that is empty or only colons yields no uuid and falls back to the TTY (MUST).
- **Boundary values**: A pid of 0 or below has no TTY (MUST). When `resolveTarget` needs the TTY (iTerm with no uuid, or Terminal.app) it converts the `Int` pid with `Int32(pid)` and no range check, so a pid above `Int32.max` traps; real pids never reach that, and the signature leaves the range to the caller.
- **Line breaks in text**: Any line break becomes a single space, so a multi-line message is sent as one line and submitted once (MUST).
- **Embedded control keys**: ESC, ^C, ^D, DEL and NUL are dropped so they cannot interrupt, clear or exit the agent (MUST).
- **Pane closed between halves**: The Return half finds the pane afresh and fails `paneNotFound`; the text already typed stays in the pane's input (MUST).
- **Cancellation**: `try? await Task.sleep` discards the cancellation error, so a cancelled caller still presses Return immediately without the 300 ms wait. The source has no other cancellation path; this is a fact about the code, not a contract it declares.
- **Concurrent access**: `inject` and `run` are `@MainActor`, so calls are serialised on the main actor; the `await` between the halves lets other main-actor work, including another `inject`, interleave between one call's typing and its Return. The source adds no lock or per-pane queue.
- **Retry and logging**: The component never retries a failed script, applies no timeout and logs nothing; each caller decides what to do with the returned `InjectionError`.
- **Error states**: Every failure is returned as an `InjectionError` in a `Result`; none is thrown or logged. A compile failure, an AppleScript error and a miss each surface as a distinct case.
- **Automation denied**: An error with number -1743 or -1744, or a "not authorized" or "privilege violation" message, becomes `permissionDenied` carrying the terminal's bundle id (MUST).
- **Unsupported terminal**: Warp, VS Code and unknown terminals fail with `unsupportedTerminal` and nothing is typed (MUST).
- **Blocking**: `NSAppleScript.executeAndReturnError` is synchronous and runs on the main actor, so a slow terminal holds the main thread for that script's duration; the source has no timeout.
- **Offline / disconnected state**: Not applicable: the component makes no network request; it talks to a local application over Apple events.

