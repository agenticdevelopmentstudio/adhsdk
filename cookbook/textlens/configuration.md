
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `elements` (`createLens`'s first argument) | `readonly HTMLElement[]` | — (required) | The text-bearing elements to split and sweep. |
| `options.radius` | `number` (CSS px) | `55` | Half-width of the lens; glyphs whose measured centre is farther than this from the sweep centre are left at rest. |
| `options.duration` | `number` (ms) | `8000` | Time for one pass across the text in one direction; the return pass takes the same duration again. |
| `options.scale` | `number` | `0.25` | Extra scale applied at the dead centre of the lens (`0.25` means `125%`). |
| `options.blur` | `number` (CSS px) | `0.35` | Blur applied at the dead centre of the lens; `0` disables it (see **blur-floor**). |
| `options.fromColor` | `string \| undefined` | `undefined` | Colour a glyph holds at rest: a hex/`rgb()` literal or a `--custom-property` name read off the element. Must be given together with `toColor` or omitted (see **colour-ramp-pairing**). |
| `options.toColor` | `string \| undefined` | `undefined` | Colour a glyph reaches at the dead centre of the lens; same forms and pairing rule as `fromColor`. |
| `options.respectReducedMotion` | `boolean` | `true` | When `true`, `prefers-reduced-motion: reduce` makes `start()` a no-op (see **reduced-motion-gate**). |
| `useTextLens`'s `containerRef` | `RefObject<HTMLElement \| null>` | — (required) | The container whose descendants are searched for `selector`. |
| `useTextLens`'s `selector` | `string` | — (required) | CSS selector (relative to the container) for the elements to split and sweep, e.g. `'.tag'`. |
| `useTextLens`'s `enabled` | `boolean` | `true` | `false` destroys the lens and returns its glyphs to rest; `true` (re)builds and starts it. |
| `useTextLens`'s `startDelay` | `number` (ms) | `0` | Delay before the FIRST sweep only; re-enabling later starts immediately (see **resweep-is-immediate-after-the-first**). |

