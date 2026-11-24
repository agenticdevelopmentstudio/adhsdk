
| State | Appearance change |
|-------|------------------|
| Default (shelf hidden) | Shelf pane collapsed to zero width; the content pane fills the window; persisted visibility is false |
| Shelf visible | Shelf pane at its remembered width (180 to 480 points) beside the content pane, divider drawn between them |
| Sliding in | Shelf host width walks from 0 to the open width over 0.2 seconds with smoothstep easing; the content pane narrows by the same amount on every frame |
| Sliding out | Shelf host width walks from its current width to 0 over 0.2 seconds; the pane collapses when the slide lands |
| Dragging | The reader moves the divider; the shelf width follows within 180 to 480 points and is persisted on each step |
| No shelf | Only the content pane exists; shelf requests do nothing |
| Pressed | Not applicable: the component is a container with no pressed styling; the divider's drag is the Dragging state. |
| Disabled | Not applicable: the source exposes no enabled flag; a shelfless window is the No shelf state. |
| Focused | Not applicable: the component never takes keyboard focus itself; focus moves to the shelf's filter only through `panel-toggle-show`. |
| Loading | Not applicable: nothing is fetched or awaited; a slide is the only timed state. |

