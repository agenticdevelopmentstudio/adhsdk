
**Decision**: One set shared by every reader.
**Rationale**: The dashboard routes, the report and the MCP tools read the same caches, so a report and an open tab share one refresh.
**Approved**: pending

**Decision**: Providers refresh separately.
**Rationale**: PostHog, Vercel, GlitchTip and the sites read have their own caches, so one slow provider never holds back another's sections.
**Approved**: pending

**Decision**: Runtime errors read in the request.
**Rationale**: They come from the app's own store, which the monitor cycle fills, so they are cheap and always fresh; the provider sections are the slow ones.
**Approved**: pending

**Decision**: Views memoized by identity.
**Rationale**: A section object is replaced only when a refresh publishes it, so the cheap identity check lets polling clients share one derivation.
**Approved**: pending

**Decision**: Settle separate from read.
**Rationale**: Reading starts the refresh and never waits; a server-side reader that must give a finished answer settles explicitly, so polling is not pushed onto its own client.
**Approved**: pending

