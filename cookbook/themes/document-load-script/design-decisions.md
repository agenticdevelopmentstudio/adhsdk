
**Decision**: Render the script only when the server snapshot is in use (server render and hydration), and render `null` on a fresh client mount.
**Rationale**: The source comment explains that a script element created by a client mount never executes and makes React log "Encountered a script tag while rendering React component"; the pre-paint job only works in the document the server sent.
**Approved**: pending

**Decision**: Use `useSyncExternalStore` with a no-op subscription instead of `useEffect` and state.
**Rationale**: Inferred from the source: its server snapshot is used for hydration, so the hydrated node matches the server HTML, while the client snapshot makes a fresh mount render nothing, and no effect or state is needed. An effect-and-state version would render the script on the first client render and then remove it.
**Approved**: pending

**Decision**: Insert `code` as raw HTML with no sanitising, and require trusted, static code.
**Rationale**: The source comment states "Trusted, static code only"; the callers pass constants and generated pre-paint scripts, and escaping would change the script text the browser runs.
**Approved**: pending

**Decision**: Leave the client-side half of the job to another module.
**Rationale**: The source comment says it belongs to whoever runs then, and names `AppearanceScope` for the appearance preferences; this component owns only the document-load half.
**Approved**: pending

