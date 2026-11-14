
`HookCaptureCommand` is what a hook helper executable runs when Claude Code fires a registered hook. The registered command line has the shape `<helper> hook --event <Type> [--ppid <int>]`. The command reads the hook payload that Claude Code piped to standard input, wraps it in an envelope together with a snapshot of the process context, and writes the envelope as a drop file that a daemon scans in later. It is the fallback transport: it writes the file whether or not a daemon is listening.

The contract of a hook is "never fail, never produce stdout". The entry point `run` therefore returns exit status 0 whatever goes wrong, so a broken hook never blocks Claude Code. Everything specific to one daemon (the drop directory and its override variable) comes from a `ClaudeHookConfiguration`; the account lookups are injected closures because the toolkit core has no account store.

The type is a caseless enum with two public static entry points, `run` and `buildEnvelope`, plus an internal `systemInfo` and `iso8601UTC` that `HookEnvelopeBuilder` reuses. The directory and file mechanics live in the drop-writer component (`HookDropWriter`); the socket-path twin of the envelope lives in the envelope-builder component (`HookEnvelopeBuilder`); the status-line command that reuses `buildEnvelope` lives in the status-line-capture component (`StatusLineCapture`).

