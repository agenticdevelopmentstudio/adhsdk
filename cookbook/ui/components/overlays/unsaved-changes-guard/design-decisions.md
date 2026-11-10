
- **Decision**: Track the Back-button interposer by the URL a sentinel history entry was pushed for, rather than a boolean "already armed" flag.
  **Rationale**: A long-lived mount (an app shell that outlives many routes) must not stack a second sentinel when re-arming at a URL it has already armed — that would cost the user two Back presses — but must push a fresh one at a URL it has not armed yet.
  **Approved**: pending

- **Decision**: Cap the guard's self-approval window (`approveBriefly`) at 1000ms, matching the registry's `approveNavigation(windowMs = 1000)` default.
  **Rationale**: The window has to stay open long enough to cover the `beforeunload`/`popstate` it is approving (both fire synchronously or near-synchronously), but expire quickly enough that if the navigation turns out to be a client-side `router.push()` with no unload, the page stays mounted, dirty, and re-armed well before the window would matter again. The value is a fixed constant in this component; `approveNavigation()`'s exported `windowMs` parameter lets a caller override it for the save-then-leave case.
  **Approved**: pending

- **Decision**: Multiple guards may be armed at once (e.g. a root layout mounting a settings-panel guard alongside a page-level guard). Only the primary answers `confirmNavigation()`, so one navigation raises exactly one prompt.
  **Rationale**: The prompt is generic ("you have unsaved changes") and Discard means discard everything, so asking every armed guard would ask the same question repeatedly. Non-primary guards still block `beforeunload` (the browser coalesces those into one native prompt), and their click listeners bail once the primary's `preventDefault()` has run. If the primary disarms, the first still-registered guard takes over — registration order (the order each guard's mount effect called `registerNavigationGuard`), never creation or render order — matching **coalesce-multiple-guards**.
  **Approved**: pending

- **Decision**: Attach the click interceptor to `document` in the capture phase rather than to individual anchors.
  **Rationale**: A capture-phase listener runs before the framework router's own click handler, so it can `preventDefault()` first; the anchor's other handlers (menu close-on-select, analytics) still run because the guard never calls `stopPropagation()`. An anchor carrying `GUARDED_NAV_ATTR` is exempt — its own handler is responsible for calling `confirmNavigation()` itself.
  **Approved**: pending

- **Decision**: The confirm resolver returns `true` for Discard and `false` for Stay.
  **Rationale**: This gives both callers of `requestConfirm()` — the popstate handler and whoever awaits `confirmNavigation()` — a single boolean to act on: the popstate handler re-issues `window.history.back()` on `true` or re-pushes the sentinel on `false`.
  **Approved**: pending

