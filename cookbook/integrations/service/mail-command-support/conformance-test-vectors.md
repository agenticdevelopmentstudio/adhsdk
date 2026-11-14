
No test in the repository references `MailJSON` or `MailDateBound`; every vector below is derived from the source and its doc comments.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-command-support-001 | bound-date-start | `normalize("2026-11-13", edge: .start)` | `"2026-11-13T00:00:00.000Z"` |
| mail-command-support-002 | bound-date-end | `normalize("2026-11-13", edge: .end)` | `"2026-11-13T23:59:59.999Z"` |
| mail-command-support-003 | bound-date-reality, bound-date-no-fallthrough | `normalize("2026-02-30", edge: .start)` | nil |
| mail-command-support-004 | bound-date-reality | `normalize("2023-02-29", edge: .end)` (not a leap year) | nil |
| mail-command-support-005 | bound-date-reality | `normalize("2024-02-29", edge: .start)` (leap year) | `"2024-02-29T00:00:00.000Z"` |
| mail-command-support-006 | bound-timestamp-utc, bound-timestamp-edge-ignored | `normalize("2026-11-13T10:30:00+02:00", edge: .end)` | `"2026-11-13T08:30:00.000Z"` |
| mail-command-support-007 | bound-timestamp-fractions | `normalize("2026-11-13T10:30:00.250Z", edge: .start)` | `"2026-11-13T10:30:00.250Z"` |
| mail-command-support-008 | bound-reject-other | `normalize("", edge: .start)` | nil |
| mail-command-support-009 | bound-reject-other, bound-date-shape | `normalize("2026-1-5", edge: .start)` (parts of 4, 1 and 1 characters) | nil |
| mail-command-support-010 | bound-reject-other | `normalize("yesterday", edge: .end)` | nil |
| mail-command-support-011 | bound-date-shape | `normalize("2026-11-1３", edge: .start)` (final digit a full-width digit) | nil |
| mail-command-support-012 | bound-reject-other | `normalize("2026-11-13T10:30:00", edge: .start)` (no zone designator) | nil |
| mail-command-support-013 | json-sorted-keys, json-pretty-printed | `encode` of a dictionary with keys `b` then `a` | multi-line text in which `"a"` appears before `"b"` |
| mail-command-support-014 | json-encoder-errors | `encode` of a value whose `encode(to:)` throws | the same error is thrown |
| mail-command-support-015 | bound-mcp-rejection | MCP argument `since` = `"2026-13-01"` | `ArgumentError` with `since must be YYYY-MM-DD or an ISO-8601 timestamp` |
| mail-command-support-016 | bound-cli-rejection, bound-cli-edges | CLI `list <account> --since 2026-02-30` | parse fails; no command runs |
| mail-command-support-017 | bound-date-shape, bound-reject-other | `normalize(" 2026-11-13", edge: .start)` (leading space) | nil |
| mail-command-support-018 | bound-date-shape, bound-reject-other | `normalize("2026/11/13", edge: .start)` | nil |
| mail-command-support-019 | bound-date-reality | `normalize("2026-00-10", edge: .start)` | nil |
| mail-command-support-020 | bound-timestamp-utc | `normalize("2026-11-13T10:30:00.1234Z", edge: .start)` | `"2026-11-13T10:30:00.123Z"` |

