
**Decision**: The component is async and server-side-only (a React Server Component), with no client-rendering path.
**Rationale**: Trades client-side flexibility (content cannot be chosen dynamically on the client without a server round-trip) for a crawlable, SEO-friendly HTML payload and no client-side "Rendering…" flash.
**Approved**: pending

**Decision**: The `adh-mv-prose` class is always applied to the root; an optional caller-supplied `className` is appended rather than replacing it.
**Rationale**: Guarantees consistent prose styling across every rendering (server and client paths look identical) while still letting a consumer scope additional style overrides.
**Approved**: pending

**Decision**: The shiki highlighter and the frozen unified processor are built once and cached at module scope (see **highlight-code**).
**Rationale**: Avoids redundant highlighter initialization on every request; repeated calls in the same process reuse the same instances.
**Approved**: pending

