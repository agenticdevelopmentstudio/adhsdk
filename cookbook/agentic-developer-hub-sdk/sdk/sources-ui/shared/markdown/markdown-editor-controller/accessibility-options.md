
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component has no animated transitions. The 300ms preview debounce is a timing delay before a re-render, not motion, so it is unaffected by this setting. Pane switching (tabbed mode) is an instant, non-animated change. |
| Increase Contrast | Preview pane inherits contrast from MarkdownReadingPalette theme (e.g., "dark" or "high-contrast" theme). Host application may pass a high-contrast themeId prop. |
| Differentiate Without Color | If the layout toggle buttons use color alone to indicate state, add additional visual indicators (e.g., icon, checkmark, underline) to communicate the active mode without relying on color. |

