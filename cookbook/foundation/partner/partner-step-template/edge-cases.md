
- **Null / empty input**: An empty command returns an empty string; an empty `values` leaves every placeholder as written (see `#requirements/empty-values-unchanged`); an empty step list returns an empty list; an empty value fills as nothing in a Claude step and as two single quotes in a terminal step.
- **Boundary values**: Adjacent placeholders such as `{a}{b}` are both filled; a placeholder at the very start or end of the command is filled; the key is word characters only, so `{a-b}` is not a placeholder and stays as written.
- **Concurrent access**: Both functions are pure over their arguments; the compiled expression is a shared immutable constant, so concurrent callers are safe.
- **Error states**: The functions cannot fail. The placeholder expression is a constant created with a forced `try!` (the source disables the lint rule on that line); it is fixed, so it cannot fail at run time.
- **Offline / disconnected state**: Not applicable: the type performs no network or file access.
- **Cancellation**: Not applicable: every function is synchronous.
- **Hostile values**: A value containing `{key}`, a single quote, `$`, backticks or spaces is covered by `#requirements/hostile-values-inert`; that is the reason for one-pass substitution and for quoting.

