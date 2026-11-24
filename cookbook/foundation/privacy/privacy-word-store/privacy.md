
- **Data collected**: The alias and real word pairs the user typed; the real words name the user, which is why they are guarded.
- **Storage**: One keychain generic-password item, JSON-encoded, in the data-protection keychain, accessible only while unlocked, this device only, never synchronizable, shareable only with the apps in the given access group. No defaults, database or file copy. The item has no expiry; it lives until `save([])` or the user removes it.
- **Transmission**: None; the store performs no network access and the item is excluded from keychain sync.
- **Retention**: Until replaced by `save` or removed with an empty `save`.
- **Sensitive-data handling**: The item is readable by the group's apps without a prompt (deliberate, so a private terminal can conceal output from its first byte); the owner is asked by the app, not the store, before showing, opening or saving. A violation (a refused or failed authentication, or an unreadable value) is reported as a thrown `StoreError`, never partial data.
- **Token lifetime and revocation**: Not applicable: the store handles no token or session; an authenticated `LAContext` is the caller's to keep or discard.

