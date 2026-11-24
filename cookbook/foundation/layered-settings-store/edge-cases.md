
- **Empty prefix**: `removeAllOverrides(withPrefix: "")` removes every override name the overrides list for the empty prefix; the store adds no guard, so what that covers is the overrides provider's `keys(withPrefix:)` answer.
- **No matching names**: `removeAllOverrides(withPrefix:)` with a prefix that lists no names MUST do nothing.
- **Secure key and `removeOverride`**: `removeOverride(_:)` on a secure key is `remove(_:)`, which routes a secure key to the fallback, so it deletes the fallback's secret; it does not report an override because `hasOverride` is false for secure keys. This is a known hazard of the current behavior, not an intended feature; a caller MUST NOT use `removeOverride` as a harmless no-op on a secure key.
- **Secure key and prefix removal**: Secure values are never enumerated, so `removeAllOverrides(withPrefix:)` never touches a secure key.
- **Fallback changed under an override**: A fallback change to a key the overrides hold is dropped from `changes`, and the store's reads keep answering the override.
- **Override removed after a hidden change**: After the override is removed, the next `get` shows the fallback's current value; the hidden change was never published, but the removal publishes the key name through the overrides provider (when it publishes the removal, as the `SettingsStorageProvider` contract says), so observers re-read it.
- **Prefix collision in the probe**: The probe lists names for the changed name as a prefix and then requires an exact match, so an override named `browser.page_zoom_extra` does not hide a fallback change to `browser.page_zoom`.
- **Released store**: Once the layered provider is gone, fallback changes pass through unfiltered (`changes-released-store`).
- **Concurrent access**: Every type is `@MainActor`, so the compiler confines calls to the main actor and serialises them; there is no concurrent mutation.
- **Error states**: The store has no throwing operations and no error path; failures belong to the injected providers.
- **Offline or disconnected state**: Not applicable: the store makes no network calls; durability and availability are whatever the overrides provider and the fallback store provide.
- **Boundary values**: Not applicable: the store imposes no limits on key names or values; those belong to the injected providers.

