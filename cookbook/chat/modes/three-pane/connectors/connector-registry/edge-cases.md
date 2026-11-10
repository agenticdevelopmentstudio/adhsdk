
- **Empty registry**: An initial `snapshot().ids()` on a fresh provider MUST return an empty array; `has(id)` and `get(id)` MUST return false and undefined respectively.
- **Unregister with mismatched reference**: If `register("btn1", elA)` is called, then the returned function is stored and later invoked after `register("btn1", elB)` is called with a different element, the function MUST NOT unregister elB (it should only unregister if the current element still matches elA).
- **Subscribe after registry populated**: `subscribe()` only adds the listener to the internal set — it does not call the listener to sync current state. A subscriber added after elements are already registered is called only on subsequent `register()`/`unregister()` calls, never on subscription itself.
- **Unsubscribe during notification**: Listeners are iterated with `Set.forEach`. A listener that unsubscribes itself, or another listener, during a notification pass takes effect immediately: a target listener not yet called in the current pass is skipped for that pass, while a listener already called is unaffected.
- **Null/undefined id or element**: Excluded by the TypeScript signature (`register(id: string, el: HTMLElement)`); these values are not assignable and are not part of the runtime contract.

