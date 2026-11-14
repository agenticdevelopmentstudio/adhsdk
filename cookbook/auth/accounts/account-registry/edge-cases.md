
- **Duplicate id on add**: The call is ignored, the existing entry is kept and no change is reported. MUST (per `add-idempotent`).
- **Unknown id on remove**: The call is a no-op with no change reported. MUST (per `remove-unknown-noop`).
- **Empty string id**: The registry applies no validation, so `""` is an ordinary id. A second `add` with `""` is ignored as a duplicate. The `Account` protocol documents no id format.
- **Duplicates in the initializer**: The initializer does not de-duplicate, so both entries are kept. `remove(id:)` removes only the first match, and a second call removes the next. MUST (per `init-stores-as-given`).
- **Remove while observed**: A removed account keeps its own `onChange` slot, and its observer is not told. The accounts UI has to drop its observer itself. MUST NOT clear it from the registry.
- **Re-entrant onChange**: An `onChange` that calls `add` or `remove` runs the nested call immediately, which can invoke `onChange` again. The registry has no limit, so a closure that always adds a new account would not terminate. This is a caller concern.
- **Concurrent access**: Not applicable as a race. The class is `@MainActor`, so the compiler confines every call to the main actor and serialises it.
- **Boundary sizes**: An empty registry is valid. Nothing caps the entry count.
- **Error states and offline**: Not applicable. The registry performs no I/O, so there is no dependency to fail and no network state to lose.
- **Cancellation and timeouts**: Not applicable. Both operations are synchronous and finish before returning.

