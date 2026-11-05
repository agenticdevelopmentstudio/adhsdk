---
id: 6593a7e1-b42f-4015-8072-20b70800124e
title: Hub Client — APT Terminal
domain: adhsdk://recipes/hub-client-apt-terminal
type: ingredient
version: 1.0.2
status: review
language: en
created: '2026-09-23'
modified: '2026-09-24'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'The apt-terminal CLI''s contract: profile/token lifecycle against the Agentic
  Developer Hub, declarative CRUD dispatch, and raw-JSON error/output rendering.'
platforms:
- python
tags:
- cli
- terminal
- auth
- client
depends-on: []
related: []
references:
- agenticdevelopercookbook://guidelines/cookbook/recipe-quality/cookbook-compliance
approved-by: ''
approved-date: ''
---

# Hub Client — APT Terminal

## Overview

`apt` (package `apt-terminal`, entry point `apt_terminal.cli:_run`, version
`0.1.0`) is the Python terminal client for the Agentic Developer Hub backend
(`api.agenticdeveloperhub.com`, `DEFAULT_BASE_URL` in `config.py`). It is a
headless **client/engine** — no visual surface — built from eight
collaborating modules:

- **`config.py`** — reads and writes `~/.config/apt/config.toml` (or an
  override), holding one or more named `Profile`s (`base_url`,
  `access_token`, `refresh_token`) under a `Config`.
- **`auth.py`** — `Session`, which owns the login/refresh/logout lifecycle
  against raw `httpx` and builds the generated client for every other
  module to use.
- **`errors.py`** — the `AptError` exception hierarchy and the HTTP
  status → error-type mapping every request path shares.
- **`crud.py`** — the declarative CRUD engine: `--set FIELD=VALUE` parsing,
  enum coercion, request-body construction, `execute()` (the authenticated
  request/retry/render pipeline), and `build_resource_app()`, which turns a
  `Resource` declaration into a Typer sub-app.
- **`resources.py`** — the fixed, import-time catalog of resources
  (`PERSONA`, `AUTH_TOKENS`, `ALL_DOMAINS`) built on top of a generated
  OpenAPI client (`apt_terminal.generated`, not itself part of this recipe's
  sources).
- **`public.py`** — the two unauthenticated lookup commands
  (`public persona <slug>`, `public user <slug>`).
- **`output.py`** — the rendering layer (`render`, `emit_table`,
  `emit_json`, `emit_kv`, `confirm`, `warn`, `die`) every command funnels
  through.
- **`cli.py`** — assembles the Typer `app` from the above at import time and
  provides the process entry point (`_run`).

The resource catalog this recipe documents (`PERSONA`, `AUTH_TOKENS`) is
declarative data, not hard-coded commands:

| Domain mount | Resource | `list` | `get` | `create` | `update` | `delete` | Named actions |
|---|---|---|---|---|---|---|---|
| `persona` | `services` | yes (+`ls`) | yes | yes | yes (`PATCH`) | yes (+`rm`) | `connect`, `models`, `models-refresh` |
| `persona` | `personas` | yes (+`ls`) | yes | yes | yes (`PUT`) | yes (+`rm`) | — |
| `persona` | `models` | yes (+`ls`) | — | — | — | — | — |
| `persona` | `templates` | yes (+`ls`) | — | — | — | — | — |
| `auth` | `tokens` | yes (+`ls`) | — | yes | — | yes (+`rm`) | — |

`services` updates via `PATCH` and `personas` via `PUT` because that is what
their respective generated operations (`patch_persona_services_id_body` /
`put_persona_personas_id_body`) implement; the source gives no rationale for
the difference and this recipe does not invent one. `templates` intentionally
lists `get_persona_provider_templates` (a redacting catalog) rather than a raw
`service-templates` endpoint, per `resources.py`'s own comment: the raw
endpoint was removed from the backend.

## Behavioral Requirements

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

## Appearance

Not applicable — this is a headless CLI/client, not a visual component.

## States

Not applicable — this is a headless CLI/client, not a visual component; its
only runtime state machine (session token lifecycle: unauthenticated →
authenticated → expired-and-refreshed → logged out) is covered under
Behavioral Requirements above, not as a visual-state table.

## Accessibility

Not applicable — this is a headless CLI/client with no rendered surface,
focus, label, or trait for an assistive technology to describe; its terminal
output is covered under Behavioral Requirements (`render-dispatch-by-shape`)
and Logging below.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| apt-terminal-001 | config-path-resolution | `$APT_CONFIG=/tmp/custom/apt.toml` | `config_path()` returns `Path("/tmp/custom/apt.toml")` — `test_config.py::test_config_path_env_override` |
| apt-terminal-002 | missing-config-file-defaults | `load(path)` where `path` does not exist | Returns `Config(path=path)` with `default_profile == "default"`, `profiles == {}}`, no exception raised — traced to `config.py`'s `load` early-return; not exercised by a given test |
| apt-terminal-003 | malformed-config-raises | `load(path)` where `path` contains invalid TOML bytes | Raises `ConfigError` whose message includes the path and the underlying parser error — traced to `config.py`'s `load` `except` clause; not exercised by a given test |
| apt-terminal-004 | profile-autovivification | `Config(path=..)`, then `cfg.profile()` twice with no prior `"default"` entry | Both calls return the identical `Profile` instance, now present in `cfg.profiles["default"]` with `base_url == DEFAULT_BASE_URL` — `test_config.py::test_default_profile_uses_default_base_url` |
| apt-terminal-005 | token-fields-omitted-when-none | A `Profile` with `access_token=None`, `refresh_token=None`, `save()`d | Serialized profile table has only `base_url`; `access_token`/`refresh_token` keys are absent, not null — traced to `config.py`'s `_dump_profile`; not exercised by a given test |
| apt-terminal-006 | config-file-permissions | `save(cfg)` on a fresh path | File mode is exactly `0o600` — `test_config.py::test_save_sets_0600` |
| apt-terminal-007 | base-url-override | `profile.base_url = "https://a"`, `$APT_BASE_URL` unset vs. set to `"https://b"` | `session.base_url` returns `"https://a"` then `"https://b"` — traced to `auth.py`'s `base_url` property; not exercised by a given test |
| apt-terminal-008 | login-persists-tokens | `POST /auth/login` mocked 200 with `accessToken: "acc1"`, `user.email: "u@x.test"`, `Set-Cookie: refresh_token=ref1` | `login()` returns `"u@x.test"`; `profile.access_token == "acc1"`; `profile.refresh_token == "ref1"`; reloading the saved config shows `access_token == "acc1"` — `test_auth.py::test_login_stores_tokens_and_saves` |
| apt-terminal-009 | login-failure-raises | `POST /auth/login` mocked `401` with `{"title": "bad creds"}` | Raises `AuthError` — `test_auth.py::test_login_failure_raises` |
| apt-terminal-010 | login-missing-tokens-raises | `POST /auth/login` mocked `200` with `accessToken` but no `Set-Cookie` header | Raises `AuthError("login succeeded but tokens were missing from the response")`; `profile.access_token` remains unset — traced to `auth.py`'s `login`; not exercised by a given test |
| apt-terminal-011 | refresh-short-circuits | `profile.refresh_token` unset, `refresh()` called | Returns `False`; no HTTP call recorded — `test_auth.py::test_refresh_without_token_returns_false` |
| apt-terminal-012 | refresh-rotates-tokens | `profile.access_token="old"`, `refresh_token="ref1"`; `POST /auth/refresh` mocked `200` with `accessToken: "acc2"`, `Set-Cookie: refresh_token=ref2` | Returns `True`; `profile.access_token == "acc2"`; `profile.refresh_token == "ref2"` — `test_auth.py::test_refresh_updates_access_token` |
| apt-terminal-013 | refresh-failure-returns-false | `POST /auth/refresh` mocked non-200 (or 200 with no `accessToken`) | Returns `False`; `profile.access_token`/`refresh_token` unchanged from before the call — traced to `auth.py`'s `refresh`; not exercised by a given test |
| apt-terminal-014 | logout-clears-session, logout-revokes-when-possible | `profile.access_token="a"`, `refresh_token="r"`; `POST /auth/revoke` mocked `200` | `profile.access_token is None` and `profile.refresh_token is None` after `logout()` — `test_auth_commands.py::test_logout_command` |
| apt-terminal-015 | logout-revoke-failure-swallowed | `profile.refresh_token="r"`; `POST /auth/revoke` mocked to raise `httpx.HTTPError` | `logout()` completes without raising; `profile.access_token`/`refresh_token` are still cleared to `None` — traced to `auth.py`'s `contextlib.suppress(httpx.HTTPError)`; not exercised by a given test (the gap itself: no test asserts the caller is ever told the revoke failed) |
| apt-terminal-016 | client-factory-requires-token | `profile.access_token` unset, `$APT_TOKEN` unset, `client_factory()` called | Raises `AuthError` — `test_auth.py::test_client_factory_requires_token` |
| apt-terminal-017 | client-factory-builds-fresh-client | `profile.access_token="acc"`, `client_factory()` called | Returns an `AuthenticatedClient` with `.token == "acc"` and `._base_url == BASE` — `test_auth.py::test_client_factory_builds_authed` |
| apt-terminal-018 | client-factory-env-override | `profile.access_token` unset, `$APT_TOKEN="envtok"` | `client_factory().token == "envtok"`; `profile.access_token` stays `None`; no config file is written — `test_auth.py::test_env_token_override_not_persisted` |
| apt-terminal-019 | whoami-retries-once-then-fixed-error | `GET /auth/me` mocked `200` with `{"email": "u@x", "id": "1"}` | `whoami()` returns that dict verbatim — `test_auth_commands.py::test_whoami_command` (only the success branch; the 401-retry and final-failure branches are traced to `auth.py`'s `whoami` and are not exercised by a given test) |
| apt-terminal-020 | no-request-timeout | `client_factory()`/`public_client()` inspected for constructor kwargs | Neither call passes `timeout=`; the resulting `AuthenticatedClient`/`Client`'s `_timeout` is `None`, which `get_httpx_client()` passes straight to `httpx.Client(timeout=None, ...)` — traced to `generated/client.py`; not exercised by a given test |
| apt-terminal-021 | error-status-mapping | `error_for_status(401, "m")`, `error_for_status(404, "m")`, `error_for_status(500, "m")` | Returns `AuthError`, `NotFoundError`, `ApiError` respectively — traced to `errors.py`'s `error_for_status`; exercised end-to-end by `test_crud.py::test_401_no_refresh_raises_auth_error` and `test_404_raises_not_found_exit_code` |
| apt-terminal-022 | exit-code-per-error-type | `NotFoundError("x").exit_code`, `AuthError("x").exit_code` | `4` and `3` respectively — `test_crud.py::test_404_raises_not_found_exit_code`, `test_401_no_refresh_raises_auth_error` |
| apt-terminal-023 | message-extraction-precedence | Bodies `{"error": {"message": "m1"}}`, `{"title": "m2"}`, `{"message": "m3"}`, `{}` (fallback `"fb"`) | Returns `"m1"`, `"m2"`, `"m3"`, `"fb"` respectively — traced to `errors.py`'s `_message_from_body`; not exercised by a dedicated unit test, but the first case is exercised end-to-end by `test_crud.py::test_401_triggers_refresh_then_retry`'s `{"error": {"message": "expired"}}` body |
| apt-terminal-024 | set-pair-parsing | `parse_set(["name=foo", "n=5", "flag=true"])` | Returns `{"name": "foo", "n": 5, "flag": True}` — `test_crud.py::test_parse_set_coerces_json` |
| apt-terminal-025 | unknown-field-rejected | `build_body(PostPersonaServicesBody, ["bogus=1"])` | Raises `AptError` — `test_crud.py::test_build_body_rejects_unknown_field` |
| apt-terminal-026 | enum-coercion-by-value-then-name | `build_body(PostPersonaServicesBody, ["name=svc", "provider_kind=openai", "base_url=https://o.test"])` | `body.provider_kind is PostPersonaServicesBodyProviderKind.OPENAI`; `body.to_dict()["providerKind"] == "openai"` — `test_crud.py::test_build_body_coerces_a_string_into_the_declared_enum`, `test_a_coerced_body_serializes_instead_of_raising` |
| apt-terminal-027 | enum-coercion-by-value-then-name | `build_body(PostPersonaServicesBody, ["name=svc", "provider_kind=nope", "base_url=https://o.test"])` | Raises `AptError` whose message contains `"provider_kind"` and `"openai"` — `test_crud.py::test_build_body_names_the_field_and_the_choices_for_a_bad_enum_value` |
| apt-terminal-028 | ambiguous-enum-union-uncoerced | `crud.enum_type(A)`, `crud.enum_type(A \| None)`, `crud.enum_type(str)`, `crud.enum_type(A \| B)` (two distinct enums `A`, `B`) | Returns `A`, `A`, `None`, `None` respectively — `test_crud.py::test_enum_type_looks_through_a_union_but_not_an_ambiguous_one` |
| apt-terminal-029 | body-construction-error-hint | `build_body` construction raises `TypeError` (e.g. a required field missing) | Raises `AptError` whose message names the model and includes the `--set`-is-JSON-parsed / quoting hint — traced to `crud.py`'s `build_body` `except TypeError`; not exercised by a given test |
| apt-terminal-030 | execute-uses-raw-httpx, execute-renders-on-success | `services list --json`, `GET /persona/services` mocked `200` with a one-item JSON array | CLI exits `0`; output is the raw JSON array (`'"id": "1"'` present) — `test_crud.py::test_list_renders_json` |
| apt-terminal-031 | execute-retries-once-on-401 | `services list --json`; first `GET` mocked `401`, `POST /auth/refresh` mocked `200`, retried `GET` mocked `200` with `[]` | CLI exits `0`; `session.profile.access_token == "acc2"` after the call — `test_crud.py::test_401_triggers_refresh_then_retry` |
| apt-terminal-032 | execute-raises-mapped-error | `crud.execute(services.ops.list_, session=sess)` with `GET` mocked `404` | Raises `NotFoundError` with `exit_code == 4` — `test_crud.py::test_404_raises_not_found_exit_code` |
| apt-terminal-033 | execute-raises-mapped-error | `crud.execute(services.ops.list_, session=sess)`, no `refresh_token` set, `GET` mocked `401` | Raises `AuthError` with `exit_code == 3` — `test_crud.py::test_401_no_refresh_raises_auth_error` |
| apt-terminal-034 | resource-command-presence | `services create --set name=svc --set provider_kind=openai --set base_url=https://o.test --json`, `POST /persona/services` mocked `201` | CLI exits `0`; the POST body's `providerKind == "openai"` — `test_crud.py::test_create_posts_body` |
| apt-terminal-035 | resource-command-presence | `services list`, `GET /persona/services` mocked `200` with `[]` | Output contains `"(none)"` — `test_crud.py::test_empty_list_renders_none` |
| apt-terminal-036 | resource-action-commands | `services models svc1`, `GET /persona/services/svc1/models` mocked `200` with `["gpt-4o", "gpt-4o-mini"]` | CLI exits `0`; output contains `"gpt-4o"` — `test_crud.py::test_models_action_renders_string_list` |
| apt-terminal-037 | static-resource-catalog | `{res.name for res in r.PERSONA}`; `r.ALL_DOMAINS["persona"]` | Equals `{"services", "personas", "models", "templates"}`; is the exact `PERSONA` tuple object — `test_resources.py::test_persona_has_expected_resources`, `test_all_domains_indexes_persona` |
| apt-terminal-038 | public-commands-unauthenticated, public-error-mapping | `public persona zed --json`, `GET /public/personas/zed` mocked `200` with `{"slug": "zed", "name": "Zed"}` | CLI exits `0`; output contains `"zed"` — `test_public.py::test_public_persona` |
| apt-terminal-039 | profile-selection | `apt --profile work persona services --help` against a config with a `work` profile | Help text for `services` renders without requiring network access — traced to `cli.py`'s `main` callback and `test_cli.py::test_persona_services_mounted` (default profile case) |
| apt-terminal-040 | version-flag-exits-early | `apt --version` | Prints `"apt 0.1.0"` and exits `0` before any config load or session build — traced to `cli.py`'s `_version_callback`; not exercised by a given test |
| apt-terminal-041 | top-level-error-mapping | `cli.app` replaced with a callable that raises `httpx.ConnectError("down")`, `cli._run()` invoked | Raises `SystemExit(1)` — `test_cli.py::test_run_handles_network_error` |
| apt-terminal-042 | concurrent-config-writes | Two `Config` instances built from the same path, both `.profile().access_token` mutated differently, both `save()`d in sequence | The second `save()` silently overwrites the first's tokens; no lock, merge, or error occurs — traced to `config.py`'s `save` (`os.O_TRUNC`); not exercised by a given test (the gap itself) |
| apt-terminal-043 | render-dispatch-by-shape | `render([{"a": 1}], False)` vs. `render({"a": 1}, False)` vs. `render(["x", "y"], False)` vs. `render(None, False)` | Table with column `a`; one-row table with column `a`; two text lines `x`/`y`; no output at all — traced to `output.py`'s `render`; not exercised by a given test directly, but the all-dict-list case is exercised end-to-end by `test_crud.py::test_list_renders_json` |
| apt-terminal-044 | table-column-union | `emit_table([{"a": 1}, {"b": 2}])` | Renders one table with columns `a`, `b` (union, first-seen order), row 1 showing `—` for `b`, row 2 showing `—` for `a` — traced to `output.py`'s `emit_table`; not exercised by a given test |
| apt-terminal-045 | confirm-noninteractive-default | `confirm("ok?")` with `input()` raising `EOFError` vs. `confirm("ok?", assume_yes=True)` | Returns `False` then `True` (no prompt printed in the second case) — traced to `output.py`'s `confirm`; not exercised by a given test |

## Edge Cases

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

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--profile` / `-p` | CLI option (`str`) | `cfg.default_profile` (itself defaulting to `"default"`) | Selects which named profile in `config.toml` the invocation uses. |
| `APT_CONFIG` | environment variable | unset | Overrides the config file path entirely, bypassing `XDG_CONFIG_HOME`/`~/.config`. |
| `XDG_CONFIG_HOME` | environment variable | unset | Base directory for the default config path (`$XDG_CONFIG_HOME/apt/config.toml`) when `APT_CONFIG` is unset. |
| `APT_BASE_URL` | environment variable | unset | Overrides `profile.base_url` for every request made by the invocation. |
| `APT_TOKEN` | environment variable | unset | Overrides `profile.access_token` for `client_factory()` only; never read by `public_client()`, never persisted. |
| `base_url` (per profile, config.toml) | `str` | `"https://api.agenticdeveloperhub.com"` (`DEFAULT_BASE_URL`) | The backend base URL for that profile. |
| `default_profile` (config.toml) | `str` | `"default"` | Which profile `main()` selects when `--profile` is omitted. |
| `--set FIELD=VALUE` | CLI option, repeatable | none | Supplies one request-body field for `create`/`update`; JSON-decoded per value, otherwise literal. |
| `--json` | CLI flag | `False` | Forces raw JSON output (`emit_json`) instead of a rendered table or text line(s). |
| `assume_yes` (`output.confirm`'s parameter) | `bool` | `False` | When `True`, skips the interactive y/N prompt and answers yes; no CLI flag in the given sources currently sets this. |

## Deep Linking

Not applicable: no source file defines a URL scheme, route table, or
app-invocation link — `base_url` composes HTTP API endpoints, which is a
network contract, not a deep link into the CLI itself.

## Localization

The CLI has no localization mechanism: no source imports `gettext`, no
message-catalog or string-key indirection exists anywhere in the eight given
modules, and every user-facing string is a hardcoded English literal (or an
f-string built from one) embedded directly at its call site. The table below
lists them, using the literal message itself in place of a string key:

| String Key (= literal text) | Default (en) | Context |
|-----------|-------------|---------|
| `login succeeded but tokens were missing from the response` | same | `auth.py`'s `login`, on a 200 with missing tokens |
| `not logged in or session expired` | same | `auth.py`'s `whoami`, on any post-retry failure |
| `not logged in — run 'apt auth login'` | same | `auth.py`'s `client_factory`, no token available |
| `login failed` | same | `auth.py`'s `_message`, fallback when the login error body has no JSON |
| `Logged in as {who}` | same | `auth_commands.py`'s `login` command, success |
| `Logged out.` | same | `auth_commands.py`'s `logout` command, always |
| `Refreshed.` / `Could not refresh — run 'apt auth login'.` | same | `auth_commands.py`'s `refresh` command, by outcome |
| `--set expects FIELD=VALUE, got {pair!r}` | same | `crud.py`'s `parse_set` |
| `unknown field(s): {fields}. allowed: {allowed}` | same | `crud.py`'s `build_body` |
| `invalid value for {field}: {value!r}. allowed: {choices}` | same | `crud.py`'s `coerce_enums` |
| `invalid fields for {model}: {exc}. Note: --set values are JSON-parsed …` | same | `crud.py`'s `build_body`, on `TypeError` |
| `failed to read {path}: {exc}` | same | `config.py`'s `load`, on a read/parse failure |
| `network error: {exc}` | same | `cli.py`'s `_run`, on `httpx.HTTPError` |
| `HTTP {status}` | same | `errors.py`'s `message_from_bytes`/`crud.py`, fallback when no error body |
| `(none)` | same | `output.py`'s `emit_table`, empty result set |
| `[y/N]` | same | `output.py`'s `confirm`, prompt suffix |

## Accessibility Options

Not applicable: `output.py`'s rich-styled terminal text has no reduced-motion,
increased-contrast, or color-independent-differentiation setting anywhere in
the given sources — a terminal CLI's accessibility surface (screen reader
behavior, color support) is delegated entirely to the user's terminal
emulator, not configured by this client.

## Feature Flags

Not applicable: no flag, toggle, or config-gated code branch exists in any of
the eight given source files — every command's availability is determined
solely by the static `resources.py` catalog (`resource-command-presence`),
not by a runtime flag.

## Analytics

Not applicable: none of the eight given source files emits an analytics or
telemetry event of any kind; every command's side effects are limited to
config I/O, one or two HTTP calls, and terminal output.

## Privacy

- **Data collected**: The CLI itself collects no telemetry. It handles only
  what the user explicitly supplies: login `email`/`password`, `--set`
  field values for CRUD bodies, and the `--profile` name.
- **Storage**: `profile.access_token` and `profile.refresh_token` — bearer
  and session credentials — are persisted in **plaintext** TOML at
  `~/.config/apt/config.toml` (or the `APT_CONFIG`/`XDG_CONFIG_HOME`
  override), with the file's mode set/tightened to `0o600` by
  `config_mod.save()` (`config-file-permissions`). The values themselves are
  not encrypted at rest.
- **Transmission**: the access token is sent as `Authorization: Bearer
  <token>` on every authenticated request (`AuthenticatedClient
  .get_httpx_client`); the refresh token is sent as a raw `Cookie:
  refresh_token=...` header by `login`/`refresh`/`logout` directly. Whether
  this transits in the clear or over TLS depends entirely on the configured
  `base_url`'s scheme — the source enforces no `https://` requirement (see
  `no-request-timeout`: the same client construction also performs no scheme
  check).
- **Retention**: tokens persist indefinitely in the config file until
  `logout()` clears them, a subsequent `login()` overwrites them, or the
  file is edited or deleted by hand. The client performs no time-based
  expiry check of its own; expiry is discovered only reactively, via a `401`
  triggering `refresh-retry` logic.

## Logging

Not applicable: no source file imports Python's `logging` module (or an
equivalent structured, leveled, filterable logging facility). `output.py`'s
`warn`/`die` write directly to the user-facing stderr console as part of the
CLI's own UI (a `[yellow]warn[/yellow]`/`[red]error[/red]`-prefixed line),
not to a logging subsystem — there is no logger name, level, or category to
document in the table this section would otherwise carry.

## Platform Notes

- **Python** (source platform): `apt_terminal.cli:_run` is the process entry
  point (`pyproject.toml`'s `[project.scripts]`). The package depends on
  `typer` (command parsing), `httpx` (the transport, both directly in
  `auth.py` and via the generated client), `attrs` (body models and
  `coerce_enums`'s field introspection), `rich` (terminal rendering), and
  `tomli`/`tomli_w` (config I/O) — a from-scratch port on another platform
  needs equivalents for all five roles, not just the HTTP client.
- **TypeScript/Node (CLI)**: model the same layering as three modules —
  a config store (`conf` or a hand-rolled TOML/JSON file with `0o600`
  permissions), a session/auth client wrapping `fetch`/`undici` with the
  same login/refresh/logout/whoami contract, and a command layer (`commander`
  or `oclif`) that mirrors `build_resource_app`'s declarative
  list/get/create/update/delete/actions dispatch over a generated OpenAPI
  client (e.g. `openapi-typescript-fetch` or `openapi-fetch`).
- **Swift (Apple, CLI or app)**: `ArgumentParser` for the command layer,
  `URLSession` for the transport (mirroring the raw-request, not
  generated-parser, execution path), `Codable` types generated from the same
  OpenAPI document, and the Keychain — not a plaintext file — for
  `access_token`/`refresh_token` storage, which is a deliberately *stronger*
  choice than the source's `0o600` TOML file, not a straight port of it.
- **Kotlin (Android or JVM CLI)**: `clikt` for the command layer, `OkHttp`
  or `ktor-client` for the transport, `kotlinx.serialization` for the
  generated models, and Android's `EncryptedSharedPreferences` (or the JVM
  equivalent for a desktop tool) in place of a plaintext config file for the
  same reason as the Swift note.
- **WinUI 3**: this is the platform this recipe exists to prepare a port
  for, and — as a CLI rather than a windowed app — the natural target is a
  .NET **console** project (`System.CommandLine` for the command layer, not
  WinUI controls), using `HttpClient` for the transport (explicitly setting
  `HttpClient.Timeout` to a finite value, since `no-request-timeout` above
  shows the source itself never sets one — an absence this port should not
  reproduce), `System.Text.Json` for the
  generated request/response models (mirroring the OpenAPI document this
  package's `generated/` tree was produced from), `Task`/`async`/`await`
  for the request pipeline (the 401-retry-once logic in `execute()`/
  `whoami()` translates directly to one `await`ed retry, no concurrency
  primitives needed since the source itself is single-threaded), and
  `Windows.Storage.ApplicationData.Current.LocalSettings` or DPAPI
  (`ProtectedData`) — again stronger than the source's plaintext TOML — for
  persisting `access_token`/`refresh_token` per profile. If a WinUI 3
  *window* ever wraps this client (rather than a console host), wrap the
  profile/session state in an `INotifyPropertyChanged`-conforming type only
  where a XAML view needs to data-bind to `logged_in`/`profile.name`
  directly, mirroring `cli.py`'s `config show` command's own three fields.

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | partial | Security |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [secure-transport](agenticdevelopercookbook://compliance/security#secure-transport) | partial | Security |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | failed | Reliability |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |

`separation-of-concerns` is passed: configuration, authentication, request
building, resource commands, and CLI dispatch each live in their own module
(see Overview), and no module reaches into another's file or HTTP state.
`unit-test-coverage` is partial: the seven test modules (`test_auth.py`,
`test_auth_commands.py`, `test_cli.py`, `test_config.py`, `test_crud.py`,
`test_public.py`, `test_resources.py`) cover the great majority of this
contract, but `whoami()`'s 401-retry-then-fail branch, `config.py`'s
missing-file and malformed-file `load()` branches, and `save()`'s
omit-when-`None` serialization are not exercised by any given test (each is
called out individually above). `secure-storage` is partial: `save()` creates
and tightens the config file to `0o600` on every write
(`test_save_sets_0600`), but the tokens live in that plain TOML file rather
than the operating system's credential store. `input-sanitization` is
passed: `build_body` rejects unknown fields and validates enum values against
the model's declared choices before any request is sent. `secure-transport`
is partial: neither `client_factory()` nor `public_client()` enforces
`https://` on `base_url`, so an overridden base URL may be plain HTTP.
`timeout-handling` is failed: neither client passes a `timeout=` argument
(see no-request-timeout). `explicit-error-handling` is partial: every
authenticated and public request path raises a named, message-bearing
`AptError` subtype with a distinct exit code, but `logout()`'s server-side
revoke failure is swallowed with no signal to the caller — the open question
on logout-revoke-failure-swallowed.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Compliance rows mapped onto catalog checks (secure-storage, secure-transport, timeout-handling); separation-of-concerns added |
| 1.0.2 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
