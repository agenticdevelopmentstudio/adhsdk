
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sizeScale` | `Double` | `1.0` | Global multiplier on every role's base size; the theme designer's scale (for example a typeface that draws small for its point size) |
| `styles` | `[String: FontStyle]` | `[:]` | Per-role overrides keyed by `TextRole.rawValue`; absent roles use `defaultStyle(_:)` |
| `FontStyle.family` | `String?` | `nil` | Font family name; `nil` is the system font |
| `FontStyle.size` | `Double` | required | Base point size before `sizeScale` |
| `FontStyle.weight` | `FontWeight` | `.regular` | Font weight |
| `FontStyle.monospaced` | `Bool` | `false` | Resolve to a monospaced font |
| `sizeScaleRange` | `ClosedRange<Double>` | `0.5...4` | Bounds a scale from outside the type may take |

The type reads no environment variables or settings keys and takes no injected dependencies.

