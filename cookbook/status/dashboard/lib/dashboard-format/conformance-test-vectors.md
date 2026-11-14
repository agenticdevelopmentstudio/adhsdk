
Vectors 001–011 are the assertions in `dashboard-format.test.ts`; the rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dfmt-001 | label-days, bucket-utc | test "label in UTC": bucket-label of `2026-11-04T00:00:00.000Z` with `"7d"` | `Nov 4` |
| dfmt-002 | label-24h | bucket-label of `2026-11-04T14:00:00.000Z` with `"24h"` | `14:00` |
| dfmt-003 | detail-24h | bucket-detail of `2026-11-04T14:00:00.000Z` with `"24h"` | `Nov 4, 14:00 UTC` |
| dfmt-004 | detail-days | bucket-detail of `2026-11-04T00:00:00.000Z` with `"30d"` | `Nov 4 (UTC)` |
| dfmt-005 | vital-seconds, vital-ms, vital-cls | test "writes each vital in its unit": `("lcp", 2400)`, `("inp", 180)`, `("cls", 0.1)` | `2.4s`, `180ms`, `0.10` |
| dfmt-006 | listed-present | test "is the server's list": body with `views.sites` of `["a.com","b.com"]` | `["a.com","b.com"]` |
| dfmt-007 | listed-absent | test "is null, not a throw": `undefined`, `{}`, and `{ views: {} }` | `null` for each |
| dfmt-008 | with-none-or-listed | test "keeps the server's list": `(["a.com","c.com"], "c.com")` and `(["a.com"], null)` | `["a.com","c.com"]` and `["a.com"]` |
| dfmt-009 | with-unlisted | test "puts a deep-linked site": `(["a.com","c.com"], "b.com")` | `["a.com","b.com","c.com"]` |
| dfmt-010 | report-own-entry | test "returns the server's report": reports with `example.com` mapped to `{ empty: false }`, site `example.com` | `{ empty: false }` |
| dfmt-011 | report-inherited-names, report-none | test "treats %s as no report" for `unknown.com`, `constructor`, `toString`, `hasOwnProperty`, `__proto__` | the `none` value itself, for each (five cases) |
| dfmt-012 | with-copy | `with-site` on `["a.com"]` with `"a.com"`; compare identity | an equal list that is not the same object |
| dfmt-013 | listed-empty-list | body with `views.sites` of `[]` | `[]`, not `null` |
| dfmt-014 | vital-threshold-before-rounding | `("lcp", 999.6)` and `("lcp", 1000)` | `1000ms` and `1.0s` |
| dfmt-015 | vital-no-validation | `("inp", -5)` and `("cls", NaN)` | `-5ms` and `NaN` |
| dfmt-016 | label-invalid-date | bucket-label of `not-a-date` with `"7d"` | throws a range error |
| dfmt-017 | with-sort-whole-list | `(["c.com","a.com"], "b.com")` | `["a.com","b.com","c.com"]` (ASCII names sort the same under any sensible collation) |
| dfmt-018 | with-exact-match | `(["a.com"], "A.com")` | `["a.com","A.com"]` under the default English ICU collation, which puts lowercase first (the lookup is case-sensitive, so the site is added; the order of the two is unspecified across runtimes, so a port MAY order them differently) |

| dfmt-019 | vital-ms | `("lcp", 999.4)` | `999ms` |
| dfmt-020 | label-days | bucket-label of `2026-11-04T00:00:00.000Z` with an unknown range `"1y"` | `Nov 4`, the day format |
| dfmt-021 | bucket-utc | bucket-label of `2026-11-04T23:59:59.999Z` with `"7d"` | `Nov 4`, the earlier day |
| dfmt-022 | report-none | empty reports object, site `""`, a `none` value | the `none` value itself |
