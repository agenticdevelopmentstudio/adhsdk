---
id: 8fa7aaae-df62-44ea-b10c-182f3094ed9f
title: "Topic Detail"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-06-26
modified: 2026-11-14
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
related:
  - 0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8
references: []
approved-by: ""
approved-date: ""
---

# Topic Detail

## Overview

**TopicDetail** is the reusable two-pane primitive: a selectable topic list (the rail) on the left beside a bare detail pane on the right. The pane has no title row and no action bar of its own. All list chrome (a titled header, a list toolbar with a filter, the create `+`, a footer, a close button) belongs to the rail, which the same file exports as **TopicRail**. `TopicDetail` composes one `TopicRail` with a `<section>` pane and passes the rail no `title`, so the standalone primitive shows the bare control strip and no toolbar; the hierarchical stack (adhsdk.ingredient.ui.blocks.hierarchical-topic-detail ([adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8))) composes `TopicRail` directly for its titled, filterable columns. The file is the source of truth: it began as a port of the adh.com/home settings rail, and that original is gone.

The rail is always collapsible. A desktop toggle shrinks it to an icon-only strip of 48px; each topic stays clickable as its icon. Below the `md` breakpoint the grid is a single column and the rail stacks above the pane as the same vertical list; only the collapse toggle and the drag handle are hidden. The component fills its container, so give it a height.

The file also exports small shared pieces: `ListToolButton` (one icon tool on a list toolbar), `filterTopicItems`, `underlineMatch`, `topicLinkOf`, `LINK_FLASH_MS`, `rowExitEl`, the width constants and `rootFontPx` / `railPx`.

## Behavioral Requirements

- **render-two-panes**: The component MUST render a left topic-list rail beside a right detail pane holding `children`.
- **fill-container**: The component MUST fill its container's height and width (grid with `min-h-0 min-w-0 flex-1`), so a caller supplies an explicit height or a `flex-1` parent.
- **mark-selected**: The row whose `id` equals `selectedId` MUST be marked active: gold text, a gold 2px left bar in the default `bar` selection style, and `aria-current="true"`.
- **report-selection**: Clicking a non-disabled row MUST call `onSelect` with the row's `id`, including a re-click on the already-selected row when the list is not `covered` (see `skip-covered-reselect`), because the component has no deselect signal of its own.
- **skip-covered-reselect**: In covered style a click on the already-selected row MUST do nothing: no `onSelect` and no link flash.
- **skip-disabled**: A `disabled` row MUST be a native disabled button, dimmed (`text-apt-text-dim`, default cursor), and MUST NOT call `onSelect`.
- **render-label**: Each row MUST render its `label` as the primary text, truncated with an ellipsis when it overflows.
- **render-label-suffix**: A row with `labelSuffix` MUST render it on the same line as the label, at the same size and weight, and it MUST truncate last: the suffix does not shrink while the label and, with `inlineSublabel`, the sublabel truncate first. Without `inlineSublabel` a row with a `labelSuffix` MUST NOT render its `sublabel` at all, because the suffix row replaces the stacked layout.
- **render-stacked-sublabel**: A row with `sublabel`, no `inlineSublabel` and no `labelSuffix` MUST render the sublabel as a dim, smaller second line.
- **render-inline-sublabel**: A row with `inlineSublabel` and a `sublabel` MUST render the sublabel on the label's line, dim, with the label growing and truncating first and the sublabel shrinking and truncating after it.
- **render-preview**: A row whose trimmed `preview` is non-empty and whose resolved line count is above 0 MUST render the preview as a dim, smaller block under the label (and under the sublabel), clamped to that many lines, preserving the source's line breaks.
- **clamp-preview**: `previewLines` MUST be truncated to an integer and clamped to 0-4, defaulting to 1 when omitted, so every input resolves to one of the four clamp classes. A value of 0 MUST render no preview, which lets a host keep passing `preview` and switch it off with the number alone.
- **align-icon-to-preview**: A row that renders a preview MUST align its icon to the top of the row; a row without one MUST centre the icon vertically.
- **render-icon**: Each row MUST render a 16px leading icon; when `icon` is omitted or falsy (including `false` from a conditional), a neutral ring MUST fill in (a link row gets the link glyph instead), so the icon-only strip never shows a blank slot.
- **hide-row-icons**: When `hideItemIcons` is true the expanded list MUST drop the leading icon from every row; the collapsed and covered strips MUST ignore the flag.
- **hide-label-when-icon-only**: In the collapsed and covered strips the row MUST hide its label, sublabel, preview, suffix and trailing accessory, and MUST carry the label as its `aria-label`.
- **tooltip-when-collapsed**: In the collapsed strip each row MUST show its `label` in a right-side tooltip on hover and keyboard focus.
- **render-empty-label**: With no rows the list MUST show `emptyLabel` in a paragraph inside a single list item (`TopicDetail` defaults it to "Nothing here yet."; `TopicRail` requires it).
- **support-rail-slot**: When `railSlot` is provided it MUST render as a leading list item above the topics with a minimum height of `2.15rem`; when absent it MUST reserve no space. A function form MUST receive the rail's collapsed state. When `railSlotActive` is true the gold selection bar MUST move onto the slot.
- **render-divider-after**: A row with `dividerAfter` MUST be followed by a separator list item (`role="separator"`, `aria-label` set to `dividerLabel`) in the expanded list and in both icon strips; the inset MUST be `mx-2` when collapsed and `mx-3` otherwise.
- **render-divider-label**: With `dividerAfter` and `dividerLabel`, the expanded list MUST render the label as an uppercase caption under the separator; the icon-only strips MUST NOT render the caption.
- **render-spacer-after**: A row with `spacerAfter` MUST be followed by a flexible spacer that pushes every following row to the list's bottom edge, in the expanded list and in both icon strips.
- **render-trailing**: A row with `trailing` content MUST render it pinned right in the expanded list and MUST NOT render it in the icon strips.
- **render-row-disclosure**: With `rowDisclosure` true, every enabled, non-link row in the expanded list MUST end in a 14px right chevron; disabled rows, link rows and the icon strips MUST NOT show it.
- **support-link-row**: A row with `onLink` MUST, when chosen through `TopicDetail`, run the link and MUST NOT call `onSelect`; the row MUST NOT become `selectedId`.
- **flash-link-row**: A chosen link row MUST be marked active in place of the list's real selection for `LINK_FLASH_MS` (1000ms), then release; a new choice MUST restart the timer.
- **render-link-glyph**: A link row without an `icon` MUST show a link glyph instead of the neutral ring, and MUST NOT show a disclosure chevron.
- **render-blocked-marker**: A row with `blocked` MUST show an amber dot on its icon in the expanded list and both strips, MUST set `data-blocked="true"` on the row button, and MUST add the words "needs attention" to the row's accessible name.
- **render-blocked-without-icon**: When `hideItemIcons` removes the icon, a blocked row in the expanded list MUST still show a standalone amber dot.
- **support-delete-action**: A row with `onDelete` MUST render a trash button in the expanded list, revealed on row hover and on keyboard focus; the strips MUST NOT render it. Activating it MUST open a destructive confirmation dialog without selecting the row.
- **run-delete-on-confirm**: Confirming the dialog MUST run `onDelete`, show a busy state and block dismissal until it settles, then close the dialog.
- **keep-dialog-on-delete-failure**: When `onDelete` throws or rejects, the dialog MUST stay open with the busy state cleared; the component does not surface the error itself.
- **support-delete-label**: `deleteLabel` MUST name the trash button ("Delete {name}") and the dialog title ("Delete {name}?"); both default to `label`.
- **support-delete-confirm**: `deleteConfirm` MUST be the dialog body, defaulting to "This action can't be undone."
- **delete-on-disabled-row**: A disabled row with `onDelete` MUST still render an enabled trash button.
- **keep-delete-title-through-close**: The dialog MUST keep the last delete target's title through its close animation.
- **support-batch-mode**: With `checkable` true, every row in the expanded list MUST show a checkbox named by the row's label, and ticking it MUST NOT select the row; the icon strips MUST ignore `checkable`.
- **report-batch-toggle**: The checkbox MUST reflect `checkedIds` membership and MUST call `onToggleChecked` with the row's `id`; the component MUST NOT hold the tick set.
- **disable-batch-check**: The checkbox MUST be disabled when the row is `disabled` or `checkDisabled`; `checkDisabled` alone MUST leave the row selectable.
- **support-prefetch**: With `onPrefetch`, the rail MUST call it with a row's `id` once the pointer or keyboard focus has rested on that row for 100ms, with one timer for the whole list; it MUST NOT arm on the selected row and MUST cancel on pointer or focus leave and on unmount.
- **support-hover-bar**: With `hoverBar` false, an unselected row MUST NOT show a hover left bar.
- **support-marker-selection**: With `selectionStyle="marker"` the selected row MUST draw no gold border; in a root list (`isRoot`) that is not collapsed, it MUST draw a full-height gold bar flush with the row's left edge.
- **support-covered-style**: With `covered`, the rows MUST render as a left-aligned icon-only strip.
- **support-covered-shadow**: With `coveredShadow`, the rail MUST cast a left drop shadow from the `--color-shadow` token.
- **collapse-rail**: The rail MUST offer a desktop collapse toggle, hidden below `md`, that switches it between full width and a `COLLAPSED_RAIL` (48px) strip; the toggle MAY be omitted only with `showToggle` false; in an untitled rail a `leftControl` or `backSlot` strip takes its place, and a `leftControl` strip carries no toggle.
- **support-controlled-collapse**: With `collapsed` provided the collapse state MUST be driven by it and `onCollapsedChange` MUST be called on each change; otherwise it MUST self-manage from `defaultCollapsed` (default false), still calling `onCollapsedChange`.
- **support-drag-resize**: With `onResize` the rail MUST render a vertical separator handle on its trailing edge, hidden below `md`, reporting the pointer's offset from the rail's left edge. In `TopicDetail`, a width below `railWidth / 3` MUST collapse the rail; from that threshold up to `railWidth` it MUST track the pointer; past `railWidth` it MUST clamp to `railWidth`.
- **transition-collapse**: From `md` up, width changes MUST animate over `200ms * var(--apt-anim-scale, 1)` and the animation MUST be suppressed while dragging.
- **respond-mobile**: Below `md` the grid MUST be a single column with the rail above the pane; the collapse toggle and the drag handle MUST be hidden and the `--rail-w` width MUST have no effect.
- **support-pane-padding**: With `panePadding` true (default) the pane MUST add `gap-6 px-6 py-4`; false MUST make content edge to edge.
- **support-titled-header**: With `title` and not collapsed, the rail MUST render a header whose title is left-justified onto the row-label column, with a 16px control slot (the `leftControl` or `backSlot`) on the icon column, the collapse toggle (when `showToggle`) and the close button right-justified, and a divider beneath.
- **support-untitled-header**: Without a `title` (or when collapsed) the rail MUST render a bare control strip, choosing in priority order `leftControl`, then `backSlot`, then the toggle and `+`, then the busy spinner alone, else nothing.
- **support-list-toolbar**: Every titled, un-collapsed rail MUST render a toolbar (`role="toolbar"`, named "{title} tools", or "List tools" for a non-string title) under the header, ordered filter button, `+`, a flexible spacer, then `titleActions`; the toolbar MUST NOT render when the rail is untitled or collapsed.
- **support-create-affordance**: With `onNew` the rail MUST render a `+` button named by `newLabel` (default "New"), in the toolbar of a titled rail and in the control strip of an untitled one; `newActive` MUST tint it gold.
- **support-close-button**: With `onClose` the rail MUST render an X button named by `closeLabel` (default "Close") in the titled header or in the control strip beside a `leftControl`; the other untitled strips (`backSlot`, toggle and `+`, busy alone) MUST NOT render it.
- **support-header-slot**: With `headerSlot` the rail MUST render it as a full-width bordered strip between the toolbar and the rows, hidden while collapsed.
- **support-footer**: With `footer` the rail MUST pin it below the list with a top border and 8px padding.
- **show-busy-indicator**: With `busy` the rail MUST show a spinner right after the title (titled), or in the control strip of every untitled shape, including collapsed and including below `md`; the title spinner is excluded from the fit measurement.
- **announce-busy**: The rail MUST always mount a polite status region that reads "Loading" while `busy` and is empty otherwise.
- **label-landmark**: The rail MUST be an `aside` named `railLabel`, defaulting to "Topic list".
- **support-dense-bottom**: With `denseBottom` the list MUST use `pb-2` rather than `pb-8`.
- **filter-every-titled-rail**: The filter MUST open a panel exactly over the toolbar, as wide as the rail, with a focused search field that has a clear button and uses `search.placeholder` (default "Filter") as placeholder and accessible name.
- **open-filter-on-mount**: With `search.autoOpen` the panel MUST be open and focused on mount.
- **suggest-matches**: While the query is non-blank and `search.live` is false, the panel MUST list the matching, enabled rows (label or sublabel, case-folded, in list order) as a listbox of options under the field, with the first highlighted, and MUST keep every rail row in the list (hidden visually, not unmounted, while suggestions show).
- **underline-match**: Each suggestion MUST underline the first case-folded occurrence of the query in its label, mapping positions back to the original label even when case-folding changes its length.
- **navigate-suggestions**: Arrow Down and Arrow Up MUST move the highlight through the suggestions, wrapping at both ends, without moving the caret; typing MUST reset the highlight; the pointer MUST take the highlight only when it moves.
- **choose-suggestion**: Enter or a click on a suggestion MUST select that row as a click on it would, dismiss the filter and clear the query; it MUST NOT call `onSelect` for the row already selected (a link row always calls it), and MUST scroll the chosen row into view once the list shows it selected (never for a link row).
- **ignore-ime-enter**: Enter while an IME composition is active MUST NOT choose a suggestion.
- **dismiss-filter**: Escape MUST close the panel, return focus to the filter button and select nothing, and MUST stop the event so a dialog around the rail stays open; the clear button MUST do the same; moving focus out of the panel MUST dismiss it, except when `search.live` is true.
- **say-no-match**: When the filter is not `live`, a query is typed, nothing matches and the host rows are not pending, the panel MUST say "Nothing matches" with the query; Enter MUST then leave the field open.
- **support-live-filter**: With `search.live` the rail MUST narrow its own rows on every keystroke (the selected row always surviving) instead of suggesting, leave Enter and focus to the host, and keep the query after the panel closes by Escape or by focus leaving (the clear button still clears it).
- **support-controlled-query**: With `search.query` the host owns filtering; the rail MUST report every keystroke through `onQueryChange`, MUST offer its `items` as suggestions (the selected row only if it matches), and MUST keep the query when focus merely leaves the field.
- **wait-for-pending-rows**: With a controlled query and `search.pending`, the panel MUST offer nothing and show "Searching…".
- **tint-active-filter**: The filter button MUST be gold while a non-blank query narrows the list with the panel closed.
- **expose-combobox**: The field MUST be a combobox over the suggestion listbox, naming the highlighted option as the active descendant, when not `live`.
- **fit-width**: With `onFit` the rail MUST report, before paint and again after fonts load, the width its rows, header and toolbar want (ceil, plus the aside's own borders and padding), clamped to `railPx(MIN_FIT_RAIL)`..`railPx(MAX_FIT_RAIL)`.
- **skip-fit-when-unmeasurable**: The rail MUST NOT report while collapsed, while a query narrows its rows, or when the measured width is 0.
- **refit-on-tool-resize**: The rail MUST re-measure when the host's tool actions change width.
- **pass-through-fields**: `description` and `leadsTo` MUST be accepted on a row and MUST NOT change anything rendered by this file.

## Appearance

- **Grid**: `grid-cols-1` below `md`; from `md` the columns are the `--rail-w` variable (full `railWidth`, default `FULL_RAIL` 240px; collapsed `COLLAPSED_RAIL` 48px) and `minmax(0,1fr)`.
- **Rail**: `bg-apt-nav`, `border-r border-apt-border`, flex column; the list scrolls with `pr-4 pt-2` (`pr-1` collapsed) and `pb-8` (`pb-2` with `denseBottom`).
- **Row**: monospace `0.8rem`, tracking `0.02em`, `border-l-2` transparent, `gap-2 pt-1 pb-0.5`, `pl-2` (`pl-8` in batch mode), `pr-3` (`pr-9` when deletable); collapsed rows centre their icon with `py-1.5`. Sublabel and preview are `0.7rem` in `text-apt-text-dim`.
- **Row colour**: default `text-apt-text`; active `text-apt-gold` with `border-l-apt-gold` in bar style; hover `border-l-apt-text`; disabled `text-apt-text-dim`.
- **Blocked dot**: 6px `bg-apt-orange` with a 2px `ring-apt-nav` punch-out at the icon's top-right.
- **Delete button**: 19px, absolute at right 3px, `bg-apt-nav text-apt-text-dim`, opacity 0 until row hover or focus, `hover:text-apt-red`, `ring-apt-red/40` on focus.
- **Header**: `min-h-[2.15rem]`, `pl-2.5 pr-2`, `border-b`; toolbar `min-h-[2rem]`, same inset and border; title `0.8rem` mono `text-apt-text-muted`.
- **Tools**: `ListToolButton` is `p-0.5 rounded`, `text-apt-text-muted` (gold when active), `hover:text-apt-text`, `ring-apt-gold/40` on focus.
- **Filter panel**: `absolute inset-0` over the toolbar, `bg-apt-surface`; suggestions hang below it, `max-h-72` capped to the room left in the clipping box, `shadow-lg`, highlighted option `bg-apt-gold/15`.
- **Dividers**: `h-px bg-apt-border`. **Drag handle**: 6px wide, `cursor-col-resize`, `hover:bg-apt-gold/40`.
- **Pane**: `bg-apt-surface`, `overflow-auto`, flex column. No raw colour values.

## States

| State | Appearance change |
|---|---|
| Default | Row in `text-apt-text`, transparent left border |
| Pressed | Not applicable: rows are plain buttons with no pressed styling in source |
| Disabled | Row dimmed to `text-apt-text-dim`, default cursor, no hover bar, checkbox disabled |
| Focused | Native focus on the row; arms prefetch; the trash button and tools show `focus-visible` rings |
| Loading | `busy` shows a spinning loader after the title and "Loading" in the status region |
| Active row | Gold text, left bar (bar style) or full-height gold bar flush left (marker, root, not collapsed), `aria-current="true"` |
| Hover | Text-coloured left bar when `hoverBar` is true; trash button fades in |
| Blocked | Amber dot on the icon, `data-blocked="true"`, "needs attention" in the name |
| Link flash | The chosen link row appears active for 1000ms |
| Collapsed | 48px strip, icon-only rows with tooltips, no toolbar |
| Covered | Left-aligned icon-only strip, no tooltip, re-click is a no-op |
| Dragging | Width transition off, rail tracks the pointer |
| Delete pending | Confirmation dialog open; busy while the delete runs |
| Delete failed | Dialog stays open, busy cleared |
| Filter open | Panel over the toolbar; suggestions, "Searching…" or "Nothing matches" below; rows invisible under them |
| Filter active, closed | Filter button gold |
| Batch | Checkbox in each expanded row |
| Below `md` | One column, rail above pane, toggle and drag handle hidden |

## Accessibility

- **row-semantics**: Rows are native buttons; the active one carries `aria-current="true"`; disabled rows are native disabled buttons; icons are `aria-hidden`.
- **icon-only-name**: Icon-only rows carry the label (plus ", needs attention" when blocked) as `aria-label`; expanded blocked rows append a screen-reader-only ", needs attention".
- **landmarks**: The rail is an `aside` named `railLabel` or "Topic list"; the toolbar is a named `role="toolbar"`; dividers are `role="separator"`; the collapse toggle is named from the label "topic list" and controls the list element.
- **tool-names**: The `+`, the close button, the filter button and the clear button take their names from `label` (so a screen reader and a hover tooltip both read it); the trash button is named "Delete {name}"; batch checkboxes are named by the row label.
- **live-regions**: A polite status region announces "Loading" while busy; "Searching…" and "Nothing matches" render as `role="status"`.
- **combobox**: The filter field is a combobox with `aria-expanded`, `aria-controls` and `aria-activedescendant` following the highlight; options are `role="option"` with `aria-selected`.
- **focus-return**: Closing the filter returns focus to the filter button; the confirmation dialog opens with focus on Cancel, with its keyboard shortcuts off (owned by `AlertModal`).
- **non-colour-signals**: The blocked dot is paired with the announced text, and the active row pairs the gold bar with `aria-current`.
- **resize-handle-keyboard**: NEEDS REVIEW: Not implemented in source. The resize handle is a `role="separator"` with an `aria-label` but handles only pointer events, so a keyboard user cannot resize the rail; the collapse toggle is the only keyboard route to a narrower rail. A product decision on whether keyboard resizing is required would settle it.
- **tool-target-size**: NEEDS REVIEW: Not implemented in source. `ListToolButton` is a 16px icon with `p-0.5` padding (about 20px) and the trash button is 19px, with no touch-size override in this file or in `styles/components.css`, whose touch rules (`adh-touch-row`, `data-htd-row`) grow the rows and suggestion options only; whether these tools meet the target-size floor is a decision the source cannot make. A target-size audit on a touch device would settle it.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-two-panes | `items` and `children` | rail left, pane right, `children` in the pane |
| T2 | mark-selected | `selectedId="x"` | row x has `aria-current="true"` and gold text and bar |
| T3 | report-selection | click row "y" | `onSelect("y")` once |
| T4 | report-selection | click the already-selected row, not covered | `onSelect` fires again with the same id |
| T5 | skip-covered-reselect | `covered`, click the selected row | no `onSelect` |
| T6 | skip-disabled | click a `disabled` row | no `onSelect`; row dimmed |
| T7 | render-empty-label | `items=[]` | "Nothing here yet." in a paragraph |
| T8 | support-rail-slot | `railSlot={(c)=>...}`, `railSlotActive`, collapsed | slot above topics with gold bar; function got `true` |
| T9 | support-rail-slot | no `railSlot` | no slot element; first row at top padding |
| T10 | render-label-suffix | `{label:"A", labelSuffix:"v2"}` | "A" and "v2" on one line, both full size |
| T11 | render-inline-sublabel | `{label:"A", sublabel:"b.com", inlineSublabel:true}` | one line; sublabel dim and shrinks first |
| T12 | render-stacked-sublabel | `{label:"A", sublabel:"b.com"}` | second dim line |
| T13 | render-preview, clamp-preview | topicDetailPreview.test: `preview` with `previewLines` 2 | preview block with 2-line clamp |
| T14 | clamp-preview | `previewLines: 0`, and `previewLines: 9` | no preview; and a 4-line clamp |
| T15 | clamp-preview | `preview: "   "` | no preview block |
| T16 | render-icon | row without `icon`; row with `icon={false}` | neutral 16px ring in both |
| T17 | hide-row-icons | `hideItemIcons`, expanded; then collapsed | no icon expanded; icon present collapsed |
| T18 | hide-label-when-icon-only, tooltip-when-collapsed | `collapsed` | rows show icons only; `aria-label` = label; tooltip on hover |
| T19 | render-divider-after | `dividerAfter` expanded, collapsed and covered | separator in all three; `mx-3` expanded and covered, `mx-2` collapsed |
| T20 | render-divider-label | `dividerAfter`, `dividerLabel:"Coming soon"` | caption expanded; none in strips |
| T21 | render-spacer-after | `spacerAfter` at position 2 of 5 | rows 3-5 at the bottom edge |
| T22 | render-trailing | `trailing={<Badge/>}` | right-justified expanded; absent when collapsed |
| T23 | render-row-disclosure | `rowDisclosure` | chevron on enabled non-link rows only |
| T24 | support-link-row | topicDetailLink.test: choose a row with `onLink` | link runs; `onSelect` not called |
| T25 | support-link-row | topicDetailLink.test: choose an ordinary row | `onSelect` runs |
| T26 | flash-link-row | topicDetailLink.test: choose a link row | marked active, then released after 1000ms |
| T27 | render-link-glyph | topicDetailLink.test: link row without icon | link glyph; no chevron |
| T28 | render-blocked-marker | topicDetailBlocked.test: `blocked: true` | dot on icon; `data-blocked="true"`; "needs attention" in name |
| T29 | render-blocked-marker | `blocked`, collapsed | `aria-label` "A, needs attention" |
| T30 | render-blocked-without-icon | `blocked`, `hideItemIcons` | standalone dot; sr-only text |
| T31 | support-delete-action | topicDetailDelete.test: hover then click trash | confirm dialog opens; row not selected |
| T32 | run-delete-on-confirm | confirm with an async `onDelete` | busy until it settles, then closed |
| T33 | keep-dialog-on-delete-failure | `onDelete` rejects, confirm | dialog open, busy cleared |
| T34 | support-delete-label | `deleteLabel:"Workspace"` | "Delete Workspace" button; "Delete Workspace?" title |
| T35 | support-delete-confirm | `deleteConfirm:"Permanent loss."` | dialog body shows it; default is "This action can't be undone." |
| T36 | delete-on-disabled-row | `disabled`, `onDelete` | trash button present and enabled |
| T37 | support-delete-action | `collapsed` or `covered` with `onDelete` | no trash button |
| T38 | support-batch-mode | topicDetailCheckable.test: `checkable` | checkbox per expanded row; none in strips |
| T39 | report-batch-toggle | tick an unticked box | `onToggleChecked(id)`; no `onSelect` |
| T40 | disable-batch-check | `checkDisabled` row | box disabled; row still selectable |
| T41 | support-prefetch | topic-rail-prefetch.test: rest on a row 100ms | `onPrefetch(id)` once |
| T42 | support-prefetch | topic-rail-prefetch.test: sweep past rows | nothing fires |
| T43 | support-prefetch | topic-rail-prefetch.test: keyboard focus; and no `onPrefetch` | fires on focus; nothing without the prop |
| T44 | support-prefetch | rest on the selected row | not armed |
| T45 | support-hover-bar | `hoverBar: false` | no hover border class |
| T46 | support-marker-selection | `selectionStyle:"marker"`, `isRoot` | full-height gold bar; no gold border |
| T47 | collapse-rail | click the toggle | rail 48px; click again restores |
| T48 | support-controlled-collapse | `collapsed:true`, toggle | `onCollapsedChange(false)`; state follows the prop |
| T49 | support-drag-resize | drag to 100px, then 50px, then 400px (default 240) | tracks 100; collapses at 50; clamps to 240 |
| T50 | transition-collapse | drag in progress | transition class absent; present when idle |
| T51 | respond-mobile | width below `md` | one column; rail above; toggle and handle hidden |
| T52 | support-pane-padding | `panePadding:false` | no inset or gap classes |
| T53 | support-titled-header | `title:"Users"` on `TopicRail` | header with title; toolbar named "Users tools" |
| T54 | support-untitled-header | no title; with `backSlot`, then `leftControl` | back slot top-left; `leftControl` wins when both given |
| T55 | support-list-toolbar | topic-rail-toolbar.test: titled, no tools | toolbar with filter present |
| T56 | support-list-toolbar | topic-rail-toolbar.test: untitled; collapsed | no toolbar |
| T57 | support-list-toolbar | topic-rail-toolbar.test: with `onNew` and `titleActions` | order filter, `+`, host tools |
| T58 | support-create-affordance | `onNew`, `newLabel:"New Topic"`, `newActive` | named "New Topic"; gold |
| T59 | support-close-button | `onClose`, `closeLabel:"Dismiss"` | button named "Dismiss" |
| T60 | support-header-slot | `headerSlot`; then collapsed | strip under toolbar; hidden collapsed |
| T61 | support-footer | `footer` | pinned below the list with a top border |
| T62 | show-busy-indicator, announce-busy | topic-rail-busy.test: `busy` | spinner by the title; "Loading" announced; empty when not busy |
| T63 | label-landmark | `railLabel:"Notes"`; default | aside named "Notes"; "Topic list" |
| T64 | support-dense-bottom | `denseBottom` | `pb-2` |
| T65 | open-filter-on-mount | topic-rail-toolbar.test: `search.autoOpen` | panel open, field focused |
| T66 | suggest-matches | topic-rail-toolbar.test: type a query | matching options by label and sublabel; rail rows kept |
| T67 | underline-match | topic-rail-toolbar.test: "İstanbul" with "stan" | "stan" underlined |
| T68 | navigate-suggestions | topic-rail-toolbar.test: Down at last option | wraps to the first; caret unmoved |
| T69 | choose-suggestion | topic-rail-toolbar.test: Enter | row selected, panel closed, query cleared |
| T70 | choose-suggestion | topic-rail-toolbar.test: choose the selected row | `onSelect` not called |
| T71 | suggest-matches | topic-rail-toolbar.test: a disabled row matches | not offered |
| T72 | say-no-match | topic-rail-toolbar.test: no match | "Nothing matches" and Enter keeps the field open |
| T73 | dismiss-filter | topic-rail-toolbar.test: Escape | closed, nothing selected, focus on button, dialog not closed |
| T74 | dismiss-filter | topic-rail-toolbar.test: focus leaves; Tab onto the clear button | closes; stays open for the clear button |
| T75 | ignore-ime-enter | topic-rail-toolbar.test: Enter while composing | nothing chosen |
| T76 | support-live-filter | topic-rail-toolbar.test: `live` | rail rows narrow; selected row survives; Enter left to host |
| T77 | support-controlled-query | topic-rail-toolbar.test: controlled | `onQueryChange` per keystroke; query kept on blur; cleared once on Escape |
| T78 | wait-for-pending-rows | topic-rail-toolbar.test: `pending` | "Searching…" and no suggestions |
| T79 | tint-active-filter | query set, panel closed | filter button gold |
| T80 | fit-width | railAutoFit.test: `onFit`, rows measured | reported width in `railPx(150)`..`railPx(420)` |
| T81 | skip-fit-when-unmeasurable | topic-rail-toolbar.test: query narrows rows; collapsed | no report; whole list re-measured after clear |
| T82 | refit-on-tool-resize | topic-rail-toolbar.test: tools outgrow rows | width wide enough for the toolbar |
| T83 | pass-through-fields | `description`, `leadsTo` set | rendered output unchanged |

## Edge Cases

- **Empty list**: MUST show `emptyLabel` in a paragraph. With a self-filtering rail and an empty result the paragraph MUST read "Nothing matches" with the query; a controlled host keeps its own label, because its empty list may still be loading.
- **No match for selectedId**: when `selectedId` is null or unknown, no row is active (unless `railSlotActive`).
- **Falsy icon**: a `false` icon (from a conditional) MUST fall back to the ring, because the fallback uses `||`.
- **Preview inputs**: blank or whitespace-only preview renders nothing; a fractional, negative or too-large `previewLines` resolves to a valid 0-4 clamp.
- **Covered versus uncovered re-click**: covered is a no-op; uncovered re-fires `onSelect` and the owner decides whether to toggle.
- **Link row selected**: a link row's click is reported to `onSelect` by the list; `TopicDetail` runs the link instead. A host that owns its own `TopicRail` MUST do the same via `topicLinkOf`.
- **Delete failure**: the error is swallowed by the dialog logic and left to the host's `onDelete`; this component shows nothing about it.
- **Concurrent delete and cancel**: Cancel MUST do nothing while a delete is running.
- **Collapse while filter open**: the toolbar leaves with the field open, so the panel and suggestions MUST NOT show.
- **Query changes under a controlled host**: the highlight follows a topic id, so a late-arriving list keeps the highlight on the same topic, or the first suggestion if that id is gone.
- **Case-folding length change**: positions are mapped per character, so the underline lands on the right letters.
- **Fit with no layout**: a zero measurement (jsdom, a hidden ancestor) reports nothing and leaves the caller's width.
- **Fit range at a non-16px root**: the range is scaled by `rootFontPx()` / 16; with no document it is 16.
- **Fit while narrowed**: the measure is skipped while a query narrows the rows, so the width does not shrink to the matches.
- **Offline or disconnected**: not applicable: the component performs no network access; `onDelete` and `onPrefetch` are caller functions.
- **Concurrent access**: not applicable: state is local React state with one prefetch timer and one flash timer per list.
- **Unmount**: prefetch and flash timers MUST be cleared on unmount.
- **SSR**: `rootFontPx()` returns 16 without a `document`.
- **Mobile**: only the toggle and drag handle hide, and `--rail-w` is ignored, so a collapsed rail still spans the full column.
- **Label suffix without inline sublabel**: the row shows the label and suffix only; its `sublabel` is not rendered. A host that needs both MUST set `inlineSublabel`.

## Configuration

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

## Deep Linking

Not applicable: the component has no internal navigation or URLs; a row's `onLink` is a caller callback.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `emptyLabel` | "Nothing here yet." | Empty list (overridable) |
| `newLabel` | "New" | The `+` name (overridable) |
| `closeLabel` | "Close" | Close button name (overridable) |
| `railLabel` | "Topic list" | Aside name (overridable) |
| `search.placeholder` | "Filter" | Field placeholder and name (overridable) |
| `deleteConfirm` | "This action can't be undone." | Dialog body (overridable per row) |
| fixed | "Loading" | Busy announcement |
| fixed | ", needs attention" | Blocked suffix |
| fixed | "Resize topic list", "Collapse topic list" / "Expand topic list", "link" | Handle, toggle and link-glyph names |
| fixed | "Delete {name}", "Delete {name}?", "Delete", "Cancel" | Trash button, dialog title and buttons |
| fixed | "Searching…", "Nothing matches “{query}”.", "Clear filter", "{label} suggestions", "{title} tools", "List tools" | Filter panel and toolbar |

Six strings are overridable; the fixed English literals have no override or i18n hook.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The width transition duration is `200ms * var(--apt-anim-scale, 1)`, which the global reduce-motion setting zeroes; the spinner uses `animate-spin` with no override here. |
| Increase Contrast | Not applicable: colours come from shared `apt-*` tokens; the component has no contrast logic. |
| Differentiate Without Color | The blocked dot is paired with announced text, and the active row pairs the gold bar with `aria-current`. |

## Feature Flags

Not applicable: the component reads no flags and is always on.

## Analytics

Not applicable: the component emits no events; hosts attach telemetry to `onSelect`, `onNew` and `onDelete`.

## Privacy

Not applicable: the component collects, stores and transmits nothing; items, the tick set and queries are caller data (the rail holds its own query in memory only).

## Logging

Not applicable: the component writes no log output.

## Platform Notes

- **SwiftUI**: Start from `NavigationSplitView` with a sidebar `List(selection:)` for the rail and a detail view for the pane; `NavigationSplitViewVisibility` replaces the collapse state, and a `.searchable` modifier or an overlaid `TextField` with a suggestion `List` replaces the filter panel. The icon-only strip has no direct equivalent and needs a custom compact row. Swipe or a trailing `Button` with a `confirmationDialog` replaces the hover-revealed trash.
- **Compose**: Start from `ListDetailPaneScaffold` (Material 3 adaptive) with a `LazyColumn` of rows in the list pane and `NavigationRail` for the collapsed strip; `ExposedDropdownMenuBox` or a `DockedSearchBar` replaces the filter autocomplete. State is hoisted with `rememberSaveable`; the hover affordances become a long-press or a trailing icon button.
- **React/Web**: Source files: `packages/web/packages/ui/src/blocks/topic-detail.tsx`, a `"use client"` module using Tailwind utilities with `apt-*` tokens, `lucide-react` icons, pointer events with pointer capture for the drag handle, `useLayoutEffect` for pre-paint measurement with `ResizeObserver` and `document.fonts.ready`, and shared `AlertModal`, `Checkbox`, `CollapseToggle` and `Tooltip` components. Next.js App Router makes the document the React root, hence the explicit `stopImmediatePropagation` on Escape.
- **AppKit / UIKit**: Start from `NSSplitViewController` (macOS, with `NSSplitViewItem.isCollapsed` for the collapse) or `UISplitViewController` (iOS), with an `NSOutlineView` or `UICollectionView` list using a sidebar configuration for the rail; `NSSearchField` or `UISearchController` with a results table gives the autocomplete. Hover affordances use `NSTrackingArea` on macOS and swipe actions on iOS.
- **WinUI 3**: Start from `SplitView` (`DisplayMode="CompactInline"`, `CompactPaneLength="48"`, `OpenPaneLength="240"`, `IsPaneOpen` bound to the collapse state) holding a `ListView` with `SelectionMode="Single"` and a custom `ItemTemplate` for the rail, and a content `Grid` for the pane; or `NavigationView` with `PaneDisplayMode="Left"` for the same split. Each row is a `ListViewItem` style with an icon `FontIcon` at 16px, a `TextBlock` with `TextTrimming="CharacterEllipsis"` for the label, a second `TextBlock` with `MaxLines` for the preview, and a left `Border` of 2px whose brush is switched by `VisualStateManager` states (`Normal`, `PointerOver`, `Selected`, `Disabled`) in the item's `ControlTemplate`. The trash button lives in the same template and is shown by a `PointerOver` or `Focused` visual state setting its `Opacity`. Delete confirms in a `ContentDialog` with `DefaultButton="Close"` so initial focus is Cancel, and a `ProgressRing` shows busy during an async delete; the busy header spinner is a `ProgressRing`. The filter is an `AutoSuggestBox` (`TextChanged`, `SuggestionChosen`, `QuerySubmitted`) in a `CommandBar`-style toolbar, with the highlighted-letter underline made by `Run` elements with `TextDecorations="Underline"`. Batch mode is a `ListView` `SelectionMode="Multiple"` check column or a `CheckBox` in the template, kept separate from the single selected item. Drag resize needs a `Thumb` or a pointer-captured `Border` on the trailing edge. A narrow layout uses `AdaptiveTrigger` to stack the rail above the pane. Use `ThemeResource` brushes that mirror the `apt-*` tokens, set `AutomationProperties.Name` on tool buttons, `LiveSetting="Polite"` on the busy `TextBlock`, and honour `UISettings.AnimationsEnabled` for the width animation.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/topic-detail.tsx` | confirmed (2.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The pane stays bare; `TopicRail` owns the header, toolbar, `+`, footer and close button.
**Rationale**: Keeps the primitive focused and gives every consumer the same chrome blocks (separation of concerns), and `TopicDetail` opts out of the titled header and toolbar by passing no `title`.
**Approved**: pending

**Decision**: Collapse is intrinsic, with both controlled and uncontrolled modes.
**Rationale**: Collapsing to an icon strip is a core site gesture; controlled mode lets the hierarchical stack auto-minimize ancestor rails.
**Approved**: pending

**Decision**: The rail measures its own intrinsic width (`max-content`, rows, header and toolbar) and reports it through `onFit`.
**Rationale**: Only the rail knows its row anatomy, and an intrinsic measure cannot oscillate with the width the parent hands back; the range is scaled by the document's real root font size, because a hard-coded 16px range was a third too generous at the family's 12px root. The measure is skipped while a query narrows the rows, since a width taken from the matches outlived the query.
**Approved**: pending

**Decision**: Every titled rail has a filter, and its default is an autocomplete that leaves the rows whole; `live` filters the rows instead.
**Rationale**: Rails are too narrow for a pinned field, so a panel pops over the toolbar; a picker dialog that drives the list from the field needs `live`. Highlight is kept by topic id so a late-arriving host list does not move it, and the selected row is offered only if it matches so Return cannot choose the topic already open.
**Approved**: pending

**Decision**: Filter keystroke quirks are handled explicitly: Escape stops at the field, Return calls `preventDefault` before focus moves, IME Return is ignored, and the clear button and suggestion list swallow `mousedown`.
**Rationale**: Each is a recorded bug: a dialog closing with the filter, Return re-opening the panel through the button's keypress, an IME candidate choosing a row, and Safari blurring the field and closing the panel before a click landed.
**Approved**: pending

**Decision**: The underline maps positions per character instead of searching the folded label.
**Rationale**: Case folding can change a label's length ("İstanbul"), which put the underline on the wrong letters.
**Approved**: pending

**Decision**: A link row is reported to `onSelect` by the list and run by the owner (`TopicDetail` does it via `topicLinkOf`); a flash id stands in for the selection for 1000ms.
**Rationale**: A link is never an entry of its own list, so without the flash the click would show nothing.
**Approved**: pending

**Decision**: The blocked dot rides the icon, with the standalone dot when icons are hidden, and the state is announced by text.
**Rationale**: Trailing slots are dropped in the strips, where a user hunting for a greyed-out Save most needs the marker; colour alone is not a signal.
**Approved**: pending

**Decision**: Ticking a batch checkbox is independent of selecting a row, and the checkbox is a sibling of the row button.
**Rationale**: A checkbox cannot nest in a button, and acting on rows other than the open one must not close its detail.
**Approved**: pending

**Decision**: Covered lists are pure-select, uncovered lists re-fire `onSelect` on a re-click.
**Rationale**: Covered rows are peeking siblings with no dismiss affordance; the uncovered owner decides whether a repeat means toggle-off.
**Approved**: pending

**Decision**: Prefetch uses one dwell timer per list and never arms on the selected row.
**Rationale**: A per-row timer would arm several during a sweep, and re-reading the open row spins its own list behind the pane.
**Approved**: pending

**Decision**: A failed `onDelete` leaves the dialog open and the error to the caller.
**Rationale**: The caller knows the failure and its wording; the dialog stays so the user can retry or cancel.
**Approved**: pending

**Decision**: Every row is guaranteed an icon, and `preview` is clamped through a lookup table with a number clamp.
**Rationale**: The icon strip must never show a blank slot; Tailwind only generates classes it sees written out, and `previewLines` comes from a user setting, so an out-of-range number would silently print the whole note.
**Approved**: pending

**Decision**: `description` and `leadsTo` stay on the shared item type though this file never reads them.
**Rationale**: One row shape serves surfaces that show a blurb and the cascading view's hold logic, so a host does not map between shapes.
**Approved**: pending

**Decision**: Technical debt: the source documents `TopicList` and `rowExitEl` with a doc comment block left over above `rowExitEl` that belongs to `TopicDetail`, and keeps two copies of the width-constant comment.
**Rationale**: Noted so implementers do not treat the stray comment as a requirement; no behavior depends on it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-platform-notes](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/90c2d8c2-cf79-5465-bffd-54f9fb1453bc) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | Artifact Formatting |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on `topic-detail.tsx`. Screen-reader and semantic-markup pass on real buttons, `aria-current`, `role="toolbar"`, `role="separator"`, the combobox wiring and the always-mounted status region. Keyboard is partial because the resize handle is pointer-only (the open question on `resize-handle-keyboard`) and touch-target size is partial for the open question on `tool-target-size`. Focus management passes: closing the filter returns focus to its button and the dialog's initial focus is Cancel. Reduced motion is partial: the width transition follows `--apt-anim-scale` but the busy spinner's `animate-spin` has no override in this file. The two internationalization checks fail because the fixed English literals listed under Localization have no override. Explicit error handling is partial because a failed `onDelete` is caught and swallowed, leaving the message to the caller. Separation of concerns passes: `TopicList`, `TopicRail` and `TopicDetail` are separate, and the filter helpers are exported pure functions. Unit-test coverage is partial: `topicDetailConformance.test.tsx` in `packages/web/packages/ui/src/__tests__` carries one test per vector, T1 to T83, and 82 pass. T51 (the single-column layout below `md`) is skipped because jsdom applies no CSS media queries.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Verified against source: corrected behavior, states and platform notes |
| 1.6.1 | 2026-09-25 | Mike Fullerton | Rail-slot/respond-mobile/skip-disabled/divider-spacer corrected vs source; T52/T53 added. |
| 1.6.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed every requirement to subject-only kebab-case (dropped the `must-` prefix everywhere, including a typo and a reword) and updated all citations in test vectors, edge cases, and design decisions; corrected factual contradictions against source (preview clamping has no fallback path, non-covered re-click re-fires `onSelect` with no deselect signal, `data-blocked` lives on the row not the marker, drag-resize has no undefined range, the collapse toggle's fixed "topic list" label is independent of `railLabel`); added a requirement, test vectors, and edge-case coverage for `denseBottom`, and test vectors for `transition-collapse`, `covered-shadow`, delete-throws, prefetch-not-arming, `onFit` post-font-load re-measurement, and `onToggleChecked`; corrected the exported-surface list (`TopicList` is module-private) and documented `description`/`leadsTo` as intentional pass-through fields; rebuilt Compliance as a catalog-linked table with honest per-check status; reformatted Design Decisions into Decision/Rationale/Approved triples; rewrote Localization and Accessibility Options with real content instead of "Not applicable"; rewrote Platform Notes to drop the "Not applicable" framing, replace outdated APIs (`NavigationSplitView`, `UIControl.Event`), map WinUI resources to token-mirroring `ThemeResource` keys instead of hardcoded hex, and drop redundant manual-keyboard guidance already covered by native `Button`. |
| 1.5.0 | 2026-09-22 | Mike Fullerton | Comprehensive revision: expand behavioral requirements to cover all API surface (batch mode, prefetch, delete confirmation, blocked state, covered style, selection styles, row disclosure, etc.); detail all appearance properties and state transitions; verify all edge cases against source implementation; complete Platform Notes with all five platforms and concrete WinUI 3 guidance; document all props and exported types; add 44 test vectors covering every MUST requirement and major features; set status to review. |
| 1.4.0 | 2026-07-14 | Mike Fullerton | `inlineSublabel` on `TopicDetailItem`: render `sublabel` on the label's line (dim, label-priority truncation) for dense single-line entity rows (sites / groups / platforms / users). New requirement `must-render-inline-sublabel`. |
| 1.3.0 | 2026-07-10 | Mike Fullerton | TopicRail `headerSlot`: pinned strip under the titled header for the shared ListHeader (filter + actions). |
| 1.2.0 | 2026-07-03 | Mike Fullerton | `spacerAfter` on `TopicDetailItem`: a flexible spacer after the item pins the following items to the rail's bottom edge (e.g. a bottom Settings), in the full rail and the collapsed/covered icon strips alike. New requirement `must-render-spacer-after`. |
| 1.1.0 | 2026-06-30 | Mike Fullerton | Collapse-aware `railSlot` render-prop (→ `+` when undisclosed); always-reserved leading slot (first-row alignment); controllable collapse (`collapsed`/`onCollapsedChange`/`defaultCollapsed`). |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial draft |
