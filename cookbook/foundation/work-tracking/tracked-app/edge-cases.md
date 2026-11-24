
- **Empty preferences**: With `WorkTrackingPreferences.default` (no added, no removed ids), the allowlist MUST equal the sorted defaults.
- **Empty bundle id**: The initializer does not validate ids. An empty string in `addedBundleIds` becomes an entry whose bundle id and name are both empty; `WorkTrackingPreferences.normalized()` de-duplicates and sorts ids but does not drop empty ones.
- **Unknown removed id**: A removed id that matches no default MUST have no effect.
- **Case sensitivity**: Bundle ids compare case-sensitively; `com.apple.dt.xcode` is not Xcode.
- **Duplicate ids in the injected defaults**: Both entries stay in `apps`; the lookup table is built from the sorted list and keeps the first in that order, so `isAllowed` and `app(for:)` see one id. The default list is checked unique by a test, so this arises only with a caller-supplied `defaults`.
- **Equal names**: Two apps with the same `name` are ordered by `bundleId`, so the order is total and deterministic. The added ids come from a `Set`, but the final sort removes any dependence on its iteration order.
- **Null input**: Not applicable: no parameter is optional; the types are non-optional `String` and a value type.
- **Boundary values**: Not applicable: there are no numeric inputs; `retentionDays` on the preferences is not read here.
- **Concurrent access**: `AppAllowlist`, `TrackedApp` and `PathResolverKind` are `Sendable` value types with only immutable stored properties, so concurrent reads are safe and nothing is serialised.
- **Error states**: Not applicable: neither initializer nor queries throw or return an error.
- **Offline or disconnected state**: Not applicable: the code uses no network.

