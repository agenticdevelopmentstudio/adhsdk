
**Decision**: Start at `initial` and hydrate from storage in an effect, not during the first render.
**Rationale**: The source's doc comment: it "starts at `initial` on first render and hydrates from storage in an effect, so SSR/first-paint match." Reading storage during render would produce different markup on the server and the client.
**Approved**: pending

**Decision**: The caller supplies `decode`, and it returns `undefined` for anything it does not recognise.
**Rationale**: Doc comment: a value "written by an older build, or hand-edited" must "keep the default rather than rendering a shape the view never expected." The module cannot know the value's shape, so validation belongs to the caller.
**Approved**: pending

**Decision**: `decode` and `encode` are read once and are not dependencies of the hydration effect or the setter.
**Rationale**: Source comment: "a caller passing an inline function must not re-hydrate (and clobber the reader's choice) on every render." The cost is that a later change to `decode` or `encode` is ignored until the key changes.
**Approved**: pending

**Decision**: Storage failures are ignored silently on both read and write.
**Rationale**: Source comments: "localStorage unavailable / bad JSON — keep the default" and "ignore persistence failure — the in-memory choice still applies." A preference that cannot be saved must not break the page. The consequence is that nothing tells the reader or a developer the setting will not survive a reload.
**Approved**: pending

**Decision**: The storage write happens inside the state update function.
**Rationale**: It gives the write access to the resolved next value, including when the caller passes an updater. The write is idempotent, so a repeated application of the update is harmless; the trade-off is a side effect inside what is normally a pure function.
**Approved**: pending

**Decision**: A key change keeps the value held under the old key when the new key has nothing usable.
**Rationale**: Hydration returns early on a missing entry and never resets to `initial`. All current callers use a fixed key per mount, so the behavior is not exercised; a port that supports changing keys should decide whether to reset.
**Approved**: pending

