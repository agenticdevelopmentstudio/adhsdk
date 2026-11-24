
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `levels` | `TopicLevel[]` | — (required) | The rail levels, outermost first. Each level's selection scopes the next. |
| `rootLabel` | `string` | — | Leading breadcrumb label; its crumb deselects every level. Omitted starts the trail at the first selection. |
| `trailingCrumbs` | `{ label: string }[]` | — | Non-interactive crumbs appended after the level crumbs. |
| `toolbar` | `ReactNode` | — | Content for the full-width strip above the breadcrumb; an empty toolbar slot collapses the strip. |
| `help` | `ReactNode` | — | Right-justified affordance on the breadcrumb bar. |
| `showBreadcrumb` | `boolean` | `true` | Show the breadcrumb trail. |
| `minDetailWidth` | `string` (CSS length) | `"28rem"` | Minimum width of the detail pane; the component drills down (hides ancestor lists) to protect it. |
| `detailTitle` | `ReactNode` | — | Title shown in the detail pane's top strip. |
| `exitGuard` | `PaneExitGuard \| null` | `null` | The leaf editor's unsaved-work guard (see **guard-exit**). |
| `manualCollapse` | `boolean` | `true` | Keep the per-list manual pin toggle in `minimized` style (see **pin-toggle**). |
| `disclosureStyle` | `"minimized" \| "covered" \| "cascading"` | `"covered"` | How ancestor lists yield room to the detail as the window narrows (see **disclosure-styles**). |
| `autoHideTopics` | `boolean` | `true` | Start with every list above the frontier hidden (see **autohide**). |
| `layoutMode` | `"auto" \| "wide" \| "narrow"` | `"auto"` | Wide (columns beside detail) vs. narrow (one full-width pane at a time). |
| `children` | `ReactNode` | — (required) | Innermost detail content for the current selection. |

### `TopicLevel` (each entry of `levels`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | `string` | — (required) | Stable key for the level. |
| `title` | `string` | — | Heading shown above the rows. |
| `items` | `TopicDetailItem[]` | — (required) | The rows for this level (rendered by the TopicRail ingredient — see [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f)). |
| `selectedId` | `string \| null` | — (required) | This level's current selection. |
| `defaultSelectedId` | `string` | — | Item to select the moment this level appears with nothing chosen (see **default-select**). |
| `onSelect` | `(id: string, opts?: { replace?: boolean }) => void` | — (required) | Make `id` the selection at this level. |
| `onClear` | `() => void` | — (required) | Clear this level and everything below it. |

