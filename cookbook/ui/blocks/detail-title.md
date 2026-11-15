---
id: fd3575ab-c4a4-480d-84ff-317a282bc359
title: "Detail Title"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Portal-based transport that hoists a detail pane's title into its stack's detail strip, with last-registered-wins and an inline fallback."
platforms:
  - typescript
  - web
tags:
  - block
  - navigation
  - master-detail
depends-on: []
related:
  - 5e401b96-7157-4c5b-a623-b90dde372231
  - 81db83fc-b30c-4ba3-b4d5-572dc8b4e335
  - 8ce108f2-b64b-4e01-8dbb-94ef3397b46a
  - aaebd90e-991f-4133-a12d-0783586eae5a
references: []
approved-by: ""
approved-date: ""
---

# Detail Title

## Overview

The Detail Title moves a detail pane's title out of the pane and into the strip that sits atop its stack's detail (the hierarchical topic/document/menu stacks). The stack owns a slot element in that strip; shared title drawers (a feature title, a button bar's title, a pane-title section header, a coming-soon pane) hand their title to the slot instead of drawing it inline. The module has two sides. The stack side is `useDetailTitleHost`, `DetailTitleProvider`, `DetailTitleSuppressed`, `detailStripTitle` and `useSelectedTopicLabel`. The pane side is `useDetailTitle`.

The transport is a portal, not a published value: a pane registers only its id, and its title node is portalled into the slot. This lets any node be a title, because a node is a new object every render and an effect keyed on one would re-publish forever. One title shows at a time; when several are registered the last to register wins and the others draw inline.

## Behavioral Requirements

- **host-registration-state**: `useDetailTitleHost` MUST return a stable `registrar` (with `register` and `unregister`), a `target` (the slot element and the active id), a `published` flag and a `slotRef` callback ref for the slot element.
- **register-idempotent**: Registering an id that is already registered MUST leave the registered ids unchanged.
- **unregister-idempotent**: Unregistering an id that is not registered MUST leave the registered ids unchanged.
- **register-appends**: Registering a new id MUST append it after all existing ids.
- **last-registered-wins**: The active id MUST be the most recently registered id still registered, and MUST be undefined when no id is registered.
- **published-flag**: `published` MUST be true while at least one id is registered, and false otherwise.
- **registrar-stable**: The `registrar` object MUST keep the same identity across renders, so a publisher's registration effect depends only on a stable value.
- **target-follows-slot-and-winner**: `target` MUST change identity only when the slot element or the active id changes.
- **provider-two-contexts**: `DetailTitleProvider` MUST expose the registrar and the target to descendants through two separate contexts, so a slot or winner change does not re-run publishers' registration effects.
- **suppress-withdraws-titles**: While `when` is true, `DetailTitleSuppressed` MUST give its descendants no registrar, which unregisters every title registered below it.
- **suppress-restores-titles**: When `when` returns to false, `DetailTitleSuppressed` MUST give its descendants the enclosing registrar again, so they register again.
- **suppress-never-remounts**: `DetailTitleSuppressed` MUST render its provider whatever `when` is, so toggling `when` never re-parents or remounts its children.
- **selected-label-live**: `useSelectedTopicLabel` MUST return the label of the selected row of the deepest selected level while that row is among the level's items.
- **selected-label-held**: When the selected row drops out of its level's items while it stays selected, `useSelectedTopicLabel` MUST return the label last seen for that exact depth and id.
- **selected-label-id-fallback**: When the selected row has never been seen among the level's items, `useSelectedTopicLabel` MUST return the selected id itself.
- **selected-label-none**: `useSelectedTopicLabel` MUST return undefined when no level has an unbroken selection from the root.
- **selected-label-keyed-on-depth**: `useSelectedTopicLabel` MUST key the held label on depth and id together, so the same id at a different depth is a different topic.
- **selected-label-no-blank-paint**: `useSelectedTopicLabel` MUST update the held label during render, not in an effect, so the strip never paints blank before the label is corrected.
- **strip-titled-rule**: `detailStripTitle` MUST report `titled` as true when a title is published or when `fallback` is neither undefined, null nor false.
- **strip-heading-role**: While `titled` is true, the strip's title cell MUST carry `role="heading"` and `aria-level="2"`.
- **strip-no-empty-heading**: While `titled` is false, the strip's title cell MUST carry no role and no aria-level.
- **strip-slot-element**: The strip's title cell MUST contain a slot element with `display: contents` that receives `slotRef`, so portalled nodes never share a parent with nodes React renders in the cell.
- **strip-fallback-when-unpublished**: The strip MUST draw `fallback` only while no title is published.
- **strip-published-wins**: While a title is published, the strip MUST NOT draw `fallback`.
- **strip-optout**: A `fallback` of null or false MUST mean the host opts out of a default title; with nothing published the strip is not titled.
- **strip-marker-attribute**: The strip's title cell MUST carry the `data-htd-detail-title` attribute.
- **pane-has-title**: `useDetailTitle` MUST treat a title of null, undefined or false as no title, and any other value as a title.
- **pane-registers-on-has**: `useDetailTitle` MUST register the pane's id while it has a title and a registrar exists, and unregister it when the title goes away or the pane unmounts.
- **pane-registration-not-keyed-on-title**: `useDetailTitle` MUST NOT re-run its registration when only the title node's identity changes.
- **pane-hoisted-rule**: `useDetailTitle` MUST report `hoisted` true only when the pane has a title, a registrar exists, the slot element exists and the pane's id is the active id.
- **pane-portal-when-hoisted**: When `hoisted`, `useDetailTitle` MUST return a portal rendering the title into the slot; otherwise `portal` MUST be null.
- **pane-inline-when-not-hoisted**: A pane MUST draw its title inline when `hoisted` is false: outside any stack, while another pane holds the strip, while suppressed, and during server rendering.
- **pane-server-inline**: Server rendering MUST keep the inline title, because the slot is a DOM element that does not exist on the server.
- **registration-layout-effect**: `useDetailTitle` MUST register in a layout effect, so the title moves into the strip before the first client paint.

## Appearance

- **Corner radius**: None; the title cell has no border or background.
- **Padding**: None set on the title cell; spacing comes from the strip that holds it.
- **Font**: monospace (`font-mono`), `text-[0.8rem]` (12.8px exact), letter-spacing `tracking-[0.02em]`; weight is not set and inherits the ambient weight.
- **Background**: None; the strip's own background shows through.
- **Foreground/Text**: `text-apt-text-muted` (semantic muted text token).
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: `min-w-0 flex-1`, so the cell fills the strip's remaining width and may shrink below its content width; overflow is cut with `truncate` (hidden overflow, ellipsis, no wrapping).

## States

| State | Appearance change |
|-------|------------------|
| Default (titled, published) | The title cell is a heading (level 2) holding the portalled title node; the fallback is not drawn |
| Titled by fallback | The title cell is a heading (level 2) holding the host's `fallback` content |
| Untitled | The title cell has no heading role and holds an empty slot; the strip is not titled |
| Pane not hoisted | The pane draws its own title inline and the strip does not show it |
| Suppressed | Titles below `DetailTitleSuppressed` are withdrawn; the strip does not name the hidden pane |

Pressed, Disabled, Focused and Loading: Not applicable: the title cell is inert, static text and has no interactive or asynchronous state in source.

## Accessibility

- **Role**: The title cell is exposed as a heading of level 2 while titled, using `role="heading"` with `aria-level="2"` on a span, so the slot element never changes type; it carries no role while untitled, so an empty strip announces no empty heading.
- **Label**: The heading's accessible name is the title text itself; no separate label prop exists.
- **Heading navigation**: Hoisting a title out of its pane MUST keep that pane's level 2 heading available to heading navigation; source records that losing it broke screen-reader heading navigation and an end-to-end role query for a level 2 heading.
- **State announcements**: Not applicable: the module announces nothing on its own; a changed title is a changed heading text.
- **Keyboard**: Not applicable: the title cell is not focusable and has no key handling in source.
- **Minimum tap target**: Not applicable: the title cell is not an interactive control.
- **title-contrast**: NEEDS REVIEW: Not implemented in source. The title uses the `text-apt-text-muted` token at 12.8px and the source does not state its contrast ratio against the strip background; a token-pair contrast measurement for light and dark themes would settle whether it meets WCAG 1.4.3 (4.5:1 for text this size).

## Conformance Test Vectors

The stack-frontier helper that `useSelectedTopicLabel` calls has tests beside it (`stack-frontier.test.ts`); vectors 12 to 14 derive from its `deepestSelectedLevel` assertions. `detailTitle.test.tsx` exercises the module through a real `HierarchicalTopicDetail` and `HierarchicalMenuDetail`; vectors 7, 8, 10, 11, 15 and 16 cite its assertions, and the rest derive from the source's documented behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| detail-title-001 | register-appends, last-registered-wins, published-flag | Host with no ids; register "a", then "b" | `published` is true and the active id is "b" |
| detail-title-002 | last-registered-wins | Ids "a" and "b" registered; unregister "b" | Active id is "a" |
| detail-title-003 | register-idempotent | Ids ["a"]; register "a" again | Ids remain ["a"]; no state change |
| detail-title-004 | unregister-idempotent, published-flag | No ids; unregister "x" | Ids remain empty; `published` is false; active id is undefined |
| detail-title-005 | suppress-withdraws-titles | A pane with a title below `DetailTitleSuppressed when={true}` | The pane's id is unregistered and `published` is false |
| detail-title-006 | suppress-restores-titles, suppress-never-remounts | Same pane; `when` goes true then false | The pane registers again and its children are the same mounted instances |
| detail-title-007 | strip-titled-rule, strip-heading-role (test: detailTitle "falls back to the stack's detailTitle prop when no pane claims the slot" and "is the pane's level-2 heading") | Nothing published; `fallback="Profile"` | `titled` is true; the cell has `role="heading"` and `aria-level="2"` and shows "Profile" |
| detail-title-008 | strip-no-empty-heading, strip-optout (test: detailTitle "honours a host's detailTitle={null} as an opt-out") | Nothing published; `fallback=null` | `titled` is false; the cell has no role and no aria-level |
| detail-title-009 | strip-published-wins, strip-fallback-when-unpublished | A pane publishes "Milestones"; `fallback="Profile"` | The slot holds "Milestones"; the fallback text is not drawn |
| detail-title-010 | pane-hoisted-rule, pane-inline-when-not-hoisted (test: detailTitle "keeps the title inline with no stack around it") | A pane with title "A" outside any stack (no registrar) | `hoisted` is false and `portal` is null; the pane draws "A" inline |
| detail-title-011 | pane-hoisted-rule, pane-portal-when-hoisted (test: detailTitle "gives the strip to the LAST registrant") | Panes "A" then "B" both titled in one stack | "B" has `hoisted` true and a portal into the slot; "A" has `hoisted` false and draws inline |
| detail-title-012 | selected-label-none (test: stack-frontier "is -1 for an empty stack") | `levels=[]` | `useSelectedTopicLabel` returns undefined |
| detail-title-013 | selected-label-none (test: stack-frontier "is -1 when the hole is the very first level") | `levels=[{selectedId:null,...},{selectedId:"b",...}]` | Returns undefined; the selection under the hole is unreachable |
| detail-title-014 | selected-label-live (test: stack-frontier "is the level above the first unselected one") | Levels selected "a", "b", then null; level 1 items include `{id:"b",label:"Beta"}` | Returns "Beta" |
| detail-title-015 | selected-label-held (test: detailTitle "keeps naming the open row after a filter drops it") | Selected "n1" with label "Note"; the level's items then drop "n1" | Returns "Note", not the id |
| detail-title-016 | selected-label-id-fallback (test: detailTitle "falls back to the selected id") | Selected "n1" never present in items (a deep link before its list loads) | Returns "n1" |
| detail-title-017 | selected-label-keyed-on-depth | "x" held at depth 0 as "One"; selection becomes "x" at depth 1, absent from items | Returns "x", not "One" |
| detail-title-018 | pane-has-title | Title `false`, `null` and `undefined` in turn | Each yields no registration and `hoisted` false |
| detail-title-019 | pane-registration-not-keyed-on-title | A titled pane re-renders with a new title node each render | `register` is not called again after the first registration |
| detail-title-020 | pane-server-inline | Server render of a titled pane inside a stack | HTML contains the inline title; `portal` is null |

## Edge Cases

- **Null and empty input**: A title of null, undefined or false MUST count as no title (`pane-has-title`); an empty string is not one of those values, so it counts as a title and registers. `fallback` null or false MUST opt out of a default title, while an empty string `fallback` makes the strip titled.
- **Boundary values**: With zero registered ids the active id MUST be undefined; with one it is that id. `useSelectedTopicLabel` MUST return undefined for an empty level list and the id itself when the id was never seen in the level's items.
- **Concurrent access**: Several panes MAY register at once; the last to register MUST win and the others MUST draw inline, so a second title is never lost. Registration uses functional state updates, so two registrations in one render batch both apply.
- **Slot not yet attached**: Until the slot element exists, `hoisted` MUST be false and the pane MUST draw inline; the layout effect moves the title once the slot is set.
- **Server rendering**: The slot is DOM, so on the server `hoisted` MUST be false and the inline title MUST stay in the HTML for crawlers and readers without JavaScript.
- **Hidden-but-mounted panes**: A pane the stack keeps mounted but hidden MUST be wrapped in `DetailTitleSuppressed`, so the strip does not name a pane that is not on screen.
- **Selected row filtered out**: When a search or filter drops the open row from its level, the strip title MUST hold the last label seen rather than blank, and the crumb falls back to the raw id.
- **Error states**: Not applicable: the module performs no network, file or other fallible I/O; its only failure path is a missing slot, covered above.
- **Offline or disconnected state**: Not applicable: the module is pure client rendering state with no network dependency.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `host` (`DetailTitleProvider`) | `DetailTitleHost` | required | The registration state and slot returned by `useDetailTitleHost` |
| `when` (`DetailTitleSuppressed`) | boolean | required | When true, withdraws every title registered below |
| `fallback` (`detailStripTitle`) | `ReactNode` | none | The host's own title; null or false opts out, and a published pane title overrides it |
| `title` (`useDetailTitle`) | `ReactNode` | none | The pane's title; null, undefined or false means no title |
| `levels` (`useSelectedTopicLabel`) | list of `{selectedId, items}` | required | The stack's levels, each with a selected id and its rows' ids and labels |

## Deep Linking

Not applicable: the module has no routes or URLs. It reads a selected id only to derive a label, and uses the id itself as the title when a deep link's list has not loaded yet.

## Localization

Not applicable: the module renders caller-supplied title nodes and strings and defines no strings of its own.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the title cell has no animation or transition in source |
| Increase Contrast | The cell has no contrast-mode branch of its own; it uses the fixed `text-apt-text-muted` token, so any increase-contrast adaptation comes from the theme that defines the token, not from this module. |
| Differentiate Without Color | Not applicable: the title carries no state shown by color alone |

## Feature Flags

Not applicable: the module has no flag checks in source.

## Analytics

Not applicable: the module emits no analytics events.

## Privacy

- **Data collected**: None.
- **Storage**: Registered ids and the held label live in React state in memory only.
- **Transmission**: None; nothing leaves the client.
- **Retention**: Discarded when the stack unmounts.

## Logging

Not applicable: the module writes no log output.

## Platform Notes

- **SwiftUI**: Start from a preference key (`PreferenceKey`) that panes write their title view into and the stack reads in a `.safeAreaInset` or toolbar strip; reduce values so the last writer wins. SwiftUI preferences carry a view, so no portal is needed, and the heading trait comes from `.accessibilityAddTraits(.isHeader)` (headings have no level number).
- **Compose**: Hold the registered ids in a `mutableStateListOf` provided through a `CompositionLocal`; the stack reads the last id and renders the winner's content in the strip, or hoists the content with a slot parameter. Mark the cell with `Modifier.semantics { heading() }`; Compose has no heading levels.
- **React/Web**: The source is `packages/web/packages/ui/src/blocks/detail-title.tsx`, with `deepestSelectedLevel` and `selectedTopicLabel` from `stack-frontier.ts` and `useIsomorphicLayoutEffect` from `hooks`. It uses `createPortal`, two contexts, `useId` and a layout effect; the heading is a span with `role="heading"` and `aria-level="2"`, styled with Tailwind utilities and `apt-*` tokens.
- **AppKit / UIKit**: Keep a registry on the stack's view controller (or a shared model) keyed by pane, and set the strip label (`NSTextField` or `UILabel`) from the last registrant; use `accessibilityRole = .staticText` with `isAccessibilityHeading` on UIKit and `setAccessibilityRole(.staticText)` plus the header trait where available. There is no portal; the strip owns the label and panes only publish text.
- **WinUI 3**: Put a `TextBlock` (`TextTrimming="CharacterEllipsis"`, `FontFamily` monospace, `FontSize` 12.8) in the stack's strip `Grid` cell with `Width="*"`. Panes publish through a shared view-model or a `WeakReferenceMessenger` message carrying an id and a `ContentPresenter` content; the strip binds to the last registrant. Set `AutomationProperties.HeadingLevel="Level2"` on the `TextBlock` so UI Automation exposes a heading, and use `{ThemeResource TextFillColorSecondaryBrush}` for the muted foreground.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/detail-title.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Transport the title by registering the publisher's id and portalling the node into a stack-owned slot, rather than publishing the title value.
**Rationale**: The earlier transport carried only a string, because a node is a new object every render and an effect keyed on one re-publishes forever. Registering the id lets any node be the title, and the stack provides the context itself, so no host plumbs anything.
**Approved**: pending

**Decision**: Split the transport into a registrar context and a target context.
**Rationale**: With one context, every slot or winner change would hand publishers a new value, re-run their registration effects, and re-append each one, reshuffling who wins on every render.
**Approved**: pending

**Decision**: When several panes register, the last to register wins and the others draw inline.
**Rationale**: This is the old registry's rule, and it means a second title is never lost.
**Approved**: pending

**Decision**: Expose the strip cell as `role="heading"` with `aria-level="2"` on a span, and only while titled.
**Rationale**: Hoisting the title out of an `h2` took the pane's accessible level 2 heading with it. A role keeps the slot element's type constant, and applying it only while titled keeps an empty strip from announcing an empty heading.
**Approved**: pending

**Decision**: Render `DetailTitleSuppressed`'s provider on every render and swap the registrar for null rather than unmounting the provider.
**Rationale**: A pane the stack keeps mounted but hidden must stay mounted; re-parenting would remount its children, and a null registrar simply unregisters their titles.
**Approved**: pending

**Decision**: Hold the last seen label for the selected row, derive it during render, and fall back to the id.
**Rationale**: A search or tag filter can drop the open row from its level while it stays open; the bare lookup then blanked the strip while the crumb showed the raw id. Updating state during render avoids painting the blank strip once before correcting it.
**Approved**: pending

**Decision**: Keep the title inline in server HTML and move it with a layout effect.
**Rationale**: The slot is DOM, so on the server the inline title stays for crawlers and readers without JavaScript, and the layout effect moves it before the first client paint.
**Approved**: pending

**Decision**: A host's `fallback` title is used only while no pane publishes, and null or false opts out.
**Rationale**: A pane's own title is the more specific name for what is on screen, while a host that owns the whole detail still names it through the prop.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |

The module separates the stack side from the pane side behind two contexts, which passes separation of concerns. `detailTitle.test.tsx` covers registration, last-registrant-wins, the heading role, the fallback and opt-out, unmount withdrawal and the held label through a real stack, and `stack-frontier.test.ts` covers `deepestSelectedLevel`; `detailTitleBlock.test.tsx` carries a test for every vector (detail-title-001 to 020), including the registrar's idempotency, the depth-keyed hold and server rendering, so unit-test coverage passes. The strip cell is a heading with a level, which passes semantic markup. The muted token's contrast is not measured in source, so contrast is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (detailTitleBlock.test.tsx, 20 of 20 vectors); unit-test-coverage now passed. |
