
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

