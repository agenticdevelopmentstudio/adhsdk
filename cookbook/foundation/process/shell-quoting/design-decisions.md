
**Decision**: The spelling matches Python's `shlex.quote`: single quotes, embedded quote written as `'"'"'`, and a plain class of `[A-Za-z0-9_@%+=:,./-]`.
**Rationale**: The source states that the Python helpers and this code write identical strings for the same path in `settings.json` and status-line entries, so a file written by either side compares equal.
**Approved**: pending

**Decision**: The embedded-quote replace is `.literal`, not the default grapheme comparison.
**Rationale**: The source comment records that the default compares by grapheme, so a single quote followed by a combining mark would go unescaped and break the quoting.
**Approved**: pending

**Decision**: The plain test is per Unicode scalar against an ASCII-only set.
**Rationale**: A non-ASCII letter is quoted rather than passed bare (test: nonASCIILetterIsQuoted). The source gives no further reason; the class follows `shlex.quote`, which the source names as the spelling to match.
**Approved**: pending

