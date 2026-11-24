
| State | Appearance change | Behavior |
|-------|-------------------|----------|
| Running | Progress bar reflects `done`/`total`; status shows `currentLabel` if provided, otherwise "Working…"; no action buttons visible | Modal is open; Escape/× dismiss requests are swallowed internally (no `onClose` call); `done` updates as the host advances the batch |
| Halted | Progress bar unchanged from the last render; status shows `currentLabel` if provided, otherwise "Paused"; error block visible; Continue and Stop buttons visible | Modal remains open; Escape/× dismiss requests are swallowed internally (no `onClose` call); awaiting a Continue/Stop decision |
| Finished | Progress bar reflects `done`/`total` as provided — not necessarily 100%, since a Stop can finish the run early; status shows `currentLabel` if provided, otherwise "Finished"; error block and halted buttons are hidden even if `error` is still set; Close button visible if `onClose` is provided | Modal is open; Escape, ×, or the Close button all call `onClose` |
| Closed | — | Modal is not rendered (`open` prop is false) |

The results log renders whenever `results` has items, independent of the state above — it is not exclusive to Finished.

