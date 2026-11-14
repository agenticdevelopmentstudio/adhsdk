
**Decision**: Compute the reading theme palette once at module scope rather than per render.
**Rationale**: The reading theme is static for any given instance of the component and does not depend on props or runtime state, so computing it once at module load time (not in render) avoids redundant theme lookups and `getThemeById()` calls. The theme applies to all instances of the component created in the same session.
**Approved**: pending

**Decision**: Read `source` through a ref (`sourceRef`) inside the fetch effect instead of listing `source` itself as a dependency.
**Rationale**: If `source` is a new object each render (same values, different reference), a naive effect dependency on `source` would re-fetch on every render. `sourceRef` reads the latest `source` value inside the effect while the effect's own dependency list holds only the stable primitive values (slug, route, baseUrl, `endpoints.content`, timeoutMs) — a common React pattern for a "read-only" dependency that should not by itself trigger a re-run.
**Approved**: pending

**Decision**: Share one abort path between unmount and document re-selection.
**Rationale**: Both cases abort the in-flight request through the same per-run `AbortController`. The effect cleanup always aborts the controller and sets `active = false`, whether it runs on unmount or because a dependency changed (a different document, a new `timeoutMs`, or Retry) and a new fetch is about to start; the next effect run then starts with a fresh controller and `active = true`. Shared cleanup logic keeps the implementation simple.
**Approved**: pending

**Decision**: Keep the empty state separate from the error state.
**Rationale**: Empty content (successful fetch, empty body) is distinct from error (failed fetch, network/timeout/server error). This distinction helps users understand whether the paper truly has no content or whether there was a technical problem (recoverable via Retry).
**Approved**: pending

**Decision**: Make `timeoutMs` a prop with a 15s default rather than a fixed constant.
**Rationale**: The 15s default mirrors [adhsdk.ingredient.agentic-developer-hub-sdk.sdk.sources-ui.shared.markdown.markdown-viewer-controller](cookbook:8f2e1c9d-7a4b-4c2e-9d8e-5f6c7d8e9f0a)'s own default timeout. Allowing `timeoutMs` as a prop enables callers to adjust based on network conditions or use-case SLAs without modifying the component.
**Approved**: pending

**Decision**: The reading theme is fixed to `DEFAULT_THEME_ID` at module scope; hosts cannot inject a theme, and the component does not follow light/dark or contrast preferences.
**Rationale**: The source has no theme prop, and the default matches the research surface's reading palette. This is a deliberate limitation, not a goal; a host that needs another theme would need an injected-theme prop that the source does not have today.
**Approved**: pending
