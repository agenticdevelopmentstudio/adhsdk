
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `service` (of the secret store; also a per-call argument on `set`, `get`, `read`, `delete` and `exists`) | string (mutable, shared) | app's bundle identifier, or `"com.mikefullerton.agenticdeveloperhubsdk"` when none is available | Credential-store service identifier that scopes every query, set, and delete. |
| `accessGroup` (of the secret store) | optional string (mutable, shared) | nothing | Optional shared credential-store access group; when set, forces data-protection-keychain semantics, after-first-unlock-this-device-only accessibility on new writes, and login-keychain recovery in `get`, `exists` and `delete`. |
| `usesDataProtectionKeychain` (of the secret store) | boolean (mutable, shared) | `false` | When true, new writes go to the data-protection keychain with after-first-unlock-this-device-only accessibility, and `get`, `exists` and `delete` also reach the login keychain copy. |
| `legacyServices` (of the secret store) | list of strings (mutable, shared) | empty list | Retired service identifiers `get`/`exists` fall back to, newest-retired-first, for migrating secrets forward. |
| the semantic-version component ceiling | integer constant | `2,147,483,647` | Fixed plausibility bound on `major`/`minor`/`patch`; not caller-configurable. |

The encoding-skip wrapper, the logger factory contract, float clamping, and
text folding take no static or environment configuration — every input
they act on is a per-call argument.

