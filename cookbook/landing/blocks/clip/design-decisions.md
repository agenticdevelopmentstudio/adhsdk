
**Decision**: The component always sets `muted=true` on the video element.
**Rationale**: Auto-playing video with sound is widely blocked by browsers and disruptive to users; the caller can provide separate UI to unmute if needed, but auto-play without mute is not a viable strategy on the web.
**Approved**: pending

**Decision**: The server-side snapshot of `useSyncExternalStore` returns `false` (motion allowed), so the initial HTML always includes `autoPlay` and `loop` attributes.
**Rationale**: The server has no OS preference to consult, so returning `false` avoids a hydration mismatch. React corrects the attributes on first hydration once the real client value is available.
**Approved**: pending

**Decision**: The component uses a `useEffect` that calls `ref.current?.pause()` whenever `reduced` becomes `true`.
**Rationale**: Setting `autoPlay=false` does not stop playback that has already started, so an imperative pause is required to guarantee the video stops the instant reduced motion is requested.
**Approved**: pending

**Decision**: The component provides no error callbacks or fallback UI for video loading failures.
**Rationale**: Video loading errors are handled by the browser's native error state; leaving error handling to the caller keeps this a small, reusable media component.
**Approved**: pending

