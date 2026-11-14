---
id: a8f66760-7db0-4a10-927e-856c2170dd4f
title: "ListHeader"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-07-10
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shared header above a list: title, filter text field, and right-aligned actions in the recessed ButtonBar strip."
platforms:
  - typescript
  - web
tags:
  - component
  - list
  - filter
  - toolbar
  - ui
depends-on:
  - 81db83fc-b30c-4ba3-b4d5-572dc8b4e335
  - 0f5b7167-b375-4f44-977b-566f720a453d
related:
  - 6acd3c5f-7bb5-4d6d-8c8d-141e1909cf73
  - c57b1aed-ef38-4803-b38a-2d7e0aeced5f
  - 0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8
references: []
approved-by: ""
approved-date: ""
---

# ListHeader

## Overview

The one home for the "header above a list" pattern in `@adh-sdk/ui`
(`blocks/list-header.tsx`): a single row hosting an optional left-aligned title,
a filter text field (search icon, controlled value), a flexible space, and
right-aligned actions (e.g. a `+ New` button, Delete) — all inside the same
recessed `ButtonBar` strip every toolbar on the platform uses, so list headers
look identical everywhere.

Consumers:

- `ListWithDetailsPane` renders it above its `DataTable`.
- A `HierarchicalTopicDetail` level hosts it via the level's `headerSlot` (a
  pinned, non-scrolling strip between the level's title header and its rows), so
  entity lists inside the stack get the same filter + actions header.

Related, NOT absorbed: `SearchFilterBar` is the stacked search-plus-filter-axes
region (`role="search"`, `<select>` rows under the field) for full search pages;
`ListHeader` is the one-row list toolbar. They share the `Input` primitive.

## Behavioral Requirements

- **one-row-layout**: The header MUST render title (when set), filter field
  (when set), a flexible space, then actions — in that order — in one
  `ButtonBar` row.
- **controlled-filter**: The filter field MUST be fully controlled
  (`search.value` / `search.onChange` fired per keystroke) — the header never
  owns filter state.
- **optional-parts**: Title, filter, and actions MUST each be independently
  omittable; an absent part reserves no space.
- **filter-width-cap**: The filter field MUST be capped at `max-w-xs` unless
  `search.grow` is true, in which case it MUST flex (`flex-1`) to share the
  row's free space equally with the always-present trailing flex spacer
  between the filter and `actions` — the field exceeds `max-w-xs`, but an
  equally-sized gap remains before `actions`, so it does not reach them.
- **accessible-names**: The bar MUST take an `ariaLabel`; the filter field's
  accessible name defaults to `"Filter"` and is overridable via `search.label`.
- **autofocus-remount**: When `search.autoFocus` is true, the filter field MUST
  receive focus every time the header is newly shown (attached to the DOM); it
  MUST NOT receive focus again merely because the header re-rendered while it
  remains shown (e.g. a keystroke updating `search.value`).
- **touch-target-minimum**: The filter field and any action buttons MUST meet
  the platform's minimum touch/click target size: 44×44pt on iOS, 48×48dp on
  Android, or 24×24 CSS px per WCAG 2.2 AA on web.

## Appearance

```
┌──────────────────────────────────────────────────┐
│ Title  [🔍 Filter…        ]        [+ New] [Del] │  ButtonBar strip
└──────────────────────────────────────────────────┘
```

- **Container**: The strip is the shared `ButtonBar` (recessed, `border-b`).
- **Title**: mono font, `text-xs`, `text-apt-text-muted`, non-shrinking left section.
- **Filter field**: shared `Input` component with `type="search"`, leading `Search`
  icon (`text-apt-text-muted` colored), constrained to `max-w-xs` unless `grow` is true
  (see **filter-width-cap**); when `grow` is true it is also `flex-1`, so it competes
  for free space equally with the flexible spacer below rather than filling it alone.
- **Flexible space**: A `flex-1` spacer always renders between the filter and actions,
  independent of `grow` — when `grow` is true, it and the (also `flex-1`) filter field
  split the row's free space evenly.
- **Actions**: Right-aligned content, no size constraint.
- **No raw hex colors**: All colors use `apt-*` design tokens.
- **No `!important` declarations**: Specificity is managed via composition.

## States

| State | Appearance change |
|---|---|
| Default | Filter placeholder (`"Filter…"` default) and no value |
| Filter focused | Shared Input focus ring applied |
| Filter with value | Text visible in field, `onChange` called per keystroke |
| No search supplied | Title (if set) and actions render; no search field at all |
| Search grows | Filter field exceeds `max-w-xs` and flexes (`flex-1`), splitting the row's free space evenly with the trailing spacer, when `grow={true}` |

## Accessibility

- **Toolbar role**: The strip inherits `ButtonBar`'s toolbar semantics via `ariaLabel`
  (required prop).
- **Search field**: Input is `type="search"` with an accessible name via `aria-label`
  (defaults to `"Filter"`, overridable via `search.label`).
- **Icon**: The Search icon is `aria-hidden="true"` (decorative, not focusable).
- **Keyboard navigation**: Users can tab to the filter field and type. `Escape`
  follows the browser's native `type="search"` behavior: in browsers that
  implement it, pressing `Escape` while the field has focus and a non-empty
  value clears the field and fires `onChange` with `""`. `Enter` has no
  component-specific handling — the component attaches no `onKeyDown`, so the
  browser default applies (form submission if the header is inside a `<form>`,
  otherwise no-op).
- **Touch target**: see **touch-target-minimum**.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | one-row-layout, controlled-filter | `{ title: "Sites", search: { value: "", onChange }, actions: <Button> }` | All three parts render, in the order title → filter → spacer → actions; typing in the field fires `onChange` with the new text |
| T2 | optional-parts | `{ title: "Sites", actions: <Button> }` (no `search`) | Title and actions render; no search field appears; flex space still fills |
| T3 | optional-parts, filter-width-cap | `{ search: { value: "", onChange } }` (no `title`, no `actions`) | Only the search field renders; it remains capped at `max-w-xs` — the absence of `title`/`actions` does not make it grow |
| T4 | optional-parts, filter-width-cap | `{ title: "Sites", search: { value: "", onChange, grow: true }, actions: <Button> }` | Filter field grows beyond `max-w-xs`, but the trailing spacer (also `flex-1`) claims an equal share of the free space, so the filter stops short of `actions` with an equally wide empty gap between them |
| T5 | autofocus-remount | `{ search: { value: "", onChange, autoFocus: true } }` remounted | Input receives focus; re-renders (keystroke) do NOT steal focus again |
| T6 | accessible-names | Render with `ariaLabel="Filter list"` and `search.label="Search"` | Toolbar reports accessible name "Filter list"; input reports "Search" |
| T7 | Long title (edge case) | `{ title: "A title long enough to exceed the available row width", search: { value: "", onChange }, actions: <Button> }` | Title renders at full width, never wrapping or truncating (no `truncate`/ellipsis styling); the filter field (`min-w-0 flex-1`, see **filter-width-cap**) shrinks first to make room, then actions |
| T8 | touch-target-minimum | Render with default classes | Filter input's computed height is `h-9` (36px) and action buttons use the shared `Button` component's default sizing — both meet the 24×24 CSS px web minimum |

## Edge Cases

- **Long title**: The title is `shrink-0` with no `truncate`/ellipsis styling, so
  it never wraps or truncates on its own — it always renders at its full natural
  width. When title, filter, and actions together exceed the available row
  width, the filter field (which flexes within `max-w-xs`, or grows per
  **filter-width-cap**) shrinks first, then actions, before the title is
  affected. See T7.
- **Empty search value and no actions**: When `search.value` is empty and no `actions`
  are supplied, only the title and filter render; the flex spacer has no visible effect.
- **No consumer state**: The header renders no filter state of its own (no "no results"
  message, no counts). Filtering, result display, and empty-state handling are
  entirely the consumer's responsibility.
- **Uncontrolled usage**: Calling `onChange` is required; a consumer that ignores
  `onChange` will see a frozen field (React's controlled-component pattern).

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `title` | `React.ReactNode` | — | Left-aligned name of the list (e.g., `"Sites"`). Optional. |
| `search` | `ListHeaderSearch` | — | The controlled filter field. Optional. See below. |
| `search.value` | `string` | — | The current filter text (required if `search` is supplied). |
| `search.onChange` | `(value: string) => void` | — | Called with the new text on every keystroke (required if `search` is supplied). |
| `search.label` | `string` | `"Filter"` | Accessible name for the input. |
| `search.placeholder` | `string` | `"Filter…"` | Placeholder text when empty. |
| `search.autoFocus` | `boolean` | `false` | Focus the field when its `<input>` attaches — re-fires on every remount, unlike the native attribute. Re-renders never steal focus (stable ref identity). |
| `search.grow` | `boolean` | `false` | Let the field flex (`flex-1`) past `max-w-xs` instead of capping there — it shares the row's free space equally with the always-present trailing spacer, so even with no `actions` it fills only about half of the free space, never all of it. See **filter-width-cap**. |
| `actions` | `React.ReactNode` | — | Right-aligned actions (e.g., `+ New` button, Delete). Optional. |
| `ariaLabel` | `string` | — | Accessible name for the toolbar (required). |
| `className` | `string` | — | Extra CSS classes applied to the `ButtonBar` container. |

## Deep Linking

Not applicable: ListHeader is a presentational toolbar component with no deep-linkable
content or state. Consumers (e.g., `ListWithDetailsPane`, `HierarchicalTopicDetail`)
handle deep linking at the list or page level.

## Localization

The component's only default strings — the `"Filter"` accessible-name label and
the `"Filter…"` placeholder — are hard-coded, user-visible English in the source
(`blocks/list-header.tsx`); they are not externalized into a localization
resource file. Consumers that need a localized experience MUST supply
`search.label` and `search.placeholder` with locale-appropriate strings (or
localize the two defaults upstream) — the component does not localize them on
its own.

## Accessibility Options

- **Reduce Motion**: The shared `Input` component applies an unconditional
  `transition-colors` CSS transition on its border/ring when focus changes.
  That transition MUST respect the `prefers-reduced-motion` media query
  (disabling or shortening it); the source does not yet gate it behind that
  query.
- **Increase Contrast**: The component uses `apt-text-muted` and `apt-text-default`
  tokens; if the active theme applies increased-contrast overrides to those tokens,
  the component inherits them automatically.
- **Differentiate Without Color**: The component MUST NOT rely solely on color to
  convey state. The focus ring (border or outline) and the filled vs. empty state
  of the input MUST be distinguishable without color.

## Feature Flags

Not applicable: ListHeader is a foundational UI component without feature-flag
control. Consumers that need to conditionally show or hide the header SHOULD manage
that at the consumer level.

## Analytics

Not applicable: ListHeader is a presentational toolbar. It emits no analytics events
of its own. Consumers that need to track filter changes or actions SHOULD attach
their own handlers to `onChange` and the action buttons' click events and emit
events at that level.

## Privacy

Not applicable: ListHeader does not collect, transmit, or store any user data.
Filter text remains in the caller's React state and is never persisted or sent
anywhere by the component itself.

## Logging

Not applicable: ListHeader is a presentational toolbar and emits no structured log
events. Consumers that need to log filter changes, debug re-renders, or monitor
performance SHOULD add their own logging at the consumer level.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/list-header.tsx`,
  exported from `@adh-sdk/ui/blocks`. Built on `ButtonBar` (toolbar
  container, `role="toolbar"`) and the shared `Input` (native `<input type="search">`);
  uses Lucide's `Search` icon (`aria-hidden`). Behavior (see **autofocus-remount**):
  the filter field is focused whenever the header is newly attached to the DOM,
  never merely because it re-rendered. The implementation achieves this with a
  `ref` callback (`focusOnAttach`) passed only when `search.autoFocus` is true —
  React calls a `ref` callback on attach/detach, not on every render, so a stable
  callback identity (via `useCallback`) avoids stealing focus on a same-element
  re-render (e.g. a keystroke).
- **SwiftUI**: A SwiftUI port would compose an `HStack` with `Text` for the title
  (monospace, small, secondary color), a `TextField` styled as a search field with a
  leading `Image(systemName: "magnifyingglass")` — or, when the header sits at the
  top of a `NavigationStack`, the native `.searchable(text:)` modifier — a `Spacer()`
  for flex fill, and an `HStack` for actions, all wrapped in a toolbar-like container
  (e.g., `.background(Color.secondary.opacity(0.1))` with a bottom border). Autofocus
  (see **autofocus-remount**) maps to `@FocusState` set in `.onAppear` (or
  `.defaultFocus` on the field), which fires each time the view appears — including
  on remount — but not on a mere re-render of an already-appeared view.
- **Compose**: A Compose port would use a `Row` (`Modifier.fillMaxWidth()`) with
  `Text` (mono style, small size, muted color) for the title, a `TextField` with a
  leading icon for the search field — or Material 3's `SearchBar` where the platform
  idiom calls for it — a `Spacer(Modifier.weight(1f))` for flex fill, and a `Row` for
  actions. Autofocus (see **autofocus-remount**) maps to `LaunchedEffect(Unit)`
  calling `FocusRequester.requestFocus()`: the effect runs once each time the
  composable enters composition (mirroring attach/remount); recomposition of an
  already-composed instance does not re-enter composition, so it does not re-run
  the effect.
- **AppKit / UIKit**: A native port would use `NSSearchField` (AppKit) or a
  `UISearchBar` / the `.searchable` modifier (UIKit) for the search field, laid out
  with `NSStackView` (AppKit) or `UIStackView` (UIKit) using content-hugging and
  compression-resistance priorities — title highest hugging (never stretches),
  search lowest hugging (shrinks/grows first), actions in between — inside a
  toolbar-style container such as an `NSVisualEffectView` (AppKit) or a bar
  background (UIKit). Autofocus (see **autofocus-remount**) maps to
  `becomeFirstResponder()` called in `viewDidAppear()`, which fires on each
  appearance including remount, but is skipped on mere layout passes of an
  already-visible view.
- **WinUI 3**: A WinUI 3 port would use a `Grid` with column widths `Auto` (title),
  `*` (search — the `AutoSuggestBox` given an explicit `MaxWidth` to mirror the
  `max-w-xs` cap, see **filter-width-cap**, with `MaxWidth` cleared and
  `HorizontalAlignment="Stretch"` set when the port's grow equivalent is true),
  `*` (spacer), and `Auto` (actions). The native search control is `AutoSuggestBox`
  with `QueryIcon="SymbolIcon Symbol=Find"` and `PlaceholderText` for the placeholder.
  Autofocus (see **autofocus-remount**) maps to calling `Focus(FocusState.Programmatic)`
  in the `Loaded` event, which fires each time the control loads (mirroring
  attach/remount) but not on a mere property-change re-render of an already-loaded
  control. The container applies `Background="{ThemeResource ControlFillColorDefaultBrush}"`
  with a bottom `Border BorderBrush="{ThemeResource DividerStrokeColorDefaultBrush}"`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/list-header.tsx` | unverified |

## Design Decisions

**Decision**: Build the list header on `ButtonBar` rather than re-rolling a new
toolbar chrome beside it.
**Rationale**: Every toolbar on the platform is the same recessed strip;
composing `ButtonBar` keeps that chrome in one place. `ListWithDetailsPane`'s
inline toolbar was extracted into this block to establish a single source of
truth for list headers.
**Approved**: pending

**Decision**: Leave `SearchFilterBar` intact as a separate component rather
than merging it with `ListHeader`.
**Rationale**: The stacked search-region (field over `<select>` axes) serves
full search pages; merging the two would force each consumer to configure
away the other's shape. They remain separate patterns.
**Approved**: pending

**Decision**: `autoFocus` re-fires on every remount rather than only once at
first mount.
**Rationale**: Unlike the native HTML `autoFocus` attribute (which fires once
at first mount), this accommodates navigation stacks where filters need to
re-focus as users return to a list level (e.g. a topic level that unmounts on
exit and remounts on re-entry).
**Approved**: pending

**Decision**: The header owns no filter state of its own.
**Rationale**: It is a fully controlled component; the consumer holds the
filter text and calls `onChange` on every keystroke. This keeps the header
stateless and composable.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because `list-header.tsx` is a pure layout
component — title, filter field, and `actions` slot — that owns no state of
its own; `search.value`/`onChange` and `actions` are supplied entirely by the
caller. `unit-test-coverage` passes: `listHeader.test.tsx` renders
`ListHeader` directly and covers the title/filter/actions layout, `autoFocus`,
and the action-only (no `search`) header.

The remaining `passed` statuses rest on what `list-header.tsx` shows directly: `ButtonBar`'s
`role="toolbar"`/`ariaLabel`, the input's `aria-label` and the icon's
`aria-hidden`, tab-key operability, the ref-callback focus mechanic, and
delegating all text entry to the native `<input>` (Unicode-safe by
construction). `partial`/`failed` rest on: `apt-text-muted`/`apt-text-default`
contrast depending on the active theme's token values, which this source
doesn't set; the input's `h-9` (36px) meeting the web (24×24 CSS px) minimum
with no native iOS/Android port yet to verify against; `Input`'s unconditional
`transition-colors` having no `prefers-reduced-motion` guard; fixed Tailwind
text sizes not verified against OS-level type scaling; `"Filter"`/`"Filter…"`
being hard-coded English with no resource-file externalization; and the
Search icon's `left-2.5` / input's `pl-8` being physical (not logical/`start`)
properties, which will misplace the icon under RTL even though the row's own
`flex` direction follows the document's writing mode.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | search.grow shares free space 50/50 with trailing spacer; filter-width-cap/T4/config fixed. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: reword autofocus-remount and touch-target as named, behavior-stated requirements; add filter-width-cap requirement; fix T3/T4 test vectors and add T7/T8; specify long-title truncation behavior; correct Platform Notes (native search controls, and the Compose/WinUI/AppKit/SwiftUI-specific errors); reformat Design Decisions to Decision/Rationale/Approved; rewrite Compliance as a table; correct Localization to acknowledge the user-visible defaults; strengthen Reduce Motion guidance; add depends-on for ButtonBar and Input; correct the 1.1.0 row's author. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Expand to full ingredient template (AI-assisted); correct domain to agenticdevelopercookbook; add all five Platform Notes bullets; complete Accessibility, Edge Cases, Conformance Test Vectors; mark not-applicable sections (Deep Linking, Localization, Feature Flags, Analytics, Privacy, Logging); add autofocus-remount requirement; add Configuration section with full prop definitions; set status to review. |
| 1.0.0 | 2026-07-10 | Mike Fullerton | Initial ingredient — extracted from ListWithDetailsPane's inline toolbar; HierarchicalTopicDetail `headerSlot` integration. |
