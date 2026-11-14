
`errorsSummary` is the server-side judgment behind the Errors card of the production-visibility
band. Given the live list of `ErrorDTO` rows (GlitchTip issues, each already stamped with the
board's own `active` verdict), it returns one `ErrorsSummary`: how many issues are active, how
many sit in the backlog behind them, how many events every issue carries, and the active issues
worth listing, loudest first. It exists so no client re-derives these figures. It is a
synchronous, pure function with no I/O. `GET /telemetry` in `routes/telemetry.ts` is its one
caller; it attaches the result to the `TelemetrySnapshot` as `errorsSummary` after the rows have
been judged. `TelemetrySnapshot.errorsSummary` is optional: a snapshot without it makes no claim
about errors, and a stored row has no verdict, so the summary exists on the live snapshot only.

