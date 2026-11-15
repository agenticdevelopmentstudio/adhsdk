---
id: 7f122a27-5b49-4f03-9439-1152249bc08f
title: "Focused Topic Detail (FTD) View"
type: recipe
version: 2.0.0
status: review
language: en
created: 2026-06-26
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A master/detail frame with a selector popup above the topic rail: focus one item to see its topics and pane, or choose All to see every item as a card."
platforms:
  - typescript
  - web
tags:
  - master-detail
  - view
  - layout
  - navigation
ingredients:
  - c21473ee-a075-4800-96db-ff3de0888515
  - 4d0e04ff-39eb-472c-93a0-8070f1b64a6a
  - 550f00f7-bfb2-415e-9b15-bd5dce015500
  - d04eef56-2dbf-4148-964b-c095f242227f
  - c99e2822-f5a9-4e84-8740-9341880bb82a
  - 8fa7aaae-df62-44ea-b10c-182f3094ed9f
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Focused Topic Detail (FTD) View

## Overview

`FocusedTopicDetail` is a block in `@adh-sdk/ui` that frames a collection of items of one kind. At any moment the reader is either focused on one item or looking at all of them.

- **Focused**: the rail lists that item's topics, the active topic is selected, and the pane shows a section header followed by whatever the consumer passes as `children`.
- **All** (nothing focused): the topics dim and cannot be chosen, the gold selection bar sits on the selector row, and the pane shows a header and a grid of cards, one per item. Clicking a card focuses that item.

A selector popup at the top of the rail switches between items and All, and can offer a New entry. The block composes four existing blocks and nothing else: `PopupMenu`, `TopicDetail`, `SectionHeader` and `ResourceCard`. It owns no state. The consumer holds `focusedId` and `activeTopicId` and passes the change callbacks. What goes inside the focused pane is the consumer's content.

The source does not implement renaming an item's identifier, deleting an item, an All-view filter, a list or card toggle, or remembering the last focus. A route that wants those builds them around this block.

## Ingredients

| Name | Ingredient | Role | Required | Configuration |
|------|--------|------|----------|---------------|
| TopicDetail | [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f) | The rail and pane frame; receives the topics, the selector as `railSlot`, and `panePadding={false}` | Yes | `items`, `selectedId`, `railSlot`, `railSlotActive`, `panePadding` |
| OptionMenu | [adhsdk.ingredient.ui.components.inputs.option-menu](cookbook:4d0e04ff-39eb-472c-93a0-8070f1b64a6a) | Related selector ingredient; the block's own selector is `PopupMenu`, a radio dropdown | No | Not used by the block's source |
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | A confirmation a consumer may raise from its pane content | No | Not used by the block's source |
| Disclosure | [adhsdk.ingredient.ui.components.layout.disclosure](cookbook:c99e2822-f5a9-4e84-8740-9341880bb82a) | A collapsible section a consumer may place in its pane content | No | Not used by the block's source |
| DataTable | [adhsdk.ingredient.ui.components.data.data-table](cookbook:d04eef56-2dbf-4148-964b-c095f242227f) | A table a consumer may place in its pane content | No | Not used by the block's source |
| ResizableSplit | [adhsdk.ingredient.ui.components.layout.resizable-split](cookbook:c21473ee-a075-4800-96db-ff3de0888515) | A split a consumer may place in its pane content | No | Not used by the block's source |

`PopupMenu`, `SectionHeader` and `ResourceCard` are sibling blocks in the same package and are not separate ingredients here.

## Integration Requirements

- **focused-state-from-known-id**: The block MUST treat the frame as focused only when `focusedId` is non-null and matches the `id` of an entry in `items`.
- **unknown-id-falls-back-to-all**: A `focusedId` that is null, or names no entry in `items` (for example the focused item was removed), MUST show the All view and MUST NOT show a half-focused frame.
- **topics-dim-when-unfocused**: While unfocused, the block MUST pass every topic to `TopicDetail` with `disabled` set, and while focused it MUST keep each topic's own `disabled` value.
- **selection-follows-focus**: The block MUST pass `activeTopicId` as the rail's `selectedId` only when focused, and null when unfocused.
- **selector-in-rail-slot**: The block MUST render a `PopupMenu` as the rail slot, fed the same `items`, with `focusedId` as its selection, `onFocus` as its select callback, and `popupAriaLabel` as its accessible name.
- **selector-bar-when-unfocused**: The block MUST set `railSlotActive` when unfocused so the gold selection bar sits on the selector row.
- **popup-new-entry-optional**: The selector SHOULD offer a New entry only when the consumer passes `onNew`, labelled by `newLabel`.
- **all-choice-clears-focus**: Choosing All in the selector MUST call `onFocus(null)`; choosing an item MUST call `onFocus` with its id.
- **pane-edge-to-edge**: The block MUST pass `panePadding={false}` so consumer content spans the full pane; the block's own header and card rows carry their own inset.
- **focused-header-derived**: When focused with no explicit `title`, `nameSuffix` set, and an active topic found in `topics`, the header MUST read "{topic label} ({item label} {nameSuffix})".
- **focused-header-override**: An explicit `title` MUST take precedence over the derived header.
- **focused-header-omitted**: When focused and neither an explicit `title` nor a derivable one exists, the block MUST omit the header row entirely.
- **focused-pane-remounts**: The focused content MUST be keyed by `focusedId`, so switching focus remounts `children` with fresh state.
- **all-header**: The All view MUST show a header titled `allTitle` (default "All items") with `allHelp`.
- **all-cards**: The All view MUST render one `ResourceCard` per item, with the item's `label` as title, `sublabel` as identifier, `description` and `meta`, and a click that calls `onFocus` with that item's id.
- **all-empty-copy**: When `items` is empty the All view MUST show `allEmptyLabel` (default "Nothing here yet.") in place of the grid.
- **headers-hoisted**: Both headers MUST be rendered with `paneTitle` so a host that hoists the pane title takes them over.
- **card-hover-gold**: The cards SHOULD hover with a gold border (`hover:border-apt-gold/60 hover:bg-apt-surface`) in place of the card default.

## Layout

```
 rail (TopicDetail)                  pane
+----------------------------+  +------------------------------------------+
| [selector popup]    (slot) |  | focused:  [section header]  (px-6 pt-4)  |
| [topic]                    |  |           [children]                     |
| [topic]                    |  |                                          |
| ...                        |  | all:      [All header]                   |
+----------------------------+  |           [card] [card] [card]           |
                                +------------------------------------------+
```

The card grid has one column by default, two from the `sm` breakpoint and three from `xl`, with a `gap-4` and `px-6` inset. The empty copy is a small muted paragraph under the header.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|-------|--------|----------|-----------|-----------|
| Focused item id | Consumer | Block (selector, header, pane) | two-way | `focusedId` in, `onFocus` out |
| Active topic id | Consumer | Block (rail selection, derived header) | two-way | `activeTopicId` in, `onTopicSelect` out |
| Items | Consumer | Selector entries, All cards | one-way | `items` prop |
| Topics | Consumer | Rail rows, derived header | one-way | `topics` prop |

The block holds no state of its own.

## Integration Test Vectors

Every vector is derived from the source and covered by `focusedTopicDetail.test.tsx`; the selector and the cards are also covered separately by the `PopupMenu` and `ResourceCard` tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ftd-001 | focused-state-from-known-id, selection-follows-focus | `focusedId` names an item, `activeTopicId="apps"` | the rail selects "apps"; the pane shows the focused header and `children` |
| ftd-002 | unknown-id-falls-back-to-all | `focusedId="gone"`, no such item | the All header and cards show; no `children` rendered |
| ftd-003 | topics-dim-when-unfocused, selector-bar-when-unfocused | `focusedId=null` | every topic is disabled, none is selected, the bar sits on the selector row |
| ftd-004 | focused-header-derived | topic "Applications", item "Temporal", `nameSuffix="Ecosystem"` | header reads "Applications (Temporal Ecosystem)" |
| ftd-005 | focused-header-override | `title="Custom"` plus `nameSuffix` | header reads "Custom" |
| ftd-006 | focused-header-omitted | focused, no `title`, no `nameSuffix` | no header row; `children` render |
| ftd-007 | all-cards | three items, unfocused | three cards; clicking the second calls `onFocus` with its id |
| ftd-008 | all-empty-copy | `items=[]`, unfocused | "Nothing here yet." shows, no grid |
| ftd-009 | focused-pane-remounts | focus changes from item A to item B | `children` unmount and mount again with fresh state |
| ftd-010 | all-choice-clears-focus | choose All in the selector | `onFocus(null)` |
| ftd-011 | popup-new-entry-optional | `onNew` omitted | the selector shows no New entry |

## Edge Cases

- **Stale focus**: a deleted item's id falls back to the All view (MUST), because the id no longer matches.
- **Empty items**: the selector still renders; the All view shows `allEmptyLabel`.
- **No active topic**: with focus but no matching topic, the derived header cannot form, so it is omitted unless `title` is given.
- **Id collision with the All row**: `PopupMenu` warns on the console when an item id collides with its All sentinel (`__all__`).
- **Selector without All**: not reachable from this block, which always leaves the All row on.
- **Disabled topic while focused**: a topic's own `disabled` is kept.
- **Error and offline states**: not applicable; the block does no I/O and surfaces no errors. Loading and failure states belong to the consumer's pane content.

## Platform Notes

- **SwiftUI**: Use a `NavigationSplitView` with a sidebar `List(selection:)` of topics and a `Picker` or `Menu` as its first row for focus; when nothing is focused, show a `LazyVGrid` of card views in the detail column. Key the focused detail by `.id(focusedId)` to remount it.
- **Compose**: A `Row` with a rail `Column` (a `DropdownMenu` selector over a `LazyColumn` of topics) and a pane; the pane switches between `children` and a `LazyVerticalGrid` of cards. Wrap the focused content in `key(focusedId)`.
- **React/Web**: The source is `packages/web/packages/ui/src/blocks/focused-topic-detail.tsx`. A `Fragment key={focusedId}` remounts pane content, and Tailwind `apt-*` tokens carry the colours.
- **AppKit / UIKit**: An `NSSplitViewController` with a source-list sidebar whose first row is an `NSPopUpButton`; the detail swaps between the consumer's view controller and an `NSCollectionView` of cards. On UIKit use `UISplitViewController` with a `UIMenu` button.
- **WinUI 3**: A `NavigationView` with `PaneDisplayMode="Left"`, a `DropDownButton` with `RadioMenuFlyoutItem` entries as the pane header, and a `Frame` whose content swaps between the consumer's page and an `ItemsRepeater` of card controls; recreate the focused page on a focus change so it starts with fresh state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/focused-topic-detail.tsx` | confirmed (2.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Compose existing blocks only and leave the focused pane's content to the consumer.
**Rationale**: The source comment says anything inside the focused detail pane is an implementation detail of the pane, not of the frame, so the frame stays reusable across item kinds.
**Approved**: pending

**Decision**: Fall back to the All view for an unknown `focusedId`.
**Rationale**: The source comment prefers it to an inconsistent half-focused frame, for example when the focused item was deleted.
**Approved**: pending

**Decision**: Key the focused content by `focusedId`.
**Rationale**: The source comment wants a focus switch to remount the pane so form and draft state start fresh.
**Approved**: pending

**Decision**: Make the pane edge-to-edge and give the block's own rows their inset.
**Rationale**: The source comment says consumer content such as a button bar then spans the full pane without negative-margin hacks.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |

`separation-of-concerns` passes because the block only arranges existing blocks and holds no state. `unit-test-coverage` passes because `packages/web/packages/ui/src/__tests__/focusedTopicDetail.test.tsx` covers all 11 integration test vectors (ftd-001 to ftd-011). `no-hardcoded-strings` fails because the defaults "All items" and "Nothing here yet." are plain literals. `platform-theming` passes because colours come from `apt-*` tokens. `keyboard-navigable` is partial: the cards are keyboard-operable through `ResourceCard`, but the block itself defines no key handling.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Verified against source: corrected behavior, states and platform notes |
| 1.2.5 | 2026-10-04 | Mike Fullerton | Matches its type's shape: required fields, title heading, and only the type's own sections. |
| 1.2.4 | 2026-10-04 | Mike Fullerton | Legacy recipe citations restored to the legacy recipes' own adhsdk://recipes/ domains; the adhsdk://recipes/ form named nothing. |
| 1.2.3 | 2026-10-04 | Mike Fullerton | Filled Reference Implementations and Compliance rows |
| 1.2.2 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-23 | Mike Fullerton | Lint pass: renamed the remaining verb-phrase requirements to subject-only names and updated every citation; split the Ecosystems/Teams instantiation values out of the general contract into a new Instantiations section; reworded Platform Notes and Design Decisions from migration-plan phrasing to a steady-state contract (Design Decisions reformatted to Decision/Rationale/Approved) and gave Platform Notes real per-platform APIs; fixed the `{basePath}` route templates that doubled a leading slash; clarified that `{id}`/`lastId` are the rdid and stated the post-rename deep-link fallback; replaced hardcoded `adh:`/hub-path/example values with `{{app_prefix}}`/`{{org_package}}` placeholders outside the instantiation appendix; promoted four requirements (rename-unknown-rdid-404, identifier-availability-check, warning-copy-article-agreement, explicit-all-precedence) out of Edge Cases/Design Decisions; added test vectors for every previously-uncovered requirement plus a delete-error vector; moved the concrete toggle ARIA rule into the accessibility requirement; explained the identifier regex's segment asymmetry and the always-lowercase rdid; standardized the shared-block naming (`FocusedTopicDetail` in `@adh-sdk/ui/blocks`, `DeleteEntitySection` in `@adh-sdk/adh-ui/blocks`); rebuilt Compliance as real linked catalog checks with a process note replacing the pre-commit-gate row. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Renamed every requirement to subject-only kebab-case, dropping the old prefix everywhere it is cited. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec (carries forward the v0.2 locked decisions A–D). |
