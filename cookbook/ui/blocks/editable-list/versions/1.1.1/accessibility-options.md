
| Option | Behavior |
|--------|----------|
| Reduce Motion | The `ResizableSplit` divider's expand/collapse animation MUST be suppressed when the app's `data-reduce-motion` setting is `"on"` (read from `document.documentElement.dataset.reduceMotion`); a direct drag is never animated regardless of the setting. |
| Increase Contrast | The component references named design tokens (`apt-gold`, `apt-border`, `apt-text-dim`, …) rather than fixed color values. Resolving those tokens to higher-contrast values under the platform's Increase Contrast setting is the responsibility of the token/theme layer — this component does not read the setting itself. |
| Differentiate Without Color | The hidden-selection count is never color-only: it MUST render as literal text ("(N not shown)"), with an accent color as a supplementary cue — see **show-hidden-selected-count**. Sort indicators MUST use (and already do use) a directional chevron icon alongside the header's sort state, so sort order is never conveyed by color alone. |

