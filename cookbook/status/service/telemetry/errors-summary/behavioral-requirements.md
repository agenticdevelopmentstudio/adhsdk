
### Contract

- **function-shape**: `errorsSummary` MUST accept a read-only array of `ErrorDTO` and return an
  `ErrorsSummary` object with exactly the fields `active`, `backlog`, `events` and `top`.
- **purity**: `errorsSummary` MUST NOT mutate the input array or any of its rows.
- **no-side-effects**: `errorsSummary` MUST NOT perform I/O, read the clock, or consult any state
  other than its argument; the same input MUST yield an equal result.
- **no-errors-raised**: `errorsSummary` MUST NOT validate its input or raise an error; the
  caller MUST pass an array of rows shaped like `ErrorDTO` (the parameter type declares it).

### Figures

- **active-count**: `active` MUST equal the number of rows whose `active` field is strictly
  `true`.
- **unjudged-is-backlog**: A row whose `active` is `false` or absent MUST be counted in
  `backlog`, never in `active`: a row with no verdict counts as backlog, never as an incident and
  never as clear.
- **backlog-count**: `backlog` MUST equal the input length minus `active`.
- **events-total**: `events` MUST be the sum of `count` over every input row, active and backlog
  alike, treating a falsy `count` (zero, `NaN`, `undefined`) as 0.
- **empty-input**: For an empty array, `errorsSummary` MUST return all-zero figures and an empty
  `top` (`active` 0, `backlog` 0, `events` 0).

### Top list

- **top-active-only**: `top` MUST contain only rows whose `active` is strictly `true`.
- **top-order**: `top` MUST be ordered by `count` descending, so the list matches its `{count}×`
  labels; GlitchTip sends rows in last-seen order, not by volume.
- **top-tie-order**: Rows with equal `count` MUST keep their relative input order (the sort is a
  stable `Array.prototype.sort` over a copy of the active rows).
- **top-cap**: `top` MUST contain at most `ERRORS_TOP_COUNT` rows, the exported constant `5`.
- **top-rows-unchanged**: Each entry of `top` MUST be the original `ErrorDTO` row, unmodified; the
  summary adds no fields to it.

### Attachment rule (owned by the caller)

- **judged-rows-only**: The caller MUST pass only rows that have been judged, with each row's
  `active` verdict stamped. `errorsSummary` itself cannot tell a judged row from an unjudged one
  (both read as backlog), so the guarantee is the caller's. `GET /telemetry` passes the rows
  returned by its `judged` step and attaches the result every time.

