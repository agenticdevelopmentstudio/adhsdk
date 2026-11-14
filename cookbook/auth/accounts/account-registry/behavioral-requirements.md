
### Data shape

- **accounts-property**: The registry MUST expose `accounts` as a readable array of `any Account`, writable only from inside the registry (`public private(set)`).
- **accounts-order**: `accounts` MUST hold entries in the order they were supplied to the initializer, followed by entries in the order they were added.
- **identity-by-id**: The registry MUST treat two accounts as the same account when their `id` strings are equal. It MUST NOT compare object identity.
- **init-default-empty**: `init(accounts:)` MUST default `accounts` to an empty array.
- **init-stores-as-given**: `init(accounts:)` MUST store the supplied array unchanged, including any duplicate ids it contains.
- **init-silent**: `init(accounts:)` MUST NOT invoke `onChange`.

### Operations

- **add-appends**: `add(_:)` MUST append the account to the end of `accounts` when no existing entry has the same `id`.
- **add-notifies**: `add(_:)` MUST invoke `onChange` exactly once after appending.
- **add-idempotent**: `add(_:)` MUST leave `accounts` unchanged when an entry with the same `id` is already present, and MUST keep the existing entry rather than replace it.
- **add-duplicate-silent**: `add(_:)` MUST NOT invoke `onChange` when it ignores a duplicate.
- **remove-by-id**: `remove(id:)` MUST remove the first entry whose `id` equals the argument and preserve the order of the remaining entries.
- **remove-notifies**: `remove(id:)` MUST invoke `onChange` exactly once after removing.
- **remove-unknown-noop**: `remove(id:)` MUST leave `accounts` unchanged and MUST NOT invoke `onChange` when no entry has that `id`.
- **remove-no-teardown**: `remove(id:)` MUST NOT call `signOut()`, `restore()` or any other method on the removed account, and MUST NOT clear that account's `onChange`.
- **no-error-surface**: Neither operation MUST throw or return a value; both are declared without `throws` and return `Void`. A duplicate add and an unknown remove are reported to the caller only by the absence of an `onChange` call.

### Change notification

- **on-change-slot**: `onChange` MUST be a single closure slot of type `@MainActor () -> Void`, defaulting to an empty closure. Assigning it again replaces the earlier closure.
- **on-change-no-payload**: `onChange` MUST carry no arguments. Observers read `accounts` to learn what changed.
- **on-change-synchronous**: `onChange` MUST run synchronously inside `add` or `remove`, after `accounts` has been mutated, so the closure observes the new array.
- **on-change-scope**: `onChange` MUST fire only for membership changes made through `add` and `remove`. The registry MUST NOT forward the `onChange` of any contained `Account`; each account has its own slot.

### Concurrency

- **main-actor-isolation**: The class MUST be isolated to `@MainActor`, so every property access and call runs on the main actor and calls are serialised. The class declares no explicit `Sendable` conformance; its `@MainActor` isolation is what keeps it in its domain.
- **no-reentrancy-guard**: The registry has no guard against `onChange` calling `add` or `remove`. A nested call runs synchronously inside the outer one, and the outer call has already finished mutating by then.

### Persistence

- **no-persistence**: The registry MUST keep `accounts` in memory only. It reads and writes no files, keychain or defaults, and the list is rebuilt by the app on each launch.
- **retains-accounts**: The registry holds each account strongly, so a registered account lives at least as long as its entry.

