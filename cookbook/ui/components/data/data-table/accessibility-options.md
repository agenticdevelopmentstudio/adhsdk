
| Option | Behavior |
|---|---|
| Reduce Motion | Not honored: a dragged row's transform (`drag?.style`) is applied unconditionally, with no `prefers-reduced-motion` check. |
| Increase Contrast | Not verified: DataTable picks design tokens (`apt-*`) for its text, header, hover and selected backgrounds, so contrast depends on the theme's token values, which the source does not check. |
| Differentiate Without Color | Partially addressed: selection is conveyed through `aria-selected`/`data-selected` plus a background tint together, not color alone, but no additional non-color marker (e.g. an icon) is added. |

