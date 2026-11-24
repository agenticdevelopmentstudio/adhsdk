
- **Null / empty input**: Nothing saved loads as an empty list (MUST); saving an empty list removes the item (MUST). A nil access group omits the attribute and the keychain uses the app's default group (MUST).
- **Boundary values**: Pairs are stored as given; the store does not trim, deduplicate, order or limit them, and a pair with an empty alias or real is stored like any other.
- **Concurrent access**: The type is a `Sendable` value with no lock or queue. Two `save` calls interleaving can each delete and then add, in which case the add of the second can find the item already added by the first and surface `StoreError.keychain` with the duplicate-item status; the keychain, not this type, serialises each call, and callers should serialise saves (SHOULD). `PrivacyWordsVault` is the caller that owns that ordering.
- **Error states**: Every failure is thrown, never swallowed: locked or interaction-denied reads become `needsAuthentication`, other keychain statuses become `keychain`, bad data becomes `unreadable`, authentication refusals become `authenticationFailed` (MUST).
- **Save is not atomic**: `save` deletes the old item before adding the new one, so when the add or the JSON encoding then fails the old words are already gone and the error is thrown; this is a fact of the implementation (MUST describe), not a rollback.
- **Locked Mac**: Because the item is `WhenUnlockedThisDeviceOnly`, a read while the Mac is locked is a keychain read that `load` maps by status: `errSecInteractionNotAllowed` and `errSecAuthFailed` throw `needsAuthentication`, and any other failing status throws `keychain` with that status.
- **Authentication cancelled**: A cancel in the system sheet throws `authenticationFailed` with the system's message (MUST); there is no separate cancelled case.
- **Offline / disconnected state**: Not applicable: the store performs no network access and the item is never synchronizable.
- **Timeouts**: Not applicable: calls are local keychain operations with no timeout of their own; `authenticate` waits as long as the user takes.

