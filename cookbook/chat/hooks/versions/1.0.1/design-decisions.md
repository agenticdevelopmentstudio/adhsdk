
**Decision**: `useChatSession` lands, rather than abandons, every in-flight `say`/`sayStream` line in a final unmount-only effect.
**Rationale**: source comments document that an `await`ing caller must still see its promise resolve after teardown — particularly under React Strict Mode's mount→cleanup→mount cycle — rather than hang forever waiting on a line whose owning component is already gone.
**Approved**: pending

**Decision**: `destroyBackend()` calls `destroy()` on the wrapped backend (the `ChatBackendAdapter` instance, when one was created), never directly on the raw backend passed in as an option.
**Rationale**: source comments explain that destroying the raw backend directly was a prior bug — it skipped the adapter's own teardown of its `AbortController` and event queue, leaking one adapter/loop per mount cycle.
**Approved**: pending

**Decision**: `useChatSession` builds its internal session object exactly once (`sessionRef.current === null` guard) and never rebuilds it when `backend`/`orchestrator` identity changes across renders.
**Rationale**: source comments explain that an inline `new MockBackend()` literal in a demo render would otherwise reset the whole conversation on every render.
**Approved**: pending

**Decision**: `useRotatingPhrase` performs its first roll in a mount-only effect but re-rolls synchronously during render on a `rerollKey` change (React's "adjust state during render" pattern), instead of doing both rolls in effects.
**Rationale**: the source's own comment states the initial pick happens on mount "so server and client agree on the first frame," while later key changes re-roll during render "so the new phrase lands in the same paint as its trigger, with no one-frame lag from an effect."
**Approved**: pending

**Decision**: `useConnectRitual` re-arms its `alive` flag at the start of every effect run rather than setting it once forever at initial mount.
**Rationale**: this makes the ritual safe under React Strict Mode's deliberate double-invoke without disabling that check — a stale first mount's `alive` flag is correctly left `false` after its cleanup runs, while the second, genuine mount re-arms its own flag and completes the ritual normally.
**Approved**: pending

**Decision**: `useBlockCursor` only updates its caret-box state when the newly measured box differs from the previous one in position or size, otherwise keeping the exact same object reference.
**Rationale**: the underlying `useCaretTracker` measurement is coalesced to one `requestAnimationFrame` per relevant DOM event, but an unchanged caret position (e.g., a `selectionchange` that doesn't actually move the caret) would otherwise still produce a new object and re-render every consumer on every such event.
**Approved**: pending

**Decision**: `useAllImagesLoaded` treats a watched image's `onerror` identically to its `onload` — both mark that source "loaded."
**Rationale**: a broken image `src` is a terminal outcome, not a pending one; treating it the same as a successful load prevents whatever gate depends on "all images loaded" (e.g., an initial-render reveal) from waiting forever on an image that will never fire `onload`.
**Approved**: pending

**Decision**: `useMouseGaze` never itself decides whether to defer to a caret-driven gaze source; `usePersonaGaze` composes `useMouseGaze` and `useCaretGaze` and performs that arbitration one level up.
**Rationale**: keeps `useMouseGaze` a single-source, independently reusable and testable hook; the mutual-exclusion policy (mouse silenced while engaged, caret gated while disengaged) only makes sense to a caller that already knows about both sources.
**Approved**: pending

