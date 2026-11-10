
| Option | Behavior |
|--------|----------|
| Dynamic Type / Font Scaling | Font size (`1.02rem`) and measure (`max-width: 72ch`, see **constrain-paragraph-measure**) are set in relative units, so the rendered paragraph scales with the user's font-size and browser-zoom preference without truncation. |
| Color Contrast | Text renders in the `--lp-ink-dim` token (fallback `#a0a0a0`); it MUST meet WCAG AA contrast against its background (see **Compliance**). |
| Reduce Motion | Not applicable — Lede has no animation or transition. |

