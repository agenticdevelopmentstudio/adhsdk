
**Decision**: Return `null` when the connector registry is unavailable rather than rendering an empty span.
**Rationale**: This gives optional-provider tolerance — the anchor degrades to a no-op when no `ConnectorRegistryProvider` ancestor is mounted, rather than registering into a registry that does not exist.
**Approved**: pending

**Decision**: Registration is side-effect based, performed in a `useEffect`, rather than declarative.
**Rationale**: Matches React's functional component patterns; the DOM ref is only available after mount, so registration must happen in an effect.
**Approved**: pending

**Decision**: The effect's dependency array is `[id, reg]`.
**Rationale**: Causes the previous `id` to be unregistered and the current `id` to be re-registered whenever `id` or the registry instance changes, matching the source implementation.
**Approved**: pending

