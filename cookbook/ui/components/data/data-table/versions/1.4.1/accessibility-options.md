
| Option | Behavior |
|---|---|
| Reduce Motion | Not honored: a dragged row's transform (`drag?.style`) is applied unconditionally, with no `prefers-reduced-motion` check. |
| Increase Contrast | Not applicable: DataTable renders no direct colors — foreground/background come entirely from the caller's `apt-*` design tokens. |
| Differentiate Without Color | Partially addressed: selection is conveyed through `aria-selected`/`data-selected` plus a background tint together, not color alone, but no additional non-color marker (e.g. an icon) is added. |

