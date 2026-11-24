
**Decision**: Secure keys bypass the overrides and go straight to the fallback.
**Rationale**: A secret has one home, and a per-pane copy would be a second place to leak it from. As a consequence `hasOverride` is always false for a secure key.
**Approved**: pending

**Decision**: Writes always land in the overrides; the fallback is never written from this layer for a non-secure key.
**Rationale**: The narrower scope must not change the broader scope's values. The cost is that a caller wanting to change the global value must use the fallback store directly.
**Approved**: pending

**Decision**: `contains` answers whether the layer holds an override, not whether a value is readable.
**Rationale**: An override is held by this layer and the fallback's values are inherited, not held. `hasOverride` and any reset-to-default behavior rely on that distinction.
**Approved**: pending

**Decision**: Fallback changes are filtered with an exact-name probe through `keys(withPrefix:)` rather than `contains`.
**Rationale**: The filter has only a name, not a typed key. Asking the overrides for the keys that start with that exact name works even for a provider that cannot enumerate, and it avoids needing a value type. The Swift implementation does this through `keys(withPrefix:)` and checks the result for the name.
**Approved**: pending

**Decision**: The secure forwarding provider publishes nothing from `changes`.
**Rationale**: The base store merges the two providers' `changes`, and the layered provider already relays every fallback change, secure ones included; relaying in both places would publish each change twice and would skip the override filter.
**Approved**: pending

**Decision**: Removal by prefix removes through a private `NamedSetting` key typed as `Bool`.
**Rationale**: Providers remove by name, so the value type is irrelevant; in the Swift implementation a private by-name key exists only to carry a name from `keys(withPrefix:)` back into `remove`.
**Approved**: pending

**Decision**: `removeOverride` is an alias of `remove` and does not check `isSecure`. This records current behavior and a known defect, not a reasoned design.
**Rationale**: `removeOverride` was written as a name for `remove`, and nothing guards the secure case. It means `removeOverride` on a secure key removes the fallback's secret; callers must pass only non-secure keys until the store makes it a no-op or an error.
**Approved**: pending

