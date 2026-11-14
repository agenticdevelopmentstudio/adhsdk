
This layer takes no defaults, environment variables, settings keys, or
injected dependencies — every operation is an explicit function call with
explicit arguments. The table below lists the parameters each public
operation's caller supplies.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `d` (`parsePath`) | `String` / `string` | none — required | Path-data string to parse into a `ParsedPath`. |
| `p` (`emitPath`, `promotePolyline`) | `ParsedPath` | none — required | The parsed path to serialize or re-express. |
| `v` (`fmt`) | `Double` / `number` | none — required | The coordinate value to format for path-data output. |
| `cx, cy, rx, ry` (`cubicO`) / `cx, cy, r` (`disc`) | `Double` / `number` | none — required | Center and radii of the ellipse or circle to draw. |
| `cx, cy, r, band` (`ring`) | `Double` / `number` | none — required | Center, outer radius, and band (stroke) width of the annulus. |
| `cx, cy, r, from, to` (`arc`) | `Double` / `number` | none — required | Center, radius, and start/end angle in degrees (screen-space, `y` down). |
| `points` (`polyline`, `bezier`) | `[[Double]]` / `readonly (readonly [number, number])[]` | none — required | Ordered `[x, y]` pairs the shape is built from. |
| `a, b, t` (`morphPath`) | `ParsedPath`, `ParsedPath`, `Double` / `number` | none — required | The two paths to interpolate and the (unclamped) interpolation factor. |
| `segments` (`promotePolyline`) | `Int` / `number` | none — required | The target cubic-segment count; MUST be a whole multiple of the polyline's line count. |

