
**Decision**: The panel enumeration is persisted by raw value, so cases are added
and never renamed.
**Rationale**: The source comment states that the raw value is what is persisted.
**Approved**: pending

**Decision**: The filter text is held on the group but never persisted.
**Rationale**: The source comment says a filter is a moment's question, and a list
already narrowed by a filter from yesterday reads as projects having gone
missing.
**Approved**: pending

**Decision**: A newly activated project is placed after the one on screen.
**Rationale**: The source comment says a project opened from the browser lands
next to the one the user was working in.
**Approved**: pending

**Decision**: `deactivate` returns the next selection rather than applying it.
**Rationale**: The group cannot swap windows itself; the caller owns the window
change and applies the returned id with `select`. The return prefers the next
project, then the previous one, so the neighbour in the bar takes over.
**Approved**: pending

**Decision**: One group object is read by every window's shelf.
**Rationale**: The source comment says every window in the group has its own shelf
and every shelf reads this object, so the panel, active list and filter are the
same whichever window is on screen.
**Approved**: pending

**Decision**: `select(_:)` assigns only on a difference.
**Rationale**: It avoids publishing an unchanged selection to every subscribed
shelf (inferred from the guard in the source; no comment states the reason).
**Approved**: pending

