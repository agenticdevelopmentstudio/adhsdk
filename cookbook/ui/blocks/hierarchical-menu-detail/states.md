
| State | Appearance change |
|-------|------------------|
| Default (list disclosed, not selected) | Rows visible in normal text color. |
| Row selected | Row highlighted with the selection accent colour, as text or background (delegated to TopicRail). Breadcrumb shows row's label. Selection connector draws to this row. |
| Hovered (pointer over row) | Hover state delegated to TopicRail item renderer. |
| Focused (keyboard on row) | Focus-visible ring applied to interactive row element. |
| List hidden by autoHide or width pressure | Column slid off-screen (0-width, aria-hidden, pointer-events-none) or shown as icon strip only. |
| List pinned hidden | Hidden despite autoHide being false; toggle shows pin state. |
| List pinned disclosed | Disclosed despite autoHide being true; toggle shows pin state. |
| Covered style — covered list | List clipped to a 40px icon-only peek, occluded by its child list with a left drop-shadow (see **covered-peek**); header stays visible. |
| Cascading mode — revealed branch (hover) | All ancestor lists above hovered row expanded to full width for duration of pointer presence. |
| Narrow mode — alternate panes | One full-width pane visible; others hidden. Back button shows to navigate up. |
| Breadcrumb crumb hovered | Crumb colour changes to the primary text colour (lighter than the muted default). |
| Breadcrumb crumb focused | Focus-visible ring applied. |
| Detail guard dirty | Unsaved-changes alert shown on exit attempt. |

