
- **Nothing answered**: Every section null gives empty lists, null optional fields and no reports.
- **Zero versus absent**: Zero figures are absent in a site report, except health on a site that served requests (see `#requirements/report-health`).
- **Mismatched axes**: Handled by `#requirements/series-gap`; a bucket a provider has not reached is a gap.
- **Project with no domain**: Keyed by its name, listed through the roster, and its site page is not empty.
- **Mixed-case or `www` hosts**: Normalized by `#requirements/site-key`.
- **Unmeasured vital**: Null value gives a null rating, not `good`.
- **Unparseable `lastSeen`**: `Date.parse` gives NaN, and the comparison is then false so the already accumulated row's value is kept (see `#requirements/merge-rows`).
- **Equal counts**: Every sort has an explicit name tiebreak, using the fixed-locale comparator of `#requirements/tiebreak-comparator`, so output is stable on every host.
- **Concurrent access**: Not applicable; the functions are pure and share nothing.
- **Offline or error**: The module does no I/O; a failed section appears in `failures` when it has no last-good data.
- **Retry**: Not applicable; the sections' cache retries.

