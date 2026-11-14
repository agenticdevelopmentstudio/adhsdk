
- **Nothing stored** (MUST): `get` returns the default and `contains` is false; no index exists.
- **Stored text is not JSON** (MUST): Reads as absent for `get` and `contains`, and `keys(withPrefix:)` leaves it out; the layer above falls back.
- **Stored text is JSON but not a one-element array** (MUST): `keys(withPrefix:)` leaves the name out; a typed `get` of a one-element array of the wrong element type also reads as absent. The source comment names this the one place `contains` and `keys` can still differ: only a typed caller can tell the element type, so `keys` can list a name that `contains` rejects for a different type.
- **Stored array is empty** (MUST): `get` reads it as absent (the decoded array has no first element) and `contains` is false, while `keys(withPrefix:)` also leaves it out because it requires exactly one element.
- **Stored array has several elements** (MUST): `get` returns the first, while `keys` leaves the name out because it requires exactly one.
- **Empty prefix filter** (MUST): `keys(withPrefix: "")` returns every indexed name that still holds a well-formed value.
- **Prefix with no match** (MUST): returns an empty array.
- **Value that cannot be encoded** (MUST): `set` stores nothing, leaves the index and the existing value alone, publishes nothing, and trips an assertion failure that only fires in debug builds; a release build fails silently.
- **Index text corrupt when setting** (MUST): The index reads as empty, so `set` writes an index holding only the new name; names the corrupt index held are no longer listed by `keys(withPrefix:)`, though their values remain stored and readable by `get`.
- **Name stored outside this provider** (SHOULD NOT rely on): A value written to the store directly under a prefixed key is readable by `get` and `contains` but is not listed by `keys(withPrefix:)` until a `set` through the provider indexes it.
- **Setting named like the index** (MUST): The source does not guard against a setting whose name equals `__keys`; it would share its storage key with the index.
- **Remove with a malformed value** (MUST): The stored text counts as a value, so it is deleted and `changes` publishes the name.
- **Remove of an indexed name whose value was deleted elsewhere** (MUST): The name leaves the index, nothing is published.
- **Same value set twice** (MUST): Each `set` publishes; the source does not compare with the stored value.
- **Concurrent access** (MUST): The type is confined to the main actor, so reads and writes are serialized on the main thread; there is no cross-thread access to define.
- **Network or offline state**: Not applicable: the provider reads and writes only the injected pane state store and performs no network call.
- **Boundary values**: Not applicable: the provider imposes no length or range limit on a value; limits belong to the setting type and the store behind the pane state.

