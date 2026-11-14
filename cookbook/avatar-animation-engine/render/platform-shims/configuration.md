
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` (web) | `CharacterConfig` | none — required | Passed to `createSvgRenderer` and `renderToString`; supplies `character.canvas.{w,h}` for the `<svg>` `viewBox` and `character.strokeStyle.{width,linecap,linejoin}` for a stroked item's defaults. |
| `doc` (web) | `Document` | `document` (the global) | Passed to `createSvgRenderer`; injected so the renderer can run against a fake `Document` in tests or any non-browser host. |

Neither file reads an environment variable, a `UserDefaults`/settings key, or
a config file directly. The remaining inputs (a path-data string, a hex ink
string, a `Mat`, a target/selector/action) are ordinary function arguments,
specified in Behavioral Requirements.

