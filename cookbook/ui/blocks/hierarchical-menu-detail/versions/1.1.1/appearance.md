
- **Rail layout**: Each list column is a vertical stack with a header (level title + toggles) and a scrollable item list below.
- **Header height**: 2.15rem (approximately 34px at 16px base font).
- **List item styling**: Rows inherit from the TopicRail ingredient (see [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f)); no fixed height specified in this component.
- **Text styling**: List headers use monospace, 0.8rem (12.8px), muted color. Breadcrumb uses the same monospace + 0.75rem.
- **Border**: 1px solid, using the theme's border colour token.
- **Background**: Lists use the navigation-surface background colour; the detail pane uses the content-surface background colour.
- **Spacing**: Breadcrumb has 4px–16px padding, 12px gaps between crumbs. Rails have no padding outside the item list (scrollable area consumes container).
- **Selection connector**: Elbow path in the theme's selection accent colour, 2px stroke, drawn over the list area (pointer-events-none).
- **Toggle icons**: 16px icons — a panel-open/closed pictogram for the auto-hide toggle, and a chevrons-left/right pictogram for both the per-list pin toggle and, in cascading style, the detail-immersion toggle (same icon pair, two different controls).
- **Focus indicator**: 2px ring in the theme's selection accent colour at reduced opacity, on keyboard focus for breadcrumb crumbs and header toggles.

