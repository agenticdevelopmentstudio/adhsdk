# AgenticDeveloperHubClient

A Swift client for the **entire** `api.agenticdeveloperhub.com` REST API, callable
through either of two interchangeable transports chosen at runtime:

1. **Direct** — HTTPS straight to `https://api.agenticdeveloperhub.com`.
2. **Daemon** — HTTP to the local `adhd` daemon (a transparent caching
   reverse-proxy) at `http://127.0.0.1:22850`.

The typed surface is generated from the backend's Stripe-style `/v1` OpenAPI
document (`openapi.v1.json`) with Apple's [swift-openapi-generator]; the transports are `ClientTransport` conformers, so the
generated client is byte-identical across both paths. A resolver picks the daemon
when it is reachable and falls back to Direct otherwise — the client always works.

> macOS 14+, Swift 6 (strict concurrency). This is the **client library only**.
> The `adhd` daemon, its cache, and the sync engine are a separate effort; this
> package defines the contract that daemon must honor (`DaemonContract.swift`).

## Quick start

```swift
import AgenticDeveloperHubClient

// Let the resolver choose Daemon (if up) or Direct (fallback).
let client = await ADHClient.resolved()

// Authenticate — the JWT is persisted in the Keychain and forwarded on every call.
try await client.login(email: "me@example.com", password: "…")

// Call any operation on the full generated API surface.
let health = try await client.api.getHealth()
let me = try await client.api.getV1Account()
```

Force a transport explicitly when you don't want resolution:

```swift
let direct = ADHClient.direct()                       // always HTTPS to the backend
let daemon = ADHClient.daemon()                        // assumes the daemon is up
let forced = await ADHClient.resolved(using: TransportResolver(override: .forceDirect))
```

## Layers

| Type | Role |
|------|------|
| `ADHClient` | Façade. Exposes the generated client as `.api` and wires transport + auth. |
| `APITransport` | `(serverURL, transport)` pair. Factories: `.direct(…)`, `.daemon(…)`. |
| `TransportResolver` | Probes daemon `GET /health`; caches the `.direct`/`.daemon` decision. |
| `AuthenticationMiddleware` | Injects `Authorization: Bearer <token>` on every request (both transports). |
| `CredentialStore` | `KeychainCredentialStore` (default) or `InMemoryCredentialStore` (tests). |
| `DaemonContract` | The HTTP contract the future `adhd` daemon must implement. |

Authentication is a `ClientMiddleware` rather than baked into a transport, so it
stays orthogonal to transport selection. The token is read from the
`CredentialProvider` at *send time*, so rotation takes effect without rebuilding
the client.

### Auth convenience wrappers

`login` / `createAPIToken` / `adopt` / `logout` are thin ergonomics over the
generated `/v1` ops (`client.api.postV1AuthSessions`, `postV1ApiKeys`, …):

- `login(email:password:)` persists the returned JWT.
- `createAPIToken(name:expiresAt:)` returns the raw token but **does not** persist
  it — minting a token must not silently swap your session credential. Call
  `adopt(_:)` to switch the client to a credential, `logout()` to clear it.

## Sessions (native apps)

`ADHClient(transport:session:onSessionExpired:)` installs `SessionRefreshMiddleware`
instead of the bearer-only `AuthenticationMiddleware`:

- `Session` = `Credentials` + optional refresh token; `SessionStore` refines
  `CredentialStore` (`KeychainSessionStore`, `InMemorySessionStore`).
- On a 401 for a JWT session the middleware `POST /v1/auth/sessions/refresh {refreshToken}`,
  saves the rotated pair, and retries the request once. Only an explicit 401/403
  from refresh clears the session (and calls `onSessionExpired`); 5xx/transport
  failures keep it. Login-family operations and refresh itself are exempt.
- Sign-in flows: `signIn(email:password:) -> SignInOutcome`, `completeMfa`,
  `sendMfaSms`, `passkeyOptions`/`completePasskey`, `mfaPasskeyOptions`/`completeMfaPasskey`, `exchangeOAuthCode`,
  `signOut()` (revokes, then clears), `currentUser()`.
- `rawJSON(method:path:query:body:)` sends a route through the same middleware
  chain without a generated operation; use it only for routes missing from
  `openapi.v1.json`, or whose documented schema cannot express the real request.
  Today there are three such cases:
  - `POST /v1/auth/sessions/revoke`, which the backend accepts with a
    `{"refreshToken": …}` body while the document describes it as bodiless — so
    `signOut()` sends it raw (and the refresh middleware exempts it from
    refresh-and-retry).
  - `POST /v1/auth/sessions/refresh`, whose `{"refreshToken": …}` body is
    likewise undeclared; the refresh middleware sends it raw.
  - The OAuth code exchange behind `exchangeOAuthCode`, which the `/v1` document
    does not describe at all.

## Regenerating the client

The `/v1` OpenAPI spec snapshot (`openapi.v1.json`) and the generated sources
(`Sources/Generated/`) are **committed**; regeneration is an explicit, reviewable
step (not a per-build plugin — build-tool plugins are unreliable inside an
XcodeGen `.xcodeproj`).

```bash
# Regenerate from the committed openapi.v1.json snapshot:
python3 scripts/generate.py

# Or refresh the snapshot from the live backend (GET /v1/openapi.json) first:
python3 scripts/generate.py --refresh-spec

# Or generate from a locally dumped spec, which refreshes the snapshot:
python3 scripts/generate.py --spec /path/to/openapi.v1.json
```

`generate.py` clones swift-openapi-generator `1.12.2` into a gitignored `.tooling/`
and generates both targets from the snapshot as-is (no spec patches):
`Sources/Generated/{Client,Types}.swift` for the full client and
`AuthSources/Generated/{HubAuthClient,Types}.swift` for the auth-only one. Commit
the diff. If the spec is unchanged, re-running produces no diff.

The `/v1` wire is snake_case, with unix-seconds `created`/`updated`, lists in a
`{object: "list", data, has_more, url}` envelope paged by `limit` and
`starting_after`, and every error as `{error: {type, code?, message}}`
(`Components.Schemas.StripeError`).

**After adding/removing any source or test file, re-run `xcodegen generate`** —
XcodeGen enumerates files at generation time, so new files are invisible to the
build until the project is regenerated.

```bash
xcodegen generate
xcodebuild -scheme AgenticDeveloperHubClient build test   # or: cc-xcbuild AgenticDeveloperHubClient --test
```

## The daemon contract

`DaemonContract.swift` is the single source of truth for what the future `adhd`
daemon must implement and what `MockDaemonServer` reproduces in tests:

- Listens on a **fixed loopback port `22850`** (`DaemonContract.port`).
- Answers `GET /health` with `200` and a `HealthStatus` JSON body when healthy.
- Accepts every request other than its own `/health` **verbatim** — same method,
  headers (including `Authorization: Bearer`), body, and response semantics as the
  backend — so the generated client is identical whether it points at the backend
  or the daemon.
- The daemon does **not** own auth; the client forwards the bearer on both paths.

## Testing

Swift Testing, macOS unit-test bundle. The default suite is **hermetic and
offline**:

- `MockClientTransport` validates codegen wiring and auth injection.
- `DirectTransportTests` exercises a real `URLSessionTransport` via a stubbed
  `URLProtocol` (no packets leave the machine).
- `MockDaemonServer` (in-process `NWListener` loopback) exercises the Daemon
  transport and the resolver's up/down paths over a real socket.

One opt-in integration test hits the live backend's `/health`; it is skipped
unless enabled:

```bash
ADH_LIVE_TESTS=1 xcodebuild -scheme AgenticDeveloperHubClient test
```

[swift-openapi-generator]: https://github.com/apple/swift-openapi-generator
