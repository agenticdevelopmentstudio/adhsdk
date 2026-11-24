
- **Decision**: A pre-hydration bootstrap script runs synchronously before React hydration so the persisted theme is applied before first paint. The script targets its own parent element to isolate its scope.
  **Rationale**: Prevents the visual jarring of loading in the default theme and then switching.
  **Approved**: pending

- **Decision**: Rendered markdown is stored as source text, not cached as an `AttributedString`; the Apple renderer re-renders on every palette change instead.
  **Rationale**: Re-rendering on palette change is cheap enough that caching adds unnecessary complexity and divergence risk, and this keeps the rendered output synchronized with the active palette.
  **Approved**: pending

- **Decision**: Theme selection is persisted locally — in `localStorage` on web, where the component owns it — and not synchronized to a backend user preference. On Apple, the component holds no theme state at all; the host owns the selection via the injected `palette`.
  **Rationale**: Allows independent theme choices across multiple app instances and respects local-first behavior. A host app can implement backend tracking, or its own persistence, separately if desired.
  **Approved**: pending

- **Decision**: Fetch timeouts are configured per component instance (`timeoutMs`), not globally.
  **Rationale**: Different use cases may require different timeout values (e.g., a quick preview vs. a long-form document), so per-instance configuration maximizes flexibility.
  **Approved**: pending

- **Decision**: If theme persistence fails on web (quota exceeded, permissions denied, private mode), the operation fails silently and the component continues working with the theme in memory for the current session.
  **Rationale**: The user's chosen theme still applies live; a persistence failure isn't fatal to the component's function, so nothing is surfaced to the user and no log event is emitted (see Logging).
  **Approved**: pending

