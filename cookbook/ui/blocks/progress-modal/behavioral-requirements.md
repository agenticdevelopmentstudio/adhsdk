
- **render-as-dialog**: Component MUST render as a modal dialog that can be opened and closed via the `open` prop.
- **show-progress-bar**: Component MUST display a progress bar whose value is calculated as `(done / total) * 100` when total is greater than zero, or zero when total is zero.
- **display-completion-count**: Component MUST display the count as "done of total" in monospace font.
- **display-status-or-current-label**: Component MUST display `currentLabel` when provided. When `currentLabel` is omitted and the run is finished, MUST display "Finished". When omitted and the run is halted (error set and not finished), MUST display "Paused". When omitted and the run is in progress (no error, not finished), MUST display "Working…".
- **halt-on-error**: When `error` is set and `finished` is false (halted), the component MUST render the error block and, instead of the in-progress button state, show the Continue/Stop buttons (see **show-continue-and-stop-when-halted**). The progress bar continues to reflect `done`/`total` exactly as supplied by the host — the component does not itself pause any operation.
- **show-error-block-when-halted**: When halted, component MUST render an error block containing the error message. If `error.itemLabel` is present, it MUST appear above the error message.
- **show-results-log-when-provided**: When `results` array has items, component MUST render them as a scrollable list with maximum height constraint, regardless of whether the run is running, halted, or finished.
- **render-result-label-and-status**: Each result item MUST display the result's label followed by a status indicator. For failed results, MUST display the result message or `failedLabel` in red. For successful results, MUST display the result message or `okLabel` in muted text.
- **show-continue-and-stop-when-halted**: When halted (error set and not finished), component MUST display Continue and Stop buttons if their respective callbacks are provided.
- **show-close-when-finished**: When finished is true, component MUST display a Close button if `onClose` callback is provided.
- **finished-overrides-halt**: When `finished` is true, the component MUST NOT render the error block or the Continue/Stop buttons, even if `error` is still set; only the Close button (per **show-close-when-finished**) may render.
- **hide-buttons-during-progress**: When the run is in progress (no error and not finished), component MUST not display any action buttons.
- **prevent-dismiss-mid-run**: When `finished` is false, the component MUST swallow Escape and close-button dismiss requests internally and MUST NOT call `onClose`. When `finished` is true, the component MUST call `onClose` in response to Escape or the close button.
- **calculate-percentage-safely**: Component MUST handle zero total by setting percentage to zero instead of NaN.

