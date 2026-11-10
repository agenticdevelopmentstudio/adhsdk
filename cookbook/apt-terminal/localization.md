
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

