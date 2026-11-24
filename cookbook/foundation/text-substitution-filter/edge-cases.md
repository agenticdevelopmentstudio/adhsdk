
- **Null / empty input**: Empty text, or a filter with no pairs, returns the text unchanged (MUST). Pairs with an empty side never enter the filter (MUST). An empty or all-separator text parses to `identity`-equivalent pairs (MUST).
- **Boundary values**: An entry like `a=b` with no spaces parses the same as `a = b` (MUST). A one-letter match is cased as all capitals or all lower case by `casing` (MUST). A match with no letters keeps the replacement as given (MUST).
- **Overlapping patterns**: The longest pattern wins at a position; a shorter pattern that starts inside it cannot match there because the scan resumes after the replaced text (MUST).
- **Duplicate patterns**: Two pairs with the same alias are both kept; the first in declaration order is the one used when the text matches (SHOULD be avoided by callers; the source does not reject it).
- **Pairs that cannot round-trip**: A pair whose side contains `;` or a newline, or whose alias contains `=`, or whose sides carry leading or trailing whitespace, does not reappear identically after `serialized` and `init(parsing:)`, because the parser splits on those characters and trims; `init(pairs:)` itself accepts them.
- **Unicode**: Matching is case-insensitive and works on whole text, and unmatched text is copied through unchanged. Length ordering counts `Character`s in the Swift source, so a combined character counts once; a platform that counts UTF-16 units or code points MAY order patterns of differing Unicode composition differently, and that divergence is allowed.
- **Large text**: A single regular expression covers every pattern, because a browser pane conceals whole page reads, hundreds of kilobytes at a time, on the main actor; the expression is rebuilt on every call.
- **regex-failure-passthrough**: NEEDS REVIEW: Not implemented in source. A combined expression that fails to compile is meant to return the input text unchanged with no error or log, so a `concealing` call would pass real text through; no test shows the case, because every pattern is escaped.
- **Concurrent access**: The type is an immutable `Sendable` value and each call builds its own expression, so any number of threads may call it at once with no ordering rule.
- **Error states**: No function throws or returns an error; unusable parse entries are skipped and a compile failure is meant to fall back to the input text.
- **Offline / disconnected state**: Not applicable: the component performs no network access or I/O.

