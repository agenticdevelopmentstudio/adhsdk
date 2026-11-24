
The source has no tests beside it and the package's tests do not construct
`ProjectWindowGroup`; the vectors are derived from the source. Repository ids
are written A, B, C, D.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| group-001 | state-defaults, group-init-from-state | `ProjectWindowGroup()` | `activeRepoIDs` is empty, `selectedRepoID` is `nil`, `panel` is `browser`, `filterText` is empty |
| group-002 | activate-appends-at-end | Empty group; `activate(A)`, `activate(B)` | `[A, B]` |
| group-003 | activate-appends-after-selected | Active `[A, B, C]`, selected A; `activate(D)` | `[A, D, B, C]` |
| group-004 | activate-idempotent | Active `[A, B]`; `activate(A)` | `[A, B]`, nothing published |
| group-005 | deactivate-selected-next | Active `[A, B, C]`, selected B; `deactivate(B)` | Returns C; list `[A, C]`; `selectedRepoID` still B |
| group-006 | deactivate-selected-next | Active `[A, B, C]`, selected C; `deactivate(C)` | Returns B; list `[A, B]` |
| group-007 | deactivate-selected-none | Active `[A]`, selected A; `deactivate(A)` | Returns `nil`; list empty |
| group-008 | deactivate-not-selected | Active `[A, B]`, selected A; `deactivate(B)` | Returns A; list `[A]` |
| group-009 | deactivate-absent-noop | Active `[A]`, selected A; `deactivate(D)` | Returns A; list unchanged |
| group-010 | group-state-snapshot, group-filter-not-persisted | Group with filter text set for `browser`; read `state` | State has the four fields; no filter text |
| group-011 | panel-title, panel-symbol, panel-filter-placeholder | Read all three for each case | `Project Browser`/`folder`/`Filter Projects` and `Active Projects`/`square.stack.3d.up`/`Filter Active Projects` |
| group-012 | panel-raw-values-persisted, panel-codable, state-fields | Encode a `ProjectWindowState` with panel `activeProjects`, decode | Equal state; encoded panel is `activeProjects` |
| group-013 | select-changes-only-on-difference | Subscribe to `$selectedRepoID`, `select(A)` twice | One new value after the subscription's first |
| group-014 | selection-not-validated | `select(D)` where D is not active | `selectedRepoID` becomes D (no check) |
| group-015 | activate-appends-at-end | Active `[A]`, selected D (not in list); `activate(B)` | `[A, B]` |

