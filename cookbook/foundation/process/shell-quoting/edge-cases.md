
- **Null / empty input**: An empty word MUST become `''` from both `quote(_:)` and `quoteIfNeeded(_:)`; an empty word list MUST yield the empty string from `commandLine(_:)`.
- **Boundary values**: A word made only of single quotes MUST have each quote escaped, so `'` becomes `''"'"''`. A word one scalar outside the plain class, such as a trailing space, MUST be quoted whole, never partly.
- **Malformed input**: Any string is accepted; the functions do not validate. Characters special to a shell (`$`, backtick, `*`, `~`, `;`, newline) are not in the plain class, so `quoteIfNeeded(_:)` quotes them, and inside single quotes the shell does not expand them.
- **Command position**: The first word of `commandLine(_:)` is in command position. `commandLine(["FOO=bar", "ls"])` gives `FOO=bar ls`, which a shell runs as an environment assignment followed by `ls`, and a reserved word such as `if` as the first word is parsed as a keyword. The caller MUST pass a real program path as the first word; the functions do not guard against this.
- **Unicode**: A single quote followed by a combining mark MUST still be escaped (see **quote-replaces-literally**). Non-ASCII letters are quoted, never passed bare.
- **Concurrent access**: The functions are pure and the plain character set is an immutable `private static let`, so concurrent calls from any thread do not interact.
- **Error states**: Not applicable: no function throws or returns an error value, and none touches the file system, network or a process.
- **Offline / disconnected state**: Not applicable: the functions perform no network access.
- **Cancellation and timeouts**: Not applicable: each call is a synchronous in-memory string transformation with no wait.

