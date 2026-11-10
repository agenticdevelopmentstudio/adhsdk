
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not respected: the companion `registry-mark.css` applies its hover/focus bloom (`filter` transition) and popover fade/slide transitions unconditionally; neither is gated behind `prefers-reduced-motion` |
| Increase Contrast | Not applicable: the @ glyph and star colors come from `currentColor` (host-controlled) and a fixed hex; the component and its companion CSS define no separate high-contrast styling |
| Differentiate Without Color | Not applicable: the mark conveys no state through color alone — the @ glyph and star are always both present regardless of tint |

