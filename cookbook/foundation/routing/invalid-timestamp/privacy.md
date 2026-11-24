
- **Data handled**: Only the message its caller passes in; `RouteRequest` includes the rejected raw query value in it.
- **Echoed value**: The message includes the raw, untrusted query value (`RouteRequest.swift`, `parseISO8601`), which can hold quotes, newlines or markup. The type does not limit its length or escape it. A consumer MUST NOT write the message to a log or render it as markup without escaping; `RouteResponse.error` JSON-encodes it.
- **Storage**: None; it persists nothing.
- **Transmission**: None; it performs no network access itself.
- **Retention**: None beyond the lifetime of the value the caller holds.

