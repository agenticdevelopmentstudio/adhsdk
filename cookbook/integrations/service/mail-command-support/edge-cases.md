
- **Empty text**: `normalize("")` MUST return nil. It is not date-shaped and is not a timestamp.
- **Surrounding whitespace**: `normalize(" 2026-11-13")` MUST return nil. The source does not trim, so a leading or trailing space breaks both the date shape and the timestamp parse.
- **Wrong separators or lengths**: `2026/11/13`, `26-11-13` and `2026-1-5` MUST return nil.
- **Non-ASCII digits**: Digits from other scripts MUST NOT count; only `-` and ASCII digits pass the shape test.
- **Year range**: The source sets no year range of its own; a four-digit year is accepted when the Gregorian calendar can build the date and read the same year, month and day back. Years such as `0001` and `2026` satisfy that; `0000` is not verified, because the calendar may map it to 1 BC and the read-back check may then reject it.
- **Impossible dates**: A month of `00` or `13`, a day of `00` or `32`, and 29 February in a non-leap year MUST return nil.
- **Date-only start and end**: The same date returns different strings for `start` and `end`, so `since=until=D` covers the whole UTC day.
- **Timestamp without a zone designator**: Rejected. Both ISO-8601 option sets used require an internet date-time, which carries a zone.
- **Local time**: Date-only values are read as UTC days regardless of the machine's zone; a timestamp's offset is honored and converted.
- **Precision loss**: A timestamp with more precision than milliseconds is rewritten by `IntegrationClock.string(from:)` in millisecond form (vector 020).
- **Unencodable value**: `MailJSON.encode` MUST propagate the encoder's error; the front ends decide how to show it. The source also guards against bytes that are not UTF-8 by throwing `EncodingError.invalidValue` (`not UTF-8`); the standard encoder never produces such bytes, so the branch is unreachable and no port needs it.
- **Escaped slashes**: Because the encoder is left on its defaults, a `/` in a string is written as `\/` on Apple's Foundation. This is not part of the output contract (see json-output-contract); ports need only valid, sorted, deterministic output.
- **Dates inside encoded values**: No date strategy is set, so a `Date` field is written in the encoder's default numeric form; the records the front ends print carry timestamps as strings already.
- **Concurrent calls**: Not applicable to shared state; every call makes its own encoder, calendar and formatters, so calls cannot interfere.
- **Offline, cancellation, timeouts**: Not applicable; both enums are synchronous and touch no network, file or process.

