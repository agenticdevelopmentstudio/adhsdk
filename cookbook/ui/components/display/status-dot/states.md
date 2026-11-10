
| State | Appearance change |
|---|---|
| Default (`neutral`) | `apt-text-muted` fill + muted glow |
| Tinted (`success`/`error`/`accent`/`blue`/`orange`/`muted`) | Fill and glow both recolor to the tone's `apt-*` color |
| Small (`size` < 10) | Dot shrinks; glow clamps to a 6 px floor so it stays visible |
| Large (`size` big) | Dot grows; glow radius scales to `round(size * 0.55)` px |
| Labeled | Announced as an image named `label` (`role="img"`) |
| Decorative (no `label`) | `aria-hidden`; ignored by AT |

