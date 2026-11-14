
- **Nothing stored**: With no cache entry, `readStoredAppearance` returns the defaults, so the first snapshot is colour mode `auto`. The store MUST accept this (it is the signed-out state).
- **Stored JSON is corrupt or has unknown or wrongly typed fields**: `readStoredAppearance` returns the defaults on a parse error and `normalizeAppearance` drops unrecognised values, so the snapshot is always a complete `AppearancePrefs`. This applies to reads only.
- **A partial or wrongly typed value reaches `set` or `adoptAppearance`**: it is stored and painted as given. The type signature is the only guard, so a caller outside TypeScript is responsible for passing valid values.
- **Reset when never signed in**: `resetAppearance()` on a browser that never signed in changes nothing visible: the defaults replace the defaults and the (absent) cache is cleared. Listeners are still notified.
- **Adopt resolves after the reader left a scoped route**: The prefs are cached and held but not painted (AS-002); the next scope mount paints them (AS-003). The store MUST NOT paint a page that never asked for the prefs.
- **A scope is mounted before any prefs are read**: The mount's snapshot read loads the cache. This is what arms OS following for a site that only mounts a scope (AS-005).
- **Release called twice**: counted once, so the mounted count never drops below the number of live scopes.
- **Boundary, scope count 0 to 1 to 0**: paint on the first mount, clear on the last release. Only the 0 to 1 and 1 to 0 transitions touch `<html>`; a second mount paints nothing new.
- **Concurrent calls**: Not applicable as parallelism: the module runs on the single browser thread, and every commit is a synchronous run of replace, cache, paint and notify. Two commits from separate calls resolve in call order; the last one wins, and a late-resolving `adoptAppearance` overwrites an earlier `set`.
- **Another tab changes the prefs**: The store attaches no `storage` event listener, so a change in another tab reaches this tab only through its next read after a reload. This is an absent feature, not a gap in a stated contract.
- **A listener throws during notification**: The error propagates out of the commit and later listeners are not called; the held prefs, cache and paint have already happened.
- **OS signal unavailable**: With no `matchMedia`, `auto` resolves to light and no OS change is ever observed (os-listener-guards).
- **Offline or server unreachable**: Not applicable: the store makes no network call; the server round-trip belongs to the caller (`AppearanceSync`, which reports a fetch failure and leaves the pre-paint result in place).
- **Storage unavailable**: Private mode or a full quota loses the cache write silently (cache-failure-silent); the page keeps the in-memory prefs until reload.
- **No `document` (server render)**: commits skip the paint (paint-needs-document); `mountAppearanceScope` is not called there because layout effects do not run on the server.

