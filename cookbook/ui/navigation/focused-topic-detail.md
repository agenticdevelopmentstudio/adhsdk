---
id: 7f122a27-5b49-4f03-9439-1152249bc08f
title: "Focused Topic Detail (FTD) View"
type: recipe
version: 1.2.5
status: accepted
language: en
created: 2026-06-26
modified: 2026-10-04
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The master/detail view contract governing every route that manages a collection of one entity kind: topic list, entity pane, selector popup, and All view."
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

This recipe defines the **general FTD contract** that governs *every* route built
on the Focused Topic Detail view. Concrete instantiations (Ecosystems, Teams,
Persona APIs) live in **## Instantiations**, below; when a general statement here
and an instantiation's own value seem to disagree, the general contract wins and
the instantiation is the one that's wrong.

A **Focused Topic Detail (FTD)** view manages a *collection of entities of one
kind* (ecosystems, teams, persona-services, …). At any moment the user is either:

- **Focused on one entity** — a left-hand **topic list** of that entity's sections, and a right-hand **detail panel** for the selected topic; or
- **Surveying all entities** — the **"All" view**, a browsable index of every entity in the collection.

The user moves between entities (and into "All") through a single **selector
popup** at the top-left of the view. The canonical implementation is the shared
`FocusedTopicDetail` block in `@adh-sdk/ui/blocks` (master/detail
layout) — all FTD routes compose it; none hand-roll the layout.

**Terminology / parameters.** Every FTD route binds these parameters (Ecosystems
values shown for reference — see **Instantiations**):

| Parameter | Meaning | Ecosystems value |
|---|---|---|
| `Entity` | Singular display name of the managed thing | **Ecosystem** |
| `Entities` | Plural | **Ecosystems** |
| `basePath` | Route root | `/ecosystems` |
| `rdid` | The **mutable** reverse-domain **identifier** that uniquely names an entity; shown as the **Identifier** field; maps to an immutable internal UUID via `registry.identifiers` | `identifier` (e.g. `{{org_package}}.myecosystem`) |
| `topics` | Ordered sections shown in the topic list | Ecosystem, Applications, Buckets, Users |
| `childEntities` | Dependent data a delete cascades through (used in delete copy) | applications, buckets, and users |

The identifier is the entity's **public, mutable** name; internally the row is
keyed by an immutable UUID, and `registry.identifiers` maps rdid → UUID so the
identifier can change without breaking UUID foreign keys.

Every `{id}` route segment — and the persisted `lastId` — is the **rdid**, never
the immutable UUID; the two exchange only through `registry.identifiers`.
Because the rdid is mutable, a deep link built from a pre-rename rdid no longer
matches any entity once the rename lands: the resolver treats an unrecognized
id exactly like a stale `lastId` (see **Edge Cases**) and falls back to the All
view rather than a 404.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| FocusedTopicDetail block | [adhsdk.ingredient.ui.blocks.topic-detail](cookbook:8fa7aaae-df62-44ea-b10c-182f3094ed9f) | The master/detail layout (topic list + detail panel) every route composes | yes | `topics`, `paneOwnedActions` |
| OptionMenu | [adhsdk.ingredient.ui.components.inputs.option-menu](cookbook:4d0e04ff-39eb-472c-93a0-8070f1b64a6a) | The selector popup that switches focus and hosts the New action | yes | radio entities + All + trailing New item |
| AlertAndDialog | [adhsdk.recipe.alert-and-dialog](cookbook:550f00f7-bfb2-415e-9b15-bd5dce015500) | Step-1 warning alert + step-2 type-to-confirm delete dialog | yes | destructive; `Entity`/`rdid`/`childEntities` params |
| Disclosure | [adhsdk.ingredient.ui.components.layout.disclosure](cookbook:c99e2822-f5a9-4e84-8740-9341880bb82a) | The collapsible Danger Zone in the entity pane | yes | collapsed default; apt-red accent only when open |
| DataTable | [adhsdk.ingredient.ui.components.data.data-table](cookbook:d04eef56-2dbf-4148-964b-c095f242227f) | The All view "list" render mode (one row per entity) | yes | name + identifier + key meta columns |
| ResizableSplit | [adhsdk.ingredient.ui.components.layout.resizable-split](cookbook:c21473ee-a075-4800-96db-ff3de0888515) | Optional split layout within a topic's detail panel | no | as needed per topic |

## Integration Requirements

- **shared-block-composition**: Every FTD route MUST compose the shared `FocusedTopicDetail` block (`@adh-sdk/ui/blocks`) and MUST NOT hand-roll the master/detail layout.
- **first-topic-is-entity**: The first topic MUST be the entity itself, labelled with the singular `Entity` name, editing the entity's own attributes plus the Danger section; there MUST be no divider above the first topic.
- **no-action-bar**: The FTD view MUST NOT render a full-width `New | Delete` action bar; New lives in the selector popup and Delete lives in the entity pane's Danger section.
- **editable-identifier**: The Identifier (rdid) MUST be editable for existing entities, renaming via `PATCH /registry/identifiers/{rdid}` with the **old** rdid in the path, leaving the internal UUID and all FK references unchanged.
- **validate-identifier-format**: The Identifier MUST validate the reverse-domain format `^[a-z0-9]+(?:\.[a-z0-9-]+)+$`, lowercased on input. The first segment excludes hyphens because it mirrors a top-level-domain label, which real TLDs never hyphenate; later segments mirror ordinary domain labels, which may. Because input is lowercased before validation, the stored rdid is always lowercase, so the case-sensitive match in **typed-confirm-exact** never has to reconcile case — both sides are already lowercase.
- **rename-unknown-rdid-404**: `PATCH /registry/identifiers/{rdid}` MUST return 404 when the rdid in the path is not currently registered to any entity.
- **identifier-availability-check**: The Identifier field SHOULD call `GET /registry/identifiers/{rdid}/exists` while the user edits it, to surface an inline availability hint ahead of the authoritative 409 in **surface-identifier-collision**.
- **surface-identifier-collision**: A server-side uniqueness collision (HTTP 409) MUST surface as an inline field error.
- **danger-zone-collapsed-neutral**: The Danger Zone MUST be a disclosure that is collapsed by default and styled neutrally while closed, taking the `apt-red` accent (red title + border) only once disclosed; the warning-triangle glyph MUST stay `apt-gold` in both states.
- **two-step-delete**: Deleting an entity MUST require two steps — a warning alert with `[ Cancel ][ Yes ]`, then (only on Yes) a type-to-confirm dialog.
- **warning-copy-article-agreement**: The step-1 warning copy MUST select "a" or "an" for `{Entity}` by the entity noun's leading sound, never a hardcoded article.
- **typed-confirm-exact**: The `Permanently Delete` button MUST stay disabled until the typed text exactly equals the rdid — case-sensitive, no leading/trailing/internal extra whitespace, no normalization.
- **delete-navigates-to-all**: On a successful delete, the view MUST clear the persisted last-selected entry and navigate to the All view; on error it MUST show inline error text and keep the dialog open.
- **selector-popup-switches-focus**: The selector popup MUST be the single entry point for switching focus; All and each entity MUST be radio items that navigate (`{basePath}/all` or `{basePath}/{id}/{topic}`).
- **new-action-in-popup**: The popup MUST place a non-radio `New {Entity}…` action at the bottom after a divider that opens the Create dialog (with its unsaved-changes guard), not a navigation.
- **all-view-filter**: The All view MUST provide a text filter immediately left of the card/list toggle, filtering client-side by name and identifier (case-insensitive substring), with an empty state "No {entities} match \"{query}\".".
- **all-view-toggle**: The All view MUST provide a two-option segmented toggle — cards (`LayoutGrid`) and list (`List`) — defaulting to cards, both linking each entity to `{basePath}/{id}/{firstTopic}`.
- **explicit-all-precedence**: `{basePath}/all` MUST always render the All view, even when a persisted `lastId` still matches a live entity.
- **persist-view-mode**: The chosen All view mode MUST persist under `{{app_prefix}}:ftd:{basePath}:viewMode` so it survives navigation and reload.
- **resume-last-selected**: On entering the bare base path, after the entity list loads the view MUST focus the last-selected entity under `{{app_prefix}}:ftd:{basePath}:lastId` when it still matches a live entity, otherwise show the All view.
- **clear-laststate-on-delete**: When an entity is deleted, the view MUST clear `…:lastId` if it pointed at that entity.
- **resolve-after-list-load**: Local-storage resolution MUST occur after the list has loaded (to avoid SSR hydration mismatch), showing the normal loading state until then.
- **shared-piece-location**: New shared pieces (the Danger Zone / delete-confirm `DeleteEntitySection` block, the All toolbar, the list-mode renderer) MUST go into `@adh-sdk/adh-ui/blocks`, never forked into a site.
- **surface-states**: Every new surface MUST handle loading, empty, and error states (All list loading, no entities yet, filter-no-match, delete error inline, identifier-collision inline).
- **accessibility**: Dialogs MUST be `role="dialog"` with focus trap + restore and labelled controls; the type-to-confirm input MUST have a `<label htmlFor>`; the All view's card/list toggle MUST carry `role="radiogroup"` and `aria-label="View as"`; full keyboard operability (Esc cancels dialogs) is required.

## Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  [ Selector popup ▾ ]                                              │  ← top-left popup
├───────────────┬──────────────────────────────────────────────────┤
│  TOPIC LIST   │  DETAIL PANEL                                      │
│               │                                                    │
│  {Entity}     │   (content for the selected topic)                │
│  {Topic 2}    │                                                    │
│  {Topic 3}    │                                                    │
│  …            │                                                    │
└───────────────┴──────────────────────────────────────────────────┘
```

- **No action bar.** A full-width `New | divider | Delete` bar is never rendered above the grid; New lives in the selector popup, Delete lives in the entity pane's Danger section.
- In the **All** view the detail panel is replaced by the All index and the topic list is not shown (there is no focused entity).

The All view toolbar (upper-right):

```
┌──────────────────────────────────────────────────────────────────┐
│  All {Entities}                  [ filter… ]   [▦ cards] [☰ list] │  ← toolbar
├──────────────────────────────────────────────────────────────────┤
│   … cards grid  OR  list rows …                                   │
└──────────────────────────────────────────────────────────────────┘
```

The two-step delete (step 2, type-to-confirm):

```
You are about to permanently delete this {Entity}.

Enter "{rdid}" below
┌────────────────────────────────────────────┐
│                                            │   ← text entry
└────────────────────────────────────────────┘
                              [ Cancel ]  [ Permanently Delete ]   ← red, disabled
```

Color only via `apt-*` tokens (`apt-red` destructive, `apt-border`, `apt-text-muted`, …). No raw hex / arbitrary colors / `!important`.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| selected entity id | Route (URL) | Topic list + detail panel | Down | URL param `{basePath}/{id}/{topic}` |
| last-selected id | localStorage `{{app_prefix}}:ftd:{basePath}:lastId` | Bare-path resolver | Both | Written on focus; cleared on delete of that id |
| view mode (`cards`/`list`) | localStorage `{{app_prefix}}:ftd:{basePath}:viewMode` | All view toggle | Both | Read on init (default `cards`); written on change |
| filter query | All view local state | Client-side entity filter | Down | Component state |
| entity list | Module-level cache (stale-while-revalidate) | Topic list, All view | Down | SWR-style cache |
| Danger Zone disclosure open | Entity pane local state | Disclosure styling + delete control | Down | Component state |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | editable-identifier, surface-identifier-collision | rename Identifier to a taken rdid | inline collision (409) error; UUID unchanged |
| T2 | editable-identifier | rename Identifier to a free rdid | `PATCH /registry/identifiers/{oldRdid}` called; route/`lastId` refresh to the new rdid |
| T3 | two-step-delete, typed-confirm-exact | Delete → Yes → type partial rdid | `Permanently Delete` disabled until exact, case-sensitive match |
| T4 | delete-navigates-to-all, clear-laststate-on-delete | confirm delete succeeds | API called; `lastId` cleared; navigates to All |
| T5 | new-action-in-popup | open popup → New {Entity}… | Create dialog opens (not a navigation) |
| T6 | all-view-filter | type a query in All filter | list narrows by name/identifier; no-match shows empty state |
| T7 | all-view-toggle, persist-view-mode | switch to list, reload | list mode persists via `…:viewMode` |
| T8 | resume-last-selected | enter bare base path with a live `lastId` | focuses that entity; stale/missing → All |
| T9 | delete-navigates-to-all | confirm delete → API call rejects | inline error text shown; dialog stays open; `lastId` unchanged |
| T10 | validate-identifier-format | type an uppercase or malformed identifier | value is lowercased; a malformed value blocks submit with an inline format error |
| T11 | danger-zone-collapsed-neutral | load the entity pane | Danger Zone renders collapsed, neutral border/title, `apt-gold` glyph; opening it applies the `apt-red` title/border |
| T12 | first-topic-is-entity | load any FTD route's topic list | first topic is the entity itself, labelled `Entity`, no divider above it |
| T13 | no-action-bar | load any FTD route | no full-width New/Delete action bar renders above the grid |
| T14 | selector-popup-switches-focus | choose a different entity (or All) in the selector popup | view navigates to `{basePath}/{id}/{topic}` (or `{basePath}/all`) for the chosen item |
| T15 | resolve-after-list-load | enter the bare base path before the entity list has loaded | normal loading state shows; `lastId` resolution runs only after the list resolves |
| T16 | surface-states | All view loading / no entities / filter-no-match / delete error / identifier collision | each condition shows its own state (spinner, empty copy, "No {entities} match…", inline delete error, inline collision error) |
| T17 | accessibility | open a delete dialog; inspect the All-view toggle | dialog has `role="dialog"` with focus trapped and restored on close; toggle carries `role="radiogroup"` and `aria-label="View as"` |
| T18 | rename-unknown-rdid-404 | `PATCH` with an old rdid that is no longer registered | 404 response surfaces as an inline error |
| T19 | identifier-availability-check | type a candidate identifier | inline availability hint reflects `GET …/exists` before submit |
| T20 | warning-copy-article-agreement | `Entity` starting with a vowel vs. a consonant | step-1 copy reads "an" vs. "a" correctly |
| T21 | explicit-all-precedence | navigate to `{basePath}/all` while a live `lastId` is set | All view renders regardless of the stored id |

## Edge Cases

- A stale or deleted `lastId` (no longer a live entity) resolves to the All view; the same fallback applies to a deep link built from a pre-rename rdid, since the resolver cannot distinguish "never existed" from "renamed away" (see **explicit-all-precedence**).
- `{basePath}/all` is the **explicit** All view and always shows All regardless of the stored id (**explicit-all-precedence**).
- Local storage is client-only; resolution happens after the list loads to avoid SSR hydration mismatch (**resolve-after-list-load**).
- `PATCH /registry/identifiers/{rdid}` returns 404 if the old rdid is unknown (**rename-unknown-rdid-404**) and 409 on collision (**surface-identifier-collision**); `GET /registry/identifiers/{rdid}/exists` supports inline availability checks (**identifier-availability-check**).
- The type-to-confirm match is exact (`===` rdid), case-sensitive, with no whitespace normalization; because the identifier is lowercased on input, the stored rdid — and so the value being matched against — is always already lowercase.
- The filter empty result shows "No {entities} match \"{query}\".".

## Platform Notes

- **React/Web** (source): Each FTD route composes the shared `FocusedTopicDetail` block (`@adh-sdk/ui/blocks`) for the master/detail layout and the `DeleteEntitySection` block (`@adh-sdk/adh-ui/blocks`) for the Danger Zone and two-step delete; the selector popup and All-view toolbar are the route's own composition around those two blocks. The Identifier field's rename flow calls `PATCH /registry/identifiers/{rdid}` (keyed by the *old* rdid) and `GET /registry/identifiers/{rdid}/exists`; the entity's own create/update endpoint never sends `identifier`, since it is server-managed and renamed only through the identifiers route.
- **SwiftUI**: A `NavigationSplitView` supplies the topic list as its sidebar and the detail panel as its detail column; the selector popup is a toolbar `Menu`/`Picker`; the Danger Zone is a `DisclosureGroup` gated behind a two-step `.alert` / `.confirmationDialog` pair; the All view toggles a `Grid`/`List` via a segmented `Picker(.segmented)`.
- **Compose**: A `ListDetailPaneScaffold` (or an adaptive two-pane `Row`) plays the split-view role; the selector popup is a `DropdownMenu`; the Danger Zone is an `ExpandableCard` gated behind a two-step `AlertDialog` pair; the All view toggles `LazyVerticalGrid`/`LazyColumn` via a segmented control.
- **AppKit / UIKit**: `NSSplitViewController` (AppKit) or a two-pane `UISplitViewController` (UIKit) plays the split-view role; the selector popup is an `NSPopUpButton` / `UIMenu`; the Danger Zone is a collapsible section gated behind a two-step `NSAlert` / `UIAlertController` pair.
- **WinUI 3**: A `NavigationView` (or a two-pane `SplitView`) plays the split-view role; the selector popup is a `DropDownButton` with a `MenuFlyout`; the Danger Zone is an `Expander` gated behind a two-step `ContentDialog` pair; the All view toggles a `GridView`/`ListView` via a segmented `ToggleSwitch`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/focused-topic-detail.tsx` | unverified |
| web | `packages/web/packages/ui/src/blocks/topic-detail.tsx` | unverified |
| web | `packages/web/packages/ui/src/blocks/popup-menu.tsx` | unverified |
| web | `packages/web/packages/ui/src/blocks/resource-card.tsx` | unverified |
| web | `packages/web/packages/ui/src/blocks/section-header.tsx` | unverified |

## Design Decisions

- **Decision**: Remove the full-width action bar (New | divider | red Delete) from the FTD composition; New lives in the selector popup and Delete lives in the entity pane's Danger section behind a two-step confirm.
  **Rationale**: A redundant, always-present destructive affordance violates least-astonishment; contextual placement plus a deliberate two-step confirm removes it without losing the action.
  **Approved**: pending

- **Decision**: The rdid is mutable via the `registry.identifiers` table, which maps the mutable rdid to an immutable UUID primary key; renaming updates the mapping only, never the UUID or its foreign-key references. The mapping table and its `PATCH /registry/identifiers/{rdid}` endpoint already exist and are in the OpenAPI spec and generated clients, so no backend route or codegen is added by this recipe.
  **Rationale**: Matches the platform-wide pattern of renaming organizations/namespaces via the identifiers route rather than an entity's own update endpoint, so FK relationships never need to be rewritten on rename; because the endpoint already exists, this recipe's remaining work is frontend wiring.
  **Approved**: pending

- **Decision**: Replace `window.confirm()` with a two-step delete built as one shared block, `DeleteEntitySection` (`@adh-sdk/adh-ui/blocks`), parameterized by `Entity`, `rdid`, and `childEntities`; the step-1 warning copy is templated ("{gerund} {a/an} {entity} deletes all the data associated with the {entity}, including {childEntities}. Do you wish to proceed?") with the article chosen by the entity noun's leading sound (**warning-copy-article-agreement**).
  **Rationale**: One authoritative implementation is shared by every FTD route (DRY) instead of each route re-deriving its own confirm copy and article agreement.
  **Approved**: pending

- **Decision**: Step-1 warning dialog buttons are labelled `Cancel` / `Yes`.
  **Rationale**: Cancel/Yes reads as a plain acknowledgement; the destructive verb is reserved for the type-to-confirm step's button, not repeated at step one.
  **Approved**: pending

- **Decision**: The All view's `cards`/`list` toggle persists its chosen mode.
  **Rationale**: A layout preference set once should survive navigation and reload rather than reset to the default on every visit.
  **Approved**: pending

### Instantiations

Concrete bindings for each route that composes this contract. The general
contract above always wins on conflict.

#### Ecosystems

The first concrete FTD instantiation. Parameter bindings are given inline in
the Overview's Terminology table.

**Topic order** (top → bottom, no dividers): `Ecosystem` (the entity's own
pane), `Applications`, `Buckets`, `Users`. Route ids stay stable where only the
label changes, to avoid breaking deep links; renaming the `schemas` route
segment itself to `buckets` is a separate, reversible decision that would need
its own redirect.

**Layout, concretely:**
- Topic list: `Ecosystem, Applications, Buckets, Users`.
- All-view toolbar title: `All Ecosystems`.
- Delete dialog: "You are about to permanently delete this Ecosystem. Enter
  \"{{org_package}}.myecosystem\" below."
- `rdid` example: `{{org_package}}.myecosystem`.
- `childEntities` copy: "applications, buckets, and users".
- Persistence keys: `{{app_prefix}}:ftd:/ecosystems:lastId`,
  `{{app_prefix}}:ftd:/ecosystems:viewMode`.

**Frontend wiring** (identifier rename — the backend already supports it):
reuse `PATCH /registry/identifiers/{rdid}` and `GET …/{rdid}/exists`; no new
backend route, no codegen. An API client wraps the identifiers endpoints, and
the Identifier field's save renames via the *old* rdid, refreshing the
route/`lastId` to the new rdid on success. The ecosystem's own update endpoint
keeps ignoring `identifier` (it is server-managed).

**Hub file map:**
- `src/components/settings/topics.ts` — the ecosystem topic list: `Ecosystem` first (no divider above it), `Buckets` in place of `Schemas`.
- `src/components/settings/ecosystems/EcosystemDetail.tsx` — editable Identifier; Danger Zone.
- `@adh-sdk/adh-ui/blocks` — the shared `DeleteEntitySection` block, parameterized by `Entity`, `rdid`, `childEntities`.
- `src/components/home/resource/ResourcePopup.tsx` — the New action (trailing divider + non-radio `New {Entity}…`).
- `src/components/home/resource/ResourceLanding.tsx` — the All toolbar: filter, card/list toggle, list renderer.
- `src/components/home/resource/ResourceTab.tsx` — last-selected + view-mode persistence and bare-path resolution.

- **Decision**: Rename the Ecosystems "Schemas" topic to "Buckets".
  **Rationale**: Buckets are real ecosystem child data; "Schemas" no longer matches what the topic manages, and the delete-warning child-entities copy ("…applications, buckets, and users") already reflects this name.
  **Approved**: pending

#### Teams / Persona APIs

Both compose the shared `ResourceTab` orchestrator. The entity's own pane
(`Team` / `Service`) is the first topic; `paneOwnedActions` keeps the action
bar out of the composition; New is the selector popup's trailing action;
Delete is the entity pane's `DeleteEntitySection` Danger Zone, with the
type-to-confirm value bound to the team's `identifier` or the service's
`name`. `Members/Permissions` and `Models` keep their existing route ids.
Each tab seeds its list from the same module-level (stale-while-revalidate)
cache as Ecosystems.

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.test-pyramid](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/203de556-83a8-5211-acaf-155c49da0eb3) | partial | Best Practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.platform-compliance.deep-linking-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c2a477a7-bd42-5e3f-9ebd-5a64b4b63de4) | passed | Platform Compliance |

The passed rows rest on `DeleteEntitySection`'s `@base-ui/react/dialog`
primitive (focus trap, Escape-to-close), its `Label htmlFor` wiring, its
`apt-*`-only token usage, and the URL-driven `{basePath}/{id}/{topic}`
routing; the partial accessibility rows reflect that the All view's filter,
toggle, and its `role="radiogroup"`/`aria-label` are not yet built and no
computed contrast or hit-size values are given; `no-hardcoded-strings` is
failed because every string in `delete-entity-section.tsx` is a plain JSX
literal with no localization call; `test-pyramid` is partial because the
recipe defines integration-level vectors (a Playwright e2e suite) but no
unit-test strategy.

Process: the repo's pre-commit gate (`check_ui.py`, typecheck, lint,
`/code-review`) runs before every commit on this surface; it is a workflow
step, not a compliance check.

Separation-of-concerns is passed: `focused-topic-detail.tsx` composes only existing blocks (`PopupMenu`, `TopicDetail`, `SectionHeader`, `ResourceCard`) and leaves the focused pane's content to the consumer, and the destructive flow lives in the separate `DeleteEntitySection` block. Unit-test-coverage is partial: `deleteEntitySection.test.tsx` and the `topicDetail*.test.tsx` files in `packages/web/packages/ui/src/__tests__` cover the delete flow and the topic-detail block it composes, but no test file imports the focused-topic-detail block itself, so the popup/All-view/card-toggle composition is untested.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.5 | 2026-10-04 | Mike Fullerton | Matches its type's shape: required fields, title heading, and only the type's own sections. |
| 1.2.4 | 2026-10-04 | Mike Fullerton | Legacy recipe citations restored to the legacy recipes' own adhsdk://recipes/ domains; the adhsdk://recipes/ form named nothing. |
| 1.2.3 | 2026-10-04 | Mike Fullerton | Filled Reference Implementations and Compliance rows |
| 1.2.2 | 2026-09-27 | Mike Fullerton | Moved into the concept grouping. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-23 | Mike Fullerton | Lint pass: renamed the remaining verb-phrase requirements to subject-only names and updated every citation; split the Ecosystems/Teams instantiation values out of the general contract into a new Instantiations section; reworded Platform Notes and Design Decisions from migration-plan phrasing to a steady-state contract (Design Decisions reformatted to Decision/Rationale/Approved) and gave Platform Notes real per-platform APIs; fixed the `{basePath}` route templates that doubled a leading slash; clarified that `{id}`/`lastId` are the rdid and stated the post-rename deep-link fallback; replaced hardcoded `adh:`/hub-path/example values with `{{app_prefix}}`/`{{org_package}}` placeholders outside the instantiation appendix; promoted four requirements (rename-unknown-rdid-404, identifier-availability-check, warning-copy-article-agreement, explicit-all-precedence) out of Edge Cases/Design Decisions; added test vectors for every previously-uncovered requirement plus a delete-error vector; moved the concrete toggle ARIA rule into the accessibility requirement; explained the identifier regex's segment asymmetry and the always-lowercase rdid; standardized the shared-block naming (`FocusedTopicDetail` in `@adh-sdk/ui/blocks`, `DeleteEntitySection` in `@adh-sdk/adh-ui/blocks`); rebuilt Compliance as real linked catalog checks with a process note replacing the pre-commit-gate row. |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Renamed every requirement to subject-only kebab-case, dropping the old prefix everywhere it is cited. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec (carries forward the v0.2 locked decisions A–D). |
