
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

