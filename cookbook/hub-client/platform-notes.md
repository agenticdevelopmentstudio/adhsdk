
- **SwiftUI** (source platform — apple, `macOS 14.0` / `iOS 17.0`, one
  multi-destination target): `ADHClient.swift`, `ADHClient+Raw.swift`
  (`packages/apple/AgenticDeveloperHubClient/Sources/`) and their tests,
  `ADHClientWiringTests.swift`, `RawJSONTests.swift`
  (`.../Tests/AgenticDeveloperHubClientTests/`, using `MockClientTransport`).
  Built on the generated swift-openapi-runtime `Client` /
  `ClientMiddleware` / `ClientTransport` types, `HTTPTypes`'s `HTTPRequest` /
  `HTTPResponse` / `HTTPField`, a `Sendable` value type, and the sibling
  `APITransport` / `TransportResolver` (`hub-client-transport`) and
  `CredentialStore` / `SessionStore` / `AuthenticationMiddleware` /
  `SessionRefreshMiddleware` (`hub-client-auth`) types.
- **Compose** (Android/Kotlin): start from a generated OpenAPI client (or a
  hand-rolled `OkHttpClient` / Ktor `HttpClient` wrapper) for the typed
  surface `api` exposes here, a small façade class mirroring `ADHClient`'s
  two constructors (bearer-only vs. session-backed, selecting which auth
  interceptor to install), and a `suspend fun rawJson(method, path, query, body, headers)`
  mirroring `rawJSON`'s contract — leading-slash validation, sorted
  percent-encoded query, default `Accept` / `Content-Type`, and a 16 MiB
  response-body cap.
- **React/Web**: start from the generated OpenAPI TypeScript client (or
  `fetch`) for the typed surface, a small façade module exposing the same
  two construction shapes, and an `async function rawJson(...)` mirroring
  the same query-encoding, header-override, and cap contract; browser
  `fetch` has no built-in response-size limit, so a port must enforce the 16
  MiB cap itself while reading the body.
- **AppKit / UIKit**: no change from the SwiftUI bullet — `ADHClient` has no
  UI layer; both AppKit and UIKit hosts consume the same
  `AgenticDeveloperHubClient` package target unmodified.
- **WinUI 3**: start from the nearest .NET OpenAPI-generated client (or a
  hand-written typed client) for `api`, a façade class mirroring the two
  constructors, and a `Task<RawResponse> RawJsonAsync(...)` mirroring
  `rawJSON` — `HttpRequestMessage` / `HttpResponseMessage` in place of
  `HTTPRequest` / `HTTPResponse`, `System.Text.Json` for
  `RawResponse.Decode<T>()`, and a manual read-loop (or
  `HttpClient.MaxResponseContentBufferSize`, which throws
  `HttpRequestException` rather than a dedicated typed exception) to
  enforce the 16 MiB response cap.

