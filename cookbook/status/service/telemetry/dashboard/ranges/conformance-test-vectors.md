
The vectors use `NOW = 2026-11-04T15:30:20.000Z`, the clock reading in `telemetry-dashboard-sections.test.ts`. Vectors 001 to 003 and 006 and 007 come from the `rangeWindow` and `alignToBuckets` blocks of that test file.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ranges-001 | range-names, range-type | Read `ANALYTICS_RANGES` | `["24h", "7d", "30d"]` |
| ranges-002 | window-24h-unit, window-24h-count, window-24h-start, window-24h-last-bucket, window-buckets-format | Test "24h is 25 hourly buckets ending in the current hour": `rangeWindow("24h", NOW)` | `unit` is `"hour"`; 25 buckets; first `"2026-11-03T15:00:00.000Z"`; last `"2026-11-04T15:00:00.000Z"` |
| ranges-003 | window-day-unit, window-day-count, window-day-boundaries, window-day-includes-today | Test "7d and 30d are that many UTC days including today": `rangeWindow("7d", NOW)` and `rangeWindow("30d", NOW)` | 7d: `unit` `"day"`, 7 buckets, first `"2026-10-29T00:00:00.000Z"`, last `"2026-11-04T00:00:00.000Z"`; 30d: 30 buckets |
| ranges-004 | window-until, window-since-is-first-bucket, window-fields | `rangeWindow("7d", NOW)` | `until` equals `new Date(NOW)`; `since` is `2026-10-29T00:00:00.000Z` |
| ranges-005 | window-buckets-order, window-24h-count | `rangeWindow("24h", NOW).buckets` | Strictly ascending; every consecutive pair 3,600,000 ms apart |
| ranges-006 | align-zero-fill, align-timestamp-spellings, align-sum | Test "zero-fills, tolerates either timestamp spelling, and sums repeats": buckets `["2026-11-03T00:00:00.000Z", "2026-11-04T00:00:00.000Z"]`, points `["2026-11-04T00:00:00Z", 2]` and `["2026-11-04T00:00:00.000Z", 3]` | `[0, 5]` |
| ranges-007 | align-drop-off-axis, align-drop-unparseable | Test "drops what is off the axis or unparseable": same buckets, points `["2026-01-01T00:00:00Z", 9]`, `["nope", 9]`, `[null, 9]` | `[0, 0]`; nothing thrown |
| ranges-008 | window-day-boundaries, window-day-no-local-time | `rangeWindow("7d", Date.parse("2026-11-04T00:00:00.000Z"))` run once under `TZ=UTC` and once under `TZ=Pacific/Chatham`, with identical output | Last bucket `"2026-11-04T00:00:00.000Z"`; first `"2026-10-29T00:00:00.000Z"` |
| ranges-009 | window-24h-start, window-24h-last-bucket | `rangeWindow("24h", Date.parse("2026-11-04T15:00:00.000Z"))` (exactly on the hour) | First `"2026-11-03T15:00:00.000Z"`; last `"2026-11-04T15:00:00.000Z"`; 25 buckets |
| ranges-010 | align-exact-match | Buckets as in ranges-006, point `["2026-11-04T06:00:00Z", 4]` (inside the day, not on its boundary) | `[0, 0]`; the point is dropped, not rounded |
| ranges-011 | align-timestamp-spellings | Buckets as in ranges-006, point `[Date.parse("2026-11-03T00:00:00.000Z"), 6]` (a number) | `[6, 0]` |
| ranges-012 | align-length, align-zero-fill | `alignToBuckets([], [["2026-11-04T00:00:00Z", 1]])` | `[]` |
| ranges-013 | align-input-iterable | Buckets as in ranges-006; points supplied as a generator yielding the one pair `["2026-11-04T00:00:00.000Z", 1]` | The pair is counted once; the result is `[0, 1]` |
| ranges-014 | align-pure | Call `alignToBuckets` twice with the same arrays | Equal results; the `buckets` array is unchanged |
| ranges-015 | window-day-includes-today, window-day-count | `rangeWindow("30d", NOW)` | 30 buckets; first `"2026-10-06T00:00:00.000Z"`; last `"2026-11-04T00:00:00.000Z"` |

