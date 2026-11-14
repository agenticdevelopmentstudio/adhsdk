
**Decision**: The switch is a shared class instance, not a per-browser flag.
**Rationale**: The source comment states that a project hands one object to all
of its browser panes so that turning it off in one pane shows hidden files in
every pane of that project.
**Approved**: pending

**Decision**: The object reports changes through an `onChange` callback and does
no persistence itself.
**Rationale**: The source comment says "Called after each change, for the owner
that persists it", keeping storage out of the model so a browser built without
an owner works with an in-memory default.
**Approved**: pending

**Decision**: `onChange` is guarded against same-value assignments, while the
published property is not.
**Rationale**: The did-set guard compares with the old value before calling the
owner, so persistence is not rewritten on a no-op. The published channel is the
property wrapper's own and fires on every assignment; the file browser view
controller de-duplicates on its side.
**Approved**: pending

**Decision**: The default is on (excluded content hidden).
**Rationale**: The source comment says "the default is that excluded content
stays hidden", for both an explicit default argument and a browser that builds
its own state.
**Approved**: pending

**Decision**: Subscribers must not read the value synchronously from the
publisher.
**Rationale**: `@Published` publishes from will-set. The file browser view
controller's source comment records the workaround: it hops to the main run
loop so the new value has landed before the patterns are re-read.
**Approved**: pending

