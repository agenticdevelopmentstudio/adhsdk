
- **Null or undefined value**: a `created` or `updated` integer column with a null
  or undefined value MUST be returned as is, not converted and not replaced by an
  empty string; showing a placeholder is the caller's job (`cellText` renders an
  em dash for it).
- **Zero**: `0` is a valid timestamp and MUST convert to the epoch
  (`1970-01-01T00:00:00.000Z`); it is not treated as missing.
- **Negative seconds**: a negative finite number converts to a date before 1970
  through `unixToIso`; the source adds no lower bound.
- **Fractional seconds**: a non-integer number is converted without rounding, so
  the fraction appears in the millisecond field; the source does not check that an
  `integer` column holds a whole number.
- **Non-finite numbers**: `NaN` and the infinities MUST come back unchanged
  because `unixToIso` returns null for them and the function falls back to the
  original value (the `??` fallback).
- **Out-of-range magnitude**: a finite number beyond the `Date` range makes
  `unixToIso` throw `RangeError`; the function neither catches nor reports it, so
  it reaches the caller (a rendering list surface) as an exception. This is
  surfaced, not swallowed, so it is stated here as a fact.
- **Wrong column type**: a `created` or `updated` column typed `string` or
  `number` MUST pass through, so an ISO-string `created` from a different API is
  not double-converted.
- **Concurrent access**: not applicable — the function is synchronous, holds no
  state and reads only its arguments, and JavaScript runs it single-threaded.
- **Error states and offline state**: not applicable — it performs no I/O, so
  there is no dependency to be unavailable and no network to lose; the only failure
  path is the `RangeError` above.

