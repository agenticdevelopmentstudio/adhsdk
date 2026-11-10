
Subsystem: none (browser console) | Category: HelpEnabled

| Event | Level | Message |
|-------|-------|---------|
| Missing help entry | warn | `[HelpEnabled] no help entry for id "<id>" — rendering plain text` |

Emitted once per missing `id` per session (see **warns-on-missing-entry**); never emitted when a `fallback` is supplied (see **suppresses-warning-when-fallback-given**).

