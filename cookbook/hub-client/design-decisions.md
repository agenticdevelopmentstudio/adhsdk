
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
  malformed header abort authentication.
  **Approved**: pending

- **Decision**: The 16 MiB buffering cap (`ADHBodyLimit.maxBuffered`) is a
  single, non-configurable constant, defined here and shared with
  `hub-client-auth`'s `SessionRefreshMiddleware` for request-body buffering.
  **Rationale**: the doc comment states it "covers every JSON body the hub
  sends; uploads go through storage presigned URLs, not this client" — one
  contract avoids the two call sites silently drifting to different limits.
  **Approved**: pending

