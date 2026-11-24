
**Decision**: `syncNow` has no deadline while every other request, and bytes that are not a request, keep `callTimeout`.
**Rationale**: A sync answers when it ends, joins one already running, and is paced at about 40 messages a second, so a large first sync can outlast any fixed deadline while the daemon is healthy. A dead daemon still ends the call through the dropped connection.
**Approved**: pending

**Decision**: `callTimeout` is 360 s.
**Rationale**: It must exceed the SDK's 300 s cap on a browser sign-in, which runs inside the daemon while the call waits (stated on `callTimeout` in `MailDaemonTransport.swift`).
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
**Rationale**: Both the host's status panel and its command-line tool show the same sentence; the source does not externalise it. A port that needs localization must replace them.
**Approved**: pending

**Decision**: A cancelled call is not special-cased: it is reported through `onFailure` and `classify` like any other error.
**Rationale**: The transport has no way to know why the host's `call` was cancelled, and the host's `classify` already owns the mapping from errors to sentences; a user who cancels may therefore see a `cannot reach <daemonName>` sentence unless the host's `classify` maps cancellation to something quieter.
**Approved**: pending

**Decision**: The failure sentences are part of the cross-platform contract, except the code-signing hint in the connection-dropped sentence.
**Rationale**: Every host and every port shows the same wording for the same failure, so the sentences are tested as exact text. The hint ("signed by the same team as this tool") only makes sense where a daemon connection is checked by code signing, so a port without that check MAY replace the parenthetical.
**Approved**: pending
