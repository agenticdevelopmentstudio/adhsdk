
- **convert-unix-timestamp-columns**: When `column.name` is `created` or
  `updated`, `column.type` is `integer`, and `value` is a JavaScript number,
  the function MUST return that value converted to an ISO 8601 date string in
  UTC with millisecond precision (the `unixToIso` result).
- **interpret-value-as-seconds**: The function MUST treat the numeric value as
  unix seconds, so `0` yields `1970-01-01T00:00:00.000Z` and `1700000000`
  yields `2023-11-14T22:13:20.000Z`.
- **match-name-exactly**: The conversion MUST apply only to the exact column
  names `created` and `updated`; the name match is case-sensitive and no other
  column name qualifies.
- **require-integer-column-type**: A column named `created` or `updated` whose
  `type` is anything other than `integer` MUST be returned unconverted.
- **require-numeric-value**: A `created` or `updated` integer column whose value
  is not a JavaScript number (`null`, `undefined`, a string, an object) MUST be
  returned unchanged, so a null timestamp stays null.
- **fall-back-on-non-finite**: When the value is a number that `unixToIso`
  rejects (`NaN`, `Infinity`, `-Infinity`), the function MUST return the original
  value rather than `null`.
- **pass-through-other-columns**: Every value for a column that does not meet
  the conversion conditions MUST be returned as the identical value (same type,
  same reference for objects), including integer columns not named `created`
  or `updated` and string timestamp columns such as `granted_at`.
- **no-input-mutation**: The function MUST NOT mutate `column` or `value`.
- **no-metadata-lookup**: The function MUST decide from the supplied `column`
  descriptor alone and MUST NOT read the row or the table metadata.
- **return-type-unknown**: The function's return type is `unknown`; the caller
  MUST apply its own null, stringify and truncate formatting to the result.
- **shared-by-list-surfaces**: The table cell text helper (`cellText` in
  `CrudTable`) SHOULD obtain its displayed value from this function so that
  every list surface renders the same timestamp text; the data view also routes
  its cells, including the cells of an unsaved draft row (the buffered value, else the
  seeded baseline), through it.
- **throw-on-unrepresentable-date**: A finite number so large that its millisecond
  value falls outside the range of a JavaScript `Date` (more than 8.64e12
  seconds in magnitude) is passed to `unixToIso` unguarded, so the function MUST
  let the resulting `RangeError` propagate to the caller. (This is the source's
  actual behavior, recorded as a requirement of the port; see Edge Cases.)

