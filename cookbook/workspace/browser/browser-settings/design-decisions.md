
**Decision**: a moved control keeps its key; only its group changes.
**Rationale**: A key is a storage format once shipped; renaming one orphans
every user's stored value. Moving controls is a presentation change and must
stay one (`optimize-for-change`).
**Approved**: pending

**Decision**: site data moves out of the topic into a modal Site Data window.
**Rationale**: From the design. A table of every site's data crowds a topic
that is otherwise rows of switches; a resizable window gives the table the
room it needs.
**Approved**: pending

**Decision**: "Agent can see history" defaults to None and is per pane.
**Rationale**: The owner's decision: an agent with privacy on has little
reason to see history. Per pane follows the layered settings unit, so the
override covers all of a pane's tabs.
**Approved**: pending

**Decision**: the recording gate is one function every record call goes
through.
**Rationale**: A private pane must never record, and a second call site that
forgot the private check would leak a visit; one gate keeps the rule in one
place (`dry`).
**Approved**: pending

**Decision**: "Open sites in tabs" and "Keep visits for" stay Settings-window
only, as today.
**Rationale**: Builder's reading of existing behavior: the first governs a
window's New command, the second a store shared by the whole app; neither is
a pane's to override.
**Approved**: pending

**Decision**: the "every key has a home" check counts the Chrome topics only
when they are compiled in.
**Rationale**: Builder's choice. With the Chrome engine compiled out its four
keys have no topic to live in, and a check that failed on them would only be
silenced.
**Approved**: pending

