
**Decision**: The spelling matches Python's `shlex.quote`: single quotes, embedded quote written as `'"'"'`, and a plain class of `[A-Za-z0-9_@%+=:,./-]`.
**Rationale**: The type doc comment (`ShellQuoting.swift`, lines 3-6) states that the Python helpers and this code write identical strings for the same path in a shared configuration file, so a file written by either side compares equal.
**Approved**: pending

**Decision**: The embedded-quote replace is `.literal`, not the default grapheme comparison.
**Rationale**: The doc comment on `quote(_:)` (`ShellQuoting.swift`, lines 9-11) records that the default compares by grapheme, so a single quote followed by a combining mark (U+0301) would go unescaped and break the quoting. This is a Swift pitfall; other platforms compare by code unit or code point and do not have it.
**Approved**: pending

**Decision**: The plain test is per Unicode scalar against an ASCII-only set.
**Rationale**: A non-ASCII letter is quoted rather than passed bare (test: nonASCIILetterIsQuoted). The doc comment on `quoteIfNeeded(_:)` (`ShellQuoting.swift`, lines 16-18) lists the class and gives no further reason; the class follows `shlex.quote`, which the type doc comment (lines 3-6) names as the spelling to match.
**Approved**: pending

