
**Construction**

- **init-parts**: `init(overrides:fallback:)` MUST take a `SettingsStorageProvider` for the overrides and a `SettingsStore` for the fallback, and MUST expose the fallback as the public read-only property `fallback`.
- **init-wiring**: The store MUST be built on the `SettingsStore` base initializer with a layered provider (overrides over fallback) as its non-secure provider and a fallback-forwarding provider as its secure provider.
- **main-actor**: `LayeredSettingsStore` and both private providers MUST be isolated to the main actor.

**Reads**

- **get-override-wins**: For a non-secure key, `get` MUST return the override's value when the overrides contain the key.
- **get-fallback-reads-through**: For a non-secure key, `get` MUST return the fallback's value, `fallback.get(key)`, when the overrides do not contain the key.
- **get-secure-from-fallback**: For a secure key, `get` MUST return `fallback.get(key)` without consulting the overrides.
- **contains-is-override-only**: For a non-secure key, `contains` MUST report only whether the overrides hold the key; a value inherited from the fallback MUST NOT count as contained.
- **contains-secure-from-fallback**: For a secure key, `contains` MUST return `fallback.contains(key)`.

**Writes**

- **set-lands-in-overrides**: For a non-secure key, `set` MUST write to the overrides and MUST NOT write to the fallback.
- **set-secure-to-fallback**: For a secure key, `set` MUST write to the fallback and MUST NOT write to the overrides.
- **remove-from-overrides**: For a non-secure key, `remove` MUST remove the key from the overrides only, so later reads show the fallback's value.
- **remove-secure-from-fallback**: For a secure key, `remove` MUST remove the key from the fallback.

**Override management**

- **has-override**: `hasOverride(_:)` MUST return true only when the key is not secure and the overrides contain it.
- **has-override-secure-false**: `hasOverride(_:)` MUST return false for every secure key, including one whose value is set.
- **remove-override**: `removeOverride(_:)` MUST behave exactly as `remove(_:)`: it drops this layer's value so reads show the fallback's again.
- **remove-all-by-prefix**: `removeAllOverrides(withPrefix:)` MUST remove from the overrides every key name that the overrides list for the prefix through `keys(withPrefix:)`.
- **remove-all-spares-others**: `removeAllOverrides(withPrefix:)` MUST NOT remove an override whose name does not start with the prefix.
- **remove-all-by-name**: `removeAllOverrides(withPrefix:)` MUST remove each listed name through a private by-name key (`NamedSetting`) whose `isSecure` is `false` and whose value type is `Bool`, because providers remove by name and the value type never matters.
- **keys-from-overrides**: `keys(withPrefix:)` MUST list only the names the overrides hold, not the fallback's names, and never a secure key.

**Change publication**

- **changes-override**: `changes` MUST publish the key name of every change the overrides publish.
- **changes-fallback-unshadowed**: `changes` MUST also publish the key name of a fallback change when the overrides do not hold that exact name.
- **changes-fallback-hidden**: `changes` MUST NOT publish a fallback change for a key name the overrides hold.
- **changes-exact-probe**: The overrides-hold test for a fallback change MUST be an exact-name probe, calling `keys(withPrefix:)` with the changed name and checking that the result contains that name, so that a provider that cannot enumerate still answers whether it holds that one name.
- **changes-secure-relayed-once**: A fallback change to a secure key MUST be published exactly once through the layered provider's relay; the secure forwarding provider's `changes` MUST publish nothing, because relaying there too would publish each change twice and would skip the override filter.
- **changes-remove-emits**: Removing an override MUST publish that key name through the overrides' own `changes`; the store adds no publication of its own, so whether a removal publishes is the overrides provider's rule (`SettingsStorageProvider` documents "set or removed"; the pane-state provider publishes on removal only when a value was held).

