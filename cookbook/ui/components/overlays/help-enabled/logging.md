
Subsystem: none (browser console) | Category: HelpEnabled

| Event | Level | Message |
|-------|-------|---------|
| Missing help entry | warn | `[HelpEnabled] no help entry for id "<id>" — rendering plain text` |

Emitted once per missing `id` for the lifetime of the page (see **warns-on-missing-entry**); never emitted when a `fallback` is supplied (see **suppresses-warning-when-fallback-given**). The record of warned ids is a module-level `Set`, so a page reload or hot module replacement resets it.

