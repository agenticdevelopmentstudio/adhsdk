
**Decision**: Bucket labels are formatted in UTC.
**Rationale**: The source comment: buckets are UTC, so they are labelled in UTC; "a local 'Nov 3' over a UTC-day bucket would be a different day's traffic for anyone west of Greenwich." Detail text states the zone (` UTC`, ` (UTC)`) because a tooltip or table has room to say it.
**Approved**: pending

**Decision**: The module words values and does not derive them.
**Rationale**: The header comment: every join, sort, threshold and rating is computed by the status server and arrives in `views`, so clients show the same answer and a port has little logic to copy.
**Approved**: pending

**Decision**: `listedSites` returns `null` for a missing list instead of throwing or returning an empty list.
**Rationale**: Doc comment: a backend older than `views` (staggered deploy, rollback) sends none, which "must leave the rail empty rather than throw during render." Returning `null` also lets a caller tell "no read yet" apart from a server that sent an empty list.
**Approved**: pending

**Decision**: `withSite` adds a URL-named site that the server lacks and re-sorts the whole list.
**Rationale**: Doc comment: a deep link to a site with no data yet must still show as selected. The list is otherwise in the server's order, so the helper is used only for that case, and the re-sort of the whole list is a simple way to find the new site's place.
**Approved**: pending

**Decision**: `siteReportFor` checks own entries with `Object.hasOwn`.
**Rationale**: Doc comment: a site segment such as `constructor` or `__proto__` would otherwise read a property every object inherits, "and the page would destructure a function or Object.prototype as a report."
**Approved**: pending

**Decision**: Vitals use milliseconds below 1000 and seconds with one decimal above, and CLS has two decimals and no unit.
**Rationale**: Doc comment: "CLS is unitless, the rest are milliseconds." The seconds form keeps long values short. The threshold compares the raw value, so a value that rounds up to 1000 reads `1000ms`, a small inconsistency kept as the source behaves. Known debt: the source does not record the inconsistency as a defect; the remedy is to compare after rounding, so `999.6` reads `1.0s`.
**Approved**: pending


**Decision**: Month names and the literal suffixes (` UTC`, ` (UTC)`, `ms`, `s`) are fixed English strings.
**Rationale**: The source builds both date formatters with the `"en"` locale and writes the suffixes as literals, so every viewer sees the same wording. It is a choice that affects what ports show, so it is recorded here for review rather than left implicit.
**Approved**: pending
