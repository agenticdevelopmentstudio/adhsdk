
- **Null/undefined id**: Component enters idle state; no fetch is triggered. MUST not error.
- **id changes during in-flight fetch**: The previous fetch's `AbortSignal` MUST be aborted. With the default native-fetch fetcher (which rejects on abort), this means its response is ignored and only the new `id`'s fetch determines the resulting state (see **abort-on-id-change**). Exception: if the stale fetch had already timed out before `id` changed, its signal is already aborted with the timeout reason, and the cleanup's second `abort()` call cannot change that reason — a fetcher that ignores `AbortSignal` can therefore still deliver the stale id's late success or error and overwrite the new id's state instead of being suppressed.
- **Stale theme ID in storage (web)**: If stored theme ID is no longer in the valid registry, MUST fall back to the default theme without error.
- **Storage quota exceeded or unavailable (web)**: Theme selection still works live; persistence just fails silently. User's session theme remains active until app restart.
- **CSP blocks bootstrap script (web)**: No-flash protection is disabled; SSR paint uses default theme, then hydration applies persisted theme (visible flash). Component still functions.
- **Fetch timeout with no timeout configured**: Uses default timeout (15000ms).
- **Very large markdown content**: Component renders all content; SHOULD NOT paginate or truncate.
- **Markdown with deeply nested lists or tables**: MUST render all nesting levels.
- **Empty string title**: Toolbar displays empty title (no text, but toolbar remains present).
- **Network error with no message**: MUST show error state with a generic error message (e.g., "Failed to load document").

