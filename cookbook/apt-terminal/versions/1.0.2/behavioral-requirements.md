
- **config-path-resolution**: `config_path()` MUST resolve to `$APT_CONFIG`
  (expanded) when set; otherwise to `$XDG_CONFIG_HOME/apt/config.toml`
  (`$XDG_CONFIG_HOME` expanded) when that variable is set; otherwise to
  `~/.config/apt/config.toml`.
- **missing-config-file-defaults**: `load()` MUST return a `Config` with
  `default_profile == "default"` and an empty `profiles` mapping, without
  raising, when the resolved path does not exist.
- **malformed-config-raises**: `load()` MUST raise `ConfigError` — wrapping
  the path and the underlying `OSError`/`tomllib.TOMLDecodeError` message —
  when the file exists but cannot be opened or parsed as TOML.
- **profile-autovivification**: `Config.profile(name)` MUST create and
  register a new `Profile(name=n, base_url=DEFAULT_BASE_URL)` in
  `self.profiles` the first time a given name (or the default profile name)
  is requested, and MUST return that same stored instance on every
  subsequent call with the same name — this is a mutating operation, not a
  read-only lookup.
- **token-fields-omitted-when-none**: `save()` MUST omit a profile's
  `access_token`/`refresh_token` key entirely from the serialized TOML when
  its value is `None`, rather than serializing a null.
- **config-file-permissions**: `save()` MUST create a new config file with
  mode `0o600` and MUST additionally `chmod` an existing file to `0o600` on
  every save, tightening a previously looser file.
- **base-url-override**: `Session.base_url` MUST return `$APT_BASE_URL` when
  set, otherwise `profile.base_url`.
- **login-persists-tokens**: `login(email, password)` MUST `POST
  {base_url}/auth/login` with JSON body `{email, password, rememberMe:
  false}` — `rememberMe` is always `false`; the CLI exposes no option to
  request a longer-lived session — and on a `200` response MUST store the
  body's `accessToken` as `profile.access_token`, the `refresh_token` cookie
  value (parsed from the raw `Set-Cookie` header) as `profile.refresh_token`,
  persist via `config_mod.save`, and return the body's `user.email` (falling
  back to the given `email` when absent).
- **login-failure-raises**: `login` MUST raise `AuthError` on any non-`200`
  response, with a message derived from the body's `error.message`, `title`,
  or `message` field (in that order), falling back to `"login failed"`, and
  MUST NOT write to the profile or config in that case.
- **login-missing-tokens-raises**: `login` MUST raise `AuthError` with the
  exact message `"login succeeded but tokens were missing from the
  response"` when a `200` response is missing either the access token or the
  refresh cookie, without mutating the profile in that case.
- **refresh-short-circuits**: `refresh()` MUST return `False` immediately,
  issuing no request, when `profile.refresh_token` is unset.
- **refresh-rotates-tokens**: `refresh()` MUST `POST {base_url}/auth/refresh`
  with an `Authorization: Bearer <access_token or ''>` header and a `Cookie:
  refresh_token=<refresh_token>` header; on a `200` response carrying
  `accessToken` it MUST store the new access token, adopt a rotated
  `refresh_token` cookie when the response sets one (otherwise retain the
  existing refresh token), persist via `config_mod.save`, and return `True`.
- **refresh-failure-returns-false**: `refresh()` MUST return `False`,
  without persisting or mutating the profile, when the response is not
  `200` or its body has no `accessToken`.
- **logout-clears-session**: `logout()` MUST set both `profile.access_token`
  and `profile.refresh_token` to `None` and persist via `config_mod.save`,
  unconditionally — regardless of whether a server-side revoke was attempted
  or what its outcome was.
- **logout-revokes-when-possible**: `logout()` MUST `POST
  {base_url}/auth/revoke` with `Cookie: refresh_token=<refresh_token>` and
  `Content-Type: application/json` (body `"{}"`)  only when
  `profile.refresh_token` is set.
- **logout-revoke-failure-swallowed**: NEEDS REVIEW: Not implemented in source. `logout()` wraps the `/auth/revoke` POST in `contextlib.suppress(httpx.HTTPError)` with no logging, warning, or return signal, and `auth_commands.py`'s `logout` command unconditionally prints `"Logged out."` regardless of whether the server actually revoked the refresh token. What is missing: a way for the caller to learn that server-side revocation failed, so a refresh token that is still live on the server is not mistaken for dead. Evidence needed: whoever owns `auth.py` deciding whether `logout()` should surface a revoke failure (return value, warning line, or raised error) instead of swallowing it.
- **client-factory-requires-token**: `client_factory()` MUST raise
  `AuthError` with the exact message `"not logged in — run 'apt auth
  login'"` when neither `$APT_TOKEN` nor `profile.access_token` is set.
- **client-factory-env-override**: `client_factory()` MUST prefer
  `$APT_TOKEN` over `profile.access_token` when both are set, and an
  env-supplied token MUST NOT be written to the profile or persisted to
  config.
- **client-factory-builds-fresh-client**: `client_factory()` MUST construct
  and return a new `AuthenticatedClient` on every call; it MUST NOT cache or
  reuse a previous instance.
- **public-client-unauthenticated**: `public_client()` MUST construct a
  `Client` with no authentication token attached.
- **whoami-retries-once-then-fixed-error**: `whoami()` MUST retry its `GET
  /auth/me` exactly once, via a freshly built client, when the first
  attempt returns `401` and `refresh()` succeeds; for any other non-`200`
  outcome (including a second `401`, a `5xx`, or any other status) it MUST
  raise `AuthError` with the fixed message `"not logged in or session
  expired"`, regardless of the actual status code — unlike `execute()`
  (below), `whoami()` does not distinguish error types by status code.
- **no-request-timeout**: Neither `client_factory()` nor `public_client()`
  passes a `timeout` argument when constructing `AuthenticatedClient`/`Client`
  (`auth.py`), so the generated client's `_timeout` field keeps its default of
  `None`; `generated/client.py`'s `get_httpx_client`/`get_async_httpx_client`
  pass that `None` straight through to `httpx.Client`/`httpx.AsyncClient`,
  which disables timeouts entirely rather than falling back to httpx's own
  default. A command against an unreachable or hanging server therefore
  blocks indefinitely.
- **error-status-mapping**: `error_for_status(status, message)` MUST return
  `AuthError` for `401` or `403`, `NotFoundError` for `404`, and
  `ApiError(status, message)` for every other status `>= 400`.
- **exit-code-per-error-type**: Each error type MUST expose a fixed process
  exit code: `AptError` (base/uncategorized) `1`, `ConfigError` `2`,
  `AuthError` `3`, `NotFoundError` `4`, `ApiError` `5`.
- **message-extraction-precedence**: Extracting a user-facing message from a
  JSON error body MUST check, in order, a non-empty `error.message`, then a
  non-empty `title`, then a non-empty `message`, and MUST fall back to the
  caller-supplied default when none of those match or the body is not a
  JSON object.
- **set-pair-parsing**: A `--set FIELD=VALUE` pair MUST raise `AptError` when
  it contains no `=`; otherwise `VALUE` MUST be JSON-decoded when it parses
  as valid JSON (so `true`/`false`/`null`/numbers/objects/arrays become
  their typed Python values) and otherwise MUST be kept as the literal
  string.
- **unknown-field-rejected**: `build_body` MUST raise `AptError` naming the
  offending `--set` key(s) and the allowed field names (excluding
  `additional_properties`) when a key is not a declared field of the target
  body model.
- **enum-coercion-by-value-then-name**: For a body-model field typed as an
  `Enum` (directly, or as the sole `Enum` type inside a union),
  `build_body` MUST coerce a non-enum `--set` value by matching the enum's
  `value` first, then its member name, and MUST raise `AptError` naming the
  field and the allowed `value`s when neither match.
- **ambiguous-enum-union-uncoerced**: `enum_type` MUST return no type — and
  `coerce_enums` MUST therefore leave the raw `--set` value uncoerced — for
  a field whose union names more than one `Enum` type.
- **body-construction-error-hint**: A `TypeError` raised while constructing
  the body model from coerced kwargs MUST be re-raised as `AptError` whose
  message includes a hint that `--set` values are JSON-parsed and that a
  literal string value must be quoted (e.g. `--set name='"true"'`).
- **execute-uses-raw-httpx**: `execute()` MUST build the HTTP request from
  the generated operation's `_get_kwargs()` and issue it via the client's
  raw `httpx.Client` (`get_httpx_client().request(**kwargs)`); it MUST NOT
  call the generated operation's own `sync_detailed()`, because that
  function's strict `attrs` `from_dict()` raises on any field drift between
  the OpenAPI spec and the live server, and this tool must display whatever
  the server actually returned.
- **execute-retries-once-on-401**: `execute()` MUST retry the request
  exactly once, via a freshly built client, when the first response is
  `401` and `session.refresh()` succeeds.
- **execute-raises-mapped-error**: `execute()` MUST raise the error
  `error_for_status` returns for the response's status code whenever the
  (possibly retried) response status is `>= 400`, with the message taken
  from `errors.message_from_bytes(resp.content, "HTTP {status}")`.
- **execute-renders-on-success**: On a response with status `< 400`,
  `execute()` MUST attempt to parse the body as JSON — treating an
  unparseable or empty body as `None` — and pass the result to `render()`
  together with the caller's `json_out` flag.
- **resource-command-presence**: `build_resource_app` MUST register a `list`
  command (with a hidden `ls` alias) only when `Ops.list_` is set, a `get
  <id>` command only when `Ops.get` is set, a `create` command only when
  both `Ops.create` and `Resource.create_body` are set, an `update <id>`
  command only when both `Ops.update` and `Resource.update_body` are set,
  and a `delete <id>` command (with a hidden `rm` alias) only when
  `Ops.delete` is set.
- **resource-action-commands**: `build_resource_app` MUST register one
  subcommand per entry in `Resource.actions`, named and described from that
  `Action`, and each such subcommand MUST take a single `id` path argument.
- **static-resource-catalog**: The `PERSONA` and `AUTH_TOKENS` tuples and the
  `ALL_DOMAINS` mapping MUST be fixed at import time; no resource, action,
  or domain is added or removed at runtime.
- **domain-registration-extensibility**: A new resource domain MAY be added
  by giving `ALL_DOMAINS` a new entry; `cli.py`'s domain-mounting loop
  iterates `ALL_DOMAINS.items()` generically and requires no change to
  itself to mount it.
- **public-commands-unauthenticated**: `public persona <slug>` and `public
  user <slug>` MUST issue their request through `session.public_client()`
  and MUST NOT attempt a `refresh()`-and-retry on a `401` response — unlike
  every authenticated path above.
- **public-error-mapping**: A `public` command MUST raise the same
  `error_for_status`-mapped error type as an authenticated command for a
  response with status `>= 400`.
- **profile-selection**: The global `--profile`/`-p` option MUST select the
  named config profile for the invocation, defaulting to
  `cfg.default_profile` when omitted; `main()`'s callback MUST run (loading
  config and resolving the profile) before any subcommand's body executes.
- **version-flag-exits-early**: `--version` MUST print `"apt {__version__}"`
  and exit the process before any subcommand callback runs (`is_eager=True`
  on the option).
- **top-level-error-mapping**: `_run()` MUST map an escaping `AptError` to
  `die(str(exc), code=exc.exit_code)` and an escaping `httpx.HTTPError` to
  `die(f"network error: {exc}", code=1)`; any other exception type MUST
  propagate out of `_run()` uncaught.
- **concurrent-config-writes**: NEEDS REVIEW: Not implemented in source. Two `apt` invocations that both call `config_mod.save()` against the same config path (e.g. a background `refresh` racing a foreground `login`) have no file lock or atomic-rename protection: `save()` opens the file directly at its final path with `os.O_TRUNC`. What is missing: a defined outcome for a concurrent write — whether a lost update (the later writer silently discarding the other process's just-issued tokens) is acceptable, or must be prevented. Evidence needed: confirmation from whoever owns `config.py` on whether concurrent `apt` invocations against one profile are a supported scenario.
- **render-dispatch-by-shape**: `render(data, json_out)` MUST emit nothing
  when `data is None`; MUST always emit JSON when `json_out` is `True`;
  otherwise MUST render a list whose items are all `dict`s as a table, a
  list containing any non-`dict` item as one text line per item (a `str`
  item verbatim, any other item as compact JSON), a single `dict` as a
  one-row table, and any other value via its string form.
- **table-column-union**: `emit_table` with no explicit `columns` MUST
  derive the column set as the union of every key seen across *all* rows —
  not just the first row — in first-seen order, and MUST print `(none)` in
  place of a table when `rows` is empty.
- **confirm-noninteractive-default**: `confirm()` MUST return `False` on an
  `EOFError` from `input()` (no interactive stdin available) unless
  `assume_yes` is `True`, in which case it MUST return `True` without
  prompting.

