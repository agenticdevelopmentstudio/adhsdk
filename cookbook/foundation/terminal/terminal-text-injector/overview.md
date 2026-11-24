
`TerminalTextInjector` types a line of text (for example `/compact`) into the live terminal pane a session is running in, by scripting iTerm2 or Terminal.app through `NSAppleScript`. It runs only in a process that holds a user's GUI session and the TCC Automation grant: the app, or the command-line tool from a terminal. A daemon can drive neither.

It targets the exact pane so it never types into the wrong session. iTerm2 is matched by session id (from `TERM_SESSION_ID`) or, failing that, by the pane's TTY. Terminal.app is matched by the tab's TTY. A terminal it cannot target precisely fails with `unsupportedTerminal` instead of a guess. The pane resolution and the AppleScript builders are pure `static` functions, unit-tested without driving a terminal; only `inject` and `run` execute AppleScript. `SessionWatcher.SessionWatcherActionHandler` shares the same builders, passing `text: nil`, for its select-and-raise click actions.

