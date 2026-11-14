
**Decision**: Compute the reading theme palette once at module scope rather than per render.
**Rationale**: The reading theme is static for any given instance of the component and does not depend on props or runtime state, so computing it once at module load time (not in render) avoids redundant theme lookups and `getThemeById()` calls. The theme applies to all instances of the component created in the same session.
**Approved**: pending

**Decision**: Read `source` through a ref (`sourceRef`) inside the fetch effect instead of listing `source` itself as a dependency.
**Rationale**: If `source` is a new object each render (same values, different reference), a naive effect dependency on `source` would re-fetch on every render. `sourceRef` reads the latest `source` value inside the effect while the effect's own dependency list holds only the stable primitive values (slug, route, baseUrl, contentTemplate, timeoutMs) — a common React pattern for a "read-only" dependency that should not by itself trigger a re-run.
**Approved**: pending

**Decision**: Share one abort path between unmount and document re-selection.
**Rationale**: Both cases benefit from aborting in-flight requests via the same `AbortController`. An `active` flag distinguishes them: unmount sets `active = false` and drops the result silently; a re-select (different slug/route/baseUrl) triggers a new effect and starts a new fetch. Shared cleanup logic keeps the implementation simple.
**Approved**: pending

**Decision**: Keep the empty state separate from the error state.
**Rationale**: Empty content (successful fetch, empty body) is distinct from error (failed fetch, network/timeout/server error). This distinction helps users understand whether the paper truly has no content or whether there was a technical problem (recoverable via Retry).
**Approved**: pending

**Decision**: Make `timeoutMs` a prop with a 15s default rather than a fixed constant.
**Rationale**: The 15s default mirrors [adhsdk.ingredient.agentic-developer-hub-sdk.sdk.sources-ui.shared.markdown.markdown-viewer-controller](cookbook:8f2e1c9d-7a4b-4c2e-9d8e-5f6c7d8e9f0a)'s own default timeout. Allowing `timeoutMs` as a prop enables callers to adjust based on network conditions or use-case SLAs without modifying the component.
**Approved**: pending

