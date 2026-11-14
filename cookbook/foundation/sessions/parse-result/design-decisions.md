
**Decision**: Four cases instead of an optional.
**Rationale**: The old `nil` meant both "not tracked" and "malformed"; collapsing them quarantined valid StatusLine events and lit the error badge.
**Approved**: pending

**Decision**: An empty file is `.lostEvent`, decided inside the parser, not `.unparseable`.
**Rationale**: The writer died between creating and filling the file, so the event is gone and cannot be recovered; quarantining it would spend the retry budget on a file that never parses. Deciding it here keeps the live scan and the quarantine retry from drifting.
**Approved**: pending

**Decision**: A missing `session_id` is a skip with a reason, not an error.
**Rationale**: Session-less events are deliberately not tracked (the socket path and the envelope builder drop them too); a skip is discarded quietly.
**Approved**: pending

**Decision**: Wrong-typed optional fields fall back to defaults and the parse does not fail.
**Rationale**: One bad optional field must not lose an otherwise valid event; the cost is that a mistyped `timestamp` becomes the empty string without a signal.
**Approved**: pending

**Decision**: The doc comment says "three cases" and then lists four, and the code keeps a no-op `_ = sessionId` line.
**Rationale**: Both are leftovers of the split from the old overloaded `nil`; the code has four cases and the requirements here follow the code.
**Approved**: pending

