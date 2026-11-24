
`ADHClient` is the entry point to the Agentic Developer Hub API — a thin
façade over the generated `Client` from swift-openapi-runtime /
swift-openapi-urlsession. It wires one of two `APITransport` seams (Direct,
straight to the backend over HTTPS; Daemon, HTTP to a local `adhd` daemon —
which does not exist yet, per `DaemonContract`'s own doc comment) to exactly
one `ClientMiddleware`: the bearer-only `AuthenticationMiddleware` or the
bearer-plus-refresh-and-retry `SessionRefreshMiddleware`. The generated
client is exposed directly as `api`; consumers call any operation the
OpenAPI document describes through it (e.g. `client.api.getHealth()`).
`ADHClient+Raw.swift` extends the same façade with
`rawJSON(method:path:query:body:headers:)`, an escape hatch that runs an
arbitrary un-generated request through the identical transport-and-middleware
pipeline, for backend routes the OpenAPI document does not describe or
describes stalely.

This recipe covers exactly `ADHClient.swift` and `ADHClient+Raw.swift`
(`packages/apple/AgenticDeveloperHubClient/Sources/`). `AuthenticationMiddleware`,
`SessionRefreshMiddleware`, `RefreshCoordinator`, `CredentialStore`,
`SessionStore`, `Credentials`, `Session`, `KeychainHelper`, and the
`ADHClient+Auth.swift` / `ADHClient+Session.swift` convenience wrappers
(`login`, `signIn`, `signOut`, and the rest) are `hub-client-auth`'s
contract — they are referenced here only where `ADHClient` composes or calls
into them. `APITransport`, `DaemonContract`, and `TransportResolver` are
`hub-client-transport`'s contract — referenced here only where `ADHClient`'s
factories select between them.

