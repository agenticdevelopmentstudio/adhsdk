
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

