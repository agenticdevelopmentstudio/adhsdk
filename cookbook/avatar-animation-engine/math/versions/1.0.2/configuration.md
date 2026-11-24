
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hex` (parseHex) | `String` / `string` | — (required) | A 3- or 6-digit hex color, with or without a leading `#`, with or without surrounding whitespace. No default; every call must supply one. |
| `t` (mix/mixColor) | `Double` / `number` | — (required) | Interpolation position between two colors. Values `<= 0` or `>= 1` snap to an endpoint (`mix-endpoint-exactness`); values inside `(0,1)` are used as given, unclamped. |
| `name` (Ease.resolve/resolveEase) | `String` / `string` | — (required) | One of the 24 closed vocabulary names. No default; no partial match. |
| `x`, `y` (Mat.from/fromTransform) | `Double` / `number` | `0` | Translation applied after the pivoted rotate/scale. |
| `rotation` (Mat.from/fromTransform) | `Double` / `number` | `0` | Degrees, converted internally to radians. |
| `scaleX`, `scaleY` (Mat.from/fromTransform) | `Double` / `number` | `1` | Scale factors applied about `pivot`. |
| `pivot` (Mat.from/fromTransform) | `(Double, Double)` / `readonly [number, number]` | `(0, 0)` | Absolute design-space point that rotation and scale are performed about. |
| `seed` (Prng init/createPrng) | `UInt32` / `number` | — (required) | Seed expanded via `splitmix32` into the four-word xoshiro128** state. No default; callers that want reproducibility supply a fixed seed. |
| `lo`, `hi` (Prng.range) | `Double` / `number` | — (required) | Inclusive lower / exclusive upper bound; no validation that `lo <= hi`. |
| `m` (Prng.signed) | `Double` / `number` | — (required) | Symmetric magnitude; result is drawn from `[-m, m)`. |
| `p` (Prng.chance) | `Double` / `number` | — (required) | Probability threshold compared against `float()`; not clamped to `[0,1]` by the source. |
| `items` (Prng.pick/pickOrNil/pickOrUndefined) | `[T]` / `readonly T[]` | — (required) | Candidate list; emptiness is a caller/config contract violation for `pick`, and the defined empty case for `pickOrNil`/`pickOrUndefined`. |

There are no environment variables, settings keys, or injected dependencies
anywhere in these four files — all configuration is passed as explicit
function/initializer arguments.

