
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | String | "" | The pane's title text, displayed in the label and as tooltip when non-empty. |
| `accessoryViews` | [NSView] | [] | Array of views to display between title and gear, in left-to-right order. |
| `gearView` | NSView? | nil | Optional view for the trailing gear button or menu control, positioned at trailing edge. |
| `controls` | `PaneControlCluster` (read-only) | instantiated internally | The leading close/minimize/zoom cluster; not configurable by callers beyond what `PaneControlCluster` itself exposes. See **leading-controls-cluster**. |
| `yieldWidthToContainer()` | Method | not called (opt-in) | One-way switch: sets the horizontal compression resistance of the bar and every current and future subview (including the gear) to priority 1. Cannot be undone; see **honor-yield-width-request** and **apply-yield-to-future-subviews**. |

