
**TopicDetail props:**
- `items: TopicDetailItem[]` — list of row objects (required)
- `selectedId: string | null` — the currently selected item's id
- `onSelect: (id: string) => void` — called when a non-disabled row is clicked
- `emptyLabel?: ReactNode` — text shown when `items` is empty (default "Nothing here yet.")
- `railSlot?: RailSlot` — optional leading row above topics (a function can receive collapsed state)
- `railSlotActive?: boolean` — move the gold bar onto the rail slot (nothing selected in list)
- `onNew?: () => void` — create affordance; fires when the `+` button is clicked
- `newLabel?: string` — accessible name + tooltip for the `+` (default "New")
- `newActive?: boolean` — tint the `+` gold (create in progress, nothing selected)
- `hideItemIcons?: boolean` — drop the leading icon from rows in expanded list only
- `panePadding?: boolean` — add standard inset to pane (default true)
- `collapsed?: boolean` — controlled collapse state (omit for self-managed)
- `onCollapsedChange?: (collapsed: boolean) => void` — called when collapse state changes
- `defaultCollapsed?: boolean` — initial collapse state in uncontrolled mode (default false)
- `railWidth?: number` — the rail's full width in px (default 240)
- `children: ReactNode` — the detail pane content

**TopicRail props** (a public export in its own right — the single-column rail that `TopicDetail` composes with the pane; the hierarchical stack recipe composes `TopicRail` directly for its multi-column layout):
- All TopicDetail props, plus:
- `title?: string` — render a titled header with this text
- `titleActions?: ReactNode` — extra controls in titled header, right-justified before toggle
- `headerSlot?: ReactNode` — pinned strip below titled header (filter + actions)
- `onResize?: (widthPx: number) => void` — drag handle fires with new width
- `onResizeStart?: () => void`, `onResizeEnd?: () => void` — drag lifecycle
- `footer?: ReactNode` — pinned strip at rail bottom
- `backSlot?: ReactNode` — optional back button top-left
- `leftControl?: ReactNode` — optional control replacing top-left (e.g., covered `«`/`»`)
- `showToggle?: boolean` — show desktop collapse toggle (default true)
- `coveredShadow?: boolean` — cast left drop-shadow (default false)
- `covered?: boolean` — render as icon-only left-aligned strip
- `isRoot?: boolean` — this is the root list (marker-style root dash)
- `selectionStyle?: "bar" | "marker"` — how to mark selection
- `rowDisclosure?: boolean` — show chevron on rows
- `onClose?: () => void` — close button fires
- `closeLabel?: string` — accessible name for close button (default "Close")
- `denseBottom?: boolean` — tighten bottom padding
- `hoverBar?: boolean` — show bar on hover (default true)
- `onPrefetch?: (id: string) => void` — prefetch callback
- `checkable?: boolean` — show checkboxes in batch mode
- `checkedIds?: ReadonlySet<string>` — which rows are checked
- `onToggleChecked?: (id: string) => void` — checkbox toggle fires
- `onFit?: (widthPx: number) => void` — report intrinsic row width
- `railLabel?: string` — accessible name for the `<aside>` (default "Topic list")
- `busy?: boolean` — show loading spinner
- `className?: string` — extra classes on the rail root

**TopicDetailItem shape:**
```
{
  id: string;                           // unique identifier (required)
  label: string;                        // primary text (required)
  labelSuffix?: ReactNode;              // additional text on label's line (name component)
  sublabel?: string;                    // secondary line or inline text (metadata)
  inlineSublabel?: boolean;             // render sublabel on label's line (label-priority)
  preview?: string;                     // content preview (clamped to previewLines)
  previewLines?: number;                // 0-4 lines (default 1)
  description?: string;                 // NOT rendered by this component (legacy, for other surfaces)
  icon?: ReactNode;                     // 16px icon (neutral ring fills in when omitted)
  leadsTo?: "list" | "detail";          // where this row leads (default "detail"); NOT read by this component
                                         // (legacy pass-through for a cascading/hierarchical consumer, like `description`)
  dividerAfter?: boolean;               // render separator after item
  spacerAfter?: boolean;                // render flexible spacer after item
  disabled?: boolean;                   // dimmed, non-clickable
  trailing?: ReactNode;                 // right-justified accessory (expanded only)
  onDelete?: () => void | Promise<void>; // async delete handler
  deleteLabel?: string;                 // accessible name for delete (defaults to label)
  deleteConfirm?: ReactNode;            // confirmation dialog body (default "This action can't be undone.")
  blocked?: boolean;                    // amber dot + sr-only "needs attention"
}
```

**Exported types and constants:**
- `TopicDetail`, `TopicRail`, `TopicDetailItem`, `RailSlot` (component/types). `TopicList` is a module-private helper (no `export` keyword) — not part of the public API.
- `FULL_RAIL = 240` (full rail width in px)
- `COLLAPSED_RAIL = 48` (collapsed icon-only strip width)
- `MIN_FIT_RAIL = 150`, `MAX_FIT_RAIL = 420` (auto-fit clamping range)
- `rootFontPx()`, `railPx(designPx)` (utility functions for font-relative sizing)

