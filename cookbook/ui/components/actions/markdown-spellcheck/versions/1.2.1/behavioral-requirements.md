
- **default-off**: The control MUST render its toggle in the off state
  (`aria-pressed="false"`) and MUST NOT lint, load harper, or show the panel
  until the toggle is enabled.
- **lazy-load-harper**: The control MUST import harper.js (and its WASM) only
  the first time the check is enabled — never on initial render — and MUST reuse
  that one linter instance for the lifetime of the control.
- **use-worker-linter**: The control MUST drive harper's `WorkerLinter` (WASM
  in a Web Worker), not a main-thread `LocalLinter`, so the UI thread is not
  blocked.
- **lint-markdown-source**: The control MUST lint in markdown source mode
  (`language: 'markdown'`) so fenced code blocks and markdown syntax are skipped
  and only prose is checked.
- **list-problems**: When enabled and problems exist, the control MUST list
  each problem as the flagged text plus harper's message in the panel.
- **offer-suggestions**: For a problem that has suggestions, the control MUST
  render one apply action per suggestion, capped at the first four; applying it
  MUST call `onApply` with the next markdown source.
- **relint-on-settle**: While the panel is open, the control MUST re-lint
  when the source settles after a change, debounced so a burst of edits coalesces
  into one check.
- **show-empty-state**: When enabled and no problems are found, the control
  MUST show an explicit "No issues found." state rather than an empty panel.
- **show-error-state**: If harper fails to load or lint, the control MUST
  show an inline "unavailable" state instead of crashing.
- **reset-on-disable**: Toggling the check off MUST close the panel and clear
  the listed problems.
- **be-client-only**: The control MUST be a client component
  (`"use client"`); it MUST NOT execute harper or worker code during SSR.
- **dispose-on-unmount**: The control MUST call the linter's `dispose()` when
  the control unmounts, releasing its worker/WASM resources.
- **apply-latest-lint**: `apply` MUST resolve `issueIndex` and `suggestionIndex`
  against the results of the linter's most recently completed `lint(source)`
  call.

