
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `delegate` | Delegate reference (optional, held weakly) | None | Receives tab lifecycle callbacks: new-tab request, select, active-tab change, close request, reorder. |
| `mainContentViewController` | Content reference (optional) | None | Shown in the shared content area while no tab is active. |
| `contentInsets` | Insets (top/left/bottom/right, points) | All zero | Gap held between the mounted content and the tab bars/edges around it. |
| `centerBackgroundColor` | Color (optional) | None | Overrides the shared content area's fill; unset falls back to the `windowBackground` role. |
| `centerOutlineColor` | Color (optional) | None | Overrides the shared content area's `1pt` border color; unset falls back to the palette's `outline` role. |
| Tab start inset | Number (points) per edge | `8` | Where a bar's first tab begins, measured along the bar from its start. |
| Edge enabled state | Boolean per edge | From `tabs.positions` while following the app-wide setting | Whether an edge's tab bar and tabs are shown at all. |
| `tabs.positions` | Set of edges (never empty) | The top edge alone | App-wide tab positions, set from System > General > Window Behavior > Tab position and View > Tab Position; a view or pane override takes precedence (a browser pane's is `browser.tabs.positions`). |
| Follows global tab positions | Boolean | `true` | Whether the view applies `tabs.positions`; becomes `false` on an explicit edge change or override. |
| Top accessory | View (optional) | None | Pinned above the shared content area regardless of enabled edges. |

