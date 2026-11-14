
**Decision**: `add` ignores a duplicate `id` silently instead of throwing or replacing the entry.
**Rationale**: The source comment calls this idempotency. Repeated registration by app setup code is harmless, and the existing account object keeps its live state and observer.
**Approved**: pending

**Decision**: Accounts are matched by `id` string, not object identity.
**Rationale**: `remove(id:)` takes a string, so a caller needs no reference to the account. `add` uses the same key to stay consistent.
**Approved**: pending

**Decision**: `onChange` is a single closure slot with no payload, not a list of observers.
**Rationale**: One observer is the expected case, matching the single-slot design of `Account.onChange`. A later assignment replaces the earlier observer, and the observer re-reads `accounts`.
**Approved**: pending

**Decision**: `remove` does not sign the account out or release its observer.
**Rationale**: The registry only lists accounts. Teardown belongs to the account and its UI. The registry has no teardown hook.
**Approved**: pending

**Decision**: The initializer accepts duplicate ids without de-duplicating.
**Rationale**: Only `add` has the idempotency guard in source. The initializer assigns the array directly. The inconsistency with `add` is unresolved: a port keeps this difference for now so existing app setup behaves the same, and the approval is still pending because the owner may prefer to make the initializer enforce unique ids.
**Approved**: pending

**Decision**: A duplicate add and an unknown remove are deliberate silent no-ops, and the operations return `Void` rather than a `Bool`.
**Rationale**: Repeated registration from app setup code is harmless, so a no-op is the safe outcome. A caller can still tell a real change from a no-op because `onChange` fires only for a real change. The `explicit-error-handling` check stays `partial` because nothing is logged.
**Approved**: pending
