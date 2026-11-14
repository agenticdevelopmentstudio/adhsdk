
- **provide-context**: The registry MUST be established by a scoped provider that exposes it to descendant views in a subtree, so independent registries can coexist without global state. On the source platform this is `ConnectorRegistryProvider`, backed by React Context (see Platform Notes).
- **register-elements**: The registry MUST accept registration of a platform view handle (an `HTMLElement` on the source web platform) under a unique string identifier via a `register(id, element)` operation.
- **unregister-function**: `register()` MUST return a function that unregisters the element when called.
- **idempotent-reregister**: If an element is registered again under an id it already holds, with the identical element reference, `register()` MUST return a no-op unregister function and MUST NOT notify subscribers.
- **replace-on-conflict**: If an element is registered again under an id it already holds, but with a *different* element reference, the registry MUST replace the stored element and notify subscribers as an ordinary change.
- **update-registry-on-change**: Registering or unregistering an element MUST notify all active subscribers immediately (synchronously, before the call returns).
- **provide-snapshot**: The registry MUST provide a `snapshot()` operation that returns a current `RegistrySnapshot` object containing the full registry state.
- **stable-snapshot-identity**: `snapshot()` MUST return the same `RegistrySnapshot` object reference on repeated calls as long as no registration or unregistration has occurred in between, so a reactive binding (e.g. `useSyncExternalStore` on the source platform) can treat an unchanged snapshot as identical and skip re-rendering.
- **implement-subscription**: The registry MUST support subscription to changes via a `subscribe(listener)` operation, which MUST return an unsubscribe function.
- **expose-has-method**: A `RegistrySnapshot` MUST provide a `has(id)` method that returns a boolean indicating whether an id exists in the registry.
- **expose-get-method**: A `RegistrySnapshot` MUST provide a `get(id)` method that returns the registered element or `undefined` if the id is not present.
- **expose-ids-method**: A `RegistrySnapshot` MUST provide an `ids()` method that returns an array of all registered identifiers in the registry.
- **throw-without-provider**: Accessing the registry handle outside the scope of a provider MUST raise an error identifying the missing provider. On the source platform, `useConnectorRegistry()` throws (see Platform Notes).
- **provide-optional-hook**: The registry MUST also be accessible through an optional accessor that returns the registry handle when a provider is in scope and `null` otherwise, for call sites that must tolerate running without one. On the source platform this is `useConnectorRegistryOptional()`.
- **provide-snapshot-hook**: The registry MUST provide a reactive accessor that returns the current snapshot and automatically subscribes to updates, re-rendering/re-evaluating the consumer on registry changes; because it depends on the provider being in scope, it MUST also raise the same missing-provider error as **throw-without-provider**. On the source platform this is `useRegistrySnapshot()`, which composes `useConnectorRegistry()`.

