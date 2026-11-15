
### Public operation

- **signature**: Source Filter MUST take one argument, the storage key under which the selection is kept, and MUST return an object with exactly two fields: `sources` (the set of selected sources) and a toggle operation that takes one source and returns nothing.
- **source-type**: The toggle operation's parameter MUST be one of the eight fixed source values. The type signature is the caller precondition. Source Filter does no runtime membership check.
- **toggle-identity-unstable**: The toggle operation MUST be a new function value each time Source Filter is used, because the source does not give it a stable identity. A consumer that lists it in a dependency list re-runs every time.
- **sources-immutability**: Each toggle MUST produce a new set instance and MUST NOT mutate the previous one, so a consumer that compares `sources` by reference sees every change.

### Initial state

- **default-all-selected**: On the first use of each mount, `sources` MUST contain every one of the eight fixed sources, in their defined order, until a stored selection is restored.
- **seed-decoupled**: The seeded set MUST be a copy of the fixed source list. Mutating it MUST NOT alter the fixed source list, and the reverse also holds.

### Toggle

- **toggle-flip**: The toggle operation MUST remove a source from the selection when it is present and add it when it is absent.
- **toggle-order**: A source added by the toggle operation MUST come after the existing members in the set's iteration order.
- **toggle-may-empty**: The toggle operation MUST allow the selection to become empty. There is no minimum of one selected source.
- **toggle-functional-update**: The toggle operation MUST derive the next selection from the latest state, so several toggles in one batch of updates compose instead of overwriting each other.
- **toggle-no-error**: The toggle operation MUST NOT throw and MUST NOT return a value. A storage failure is swallowed (see write-failure-ignored).

### Ordering, concurrency and scope

- **single-threaded**: All state updates run on a single execution thread, so toggles cannot interleave. Updates apply in the order they are issued.
- **updater-pure**: The set computation MUST build the next set from the previous one without mutating it. The environment MAY apply the update more than once for the same input, and each application returns an equivalent set and writes the same stored value.
- **per-instance-state**: Each use MUST hold its own selection. A toggle in one use MUST NOT change another concurrent use, unless both use the same storage key.
- **persisted-per-key**: The selection MUST be persisted as a JSON array of its members, in iteration order, in browser local storage under the storage key the caller passes. Each filtered pane passes its own key, so each pane's choice survives a reload.
- **deferred-hydration**: The first render MUST show the default all-selected set. After that render, Source Filter MUST read the stored value once per key and, when it decodes, replace the selection with it, so a server render and the first paint match.
- **decode-known-sources**: When hydrating, Source Filter MUST accept only a JSON array and MUST keep only the members that are known source values, dropping any other entry. A stored value that is not an array MUST be ignored and the default kept.
- **read-failure-keeps-default**: When the storage read throws or the stored value is not valid JSON, Source Filter MUST keep the default selection and MUST NOT propagate the error.
- **write-failure-ignored**: When the storage write throws, the toggle MUST still apply the new in-memory selection and MUST NOT propagate the error.
- **no-side-effects**: Source Filter MUST NOT make network requests, log, start timers, or subscribe to anything. Its only storage access is one read per key and one write per toggle.
- **client-only**: Source Filter MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

