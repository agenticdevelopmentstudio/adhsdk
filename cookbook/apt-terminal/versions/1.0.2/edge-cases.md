
- **Empty `--set` value.** `--set name=` JSON-decodes to nothing valid, so
  `parse_set` falls back to the literal empty string `""` for `name` — MUST.
- **No `--set` at all.** `create`/`update` with no `--set` option builds the
  body from `parse_set([])` (an empty dict), relying entirely on the body
  model's own field defaults; any missing required field surfaces via
  `body-construction-error-hint` — MUST.
- **Unparseable or empty response body.** A `2xx` response with no body or a
  non-JSON body is treated as `data = None` by both `execute()` and
  `public.py`'s `_run()`, and `render(None, ...)` then produces *no output at
  all* — not even a success confirmation — MUST (see `render-dispatch-by-shape`).
- **Boundary: `--set FIELD=VALUE` with no `=`.** Raises `AptError` naming the
  malformed pair — MUST (`set-pair-parsing`).
- **Boundary: unknown `--set` field / unknown enum value.** Both raise
  `AptError` naming the offending input and the allowed choices before any
  request is sent — MUST (`unknown-field-rejected`, `enum-coercion-by-value-then-name`).
- **Concurrent access.** Within a single `apt` invocation there is no
  concurrency: `main()`'s callback populates module-level `_STATE` once,
  synchronously, before any subcommand body runs, and every request is made
  serially. Across *separate* invocations sharing one config file, see the
  `concurrent-config-writes` requirement above — this is the one concurrency
  scenario the source leaves genuinely undefined.
- **Error state: server reachable but returns an error status.** Every
  authenticated and public request path maps `>= 400` through
  `error_for_status`; `execute()` and `public.py`'s `_run()` do this
  directly, while `whoami()`/`login()`/`refresh()`/`logout()` have their own
  narrower, hand-written handling (see the corresponding requirements and
  Design Decisions) — MUST.
- **Error state: server reachable but returns a malformed/non-JSON error
  body.** `errors.message_from_bytes`/`_message` both catch the decode
  failure and fall back to the caller-supplied default message (e.g. `"HTTP
  {status}"`) rather than raising a second error — MUST.
- **Offline / unreachable server.** A `httpx.HTTPError` (connection refused,
  DNS failure, TLS failure, etc.) raised anywhere inside the `app()` call is
  caught only at `cli._run()`'s outer boundary and reported as `"network
  error: {exc}"` with exit code `1`. A caller that invokes `Session` methods
  directly, bypassing `_run()`, gets no such handling — the error propagates
  as a raw `httpx.HTTPError` — MUST (`top-level-error-mapping`).
- **Offline mid-refresh.** If the network becomes unreachable specifically
  during the refresh POST inside `execute()`'s or `whoami()`'s 401-retry
  path, the raised `httpx.HTTPError` propagates out of `execute()`/`whoami()`
  uncaught by either function — it is not converted to `refresh() returning
  False`, because `refresh()` itself does not catch transport errors, only
  non-200 *responses* — MUST (traced to `auth.py`'s `refresh`, which has no
  `try`/`except` around its `httpx.post` call).
- **Missing config file on first run.** Handled cleanly: `load()` returns
  defaults and the CLI proceeds as an unauthenticated, default-profile
  session — see `missing-config-file-defaults`.
- **Unbounded wait on a hanging/unreachable server.** Neither `client_factory()`
  nor `public_client()` sets a timeout anywhere in the request path (see
  `no-request-timeout`), so a command against an unreachable or hanging
  server blocks indefinitely — this is a source-wide absence, not merely
  unhandled at one call site.

