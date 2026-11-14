
### MailJSON

- **json-encode-signature**: `MailJSON.encode(_:)` MUST accept any `Encodable` value and return its JSON as a `String`.
- **json-pretty-printed**: The output MUST be pretty-printed (multi-line, indented).
- **json-sorted-keys**: Object keys MUST be written in sorted order, so the same value always prints the same text.
- **json-output-contract**: Ports MUST produce valid JSON, pretty-printed, with sorted keys and deterministic text. They need not match Swift byte for byte: Apple's Foundation writes `/` as `\/`, and a port MAY write `/` unescaped. Both front ends on a platform MUST call the same shared encode function.
- **json-source-of-truth**: `MailJSON.encode` MUST be the one encoder for the JSON that the MCP tools and the `--json` flag both print. How each front end calls it is specified in its own recipe (see Callers below).
- **json-encoder-errors**: `encode` MUST throw whatever error the encoder throws for a value it cannot encode; the error is not wrapped or caught. (The source also has a guard that throws `EncodingError.invalidValue` if the bytes are not UTF-8; it is unreachable and is described in Design Decisions, not required of ports.)
- **json-default-strategies**: `encode` MUST NOT set a date, data, key or non-conforming-float strategy. Values passed to `encode` MUST NOT contain `Date` or `Data` fields: timestamps arrive as strings, because Swift's default would write a `Date` as a number of seconds from 2001-01-01 (a `Date` at the Unix epoch encodes as -978307200) and no other platform has a matching default.
- **json-no-shared-state**: `encode` MUST NOT depend on state kept between calls, so the same value always gives the same text.

### MailDateBound

- **bound-signature**: `MailDateBound.normalize(_:edge:)` MUST take the raw text and an `Edge` (`start` or `end`) and return `String?`: a UTC timestamp, or nil for rejected input.
- **bound-date-start**: Text shaped `YYYY-MM-DD` that names a real date MUST return the text followed by `T00:00:00.000Z` when `edge` is `start`.
- **bound-date-end**: Text shaped `YYYY-MM-DD` that names a real date MUST return the text followed by `T23:59:59.999Z` when `edge` is `end`.
- **bound-date-shape**: A value counts as `YYYY-MM-DD` only when it splits on `-` into exactly three parts of 4, 2 and 2 characters, and every character is `-` or an ASCII digit.
- **bound-date-reality**: A value of that shape that does not name a real Gregorian date, in UTC, MUST return nil. The check builds the date and compares the year, month and day it reads back; a date the calendar rolls forward is rejected.
- **bound-date-no-fallthrough**: A value of `YYYY-MM-DD` shape that is not a real date MUST return nil and MUST NOT be tried as a timestamp.
- **bound-timestamp-utc**: Text that is not date-shaped but is a full ISO-8601 internet date-time (with a zone designator) MUST return that instant converted to UTC and written by `IntegrationClock.string(from:)` (see [adhsdk.ingredient.integrations.model.integration-records](cookbook:888b7ba2-61f6-4251-88df-3586c5c86b1f)), which gives the form `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`.
- **bound-timestamp-fractions**: A timestamp MUST be accepted both with fractional seconds and without them; the fractional form is tried first.
- **bound-timestamp-form**: The accepted timestamp text MUST match `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|z|[+-]\d{2}(:?\d{2})?)$`: an uppercase `T`, seconds, and a zone designator that is `Z`, `z` or a signed offset with or without a colon. Text without a zone designator, with a lowercase `t`, or with a space instead of `T` MUST return nil.
- **bound-fraction-truncate**: Fractional seconds beyond the millisecond MUST be truncated, not rounded, so `10:30:00.9996Z` gives `10:30:00.999Z`.
- **bound-timestamp-edge-ignored**: For a timestamp, `edge` MUST have no effect; the result is the given instant, not a start or end of day.
- **bound-reject-other**: Any other text, including the empty string, MUST return nil.
- **bound-lexical-compare**: The UTC string form is required because the store compares UTC strings lexically; callers MUST pass the returned string to the store unchanged.
- **bound-no-throw**: `normalize` MUST NOT throw; rejection is expressed only by nil.

### Callers

How a nil bound is reported, which edge each argument uses and how JSON is printed belong to the callers: [adhsdk.ingredient.integrations.cli.mail-command-line](cookbook:be4db0fe-628d-41f8-9fdf-25a6d46844cf) and [adhsdk.ingredient.integrations.mcp.mail-tool-source](cookbook:cbee8b02-9456-4d9b-942a-51f8a9c074fc). They are not repeated here.

### Runtime shape

Both enums are pure functions of their inputs. `normalize` builds a Gregorian UTC calendar and ISO-8601 formatters per call and never reads the clock. No ordering or concurrency rule applies: each call builds its own calendar, formatter or encoder.

