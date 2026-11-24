
- **Decision**: `execute()` (crud.py) and `public.py`'s `_run()` build the
  HTTP request from the generated operation's `_get_kwargs()` but issue it
  via raw `httpx` and parse the raw JSON response themselves, instead of
  calling the generated operation's own `sync_detailed()`.
  **Rationale**: `crud.py`'s own comment states the generated `attrs`
  `from_dict()` is strict and raises on any field drift between the OpenAPI
  spec and what the live server actually returns (the comment cites `auth
  token` vs. `accessToken` as a known example); a display tool must show
  whatever the server sent, not fail closed on a spec/server mismatch.
  **Approved**: pending
- **Decision**: `whoami()` implements its own inline 401-retry-then-raise
  logic instead of routing through `crud.execute()`, and collapses every
  failure mode (a second 401, a 5xx, any other status) into one fixed
  `AuthError("not logged in or session expired")`, whereas `execute()`
  dispatches by status via `error_for_status`.
  **Rationale**: The source gives no comment explaining the duplication;
  this recipe records it as an observed inconsistency rather than
  reconciling it, per source fidelity. A port should decide deliberately
  whether to preserve the fixed-message behavior for `whoami` or unify it
  with `execute()`'s per-status mapping — the two are not currently the
  same contract.
  **Approved**: pending
- **Decision**: `Config.profile(name)` mutates `self.profiles` as a side
  effect of what reads as a lookup, auto-creating a `Profile` the first time
  a name is requested.
  **Rationale**: This lets `cli.py`'s `main()` callback call `cfg.profile(profile
  or cfg.default_profile)` unconditionally, on every invocation, without a
  separate "does this profile exist yet" branch — the first `apt --profile
  new-profile ...` invocation for a never-before-seen name just works. The
  cost is that a read-looking call is not read-only, which a port should
  preserve deliberately rather than accidentally making `profile()` a true
  read that then requires call sites to add their own creation branch.
  **Approved**: pending
- **Decision**: `resources.py`'s `templates` resource maps to
  `get_persona_provider_templates` (a redacting provider-templates catalog)
  rather than a raw `service-templates` endpoint.
  **Rationale**: `resources.py`'s own comment states the raw
  `/persona/service-templates` endpoint was removed from the backend; this
  is a historical/backend-driven rename this recipe documents as-is, per
  source fidelity, without further explanation the source does not give.
  **Approved**: pending
- **Decision**: `config.py`'s `save()` both opens a new file with an
  `os.open` mode of `0o600` *and* separately `chmod`s the path afterward.
  **Rationale**: The source's own comment states this doubles as tightening
  an *existing*, previously looser file — `os.open`'s `mode` argument only
  applies at file *creation*, so relying on it alone would leave a
  pre-existing 0o644 file unprotected after every subsequent save.
  **Approved**: pending
- **Decision**: message extraction from an HTTP error body is implemented
  twice — `auth.py`'s `_message(resp, fallback)` (via `resp.json()`) for
  `login`, and `errors.py`'s `message_from_bytes(content, fallback)` (via
  manual `bytes` decode) for every other authenticated/public call — both
  ultimately delegating to the same `errors._message_from_body`.
  **Rationale**: The source gives no comment explaining two entry points
  instead of one; this recipe records the duplication as a fact rather than
  merging it into a single normative requirement the source does not
  express as one.
  **Approved**: pending

