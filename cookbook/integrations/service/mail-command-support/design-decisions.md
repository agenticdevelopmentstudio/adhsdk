
**Decision**: Output is pretty-printed with sorted keys.
**Rationale**: The same value always prints the same text, so output can be diffed and compared between the CLI and the MCP tools.
**Approved**: pending

**Decision**: `MailJSON` leaves every `JSONEncoder` strategy at its default.
**Rationale**: The records the front ends print already carry timestamps as strings and keys in the shape the records name, so no conversion is needed. A port that adds a strategy would change the shape both front ends share.
**Approved**: pending

**Decision**: Date-only bounds become the first or last millisecond of a UTC day, and timestamps are rewritten to the same millisecond UTC form.
**Rationale**: The source comment gives the reason: the store compares UTC strings lexically, so every bound must be in one fixed-width form.
**Approved**: pending

**Decision**: A date-shaped value that is not a real date is rejected and never retried as a timestamp.
**Rationale**: `isRealDate` returns a three-way answer (not date-shaped, real, not real) so that `2026-02-30` fails instead of falling through. The check compares the components read back from the calendar because the Gregorian calendar rolls an impossible date forward instead of failing.
**Approved**: pending

**Decision**: A rejected bound is nil, not a thrown error, and the two front ends report it differently.
**Rationale**: The MCP tools can name the argument and the accepted forms in an `ArgumentError`; the command-line parser only returns no result, so the offending value is not named. This is a difference between callers, not between the helpers.
**Approved**: pending

**Decision**: There is no test file for these helpers.
**Rationale**: None is given in the source. The vectors above are derived from the code and its comments, and the compliance table records the gap under unit-test-coverage.
**Approved**: pending

