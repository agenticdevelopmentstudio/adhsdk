
Subsystem: the hub client's own reverse-DNS identifier (`KeychainHelper.service`'s fallback literal) | Category: `Keychain`

| Event | Level | Message |
|-------|-------|---------|
| `KeychainHelper.set` fails (`status != errSecSuccess`) | error | `Keychain set failed for '<key>': <OSStatus>` — key name and status only, never the value being stored. |
| `KeychainHelper.get` fails for a reason other than "not found" (`status != errSecSuccess && status != errSecItemNotFound`) | error | `Keychain get failed for '<key>': <OSStatus>` — key name and status only, never any value. |

No other file under `Sources/Auth/` logs anything; `errSecItemNotFound` is treated as a normal, unlogged outcome in both `get` and `exists`.

