
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config` (web) | `CharacterConfig` | none — required | Passed to `createSvgRenderer` and `renderToString`; supplies `character.canvas.{w,h}` for the `<svg>` `viewBox` and `character.strokeStyle.{width,linecap,linejoin}` for a stroked item's defaults. |
| `doc` (web) | `Document` | `document` (the global) | Passed to `createSvgRenderer`; injected so the renderer can run against a fake `Document` in tests or any non-browser host. |
| `d` (apple) | `String` | none — required | The path-data argument to `CGPath.avatarItem(_:)`. |
| hex string (apple) | `String` | none — required | The `#rrggbb`/`#rgb` argument to `CGColor.avatarInk(_:)`. |
| `m` (apple) | `Mat` | none — required | The 2×3 affine argument to `CGAffineTransform.init(_:)`. |
| `target`/`selector`/`action` (apple) | `AnyObject`/`Selector` | none — required | Arguments to `Platform.displayLink(on:target:selector:)`, `.makeTapRecognizer(target:action:)`, and `.makeDragRecognizers(target:action:)`. |

Neither file reads an environment variable, a `UserDefaults`/settings key, or
a config file directly; every parameter above is supplied by the caller at
the call site.

