
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| utc-day-001 | day-string-from-date, matches-wire-prefix | `string(from:)` of epoch 0 and of epoch 1,700,000,000 (`2023-11-14T22:13:20Z`). | `1970-01-01` and `2023-11-14`, the UTC day and not the local-time day (test: testStringFromEpochIsUTC). |
| utc-day-002 | day-after | `dayAfter("2026-06-19")`. | `2026-06-20` (test: testDayAfterSimple). |
| utc-day-003 | day-after | `dayAfter("2026-01-31")`. | `2026-02-01` (test: testDayAfterMonthBoundary). |
| utc-day-004 | day-after | `dayAfter("2026-12-31")`. | `2027-01-01` (test: testDayAfterYearBoundary). |
| utc-day-005 | day-after | `dayAfter("2024-02-28")`, `dayAfter("2024-02-29")` and `dayAfter("2026-02-28")`. | `2024-02-29`, `2024-03-01` and `2026-03-01` (test: testDayAfterLeapDay). |
| utc-day-006 | day-after-unparseable, no-throw | `dayAfter("not-a-date")`. | `not-a-date`, unchanged (test: testDayAfterReturnsInputOnGarbage). |
| utc-day-007 | utc-pinned | `string(from:)` of epoch 1,700,000,000 with the host time zone set to Pacific/Auckland (UTC+13 in November). | `2023-11-14` regardless of host zone; the source pins the zone (test: testUtcDay007_stringIgnoresHostTimeZone). |
| utc-day-008 | day-after-unparseable | `dayAfter("")` (test: see UTCDayTests). | The empty string, unchanged. |
| utc-day-009 | day-after-out-of-range | `dayAfter("2026-13-01")` (test: see UTCDayTests). | `2026-13-01`, unchanged. |
