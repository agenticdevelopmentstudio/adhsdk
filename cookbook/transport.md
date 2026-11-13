---
id: d9dfd305-be0d-4770-9db8-43a35218c8b7
title: "Hub Client Transport"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-09-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Direct-vs-Daemon transport contract for the hub client: APITransport, DaemonContract, and TransportResolver's probe-and-cache selection."
platforms:
  - swift
  - macos
  - ios
tags:
  - networking
  - transport
  - daemon
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Hub Client Transport

## Overview

Hub Client Transport is the seam `ADHClient` (the Agentic Developer Hub API
client) builds its generated `Client` from. It has no visual surface: it is a
value type (`APITransport`), a namespace of constants (`DaemonContract`), and
a decision actor (`TransportResolver`) that together decide, and cache,
whether a request goes straight to the backend over HTTPS ("Direct") or to a
local caching proxy daemon over loopback HTTP ("Daemon").

The three source files, all under the hub client package's
`Sources/Transport/`, are:

- `APITransport.swift` — `TransportKind`, `APITransport`, and the
  `direct(serverURL:transport:)` / `daemon(port:transport:)` factories.
- `DaemonContract.swift` — the constants and wire shape (`HealthStatus`)
  that define what a conforming local daemon must implement.
- `TransportResolver.swift` — the `actor` that probes the daemon's
  `GET /health` and caches the resulting `TransportKind`.

Because swift-openapi-runtime takes the server URL on the generated `Client`
itself (not on the transport), Direct and Daemon are fully captured by the
`(serverURL, transport)` pair `APITransport` carries — the generated `Client`
is identical either way. `TransportResolver` never launches the daemon; it
only detects one that is already running, with Direct as the always-available
fallback. `ADHClient` (`Sources/ADHClient.swift`, outside this component's
file set) is the consumer: `ADHClient.resolved(using:credentials:)` asks a
`TransportResolver` for a `TransportKind` and rebuilds a fresh `APITransport`
(`.daemon(port:)` or `.direct()`) from that decision on every call.

## Behavioral Requirements

### TransportKind & APITransport

- **transport-kind-cases**: `TransportKind` MUST be a `String`-backed,
  `Sendable` enum with exactly two cases, `direct` and `daemon`, whose raw
  values equal their case names (`"direct"`/`"daemon"`).
- **api-transport-shape**: `APITransport` MUST be a `Sendable` struct
  exposing exactly three public, immutable fields — `kind: TransportKind`,
  `serverURL: URL`, `transport: any ClientTransport` — constructible via the
  public `init(kind:serverURL:transport:)`.
- **direct-factory**: `APITransport.direct(serverURL:transport:)` MUST tag
  the result `kind: .direct`, MUST default `serverURL` to
  `DaemonContract.backendURL`, and MUST default `transport` to a plain
  `URLSessionTransport()`.
- **daemon-factory**: `APITransport.daemon(port:transport:)` MUST tag the
  result `kind: .daemon`, MUST default `port` to `DaemonContract.port`, MUST
  set `serverURL` to `DaemonContract.daemonURL(port:)`, and MUST default
  `transport` to a fresh value from `makeDaemonURLSessionTransport()`
  whenever the caller passes `transport: nil` (its default).
- **daemon-session-is-ephemeral**: The `URLSessionTransport` that
  `makeDaemonURLSessionTransport()` builds MUST use an `.ephemeral`
  `URLSessionConfiguration` (no shared cache or cookies), MUST set
  `waitsForConnectivity = false`, and MUST set
  `timeoutIntervalForRequest = 30` seconds.
- **transport-injectable-for-tests**: Both `direct(serverURL:transport:)`
  and `daemon(port:transport:)` MAY be called with a caller-supplied
  `ClientTransport` in place of the production one, so a test MAY substitute
  a mock transport without changing which `serverURL`/`kind` the factory
  selects.
- **transport-is-the-sole-variation-point**: For a fixed
  `(serverURL, transport)` pair, the generated `Client` an `APITransport`
  value feeds MUST be identical in shape regardless of `kind` — Direct and
  Daemon MUST differ only in which `(serverURL, transport)` pair is supplied,
  never in the request/response types available through it.

### DaemonContract

- **backend-url-constant**: `DaemonContract.backendURL` MUST be a fixed,
  hardcoded `https` production backend base URL — declared as a
  `static let`, never computed or overridable at runtime — and is the
  `Direct` transport's target.
- **daemon-port-constant**: `DaemonContract.port` MUST be the fixed value
  `22850`.
- **daemon-url-construction**: `DaemonContract.daemonURL(port:)` MUST
  construct `http://127.0.0.1:<port>` for the given `port`, defaulting
  `port` to `DaemonContract.port` when omitted.
- **health-path-constant**: `DaemonContract.healthPath` MUST be the literal
  string `/health`.
- **health-url-construction**: `DaemonContract.healthURL(port:)` MUST equal
  `daemonURL(port:)` with the health path's leading `/` stripped and appended
  as a path component — i.e. `http://127.0.0.1:<port>/health`.
- **health-status-decoding**: `DaemonContract.HealthStatus` MUST decode a
  JSON object whose `status` field is a required `String` and whose
  `version` field is an OPTIONAL `String?`, and MUST ignore any other keys
  present in the decoded object.
- **daemon-request-forwarding-contract**: A conforming daemon MUST accept
  every request other than its own `GET /health` verbatim — same HTTP
  method, headers (including any `Authorization: Bearer` header already
  attached by the caller's middleware), body, and response semantics as
  `DaemonContract.backendURL` — so that a `Client` built against the daemon
  behaves identically to one built against the backend.
- **daemon-health-contract**: A conforming daemon MUST answer `GET /health`
  with HTTP `200` and a JSON body compatible with `HealthStatus` when it is
  healthy.

### TransportResolver — decision and caching

- **resolver-is-an-actor**: `TransportResolver` MUST be declared as an
  `actor`, so its stored `cached` value MUST be read and written only from
  within the actor's isolation domain.
- **resolver-nonisolated-config**: `override` and `port` MUST be exposed as
  `nonisolated let` properties, so a caller MAY read the resolver's
  configuration synchronously, from any isolation domain, without `await`.
- **forced-override-skips-probe**: When constructed with
  `override: .forceDirect`, `resolve()`/`reresolve()` MUST return `.direct`
  without invoking the probe; when constructed with `override: .forceDaemon`,
  they MUST return `.daemon` without invoking the probe.
- **auto-override-probes**: When constructed with `override: .auto`,
  `resolve()`/`reresolve()` MUST return `.daemon` when the probe applied to
  `DaemonContract.healthURL(port: self.port)` returns `true`, and MUST
  return `.direct` when it returns `false`.
- **resolve-serves-from-cache**: `resolve()` MUST return the existing
  `cached` `TransportKind` without invoking the probe (or re-applying the
  override) once a prior `resolve()`/`reresolve()` call has already produced
  one.
- **reresolve-always-recomputes**: `reresolve()` MUST unconditionally re-run
  the override/probe decision — even when a cached value already exists —
  and MUST overwrite `cached` with the new result.
- **cached-kind-reflects-last-decision**: `cachedKind` MUST return `nil`
  before `resolve()`/`reresolve()` has ever completed, and MUST return the
  `TransportKind` from the most recently completed `resolve()`/`reresolve()`
  call afterward.
- **resolver-never-launches-daemon**: `TransportResolver` MUST only detect
  whether a daemon is already listening on `port`; it MUST NOT start,
  install, or otherwise launch a daemon process.

### TransportResolver — health probe

- **probe-issues-single-bounded-get**: The production probe (used whenever
  no test probe is injected) MUST issue exactly one `GET` request to the
  given URL, using an `.ephemeral` `URLSessionConfiguration` with
  `waitsForConnectivity = false` and both `timeoutIntervalForRequest` and
  `timeoutIntervalForResource` set to the resolver's `probeTimeout`.
- **probe-success-is-status-200-only**: The production probe MUST report
  success (`true`) if and only if the response is an `HTTPURLResponse`
  whose `statusCode` is exactly `200`; it MUST NOT inspect or decode the
  response body to reach this decision.
- **probe-failure-collapses-to-false**: The production probe MUST report
  failure (`false`), rather than throwing, when the request throws for any
  reason (refused connection, DNS failure, timeout, or any other error) —
  the specific cause is not distinguished or surfaced.
- **default-probe-timeout**: `TransportResolver.init(override:port:probeTimeout:)`
  MUST default `probeTimeout` to `2` seconds and MUST default `port` to
  `DaemonContract.port`.
- **probe-injectable-for-tests**: `TransportResolver` MUST expose an
  `init(override:port:probe:)` initializer accepting a caller-supplied
  `@Sendable (URL) async -> Bool` closure in place of the production probe,
  for hermetic testing.
- **user-defaults-override**: `TransportResolver.fromUserDefaults(_:port:)`
  MUST read the boolean `UserDefaults` key `"useDirectMode"` and MUST
  construct the resolver with `override: .forceDirect` when that value is
  `true`, or `override: .auto` otherwise (including when the key is absent,
  since `UserDefaults.bool(forKey:)` defaults an absent key to `false`).

## Appearance

Not applicable — this is a networking transport-selection component, not a
visual component.

## States

Not applicable — this is a networking transport-selection component, not a
visual component. Its one runtime state machine (uncached / cached-direct /
cached-daemon, driven by `TransportResolver.cachedKind`) is specified under
Behavioral Requirements ("TransportResolver — decision and caching") rather
than as a visual-state table.

## Accessibility

Not applicable — this is a networking transport-selection component, not a
visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hct-001 | forced-override-skips-probe, probe-injectable-for-tests | `TransportResolver(override: .forceDirect, port: p, probe: <counting stub returning true>)`; call `resolve()` | Returns `.direct`; the stub probe is invoked 0 times |
| hct-002 | forced-override-skips-probe, probe-injectable-for-tests | `TransportResolver(override: .forceDaemon, port: p, probe: <counting stub returning false>)`; call `resolve()` | Returns `.daemon`; the stub probe is invoked 0 times |
| hct-003 | auto-override-probes, probe-issues-single-bounded-get | `TransportResolver(override: .auto, port: p, probe: <stub returning true>)`; call `resolve()` | Returns `.daemon`; the stub is invoked once with `DaemonContract.healthURL(port: p)` |
| hct-004 | auto-override-probes | `TransportResolver(override: .auto, port: p, probe: <stub returning false>)`; call `resolve()` | Returns `.direct` |
| hct-005 | resolve-serves-from-cache | Resolver as in hct-003; call `resolve()` twice in sequence | Both calls return `.daemon`; the stub probe's call count stays at 1 |
| hct-006 | reresolve-always-recomputes, cached-kind-reflects-last-decision | Continuing hct-005, call `reresolve()` | Returns `.daemon`; stub call count becomes 2; `cachedKind == .daemon` |
| hct-007 | user-defaults-override | `UserDefaults` suite with `useDirectMode = true`; call `TransportResolver.fromUserDefaults(defaults)` | Result's `override == .forceDirect` |
| hct-008 | user-defaults-override | Same suite with `useDirectMode = false`; call `TransportResolver.fromUserDefaults(defaults)` | Result's `override == .auto` |
| hct-009 | probe-success-is-status-200-only, daemon-health-contract | Start `MockDaemonServer` on an OS-assigned port; `TransportResolver(override: .auto, port: <that port>, probeTimeout: 2)`; call `resolve()` | Returns `.daemon` (the mock's default handler answers `GET /health` with `200` and `{"status":"ok","version":"mock"}`) |
| hct-010 | probe-failure-collapses-to-false | Start `MockDaemonServer`, learn its port, then `stop()` it; `TransportResolver(override: .auto, port: <dead port>, probeTimeout: 1)`; call `resolve()` | Returns `.direct`; no error is thrown to the caller |
| hct-011 | resolver-never-launches-daemon | Continuing hct-010, after `resolve()` returns | The dead port still has no listener — nothing in the resolver started one |
| hct-012 | daemon-factory, daemon-session-is-ephemeral, daemon-request-forwarding-contract | `ADHClient(transport: .daemon(port: <live MockDaemonServer port>), credentials: <token "tok-daemon">)`; call `adh.api.getHealth()` | The call round-trips over loopback and decodes the daemon's `200`; `adh.transportKind == .daemon` |
| hct-013 | daemon-request-forwarding-contract, health-path-constant | Continuing hct-012 with token `"tok-verbatim"`; inspect the last request `MockDaemonServer` recorded | `method == "GET"`, `path == DaemonContract.healthPath`, `headers["authorization"] == "Bearer tok-verbatim"` |
| hct-014 | direct-factory, api-transport-shape | `ADHClient(transport: .direct(transport: <URLSessionTransport over StubURLProtocol returning 200>), credentials: <token "tok-direct">)`; call `adh.api.getHealth()` | Captured request URL equals `DaemonContract.backendURL` with the health path appended, method `GET`, `Authorization == "Bearer tok-direct"`; the `200` response decodes |
| hct-015 | health-url-construction, health-path-constant, daemon-port-constant | `DaemonContract.healthURL(port: 22850)` | `== URL(string: "http://127.0.0.1:22850/health")!` |
| hct-016 | daemon-url-construction, backend-url-constant | `DaemonContract.daemonURL(port: 9999)`, `DaemonContract.backendURL` | `daemonURL == URL(string: "http://127.0.0.1:9999")!`; `backendURL` is a fixed `https` URL literal (a `static let` constant, not derived from `port` or any environment input) |
| hct-017 | health-status-decoding | Decode `{"status":"ok","version":"mock","extra":"ignored"}` as `HealthStatus` | Decodes successfully; `status == "ok"`, `version == "mock"`; the unknown `extra` key does not fail decoding |
| hct-018 | health-status-decoding | Decode `{"status":"ok"}` (no `version` key) as `HealthStatus` | Decodes successfully; `status == "ok"`, `version == nil` |
| hct-019 | transport-kind-cases | `TransportKind(rawValue: "direct")`, `TransportKind(rawValue: "daemon")` | Both initialize to the matching case; `TransportKind.direct.rawValue == "direct"`, `TransportKind.daemon.rawValue == "daemon"` |
| hct-020 | transport-is-the-sole-variation-point, transport-injectable-for-tests | Build `ADHClient`s from `.direct(transport: mockA)` and `.daemon(port: p, transport: mockB)` | Each client dispatches through the supplied mock transport (no real network call); the two clients differ only in `serverURL`/`kind`, not in the operations `api` exposes |
| hct-021 | resolver-is-an-actor, resolver-nonisolated-config | From a non-actor-isolated context, read `resolver.override` and `resolver.port` on a constructed `TransportResolver` | Both reads compile and return the constructor-supplied values synchronously, without `await` |
| hct-022 | default-probe-timeout | `TransportResolver(override: .auto, port: <a port with nothing listening>)` constructed with no `probeTimeout` argument; call `resolve()` and measure elapsed time | Returns `.direct`; elapsed time is milliseconds, not close to `2` seconds — a refused loopback connection fails at once and is never bound by `probeTimeout`, so this only confirms the default compiles and resolves, not that it equals `2` (only a non-responding, black-holed target would actually exercise the timeout, and the source has no test for that case) |

## Edge Cases

- **`transport: nil` passed to `daemon(port:transport:)`** (null/empty
  input — MUST): the default path MUST build a fresh
  `makeDaemonURLSessionTransport()` rather than reusing any transport
  instance from a prior call — each call that omits `transport` gets its own
  `URLSession`.
- **Malformed or out-of-range `port`** (boundary values): `daemonURL(port:)`
  and `healthURL(port:)` build their URL via
  `URL(string: "http://127.0.0.1:\(port)")!`, force-unwrapping the result;
  `port` is an unconstrained `Int` accepted by `TransportResolver.init`,
  `APITransport.daemon(port:)`, and `fromUserDefaults(port:)` alike, with no
  range or sign check anywhere in the given sources — see the open question
  on port-validation.
- **port-validation**: NEEDS REVIEW: Not implemented in source. No range or sign check on `port` guards the force-unwrapped `URL(string: "http://127.0.0.1:\(port)")!` in `daemonURL(port:)`/`healthURL(port:)`, so a negative or larger-than-`65535` port crashes rather than returning an error the caller can handle; `TransportResolverTests.swift` has no test for an out-of-range port, so nothing in the given sources defines the intended failure mode — resolvable by whoever decides whether an invalid port should throw, precondition, or stay an undocumented caller contract.
- **`probeTimeout <= 0`** (boundary values): `TransportResolver.init` and
  the production probe pass `probeTimeout` straight through to
  `URLSessionConfiguration.timeoutIntervalForRequest`/
  `timeoutIntervalForResource` with no validation; the given sources define
  no minimum, so the resulting behavior for a non-positive timeout is
  whatever `URLSession` itself does with that value — not defined in
  `TransportResolver.swift`.
- **Two `resolve()` calls racing before either has cached a decision**
  (concurrent access): `resolve()`'s cache check
  (`if let cached { return cached }`) happens synchronously, but the
  `await reresolve()` it falls through to is a suspension point; because
  `TransportResolver` is a (reentrant) actor, two overlapping first-time
  `resolve()` calls can each observe `cached == nil` before either has
  written a result, so each independently calls `reresolve()` and launches
  its own probe rather than sharing one in flight — see the open question
  on concurrent-resolve.
- **concurrent-resolve**: NEEDS REVIEW: Not implemented in source. No in-flight decision (e.g. a stored `Task<TransportKind, Never>` a second caller awaits instead of re-probing) coalesces concurrent first-time `resolve()` calls into a single probe and cache write; `TransportResolverTests.swift` exercises only sequential `resolve()` calls, so nothing in the given sources shows an intended de-duplication rule — resolvable by whoever adds a concurrent-resolve test and, if the duplicate probing is undesired, an in-flight cache.
- **Two `reresolve()` calls racing** (concurrent access — MUST, not a gap):
  the same reentrancy applies to `reresolve()`, but it is not a gap there —
  `reresolve()`'s own contract ("probe again and replace the cached
  decision") never claims exclusivity between overlapping calls, unlike
  `resolve()`'s cache-reuse promise. Two overlapping `reresolve()` calls
  MUST each run the override/probe decision independently, and whichever
  finishes last MUST be the value left in `cached` (last-write-wins).
- **Daemon reachable but returns a non-`200` status** (error state — MUST):
  the probe treats any non-`200` status (`404`, `500`, etc.) exactly like a
  thrown error or timeout — indistinguishably folded into `false` — so
  `.auto` MUST resolve `.direct` in every non-`200` case, per
  probe-success-is-status-200-only/probe-failure-collapses-to-false; this is
  expected behavior, not a gap, since the source draws no distinction
  between "reachable but unhealthy" and "unreachable."
- **Daemon unreachable, connection refused, DNS failure, or probe timeout**
  (offline/disconnected — MUST): all four collapse to the same `false`
  outcome via the probe's `catch`, per probe-failure-collapses-to-false;
  `.auto` MUST resolve `.direct`. Per the source's own doc comment on
  `TransportResolver`, "Direct is the guaranteed fallback, so the client
  always works." No retry or backoff is attempted by the probe itself; a
  caller that wants the daemon re-checked later MUST call `reresolve()`
  again.
- **Cancellation of the surrounding `Task` during a probe** (MUST): the
  given sources define no explicit cancellation handling in
  `TransportResolver`; Swift's standard cooperative cancellation propagates
  to the awaited `session.data(for:)` call inside the probe closure, which
  is caught by the probe's own `catch` and folded into `false` like any
  other thrown error — the resolver never distinguishes "cancelled" from
  "network failure."

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `override` | `TransportResolver.Override` (`.auto` / `.forceDirect` / `.forceDaemon`) | `.auto` | Forces a transport or lets the health probe decide. |
| `port` | `Int` | `DaemonContract.port` (`22850`) | Loopback port the daemon is expected to listen on; feeds `daemonURL(port:)`/`healthURL(port:)` and `APITransport.daemon(port:)`. |
| `probeTimeout` | `TimeInterval` | `2` (seconds) | Bounds the health probe's `timeoutIntervalForRequest`/`timeoutIntervalForResource` before the daemon is treated as down. |
| `probe` | `@Sendable (URL) async -> Bool` (test seam) | The production network probe | Caller-injectable replacement for the real network probe, via `init(override:port:probe:)`. |
| `serverURL` (`APITransport.direct` parameter) | `URL` | `DaemonContract.backendURL` | Overridable backend URL for the Direct path. |
| `transport` (`APITransport.direct`/`daemon` parameter) | `any ClientTransport` / `(any ClientTransport)?` | `URLSessionTransport()` (direct) / `makeDaemonURLSessionTransport()` (daemon) | Overridable client transport, mainly for injecting a mock in tests. |
| `useDirectMode` (`UserDefaults` key, via `fromUserDefaults(_:port:)`) | `Bool` | `false`/absent → `.auto` | User-default escape hatch that forces Direct mode. |

## Deep Linking

Not applicable: none of `APITransport.swift`, `DaemonContract.swift`, or
`TransportResolver.swift` registers or resolves an app URL scheme or
universal link — the URLs they build (`backendURL`, `daemonURL`,
`healthURL`) are outbound API endpoints, not inbound deep links.

## Localization

Not applicable: no user-facing strings appear anywhere in
`APITransport.swift`, `DaemonContract.swift`, or `TransportResolver.swift` —
only URLs, an HTTP header value, and the `"useDirectMode"` `UserDefaults`
key, none of which are displayed or localized text.

## Accessibility Options

Not applicable: this is a networking transport-selection component with no
rendered UI, so Reduce Motion, Increase Contrast, and Differentiate Without
Color have nothing to apply to.

## Feature Flags

Not applicable: `TransportResolver.Override` and the `"useDirectMode"` user
default (captured under Configuration) are operator/test configuration
switches that pick which transport is used — neither is a feature-flag gate
on whether this component itself is enabled.

## Analytics

Not applicable: no analytics or telemetry calls exist in
`APITransport.swift`, `DaemonContract.swift`, or `TransportResolver.swift`.

## Privacy

- **Data collected**: None originates in this component. Transport does not
  read, store, or generate the `Authorization` bearer token; it only carries
  whatever header the caller's attached `ClientMiddleware` (outside this
  component's file set — `AuthenticationMiddleware`/`SessionRefreshMiddleware`
  in `Sources/Auth/`) has already added to the request, verbatim, to
  whichever URL `serverURL` resolves to. Token lifetime, storage, and
  revocation are that middleware/`CredentialStore`'s responsibility, not
  this component's.
- **Storage**: None. `APITransport`/`TransportResolver` hold only an
  in-memory `URL`/`ClientTransport` pair and a cached `TransportKind`;
  nothing here persists to disk.
- **Transmission**: The Direct path transmits over HTTPS to
  `DaemonContract.backendURL`. The Daemon path transmits over plain HTTP,
  but only to `127.0.0.1` (loopback per `daemonURL(port:)`), so those bytes
  never leave the device.
- **Retention**: None beyond the lifetime of the `URLSession` in use. The
  daemon path's session is `.ephemeral` (no shared cache or cookies, per
  daemon-session-is-ephemeral); the direct path's session is
  swift-openapi-urlsession's default `URLSessionTransport()`, whose
  retention this component does not further constrain.

## Logging

`APITransport.swift`, `DaemonContract.swift`, and `TransportResolver.swift`
emit no log calls — no `os_log`, `Logger`, or `print` statement appears in
any of the three files. `TransportResolver.cachedKind` and
`ADHClient.transportKind` (outside this component's file set) expose the
current decision for a caller to log if it chooses to, but no logging
subsystem or category is defined by this source.

## Platform Notes

- **SwiftUI**: The source lives in the hub client package's
  `Sources/Transport/{APITransport,DaemonContract,TransportResolver}.swift`.
  It is UI-framework-agnostic — `APITransport` is a plain `Sendable` struct
  and `TransportResolver` a plain `actor`, with no dependency on SwiftUI. A
  SwiftUI host typically calls `await TransportResolver().resolve()` (or
  `ADHClient.resolved(using:)`) once at app-launch time, from a `.task`
  modifier or an `@Observable` view model's initializer, and stores the
  resulting `ADHClient`/`TransportKind` in state.
- **Compose**: Model `TransportKind` as a two-case `enum class` and
  `APITransport` as a `data class` carrying `kind`, `serverURL: String`
  (or `okhttp3.HttpUrl`), and the chosen HTTP client/interceptor. Port the
  probe with `OkHttpClient`/Ktor's client configured with matching connect
  and read timeouts, and model `TransportResolver` as a class backed by a
  `Mutex` (or a single-threaded `CoroutineDispatcher`) guarding the cached
  `TransportKind` — the direct analogue of the source's actor isolation.
  Use `DataStore`/`SharedPreferences` for the `useDirectMode` equivalent.
- **React/Web**: No TypeScript/web implementation of this component exists
  yet in this repo. A port would use `fetch` with an `AbortController`
  driving the probe's timeout, and a module-level (or class-held) cached
  `TransportKind` guarded by ordinary single-threaded JS execution (no actor
  needed). The Daemon path itself does not translate directly to a browser:
  fetching `http://127.0.0.1:<port>` from an `https://` page is blocked by
  mixed-content and CORS policy in every major browser, so a browser-hosted
  port would need either an HTTPS-fronted local proxy or to drop the Daemon
  path entirely — a genuine platform divergence, not an oversight in this
  recipe.
- **AppKit / UIKit**: Same underlying Swift package as the SwiftUI note
  above — `APITransport`/`TransportResolver` make no distinction between
  SwiftUI and an imperative AppKit/UIKit host. A UIKit/AppKit call site
  awaits `resolve()`/`ADHClient.resolved(using:)` from a `Task` launched in
  `viewDidLoad`/`applicationDidFinishLaunching` and stores the resulting
  client on the owning controller.
- **WinUI 3**: Model `TransportKind` as a two-case `enum`, and `APITransport`
  as a `record` (or plain class) carrying `Kind`, `Uri ServerUrl`, and an
  `HttpClient` (two named/keyed `HttpClient` instances — one for the backend
  base address, one for the loopback daemon base address — mirror
  Direct/Daemon). Use `System.Text.Json` with `JsonSerializerOptions` left at
  its default (which already ignores unknown members, matching
  health-status-decoding) to model `HealthStatus`. Model `TransportResolver`
  as a class exposing `Task<TransportKind> ResolveAsync()`/
  `ReresolveAsync()`, guarding its cached field with a `SemaphoreSlim(1,1)`
  or `lock` — .NET has no actor primitive, so this lock is also the natural
  place to fix the source's unresolved concurrent-`resolve()` race (see
  Edge Cases) by caching the in-flight `Task` itself rather than only the
  completed result. Drive the probe's timeout with a
  `CancellationTokenSource` (`CancelAfter(probeTimeout)`) rather than
  `HttpClient.Timeout`, so a single `HttpClient` instance can serve probes
  with different timeouts. Use
  `Windows.Storage.ApplicationData.Current.LocalSettings` for the
  `useDirectMode` equivalent. `ObservableCollection`/`INotifyPropertyChanged`
  are unnecessary — nothing in the source makes `TransportResolver`'s
  decision observable; a caller reads `CachedKind`/awaits `ResolveAsync()`
  on demand.

## Design Decisions

- **Decision**: The transport chooses between Direct and Daemon by varying
  only `(serverURL, transport)` on an otherwise identical generated
  `Client`, rather than exposing two different client types or APIs.
  **Rationale**: swift-openapi-runtime places the server URL on the `Client`
  itself, not the transport, so `(serverURL, transport)` is already the
  complete seam; keeping `ADHClient.api` a single `Client` type means every
  caller-facing operation works identically regardless of which path was
  chosen.
  **Approved**: pending

- **Decision**: `TransportResolver` only detects whether a daemon is
  already listening; it never starts, installs, or manages the daemon
  process.
  **Rationale**: per the source's own doc comment, Direct is the guaranteed
  fallback, so decoupling detection from process management means the
  client always works even before the daemon (`adhd`) exists or is
  installed — confirmed by `DaemonContract`'s own note that "the real daemon
  does not exist yet."
  **Approved**: pending

- **Decision**: The production probe decides success from the HTTP status
  code alone (`== 200`) and never decodes the response body, even though
  `DaemonContract.HealthStatus` documents the body's wire shape.
  **Rationale**: this keeps the probe's hot path cheap (no JSON parsing) and
  independent of the exact `HealthStatus` payload; `HealthStatus` remains
  the documented contract for the daemon to honor and for any future caller
  that does inspect the body, but `TransportResolver` itself does not need
  to.
  **Approved**: pending

- **Decision**: The Daemon transport builds a dedicated `.ephemeral`
  `URLSession` (no shared cache/cookies, 30s timeout) rather than reusing
  the Direct path's session or `URLSession.shared`.
  **Rationale**: per the factory's doc comment, an ephemeral session "does
  not wait for connectivity since the resolver has already confirmed the
  daemon is up," and avoiding a shared cache/cookie jar keeps loopback
  daemon traffic from interacting with any HTTPS backend session state.
  **Approved**: pending

- **Decision**: Concurrent first-time `resolve()` calls are left able to
  launch duplicate probes (see Edge Cases), and out-of-range `port` values
  are left to crash at a forced URL unwrap rather than being validated.
  **Rationale**: neither is addressed anywhere in
  `TransportResolver.swift`/`DaemonContract.swift`, and neither is exercised
  by `TransportResolverTests.swift`; both are recorded as open questions
  under Edge Cases rather than resolved here, since resolving them would
  mean inventing behavior the source does not define.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |
| [adc.check.security.secure-transport](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0a75f61f-9508-506e-b92e-0f5b29a91c95) | partial | Security |

`separation-of-concerns` passes: `APITransport` (the value type),
`DaemonContract` (the daemon's contract and constants), and
`TransportResolver` (the decision actor) each own exactly one responsibility,
and none reaches into another's internals. `explicit-error-handling` is
partial: the production probe folds every failure mode (refused connection,
DNS failure, timeout, non-200) into the same `false`/`.direct` outcome with
no distinguishable error surfaced to the caller (see
probe-failure-collapses-to-false). `unit-test-coverage` passes: all three
files are covered directly by `TransportResolverTests.swift`,
`DaemonTransportTests.swift`, and `DirectTransportTests.swift`, including
both hermetic (injected probe) and semi-hermetic (`MockDaemonServer`,
`StubURLProtocol`) paths. `fault-tolerance` passes: Direct is a documented,
guaranteed fallback, and a daemon probe failure never blocks `ADHClient`
construction. `graceful-degradation` is partial: the daemon-down path
degrades cleanly to Direct, but the concurrent-`resolve()` race and the
unvalidated `port` crash (both under Edge Cases) are unresolved, undegraded
failure modes. `secure-transport` is partial: the Direct path is always
HTTPS, but the Daemon path is plain HTTP — acceptable only because it is
restricted to `127.0.0.1` loopback traffic that never leaves the device (see
Privacy), a distinction this check does not itself encode.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Removed 8 agenticdeveloperhub product-name mentions (private-scope leak, D_2) via code-identifier rephrasing; hct-022 corrected to reflect that a refused loopback connection fails immediately and does not exercise probeTimeout. |
