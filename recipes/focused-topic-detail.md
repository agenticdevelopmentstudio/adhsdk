---
id: c044fa91-11c6-46e9-b64a-bd890535acae
title: Focused Topic Detail
domain: adhsdk://recipes/focused-topic-detail
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Layout component composing a selectable popup menu and topic-detail rail
  into a two-pane focused/all-items view.
platforms:
- typescript
- web
tags:
- layout
- composition
depends-on:
- adhsdk://recipes/popup-menu
- adhsdk://recipes/resource-card
- adhsdk://recipes/section-header
- adhsdk://recipes/topic-detail
related: []
references: []
approved-by: ''
approved-date: ''
---

# Focused Topic Detail

## Overview

A two-pane layout composition that presents items via a popup menu and either focused detail content or an all-items card grid, depending on focus state. Used in hubs and resource dashboards where users drill from a list into topic-scoped details. Composes `PopupMenu`, `TopicDetail`, `SectionHeader`, and `ResourceCard` blocks.

## Behavioral Requirements

- **render-popup-menu**: Component MUST render a `PopupMenu` with items and selections in the rail slot of `TopicDetail`.
- **support-focus-selection**: Component MUST invoke `onFocus` callback when a popup menu item is selected, passing the item's `id`.
- **render-focused-title**: Component MUST render a `SectionHeader` with the focused title when an item is focused and a title is available, whether supplied explicitly (see **honor-explicit-title**) or derived (see **derive-focused-title**); if neither is available, no focused header renders.
- **render-focused-content**: Component MUST render the `children` prop in the detail pane when an item is focused.
- **render-all-items-header**: Component MUST render a `SectionHeader` with `allTitle` text in the detail pane when no item is focused.
- **render-card-grid**: Component MUST render items as a `ResourceCard` grid in the detail pane when no item is focused and the items array is not empty.
- **render-empty-state**: Component MUST render the `allEmptyLabel` text in a paragraph when no item is focused and the items array is empty.
- **disable-topics-unfocused**: Component MUST force `disabled: true` on every topic item in the `TopicDetail` when no item is focused.
- **enable-topics-focused**: Component MUST let each topic item's own `disabled` value stand, with no forced disabling, when an item is focused.
- **pass-topic-selection**: Component MUST invoke `onTopicSelect` callback when a topic item is selected, passing the item's `id`.
- **derive-focused-title**: Component MUST construct the focused title as `"{topicLabel} ({focusedItemLabel} {nameSuffix})"` when an item is focused, a topic is selected, and both `nameSuffix` and a matching topic exist; when any of the three is missing, no title is derived.
- **honor-explicit-title**: Component MUST use the `title` prop as the focused title when provided, overriding the derived title.
- **pane-state-resets-on-focus-change**: Detail pane content MUST reset (losing any transient state such as draft text) when the focused item changes.
- **fallback-stale-focus**: Component MUST show the all-items view and disable all topic items when `focusedId` does not match any item in the `items` array.
- **support-new-action**: Component MUST render a "New" entry in the popup menu when the `onNew` prop is provided.
- **set-new-label**: Component MUST display `newLabel` text on the "New" entry when provided.
- **display-card-title**: Component MUST render each item's `label` as the card title via `ResourceCard`'s `title` prop.
- **display-card-identifier**: Component MUST render each item's `sublabel` as the card identifier via `ResourceCard`'s `identifier` prop when present.
- **display-card-description**: Component MUST render each item's `description` as the card body text via `ResourceCard`'s `description` prop when present.
- **display-card-meta**: Component MUST render each item's `meta` as the card meta row via `ResourceCard`'s `meta` prop when present.
- **focus-card-onclick**: Component MUST invoke `onFocus` with the card's item `id` when the card is clicked.
- **gold-bar-tracks-focus-target**: The popup menu MUST render at full width in the rail slot regardless of focus state; what moves with focus is the gold left-bar selection marker, via `railSlotActive={!focused}` passed to `TopicDetail` — the marker sits on the rail slot's popup row when no item is focused, and on the active topic's row (`selectedId=activeTopicId`) when an item is focused.
- **unfocused-card-hover-accent**: Unfocused cards MUST show an accent-colored (gold) hover border and a surface-tinted hover background.
- **display-focused-help**: Component SHOULD render the `help` prop in the focused `SectionHeader` when provided and focused.
- **display-all-help**: Component SHOULD render the `allHelp` prop in the all-items `SectionHeader` when provided and unfocused.

## Appearance

- **Corner radius**: Inherited from child components (`PopupMenu`, `ResourceCard`, `SectionHeader`).
- **Padding**: Rail section header: 1.5rem horizontal, 1rem top / 0.5rem bottom. All-items section header: 1.5rem horizontal, 1rem top / 0.5rem bottom. Card grid: 1.5rem horizontal, 0.5rem top / 1.5rem bottom.
- **Font**: Inherited from `SectionHeader` and `ResourceCard` children.
- **Background**: No background applied to the layout itself; inherited from `TopicDetail`.
- **Foreground/Text**: All-empty label text uses the muted-text role at a small size (see Platform Notes: React/Web for the concrete token).
- **Border**: None on layout; inherited from child components.
- **Shadow**: None on layout; inherited from child components.
- **Min/Max size**: Card grid uses responsive columns: 1 column mobile, 2 columns at the `sm` breakpoint, 3 columns at the `xl` breakpoint. Grid gap: 1rem.
- **Card hover state**: See **unfocused-card-hover-accent** — unfocused cards use an accent (gold) hover border and a surface-tinted hover background (see Platform Notes: React/Web for the concrete tokens).

## States

| State | Appearance change |
|-------|-------------------|
| Focused | Popup menu shows selected item highlighted, still full-width in the rail slot; topic rail is enabled; detail pane shows focused content with derived or explicit title; the gold selection bar is on the active topic's row, not the rail slot (see **gold-bar-tracks-focus-target**). |
| Unfocused/All-items | Popup menu shows no selection, full-width in the rail slot; topic rail is disabled (all items grayed); detail pane shows card grid with all items (or empty state if no items); the gold selection bar is on the rail slot's popup row (see **gold-bar-tracks-focus-target**). |
| Empty items | When items array is empty and view is unfocused, card grid is hidden; empty state label is shown instead. |

## Accessibility

- **Role**: The layout is a composition; no single role applies. `PopupMenu` exposes its own role (button/menu). `ResourceCard` elements should be buttons or clickable containers with appropriate roles.
- **Label requirements**: PopupMenu MUST receive an `ariaLabel` prop for screen readers. SectionHeaders render text that serves as the pane label. Topic items in the rail should have descriptive labels via TopicDetail.
- **Announce state changes**: On a focus-state change, the component SHOULD move keyboard focus to the newly rendered `SectionHeader`, or announce it via a live region, so assistive technology reports the new title and content scope; an unfocused → focused transition SHOULD announce the newly focused item's label the same way.
- **Minimum tap target**: ResourceCard click targets SHOULD be at least 44×44pt (inherited from ResourceCard implementation). PopupMenu items MUST meet touch target standards.
- **Keyboard navigation**: PopupMenu MUST support keyboard navigation. ResourceCards MUST be keyboard-accessible (focusable, activatable via Enter/Space). Topic rail MUST support arrow keys for topic selection when focused.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| focused-topic-detail-001 | render-popup-menu, support-focus-selection | items=`[{id:'a',label:'Item A'}]`, focusedId=null, onFocus=callback | PopupMenu renders with items; clicking item 'a' invokes onFocus('a') |
| focused-topic-detail-002 | honor-explicit-title | focusedId='a', focusedItem found, title='Explicit Title' | SectionHeader renders 'Explicit Title' |
| focused-topic-detail-003 | derive-focused-title, render-focused-title | focusedId='a', focusedItem.label='Item A', activeTopicId='t1', topicLabel='Topic 1', nameSuffix='Suffix' | SectionHeader renders 'Topic 1 (Item A Suffix)' |
| focused-topic-detail-004 | fallback-stale-focus | focusedId='stale', items has no matching id | All-items view renders; card grid or empty state shown |
| focused-topic-detail-005 | render-all-items-header | focusedId=null, allTitle='All Items' | SectionHeader renders 'All Items' |
| focused-topic-detail-006 | render-card-grid | focusedId=null, items=`[{id:'a',label:'A',sublabel:'sub'},{id:'b',label:'B'}]` | Grid renders 2 ResourceCard components; both receive title, identifier props |
| focused-topic-detail-007 | render-empty-state | focusedId=null, items=[], allEmptyLabel='Nothing' | Paragraph renders 'Nothing' with muted text class |
| focused-topic-detail-008 | disable-topics-unfocused | focusedId=null, topics=`[{id:'t1'},{id:'t2'}]` | TopicDetail receives items with `disabled: true` for all |
| focused-topic-detail-009 | enable-topics-focused | focusedId='a', topics=`[{id:'t1',disabled:false},{id:'t2',disabled:true}]` | TopicDetail receives items with each topic's own `disabled` value unchanged |
| focused-topic-detail-010 | pane-state-resets-on-focus-change | focusedId changes from 'a' to 'b' | Pane content remounts; any transient state (e.g. draft text) is cleared |
| focused-topic-detail-011 | support-new-action | onNew=callback, newLabel='New Item' | PopupMenu renders 'New Item' entry; clicking invokes onNew() |
| focused-topic-detail-012 | focus-card-onclick | Unfocused; items=`[{id:'x'}]` | Clicking ResourceCard invokes onFocus('x') |
| focused-topic-detail-013 | display-card-description | Unfocused; items=`[{id:'a',description:'Desc text'}]` | ResourceCard receives description='Desc text' |
| focused-topic-detail-014 | display-card-meta | Unfocused; items=`[{id:'a',meta:<span>Meta</span>}]` | ResourceCard receives meta=<span>Meta</span> |
| focused-topic-detail-015 | display-focused-help | Focused, help='Help text' | SectionHeader receives help='Help text' |
| focused-topic-detail-016 | display-all-help | Unfocused, allHelp='All Help' | SectionHeader receives help='All Help' |
| focused-topic-detail-017 | render-focused-title | focusedId='a', title=undefined, nameSuffix and topicLabel present (derived path) | SectionHeader renders with the derived title; a focused header is present |
| focused-topic-detail-018 | pass-topic-selection | topics=`[{id:'t1'},{id:'t2'}]`, activeTopicId='t1', focused, onTopicSelect=callback | Clicking topic 't2' invokes onTopicSelect('t2') |
| focused-topic-detail-019 | set-new-label | onNew=callback, newLabel='Add Widget' | PopupMenu's New entry displays 'Add Widget' |
| focused-topic-detail-020 | display-card-identifier | Unfocused; items=`[{id:'a',label:'A',sublabel:'ID-123'}]` | ResourceCard receives identifier='ID-123' |
| focused-topic-detail-021 | gold-bar-tracks-focus-target | focusedId=null vs. focusedId='a' | TopicDetail receives railSlotActive=true when unfocused, railSlotActive=false when focused; popup menu width is unchanged in both cases |
| focused-topic-detail-022 | derive-focused-title | activeTopicId='missing' (no matching topic), no explicit title | topicLabel is undefined; no SectionHeader renders in the focused pane |
| focused-topic-detail-023 | derive-focused-title | nameSuffix=undefined, no explicit title, focusedItem and topicLabel present | No SectionHeader renders in the focused pane |

## Edge Cases

- **Null focusedId**: When `focusedId` is null, the component MUST show the all-items card view and disable all topic items. This is the default state.
- **Unknown/stale focusedId**: When `focusedId` does not match any item in the array (e.g., the focused item was deleted after the parent cached the id), the component MUST treat it as null and show the all-items view (see **fallback-stale-focus**). The fallback ensures the UI remains consistent and does not show a half-focused, broken state.
- **Empty items array**: When items.length === 0, the component MUST render the empty state label (`allEmptyLabel`) instead of an empty card grid (see **render-empty-state**). The card grid MUST NOT render if there are no items.
- **Missing topic**: When a topic matching `activeTopicId` does not exist in the topics array, the component MUST not derive a title (see **derive-focused-title**); `topicLabel` becomes undefined and, absent an explicit `title`, no focused header renders.
- **No nameSuffix**: When the `nameSuffix` prop is not provided, the component MUST not derive a title (see **derive-focused-title**); only an explicit `title` prop will show a focused header.
- **Rapid focus changes**: When focusedId changes multiple times in quick succession, each change resets the pane content (see **pane-state-resets-on-focus-change**), ensuring state is not carried over between focused items.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| items | FocusedTopicDetailItem[] | (required) | Array of focusable items; drives popup menu and all-items card grid. |
| focusedId | string \| null | (required) | The currently focused item id, or null for all-items view. |
| onFocus | (id: string \| null) => void | (required) | Callback fired when an item is selected (focused) or deselected (null). |
| topics | TopicDetailItem[] | (required) | Array of topic/detail items scoped to the focused item. |
| activeTopicId | string \| null | (required) | The currently selected topic id. |
| onTopicSelect | (id: string) => void | (required) | Callback fired when a topic is selected. |
| title | ReactNode | undefined | Explicit focused-view title; overrides derived title. |
| nameSuffix | string | undefined | Suffix appended to derived title: "{topic} ({item} {suffix})". |
| help | ReactNode | undefined | Help text rendered in the focused SectionHeader. |
| allTitle | string | "All items" | Title for the all-items card view. |
| allHelp | ReactNode | undefined | Help text rendered in the all-items SectionHeader. |
| allEmptyLabel | string | "Nothing here yet." | Text shown when items is empty and view is unfocused. |
| onNew | () => void | undefined | Optional callback for a "New" action in the popup menu. |
| newLabel | string | undefined (falls through to `PopupMenu`'s own default, `"New…"`) | Label for the "New" popup entry; this component forwards whatever it receives (including `undefined`) to `PopupMenu`, which supplies the default. |
| popupAriaLabel | string | (required) | Accessible label for the popup menu. |
| children | ReactNode | (required) | Content rendered in the detail pane when focused. |

## Deep Linking

Not applicable: Focused Topic Detail is a layout component that composes other blocks. Deep linking is handled by the consumer application based on the focused item id and active topic id.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| allTitle | "All items" | Label for the all-items card grid view section. |
| allEmptyLabel | "Nothing here yet." | Message shown when no items exist. |
| newLabel | "New…" (from `PopupMenu`) | Label for the optional "New" popup entry; this component has no default of its own and forwards its `newLabel` prop as-is to `PopupMenu`, which applies `"New…"` whenever the prop is left `undefined`. |

## Accessibility Options

Not applicable: Focused Topic Detail does not directly implement accessibility display options. Accessibility options are handled by child components (`PopupMenu`, `ResourceCard`, `TopicDetail`, `SectionHeader`) and the consumer's text/content.

## Feature Flags

Not applicable: This is a UI composition component with no feature-flag control. Feature control is delegated to consumers and child components.

## Analytics

Not applicable: Analytics instrumentation is delegated to consumers and child components. The component itself does not emit analytics events; the parent application defines what focus changes, topic selections, or card clicks mean in product terms.

## Privacy

Not applicable: Focused Topic Detail does not collect, store, or transmit data. It is a stateless presentation component that renders user-provided content.

## Logging

Not applicable: The component does not emit structured logs. Debug output, if needed, is the responsibility of the parent consumer or the child components.

## Platform Notes

- **React/Web**: Source is `packages/web/packages/ui/src/blocks/focused-topic-detail.tsx`. Tailwind CSS supplies padding, grid layout, and hover states; the unfocused card hover accent (**unfocused-card-hover-accent**) is `hover:border-apt-gold/60 hover:bg-apt-surface`, and the empty-state text (**render-empty-state**) uses `text-sm text-apt-text-muted`. Responsive grid via `sm:` and `xl:` breakpoints. **gold-bar-tracks-focus-target** is implemented by toggling the `railSlotActive` prop passed to `TopicDetail`; the popup's own trigger stays `w-full` in both states (`PopupMenu` renders no `className` override here), so only the gold left-bar marker's position changes. **pane-state-resets-on-focus-change** is implemented by wrapping the focused pane's children in a `Fragment` keyed by `focusedId`, forcing React to remount them on focus change. Composed from `PopupMenu`, `TopicDetail`, `SectionHeader`, `ResourceCard`. No platform-specific DOM elements; uses semantic divs and conditional rendering.
- **SwiftUI**: Use a `NavigationSplitView`. The sidebar hosts the topic rail as a `List`, disabled item-by-item via `.disabled()` driven by focus state. The item selector (the popup) is a `Menu` or `Picker` placed in the rail slot — not a sidebar row, since it is a single-selection control, not a browsable list — and keeps a consistent width regardless of focus state; only the selection indicator (the source's gold bar) moves between the selector row (unfocused) and the active sidebar row (focused) (**gold-bar-tracks-focus-target**). The detail side shows either the focused content or a `ScrollView` of cards. Apply the hover/press accent with a dynamic foreground or background modifier. Force **pane-state-resets-on-focus-change** with `.id(focusedId)` on the detail pane's content.
- **Compose**: Build with a `Row`: the left side is the topic rail as a `LazyColumn` (items carrying their own `enabled` state); the item selector is an `ExposedDropdownMenuBox` (not a `SelectionContainer`, which is a text-selection API) at a consistent width regardless of focus state; only the selection indicator moves between the selector and the active rail row (**gold-bar-tracks-focus-target**). The right side conditionally shows a `LazyVerticalGrid` of cards (unfocused) or the focused detail content. Apply the hover/press accent via `Modifier.clickable`'s interaction source. Force **pane-state-resets-on-focus-change** with `key(focusedId)` on the detail composable.
- **AppKit / UIKit**: Implement as a split view controller (`NSSplitViewController` on macOS, a custom container on iOS). The topic rail is the sidebar (table or outline view), disabled per row via a data-model flag. The item selector is an `NSPopUpButton` (AppKit) or a `UIButton` with a `UIMenu` (UIKit) — not the sidebar list. The detail pane hosts either the focused content or a collection view of cards, with tap/hover handling on the card cells. On macOS use `NSSplitViewItem` to manage pane visibility and sizing. Force **pane-state-resets-on-focus-change** by removing and re-adding the detail child view controller when `focusedId` changes.
- **WinUI 3**: Build as a `Grid` with two columns: the left column hosts the topic rail as an `ItemsControl`/`ListView` with `IsEnabled` bound per item. The item selector is a `ComboBox` or a `MenuFlyout` anchored to a button — not the rail's `ItemsControl` — at a consistent width regardless of focus state; only the selection indicator moves between the selector and the active rail row (**gold-bar-tracks-focus-target**). The right column conditionally shows the focused detail pane or a `GridView` of cards. Force **pane-state-resets-on-focus-change** by replacing `ContentControl.Content` with a new element when `focusedId` changes (no attached property needed). Apply the hover accent via pointer-entered/exited visual states on the card template.

## Design Decisions

- **Decision**: The focused header title is derived only when all three inputs (topic label, focused item, `nameSuffix`) are present.
  **Rationale**: Requiring all three avoids showing an incomplete or misleading header — e.g. a topic name alone with no indication of which item it belongs to. An explicit `title` prop always overrides the derived title, so consumers can customize specific cases without fighting the derivation.
  **Approved**: pending

- **Decision**: A `focusedId` that doesn't match any item in `items` (e.g. the focused item was deleted) falls back to the all-items view rather than rendering a half-focused state.
  **Rationale**: Silently returning to a known-good view keeps the UI consistent and usable instead of showing broken or stale focused content when the underlying data has moved on.
  **Approved**: pending

- **Decision**: Pane content is wrapped in a `Fragment` keyed by `focusedId` (see **pane-state-resets-on-focus-change**).
  **Rationale**: Keying by the focused id forces React to remount the pane's children on every focus switch, clearing form state, draft text, and other ephemeral pane state so it never leaks between focused items. This is a React-specific mechanism; other platforms only need to reproduce the observable reset behavior (see Platform Notes).
  **Approved**: pending

- **Decision**: The popup menu keeps a constant full width in the rail slot in both focus states; the gold left-bar selection marker moves between the rail slot's popup row (unfocused) and the active topic row (focused) instead (see **gold-bar-tracks-focus-target**).
  **Rationale**: A single shared marker communicates "what you're currently looking at" without a layout reflow — the popup never resizes, so switching focus doesn't shift the rail's geometry, only which row carries the accent.
  **Approved**: pending

- **Decision**: `TopicDetail` is given `panePadding={false}`, so the pane is edge-to-edge.
  **Rationale**: Child content (e.g. a ButtonBar) brings its own padding, eliminating the need for negative-margin hacks and keeping the CSS predictable and composable.
  **Approved**: pending

- **Decision**: The `sublabel` field is rendered as a mono-spaced identifier line on `ResourceCard`s, distinct from the label and description.
  **Rationale**: Sublabels are typically identifiers (e.g. a reverse-domain id); a mono-spaced treatment visually distinguishes them from prose text.
  **Approved**: pending

- **Decision**: Clicking a card always invokes `onFocus` with that card's id, including when the view is already focused on that same item.
  **Rationale**: `onFocus` MAY be called with the id of the already-focused item; the component does not dedupe or suppress the call, leaving reselection semantics (no-op vs. refresh) to the consumer.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The accessibility statuses rest on this file delegating roles, keyboard handling, tap targets, and contrast to `PopupMenu`, `ResourceCard`, `TopicDetail`, and `SectionHeader`, which this recipe's source cannot verify on its own; the internationalization statuses rest on every user-visible string (`allTitle`, `allEmptyLabel`, `newLabel`, `help`, `allHelp`) arriving as a prop or a documented default (see Localization), with layout built from flexible Tailwind spacing rather than fixed-width text containers. `separation-of-concerns` is `passed` because the file composes existing blocks (`PopupMenu`, `ResourceCard`, `TopicDetail`, `SectionHeader`) and derives only view state (`focusedItem`, `derivedTitle`) with no data access or business rules of its own; `unit-test-coverage` is `failed` because no test exercises `focused-topic-detail.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and reworded rail-slot/pane-remount requirements as observable behavior; added depends-on for the four composed ingredients; fixed the Compliance table's links, categories, and statuses; fixed test vector 016's expectation and vector 002's mapping and added vectors for previously uncovered requirements and edge cases; replaced hardcoded Tailwind tokens in Appearance with semantic references; corrected native-control mismatches and vague mechanisms in Platform Notes; reformatted Design Decisions to Decision/Rationale/Approved and removed unlinkable/unsupported claims; removed the unreachable "Card click while focused" edge case; clarified the focus-announcement mechanism, the enable-topics-focused wording, and the "New" entry's default-label documentation. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Renamed popup-full-width-unfocused to gold-bar-tracks-focus-target (popup is always full-width); fixed newLabel default. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
