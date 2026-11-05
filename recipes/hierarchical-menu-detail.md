---
id: aaebd90e-991f-4133-a12d-0783586eae5a
title: Hierarchical Menu Detail
domain: adhsdk://recipes/hierarchical-menu-detail
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A nested-menu framework rendering hierarchical lists with three disclosure
  styles and optional detail pane.
platforms:
- typescript
- web
tags:
- menu
- navigation
- hierarchy
depends-on:
- adhsdk://recipes/topic-detail
related:
- adhsdk://recipes/topic-detail
references: []
approved-by: ''
approved-date: ''
---

# Hierarchical Menu Detail

## Overview

HierarchicalMenuDetail is a container for rendering cascading hierarchies of topic/detail rails where each level's selection scopes the next. A consumer passes a flat `levels` array; the component renders each as a side-by-side column (wide mode) or full-width pane (narrow mode), connecting selections via breadcrumb trail. Three disclosure styles control how ancestor lists yield room to the detail pane as the window narrows: minimized (icon strips then slide off), covered (stack under child), and cascading (each deeper list opens to the right of its parent, stepped down one header-height per level, like a nested menu).

## Behavioral Requirements

- **render-levels**: Component MUST render each level from `levels[0]` through the frontier (see **scope-by-selection**) as a distinct, scrollable list column with rows for that level's `items`.
- **scope-by-selection**: Each level's visible items MUST be determined by the parent level's `selectedId`. The frontier — the first level whose `selectedId` is `null`, or the last level if every level has a selection — MUST render, showing all of its items with nothing selected; every level deeper than the frontier MUST NOT render at all.
- **show-breadcrumb**: When `showBreadcrumb` is true (default), component MUST display a breadcrumb trail with a root label (if provided) and a crumb for each level whose `selectedId` is non-null, reading from outermost to deepest.
- **navigate-breadcrumb**: When breadcrumb crumbs are interactive (`onNavigate` provided), clicking a crumb MUST call the level's `onClear()` for all levels deeper than the clicked crumb, leaving the clicked level's selection in place.
- **deselect-on-reclick**: Clicking a row whose `id` is already `selectedId` MUST call the level's `onClear()`.
- **disclosure-styles**: Component MUST support three `disclosureStyle` values — "minimized", "covered", "cascading" — each controlling how ancestor lists are hidden or revealed when viewport narrowness prevents showing all columns (see also **covered-peek** for the covered style's specific hidden-list treatment).
- **autohide**: When `autoHideTopics` is true (default), only the frontier level (deepest rendered) MUST remain disclosed; all ancestor lists MUST be hidden by their child, even when space permits. The root-level header MUST carry a toggle to flip this behavior (flipping it clears every pin — see **pin-toggle**).
- **pin-toggle**: In `covered` and `cascading` styles, every rendered list's header except the ROOT's MUST carry a `«`/`»` toggle that pins or covers that list's PARENT (not the list itself), independent of `autoHide`, persisting across selections; the root list carries no `«`/`»` toggle — its header holds only the auto-hide toggle (see **autohide**). The frontier list's own cover toggle rides the detail pane's leading strip in `covered` style; in `cascading` style the frontier list has no cover toggle at all (the detail strip's immersion toggle takes its place). In `minimized` style, a separate manual pin toggle — present only when `manualCollapse` is true (default) — pins the list it appears on directly. A parent pin overrides `autoHide` for that parent: pinned-hidden (`true`) MUST keep it hidden; pinned-disclosed (`false`) MUST keep it disclosed unless width pressure forbids it. Flipping `autoHide` MUST clear every pin.
- **covered-peek**: In `covered` style, a list hidden by autoHide, a pin, or width pressure MUST remain rendered but visually covered by its child: clipped to a fixed peek width (40px) showing only its leading icon column, with the covering child casting a left drop-shadow so the stack reads as physically layered. No Back button is rendered in `covered` style.
- **render-detail**: Component MUST render the `children` into a detail pane that sits beside the list columns as the rightmost pane in wide mode, or as the only visible pane in narrow mode.
- **render-toolbar**: When `toolbar` is provided, component MUST render it in a full-width strip above the breadcrumb, collapsing the strip if the toolbar slot is empty.
- **min-detail-width**: When total width of list columns plus `minDetailWidth` exceeds the container, component MUST drill down (hide ancestor columns) to keep the detail pane at least `minDetailWidth` wide.
- **default-select**: When a level appears with `defaultSelectedId` and no selection (`selectedId == null`), component MUST call the level's `onSelect(defaultSelectedId, { replace: true })` once per appearance. An **appearance** is the combination of this level being rendered (at or above the frontier) together with its ancestors' current selections; it changes whenever an ancestor's selection changes, or when the level stops rendering and later starts rendering again. The default does not re-fire for the same appearance after a manual clear, and a level that appears already selected (a deep link) spends that appearance without firing.
- **guard-exit**: When `exitGuard` is provided (non-null), any of the following MUST show an unsaved-changes alert before proceeding, while the guard's `isDirty` is true: switching to a sibling at the deepest level, clicking a shallower row, navigating breadcrumb-up, or re-clicking the deepest selected row (deselect) — every change that would clear or replace the open leaf editor's content.
- **cascading-layout**: In cascading mode, only the root list spans full height; deeper lists open to the right of their parent, positioned just under the parent header, with height hugging their rows (capped at container bottom). The detail pane sits beside the root.
- **render-connectors**: When two or more levels are rendered in wide mode, component MUST draw a visual chain (selection connector) from each selected parent row to its selected child row, using an elbow path in the theme's selection accent colour from parent to child.
- **narrow-mode**: When `layoutMode` is "narrow", or when "auto" and the container is narrower than the wide-mode floor, or when the browser reports a phone user agent (checked after mount, via a user-agent pattern for iPhone/iPod or Android + Mobile), component MUST render one full-width pane at a time (the frontier list, or the detail once every level is selected), with a Back button — shown for every disclosure style — to navigate up the hierarchy by clearing the deepest selected level. The wide-mode floor is `minDetailWidth` plus a fixed strip (40px in `covered`/`cascading` style, 48px in `minimized` style), clamped to never go below 480px regardless of `minDetailWidth` — deliberately NOT `minDetailWidth` plus one full topic list's width, which would switch to narrow mode while the wide layout still had ancestor lists left to cover progressively.
- **render-trailing-crumbs**: When `trailingCrumbs` is provided, component MUST append each as a non-interactive crumb after the level crumbs in the breadcrumb trail.
- **hide-offscreen**: Lists that do not fit in the visible viewport (after considering autoHide, pins, width pressure, and disclosure style) MAY be rendered but hidden via `aria-hidden` and pointer-events-none.
- **hover-reveal**: In covered and cascading modes, a pointer ENTER on a covered list row MAY reveal every on-screen ancestor list above it for the duration of the pointer's presence in the menu stack, re-hiding when the pointer exits.

## Appearance

- **Rail layout**: Each list column is a vertical stack with a header (level title + toggles) and a scrollable item list below.
- **Header height**: 2.15rem (approximately 34px at 16px base font).
- **List item styling**: Rows inherit from the TopicRail ingredient (see adhsdk://recipes/topic-detail); no fixed height specified in this component.
- **Text styling**: List headers use monospace, 0.8rem (12.8px), muted color. Breadcrumb uses the same monospace + 0.75rem.
- **Border**: 1px solid, using the theme's border colour token.
- **Background**: Lists use the navigation-surface background colour; the detail pane uses the content-surface background colour.
- **Spacing**: Breadcrumb has 4px–16px padding, 12px gaps between crumbs. Rails have no padding outside the item list (scrollable area consumes container).
- **Selection connector**: Elbow path in the theme's selection accent colour, 2px stroke, drawn over the list area (pointer-events-none).
- **Toggle icons**: 16px icons — a panel-open/closed pictogram for the auto-hide toggle, and a chevrons-left/right pictogram for both the per-list pin toggle and, in cascading style, the detail-immersion toggle (same icon pair, two different controls).
- **Focus indicator**: 2px ring in the theme's selection accent colour at reduced opacity, on keyboard focus for breadcrumb crumbs and header toggles.

## States

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

## Accessibility

- **Role**: The root is a flex container wrapping a `nav` (breadcrumb) and multiple aside-like sections (rail columns). The `nav` element carries `aria-label="Breadcrumb"`.
- **Breadcrumb navigation**: Semantic nav + ol/li structure. Current crumb marked with `aria-current="page"`. Crumb buttons use `aria-label` or visible text; chevron separators marked `aria-hidden`.
- **Column identification**: Each list column carries an internal index marker used to locate the selected row's endpoint for connector paths; selection within each column is marked with `aria-current="true"` on the selected row element. Rail-internal roles, accessible names, and row-level keyboard navigation (arrow keys) are the TopicRail ingredient's concern — see adhsdk://recipes/topic-detail.
- **Header toggles**: AutoHide toggle has `aria-label`, `aria-pressed` showing toggle state. Pin toggles have descriptive `aria-label` ("Auto-hide parent lists: on/off", "Expand/collapse this list").
- **Offscreen columns**: Hidden columns marked `aria-hidden="true"` and `pointer-events-none`.
- **Back button (narrow mode)**: Labeled `aria-label="Back"`, showing a chevron-left icon + text.
- **Decorative elements**: Icons used as decoration (chevron-right in breadcrumb, icon-only toggles) marked `aria-hidden`.
- **Selection connectors**: SVG path overlay marked `aria-hidden` and `pointer-events-none`.
- **Minimum touch target**: Header toggles measure roughly 2.15rem (~34px) tall with small icon padding; breadcrumb crumbs are text-sized click targets. Neither meets the 44×44px touch-target guideline (see Compliance).
- **Keyboard navigation**: Breadcrumb crumbs, header toggles, and the Back button are native `<button>` elements, focusable and activatable via standard keyboard controls (Tab, Enter/Space). Row-level keyboard navigation is the TopicRail ingredient's concern — see adhsdk://recipes/topic-detail. Escape MAY close a revealed branch (not implemented in source; no explicit MUST).
- **Label clarity**: Breadcrumb uses visible text; toggles use `aria-label` + visible icon. Lists inherit labels from TopicRail.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hmd-001 | render-levels | `levels` with 2 items, level 0 has 3 items, level 1 has 2 items | Both levels render as columns with correct item counts. |
| hmd-002 | scope-by-selection | 3 levels; level 0 `selectedId="a"`, level 1 `selectedId=null`, level 2 `selectedId="c"` | Level 0 and level 1 render (level 1 is the frontier: all its items visible, none selected); level 2 does not render. |
| hmd-003 | show-breadcrumb | `showBreadcrumb=true`, `rootLabel="Root"`, level 0 selected | Breadcrumb shows "Root" + selected item label. |
| hmd-004 | navigate-breadcrumb | Breadcrumb crumb clicked for level 0 | `onClear()` called for levels 1+; level 0 selection unchanged. |
| hmd-005 | deselect-on-reclick | Row with `id="x"` already selected, row clicked again | `onClear()` called for that level. |
| hmd-006 | disclosure-styles | `disclosureStyle` set to each of "minimized", "covered", "cascading" | Each style renders lists with correct layout/hiding strategy. |
| hmd-007 | autohide | `autoHideTopics=true`, 3 levels rendered | Only frontier (level 2) visible; levels 0–1 hidden. Root header toggle exists. |
| hmd-008 | pin-toggle | `autoHideTopics=true`, level 0 pinned disclosed (`pins["level-0"]=false`) | Level 0 remains visible despite autoHide. |
| hmd-009 | pin-toggle | `disclosureStyle="minimized"`, `manualCollapse=true`, list header toggle clicked | List pin state flips; layout re-renders immediately. |
| hmd-010 | render-detail | `children` provided with text "Detail" | Text "Detail" appears in the rightmost pane, beside the list columns. |
| hmd-011 | render-toolbar | `toolbar` with a button | Button renders in strip above breadcrumb. |
| hmd-012 | min-detail-width | `minDetailWidth="28rem"`, window width 32rem, 2 levels at 10rem each | Detail pane shows at 28rem; level 0 hidden off-screen. |
| hmd-013 | default-select | Level 0 appears with `defaultSelectedId="x"` and `selectedId=null` | `onSelect("x", { replace: true })` called once. Subsequent renders do not re-fire. |
| hmd-014 | guard-exit | `exitGuard` with `isDirty=true`, breadcrumb crumb clicked | Unsaved-changes alert shown; navigation blocked until user confirms. |
| hmd-015 | cascading-layout | `disclosureStyle="cascading"`, 2 levels selected | Root list spans full height; level 1 opens to right of root, below root header. |
| hmd-016 | render-connectors | Wide mode, 2 levels, both with selections | Elbow path, in the selection accent colour, drawn from level 0 selected row to level 1 selected row. |
| hmd-017 | narrow-mode | `layoutMode="narrow"` or "auto" on phone, 2 levels | One full-width pane visible; Back button shows to switch panes. |
| hmd-018 | render-trailing-crumbs | `trailingCrumbs=[{label:"Leaf"}]` | "Leaf" appears after level crumbs, non-interactive. |
| hmd-019 | hover-reveal | `disclosureStyle="covered"`, pointer ENTER on covered list row | Ancestor lists reveal at full width for pointer duration. |
| hmd-020 | covered-peek | `disclosureStyle="covered"`, 2 levels, level 0 covered by width pressure | Level 0 renders clipped to a 40px peek (icon only); level 1 casts a left drop-shadow; no Back button appears. |

## Edge Cases

- **Empty levels array**: Component MUST render without error (no columns, only toolbar and breadcrumb if provided).
- **No selection at any level**: Component renders only level 0 (frontier is 0) with all items visible. Breadcrumb shows only root label if provided.
- **Selection gap**: If `levels[0].selectedId != null` but `levels[1].selectedId == null`, frontier is level 1 and only levels 0–1 render.
- **defaultSelectedId not in items**: If a level's `defaultSelectedId` names an item not in `items`, the default is not applied and no error is raised.
- **Async item updates**: If `items` changes after a default has fired, the default does not re-fire. A manual `onSelect` can re-apply the selection.
- **Width below minDetailWidth**: If container width is less than `minDetailWidth`, detail pane shows at container width (no horizontal scroll); ancestor columns remain hidden.
- **exitGuard isDirty flip during alert**: If `exitGuard.isDirty` becomes false while the alert is shown, the alert MUST still block the pending action (the guard check happens once, not re-checked while rendering).
- **Pin state on hidden list**: A pinned-disclosed list that is later hidden by width pressure MUST remain pinned (the toggle preserves the intent); when space recovers, the list is re-disclosed.
- **Pointer exit during reveal**: If pointer leaves the menu area while a branch is revealed, the reveal MUST close and the stack MUST re-settle to the configured disclosure style on the next render.
- **Multiple levels with same defaultSelectedId**: Each level applies its own default independently; sharing the same `defaultSelectedId` is valid and not a conflict.

## Configuration

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
| `items` | `TopicDetailItem[]` | — (required) | The rows for this level (rendered by the TopicRail ingredient — see adhsdk://recipes/topic-detail). |
| `selectedId` | `string \| null` | — (required) | This level's current selection. |
| `defaultSelectedId` | `string` | — | Item to select the moment this level appears with nothing chosen (see **default-select**). |
| `onSelect` | `(id: string, opts?: { replace?: boolean }) => void` | — (required) | Make `id` the selection at this level. |
| `onClear` | `() => void` | — (required) | Clear this level and everything below it. |

## Deep Linking

Not applicable: Deep linking is managed by the host via the `selectedId` values passed to each level. The component renders what the host supplies; URL routing is the host's responsibility.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `htd.back` | "Back" | Back button text and `aria-label`, shown in narrow mode (every disclosure style) and in `minimized` style's drill-down Back. |
| `htd.autoHide.on` | "Auto-hide parent topic lists: on — show them all" | `aria-label`/`title` on the root list's auto-hide toggle when auto-hide is on. |
| `htd.autoHide.off` | "Auto-hide parent topic lists: off — hide all but the last" | `aria-label`/`title` on the root list's auto-hide toggle when auto-hide is off. |
| `htd.cover.cover` | "Cover previous list (⌘/Ctrl-click: cover all)" | `aria-label`/`title` on a `covered`/`cascading` list's pin toggle when it covers its parent. |
| `htd.cover.uncover` | "Uncover previous list (⌘/Ctrl-click: uncover all)" | `aria-label`/`title` on the same toggle when it uncovers its parent. |
| `htd.immerse.hide` | "Hide the topic lists" | `aria-label`/`title` on the cascading style's detail-immersion toggle when the lists are shown. |
| `htd.immerse.show` | "Show the topic lists" | `aria-label`/`title` on the same toggle when the lists are immersed. |

All other user-facing strings (row labels, `rootLabel`, `trailingCrumbs`, `detailTitle`, `help`, item labels, `emptyLabel`, `newLabel`) are supplied by the host as props; the keys above are the ones the component generates itself and does not externalize.

## Accessibility Options

Responds to platform accessibility preferences as inherited by React/Web:

| Option | Behavior |
|--------|----------|
| Reduce Motion | No transition in this component is gated on `prefers-reduced-motion` — a deliberate decision, not a gap (see Design Decision 8). |
| Increase Contrast | Focus rings and borders use the applied theme's contrast tokens. Component does not override or adapt further. |
| Differentiate Without Color | Selection is marked with `aria-current` and a text-colour change, not colour alone. |

## Feature Flags

Not applicable: No feature flags are present in source. Behavior is controlled entirely by props.

## Analytics

Not applicable: Component does not emit analytics events. The host's `onSelect` and `onClear` callbacks are where selection tracking belongs.

## Privacy

Not applicable: Component does not collect, store, or transmit data. It renders provided props and calls host callbacks.

## Logging

Not applicable: Source includes an internal debug log (gated behind a dev-only switch) for development; no production logging is implemented.

## Platform Notes

- **React/Web**: Implemented in TypeScript + React with Tailwind CSS. Layout state (autoHide, pins, hover id, detail hold, cascade mode) persists in a module-scoped `Map` keyed by the root level's id, outside React state, so it survives the remount that a selection (route change) causes. Columns carry an internal index attribute and the selected row carries `aria-current="true"` so the selection-connector SVG paths can find their endpoints. Visual tokens are Tailwind custom-property color tokens (a selection-accent colour, a border colour, a nav-surface colour, and text/muted-text colours). Toggle icons are drawn from an icon library: a panel-open/closed pair for the auto-hide toggle, a chevrons-left/right pair for both the per-list pin toggle and the cascading style's detail-immersion toggle, and a chevron-left/right pair for Back and the breadcrumb separator. An internal debug log (behind a dev-only switch) traces surface-state transitions; no production logging is implemented. No framework-specific behavior beyond React hooks (useCallback, useState, useLayoutEffect, useReducer, useRef, useEffect).
- **Compose (Android)**: Compose equivalent would use a LazyRow for the level columns (or a single pane in narrow mode) with a Column for detail. A Modifier for selection state replaces `aria-current`. Manual state management (e.g. a ViewModel) replaces the persisted surface-state map. Three layout modes map to different Arrangement strategies (Row vs Column vs overlay). No direct equivalent to CSS transforms/transitions; use Compose animations and LazyRow scroll + visibility state.
- **UIKit / AppKit (iOS/macOS)**: UIKit port would use a UICollectionView for each level (horizontal scroll, one column per level) or a UINavigationController for narrow mode. Stacking and hiding use views' `isHidden` + `alpha` or removal from hierarchy. A manual state store replaces the persisted surface-state map. Selection state in UICollectionViewCell selection model. Accessibility via VoiceOver rotor + custom focus engine. AppKit is similar (NSView hierarchy, NSSplitView for columns).
- **SwiftUI**: SwiftUI would use a ScrollView per level, arranged in an HStack for wide mode or NavigationStack for narrow mode. State stored in an `@Observable` object placed in the environment (preferred over a singleton) to mirror the persisted surface state across the equivalent of a route change. Selection managed via @State and @Binding. Connectors drawn with Canvas or overlay Shape. Animations via .transition and .animation. Accessibility via accessibilityElement(children:) and custom accessibility labels.
- **WinUI 3**: WinUI 3 would render ListViews for each level in a horizontal ScrollView (or ContentPresenter for narrow mode). Disclosure styles map to Grid.ColumnDefinitions (collapse/cover/cascade). Selection state via attached properties or a ViewModel (replacing the persisted surface-state map). Visual connectors drawn with Path or Polyline shapes in a Canvas. Theme colors map to ThemeResource references. Keyboard navigation and focus management via Control.IsTabStop and FocusManager.

## Design Decisions

1. **Decision**: Surface state (autoHide, pins, hover reveal, detail hold) is stored outside per-render component state, keyed by the root level's id, so it survives the remount that a selection causes.
   **Rationale**: Storing this in ordinary component state would lose pins, hover reveal, and the held detail on every selection, because selecting a row is a route change that remounts the component subtree. Keying by the root level's id keeps the state stable across navigations within one surface; a page reload starts fresh, which is the correct seam for a deliberate fresh start.
   **Approved**: pending

2. **Decision**: Three disclosure styles — minimized (icon strips), covered (layered stacks), cascading (stepped nested-menu) — cover different screen sizes and interaction patterns.
   **Rationale**: Minimized suits phones with a Back button; covered maximizes list visibility without a Back button; cascading mimics native nested-menu hover-reveal behavior.
   **Approved**: pending

3. **Decision**: Per-list pins persist in the same outside-of-component surface state as autoHide, not in component state.
   **Rationale**: Selecting a row is a route change that remounts the component, so pins stored in component state would reset on every selection; storing them in the persisted surface state lets a pin survive across selections without fighting the user.
   **Approved**: pending

4. **Decision**: A level's `defaultSelectedId` fires as `onSelect(id, { replace: true })`.
   **Rationale**: Without `replace: true`, the Back gesture would land on the bare parent, which would immediately re-apply the default and bounce forward, costing two Back presses to escape instead of one.
   **Approved**: pending

5. **Decision**: The unsaved-changes guard runs on breadcrumb-up navigation (deselecting shallower levels), sibling swaps at the deepest selected level, breadcrumb-up clicks on a shallower row, and re-clicking a selected row (deselect) — any selection change that would clear or replace the open leaf editor.
   **Rationale**: Each of these can discard in-progress work in the detail pane, so each must be able to raise the unsaved-changes alert before proceeding.
   **Approved**: pending

6. **Decision**: Selection connectors are measured on demand (via a resize observer) and re-measured on a short loop (400ms default) while animations play, rather than computed on every render.
   **Rationale**: This avoids computing paths for connectors that are off-screen or not rendered, and keeps the selection chain in sync while the lists slide.
   **Approved**: pending

7. **Decision**: The frontier is the first level with no selection, or the last level if every level has a selection; only the frontier and the levels above it render.
   **Rationale**: This keeps the render cost and the layout math to exactly the levels the user can see or is choosing from.
   **Approved**: pending

8. **Decision**: No transition in this component is gated on the `prefers-reduced-motion` system preference.
   **Rationale**: Standing instruction from the component's owner to ignore that preference until it is lifted; it is not a claim that the preference doesn't matter, only that this component doesn't yet act on it.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on the source's native `<button>`/`aria-*`/`nav`+`ol`/`li` markup and 2.15rem toggle-header height (Accessibility); the hardcoded strings listed under Localization; and the physically `left`-positioned, `translateX`-based layout with no `dir`/RTL handling anywhere in the source (Internationalization). Colour contrast cannot be verified without the host's theme-token values, which live outside this component. `separation-of-concerns` is partial: the cascade's state machine and geometry are extracted into `cascade-rules` and dedicated hooks (`useCascadePointerAuthority`, `useContainerWidth`, `cascadeMemoryFor`), but the covering/width-pressure derivation inside `CascadingStack` is computed inline alongside its rendering rather than extracted further; `unit-test-coverage` passes on the combined exercise of `breadcrumbLeadingSeparator.test.tsx`, `cascadeInteraction.test.tsx`, `detailPaneMarker.test.tsx`, and `hmdvExitGuard.test.tsx`, which drive the component's breadcrumb, click wiring, crossfade marker, and unsaved-work guard directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only names and fixed the dangling hmd-019 citation; merged the pin and manual-collapse requirements into pin-toggle and gave the pin and detail-immersion toggles distinct icon-role descriptions; added the re-click case to guard-exit; fixed the frontier, detail-position, and cascading-direction contradictions; added a covered-peek requirement and test vector; defined narrow-mode Back scope and phone detection, and "once per appearance" for default-select; replaced Configuration and Localization "Not applicable" prose with real tables; reformatted Design Decisions into Decision/Rationale/Approved form and added the reduced-motion decision; built a real Compliance table and corrected the touch-target and reduced-motion claims; corrected the WinUI 3 and SwiftUI platform notes; moved React-specific names out of the platform-neutral sections into the React/Web platform note. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Corrected pin-toggle: root has no pin toggle (auto-hide only), each non-root list pins its PARENT, frontier toggle location per style (bucket-02_0); corrected narrow-mode wide-floor formula to minDetailWidth+strip clamped to 480px, not one-list+minDetailWidth (bucket-02_3). Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
