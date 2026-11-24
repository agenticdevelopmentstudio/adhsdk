
**Decision**: Substitute in a single left-to-right pass rather than one replacement per pair.
**Rationale**: A replacement must never be rewritten by a later pair: with `a = b; b = c`, "a" is sent as "b", not as "c", which is the least surprising result (principle of least astonishment).
**Approved**: pending

**Decision**: The longest pattern wins at each position, by sorting patterns longest first in one alternation.
**Rationale**: `mike fullerton` must be replaced whole before a shorter `mike` pair can split it; an alternation takes the first alternative that matches at a position.
**Approved**: pending

**Decision**: Matching is case-insensitive in both directions.
**Rationale**: A program prints a name however it likes and each case is the same leak.
**Approved**: pending

**Decision**: Case matching (`matchingCase`) is opt-in and the pair's own case is the default.
**Rationale**: The source documents the replacement as "written as given"; callers that want "BLUEBIRD" to become "REDBIRD" ask for it. Mixed-case or letterless matches keep the replacement as given, since no rule can be read from them.
**Approved**: pending

**Decision**: `wholeWords` exists only on `revealing`.
**Rationale**: An alias inside a longer word or a host name ("robin" in `robinhood.com`) would otherwise be turned into an address nobody typed. `concealing` hides real text wherever it appears, since a partial leak is still a leak.
**Approved**: pending

**Decision**: Pairs with an empty side are dropped at initialisation, and unusable parse entries are skipped rather than refused.
**Rationale**: An empty pattern matches everywhere and an empty replacement deletes text; half an entry is the normal state of one typed a field at a time.
**Approved**: pending

**Decision**: One regular expression with a capture group per pattern, not a probe per pattern at each character.
**Rationale**: A browser pane conceals whole page reads, hundreds of kilobytes at a time, on the main actor.
**Approved**: pending

**Decision**: When the combined expression cannot be compiled, `substitute` falls back to returning the input.
**Rationale**: Every pattern is escaped, so a compile failure is not expected. The risk is accepted knowingly: if it did happen, `concealing` would pass real text through unchanged, so a port that needs to fail closed should redact or return an error instead. See Edge Cases.
**Approved**: pending

