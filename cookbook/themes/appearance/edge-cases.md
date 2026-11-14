
- **Non-object stored value**: a stored JSON string, number or array is normalized to a copy of the defaults with no field accepted. `readStoredAppearance` MUST NOT throw.
- **Partial stored object**: a stored object with only some fields keeps the defaults for the missing ones. MUST.
- **Out-of-range enum value**: an unrecognized string for any enum preference falls back to that field's default in `normalizeAppearance`. MUST. The pre-paint script writes it unchanged until the store re-applies normalized preferences (see `prepaint-no-validation`).
- **Wrong type for a boolean**: a string, number or `null` for `focusOutlines` or `underlineLinks` leaves it `false`. MUST.
- **Server-side rendering**: with no `window`, read returns defaults and write and clear do nothing. MUST.
- **Storage blocked, private mode or quota exceeded**: read returns the defaults; write and clear are silent no-ops. MUST. Nothing is logged and the caller receives no signal, so a preference that failed to cache is lost on reload.
- **Stored literal `null`**: `readStoredAppearance` returns the defaults. The pre-paint script throws inside its own try/catch and applies nothing. MUST.
- **Corrupt JSON**: read returns the defaults; the pre-paint script applies nothing. MUST.
- **Concurrent access**: all calls are synchronous on one thread, so they cannot interleave. Two browser tabs share one `localStorage` key and the last write wins; this module has no cross-tab synchronization. This is a fact about the source, not a requirement.
- **Offline or disconnected**: not applicable; the module makes no network requests.
- **Element reuse across routes**: `clearAppearance` MUST restore the element exactly, so a site that wears preferences on only some routes does not leak them onto others.
- **Unrelated element state**: `applyAppearance` and `clearAppearance` MUST NOT touch classes other than `dark` or attributes other than the ones named above.

