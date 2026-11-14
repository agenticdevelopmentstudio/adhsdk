
| Option | Type | Default | Description |
|---|---|---|---|
| `text` | `string` | — (required) | The text the lens rides over. |
| `active` | `boolean` | — (required) | Run the lens; false keeps the plain, un-split text. |
| `as` | `keyof JSX.IntrinsicElements` | `"p"` | Element to render (must be a real DOM element). |
| `resetKey` | `string \| number` | the `text` | Re-split + re-measure (and remount) when it changes. |
| `colorFrom` | `string` | `"currentColor"` | Glyph colour at the lens edge. |
| `colorTo` | `string` | `"currentColor"` | Glyph colour at the lens centre (equal to `colorFrom` = no shift). |
| `radius` | `number` | `44` | Lens influence radius in px. |
| `maxScale` | `number` | `0.18` | Extra scale at the lens centre (1 → 1+maxScale). |
| `maxBlur` | `number` | `0.4` | Blur in px at the lens centre. |
| `msPerChar` | `number` | `48` | Travel speed: ms the lens spends per glyph. |
| `minDuration` | `number` | `4500` | Floor (ms) so short strings don't whip past. |
| `pauseMs` | `number` | `0` | Idle hold (ms) before each sweep; 0 = continuous loop. |
| `className` / `style` | `string` / `CSSProperties` | — | Passed to the rendered element. |

`useTextBubble<T>(options)` returns a `RefObject<T | null>` to attach to any real
DOM element; `TextBubble` is the ready-made wrapper around it.

