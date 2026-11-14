Verify the visual vectors with Playwright in the UI showcase app: render each variant and exercise the keyboard flows at 375, 768 and 1440 px widths. Vectors T9 to T11 are derived from the source and have no test behind them yet.

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
| T9 | keyboard-explicit-map, escape-routing | `{ Escape: "confirm" }` in confirm mode, press Escape | `onCancel` fires once; `onConfirm` does not (Escape is routed by `onOpenChange`, not the map) |
| T10 | keyboard-none, escape-routing | `keyboard:"none"`, press Escape, then click the backdrop | Escape does nothing; the backdrop click fires `onCancel` (confirm mode) or `onConfirm` (alert mode) once |
| T11 | destructive-forces-none, confirm-mode-trigger | `destructive: true` with no `cancelLabel` | one red button (`variant="destructive"`); Escape and Enter do nothing; backdrop click fires `onConfirm` |
| T12 | be-accessible-dialog | `destructive: true` with `cancelLabel` | Cancel has initial focus; Enter does not activate the delete button |
