---
id: 88d69611-4a12-4777-9509-8af6c0626dc7
title: "CategoryPickerDialog"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-08-23
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Modal tree browser that returns a place in the category hierarchy (a category id or the top level), with filter search, keyboard navigation and OK/Cancel."
platforms:
  - typescript
  - web
tags:
  - category
  - picker
  - tree
  - dialog
depends-on:
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
  - f679a77e-04f7-4e43-b898-6d78a637a760
related:
  - 40827b84-406e-4091-951b-9498b2f78253
  - 79f7ed30-3193-49bc-856b-d7dd01303baa
  - 550f00f7-bfb2-415e-9b15-bd5dce015500
references: []
approved-by: ""
approved-date: ""
---

# CategoryPickerDialog

## Overview

`CategoryPickerDialog` is the family's category **picker**: a modal that browses
the owner's whole category hierarchy and returns one **place** in it — a category
id, or (when offered) the top level. It is built directly on the shared `Dialog`
primitives (`Dialog`, `DialogContent`, `DialogHeader`, `DialogTitle`,
`DialogDescription`, `DialogActions`, `Input`, `ErrorText`) rather than on
`ListChooser` or `EntityChooser`: those compose a single-field filter/add control
over a **flat** list, and a place in a tree cannot be expressed as a bare name.

The dialog folds the caller's flat `nodes: CategoryTreeNode[]` into a forest with
`buildCategoryTree` (`category-tree.ts`), inside a `useMemo` keyed on `nodes` — so
it recomputes only when the caller's rows actually change, always browsing the
same materialisation Topic Detail ([adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f))
draws for its own rail. Browsing is a real WAI-ARIA `tree` — one roving tab stop,
arrow-key expand/move/collapse — and typing into the field switches the list to a
flat, trail-annotated filter (`role="listbox"`) so a match three levels down is
found by typing its name rather than walking to it.

It is the modal behind a hierarchical category browser's "Move…" gear action —
the host supplies `disabledIds` (the moved category and its own descendants, so a
category can never become its own ancestor) and `allowRoot` (a move can land a
category at the top level, which is why the root row exists at all). Every word
the host controls — `title`, `description`, `confirmLabel`, `rootLabel` — is
supplied by it; the component's own built-in English strings ("No categories
yet.", the filter-match message, `aria-label="Filter categories"` /
`aria-label="Categories"`, the placeholder "Filter categories…", and the
Expand/Collapse `title`) are not props and are not currently overridable — see
Compliance and Localization-adjacent notes below.

## Behavioral Requirements

- **return-a-place-not-a-record**: Confirming MUST call `onConfirm` with either a category id (the selected node) or `null` (the root row), never a name or a record — the picked value is WHERE, not WHAT.
- **browse-the-full-forest**: With the filter empty, the dialog MUST render every node `buildCategoryTree(nodes)` yields, each with a chevron toggle when it has children and no toggle when it does not.
- **filter-by-substring-with-trail**: Typing in the field MUST narrow the list to nodes whose name contains the typed text (case-insensitive substring), each option showing the "/"-joined names of its ancestors; a node filed under more than one parent MUST appear once, keeping its first (sibling-order) trail.
- **offer-a-root-row-only-when-allowed**: The "top level" row (`rootLabel`, default "Top level") MUST render only when `allowRoot` is set, and selecting it MUST make `null` the pending selection.
- **disable-forbidden-rows**: A node whose id is in `disabledIds` MUST render visibly disabled and MUST NOT become selectable, in both browse and filter mode.
- **preselect-initial-id**: On open, the pending selection MUST start at `initialSelectedId` (default `null`). A `null` selection IS the root row, not "no selection": when `allowRoot` is set, the "Top level" row renders selected and highlighted from open, and is confirmable while the filter text is empty (see **disable-confirm-when-unpickable**); when `allowRoot` is not set, there is no root row to render, so a `null` selection shows no highlighted row and Confirm stays disabled.
- **tree-keyboard-nav**: In browse mode, ArrowDown/ArrowUp MUST move the roving tab stop to the next/previous VISIBLE row (collapsed children skipped); ArrowRight on a collapsed parent MUST expand it, on an expanded parent MUST move into its first child; ArrowLeft on an expanded parent MUST collapse it, on a leaf or collapsed node MUST move to its parent; Home/End MUST move to the first/last visible row.
- **filter-mode-arrow-nav**: In filter mode, ArrowDown/ArrowUp MUST move the roving tab stop to the next/previous option in the flat hit list (the same shared row list and key handler browse mode uses), and Home/End MUST move it to the first/last option; arrow keys have no effect while focus is still in the filter field itself — reaching the list requires Tab (to the roving tab stop) or a pointer click first. No `aria-activedescendant` is used; each option is an independently focusable `<button>` using the same roving-tabindex pattern browse mode uses.
- **native-row-activation**: Every row, in either mode, MUST be a native `<button>`, so Enter, Space, a click, and a double-click all activate it identically — there is no separate keydown handler for row selection, only the browser's own button-activation behavior.
- **filter-field-enter-inert**: Enter pressed in the filter field MUST NOT select or confirm anything — the field is not enclosed in a `<form>`, so Enter performs no default action and the dialog defines none of its own.
- **disable-confirm-when-unpickable**: The confirm button MUST be disabled unless the pending selection is confirmable — the root row when `allowRoot` is set AND the filter text is empty, or a node not in `disabledIds`. (The empty-filter condition on the root row exists to prevent a silent move-to-root once the list has been filtered down to something else.)
- **reset-on-reopen**: Each transition to `open=true` MUST clear the filter text, the expanded set and the roving focus, and MUST reset the pending selection to `initialSelectedId` — a reopen is a fresh question, not a resumed one.
- **roving-focus-origin**: The roving tab stop MUST start on the first visible row after a reset — the root row when `allowRoot` is set, otherwise the first top-level category — regardless of `initialSelectedId`; a collapsed branch containing `initialSelectedId` is NOT auto-expanded to reveal it, so a nested preselection starts off-screen and unfocused until the user navigates to it.
- **report-write-errors-inline**: A non-null `error` MUST render above the button bar without closing the dialog; `busy` MUST disable the filter field and MUST replace both the Cancel and Confirm buttons with a `role="status"` loading indicator (via `DialogActions`) while a confirm is in flight — there is no disabled button in the DOM, only the field is actually disabled.
- **cancel-without-confirming**: Esc, the Cancel button, or a non-busy outside dismiss MUST call `onCancel` and MUST NOT call `onConfirm`; while `busy`, all three are blocked instead — Cancel and Confirm are both replaced by the loading indicator (see **report-write-errors-inline**), so there is no Cancel button to click, and Esc/outside dismissal are suppressed by the same busy check, so none of the three call `onCancel` either.
- **show-empty-messages**: With no categories at all, browse mode MUST show "No categories yet."; with a filter that matches nothing, filter mode MUST show a message naming the typed text.

## Appearance

Filter field, then either the tree or the filtered list, then the button bar:

```
┌───────────────────────────────────────────┐
│ Move "Q3"                                  │  ← title — the host's own words
│ Choose where it should sit. Its other      │  ← optional description
│ filings are left alone.                    │
├───────────────────────────────────────────┤
│ [ Filter categories…                    ]  │  ← Input, autoFocus, role="searchbox"
├───────────────────────────────────────────┤
│   Top level                                │  ← allowRoot row (FolderTree icon, no chevron)
│ ▾ Work                                     │  ← expanded parent (ChevronDown)
│     Q1                                     │  ← child of Work (Folder icon, no chevron)
│     Q2                                     │
│ ▸ Planning                                 │  ← collapsed parent (ChevronRight)
├───────────────────────────────────────────┤
│                         Cancel      Move   │  ← DialogActions; confirm disabled if unpickable
└───────────────────────────────────────────┘
```

Filtering ("q" typed) replaces the tree with a flat `listbox` of matches, each
row showing the match name and its dim, monospace ancestor trail underneath.
Selected row: `bg-apt-gold/15`. Disabled row: `opacity-40`. All color from
`apt-*` tokens; no raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| Closed | not rendered |
| Open, `allowRoot` unset, no `initialSelectedId` | confirm disabled; no row shows `bg-apt-gold/15` (there is no root row to highlight) |
| Open, `allowRoot` set, no `initialSelectedId` | `null` selection is the root row: "Top level" shows `bg-apt-gold/15` from open; confirm enabled while the filter is empty, disabled once it isn't |
| Row selected (allowed) | `bg-apt-gold/15`; confirm enabled |
| Row selected (forbidden) | cannot occur — a forbidden row cannot be clicked into selection |
| Node collapsed | `ChevronRight`; children not in the DOM or the keyboard order |
| Node expanded | `ChevronDown`; children rendered and reachable by ArrowDown |
| Filtering | tree replaced by a flat `listbox` of trail-annotated matches |
| No categories | "No categories yet." (browse mode only) |
| No filter match | `No categories match "<text>".` |
| `busy=true` | field disabled; Cancel and Confirm both replaced by a `role="status"` loading spinner (no buttons in the DOM) |
| `error` set | `ErrorText` renders above the button bar |

## Accessibility

- Browse mode: the list is `role="tree"` (`aria-label="Categories"`); each row is
  `role="treeitem"` with `aria-selected`, `aria-expanded` (parents only) and
  `aria-disabled` on a forbidden row. Exactly one row carries `tabIndex={0}` (the
  roving tab stop); every other row is `tabIndex={-1}`, so Tab moves past the
  whole tree in one stop and arrow keys move within it (WAI-ARIA tree pattern).
- Filter mode: the list is `role="listbox"` (`aria-label="Categories"`); each row
  is `role="option"` with `aria-selected` / `aria-disabled`.
- The filter field is `role="searchbox"` with `aria-label="Filter categories"`
  and `autoFocus` on open.
- The dialog itself carries the shared `Dialog`'s focus trap, portal and
  Escape-to-close; closing (when not `busy`) returns focus per that primitive.
- Every expand/collapse chevron button carries a `title="Expand/Collapse <name>"`
  tooltip and is `aria-hidden`, so it is excluded from both the tab order
  (`tabIndex={-1}`) and the accessibility tree entirely — it is a pointer
  affordance; the same action is reachable from the row via ArrowRight/Left.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | browse-the-full-forest | open with a 2-level forest | roots render; expanding a root reveals its children |
| T2 | filter-by-substring-with-trail | type a substring matching a depth-2 node | that node appears as an option with its "/"-joined ancestor trail |
| T3 | return-a-place-not-a-record, disable-confirm-when-unpickable | open, confirm disabled; click a row, confirm | confirm was disabled with no selection; `onConfirm(nodeId)` fires after the click |
| T4 | offer-a-root-row-only-when-allowed | `allowRoot`, select "Top level", confirm | `onConfirm(null)` |
| T5 | disable-forbidden-rows | `disabledIds=[x]`, click row x | row x stays unselected; confirm stays disabled |
| T6 | cancel-without-confirming | open, click Cancel | `onCancel` fires; `onConfirm` never fires |
| T7 | tree-keyboard-nav | roving stop on a collapsed parent; ArrowRight, ArrowDown, ArrowUp | ArrowRight expands it; ArrowDown moves into its now-visible first child, skipping collapsed siblings; ArrowUp reverses |
| T8 | tree-keyboard-nav | roving stop on an expanded parent's child; ArrowLeft, ArrowLeft again | first collapses the parent; second moves the stop to the parent |
| T9 | tree-keyboard-nav | Home, then End | roving stop moves to the first, then the last, visible row |
| T10 | preselect-initial-id, reset-on-reopen | open with `initialSelectedId="x"`, close, reopen with the same prop | selection starts at x both times; filter/expanded state is empty each open |
| T11 | report-write-errors-inline | `error="conflict"`, `busy` | error text shown above the buttons; field disabled; Cancel/Confirm replaced by a `role="status"` loading spinner — no Cancel/Confirm buttons exist in the DOM |
| T12 | show-empty-messages | `nodes=[]` (browse); a filter matching nothing | "No categories yet."; `No categories match "<text>".` |
| T13 | roving-focus-origin | open with `initialSelectedId` inside a collapsed branch, `allowRoot` unset | roving tab stop is the first top-level category, not the (invisible) preselected node |
| T14 | native-row-activation | focus a row, press Enter (then, on another row, Space) | row selects, identical to a click |
| T15 | filter-field-enter-inert | type a filter, press Enter while focus is still in the field | nothing selects or confirms; focus remains in the field |
| T16 | filter-mode-arrow-nav | type a filter matching several nodes, Tab into the list, ArrowDown twice | roving tab stop moves to the second option, then the third |
| T17 | filter-by-substring-with-trail | type a substring matching a node filed under two parents | exactly one option renders, showing its first (sibling-order) trail |
| T18 | filter-by-substring-with-trail, show-empty-messages | type only spaces into the filter field | browse mode (tree) renders; the "no match" message does not |
| T19 | disable-confirm-when-unpickable | open with `initialSelectedId` naming an id absent from `nodes` | no row renders selected; Confirm's enabled state follows only `disabledIds` membership, so it stays enabled and would call `onConfirm` with the nonexistent id if clicked |
| T20 | disable-forbidden-rows | `disabledIds=[x]`, filter to a hit that includes x | row x renders disabled and unselectable in the option list too |
| T21 | offer-a-root-row-only-when-allowed | open with `allowRoot` unset (default `false`) | no "Top level" row renders; the first visible row is the first top-level category |
| T22 | cancel-without-confirming | press Esc while not busy; then press Esc (and attempt an outside click) while `busy` | not busy: `onCancel` fires; busy: dialog remains open and `onCancel` does not fire either time |
| T23 | preselect-initial-id, disable-confirm-when-unpickable | `allowRoot`, no `initialSelectedId` (default `null`) | "Top level" renders `aria-selected="true"` and `bg-apt-gold/15` on open; Confirm is enabled; clicking it calls `onConfirm(null)` |
| T24 | disable-confirm-when-unpickable | continuing from T23, type any filter text | Confirm becomes disabled (the root row is confirmable only while the filter is empty) |

## Edge Cases

- **Empty vocabulary.** `nodes=[]` renders no category rows in browse mode; the
  root row still renders when `allowRoot` is set (it does not depend on `nodes`),
  and the **show-empty-messages** text ("No categories yet.") renders alongside
  it in the same pass — the message names the absence of categories, not the
  absence of rows generally, so the root row does not suppress it. Never an
  error state; see T12.
- **A category filed under two parents.** It draws once per placement in browse
  mode (the same node, two different `path`s — `categoryKey` disambiguates the
  React keys), but the FILTER list dedupes it to one option by `id`, keeping the
  first placement's trail — a filter result is one id, so it must read as one
  option (see `category-picker-dialog.tsx`'s `dedupeById`); see T17.
- **A cycle in legacy data.** The dialog never sees the raw edges — `nodes` is
  the caller's flat `CategoryTreeNode[]` rows, unfolded. This component is the
  one that calls `buildCategoryTree` (memoized on `nodes`), and that fold's own
  cycle-breaking (re-seeding an orphaned branch as a root) is what determines
  what the tree shows; see the tree-fold's own contract for `buildCategoryTree`.
  The dialog adds no cycle handling of its own — it only walks what the
  fold hands back.
- **The `MAX_TREE_NODES` cap (4000).** A forest at the cap still renders and is
  still fully keyboard-navigable — the fold stops MATERIALISING nodes, not the
  dialog from walking whatever it received; a picker over a capped forest simply
  cannot offer the nodes that were never drawn.
- **Whitespace-only filter text.** Trimmed before matching; an all-whitespace
  filter behaves as no filter (browse mode, not an empty-match message); see T18.
- **`null` selection is the root row, not "nothing picked."** With `allowRoot` set and no `initialSelectedId`, the dialog opens with "Top level" already selected and confirmable — clicking Confirm immediately calls `onConfirm(null)`. Typing any filter text makes the root row unconfirmable again (see **disable-confirm-when-unpickable**) even though it stays the pending selection, closing what would otherwise be a silent move-to-root once the list no longer shows the root row as the obvious pick; see T23, T24.
- **Reopening on a stale `initialSelectedId`.** If the id no longer exists in
  `nodes`, no row renders as selected — the lookup that drives the highlight
  finds nothing to match — but **disable-confirm-when-unpickable** checks only
  `disabledIds` membership, not existence in `nodes`; a stale id that is not
  itself in `disabledIds` leaves Confirm enabled, and clicking it calls
  `onConfirm` with an id no visible row matches. The dialog does not fall back
  to the root or the first row, and performs no validation of
  `initialSelectedId` against `nodes` on its own; see T19.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `open` | `boolean` | — | Controls the `Dialog`. |
| `nodes` | `readonly CategoryTreeNode[]` | — | The owner's whole vocabulary; folded internally with `buildCategoryTree`. |
| `title` | `string` | — | Dialog title — the host's words. |
| `description` | `React.ReactNode` | — | Optional dialog description. |
| `confirmLabel` | `string` | — | The confirm button's verb ("Move", "Choose…") — the host's, because only it knows what the pick is for. |
| `disabledIds` | `readonly string[]` | `[]` | Ids that cannot be picked — for a move, the category itself and its descendants. |
| `allowRoot` | `boolean` | `false` | Offers a "no parent" row that confirms with `null`. |
| `rootLabel` | `string` | `"Top level"` | Copy for the root row. |
| `initialSelectedId` | `string \| null` | `null` | Pre-selected category id. `null` selects the root row — highlighted and confirmable (while the filter is empty) when `allowRoot` is set; unhighlighted with Confirm disabled when it is not. |
| `error` | `string \| null` | `null` | A rejected confirm's message — the host owns it. |
| `busy` | `boolean` | `false` | Disables the field and replaces both action buttons with a `role="status"` loading spinner (`DialogActions`) while a confirm is in flight. |
| `onConfirm` | `(categoryId: string \| null) => void` | — | Fired on confirm with the pending selection. |
| `onCancel` | `() => void` | — | Fired on Cancel, Esc, or a non-busy outside dismiss. |

Exports: `CategoryPickerDialog`, `CategoryPickerDialogProps`.

## Deep Linking

None: the dialog is invoked imperatively by the host via its `open` prop. The
source subscribes to no router and reads/writes no URL.

## Localization

None: `title`, `description`, `confirmLabel`, and `rootLabel` are host-supplied
strings, so the host controls their translation. But the source also carries its
own hardcoded English strings that are not run through any i18n mechanism: the
filter's placeholder ("Filter categories…") and `aria-label` ("Filter
categories"), and the two empty-state messages ("No categories yet." and `No
categories match "{filter}".`).

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: the source contains no `prefers-reduced-motion` check, and the `Dialog`/`DialogContent` primitives it composes carry no open/close transition of their own in this file. |
| Increase Contrast | Depends on the `apt-*` design tokens (e.g. `apt-gold`, `apt-text-muted`, `apt-border`); the component itself does no `prefers-contrast` handling. |
| Differentiate Without Color | A selected row's `aria-selected` and a forbidden row's `aria-disabled`/`opacity-40` are both readable independent of color; the chevron's direction (right = collapsed, down = expanded) also carries state without relying on color. |

## Feature Flags

None: the dialog is a presentational control invoked by the host. Feature-gating
whether it opens at all is the host's concern, not the source's.

## Analytics

None: the source calls only `onConfirm`/`onCancel`. It emits no analytics or
telemetry events of its own; any tracking around a pick is the host's, driven by
those callbacks.

## Privacy

None: the dialog transmits nothing. `nodes`, `disabledIds`, and the confirmed id
are held and passed in memory by the host, which owns any request to a backend.

## Logging

None — a presentational control. The host performs the write the confirmed id
drives and owns any telemetry for it.

## Platform Notes

- **React / Web (TypeScript):** `packages/web/packages/ui/src/blocks/category-picker-dialog.tsx`. `"use client"`.
- **SwiftUI:** Present with `.sheet(isPresented:)`, pairing `.interactiveDismissDisabled()` with this dialog's non-busy-only dismissal; inside the sheet, an `OutlineGroup` (or nested `DisclosureGroup`s, one per row) over the category forest gives native disclosure-triangle expand/collapse and built-in keyboard navigation — not a bare `List`. Apply `.searchable(text:)` to the sheet for the filter field; SwiftUI itself switches to a flat, breadcrumb-annotated result list when the search text is non-empty. The confirm button's `disabled` binding tracks the same pickability computation as the source; a tap on a row selects it, matching the WAI-ARIA tree pattern's row-activation model.
- **Compose:** Build on `Dialog` (or `ModalBottomSheet`) with custom content — not `AlertDialog`, which is an alert-shaped container with no room for a tree body or a search field. A `LazyColumn` displays expandable category items, each row's expand icon toggling a `remember`ed expanded-id set; a `TextField` above the column switches it to a flat list with parent breadcrumbs when its value is non-empty; disabled categories render at reduced opacity and ignore taps; the confirm button's `enabled` binding mirrors the same pickability computation; arrow keys and a roving `FocusRequester` provide keyboard-only navigation over the shared row list.
- **AppKit / UIKit:** Not `NSAlert`/`UIAlertController` — both are scoped to alert/action-sheet layouts and cannot host a tree or a search field (the same reason the web implementation builds on plain `Dialog` rather than `AlertModal`; see Design Decisions). Use an `NSPanel` presented as a sheet (macOS) or a modally presented `UIViewController` (iOS) as the container, with an `NSOutlineView` (macOS) or a custom hierarchical `UITableView`/`UICollectionView` (iOS) for browsing; add an `NSSearchField` or `UISearchBar` above it that swaps the outline/table for a flat, breadcrumb-annotated result list while its text is non-empty; disabled rows render at reduced opacity and reject selection; the confirm control's enabled state tracks the same pickability computation; keyboard navigation follows each platform's native outline/table conventions.
- **WinUI 3:** Use `ContentDialog` as the modal container with a `TreeView` for hierarchical browsing (`IsExpanded` per node) — `TreeView` already provides roving keyboard focus and arrow-key navigation natively, so no additional `IsTabStop` wiring is needed. Add an `AutoSuggestBox` above it for search/filtering; when its text is non-empty, replace the `TreeView` with a `ListView` showing the flat, breadcrumb-annotated results below each match. Apply a disabled visual state (reduced opacity) to items in the `disabledIds` set; `IsPrimaryButtonEnabled` binds to a computed property mirroring the same pickability check.

Consumes `buildCategoryTree`, `categoryKey`, `CategoryNode`, `CategoryTreeNode` from the sibling `category-tree.ts` — the single fold every hierarchical category surface reads. Demo: the UI showcase app's demo page (Topic id `category-picker`) + the showcase source registry. The showcase is a consumer of this package and lives outside this repo. First (and so far only) consumer: a hierarchical category browser's Move action. Responsive: verify via the ui-showcase demo at 375 / 768 / 1440 — the dialog's own `max-w-md` and internal scroll (`max-h-72`) keep it usable at phone width; keyboard-only and pointer flows both apply at every width.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/category-picker-dialog.tsx` | unverified |

## Design Decisions

**Decision**: Build a tree browser on the base `Dialog` primitives, not on
`ListChooser`/`EntityChooser`'s flat filter-and-add pattern.
**Rationale**: [adhsdk.ingredient.ui.components.inputs.list-chooser](cookbook:40827b84-406e-4091-951b-9498b2f78253)
and [adhsdk.ingredient.ui.components.inputs.entity-chooser](cookbook:79f7ed30-3193-49bc-856b-d7dd01303baa) both pick
a RECORD from a flat set — the correct model when a name is already a unique,
sufficient answer (a document's category via `CategoryField`, or a tag). This
dialog picks a **place** in a tree — a parent — and a place cannot be named
without saying where it sits; "no parent (make it a root)" is a legitimate
answer neither chooser can express (`ListChooser`/`EntityChooser` have no
concept of nesting, let alone an explicit top-level option). So the tree is the
primary control here and the filter is a shortcut into it, the reverse of
`ListChooser`'s filter-is-everything model. `CategoryField`'s own chooser (the
document-level "pick a category by name" control) makes the identical trade the
other way, for the identical reason: names are unique per owner across the whole
hierarchy, so a bare name is already an exact address there, and walking a tree
to find what typing three characters already resolves would be slower, not more
precise. `CategoryField` is shipped but has no recipe of its own yet; the
contrast lives here because a reader comparing the two pickers is most likely to
land on this file first.
**Approved**: pending

**Decision**: Compose the base `Dialog` primitives, not
[adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500)'s
`AlertModal`.
**Rationale**: `AlertModal` is an alert/confirm shape with a single description
slot; this dialog needs an interactive tree body, a search field, and an OK
that is conditionally disabled on a live selection — none of which fits the
alert/confirm contract. Building on the plain `Dialog` primitives keeps the
focus trap, portal and Escape-close shared without forcing an ill-fitting shape
onto them.
**Approved**: pending

**Decision**: The filter result dedupes by category id; the browse tree does
not.
**Rationale**: Browsing shows every real placement (the honest DAG picture
Topic Detail ([adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f)) itself shows for
its own rail); a filter result is read as one answer per id, so showing the
same category twice there would look like two different categories. Deduping
only the filter view keeps both readings correct for what each is for.
**Approved**: pending

**Decision**: `buildCategoryTree` runs again inside this component rather than
accepting a pre-built `CategoryNode[]` prop.
**Rationale**: Taking `nodes: CategoryTreeNode[]` rather than a pre-built
`CategoryNode[]` keeps this component's public contract independent of the
internal fold's shape, and lets any caller with the flat rows open the picker
without importing `buildCategoryTree` itself. The fold runs inside a `useMemo`
keyed on `nodes`, so it recomputes only when the caller's rows actually change
rather than on every render; bounded by `MAX_TREE_NODES`, that memoized
recomputation is cheap enough that this component's contract independence costs
nothing measurable.
**Approved**: pending

**Decision**: No built-in async state.
**Rationale**: `nodes` is a controlled in-memory prop; the host owns fetching,
loading and error, and reports a REJECTED confirm through `error`/`busy` —
consistent with the sibling form controls
([adhsdk.ingredient.ui.components.inputs.list-chooser](cookbook:40827b84-406e-4091-951b-9498b2f78253),
[adhsdk.ingredient.ui.components.inputs.entity-chooser](cookbook:79f7ed30-3193-49bc-856b-d7dd01303baa)).
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `category-picker-dialog.tsx`: the `role`/`aria-*` attributes on
tree and listbox rows, the inherited `Dialog` focus trap, and the full arrow-key
plus Home/End coverage support the passed accessibility rows; the `apt-*` token
contrast values and whether the `text-sm`/`text-xs` rem-based classes track
system font scaling aren't verifiable from this file, hence partial; the
expand/collapse toggle's `size-6` (24×24px) hit area and the row buttons'
`px-2 py-1` padding both fall well short of the 44×44 target, so
touch-target-size fails; and the hardcoded, non-overridable built-in strings
("No categories yet.", the filter-match message, `aria-label="Filter
categories"`/`"Categories"`, the placeholder, and the Expand/Collapse `title`)
fail both internationalization checks. separation-of-concerns is partial
because `flattenWithTrails`/`dedupeById` are extracted but the roving-tabindex
keyboard state machine (`onRowsKeyDown`, `visibleRows`) still lives inside the
component, while unit-test-coverage is passed because
`categoryPickerDialog.test.tsx` exercises expansion, filtering, selection,
disabled rows, and every arrow-key interaction with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.1 | 2026-09-25 | Mike Fullerton | busy replaces Cancel/Confirm with a status spinner (field-only disabled), not two disabled buttons (T11 corrected); null initialSelectedId is the root-row selection (confirmable only while filter is empty) not "no selection" (T23/T24 added). Added the Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics and Privacy sections. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed Behavioral Requirements to subject-only kebab-case and updated every citation; added filter-mode-arrow-nav, native-row-activation, filter-field-enter-inert and roving-focus-origin requirements with new test vectors T13-T16; added vectors T17-T22 for multi-parent filter dedupe, whitespace-only filter, a stale initialSelectedId, disabled rows in filter mode, no root row when allowRoot is unset, and Esc/outside-dismiss under busy; corrected the Appearance diagram's glyphs and dropped its unclear title annotation; corrected the chevron button's Accessibility citation from aria-label to title/aria-hidden; resolved the buildCategoryTree double-fold contradiction between the Edge Cases and Design Decisions and restated the fold's actual useMemo-based memoization; corrected the stale-initialSelectedId and empty-vocabulary Edge Cases against source; replaced wiki-link cross-references with full domain URLs, linked "the rail" to Topic Detail, and added alert-and-dialog to related; trimmed tags from seven to four; reformatted Design Decisions into Decision/Rationale/Approved blocks; rebuilt Compliance as linked accessibility/internationalization checks with a supporting sentence; corrected the SwiftUI/Compose/AppKit-UIKit/WinUI 3 Platform Notes to real, tree-and-search-capable APIs |
| 1.1.1 | 2026-09-22 | Claude Haiku 4.5 | Add concrete WinUI 3 and other platform translation guidance to Platform Notes |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Revised recipe per writer guidelines for Phase 2 ui-blocks recipes. |
| 1.0.0 | 2026-08-23 | Mike Fullerton | Initial component + recipe. |
