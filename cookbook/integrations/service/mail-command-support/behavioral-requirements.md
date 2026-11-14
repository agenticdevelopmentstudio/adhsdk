
### MailJSON

- **json-encode-signature**: `MailJSON.encode(_:)` MUST accept any `Encodable` value and return its JSON as a `String`.
- **json-pretty-printed**: The output MUST be pretty-printed (multi-line, indented).
- **json-sorted-keys**: Object keys MUST be written in sorted order, so the same value always prints the same text.
- **json-output-contract**: Ports MUST produce valid JSON, pretty-printed, with sorted keys and deterministic text. They need not match Swift byte for byte: Apple's Foundation writes `/` as `\/`, and a port MAY write `/` unescaped. Output compared across front ends of one platform MUST come from one encoder.
- **json-source-of-truth**: The comment on the type, which names [MailCommandLine] and [MailToolSource], states that this is "the JSON shape the MCP tools and the `--json` flag both print"; both front ends MUST call `MailJSON.encode` for every JSON result and MUST NOT configure their own encoder.
- **json-encoder-errors**: `encode` MUST throw whatever error the encoder throws for a value it cannot encode; the error is not wrapped or caught. (The source also has a guard that throws `EncodingError.invalidValue` if the bytes are not UTF-8; it is unreachable and is described in Design Decisions, not required of ports.)
- **json-default-strategies**: `encode` MUST NOT set a date, data, key or non-conforming-float strategy; the encoder's defaults apply to every value.
- **json-no-shared-state**: `encode` MUST NOT depend on state kept between calls, so the same value always gives the same text.

### MailDateBound

- **bound-signature**: `MailDateBound.normalize(_:edge:)` MUST take the raw text and an `Edge` (`start` or `end`) and return `String?`: a UTC timestamp, or nil for rejected input.
- **bound-date-start**: Text shaped `YYYY-MM-DD` that names a real date MUST return the text followed by `T00:00:00.000Z` when `edge` is `start`.
- **bound-date-end**: Text shaped `YYYY-MM-DD` that names a real date MUST return the text followed by `T23:59:59.999Z` when `edge` is `end`.
- **bound-date-shape**: A value counts as `YYYY-MM-DD` only when it splits on `-` into exactly three parts of 4, 2 and 2 characters, and every character is `-` or an ASCII digit.
- **bound-date-reality**: A value of that shape that does not name a real Gregorian date, in UTC, MUST return nil (the source comment says "including a date that does not exist"). The check builds the date and compares the year, month and day it reads back; a date the calendar rolls forward is rejected.
- **bound-date-no-fallthrough**: A value of `YYYY-MM-DD` shape that is not a real date MUST return nil and MUST NOT be tried as a timestamp.
- **bound-timestamp-utc**: Text that is not date-shaped but is a full ISO-8601 internet date-time (with a zone designator) MUST return that instant converted to UTC and written by `IntegrationClock.string(from:)`, (see [IntegrationClock](cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f)), which gives the form `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`.
- **bound-timestamp-fractions**: A timestamp MUST be accepted both with fractional seconds and without them; the fractional form is tried first.
- **bound-timestamp-edge-ignored**: For a timestamp, `edge` MUST have no effect; the result is the given instant, not a start or end of day.
- **bound-reject-other**: Any other text, including the empty string, MUST return nil.
- **bound-lexical-compare**: The UTC string form is required because the store compares UTC strings lexically, as the source comment says; callers MUST pass the returned string to the store unchanged.
- **bound-no-throw**: `normalize` MUST NOT throw; rejection is expressed only by nil.

### Callers' handling of a rejected bound

These rules belong to the callers and are recorded here only so the helpers' nil result has a defined meaning; the callers' own recipes are [MailCommandLine](cookbook:be4db0fe-628d-41f8-9fdf-25a6d46844cf) and [MailToolSource](cookbook:cbee8b02-9456-4d9b-942a-51f8a9c074fc).

- **bound-mcp-rejection**: `MailToolSource` MUST turn a nil result into an `ArgumentError` whose message is `<key> must be YYYY-MM-DD or an ISO-8601 timestamp`, where `<key>` is the argument name.
- **bound-cli-rejection**: `MailCommandLine` MUST treat a nil result for `--since` or `--until` as a failed parse (it returns no parsed command) and does not name the offending value.
- **bound-cli-edges**: `MailCommandLine` MUST read `--since` with `edge: .start` and `--until` with `edge: .end`, so a bare date range is inclusive of both days.

### Runtime shape

Both enums are pure functions of their inputs. `normalize` builds a Gregorian UTC calendar and ISO-8601 formatters per call and never reads the clock. No ordering or concurrency rule applies: each call builds its own calendar, formatter or encoder.

