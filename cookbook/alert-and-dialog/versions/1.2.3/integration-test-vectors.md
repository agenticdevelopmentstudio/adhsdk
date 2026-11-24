
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | full-width-single-action | one-button alert | action button full width, gold |
| T2 | equal-width-when-narrow | two buttons, both natural widths within the row's equal share | equal-width `[ Cancel ][ OK ]` |
| T3 | natural-width-when-wide | two buttons, wide content (room for both at natural width) | natural-width, right-justified |
| T4 | keyboard-default | `keyboard:"default"`, Enter then Escape | Enter→confirm; Escape→cancel (or OK if no cancel) |
| T5 | keyboard-none | `keyboard:"none"`, press keys | keys ignored |
| T6 | keyboard-explicit-map | `{ Enter: "confirm" }`, then Escape | Enter→confirm; unlisted keys ignored; Escape still dismisses via cancel (or the action in alert mode) despite not being listed |
| T7 | destructive-forces-none | `destructive: true` | action red; no keyboard shortcuts |
| T8 | block-dismissal-when-busy | `busy: true` | dismissal blocked; spinner replaces buttons |

