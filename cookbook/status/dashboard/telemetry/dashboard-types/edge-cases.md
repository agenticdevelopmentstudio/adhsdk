
- **Null and empty input — sections**: a section with `data` `null` is a first load or a source that has never answered; a client reads `error` to tell a failure from "not yet".
- **Null and empty input — views**: nullable view fields are `null` when their section has no data; lists such as `sites` may be empty, and `siteReports` may be an empty object.
- **Boundary — row caps**: the dimensions and site error detail sections set `truncated` when a row cap is hit; the runtime report's `groups` may be shorter than `total`.
- **Boundary — series length**: a series is one value per bucket, so the `24h` range, which the server buckets hourly (25 buckets, counting the partial first hour), has 25 values and a daily range has one per day.
- **Malformed input — versions**: a backend older than `views` sends no `views`; the shape here says `views` is required, so a client must tolerate its absence at the call site (the formatting module's site-list helper does this).
- **Malformed input — unknown names**: a site name in a URL need not be in `siteReports`; a client looks it up with an own-key check.
- **Concurrent access**: not applicable — the module holds only immutable constants and types.
- **Error states**: a failed source shows as a section `error` and as an entry in the views' failure list; other sections stay usable.
- **Offline and cancellation**: not applicable — the module performs no I/O.
- **Drift**: if the server adds or renames a field, the parity check fails until the web copy is updated; a field the web copy lacks is not visible to the pages.

