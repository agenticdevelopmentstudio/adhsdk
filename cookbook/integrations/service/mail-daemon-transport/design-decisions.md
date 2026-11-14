
**Decision**: `syncNow` has no deadline while every other request, and bytes that are not a request, keep `callTimeout`.
**Rationale**: A sync answers when it ends, joins one already running, and is paced at about 40 messages a second, so a large first sync can outlast any fixed deadline while the daemon is healthy. A dead daemon still ends the call through the dropped connection.
**Approved**: pending

**Decision**: `callTimeout` is 360 s.
**Rationale**: It must exceed the SDK's 300 s cap on a browser sign-in, which runs inside the daemon while the call waits.
**Approved**: pending

**Decision**: Nothing is retried.
**Rationale**: `signIn` opens a browser and `modifyLabels` writes to Gmail; a retry after a timeout could do either twice.
**Approved**: pending

**Decision**: An empty reply is an error, `<daemonName> dropped the reply`.
**Rationale**: Zero bytes cannot be a `MailResponse`; reporting it here gives the same wording to every host rather than a decode error later.
**Approved**: pending

**Decision**: The host classifies its own IPC errors into `MailTransportFailure`, and `onFailure` sees the raw error first.
**Rationale**: The wording stays in one place whatever the transport is, while the host keeps the underlying error for its own logs.
**Approved**: pending

**Decision**: Failure sentences are hardcoded English with the daemon name interpolated.
**Rationale**: Both the host's panel and its command-line tool show the same sentence; the source does not externalise it. A port that needs localization must replace them.
**Approved**: pending

