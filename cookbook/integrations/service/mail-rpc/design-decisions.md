
**Decision**: `notFound` rides inside `.failure` as an optional flag instead of being its own `MailResponse` case.
**Rationale**: The type's comment says a client built before the flag still decodes the reply and shows the message; a new case would make an older client fail to decode it.
**Approved**: pending

**Decision**: The page carries `appliedAnyLabels` and `appliedQuery`, and `MailClient.messages` throws when a flag the request needed is false.
**Rationale**: An older service decodes the filter without the new fields and lists everything; its reply omits the flags, which decode as false, so the client can tell the filter was ignored and refuses a wrong answer rather than showing it.
**Approved**: pending

**Decision**: The client turns the text `bad request` from `getThread` into "too old to show threads".
**Rationale**: A service built before threads cannot decode the request and answers `bad request`; the client is the only place that knows which request was sent. The match is on the exact text, so a different failure is passed through.
**Approved**: pending

**Decision**: `MailMessageFilter` decodes leniently, with only `account` required, and clamps `limit` both in the initializer and in a `didSet`.
**Rationale**: A caller or tool can send a short filter, and a limit outside 1 through 500 can never reach the service. A `didSet` does not run inside an initializer, so the initializer clamps on its own.
**Approved**: pending

**Decision**: `isMailboxAccess` is an exhaustive switch with no default.
**Rationale**: A host gates its non-UI clients on this flag, so a new request must be placed on one side before the code compiles.
**Approved**: pending

**Decision**: `clientSecretSuffix` shows the last 5 characters only when at least 15 characters exist.
**Rationale**: The user can tell which secret is stored, while at least twice as many characters stay hidden; a short secret shows nothing.
**Approved**: pending

**Decision**: The older-service error messages end with "restart it and try again".
**Rationale**: The source words them that way for a service that predates a field; the likely cause is a daemon still running from before an upgrade.
**Approved**: pending

**Decision**: The client sets no timeout, retry or cancellation, and signs no request.
**Rationale**: The transport is injected and may be XPC, a socket or in-process, so these concerns stay with the transport; the source leaves them out, and this recipe records that as the contract.
**Approved**: pending

