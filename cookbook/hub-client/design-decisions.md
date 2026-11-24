
- **Decision**: The generated `Client` is exposed directly as `public let
  api`, with no additional per-operation wrapping on `ADHClient`.
  **Rationale**: the type's own doc comment states consumers "call the full,
  typed API through it" — this avoids re-declaring every generated
  operation on `ADHClient` itself, so a newly generated operation is usable
  immediately with no change to this façade.
  **Approved**: pending

- **Decision**: Direct and Daemon transports differ only by
  `(serverURL, transport)` on `APITransport`; `ADHClient` builds an
  identical generated `Client` from either.
  **Rationale**: swift-openapi-runtime takes the server URL on `Client`, not
  the transport, so transport selection is fully captured by that pair —
  `ADHClient` needs no branching between the two beyond which
  `APITransport` value it was given.
  **Approved**: pending

- **Decision**: `credentials`, `session`, and `middlewares` are non-public.
  **Rationale**: `api` / `transport` / `transportKind` are the intended
  public surface, per the type's own doc comment. `hub-client-auth`'s
  `ADHClient+Auth.swift` / `ADHClient+Session.swift` wrappers reach
  `credentials` / `session` from within the module, but a consumer outside
  the module has no supported reason to reach past `api` for
  authentication.
  **Approved**: pending

- **Decision**: `rawJSON` rebuilds an equivalent middleware chain from the
  same `middlewares` array `ADHClient` was constructed with, rather than
  sharing a pre-built pipeline with `api`.
  **Rationale**: swift-openapi-runtime's generated `Client` does not expose
  its assembled middleware pipeline for reuse, so `rawJSON` reconstructs one
  from the identical `middlewares` array, guaranteeing raw and typed
  requests see identical auth/refresh behavior without depending on
  `Client`'s internals.
  **Approved**: pending

- **Decision**: A caller-supplied header name that `HTTPField.Name` rejects
  is silently dropped rather than thrown.
  **Rationale**: the doc comment states this is "a transport detail, not a
  place to crash a sign-in" — the one real caller needing arbitrary headers
  (`hub-client-auth`'s `exchangeOAuthCode`) must not have an unrelated
  malformed header abort authentication. This is a deliberate exception to
  failing fast: the drop gives the caller no signal.
  **Approved**: pending

- **Decision**: The 16 MiB buffering cap (`ADHBodyLimit.maxBuffered`) is a
  single, non-configurable constant, defined here and shared with
  `hub-client-auth`'s `SessionRefreshMiddleware` for request-body buffering.
  **Rationale**: the doc comment states it "covers every JSON body the hub
  sends; uploads go through storage presigned URLs, not this client" — one
  contract avoids the two call sites silently drifting to different limits.
  **Approved**: pending

- **Decision**: `RawResponse.headers` is a single-value `[String: String]`, so
  repeated response headers collapse to the last value.
  **Rationale**: the source states no reason; the type is the simple shape the
  one known caller can use. Headers that repeat, such as `Set-Cookie` or
  `Link`, lose their earlier values, so a caller needing them must not use
  `rawJSON`. A multi-value representation is the alternative and is an open
  question for the maintainer.
  **Approved**: pending

- **Decision**: The Daemon transport targets `DaemonContract`, not a running
  daemon.
  **Rationale**: `DaemonContract`'s doc comment says the real `adhd` daemon
  does not exist yet and the type defines what it must implement. That was the
  state of the source on 2026-11-14; recheck the comment before relying on a
  daemon being present, and prefer `.resolved(...)`, which falls back to
  Direct.
  **Approved**: pending
