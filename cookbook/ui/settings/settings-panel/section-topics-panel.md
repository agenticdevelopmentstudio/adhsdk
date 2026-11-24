---
id: 308464cf-899c-4296-97b8-844a00865bc4
title: "Section Topics Panel"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One settings sidebar topic for a whole section: a vertical topic list of the section's panels beside the selected one, with the list hidden for a single panel."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - panel
  - navigation
depends-on: []
related:
  - 432e8d4b-43c3-49fd-b481-036a759e7c55
  - ba8d9517-2528-4ae9-bc52-16046d68b126
references:
  - https://developer.apple.com/design/human-interface-guidelines/sidebars
approved-by: ""
approved-date: ""
---

# Section Topics Panel

## Overview

The section topics panel is one sidebar topic of the settings window that
stands for a whole section. Inside it, a vertical topic list has one row per
panel in the section, beside the selected panel, the same topic and detail
split the Theme panel uses for its themes:

    Workspace  | Git        | <the selected panel>
               | Projects   |

It replaced a row of horizontal tabs. A tab bar stacked a second kind of
navigation over panels that already had a vertical one of their own, and ran
out of width at four tabs.

A section holding a single panel shows no list, because one row chooses
nothing; the panel fills the topic and the list returns when a second panel
arrives. Rows keep the order they are handed over in (the settings coordinator
hands them over alphabetised). The selected row survives a replacement of the
panels when its panel is still among the new ones.

The same file declares the container contract, `SettingsPanelContainer`: a
panel that holds other panels and shows one at a time. The window's search,
toolbar title, help and back and forward look through a container to the panel
the reader is actually looking at. This panel is the one conforming type. See
[adhsdk.ingredient.ui.settings.settings-panel-split](cookbook:ba8d9517-2528-4ae9-bc52-16046d68b126)
for the split it extends and
[adhsdk.ingredient.ui.settings.settings-panel](cookbook:432e8d4b-43c3-49fd-b481-036a759e7c55)
for the panel contract.

## Behavioral Requirements

- **main-actor-confined**: The panel and the container contract MUST be confined to the main actor.
- **container-contract**: A container MUST expose its contained panels, the contained panel currently selected (or none), and an operation that selects a given contained panel.
- **titled-for-section**: The panel's descriptor title MUST be the section name given to the initializer.
- **icon-from-initializer**: The panel's descriptor icon MUST be the icon given to the initializer, which MAY be absent.
- **no-sidebar-title**: The topic list MUST NOT show a header title, because the section's own name is already the selected sidebar row.
- **no-section-titles**: The topic list MUST NOT show section headers, because every panel in it carries the section's name as its own section.
- **list-hidden-before-panels**: A newly built panel MUST start with its topic list hidden until `setSectionPanels` decides otherwise.
- **list-needs-two**: `setSectionPanels` MUST show the topic list only when the section has more than one panel.
- **single-panel-fills**: With exactly one panel, the list MUST be collapsed and that panel MUST fill the topic.
- **list-returns**: When a later `setSectionPanels` call brings the count above one, the topic list MUST be shown again.
- **list-hides-again**: When a later call brings the count back to one, the topic list MUST be hidden again.
- **rows-keep-order**: The rows MUST keep the order the panels were handed over in.
- **contained-panels**: `containedPanels` MUST return the section's panels in row order.
- **selection-survives**: When the previously selected panel is still among the new panels, it MUST stay selected after `setSectionPanels`.
- **late-panel-selects-first**: When the view is loaded, no panel is selected and the new list is non-empty, `setSectionPanels` MUST select the first panel.
- **no-select-before-load**: `setSectionPanels` MUST NOT select a panel itself while the view is not loaded; selection then waits for the view to appear.
- **empty-section**: With no panels, `setSectionPanels` MUST hide the list and MUST NOT select anything.
- **select-contained**: `selectContainedPanel` MUST select the given panel in the detail area when it is one of the section's panels, and MUST do nothing when it is not.
- **selected-contained**: `selectedContainedPanel` MUST return the panel selected in the detail area, or none when nothing is selected.
- **container-seen-through**: The window MUST treat this panel as a container: search harvests every contained panel's title, section, keywords and help whether or not the section's view has loaded (a contained panel's on-screen labels are added only once that panel's own view has loaded), a search pick opens the first contained panel the query matches, and the toolbar title names the selected contained panel.
- **coder-unavailable**: Decoding from an archive MUST NOT be supported; the coder initializer MUST be unavailable and trap if reached.

## Appearance

- **Corner radius**: Not applicable: the panel draws no shape of its own; it is a split of a topic list and a detail area.
- **Padding**: Not set by this panel; the inherited split sets none beyond what the list and detail controllers carry.
- **Font**: Not set by this panel; row text comes from the shared panel list.
- **Background**: Not set by this panel; the split paints from the current theme palette on appearing.
- **Foreground/Text**: Row titles are the panels' descriptor titles; no header above the list.
- **Border**: Not set by this panel; the divider is the split view's.
- **Shadow**: None.
- **Min/Max size**: The detail area keeps the inherited minimum thickness of 200 points; the topic list is content-sized and unified to one width by the parent split, so switching between sibling sections never shifts the inner divider.

## States

| State | Appearance change |
|-------|------------------|
| Default (no panels) | List collapsed; detail empty |
| One panel | List collapsed; the panel fills the topic |
| Two or more panels | List visible with one row per panel; the selected panel shown in the detail area |
| Panel arrives while on screen with nothing selected | The first panel is selected so the detail is never empty beside a list |
| Pressed | Row press behavior is the shared panel list's; this panel adds none |
| Disabled | Not applicable: the panel has no enabled or disabled state in source |
| Focused | Not applicable: the panel adds no focus behavior of its own |
| Loading | Not applicable: panels are handed over synchronously; there is no loading state in source |

## Accessibility

- **role-trait**: NEEDS REVIEW: Not implemented in source. The panel sets no accessibility role, label or announcement of its own; the list and detail are the shared split and list controllers'. Evidence that would settle it is a screen-reader pass over a two-panel section checking that the list, the selected row and the detail are announced in order.
- Label requirements: The rows read as the panels' titles; this panel supplies no extra label.
- **announce-state-changes**: NEEDS REVIEW: Not implemented in source. Hiding or showing the list, and selecting the first panel on a late arrival, post no accessibility notification; a screen-reader pass would settle whether one is needed.
- Minimum tap target: Not applicable: the panel defines no control; row sizes belong to the shared panel list.

## Conformance Test Vectors

Derived from `SectionTopicsPanelTests` beside the source. Panels in the
vectors are plain settings panels titled as shown. Vectors 005 to 011 have no
test beside the source and are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| section-topics-001 | list-needs-two, single-panel-fills (onePanelHidesList) | Section "Web Browser"; `setSectionPanels` with one panel; load the view | `showsSidebar` is false and the first split item is collapsed |
| section-topics-002 | list-needs-two, rows-keep-order, contained-panels (twoPanelsShowList) | Section "AI"; two panels "Providers" and "Summaries"; load the view | `showsSidebar` is true, the first split item is not collapsed, `containedPanels` titles are Providers then Summaries |
| section-topics-003 | list-hides-again (twoPanelsShowList) | After 002, `setSectionPanels` with only the first panel | `showsSidebar` is false and the first split item is collapsed |
| section-topics-004 | selection-survives, select-contained, selected-contained (selectionSurvivesAddition) | Section "File Browser" with Editor and Excluded; load; select Excluded; call again with Editor, Excluded and File Types | `selectedContainedPanel` is still the Excluded panel (same object) |
| section-topics-005 | late-panel-selects-first | View loaded, no selection; `setSectionPanels` with two panels | `selectedContainedPanel` is the first panel |
| section-topics-006 | no-select-before-load | View not loaded; `setSectionPanels` with two panels | The call selects nothing itself; `selectedContainedPanel` is none until the view appears |
| section-topics-007 | empty-section | View loaded; `setSectionPanels` with an empty list | `showsSidebar` is false and `selectedContainedPanel` is none |
| section-topics-008 | select-contained | `selectContainedPanel` with a panel that is not in the section | The selection does not change |
| section-topics-009 | titled-for-section, icon-from-initializer | Initialize with section "AI" and a nil icon | The descriptor title is "AI" and the descriptor icon is none |
| section-topics-010 | no-sidebar-title, no-section-titles, list-hidden-before-panels | A new panel before any `setSectionPanels` call | Its sidebar title is none, the list shows no section titles, and `showsSidebar` is false |
| section-topics-011 | container-seen-through | A section hosted in a settings window with two panels; search for a term in the second panel before the section's view has loaded | The search harvests the second panel's title, section, keywords and help terms; its on-screen labels are added only if that panel's own view has loaded |

## Edge Cases

- **No panels** (MUST): The list is hidden, nothing is selected, and the detail is empty.
- **One panel** (MUST): No list; the panel fills the topic. It is selected once the view appears or a late-arrival selection runs.
- **Panel arrives after the section is on screen** (MUST): With nothing selected, the first panel is selected at once, because no appearance event will do it and an empty detail beside a list looks broken. If a panel was already selected, it stays selected.
- **Same panels, same order, handed over again** (MUST): The inherited split only redraws the rows and leaves the back and forward trail alone, as its comment says for a record window refreshing on a timer.
- **Selected panel removed** (MUST): The selection does not survive; with the view loaded and nothing selected, the first remaining panel is selected.
- **Different panel list** (MUST): The inherited split resets the back and forward trail, since its positions point at other panels.
- **View not yet loaded** (MUST): The list's visibility is recorded and applied when the view loads; selection waits for the view to appear.
- **Section name repeated by every panel** (MUST): Section headers are suppressed so the list does not show one repeating header.
- **Same section requested again by the coordinator** (MUST): The coordinator keeps one panel per section name and drops it when no panel claims the section, so the instance survives panels coming and going.
- **Concurrent access** (MUST): The type is confined to the main actor, so every call runs serialized on the main thread; there is no cross-thread access to define.
- **Network or offline state**: Not applicable: the panel does no network, disk or external work.
- **Boundary values**: One panel is the only boundary the source handles specially (list hidden at one or fewer); there is no upper limit.
- **Decoding from an archive** (MUST NOT): The coder initializer is unavailable and traps if called.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| section | String | none (required) | The section name; becomes the panel's title |
| icon | NSImage? | none (required argument, may be nil) | The sidebar icon; the coordinator passes the section icon, else the first panel's icon |
| panels | array of panels | none | Passed to `setSectionPanels`; row order is the given order |

## Deep Linking

Not applicable: the panel has no address or route in source.

## Localization

Not applicable: the panel holds no string of its own. The section name and the rows' titles are supplied by the caller and the panels' descriptors.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the panel adds no animation of its own. |
| Increase Contrast | Not applicable: the panel sets no color of its own. |
| Differentiate Without Color | Not applicable: the panel sets no color of its own; selection is shown by the shared list. |

## Feature Flags

Not applicable: the source reads no flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None.
- **Storage**: None; the panel holds only the panels it was given.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the source writes no log entry.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/SettingsPanel/SectionTopicsPanel.swift`, an AppKit class in an extension of `ComposableSettings`, subclassing the settings split view controller. In SwiftUI, a `NavigationSplitView` with a `List(selection:)` of panels in the sidebar and the selected panel's view as detail; set `columnVisibility` to `.detailOnly` when there is one panel, and seed the selection to the first panel in `onAppear` or when the list changes while nothing is selected.
- **Compose**: A `Row` of a `LazyColumn` of rows (the list) and a `Box` for the selected panel; show the list only when `panels.size > 1`; hold `selectedId` in state and keep it across list changes with `rememberSaveable`, defaulting to the first id when it is not in the list.
- **React/Web**: A two-column layout: a `nav` with `role="tablist"` (`aria-orientation="vertical"`) of buttons beside a `role="tabpanel"` region; render the nav only when `panels.length > 1`; keep `selectedId` in state, reset to the first panel only when it is missing from the new array.
- **AppKit / UIKit**: In AppKit the source subclasses a split view controller whose first item is the topic list (a sidebar split view item) and second the detail; collapse is done with `isCollapsed` and `canCollapse` on the first item. On UIKit, use `UISplitViewController` in column style with the primary column hidden (`hide(.primary)`) for one panel and `UITableView` rows in the primary column.
- **WinUI 3**: Use a `NavigationView` with `PaneDisplayMode="Left"` (or a `Grid` of two columns: a `ListView` and a `ContentControl`). Bind `NavigationView.MenuItemsSource` (or the `ListView.ItemsSource`) to the section's panels in the order given, with `SelectedItem` two-way bound. Set `IsPaneVisible` bound to a `HasSeveralPanels` property and `IsBackButtonVisible="Collapsed"`, or set the list column's `Visibility` to `Collapsed` when there is one panel. Keep the selection when the collection is replaced by comparing `SelectedItem` against the new items and selecting the first item only if nothing is selected and the page has raised `Loaded`. Set `AutomationProperties.Name` on the list to the section name. Implement the container contract as an `ISettingsPanelContainer` interface with `ContainedPanels`, `SelectedContainedPanel` and `SelectContainedPanel` so search and the title bar can read through it.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/SettingsPanel/SectionTopicsPanel.swift` | confirmed (1.0.1) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A section is one sidebar topic with a vertical topic list inside it, not a row of horizontal tabs.
**Rationale**: A tab bar stacked a second kind of navigation over panels that already had a vertical one, and ran out of width at four tabs.
**Approved**: pending

**Decision**: A section with one panel shows no list.
**Rationale**: One row chooses nothing; a column naming the only thing on screen is noise.
**Approved**: pending

**Decision**: The list shows no header title and no section titles.
**Rationale**: The section's name is already the selected sidebar row, and every panel in the list carries the section's name as its own section.
**Approved**: pending

**Decision**: The first panel is selected on a late arrival only when the view is loaded and nothing is selected.
**Rationale**: A panel arriving after the section is on screen has no appearance event to select it, and an empty detail beside a list looks broken; when the view is not loaded, appearing does the selecting.
**Approved**: pending

**Decision**: The selected row survives a replacement of the panels when its panel is still present.
**Rationale**: A panel added late must never move the reader off the row they were on; the selection test records this.
**Approved**: pending

**Decision**: Rows keep the order they are handed over in; the coordinator alphabetises.
**Rationale**: The section does not impose an order of its own, so one rule sits in one place, the coordinator.
**Approved**: pending

**Decision**: The container contract lives beside this panel, and the window looks through containers instead of naming this type.
**Rationale**: Search, title, help and back and forward all need the panel the reader is looking at; one contract serves all of them.
**Approved**: pending

**Decision**: The panel adds no accessibility behavior of its own.
**Rationale**: The source relies on the shared split and list controllers; the open questions on Role/trait and Announce state changes record what a reviewer should settle.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

The panel does one job: arrange a section's panels as a list beside a detail
area and expose the container contract, leaving ordering to the coordinator
and drawing to the shared list and split, so separation of concerns passes.
The test file covers the one-panel list, the two-panel list and the selection
surviving an addition, but not the late-arrival selection, the empty section
or the container contract, so unit test coverage is partial. Screen reader
support is partial because the panel adds nothing of its own over the shared
controllers. Keyboard navigation is partial for the same reason: the panel
inherits what the split and list provide. It is built from the native split
view controller and its sidebar item, so native controls preference passes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Review markers in one-line form |
