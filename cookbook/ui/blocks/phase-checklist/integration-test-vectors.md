
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-section-per-phase, render-phase-count | two phases, the first with done/in-progress/todo/stopped items, the second empty | two sections; counts "1 / 3" and "0 / 0" |
| T2 | render-row-per-item | the same phases | four list items |
| T3 | name-status | the same phases | rows carry "done", "in progress", "to do", "stopped" |
| T4 | render-status-icon | the same phases | four `aria-hidden` svg icons |
| T5 | mute-stopped | the same phases | "Old shim" has `line-through` and `text-apt-text-dim`; "Renamed" does not |
| T6 | forward-host-attributes | `phases={[]} className="mt-2" data-testid="pc"` | the root carries both |
