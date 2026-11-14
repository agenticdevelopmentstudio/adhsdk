
| State | Appearance change |
|-------|------------------|
| Default | Text muted gray, no underline (transparent 2px border), bottom border on list visible |
| Active | Text full contrast, gold 2px bottom border, border overrides list border |
| Hover | Text full contrast, no change to border (border state unchanged) |
| Focused | Intended: a visible indicator distinct from hover. Current source: text full contrast (via `focus-visible`), no distinct focus ring — visually identical to hover; see **focus-visible-state** |
| Disabled | Intended: dimmed to 50% opacity, no hover response; click-activation blocked, keyboard focus still lands on the tab. Current source: no visual change (see **disabled-tabs**) |

