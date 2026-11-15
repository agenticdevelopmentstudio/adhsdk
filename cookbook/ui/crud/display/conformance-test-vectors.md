
Every vector is asserted by `display.test.ts` (the `columnDisplayValue` suite and the
`display conformance vectors` suite).

| ID | Requirements | Input | Expected |
|---|---|---|---|
| display-001 | convert-unix-timestamp-columns, interpret-value-as-seconds | column `created` / `integer`, value `1700000000` (test: "renders /v1 created/updated unix seconds as an ISO date") | `2023-11-14T22:13:20.000Z` |
| display-002 | convert-unix-timestamp-columns, interpret-value-as-seconds | column `updated` / `integer`, value `0` (same test) | `1970-01-01T00:00:00.000Z` |
| display-003 | pass-through-other-columns | column `count` / `integer`, value `5`; column `granted_at` / `string`, value `2024-01-01T00:00:00Z` (test: "leaves every other column, and a null timestamp, untouched") | `5`; `2024-01-01T00:00:00Z` (both unchanged) |
| display-004 | require-numeric-value | column `updated` / `integer`, value `null` (same test) | `null` |
| display-005 | shared-by-list-surfaces | `cellText({ created: 1700000000 }, created/integer column)` (test: "is what the list cell shows") | `2023-11-14T22:13:20.000Z` |
| display-006 | require-integer-column-type | column `created` / `string`, value `1700000000` | `1700000000` (unchanged number) |
| display-007 | match-name-exactly | column `Created` / `integer`, value `1700000000` | `1700000000` (unchanged) |
| display-008 | require-numeric-value | column `created` / `integer`, value the string `"1700000000"` | the string `"1700000000"` (unchanged) |
| display-009 | fall-back-on-non-finite | column `created` / `integer`, value `NaN` | `NaN` (the original value, not `null`) |
| display-010 | fall-back-on-non-finite | column `updated` / `integer`, value `Infinity` | `Infinity` |
| display-011 | require-numeric-value | column `updated` / `integer`, value `undefined` | `undefined` |
| display-012 | throw-on-unrepresentable-date | column `created` / `integer`, value `1e20` | throws `RangeError` (invalid time value) |
| display-013 | pass-through-other-columns, no-input-mutation | column `meta` / `object`, value an object `o` | the same reference `o`, unmodified |

