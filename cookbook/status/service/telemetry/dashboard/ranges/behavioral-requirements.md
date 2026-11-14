
**Range names**

- **range-names**: `ANALYTICS_RANGES` MUST be the ordered list `"24h"`, `"7d"`, `"30d"`.
- **range-type**: `AnalyticsRange` MUST be the union of exactly those three strings.
- **range-validation-by-callers**: Callers that accept a range from outside the process MUST validate it against `ANALYTICS_RANGES` first. This module does not validate; `rangeWindow` takes only an `AnalyticsRange`, and any other value is outside its contract.

**Window shape**

- **window-fields**: `rangeWindow(range, nowMs)` MUST return a `RangeWindow` with `since`, `until`, `unit` and `buckets`.
- **window-until**: `until` MUST be a `Date` equal to `nowMs`, unaligned to any bucket.
- **window-buckets-format**: Each entry of `buckets` MUST be an ISO 8601 string in the form produced by `Date.prototype.toISOString` (UTC, with milliseconds and a trailing `Z`).
- **window-buckets-order**: `buckets` MUST be ordered oldest first, with consecutive entries one step apart.
- **window-since-is-first-bucket**: `since` MUST equal the first bucket's start.

**The 24h window**

- **window-24h-unit**: For `"24h"`, `unit` MUST be `"hour"` and the step MUST be 3,600,000 ms.
- **window-24h-start**: For `"24h"`, the first bucket MUST start 24 hours before the start of the hour that contains `nowMs`.
- **window-24h-count**: For `"24h"`, `buckets` MUST hold 25 entries: 24 full hours plus the current, partial hour.
- **window-24h-last-bucket**: For `"24h"`, the last bucket MUST be the start of the hour that contains `nowMs`.

**The 7d and 30d windows**

- **window-day-unit**: For `"7d"` and `"30d"`, `unit` MUST be `"day"` and the step MUST be 86,400,000 ms (24 hours).
- **window-day-count**: For `"7d"`, `buckets` MUST hold 7 entries; for `"30d"`, 30 entries.
- **window-day-boundaries**: Day buckets MUST start at 00:00:00.000 UTC, computed by flooring `nowMs` to a multiple of 86,400,000 ms.
- **window-day-includes-today**: The last day bucket MUST be the UTC day that contains `nowMs`, and the first MUST be `days - 1` days earlier. The source comment states "that many UTC days including today".
- **window-day-no-local-time**: Day boundaries MUST NOT depend on the host's time zone or daylight-saving rules; they follow UTC arithmetic on epoch milliseconds only.

**Alignment**

- **align-length**: `alignToBuckets(buckets, points)` MUST return an array the same length as `buckets`, in the same order.
- **align-zero-fill**: A bucket that no point lands in MUST hold `0`.
- **align-sum**: Points that land in the same bucket MUST be summed, not replaced or averaged.
- **align-exact-match**: A point MUST land in a bucket only when its timestamp, parsed and re-serialised with `toISOString`, equals the bucket string exactly. The module MUST NOT round a timestamp down to the containing bucket; a provider whose timestamps are not already on a bucket boundary has them dropped.
- **align-timestamp-spellings**: A timestamp MAY be a string or a number. Both `"2026-11-04T00:00:00Z"` and `"2026-11-04T00:00:00.000Z"` MUST land on the bucket `"2026-11-04T00:00:00.000Z"`.
- **align-drop-off-axis**: A point whose timestamp matches no bucket MUST be dropped.
- **align-drop-unparseable**: A point whose timestamp is neither a string nor a number, or whose string or number does not parse to a valid date, MUST be dropped without throwing. `null`, `undefined`, objects and `"nope"` all fall in this case.
- **align-input-iterable**: `points` MAY be any iterable of `[timestamp, value]` pairs; it is consumed once.
- **align-value-added-as-is**: The value of a matched point MUST be added to the bucket total as given. The function does not validate it, and a non-numeric or `NaN` value is outside its contract; callers MUST coerce values to numbers before the call, as the sibling modules do.
- **align-pure**: `alignToBuckets` MUST NOT modify `buckets` or its input pairs.

**Side effects**

- **no-side-effects**: Neither function MUST read a clock, perform I/O, log or keep state. The same inputs MUST give the same outputs.

