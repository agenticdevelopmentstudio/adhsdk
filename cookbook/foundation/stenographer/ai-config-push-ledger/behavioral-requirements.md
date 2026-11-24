
- **key-namespace**: Each ledger MUST read and write only the `UserDefaults` entry named by its `key`, so two ledgers with different keys never see each other's ids.
- **defaults-injection**: The initializer MUST take the `UserDefaults` store as a parameter defaulting to the standard store.
- **last-pushed-read**: `lastPushed()` MUST return the set of UUIDs stored under the key by the last recorded push.
- **last-pushed-empty**: `lastPushed()` MUST return an empty set when nothing is stored under the key.
- **last-pushed-skips-malformed**: `lastPushed()` MUST skip any stored string that is not a valid UUID and return the rest.
- **removed-difference**: `removed(configured:)` MUST return the ids in `lastPushed()` that are not in `configured`.
- **removed-order**: `removed(configured:)` MUST return its ids sorted ascending by their `uuidString`.
- **configured-means-held**: The `configured` argument is every configuration the host holds now, resolvable or not; a configuration that is configured but unresolvable this time MUST NOT be returned as removed.
- **first-push-removes-nothing**: With an empty ledger, `removed(configured:)` MUST return an empty array.
- **record-landed-union**: `recordLanded(_:)` MUST store the union of the ids in `sync.configs` and the previously pushed ids that the sync did not remove.
- **record-landed-removals**: `recordLanded(_:)` MUST drop every id listed in `sync.removedConfigIds` from the previously pushed ids; a nil `removedConfigIds` drops nothing.
- **record-landed-configs-win**: An id that appears in both `sync.configs` and `sync.removedConfigIds` MUST be stored, because `sync.configs` is always recorded.
- **record-landed-keeps-unresolved**: A previously pushed id that is absent from `sync.configs` and not in `removedConfigIds` MUST remain in the ledger.
- **record-landed-format**: `recordLanded(_:)` MUST store the ids as UUID strings sorted ascending, replacing the whole entry under the key.
- **record-only-landed**: The ledger MUST be updated only by an explicit `recordLanded(_:)` call; `removed(configured:)` and `lastPushed()` MUST NOT write.
- **caller-records-after-landing**: Callers MUST call `recordLanded(_:)` only for a push the daemon accepted; the type has no knowledge of delivery.
- **caller-serialises**: Callers MUST NOT call `recordLanded(_:)` concurrently on one key, because it reads then writes the entry with no lock.

