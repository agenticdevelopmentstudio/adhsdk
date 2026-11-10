
- **SwiftUI** (source platform — apple, `macOS 14.0` / `iOS 17.0`, one
  multi-destination target): `ADHSyncAPI.swift`
  (`packages/apple/AgenticDeveloperHubClient/Sources/Sync/ADHSyncAPI.swift`)
  and its tests, `ADHSyncAPITests.swift`
  (`.../Tests/AgenticDeveloperHubClientTests/`, using `StubURLProtocol`).
  Built on `URLSession`/`async`/`await` directly, importing
  `FoundationEssentials` where available
  (`#if canImport(FoundationEssentials)`), a `Sendable` value type, and the
  sibling `CredentialProvider`/`Credentials` types under `Auth/`.
- **Compose** (Android/Kotlin): start from `OkHttpClient` (or Ktor's
  `HttpClient`) for the two requests, a pair of `kotlinx.coroutines`
  `suspend fun`s mirroring `pull`/`push`, and a sealed interface
  (`Unauthorized` / `ResyncRequired` / `Http(code: Int)` /
  `Transport(message: String)`) matching `Failure`'s four cases exactly.
  Read the bearer token from an injected credential interface on every
  call — the same way `credentials.currentCredentials()` is read fresh
  inside `perform` — rather than capturing it once at construction.
- **React/Web**: start from `fetch` (or the project's existing HTTP
  wrapper) with two `async` functions mirroring `pull`/`push`, a
  discriminated union mirroring `Failure` (`{ kind: "unauthorized" }`,
  `{ kind: "resyncRequired" }`, `{ kind: "http", status: number }`,
  `{ kind: "transport", message: string }`), and a credential accessor
  called at request time rather than captured once.
- **AppKit / UIKit**: no change from the SwiftUI bullet — `ADHSyncAPI` has
  no UI layer; both AppKit and UIKit hosts consume the same
  `AgenticDeveloperHubClient` package target unmodified.
- **WinUI 3**: start from `System.Net.Http.HttpClient` for the two calls
  (`GetAsync("sync/pull?...")`, `PostAsync("sync/push", ...)`), reaching for
  `System.Text.Json` only if a port chooses to decode — this source does
  not — and `Task`/`async`/`await` for the asynchronous surface. Model
  `Failure` as four small exception types or a discriminated result
  (`UnauthorizedSyncException`, `ResyncRequiredSyncException`,
  `HttpSyncException(int statusCode)`, `TransportSyncException(string message)`)
  thrown from the two methods. Read the bearer token from an injected
  `ICredentialProvider.CurrentCredentials()` on every request — never
  cached on the client object, mirroring `credentials.currentCredentials()`
  being called inside `perform` rather than once in the constructor — and
  attach it via
  `request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token)`.
  Credential storage (a DPAPI-backed store, mirroring
  `KeychainCredentialStore`) belongs to whatever `ICredentialProvider`
  implementation a Windows port pairs with this client, not to the client
  itself.

