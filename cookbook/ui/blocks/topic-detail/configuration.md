
**TopicDetail props**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `TopicDetailItem[]` | required | Row objects |
| `selectedId` | `string or null` | required | Selected row id |
| `onSelect` | `(id) => void` | required | Called on a click of an enabled, non-link row |
| `emptyLabel` | `ReactNode` | "Nothing here yet." | Shown with no rows |
| `railSlot`, `railSlotActive` | `RailSlot`, `boolean` | none | Leading row above topics; bar on it |
| `onNew`, `newLabel`, `newActive` | function, string, boolean | none, "New", false | The `+` |
| `hideItemIcons` | `boolean` | false | Drop expanded-row icons |
| `panePadding` | `boolean` | true | Pane inset |
| `collapsed`, `onCollapsedChange`, `defaultCollapsed` | boolean, function, boolean | none, none, false | Collapse control |
| `railWidth` | `number` | 240 | Full rail width and drag clamp |
| `children` | `ReactNode` | required | Pane content |

**TopicRail props** add: `title`, `titleActions`, `search` (a `TopicListSearch`: `query`, `onQueryChange`, `placeholder`, `autoOpen`, `live`, `pending`), `headerSlot`, `footer`, `backSlot`, `leftControl`, `showToggle` (true), `onToggle` (required), `collapsed` (required), `onResize`, `onResizeStart`, `onResizeEnd`, `covered`, `coveredShadow`, `isRoot`, `selectionStyle` ("bar"), `rowDisclosure`, `onClose`, `closeLabel`, `denseBottom`, `hoverBar` (true), `onPrefetch`, `checkable`, `checkedIds`, `onToggleChecked`, `onFit`, `railLabel`, `busy`, `className`.

**TopicDetailItem fields**: `id`, `label`, `labelSuffix`, `sublabel`, `inlineSublabel`, `preview`, `previewLines` (1), `description` (not rendered), `icon`, `leadsTo` (not read), `onLink`, `dividerAfter`, `dividerLabel`, `spacerAfter`, `disabled`, `checkDisabled`, `trailing`, `onDelete`, `deleteLabel`, `deleteConfirm`, `blocked`.

**Exports**: `TopicDetail`, `TopicRail`, `ListToolButton`, `filterTopicItems`, `underlineMatch`, `topicLinkOf`, `rowExitEl`, `rootFontPx`, `railPx`, `LINK_FLASH_MS` (1000), `FULL_RAIL` (240), `COLLAPSED_RAIL` (48), `MIN_FIT_RAIL` (150), `MAX_FIT_RAIL` (420), and the types `TopicDetailItem`, `RailSlot`, `TopicListSearch`, `ListToolButtonProps`. `TopicList` is module-private.

