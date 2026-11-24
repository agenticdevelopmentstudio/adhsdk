
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `htd.back` | "Back" | Back button text and `aria-label`, shown in narrow mode (every disclosure style) and in `minimized` style's drill-down Back. |
| `htd.autoHide.on` | "Auto-hide parent topic lists: on — show them all" | `aria-label`/`title` on the root list's auto-hide toggle when auto-hide is on. |
| `htd.autoHide.off` | "Auto-hide parent topic lists: off — hide all but the last" | `aria-label`/`title` on the root list's auto-hide toggle when auto-hide is off. |
| `htd.cover.cover` | "Cover previous list (⌘/Ctrl-click: cover all)" | `aria-label`/`title` on a `covered`/`cascading` list's pin toggle when it covers its parent. |
| `htd.cover.uncover` | "Uncover previous list (⌘/Ctrl-click: uncover all)" | `aria-label`/`title` on the same toggle when it uncovers its parent. |
| `htd.immerse.hide` | "Hide the topic lists" | `aria-label`/`title` on the cascading style's detail-immersion toggle when the lists are shown. |
| `htd.immerse.show` | "Show the topic lists" | `aria-label`/`title` on the same toggle when the lists are immersed. |

All other user-facing strings (row labels, `rootLabel`, `trailingCrumbs`, `detailTitle`, `help`, item labels, `emptyLabel`, `newLabel`) are supplied by the host as props; the keys above are the ones the component generates itself and does not externalize.

