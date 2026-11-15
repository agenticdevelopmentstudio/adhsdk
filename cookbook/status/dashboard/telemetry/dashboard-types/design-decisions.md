
**Decision**: The web package keeps a hand mirror of the server's types instead of importing them.
**Rationale**: The header comment of `dashboard-types.ts`: the package has the server only as a development dependency, so it cannot import the types at run time. A drift test stops the copies diverging.
**Approved**: pending

**Decision**: A section keeps its last good `data` beside the latest `error`.
**Rationale**: The `DashboardSection` doc comment in `dashboard-types.ts`: the last good answer survives a later failure, so stale data stays on screen instead of the page going blank when one source fails.
**Approved**: pending

**Decision**: The server derives the views and the pages only lay them out.
**Rationale**: The section comment above the views in `dashboard-types.ts`: every join, sort, threshold and rating lives in the server's views module, so every client shows the same answer and a port copies shapes, not logic.
**Approved**: pending

**Decision**: Unknown numbers are `null`, not zero.
**Rationale**: The `VercelRosterEntry.pageviews` doc comment in `dashboard-types.ts`: null when analytics is off or the count could not be read, which is not a zero. A zero would read as "measured, and none".
**Approved**: pending

**Decision**: Parity is checked by mutual assignability, with the lists compared at run time.
**Rationale**: The `Exact` type comment in `dashboard-types-parity.test.ts`: a renamed field, a nullability change or a union member stops the check being true. It catches drift that a transpile-only test run would not.
**Approved**: pending

**Decision**: Client reading rules over server data were removed from this recipe; this module only declares types and four constants.
**Rationale**: An earlier version of this recipe described 18 rules such as keeping stale section data after a failure, reading a null count as unknown, treating a request `status` of 0 as no response, treating `truncated` and `incomplete` as short results, and tolerating a response with no `views`. None of them runs in `dashboard-types.ts`. They are implemented in the status-web components instead: `DashboardPanel` and `viewsMissing` in `DashboardParts.tsx`, the truncation notes in `AnalyticsView.tsx` and `ErrorsSitePage.tsx`, the "No response" label in `ErrorsSitePage.tsx`, and `failureRateHigh` and the failure lists in the site pages. The server produces the rest (series length, sessions sum, runtime group message, path and key, the active-issue rule, the `views` joins), so they are not client code anywhere in status-web.
**Approved**: pending
