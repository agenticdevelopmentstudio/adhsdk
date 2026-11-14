
- **Empty and missing data**: `MailMessageFilter` decoding MUST accept `{"account":"a"}`; every other field takes its default. A missing `account` MUST fail decoding.
- **Empty collections**: `modifyLabels` and `moveMessages` MUST send empty `messageIds`, `add`, `remove` and `from` as given; this file does not reject them, and the service decides what an empty list means (an empty `from` removes nothing, per the case's comment).
- **Whitespace-only query**: A `query` that trims to nothing MUST count as no query, so no search runs and `queryIgnored` cannot be raised.
- **Boundary limits**: `limit` of 0 or less MUST become 1; `limit` above 500 MUST become 500; 1 and 500 MUST pass unchanged.
- **Cursor on the last page**: `nextCursor` MUST be nil on the last page, which ends paging.
- **Short secret**: A client secret under 15 characters MUST show no suffix, so `clientSecretSuffix` is nil.
- **Older service, any-of labels**: A page without `appliedAnyLabels` decodes as false and MUST be refused when `anyLabels` was sent, because the older service listed everything.
- **Older service, query**: A page without `appliedQuery` decodes as false and MUST be refused when a query was sent, because the older service listed the synced copy.
- **Older service, threads**: An older service cannot decode `getThread` and answers `bad request`; the client MUST report that as a service too old to show threads. The same text from any other request is not translated.
- **Older client, not found**: A client built before `notFound` MUST still decode a not-found reply as a plain failure and show its message.
- **Wrong reply shape**: A reply of a case the method did not expect MUST throw the `unexpected response` error, not return a default value.
- **Malformed reply bytes**: The decoder's own error propagates from `send`, unwrapped; this file adds no error type for it.
- **Transport failure**: An error thrown by the transport (an unreachable daemon, a broken connection) propagates from `send` unchanged; the client does not retry.
- **Concurrent calls**: Not a hazard in this file: `MailClient` is stateless and `Sendable`, so parallel calls share nothing; interleaving is the service's concern.
- **Cancellation and timeout**: The client has no cancellation or timeout logic of its own; a cancelled task behaves as the transport does.
- **Offline or unreachable service**: Surfaces as the transport's thrown error; there is no cached or degraded answer.
- **Idempotency**: Each call sends one request with no idempotency key; whether a repeated `modifyLabels`, `moveMessages` or `syncNow` is safe is decided by the service, not by this file.
- **Unvalidated dates**: `since` and `until` pass through as text; the command-line and MCP front ends validate them before building a filter (see the [MailCommandSupport](cookbook:3d12c073-edc3-44fb-a988-5edec20575e0) recipe).

