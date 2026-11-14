
### Public operations

- **signature**: The state MUST take a string `key`, an `initial` value, a `decode` function from an unknown value to the value type or `undefined`, and an optional `encode` function from the value type to a JSON-serialisable value, and MUST return a two-element pair: the value and a setter.
- **encode-default**: When `encode` is omitted, the state MUST write the value itself as the JSON to store (the identity).
- **setter-shape**: The setter MUST accept either a next value or a function from the previous value to the next value, with the same meaning as the platform's ordinary state setter.
- **boolean-decoder**: The exported `decodeBoolean` MUST return its input when it is a boolean and `undefined` for every other input, including the strings `"true"` and `"false"`, numbers and `null`.

### Initial state and hydration

- **initial-first-render**: On the first render of a mount, the value MUST equal `initial`, regardless of what storage holds, so the first paint matches a render with no storage.
- **hydrate-after-render**: The state MUST read storage after the first render, not during it, so server rendering and first paint agree.
- **hydrate-once-per-key**: The state MUST read storage once per mount and again only when `key` changes.
- **hydrate-decoded**: When storage holds a string under `key`, the state MUST parse it as JSON, pass the parsed value to `decode`, and when `decode` returns anything other than `undefined`, set the value to the result.
- **hydrate-missing-key**: When storage holds no entry under `key`, the state MUST keep its current value.
- **hydrate-unrecognised**: When `decode` returns `undefined`, the state MUST keep its current value.
- **hydrate-bad-json**: When the stored string is not valid JSON, the state MUST keep its current value and MUST NOT throw.
- **hydrate-storage-unavailable**: When reading storage throws (storage blocked or absent), the state MUST keep its current value and MUST NOT throw.
- **hydrate-decode-throws**: When `decode` throws, the state MUST keep its current value and MUST NOT throw, because the read, parse and decode run inside one guarded block.
- **hydrate-no-write**: Hydration MUST NOT write to storage; an entry is written only by the setter.
- **decode-read-once**: The state MUST use the `decode` supplied on the render in which hydration runs and MUST NOT re-hydrate when a caller passes a new inline function on a later render; the source's comment gives the reason: re-hydration would "clobber the reader's choice."

### Setting

- **set-updates-value**: The setter MUST update the in-memory value to the next value (or to the updater's result).
- **set-persists**: The setter MUST write `JSON.stringify` of `encode(next)` to storage under `key` each time it applies a value.
- **set-functional-update**: When given a function, the setter MUST pass it the latest previous value, so several updates in one batch compose instead of overwriting each other.
- **set-persists-same-value**: The setter MUST write to storage even when the next value equals the previous one; it does no equality check.
- **set-write-failure**: When writing storage throws (quota exceeded, storage blocked, or `encode` or `JSON.stringify` throwing), the setter MUST ignore the failure, MUST still apply the in-memory value, and MUST NOT throw; the source comment says "the in-memory choice still applies."
- **set-updater-throws**: When a caller's updater function throws, the state MUST NOT catch the exception, because the updater runs outside the guarded block; the host state machinery decides where it surfaces.
- **set-write-in-updater**: The storage write MUST happen inside the state update function, so it runs once for each application of that update; the environment MAY apply an update more than once for the same input, and each application writes the same string.
- **set-key-bound**: The setter MUST write to the `key` of the render that produced it; its identity MUST stay stable across renders while `key` is unchanged, and MUST change when `key` changes.
- **set-encode-captured**: The setter MUST use the `encode` supplied on the render that created it and MUST NOT pick up a new `encode` from later renders while `key` is unchanged.

### Key changes

- **key-change-rehydrates**: When `key` changes, the state MUST read storage again under the new key and apply the hydration rules.
- **key-change-keeps-value**: When `key` changes to a key with no usable stored value, the state MAY keep the value it held under the old key rather than reset to `initial`; the source keeps it, and no current caller changes its key, so a port may choose either.

### Ordering, concurrency and scope

- **single-threaded**: All updates MUST apply in the order issued, on the single execution thread.
- **per-instance-state**: Each use MUST hold its own in-memory value; two uses of the same `key` do not observe each other's changes until one of them re-reads storage (a remount or a key change).
- **no-cross-tab-sync**: The state MUST NOT subscribe to storage change events; a write in another tab does not change the value.
- **no-network**: The state MUST NOT make network requests, log, or start timers.
- **client-only**: The state MUST touch storage only on the client; it reads storage only in an effect, which never runs during a server render, so the state can be rendered on the server at `initial`.

