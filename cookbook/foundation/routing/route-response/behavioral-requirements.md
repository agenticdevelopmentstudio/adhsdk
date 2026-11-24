
### Shape

- **fields**: A `RouteResponse` MUST carry `status` (`Int`), `body` (`Data`), `contentType` (`String`) and `headers` (`[String: String]`) exactly as given to `init`.
- **builders-empty-headers**: `json`, `error`, `notFound` and `noContent` MUST each return a response whose `headers` is empty.
- **init-defaults**: `init` MUST default `contentType` to `application/json` and `headers` to an empty dictionary; `status` and `body` are required.
- **status-unchecked**: `init` MUST NOT validate `status`; any `Int` is stored as given.
- **value-semantics**: A `RouteResponse` MUST be `Sendable` and `Equatable`; two responses are equal when every field is equal.

### JSON encoding

- **wire-encoder-format**: `makeJSONEncoder()` MUST return an encoder that writes snake_case keys, ISO-8601 dates, pretty-printed output and sorted keys.
- **encoder-fresh-per-call**: `makeJSONEncoder()` MUST return a new encoder instance on every call, because `JSONEncoder` is a reference type and handlers run concurrently.
- **json-body**: `json(value, status:)` MUST encode the value with `makeJSONEncoder()` and return a response whose body is the encoded data, whose `status` is the given status (200 by default) and whose `contentType` is `application/json`.
- **json-snake-case-keys**: A property such as `fooBar` MUST appear as `foo_bar` in the body.
- **json-iso-dates**: A `Date` property MUST be written as an ISO-8601 string without fractional seconds (`2026-01-31T00:00:00Z`).
- **json-format-is-pretty-sorted**: The body MUST be pretty-printed with keys sorted, so the exact bytes are deterministic for a given value; with Foundation's formatting that is a two-space indent and ` : ` between key and value. A `/` inside a string value MUST be written as `\/`, as Foundation's `JSONEncoder` does by default, so a value such as `a/b` has the same bytes on every platform.
- **json-encode-failure-is-empty-object**: When encoding throws, `json(_:status:)` MUST return a response with the body `{}` and the requested status, and MUST NOT throw, log or otherwise surface the failure.

### Error and fixed responses

- **error-body**: `error(message, status:)` MUST return a response whose body is the JSON object with the single key `error` holding the message, produced through `json(_:status:)`.
- **error-body-is-valid-json**: The error body MUST be valid JSON that decodes back to the exact message for any message, including one with a quote, a backslash or a newline.
- **error-status**: `error(_:status:)` MUST set the response `status` to the given value.
- **not-found**: `notFound(message)` MUST return `error(message, status: 404)`, with the message defaulting to `Not found`.
- **no-content**: `noContent` MUST be a response with `status` 204 and an empty body.
- **no-content-content-type**: `noContent` MUST keep the default `contentType` of `application/json` even though its body is empty.
- **pure-builders**: Every builder MUST depend only on its arguments, MUST NOT perform I/O and MUST NOT mutate shared state.

