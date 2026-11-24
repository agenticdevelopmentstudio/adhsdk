
**Decision**: The file holds only data shapes; there is no transition logic between `AttentionState` values.
**Rationale**: The source defines the vocabulary (`open`, `discussing`, `sent`, `done` and the actions `discuss`, `resolved`, `confirm`, `reopen`) and no function maps an action to a state, so a port must not invent one from this file; the mapping belongs to whatever holds the items.
**Approved**: pending

**Decision**: Item and action ids default to a fresh UUID string and are plain Strings.
**Rationale**: Callers may supply their own ids (for example when decoding or replaying), while new items need no caller effort; a String keeps the wire form simple.
**Approved**: pending

**Decision**: Enums decode strictly, with no unknown-value fallback.
**Rationale**: This is how the source behaves, since the enums are plain raw-value enums. An older reader rejects an item carrying a value it does not know.
**Approved**: pending

**Decision**: `AttentionAction.at` is named `at` despite a short identifier.
**Rationale**: The source silences the identifier-length lint rule at the property and at the initializer parameter with a `swiftlint:disable:next identifier_name` comment, so the short name is deliberate and is part of the wire key.
**Approved**: pending

