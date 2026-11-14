
**Decision**: Work on bytes, not text.
**Rationale**: The type's doc comment says a terminal stream is not guaranteed to be valid UTF-8 at any boundary, and decoding it to match would corrupt binary or a half character at the end of a read.
**Approved**: pending

**Decision**: Fold case only for ASCII letters; every other byte matches exactly.
**Rationale**: The type's doc comment says a stream cannot afford Unicode case folding across a read boundary and names typed at a shell are overwhelmingly ASCII; this is narrower than the filter's own `String` matching, a known deviation.
**Approved**: pending

**Decision**: Hold any run that could still become a match, even when a shorter pattern already matches.
**Rationale**: Emitting half a name and matching the other half later is the leak the type exists to stop; holding costs a short delay that the owner bounds with `flush()`.
**Approved**: pending

**Decision**: The type has no timer; the owner calls `flush()` after a moment of quiet.
**Rationale**: The doc comment on `StreamingTextSubstitution` says the owner's output side flushes after a moment of quiet, so a prompt ending in a prefix of a word is not kept off the screen forever; keeping the clock outside keeps the type pure and testable.
**Approved**: pending

**Decision**: Longest pattern first, replacements never rescanned, and no whole-word or case-matching options.
**Rationale**: The same left-to-right rules as `TextSubstitutionFilter` (a replacement is never rewritten by a later pair, the longer name wins), but without that filter's `wholeWords` and `matchingCase` options, which the stream does not implement.
**Approved**: pending

