---
id: 8fa7aaae-df62-44ea-b10c-182f3094ed9f
title: Topic Detail
domain: adhsdk://recipes/topic-detail
type: ingredient
version: 1.6.1
status: review
language: en
created: '2026-06-26'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The reusable two-pane primitive: a selectable topic list (left rail) beside a detail pane (right)."
platforms:
  - typescript
  - web
tags:
  - topic-detail
  - master-detail
  - two-pane
  - navigation
depends-on: []
related: []
references:
  - https://adh.com/home
approved-by: ''
approved-date: ''
---

# Topic Detail

## Overview

**TopicDetail** is the reusable two-pane primitive — a selectable topic list on the left rail beside a detail pane on the right (see References for its source layout). The pane itself is bare: no title row and no action bar of its own — that chrome (a titled header, the create `+`, a footer, a close button) belongs to the rail (`TopicRail`) and is composed there, not the pane. It is a faithful port of the source settings rail (CSS → utilities with `apt-*` tokens) so every consumer renders identically. It fills its container, so give it a height.

The topic list is always collapsible (a core part of the site design, not a config flag): a desktop collapse toggle shrinks the rail to a thin icon-only strip for more pane room. Every topic stays clickable as its icon, the active icon keeps the gold selection bar, and the header affordances stay put. On mobile (≤768px) the layout collapses to a single column, so the rail stacks above the detail pane as the same vertical list; only the desktop collapse toggle and the drag-resize handle are hidden there.

## Behavioral Requirements

- **render-two-panes**: The component MUST render a left topic-list rail beside a right detail pane.
- **mark-selected**: The list item whose `id` equals `selectedId` MUST be marked active (gold selection bar + `aria-current="true"`).
- **report-selection**: Clicking a non-disabled item MUST call `onSelect` with that item's `id` — including a re-click on the already-selected item, since the component has no deselect signal of its own. The one short-circuit is the covered style, where a click on an already-selected item is a no-op (see **support-covered-style**).
- **skip-disabled**: A `disabled` item MUST be dimmed and non-interactive on its row button (no `onSelect`). This does not affect the delete button: an `onDelete` item still renders its hover/focus-revealed trash button, enabled, on a disabled row (see **support-delete-action**).
- **render-label**: Each item MUST render its `label` as the primary text.
- **render-label-suffix**: An item with `labelSuffix` MUST render it on the same line as the label, distinct from `sublabel` (both are name components, not metadata).
- **render-inline-sublabel**: An item with `inlineSublabel=true` and a `sublabel` MUST render the sublabel on the SAME line as the label (dim), the label keeping layout priority (grows + truncates first) and the sublabel shrinking + truncating after it — instead of the default stacked second line. The inlineSublabel MUST have no effect in the collapsed/covered icon-only strip (which hides the label entirely).
- **render-stacked-sublabel**: An item with `sublabel` but no `inlineSublabel` MUST render the sublabel as a second line (dim, smaller text).
- **render-preview**: An item with `preview` text and `previewLines > 0` MUST render the preview as a third line block (dim, smaller text, clamped to the specified number of lines, preserving source line breaks).
- **clamp-preview**: `previewLines` MUST be clamped to 0-4 (`Math.max(0, Math.min(4, Math.trunc(...)))`) before use, defaulting to 1 when omitted — every input, in or out of range, resolves to a valid clamp class, never an unclamped fallback to full text. 0 renders no preview at all (allowing consumers to keep passing `preview` and toggle display via the `previewLines` number alone).
- **render-icon**: Each item MUST render a 16px leading icon; a neutral ring icon MUST fill in when `icon` is omitted.
- **hide-label-when-collapsed**: When the rail is collapsed to an icon-only strip, labels MUST be hidden and the item's `label` MUST be carried as an `aria-label` on the button element and shown in a right-side tooltip on hover/focus.
- **render-empty-label**: With no items, the rail MUST show `emptyLabel`.
- **support-rail-slot**: When `railSlot` is provided it MUST render in a leading slot above the topics, at a fixed minimum height (`min-h-[2.15rem]`); when no `railSlot` is provided, the slot is not rendered and no space is reserved for it, so the first topic row sits at the list's top padding instead. When `railSlotActive`, the selection bar MUST move onto that slot. A `(collapsed: boolean) => ReactNode` render-prop form MUST receive the rail's collapsed state so the slot can shrink (e.g., to an icon-only `+` when undisclosed).
- **render-divider-after**: An item with `dividerAfter=true` MUST render a separator line after it — in the full expanded rail AND in the collapsed/covered icon strips alike (using a tighter inset in the icon strips).
- **render-spacer-after**: An item with `spacerAfter=true` MUST render a flexible spacer after it that pushes all following items to the rail's bottom edge (e.g., a bottom-pinned Settings) — in the full expanded rail AND in the collapsed/covered icon strips alike.
- **respond-mobile**: At viewport width ≤768px the rail MUST NOT change its own layout — it stays the same vertical list (left selection bar, `border-r`); the grid collapses to a single column so the rail (first in the DOM) stacks above the detail pane, and the desktop collapse toggle and drag-resize handle MUST be hidden.
- **collapse-rail**: The rail is always collapsible — the component MUST offer a top-right desktop toggle (hidden on mobile ≤768px) that collapses the rail to a COLLAPSED_RAIL-width (48px) icon-only strip and expands it again. Collapsibility is intrinsic, not configurable.
- **support-controlled-collapse**: When `collapsed` + `onCollapsedChange` props are provided the collapse state MUST be controlled from outside; otherwise it MUST self-manage from `defaultCollapsed` (default false).
- **support-drag-resize**: When `onResize` is provided the component MUST render a drag handle on the rail's trailing edge (desktop only) that reports the column's new width as the user drags. Below `railWidth / 3` (a third of the full configured width — 80px at the default 240px) the rail MUST snap to collapsed. From that threshold up to `railWidth`, the rail MUST track the dragged width exactly (1:1). Past `railWidth`, the rail MUST clamp back to exactly `railWidth` (never overshoot).
- **transition-collapse**: Rail width changes MUST animate via CSS transition (respecting the user's `prefers-reduced-motion` OS setting); transition MUST be suppressed during active dragging.
- **support-trailing-accessory**: An item with `trailing` content MUST render it right-justified in the expanded list (hidden in collapsed/covered icon strips).
- **support-delete-action**: An item with `onDelete` callback MUST render a hover/focus-revealed trash button in the expanded list; clicking it MUST open a confirmation dialog. When confirmed (action button), the `onDelete` callback MUST run (may be async — dialog shows spinner until settled). Dialog is destructive (red action, initial focus on Cancel). When `onDelete` throws, dialog MUST remain open without spinner so the user can retry or cancel. Trash button MUST not render in collapsed/covered icon strips; it MUST still render, enabled, on a disabled row when `onDelete` is provided — the row's `disabled` flag gates only the row's own selection, not the delete button.
- **support-delete-label**: A deletable item with `deleteLabel` MUST use it as the accessible name for the trash button and the subject in the confirmation dialog title; otherwise default to the item's `label`.
- **support-delete-confirm**: A deletable item with `deleteConfirm` MUST render it as the confirmation dialog's body copy; otherwise default to "This action can't be undone."
- **render-blocked-marker**: An item with `blocked=true` MUST render an amber dot on the icon (visible in expanded, collapsed, and covered layouts — exactly where a user hunting for a greyed-out Save button needs to see it) and append a screen-reader-only ", needs attention" announcement to the row's accessible name. The row's button element MUST carry `data-blocked="true"` for programmatic selection.
- **support-header-slot**: When `headerSlot` is provided it MUST render as a full-width strip below the titled header (hidden while collapsed); this hosts the shared ListHeader (filter + actions) for entity lists in the stack.
- **support-titled-header**: When `title` is provided the rail MUST render a titled header row with: the title left-justified (aligned to the row-label column), a fixed control slot (16px, where row icons sit), optional `titleActions` right-justified before the toggle, a create affordance `+` right-justified (fires `onNew`), and a collapsible desktop toggle (`«`/`»`).
- **support-create-affordance**: When `onNew` is provided the rail MUST render a right-justified `+` button in the header (in titled or untitled headers). The button MUST tint gold when `newActive=true` (signalling in-progress create with nothing selected). Button MUST carry `aria-label` and tooltip with `newLabel` (default "New").
- **show-busy-indicator**: When `busy=true` the rail MUST show a small spinning indicator — immediately before the title (if titled) or in the top-right of the untitled header. The indicator MUST be present even on mobile (a read is worth announcing on mobile too), and MUST be paired with an `aria-live="polite"` announcement that says "Loading" when busy.
- **support-back-slot**: When `backSlot` is provided it MUST render in the top-left of the untitled header (e.g., a "Back" button).
- **support-left-control**: When `leftControl` is provided it MUST render in place of the top-left header content (e.g., a covered style's `«`/`»` cover toggle). In the untitled header, providing `leftControl` MUST suppress the desktop collapse toggle regardless of `showToggle`. In the titled header, `showToggle` is independent of `leftControl` — the caller MUST pass `showToggle=false` there to avoid also showing the desktop toggle alongside `leftControl`.
- **support-footer**: When `footer` is provided it MUST render as a pinned strip at the bottom of the rail (with a top border) — e.g., a "New…" affordance.
- **support-close-button**: When `onClose` is provided the rail MUST render a right-justified close button (✕) in the header — used by hierarchical stacks to dismiss child menus. Button MUST carry `aria-label` and tooltip with `closeLabel` (default "Close").
- **support-row-disclosure**: When `rowDisclosure=true` the component MUST render a right-justified chevron (ChevronRight, 14px) on every non-disabled selectable row in the expanded list (hidden in collapsed/covered and on disabled rows), signalling that picking it discloses another pane (narrow/nav-stack layout affordance).
- **support-covered-shadow**: When `coveredShadow=true` the rail MUST cast a subtle left drop-shadow (used by hierarchical stack to show physical layering of a child rail peeking over a covered parent).
- **support-covered-style**: When `covered=true` the rail MUST render rows as a left-aligned icon-only strip (icons centered, no labels or accessories). Clicking a covered row MUST never toggle/unselect — selecting simply changes the selection; clicking an already-selected row in covered style is a no-op.
- **support-marker-selection**: When `selectionStyle="marker"` the component MUST mark the selected row with a full-height left dash (root only) and parent→child connector line (drawn by hierarchical overlay), not the classic gold bar. Root rows get the dash; non-root rows are marked by the connector line alone.
- **support-hover-bar**: When `hoverBar=false` the component MUST NOT render a left bar on hover of unselected rows (used by cascade menus where hover is conveyed by row un-dimming and a bar would be noise).
- **hide-row-icons**: When `hideItemIcons=true` the component MUST drop the leading icon from every row in the expanded list (for identity-less lists like documents; collapsed/covered strips ignore this, they are always icon-only).
- **support-prefetch**: When `onPrefetch` is provided the component MUST call it with the row's `id` once pointer or keyboard focus has rested on that row for 100ms (fire-and-forget, no UI). Never arm on the already-selected row (its data is already loaded). Disarm on pointer/focus leave.
- **support-batch-mode**: When `checkable=true` the component MUST render a checkbox on every row in the expanded list (hidden in icon-only), allowing multiple selection independent of the active row selection. The active row's single selection behavior is preserved underneath — ticking a box is not selecting a row.
- **manage-batch-checked**: When `checkedIds` is provided the component MUST reflect its contents in the checkboxes (read-only from the component's side). Checking/unchecking a box MUST call `onToggleChecked` with that item's `id`; the owner writes back.
- **fit-width**: When `onFit` is provided the component MUST report the intrinsic width (`max-content`) of the rail's rows, clamped to [MIN_FIT_RAIL, MAX_FIT_RAIL] (150–420px default), immediately before paint and again when web fonts load (in px). Never report when collapsed (icon strip has a fixed width by definition). Used by hierarchical stack to auto-size the rail.
- **support-dense-bottom**: When `denseBottom=true` the rail's scrollable list MUST use tightened bottom padding (`pb-2`) instead of the default generous padding (`pb-8`) under the last row.
- **support-pane-padding**: When `panePadding=true` (default) the detail pane MUST add standard content inset (`gap-6 px-6 py-4`). When false, content is edge-to-edge so consumers can compose rows with their own insets.
- **fill-container**: The component MUST fill its container height and width — give it an explicit container height or a `flex-1` parent.

## Appearance

Grid layout: `md:grid-cols-[240px_minmax(0,1fr)]` (full rail 240px, collapsed 48px); below `md` the grid is a single column, so the rail (first in the DOM) stacks above the detail pane. Rail uses `bg-apt-nav` with `border-r` at every width. Rail items are monospace `text-[0.8rem]` tracking `0.02em` with a left selection bar (`border-l-2`) at every width: active = `border-l-apt-gold text-apt-gold`, hover = `border-l-apt-text`, disabled = `text-apt-text-dim`. At ≤768px the desktop collapse toggle and drag-resize handle are hidden (`max-md:hidden`); no other rail styling changes. The detail pane is `bg-apt-surface`; with `panePadding` it adds `gap-6 px-6 py-4`. Dividers use `bg-apt-border`. Blocked marker: amber `bg-apt-orange`. Header: `border-b border-apt-border`. Drag handle: `cursor-col-resize`, `hover:bg-apt-gold/40`. Create button + close button: `text-apt-text-muted` default, `hover:text-apt-text`, focused `ring-apt-gold/40`. Busy spinner: `text-apt-text-muted`, `animate-spin`. Delete button: `bg-apt-nav text-apt-text-dim`, `hover:text-apt-red`, focused `ring-apt-red/40`. No raw hex; no `!important`.

## States

| State | Appearance change |
|---|---|
| no selection | no active item (bar may sit on an active rail slot) |
| item active | gold left bar + gold text + `aria-current="true"` |
| item hover | text-colored left bar (if `hoverBar=true`) |
| item disabled | dimmed text, non-clickable |
| item blocked | amber dot on icon + sr-only announcement |
| rail collapsed | thin strip (48px) with `»` expand control |
| rail dragging | transition suppressed, tracks pointer live |
| delete pending | confirmation dialog open, spinner during async delete |
| batch: checkbox checked | box shows check mark |
| batch: checkbox unchecked | box empty |
| covered style | icon-only left-aligned strip |
| ≤768px | single-column grid: rail stacks above the pane, unchanged vertical list with left bar and `border-r`; collapse toggle and drag-resize handle hidden |
| `busy=true` | spinner visible in header / top-right of untitled header |
| `railSlot` active | gold bar on the slot (when nothing in list is selected) |
| selection style "marker" | full-height left dash (root) + connector line (hierarchical) instead of bar |

## Accessibility

Items are real `<button>` elements (keyboard focus + activation); the active item carries `aria-current="true"` and disabled items are native `disabled` buttons. Icon-only rows carry the item's `label` as `aria-label`. Divider rows use `role="separator"`. The desktop collapse toggle carries a fixed `aria-label` of "topic list" — this is not affected by `railLabel`. The rail's own `<aside>` landmark carries `aria-label={railLabel ?? "Topic list"}`, overridable independently of the toggle's label. Delete button: `aria-label="Delete {deleteLabel}"`. Create button: `aria-label="{newLabel}"` (default "New"). Close button: `aria-label="{closeLabel}"` (default "Close"). Resize handle: `role="separator"`, `aria-orientation="vertical"`, `aria-label="Resize topic list"` (drag only — no keyboard equivalent). Blocked state: `aria-label` includes ", needs attention" + decorative amber dot. Batch checkbox: `aria-label="{itemLabel}"`. Busy indicator: paired with `aria-live="polite" role="status"` region (text says "Loading" when busy, blank when not). Prefetch is fire-and-forget with no UI. Delete confirmation dialog is destructive (keyboard shortcuts off, initial focus on Cancel); the dialog's own focus trap is owned by the shared `AlertModal` ingredient, not this component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-two-panes | `items` + `children` | rail and pane both render, rail on left (desktop) |
| T2 | mark-selected | `selectedId="x"` | item x shows the gold bar + `aria-current="true"` |
| T3 | report-selection | click item "y" | `onSelect("y")` fires |
| T4 | skip-disabled | click a `disabled: true` item | no `onSelect` fires; item text dimmed; no hover bar |
| T5 | render-empty-label | `items=[]` | `emptyLabel` shown in the rail |
| T6 | support-rail-slot | `railSlot={(c)=>…}` + `railSlotActive: true`, collapsed | slot above topics; gold bar on the slot; render-prop gets `collapsed: true` → icon-only `+` |
| T7 | render-label | `items=[{id: "x", label: "A"}]` | text "A" shown on the row |
| T8 | render-label-suffix | `{label: "A", labelSuffix: "v2"}` | text "A v2" on the row (suffix distinct) |
| T9 | render-inline-sublabel | `{label: "A", sublabel: "b.com", inlineSublabel: true}` | single line: "A" (full width) "b.com" (dim, shrinks) |
| T10 | render-stacked-sublabel | `{label: "A", sublabel: "b.com"}` (no inlineSublabel) | two lines: "A" then "b.com" (dim, smaller) |
| T11 | render-preview | `{preview: "My note", previewLines: 2}` | three lines: label, sublabel (if set), preview (dim, 2-line clamp) |
| T12 | clamp-preview | `{preview: "Text", previewLines: 0}` | no preview shown (label/sublabel only) |
| T13 | render-icon | `{icon: <ChevronRight />}` | 16px icon rendered |
| T14 | render-icon | item with no `icon` prop | neutral ring icon (16px) fills in |
| T15 | hide-label-when-collapsed | `collapsed: true` | row shows only icon, label in `aria-label`, tooltip on hover/focus |
| T16 | render-divider-after | `{dividerAfter: true}` | separator line below the item, in expanded list and in collapsed/covered icon strips alike (tighter inset when collapsed) |
| T17 | render-spacer-after | `{spacerAfter: true}` at position 2 in 5-item list | items 3–5 sit at the rail's bottom edge |
| T18 | respond-mobile | viewport 375px width | single-column grid: rail (unchanged vertical list, left bar, `border-r`) stacks above the pane; collapse toggle and drag-resize handle hidden |
| T19 | collapse-rail | click the `«` toggle (toggle hidden at ≤768px) | rail narrows to 48px icon strip; icons keep gold bar; toggle becomes `»` |
| T20 | support-controlled-collapse | `collapsed: true`, `onCollapsedChange` set | toggling calls `onCollapsedChange(false)`; rail follows `collapsed` prop |
| T21 | support-drag-resize | drag trailing edge to 100px then 50px | `onResize(100)` fired; then snap to collapsed (48px) when crossing threshold |
| T22 | render-blocked-marker | `{blocked: true}` | amber dot on icon; `aria-label` says ", needs attention"; `data-blocked="true"` on row |
| T23 | support-delete-action | `{onDelete: async () => { … }}` | hover reveals trash button; click opens confirm dialog; confirm runs `onDelete` |
| T24 | support-delete-label | `{onDelete: () => {}, deleteLabel: "Workspace"}` | trash button `aria-label="Delete Workspace"`; dialog title `"Delete Workspace?"` |
| T25 | support-delete-confirm | `{onDelete: () => {}, deleteConfirm: "Permanent loss."}` | dialog body says "Permanent loss." |
| T26 | support-trailing-accessory | `{trailing: <Badge count={3} />}` | badge right-justified in expanded list (hidden when collapsed) |
| T27 | support-header-slot | `headerSlot={<Filter />}`, `title: "Users"` | filter strip below titled header (hidden when collapsed) |
| T28 | support-titled-header | `title: "Topics"` | titled header with divider, title left-aligned, `+` and toggle right-justified |
| T29 | support-create-affordance | `onNew: () => {}, newLabel: "New Topic"` | `+` button in header; `aria-label="New Topic"`; tints gold when `newActive: true` |
| T30 | show-busy-indicator | `busy: true` | spinner visible in header / top-right; `aria-live` region says "Loading" |
| T31 | support-back-slot | `backSlot={<Back />}` (untitled) | Back button top-left of header |
| T32 | support-left-control | `leftControl={<Toggle />}`, `showToggle: false` | Toggle top-left; desktop collapse toggle hidden |
| T33 | support-footer | `footer={<Stats />}` | Stats strip pinned at rail bottom (with top border) |
| T34 | support-close-button | `onClose: () => {}, closeLabel: "Dismiss"` | ✕ button top-right of header; `aria-label="Dismiss"` |
| T35 | support-row-disclosure | `rowDisclosure: true` | ChevronRight (14px) on every non-disabled row (expanded list only) |
| T36 | support-covered-style | `covered: true` | rows left-aligned icon strip; click already-selected row is no-op |
| T37 | support-marker-selection | `selectionStyle: "marker"`, `isRoot: true` | selected root row shows full-height left dash instead of bar |
| T38 | support-hover-bar | `hoverBar: false` | no left bar appears on row hover |
| T39 | hide-row-icons | `hideItemIcons: true` | leading icon hidden in expanded list (collapsed/covered unaffected) |
| T40 | support-prefetch | `onPrefetch: (id) => { … }`, hover row "x" for 100ms | `onPrefetch("x")` fires once after dwell |
| T41 | support-batch-mode | `checkable: true` | checkbox on every expanded-list row; unchecked by default |
| T42 | manage-batch-checked | `checkedIds: new Set(["x"])` | checkbox on item x is checked |
| T43 | fit-width | `onFit: (w) => {}` | `onFit` called with row width in px (clamped to 150–420) before paint |
| T44 | support-pane-padding | `panePadding: false` | pane content is edge-to-edge (no inset) |
| T45 | transition-collapse | drag the trailing edge (dragging active) | width transition suppressed while dragging; with `prefers-reduced-motion: reduce`, the collapse/expand transition duration is zeroed via `--apt-anim-scale` |
| T46 | support-covered-shadow | `coveredShadow: true` | rail casts a left drop-shadow (`shadow-[-10px_0_22px_-8px_var(--color-shadow)]`) |
| T47 | support-delete-action | `{onDelete: () => { throw new Error() }}`, confirm the dialog | dialog remains open, spinner clears, item is not removed; user can retry or cancel |
| T48 | support-prefetch | `onPrefetch` provided; hover the already-selected row for 100ms | `onPrefetch` does NOT fire for that row |
| T49 | manage-batch-checked | click an unchecked row's checkbox | `onToggleChecked(id)` fires; the row's own single selection is unaffected |
| T50 | fit-width | `onFit` provided; simulate `document.fonts.ready` resolving after initial measure | `onFit` is called a second time with the post-font-load width |
| T51 | support-dense-bottom | `denseBottom: true` | list's bottom padding is `pb-2` instead of the default `pb-8` |
| T52 | support-rail-slot | `railSlot` omitted | no slot renders; first topic row sits at the list's top padding, not the reserved slot height |
| T53 | skip-disabled, support-delete-action | `{disabled: true, onDelete: () => {}}` | row button disabled and non-interactive; trash button still renders enabled, hover/focus-revealed, and opens the confirm dialog |

## Edge Cases

- **Empty list**: when `items.length === 0` the rail shows `emptyLabel` text in a `<p>` (no list structure).
- **No selection**: when `selectedId === null` or not matched, no row is marked active (unless `railSlotActive: true`).
- **Icon-less rows**: when `icon` is omitted or falsy (including `false` from conditional rendering), a fallback neutral ring icon fills in — every row is guaranteed a leading icon so the collapsed icon-only strip never has a blank slot.
- **Preview text handling**: `preview?.trim()` is called; if the result is empty string no preview block renders even if `previewLines > 0`. Preview text preserves source line breaks (`whitespace-pre-line`).
- **Preview line clamping**: `previewLines` is clamped to `Math.max(0, Math.min(4, Math.trunc(…)))` before it is used — every input, in or out of the 0-4 range, resolves to a valid clamp class. There is no unclamped fallback to full text.
- **Covered list selection**: in covered style, clicking an already-selected row is a no-op (pure select, never toggles). Non-covered lists have no such short-circuit: clicking an already-selected row calls `onSelect` again with the same `id` — the component has no deselect signal. A caller wanting toggle-to-deselect semantics implements it themselves by treating a repeat `onSelect(id)` call as toggle-off.
- **Prefetch timing**: dwell timer is per-list, not per-row — moving focus from row to row arms the new row (old timer cleared). Never arms on the already-selected row; disarm handlers stay unconditional to cancel any armed timer.
- **Delete error handling**: when `onDelete()` throws, the dialog stays open without spinner, allowing the user to retry or cancel; the error is the consumer's responsibility to surface.
- **Batch mode in icon-only**: checkboxes do not render in collapsed or covered layouts (no room for a 16px box in a 40px peek); `checkable=true` is ignored in those layouts.
- **Collapsed rail measurement**: `onFit` never reports while `collapsed=true` — the icon strip has a fixed width by definition (COLLAPSED_RAIL = 48px).
- **Rail width drag threshold**: the threshold is always `railWidthProp / 3` (80px at the default 240px, not a fixed pixel value). Below it the rail snaps to collapsed. From the threshold up to `railWidthProp` the rail tracks the dragged width exactly (1:1) — there is no undefined range in between. Past `railWidthProp` the rail clamps back to exactly `railWidthProp`.
- **Font loading**: measurement happens before paint and re-runs when web fonts load (document.fonts.ready), so the reported width accounts for the actual font face.
- **SSR environment**: `rootFontPx()` returns 16 when `document` is undefined (SSR); first client measurement corrects layout before paint.
- **Drag suppresses transition**: while actively dragging (`onPointerMove`), the rail's width transition is disabled so it tracks the pointer live; transition re-enables on `onPointerUp`.
- **Mobile collapse toggle**: the desktop collapse toggle (`«`/`»`) and the drag-resize handle are hidden on mobile (≤768px) via `max-md:hidden`; the rail itself keeps its vertical-list layout, left bar and `border-r` at every width — it does not wrap or move the selection bar to a bottom edge.
- **Divider and spacer rendering**: dividers and spacers render in every layout, including collapsed/covered icon strips — neither is gated on `iconOnly`. The divider picks a tighter inset in the icon strips (`mx-2`) vs. the expanded list (`mx-3`).
- **Row delete animation**: the delete confirmation dialog retains the last target through its close animation (via `lastDeleteRef`) so the title doesn't blank.
- **Header control slot alignment**: the leading control slot is a fixed `w-4` so item icons sit concentric with header controls; the title's leading edge lands on the same column as row labels (consistently aligned across cascades).
- **Rail slot vertical offset**: the leading rail slot is not reserved space — it renders only when `railSlot` is provided. A rail without `railSlot` starts its first topic row at the list's top padding; a rail with `railSlot` starts the first topic row at least `2.15rem` lower (the slot's `min-h`). The two rails are not vertically aligned.
- **Trash button reveal**: the trash button is absolutely positioned in the right padding (`pr-9` on the row, positioned `right-[3px]`), so it never causes text to wrap and can't break a hierarchical connector line — the connector overlay computes a gap around it instead of being occluded by it.
- **Pass-through fields**: `description` and `leadsTo` are typed on `TopicDetailItem` but read by no logic in this file. `description` feeds other surfaces that show a topic's blurb (e.g. a selected topic's `EmptyState`); `leadsTo` feeds a cascading/hierarchical consumer's click-time hold logic. Both survive on the shared item shape so one list can serve multiple recipes without a shape mismatch — setting them changes no pixel here.

## Configuration

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

## Deep Linking

Not applicable: this component is a presentational primitive with no internal navigation. Deep linking is the responsibility of consumers that compose the component into a routing context.

## Localization

| String Key | Default (en) | Context |
|---|---|---|
| `emptyLabel` | "Nothing here yet." | Shown when `items` is empty |
| `newLabel` | "New" | Accessible name + tooltip for the create `+` button |
| `closeLabel` | "Close" | Accessible name + tooltip for the close button |
| `deleteConfirm` | "This action can't be undone." | Delete confirmation dialog body, per item |
| `deleteLabel` | item's `label` | Accessible name for the trash button and the dialog's subject; falls back to the item's own `label` when omitted |
| `railLabel` | "Topic list" | Accessible name for the rail's `<aside>` landmark |
| *(fixed)* | "topic list" (lowercase) | Desktop collapse toggle's `aria-label` — hardcoded literal, independent of `railLabel` |
| *(fixed)* | "Loading" | `aria-live="polite"` announcement while `busy=true` |
| *(fixed)* | ", needs attention" | Screen-reader-only suffix appended to a blocked row's accessible name |
| *(fixed)* | "Resize topic list" | Resize handle's `aria-label` |
| *(fixed)* | "Delete {label}?" | Delete confirmation dialog title template |
| *(fixed)* | "Delete {label}" | Delete button's `aria-label`/tooltip template |
| *(fixed)* | "Delete" / "Cancel" | `AlertModal`'s confirm/cancel button labels at this call site |

Six strings are overridable via props; the seven marked *(fixed)* are English literals with no override and no i18n hook — this section is `partial` (see Compliance).

## Accessibility Options

| Option | Behavior |
|---|---|
| Reduce Motion | The rail's width transition (collapse/expand/drag) respects the user's `prefers-reduced-motion` OS setting via the global `--apt-anim-scale` CSS variable, which zeroes the transition duration (see **transition-collapse**). |
| Increase Contrast | Not implemented here — color values come from shared `apt-*` theme tokens, so any high-contrast variant is handled at the token layer, not by this component. |
| Differentiate Without Color | Color is never the sole signal: the blocked marker pairs the amber dot with a screen-reader-only ", needs attention" suffix, and the active row pairs the gold selection bar with `aria-current="true"`. |

## Feature Flags

Not applicable: this component has no feature-flag controls. It is always-on and always exposes its full API.

## Analytics

Not applicable: this is a presentational block. Callers own any selection, creation, or deletion telemetry.

## Privacy

Not applicable: this component does not collect, store, or transmit data. All data (items, selection, checkboxes, blobs) is caller-owned and caller-managed.

## Logging

Not applicable: this component performs no logging. It is a presentation layer.

## Platform Notes

- **SwiftUI**: A SwiftUI port would start from `NavigationSplitView` (two-column, sidebar + detail) or a custom `HStack` column layout, adapting the two-pane master-detail pattern to SwiftUI's navigation model and state management (no imperative `collapsed` state prop; instead derive from `NavigationSplitViewVisibility` or a custom environment binding).
- **Compose**: An Android/Compose port would start from `NavigationRail` + an adaptive two-pane scaffold (Material 3 `ListDetailPaneScaffold`), adapting collapse behavior to Compose's `WindowWidthSizeClass` and state architecture (`mutableStateOf` for collapse, not controlled props).
- **React/Web (TypeScript)**: Source: `packages/web/packages/ui/src/blocks/topic-detail.tsx`. The component is a `"use client"` export (Next.js). Utilities with `apt-*` design tokens (no raw hex). Tailwind classes, no `!important`. Uses Lucide React icons (16px: `Circle`, `ChevronRight`, `Plus`, `Trash2`, `X`; `Loader2` for spinner). Responsive grid with `md:` breakpoint (≤768px collapses to a single column, stacking the rail above the pane; only the collapse toggle and drag handle hide there). Drag handle via `onPointerDown`/`onPointerMove`/`onPointerUp` pointer events. `useLayoutEffect` for width measurement (before paint). Font size from `document.documentElement` (or 16px fallback in SSR). Reusable `TopicRail`, `TopicList` subcomponents; `TopicDetail` composes `TopicRail` + `<section>` pane.
- **AppKit / UIKit**: A native iOS/macOS port would start from `NavigationSplitView` (iOS 16+) or `NSSplitViewController` (macOS), adapting the two-pane master-detail pattern to Cocoa's view controller lifecycle and `UIControl.Event` / `NSResponder` event model (no synthetic event pooling like React).
- **WinUI 3**: A WinUI 3 port would start from `Microsoft.UI.Xaml.Controls.NavigationView` with `PaneDisplayMode="Left"` at every width, or a custom `Grid` with two columns (`240*` and `1*`) that collapses to a single column at narrow widths (rail row above content row, matching the source). Key considerations: (1) **Collapse**: use `NavigationView.IsPaneOpen` binding or custom `VisualStateManager` state for the expand/collapse toggle, animating `PaneWidth` from 240 to 48px via `Storyboard`. (2) **Row items**: bind a `ListViewBase` with `ItemsSource="{Binding Items}"`, each item a `Button` subclass or `ListViewItem` with customized `ControlTemplate` (icon 16px, label, sublabel with `TextTrimming="CharacterEllipsis"`, preview lines via custom `TextBlock` with `MaxLines`). (3) **Selection styling**: active item uses `SolidColorBrush` gold text + left `Border` (width 2px, gold), hover uses text-colored border via `PointerOver` `VisualState`. (4) **States**: `CommonStates` (`Normal`, `PointerOver`, `Pressed`, `Disabled`) + custom states (`Blocked`, `Loading`). (5) **Responsive**: at narrow widths keep the pane's `Grid` single-column with the rail stacked above the content (the rail itself is unchanged — same `ListViewBase`, same left `Border` bar); use `VisualStateManager` only to hide the collapse toggle and drag handle. (6) **Delete**: hover-reveal trash button via `VisualState`, show `ContentDialog` (destructive, async confirmation with spinner). (7) **Drag resize**: `PointerPressed`/`PointerMoved`/`PointerReleased` on trailing edge, `Margin` or `Canvas.Left` for position. (8) **Accessories**: `CheckBox` for batch mode (hidden in collapsed), `ProgressRing` for busy spinner, `Button` for `+` (New), `✕` (Close), and chevron disclosure (14px `FontIcon`). (9) **Binding**: bind `selected` row to `SelectedItem`, collapse state to `IsPaneOpen`, checked set to `CheckBox.IsChecked` (two-way). (10) **Resources**: define `ThemeResource` keys mirroring the web `apt-*` tokens instead of hardcoded hex — `AptGoldBrush`, `AptTextDimBrush`, `AptNavBrush`, `AptSurfaceBrush`, `AptBorderBrush`, `AptOrangeBrush`, `AptRedBrush` — resolved in `Application.Resources` per theme dictionary so light/dark follow the same token names as web. (11) **Animation scale**: respect `UISettings.AnimationsEnabled` (Windows 11+) or `UISettings.ScreenReaderEnabled` to suppress/reduce transitions. (12) **Semantic**: `AutomationProperties.Name` for labels, `AutomationProperties.HelpText` for aria-like hints, `ControlType.List` for the rail container. Native `Button` already handles Enter/Space activation and tab-stop behavior, so no manual `KeyDown`/`IsTabStop` wiring is needed.

## Design Decisions

- **Decision**: The pane stays bare; `TopicRail` owns all header chrome (titled header, create `+`, footer, close button) via its own props, not the pane and not ad hoc consumer composition around the whole primitive.
  **Rationale**: Keeps the primitive reusable and focused (separation of concerns) while still giving every consumer the same chrome building blocks instead of reinventing them per call site.
  **Approved**: pending

- **Decision**: Collapse is intrinsic, not a config flag — there is no `collapsible=true/false` prop.
  **Rationale**: The site design treats collapsing to an icon strip as a core gesture to make room for the detail pane on desktop, so it is always available rather than opt-in.
  **Approved**: pending

- **Decision**: The component supports both controlled and uncontrolled collapse — pass `collapsed` + `onCollapsedChange` for external control (e.g. a hierarchical stack auto-minimizing ancestors), or omit them and let the component self-manage from `defaultCollapsed`.
  **Rationale**: Different call sites need different ownership of the collapse flag; supporting both avoids forcing every consumer through the same pattern.
  **Approved**: pending

- **Decision**: The rail measures its own intrinsic width and reports it via `onFit` instead of the parent guessing from character counts or a fixed number.
  **Rationale**: Only the component knows the full row anatomy (icon, label, sublabel, preview, trailing, delete button). Measurement is intrinsic (`max-content`), clamped to [MIN_FIT_RAIL, MAX_FIT_RAIL], and independent of the width the parent gives back, so there is no oscillation.
  **Approved**: pending

- **Decision**: While actively dragging the trailing edge, the rail's width transition is disabled so it tracks the pointer live; it re-enables on release.
  **Rationale**: Prevents janky visual lag during the drag and makes the resize feel responsive.
  **Approved**: pending

- **Decision**: The collapsed icon-only layout is always a fixed `COLLAPSED_RAIL` width (48px) — never measured.
  **Rationale**: Accessibility and simplicity: icon buttons have a predictable target size and no computation is needed for a layout that never varies.
  **Approved**: pending

- **Decision**: Every row is guaranteed a leading icon — a fallback neutral ring icon fills in when `icon` is omitted.
  **Rationale**: Keeps the collapsed icon-only strip readable: no blank slots, consistent visual rhythm.
  **Approved**: pending

- **Decision**: Preview text preserves the source's own line breaks (`whitespace-pre-line`) instead of collapsing to a single run-on paragraph.
  **Rationale**: A note rendered as one run-on paragraph reads nothing like the original content.
  **Approved**: pending

- **Decision**: When `inlineSublabel=true`, the label grows and truncates first; the sublabel shrinks and truncates after it.
  **Rationale**: Keeps the identifier visible when space is tight and lets metadata (the sublabel) yield first.
  **Approved**: pending

- **Decision**: Checking a batch checkbox is independent of selecting a row — the row's single-selection behavior is preserved underneath.
  **Rationale**: Ticking a box to include an item in a batch action should not disturb which item's detail pane is currently open; that independence is the point of batch mode.
  **Approved**: pending

- **Decision**: In covered style, clicking an already-selected row is a no-op (pure select, never toggle); non-covered lists keep the re-click-fires-`onSelect`-again behavior.
  **Rationale**: Covered rows are peeking siblings without a dismiss affordance, so re-clicking one is a selection reset, not a toggle — the two layouts have different physical metaphors.
  **Approved**: pending

- **Decision**: Prefetch never arms on the already-selected row, and disarm handlers stay unconditional so any armed timer is always cleared.
  **Rationale**: A prefetch is a guess about where the user is going next; the already-open item's data is already loaded, so warming it again would re-read it behind the pane the user is looking at, causing visible lag.
  **Approved**: pending

- **Decision**: When `onDelete()` throws, the confirmation dialog stays open without its spinner, rather than closing as on success.
  **Rationale**: The consumer owns the error message; leaving the dialog open lets the user retry or cancel without having to dismiss and reopen it.
  **Approved**: pending

- **Decision**: The blocked marker (amber dot) rides the row's icon rather than a trailing slot, and renders in expanded, collapsed, and covered layouts alike.
  **Rationale**: Trailing slots are hidden in collapsed/covered layouts — exactly where a user hunting for a greyed-out Save button most needs to see which topic is holding it down.
  **Approved**: pending

- **Decision**: `panePadding` is a single toggle on the pane, not a per-row concern.
  **Rationale**: Lets consumers opt into edge-to-edge rows without negative-margin hacks; the pane carries the padding once instead of duplicating inset CSS on each row.
  **Approved**: pending

- **Decision**: The component is a faithful 1:1 port of the source settings rail — CSS translated to utilities with `apt-*` tokens — so every consumer renders identically.
  **Rationale**: Any visual divergence from the reference implementation is unintended drift to fix, not an accepted feature or platform difference.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [if-frontmatter-complete](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-frontmatter-complete) | passed | Artifact Formatting |
| [if-behavioral-requirements](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-behavioral-requirements) | passed | Artifact Formatting |
| [if-test-vectors](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-test-vectors) | passed | Artifact Formatting |
| [if-platform-notes](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-platform-notes) | passed | Artifact Formatting |
| [if-design-decisions](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-design-decisions) | passed | Artifact Formatting |
| [if-compliance](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-compliance) | passed | Artifact Formatting |
| [if-change-history](agenticdevelopercookbook://compliance/artifact-formatting/ingredient-formatting#if-change-history) | passed | Artifact Formatting |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on `topic-detail.tsx`: real `<button>` elements, `aria-current`, `role="separator"`, and `aria-live="polite"` support screen-reader and semantic-markup `passed`; keyboard/contrast/touch-target/focus are `partial` because they depend on caller-supplied content (icon size, row height, dialog focus trap owned by `AlertModal`) rather than being fully guaranteed by this component alone; `reduced-motion` is `passed` via `--apt-anim-scale`; the two internationalization checks are `failed` because seven strings (see Localization) are fixed English literals with no override or i18n hook; `explicit-error-handling` is `partial` because a thrown `onDelete` keeps the dialog open and lets the spinner clear, but surfacing the actual error message is left to the consumer; `separation-of-concerns` is `passed` because rendering is decomposed into `TopicRail`/`TopicList`/`TopicDetail` subcomponents rather than one monolith; `unit-test-coverage` is `partial` — the seven `__tests__/topic*`/`topic-rail*` files exercise batch mode, delete, blocked state, icons, preview measurement, and busy/prefetch, but this revision's own fixes (rail-slot absence, mobile stacking, delete-on-disabled-row, collapsed dividers/spacers) had no prior test vector at all.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.6.1 | 2026-09-25 | Mike Fullerton | Rail-slot/respond-mobile/skip-disabled/divider-spacer corrected vs source; T52/T53 added. |
| 1.6.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed every requirement to subject-only kebab-case (dropped the `must-` prefix everywhere, including a typo and a reword) and updated all citations in test vectors, edge cases, and design decisions; corrected factual contradictions against source (preview clamping has no fallback path, non-covered re-click re-fires `onSelect` with no deselect signal, `data-blocked` lives on the row not the marker, drag-resize has no undefined range, the collapse toggle's fixed "topic list" label is independent of `railLabel`); added a requirement, test vectors, and edge-case coverage for `denseBottom`, and test vectors for `transition-collapse`, `covered-shadow`, delete-throws, prefetch-not-arming, `onFit` post-font-load re-measurement, and `onToggleChecked`; corrected the exported-surface list (`TopicList` is module-private) and documented `description`/`leadsTo` as intentional pass-through fields; rebuilt Compliance as a catalog-linked table with honest per-check status; reformatted Design Decisions into Decision/Rationale/Approved triples; rewrote Localization and Accessibility Options with real content instead of "Not applicable"; rewrote Platform Notes to drop the "Not applicable" framing, replace outdated APIs (`NavigationSplitView`, `UIControl.Event`), map WinUI resources to token-mirroring `ThemeResource` keys instead of hardcoded hex, and drop redundant manual-keyboard guidance already covered by native `Button`. |
| 1.5.0 | 2026-09-22 | Mike Fullerton | Comprehensive revision: expand behavioral requirements to cover all API surface (batch mode, prefetch, delete confirmation, blocked state, covered style, selection styles, row disclosure, etc.); detail all appearance properties and state transitions; verify all edge cases against source implementation; complete Platform Notes with all five platforms and concrete WinUI 3 guidance; document all props and exported types; add 44 test vectors covering every MUST requirement and major features; set status to review. |
| 1.4.0 | 2026-07-14 | Mike Fullerton | `inlineSublabel` on `TopicDetailItem`: render `sublabel` on the label's line (dim, label-priority truncation) for dense single-line entity rows (sites / groups / platforms / users). New requirement `must-render-inline-sublabel`. |
| 1.3.0 | 2026-07-10 | Mike Fullerton | TopicRail `headerSlot`: pinned strip under the titled header for the shared ListHeader (filter + actions). |
| 1.2.0 | 2026-07-03 | Mike Fullerton | `spacerAfter` on `TopicDetailItem`: a flexible spacer after the item pins the following items to the rail's bottom edge (e.g. a bottom Settings), in the full rail and the collapsed/covered icon strips alike. New requirement `must-render-spacer-after`. |
| 1.1.0 | 2026-06-30 | Mike Fullerton | Collapse-aware `railSlot` render-prop (→ `+` when undisclosed); always-reserved leading slot (first-row alignment); controllable collapse (`collapsed`/`onCollapsedChange`/`defaultCollapsed`). |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial draft |
