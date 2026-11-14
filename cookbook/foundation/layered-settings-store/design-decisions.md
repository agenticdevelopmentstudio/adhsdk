
**Decision**: Secure keys bypass the overrides and go straight to the fallback.
**Rationale**: The source comment gives the reason: a secret has one home, and a per-pane copy would be a second place to leak it from. As a consequence `hasOverride` is always false for a secure key.
**Approved**: pending

**Decision**: Writes always land in the overrides; the fallback is never written from this layer for a non-secure key.
**Rationale**: The narrower scope must not change the broader scope's values. The cost is that a caller wanting to change the global value must use the fallback store directly.
**Approved**: pending

**Decision**: `contains` answers whether the layer holds an override, not whether a value is readable.
**Rationale**: The source comment says an override is "contained" and the fallback's values are inherited, not held. `hasOverride` and the pane's reset behavior rely on that distinction.
**Approved**: pending

**Decision**: Fallback changes are filtered with an exact-name probe through `keys(withPrefix:)` rather than `contains`.
**Rationale**: The filter has only a name, not a typed key. The source comment says a provider that cannot enumerate still answers whether it holds this one name. The name-based probe also avoids needing a value type.
**Approved**: pending

**Decision**: The secure forwarding provider publishes nothing from `changes`.
**Rationale**: The source comment explains that the base store merges the two providers' `changes`, and the layered provider already relays every fallback change, secure ones included; relaying in both places would publish each change twice and would skip the override filter.
**Approved**: pending

**Decision**: Removal by prefix removes through a private `NamedSetting` key typed as `Bool`.
**Rationale**: Providers remove by name, so the value type is irrelevant; the key exists only to carry a name from `keys(withPrefix:)` back into `remove`.
**Approved**: pending

**Decision**: `removeOverride` is an alias of `remove` and does not check `isSecure`.
**Rationale**: This is how the source behaves. It means `removeOverride` on a secure key removes the fallback's secret; callers must pass only non-secure keys.
**Approved**: pending

