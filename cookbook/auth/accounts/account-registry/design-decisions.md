
**Decision**: `add` ignores a duplicate `id` silently instead of throwing or replacing the entry.
**Rationale**: The source comment calls this idempotency. Repeated registration by app setup code is harmless, and the existing account object keeps its live state and observer.
**Approved**: pending

**Decision**: Accounts are matched by `id` string, not object identity.
**Rationale**: `remove(id:)` takes a string, so a caller needs no reference to the account. `add` uses the same key to stay consistent.
**Approved**: pending

**Decision**: `onChange` is a single closure slot with no payload, not a list of observers.
**Rationale**: The accounts panel is the one observer, matching the single-slot design of `Account.onChange`. A later assignment replaces the earlier observer, and the observer re-reads `accounts`.
**Approved**: pending

**Decision**: `remove` does not sign the account out or release its observer.
**Rationale**: The registry only lists accounts. Teardown belongs to the account and its UI. The source comment says add and remove exist so plus and minus can be enabled later without touching `Account`, and the registry has no teardown hook.
**Approved**: pending

**Decision**: The initializer accepts duplicate ids without de-duplicating.
**Rationale**: Only `add` has the idempotency guard in source. The initializer assigns the array directly. A port keeps this difference rather than tightening it, so existing app setup behaves the same.
**Approved**: pending

