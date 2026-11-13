---
id: 5a028319-034c-4852-a1ee-01247a747183
title: "EditorSection"
type: recipe
version: 1.2.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Master/detail editor shell — a pure assembly of the editing ButtonBar, the collapsible topic rail with per-row warn badges, and the shared EmptyState."
platforms:
  - typescript
  - web
tags:
  - master-detail
  - editor
  - layout
  - toolbar
ingredients:
  - 81db83fc-b30c-4ba3-b4d5-572dc8b4e335
  - 8fa7aaae-df62-44ea-b10c-182f3094ed9f
  - e86eb195-1ec2-4b12-8a24-79f8c03f65ce
depends-on: []
related:
  - 6acd3c5f-7bb5-4d6d-8c8d-141e1909cf73
references: []
approved-by: ""
approved-date: ""
---

# EditorSection

## Overview

`EditorSection` in `@adh-sdk/ui/blocks/editor-section` is the platform's
standard master/detail **editor shell**: a records rail on the left, an editing
detail pane on the right, and a fixed editing toolbar across the top. It is a
**pure assembly** — it owns no visual grammar of its own. It stacks three shared
blocks:

1. a `ButtonBar` (the recessed editing strip) carrying a gold mono title on the
   left and the standard **New / Delete / Cancel / Save** action preset on the
   right;
2. a `TopicDetail` two-pane primitive whose collapsible rail lists the records
   (each row may show a `⚠` warn badge), and
3. the shared `EmptyState` placeholder, shown in the detail pane whenever nothing
   is selected.

The consumer owns all state — the record list, the current selection, the draft
and its `dirty` flag, the `busy` (saving) flag, and every mutation callback.
`EditorSection` maps that state onto the three parts and computes the derived
"editing" condition (a selection exists) and the derived Save/Delete enablement.
`children` is the record's editor form, rendered in the pane only while editing.

It is the base editor shell behind hub/admin topics that manage a list of records
(sites, integrations, personas, …) and is reusable platform-wide.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| ButtonBar | [adhsdk.ingredient.ui.blocks.button-bar](cookbook:81db83fc-b30c-4ba3-b4d5-572dc8b4e335) | The fixed editing toolbar: gold mono title (`leading`) + the New/Delete/Cancel/Save preset | yes | `leading` = title + `titleBadge`; `actions` = `{ onCreate, createLabel, onCancel, canCancel, onSave, canSave, saving, onDelete, canDelete }`; `showDelete` = `!!onDelete` |
| TopicDetail | [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f) | The two-pane rail\|pane primitive: collapsible records rail + detail pane | yes | `items` (mapped from `EditorSectionItem[]`), `selectedId`, `onSelect`, `emptyLabel` = `emptyList`, `railSlot` = `listHeader`, `railWidth`, `panePadding={false}` |
| EmptyState | [adhsdk.ingredient.ui.components.display.empty-state](cookbook:e86eb195-1ec2-4b12-8a24-79f8c03f65ce) | The "nothing selected" placeholder rendered in the pane when not editing | yes | `title` = `emptyDetail`; fixed standard detail-pane inset (literal classes: see the React/Web platform note) |

Composed shared primitives without their own recipe domains: `Badge`
(`variant="accent"`) for the `⚠ N` count badge on warned rows.

## Integration Requirements

- **render-title-in-toolbar**: The EditorSection MUST render `title` (and the
  optional `titleBadge` accessory) as the leading content of the `ButtonBar`, in
  the gold mono title treatment.
- **derive-editing-from-selection**: The EditorSection MUST treat a non-null
  `selectedId` as "editing", and a null `selectedId` as "nothing selected".
- **show-detail-while-editing**: The EditorSection MUST render `children` in
  the detail pane while editing, and MUST render the `EmptyState` (titled
  `emptyDetail`) in the pane while nothing is selected.
- **gate-save-on-dirty-selection**: The EditorSection MUST enable Save only
  when editing AND `dirty` is true; otherwise Save MUST be disabled.
- **gate-cancel-on-editing**: The EditorSection MUST enable Cancel only while
  editing.
- **default-can-delete-to-editing**: The EditorSection MUST default the Delete
  enablement to "a record is selected" (`canDelete ?? editing`), and MUST honor an
  explicit `canDelete={false}` so Delete is not offered on an unsaved/new draft.
- **disable-delete-while-busy**: The EditorSection MUST disable Delete while
  `busy` is true.
- **disable-save-while-busy**: The EditorSection MUST disable Save while `busy`
  is true, regardless of `dirty`, and MUST render its label as "Saving…" for the
  duration.
- **disable-cancel-while-busy**: The EditorSection MUST disable Cancel while
  `busy` is true, regardless of editing.
- **keep-new-enabled-while-busy**: The EditorSection MUST NOT disable New while
  `busy` is true; New stays clickable so a second record can be started while
  the first is saving.
- **omit-delete-when-no-handler**: The EditorSection MUST hide the Delete
  button (`showDelete={false}`) when no `onDelete` handler is supplied.
- **render-warn-badge-per-row**: For a record with `warn` true, the
  EditorSection MUST render a trailing warning on its rail row — a `⚠ N` accent
  `Badge` when `warnCount` is set, otherwise a bare `⚠` — carrying `warnTitle` as
  its `aria-label` (and `title`); because that badge/span sits inside the rail
  row's own button, the `aria-label` composes into the row's accessible name
  alongside the visible label. A record with `warn` falsy MUST render no
  trailing warning.
- **surface-mutation-error**: When `error` is set, the EditorSection MUST
  surface it as a red line directly beneath the toolbar; when `error` is absent it
  MUST render no error line.
- **collapse-list-header-when-collapsed**: The EditorSection MUST place
  `listHeader` in the rail's leading slot and MUST hide it while the rail is
  collapsed.
- **default-empty-list-label**: The EditorSection MUST render `emptyList` as the
  rail's empty-state label when `items` is empty, defaulting to the hardcoded
  English literal `"Nothing here yet."` when `emptyList` is omitted.

## Layout

```
┌ ButtonBar (role=toolbar) ───────────────────────────────────────────────┐
│ ⬤ title  [titleBadge]      + New │ 🗑 Delete … ✕ Cancel   ✓ Save          │
├──────────────────────────────────────────────────────────────────────────┤
│ error (red line, only when `error` set)                                   │
├──────────────┬───────────────────────────────────────────────────────────┤
│ rail (TopicDetail, collapsible)  │  detail pane                           │
│  [listHeader]                    │                                        │
│  ▸ record label       ⚠         │   editing → children (record form)     │
│    sublabel                      │                                        │
│  ▸ record label       ⚠ 5       │   not editing → EmptyState(emptyDetail) │
│  ▸ record label                  │                                        │
│  (empty → emptyList)             │                                        │
└──────────────┴───────────────────────────────────────────────────────────┘
```

- Root is a full-height column that fills its container edge-to-edge (rail/pane
  stretch to it); give the parent a height. (Literal classes: see the React/Web
  platform note.)
- Toolbar: the `ButtonBar` recessed strip; title uses the small monospace gold
  title treatment, with the optional `titleBadge` beside it. (Literal classes:
  see the React/Web platform note.)
- Error line: a non-shrinking bordered strip in small monospace red text, only
  present when `error` is set. (Literal classes: see the React/Web platform
  note.)
- Rail + pane come from `TopicDetail` with `panePadding={false}` (each row/pane
  supplies its own inset); rail width defaults to the standard rail and widens via
  `railWidth` for long identifier rows.
- The pane's `EmptyState` uses a fixed standard inset (a small margin plus a
  minimum height) rather than filling the pane exactly. (Literal classes: see
  the React/Web platform note.)
- No raw hex; no `!important` (all color via `apt-*` tokens).

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `items` (`EditorSectionItem[]`) | Caller | TopicDetail rail (mapped to `TopicDetailItem[]`) | Down | Prop |
| `selectedId` (`string \| null`) | Caller | TopicDetail selection + editing/EmptyState choice + can* flags | Down | Prop |
| `dirty` | Caller | ButtonBar `canSave` | Down | Prop |
| `busy` | Caller | ButtonBar `saving` + Delete disablement | Down | Prop |
| `canDelete` | Caller (or derived from `selectedId`) | ButtonBar Delete enablement | Down | Prop, default `?? editing` |
| `error` | Caller | Error line under the toolbar | Down | Prop |
| selected id on row click | TopicDetail rail | Caller `onSelect(id)` | Up | Callback |
| New / Delete / Cancel / Save intents | ButtonBar | Caller `onNew` / `onDelete` / `onCancel` / `onSave` | Up | Callbacks |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | derive-editing-from-selection, show-detail-while-editing | `selectedId = null` | Pane shows the `EmptyState` titled `emptyDetail`; `children` not rendered |
| T2 | show-detail-while-editing | `selectedId = "r1"` | Pane renders `children` (the record form); no `EmptyState` |
| T3 | render-title-in-toolbar | `title="Sites"`, `titleBadge=<Badge/>` | Toolbar leading shows the gold mono title with the badge beside it |
| T4 | gate-save-on-dirty-selection | editing, `dirty=false` | Save disabled |
| T5 | gate-save-on-dirty-selection | editing, `dirty=true` | Save enabled (gold) |
| T6 | gate-cancel-on-editing | `selectedId=null` | Cancel disabled |
| T7 | default-can-delete-to-editing | editing, `canDelete` unset | Delete enabled |
| T8 | default-can-delete-to-editing | editing, `canDelete={false}` (new draft) | Delete disabled |
| T9 | disable-delete-while-busy, disable-save-while-busy, disable-cancel-while-busy, keep-new-enabled-while-busy | editing, `busy=true` | Delete disabled; Cancel disabled; Save disabled and shows "Saving…"; New remains enabled |
| T10 | omit-delete-when-no-handler | `onDelete` omitted | No Delete button rendered |
| T11 | render-warn-badge-per-row | item `{ warn:true, warnCount:5, warnTitle }` | Row trailing shows a `⚠ 5` accent Badge with `warnTitle` |
| T12 | render-warn-badge-per-row | item `{ warn:true }` (no count) | Row trailing shows a bare `⚠`; a non-warned row shows nothing |
| T13 | surface-mutation-error | `error="Save failed"` | Red error line renders under the toolbar; absent when `error` unset |
| T14 | collapse-list-header-when-collapsed | `listHeader` set, rail collapsed | `listHeader` hidden while collapsed, shown while expanded |
| T15 | default-empty-list-label | `items=[]`, `emptyList` omitted | Rail shows "Nothing here yet." (hardcoded default) |
| T16 | render-warn-badge-per-row | item `{ warn:true, warnCount:5, warnTitle:"5 project sites not yet connected" }` | The rail row's accessible name (its button content) includes `warnTitle`, contributed by the Badge's `aria-label` after the row label |

## Edge Cases

- Nothing selected (`selectedId === null`): the pane shows `EmptyState`, Cancel and
  Save are disabled, and Delete defaults to disabled (nothing to delete).
- New/unsaved draft: the consumer passes `canDelete={false}` so Delete is not
  offered for a row that isn't persisted yet, even though a draft is being edited.
- Empty record list: the rail shows `emptyList` (falling back to the hardcoded
  English literal "Nothing here yet." when omitted — see
  **default-empty-list-label**; this default is not localized).
- `busy` (saving) in flight: Save renders "Saving…" and is disabled, Cancel is
  disabled, and Delete is disabled, so a record can't be canceled out of or
  deleted mid-save; New remains enabled so a second record can be started (see
  **disable-save-while-busy**, **disable-cancel-while-busy**,
  **disable-delete-while-busy**, **keep-new-enabled-while-busy**).
- A row without `warn` renders no trailing accessory; a row with `warn` but no
  `warnCount` renders a bare `⚠` rather than a count badge.
- Rows whose labels are long identifiers (URLs): widen the rail via `railWidth`.
- The rail is always collapsible (a core `TopicDetail` behavior); collapsing hides
  the `listHeader` (see **collapse-list-header-when-collapsed**) and each row's
  warn badge/label, leaving the icon strip — that collapse-time hiding is
  `TopicDetail`'s own behavior (`support-trailing-accessory`,
  `hide-label-when-collapsed`; see
  behavioral-requirements ([adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f))), not
  something EditorSection adds.

## Platform Notes

- **SwiftUI**: A master/detail editor is a `NavigationSplitView` on every platform, including iPhone — its own compact-width collapse (sidebar to stack) already gives the rail/pane behavior `TopicDetail` needs, so no separate `NavigationStack` + `.sheet` branch is required. The sidebar is the records `List` with a `selection` binding (state-driven, mirrors `selectedId`); rows carry a `.badge(n)` modifier (or a trailing `Label` with an SF Symbol such as `exclamationmark.triangle.fill` for the countless case) for the warn indicator — `Badge(count)` and `FontIcon` are not SwiftUI APIs. The toolbar uses `.toolbar` with `.principal` placement for the title and `.toolbar` items (not `.confirmationDialog`, which is for destructive confirmation prompts, not the primary action row) for New/Delete/Cancel/Save, giving Delete `role: .destructive`. The detail column conditionally renders the form (editing) or an `EmptyState`-equivalent view (nothing selected).

- **Compose**: Root is a `Column` containing a `Row` for the toolbar (Material3 `TopAppBar` or a custom `Row` with Material3 `Button`s), an optional error `Text` (red foreground, small padding), and a horizontal `Row` splitting a records rail and the detail pane. The rail collapses the way `TopicDetail`'s own Compose note describes — an animated-width `NavigationRail` (or a `LazyColumn` whose column width animates between full and icon-only) — rather than a fixed-width column. Selection state (`selectedId`) drives rail selection and pane visibility. Warn badges render inline in the row's trailing slot as `Badge` composables or overlay `Icon`s tinted with the warning color. Plain values flow downward as parameters (never `MutableState` props, which would let a child mutate the parent's state directly); mutations flow upward via lambda callbacks, per Compose's state-hoisting pattern.

- **React/Web (TypeScript)**: Block at `packages/web/packages/ui/src/blocks/editor-section.tsx`, exported via `@adh-sdk/ui/blocks`. Assembles `ButtonBar` (toolbar), `TopicDetail` (records rail + detail pane), `EmptyState`, and `Badge` from `@adh-sdk/ui/components`. Responsive collapsing (rail to icon strip) and mobile toolbar wrapping (375/768/1440px) are inherited from TopicDetail and ButtonBar; verify with Playwright in ui-showcase. Demo at ui-showcase Topic editor-section; regenerate sources.generated.ts via gen-sources.py after source changes. Literal Tailwind: root `flex min-h-0 flex-1 flex-col`; toolbar title `font-mono text-[13px] text-apt-gold`; error line `shrink-0 border-b border-apt-border px-3.5 py-1.5 font-mono text-xs text-apt-red`; the pane's `EmptyState` inset `m-3.5 min-h-[200px] flex-1`.

- **AppKit / UIKit**: Start with `NSSplitViewController` (macOS) or `UISplitViewController` (iOS). Toolbar is `NSToolbar` (macOS) with an `NSToolbarItem` holding an `NSTextField` label for the title plus button items, or `UIToolbar` (iOS) with `UIBarButtonItem`s (New, Delete, Cancel, Save). Records rail is `NSTableView`/`NSOutlineView` (macOS) or a `UITableViewController` (iOS) with selection bindings driving pane visibility. Detail pane is a conditional container: editing state shows the form, nothing-selected state shows `EmptyState`. Warn badges are overlay `NSImageView`/`UIImageView` icons (⚠ glyph) or cell background tints. All state and callbacks flow through the view controller.

- **WinUI 3**: Root `Grid` with `RowDefinitions` for toolbar (~44px), optional error line (~24px), and content area (`Height="*"`). `CommandBar` holds the title (`TextBlock`/`Run` in a `StackPanel`, left-aligned, `Foreground="{ThemeResource AptGoldBrush}"`) and Button commands (New, Delete, Cancel, Save) right-aligned, bound to `Command`/`IsEnabled` reflecting the editing/dirty/busy conditions (Save additionally swaps its `Content` to "Saving…" while busy, via a converter or a bound property). Error `TextBlock` (`Margin="12,0,12,0"`, `Foreground="{ThemeResource AptRedBrush}"`) is shown or hidden via `Visibility="{x:Bind ErrorVisibility, Mode=OneWay}"`, a bound converter driven by whether the error string is set — not a literal with no binding behind it. The content area uses `NavigationView` with `PaneDisplayMode="Left"` (or a two-column `Grid` whose rail column animates between 240 and 48px), so the rail collapses exactly as `TopicDetail`'s own WinUI 3 note describes; a fixed `Width="240"` column with no toggle would not port the collapse behavior. Records list is a `ListView` (`SelectionMode="Single"`, `ItemsSource="{x:Bind Items}"`, `SelectedValue="{x:Bind SelectedId, Mode=TwoWay}"`, `SelectedValuePath="Id"` — `SelectedItem` would bind an item object, not the id string the shell tracks), and the detail pane is a `ContentPresenter` bound through a method (`Content="{x:Bind GetPaneContent(Editing), Mode=OneWay}"`), since `x:Bind` has no inline ternary expression syntax. Warn badges are `FontIcon` overlays (Unicode ⚠, `Foreground="{ThemeResource AptWarningBrush}"`) or `InfoBadge` controls in the `ListView.ItemTemplate`. All brushes come from `{ThemeResource}` (never `{StaticResource}`), so they follow theme changes, mapped to the `apt-*` tokens; skip `Reveal` — it was retired with UWP and has no WinUI 3 equivalent.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/editor-section.tsx` | unverified |

## Design Decisions

- **Decision**: `EditorSection` is a pure assembly with no visual grammar of its
  own.
  **Rationale**: Every editor topic must look identical; delegating all
  appearance to `ButtonBar` + `TopicDetail` + `EmptyState` keeps one blessed home
  for each part and avoids drift (optimize-for-change).
  **Approved**: pending
- **Decision**: The consumer owns all state (list, selection, draft, dirty, busy,
  error) and callbacks.
  **Rationale**: The shell computes only derived enablement;
  keeping the source of truth outside makes it reusable across every record type.
  **Approved**: pending
- **Decision**: "Editing" is derived from `selectedId !== null`, and Save from
  `editing && dirty`.
  **Rationale**: One selection prop drives both the pane
  choice and the toolbar enablement, so callers can't put the two out of sync.
  **Approved**: pending
- **Decision**: `canDelete` defaults to "anything selected" but honors an explicit
  `false`.
  **Rationale**: The common case needs no wiring, while a new/unsaved
  draft can suppress a Delete that would target a non-row.
  **Approved**: pending
- **Decision**: Warn rendering is data-driven from `warn`/`warnCount`/`warnTitle`
  on each item, mapping to a `Badge` or a bare `⚠`.
  **Rationale**: The rail stays a
  generic `TopicDetail`; the "needs configuration" affordance is expressed as data,
  not a new rail feature.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The `passed` rows rest on the source's `role="toolbar"` `ButtonBar`, the buttons'
`disabled` wiring to editing/dirty/busy state, the warn badge/span's
`aria-label`/`title` composing into its row button's accessible name, and
color usage limited to `apt-*` tokens (no raw hex, no `!important`); the
`partial` rows rest on `contrast-ratio` and `no-hardcoded-strings` being token-
and-source-derived facts the source's TSX cannot itself confirm (token contrast
ratios and translated strings live outside this file). `separation-of-concerns`
passes: `editor-section.tsx` owns no state of its own and no visual grammar —
it derives `editing`/`deletable` and maps items to `TopicDetailItem`s, then
delegates all rendering to `ButtonBar`, `TopicDetail`, `Badge`, and
`EmptyState`. `unit-test-coverage` fails — no test file in the `ui` package
exercises `EditorSection`.

## API

`@adh-sdk/ui/blocks/editor-section`:

```ts
interface EditorSectionItem {
  id: string
  label: string
  sublabel?: string
  icon?: React.ReactNode      // 16px leading icon (rail fills a neutral ring if omitted)
  warn?: boolean              // shows a ⚠ at the row's right edge
  warnTitle?: string
  warnCount?: number          // when set (and warn), renders a "⚠ N" count badge
}
interface EditorSectionProps {
  title: React.ReactNode
  titleBadge?: React.ReactNode
  createLabel: string
  items: EditorSectionItem[]
  selectedId: string | null
  onSelect: (id: string) => void
  onNew: () => void
  onDelete?: () => void        // omit → no Delete button
  onCancel: () => void
  onSave: () => void
  dirty: boolean
  busy?: boolean               // default false
  canDelete?: boolean          // default: "anything selected"
  error?: React.ReactNode      // red line under the toolbar
  emptyList?: React.ReactNode  // rail empty label; default "Nothing here yet."
  emptyDetail: React.ReactNode // EmptyState title when nothing selected
  listHeader?: React.ReactNode // rail leading slot; hidden while collapsed
  railWidth?: number           // widen for long-identifier rails
  children: React.ReactNode    // the record editor form, shown while editing
  className?: string
}
export function EditorSection(props: EditorSectionProps): React.ReactElement
```

Accessibility: the toolbar is `role="toolbar"` (via `ButtonBar`) with labeled
buttons whose `disabled` reflects the editing/dirty/busy state; each warn badge
carries `warnTitle` as its title/aria-label; the rail's selection and collapse
behaviors come from `TopicDetail`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Removed fabricated #localization/empty-list anchor (no Localization section); default-empty-list-label now describes the hardcoded English literal. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename all requirements to subject-only kebab-case; add disable-save-while-busy, disable-cancel-while-busy, keep-new-enabled-while-busy, and default-empty-list-label requirements with T15/T16 test vectors and updated T9; cite TopicDetail's own collapse-time badge/label-hiding requirements instead of duplicating them; clarify render-warn-badge-per-row's accessible-name composition; fix WinUI 3, SwiftUI, AppKit/UIKit, and Compose platform notes to name real APIs; move literal Tailwind classes out of Layout/Ingredients into the React/Web note; add ButtonBar/EmptyState ingredient domains; extract API and Accessibility into standalone sections; reformat Design Decisions to the three-line convention; rewrite Compliance as linked canonical checks. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Expand Platform Notes with all five platforms; add concrete translation guidance for SwiftUI, Compose, AppKit/UIKit, and WinUI 3. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the EditorSection assembly of ButtonBar + TopicDetail + EmptyState. |
