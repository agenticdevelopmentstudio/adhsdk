
| State | Appearance change |
|---|---|
| Default (`neutral`) | `apt-text-muted` fill + muted glow |
| Tinted (`success`/`error`/`accent`/`blue`/`orange`/`muted`) | Fill and glow both recolor to the tone's `apt-*` color |
| Small (`size` < 10) | Dot shrinks; glow clamps to a 6 px floor so it stays visible |
| Large (`size` ≥ 12) | Dot grows; glow radius scales to `round(size * 0.55)` px, which first exceeds the 6 px floor at `size` 12 (sizes 10 and 11 still sit at the floor) |
| Labeled | Announced as an image named `label` (`role="img"`) |
| Decorative (no `label`) | `aria-hidden`; ignored by AT |

