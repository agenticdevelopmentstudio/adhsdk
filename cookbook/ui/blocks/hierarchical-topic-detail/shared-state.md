
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| Per-level selection | URL path segments (or internal state) | every topic list + the detail pane | URL → view | `selectedId`; `onSelect`/`onClear` write the URL/state |
| Published feature levels | the active feature | the shell's one merged frame | child → shell | `WorkspaceChrome` context (`useWorkspaceLevels` + `useWorkspaceListLevel`) |
| Unsaved-work guard | the leaf editor (`useMasterDetailForm.guard`) | the package's `attemptExit` | child → shell → package | `useWorkspaceExitGuard` → `exitGuard` prop (stable ref-backed proxy) |
| Hidden (off-screen) count | window size (ONE ResizeObserver) | the drill-down + Back | layout → frame | summed list widths vs the detail min; capped at the frontier |
| Disclosure (collapsed?) per list | user toggle | each `TopicRail` | frame ↔ rail | manual `«` toggle (`override`); counts as icon width, then hides |
| New-item result | the new-topic modal | the owning topic list | modal → list | dialog returns the created id; the list selects it |
| Help text | the application's help config store | breadcrumb help icon | config → view | keyed by route + ui element |

