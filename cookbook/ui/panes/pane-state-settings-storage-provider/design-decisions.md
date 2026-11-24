
**Decision**: Each value is stored as JSON inside a one-element array.
**Rationale**: A bare scalar such as `1.25` or `true` is not a JSON document that every decoder accepts; wrapping it in an array makes every value decodable the same way.
**Approved**: pending

**Decision**: A stored string that no longer decodes reads as absent rather than throwing.
**Rationale**: An enum can lose a case between releases; reading absent lets the layer above fall back to its own value instead of crashing the pane.
**Approved**: pending

**Decision**: A separate index entry lists the names the provider has written.
**Rationale**: The pane state store cannot enumerate its keys, so without the index `keys(withPrefix:)` and clearing a family of overrides would stop working after a relaunch; the relaunch test records this.
**Approved**: pending

**Decision**: `keys(withPrefix:)` filters by a shallow well-formedness check (a one-element JSON array), not by the element type.
**Rationale**: Only a typed caller knows the element type; the source comment records that `contains` and `keys` can still differ for a value of the wrong element type.
**Approved**: pending

**Decision**: `remove` publishes only when something was stored, while `set` always publishes.
**Rationale**: A remove of nothing changes no reader's answer; the test for publishing records the first remove as silent. A set is treated as a change without comparing to the old value.
**Approved**: pending

**Decision**: A corrupt or missing index reads as empty, and the next `set` rewrites it with only the new name.
**Rationale**: The source never raises on a bad index. The cost is that names the corrupt index held stop appearing in `keys(withPrefix:)` although their values remain; the source accepts this rather than scanning the store.
**Approved**: pending

**Decision**: Encoding failure trips `assertionFailure` and stores nothing.
**Rationale**: A value that cannot encode is a programming error found in debug builds; release builds skip the write silently so a bad value cannot corrupt stored state.
**Approved**: pending

