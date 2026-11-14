The source platform is Python (`apt_terminal.cli:_run`, the `pyproject.toml`
`[project.scripts]` entry point), built on `typer` (command parsing), `httpx`
(the transport, both directly in `auth.py` and via the generated client),
`attrs` (body models and `coerce_enums`'s field introspection), `rich`
(terminal rendering) and `tomli`/`tomli_w` (config I/O); a from-scratch port
needs an equivalent for all five roles, not just the HTTP client. This is a
headless CLI, so the UI platforms below describe the port of the engine, and
none of them draws a view.

- **SwiftUI**: Not a UI port. Use `ArgumentParser` for the command layer,
  `URLSession` for the transport (mirroring the raw-request, not
  generated-parser, execution path), `Codable` types generated from the same
  OpenAPI document, and the Keychain, not a plaintext file, for
  `access_token`/`refresh_token` storage, which is a deliberately *stronger*
  choice than the source's `0o600` TOML file, not a straight port of it. A
  SwiftUI app would wrap the profile and session state in an `@Observable`
  type.
- **Compose**: Not a UI port. Use `clikt` for the command layer, `OkHttp` or
  `ktor-client` for the transport, `kotlinx.serialization` for the generated
  models, and Android's `EncryptedSharedPreferences` (or the JVM equivalent
  for a desktop tool) in place of a plaintext config file, for the same
  reason as the Swift note.
- **React/Web**: Not a browser port. For a Node CLI, model the same layering
  as three modules: a config store (`conf` or a hand-rolled TOML/JSON file
  with `0o600` permissions), a session/auth client wrapping `fetch`/`undici`
  with the same login/refresh/logout/whoami contract, and a command layer
  (`commander` or `oclif`) that mirrors `build_resource_app`'s declarative
  list/get/create/update/delete/actions dispatch over a generated OpenAPI
  client (for example `openapi-typescript-fetch` or `openapi-fetch`).
- **AppKit / UIKit**: Not applicable: a CLI has no view layer. A macOS
  command-line port follows the SwiftUI note above.
- **WinUI 3**: this is the platform this ingredient exists to prepare a port
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

