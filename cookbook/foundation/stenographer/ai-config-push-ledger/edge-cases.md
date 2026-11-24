
- **Null / empty input**: An unset key, or an empty `configured` list over an empty ledger, yields empty results. A nil `removedConfigIds` removes nothing from the ledger.
- **Boundary values**: Not applicable: the ledger holds no numeric limits; its size is the number of configuration ids pushed.
- **Concurrent access**: `recordLanded(_:)` is a read-then-write over `UserDefaults` with no lock, so two concurrent records on one key could lose an update. The type is declared `Sendable` and `UserDefaults` is documented thread-safe, but that covers each call, not the pair. Callers serialise, and the one caller does so through a push engine with a single in-flight push (`SettingsSnapshotPush`).
- **Error states**: A stored value that is not an array of strings reads as empty. Malformed strings are skipped without a signal; the ledger throws and logs nothing. A failed write to `UserDefaults` cannot be observed. A corrupt or non-array entry therefore reads as an empty ledger: the next push names no removals, so configurations it dropped stay behind in the daemon, and the next `recordLanded(_:)` rewrites the entry without the malformed ids.
- **Offline / disconnected state**: Not applicable: the ledger touches only local `UserDefaults`. A push that did not land is simply never recorded, so its ids stay out of the ledger.
- **Caller facts**: The one caller in source records only when its send reports the push landed, and sends through a push engine that holds one push in flight at a time.
- **Id in both lists**: An id in both `sync.configs` and `sync.removedConfigIds` stays in the ledger (see `record-landed-configs-win`).
- **Unresolvable configuration**: A configuration still held but not resolved is neither removed nor forgotten: it stays in the ledger and is not listed as removed.

