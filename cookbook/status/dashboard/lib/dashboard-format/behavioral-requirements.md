
### Bucket labels

- **bucket-utc**: Both bucket functions MUST format the timestamp in UTC, never in the viewer's local zone; the source's comment gives the reason: buckets are UTC, and "a local 'Nov 3' over a UTC-day bucket would be a different day's traffic for anyone west of Greenwich."
- **label-24h**: The bucket-label function MUST return the hour and minute as two digits each on a 24-hour clock (for example `14:00`) when the range is `"24h"`.
- **label-days**: The bucket-label function MUST return the abbreviated English month and the day of the month with no zero padding (for example `Nov 4`) when the range is `"7d"` or `"30d"`.
- **detail-24h**: The bucket-detail function MUST return the day label, a comma and a space, the 24-hour time and the suffix ` UTC` (for example `Nov 4, 14:00 UTC`) when the range is `"24h"`.
- **detail-days**: The bucket-detail function MUST return the day label followed by ` (UTC)` (for example `Nov 4 (UTC)`) when the range is `"7d"` or `"30d"`.
- **label-locale**: Both bucket functions MUST use English month names regardless of the viewer's locale.
- **label-invalid-date**: Both bucket functions MAY throw when the timestamp does not parse to a valid date; the source does so because the underlying date formatter throws a range error for an invalid date, and the module does not guard against it. Callers MUST NOT rely on the error type.

### Vital values

- **vital-cls**: The vital-formatting function MUST return the value with exactly two decimal places and no unit when the vital is `"cls"` (for example `0.1` becomes `0.10`).
- **vital-ms**: The vital-formatting function MUST return the value rounded to the nearest whole number followed by `ms` (for example `180` becomes `180ms`) when the vital is not `"cls"` and the value is below 1000.
- **vital-seconds**: The vital-formatting function MUST return the value divided by 1000, with exactly one decimal place, followed by `s` (for example `2400` becomes `2.4s`) when the vital is not `"cls"` and the value is 1000 or more.
- **vital-threshold-before-rounding**: The vital-formatting function MUST compare the raw value against 1000 before rounding, so a value of `999.6` is written `1000ms` and not `1.0s`.
- **vital-no-validation**: The vital-formatting function SHOULD NOT validate the value; as observed in the source, a negative number is written in milliseconds (`-5` becomes `-5ms`), and `NaN` is written as the text `NaN` for `"cls"` and `NaNms` for the other vitals.

### Site list

- **listed-present**: The listed-sites function MUST return the body's `views.sites` list itself, not a copy, when the body has one.
- **listed-absent**: The listed-sites function MUST return `null` when the body is `undefined`, has no `views`, or has a `views` with no `sites`; the source comment names the case: a backend older than `views` (a staggered deploy or a rollback) "must leave the rail empty rather than throw during render."
- **listed-empty-list**: The listed-sites function MUST return an empty list as an empty list, not `null`, when the server sent `sites: []`.
- **with-copy**: The with-site function MUST return a new list and MUST NOT mutate or return the list it was given.
- **with-none-or-listed**: The with-site function MUST return a copy of the list in its original order when the site is `null` or already in the list.
- **with-unlisted**: The with-site function MUST add a site that is not in the list and sort the whole result alphabetically using the platform's locale comparison (the order across runtimes is unspecified, because the source passes no locale), so a deep-linked site the server has no data for yet is still shown as selected.
- **with-exact-match**: The with-site function MUST treat a site as listed only on an exact, case-sensitive match.
- **with-sort-whole-list**: Because the sort runs over the whole result, the with-site function MAY reorder the server's entries too when it adds a site and the server's order differs from the locale order; this is observed behavior, not a requirement ports must copy.

### Site report

- **report-own-entry**: The site-report function MUST return the entry stored under `site` when the reports object has an own entry by that name.
- **report-none**: The site-report function MUST return the caller's `none` value, unchanged and by reference, when the reports object has no own entry for `site`.
- **report-inherited-names**: The site-report function MUST treat inherited property names such as `constructor`, `toString`, `hasOwnProperty` and `__proto__` as absent, because a site segment taken from a URL could otherwise read a function or the shared prototype object as a report; this is the reason the source gives for checking own entries.
- **report-no-copy**: The site-report function MUST return the stored entry itself, not a copy.

### Purity and ordering

- **pure-functions**: Every exported function MUST be pure: it MUST NOT mutate its arguments, read the clock, use storage or the network, or log.
- **synchronous**: Every exported function MUST return synchronously and MUST NOT depend on call order; the module holds no state, so concurrent calls cannot interleave.
- **module-formatters**: The two date formatters SHOULD be created once when the module loads and reused on every call, not rebuilt per call.

