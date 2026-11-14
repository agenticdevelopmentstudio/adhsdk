---
id: 024921f5-3051-4b68-84d9-a0912a0cc51e
title: "Spacing Settings Panel View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The Settings > Appearance > Spacing panel: frame, pane divider and pane content spacing, each bound to the app-wide keys, with a Tab order joined across the groups."
platforms:
  - swift
  - macos
tags:
  - composable-tabs
  - settings
  - spacing
  - settings-panel
depends-on: []
related:
  - 4c528e38-b70a-4ed3-bedc-9009292ad908
  - 92d66361-a16d-4c35-a0d3-4c1c8bbd5f52
references:
  - https://developer.apple.com/design/human-interface-guidelines/layout
approved-by: ""
approved-date: ""
---

# Spacing Settings Panel View Controller

## Overview

The settings panel titled "Spacing", the one place the app's spacing is set.
It shows three groups, each a diagram-style spacing control bound to the
app-wide keys that pane spacing reads: the room around the panes (frame
spacing), the gaps between them (pane divider spacing), and the room between
a pane's edges and its content (pane content spacing). Every window reads
these values (the project windows, the Coding Partner window and the
terminal), and none offers spacing controls of its own, so there is exactly
one answer to "why is this pane spaced like that".

The panel's own work is small: it names itself, lists the search keywords the
sidebar needs before the panel is first opened, supplies the help topics for
the help drawer, builds the three groups, and joins the Tab order of the three
controls end to end. Use it as one panel of a composable settings window.

## Behavioral Requirements

### Identity

- **panel-title**: The panel MUST present itself with the title "Spacing".
- **panel-icon**: The panel MUST present itself with the rectangle-split-three-columns system symbol and no accessibility description on that symbol.
- **search-keywords**: The panel MUST offer exactly these keywords to the settings search, in this order: spacing, frame, divider, gutter, pane, padding, margin, terminal, project, partner.
- **search-before-open**: The keywords MUST be available before the panel has ever been opened, because the sidebar search only reads the controls of a panel that has been opened.

### Groups

- **three-groups**: The panel MUST contain exactly three groups, in this order: "Frame Spacing", "Pane Divider Spacing", "Pane Content Spacing".
- **one-control-per-group**: Each group MUST contain exactly one spacing control.
- **frame-bound**: The Frame Spacing control MUST be a frame-style control bound to the four app-wide frame edge settings (top, leading, bottom, trailing).
- **divider-bound**: The Pane Divider Spacing control MUST be a pane-divider-style control bound to the two app-wide gutter settings (between columns, between rows).
- **content-bound**: The Pane Content Spacing control MUST be a frame-style control bound to the four app-wide pane content edge settings (top, leading, bottom, trailing).
- **groups-build-on-load**: The panel MUST build its groups when its view loads, not at construction.
- **live-apply**: A change made in any of the controls MUST apply to every window as the reader makes it, with no confirm step.
- **no-local-store**: The panel MUST NOT hold spacing values of its own; the controls read and write the app-wide settings through their bindings.

### Accessibility identifiers

- **frame-identifier**: The Frame Spacing control MUST carry the accessibility identifier `settings.spacing.frame`.
- **divider-identifier**: The Pane Divider Spacing control MUST carry the accessibility identifier `settings.spacing.dividers`.
- **content-identifier**: The Pane Content Spacing control MUST carry the accessibility identifier `settings.spacing.content`.

### Keyboard order

- **tab-frame-to-dividers**: Tab out of the last number field of the Frame Spacing control MUST move to the first number field of the Pane Divider Spacing control.
- **tab-dividers-to-content**: Tab out of the last number field of the Pane Divider Spacing control MUST move to the first number field of the Pane Content Spacing control.
- **shift-tab-reverse**: Shift-Tab MUST walk the same chain in the other direction, because linking the next key view sets the back link too.
- **tab-join-after-build**: The panel MUST join the Tab order after all three groups are built.
- **tab-ends-unjoined**: The panel MUST NOT link a key view out of the last number field of the Pane Content Spacing control, nor into the first number field of the Frame Spacing control; those hand-offs are the platform's.

### Help

- **help-topics**: The panel MUST offer exactly four help topics, titled "Frame Spacing", "Pane Divider Spacing", "Pane Content Spacing" and "Everywhere", in that order.
- **help-frame-body**: The Frame Spacing topic MUST say that the spacing is the room between the panes and the tab bars framing them, in points, set per side, and that an arrow pointing into the view adds space.
- **help-divider-body**: The Pane Divider Spacing topic MUST say that each number is the whole gap and not each pane's half, and that a gap of zero still drags because the divider keeps a few points of grab area.
- **help-content-body**: The Pane Content Spacing topic MUST say that a theme's own terminal padding wins for terminals when the theme carries one.
- **help-everywhere-body**: The Everywhere topic MUST say that spacing belongs to the app, not to a window, and that changes apply to all windows as they are made.

### Lifetime and isolation

- **no-archive-init**: The panel MUST NOT support construction from an archive.
- **ui-thread-confined**: The panel MUST be used on the UI thread only.

## Appearance

- **Corner radius**: Not set here; the groups and controls draw their own.
- **Padding**: Not set here; the settings panel base and its group view place the groups.
- **Font**: Not applicable: the panel sets no font; text is drawn by the group titles and the controls.
- **Background**: Not set here; the settings panel base owns the panel background.
- **Foreground/Text**: Group titles "Frame Spacing", "Pane Divider Spacing" and "Pane Content Spacing" above each control.
- **Border**: Not set here.
- **Shadow**: None.
- **Min/Max size**: Not set here; each control's number range is 0 through 40 points by default (the range of the bound control, not this panel).

## States

| State | Appearance change |
|-------|------------------|
| Default | Three titled groups stacked in order, each showing its control at the current setting values |
| Edited | The control and every window using the setting reflect the new value at once |
| Searched | The sidebar search finds the panel through its keywords before it has been opened |
| Pressed | Not applicable: the panel is a container with no pressed styling; its controls handle their own presses. |
| Disabled | Not applicable: the source exposes no enabled flag. |
| Focused | The controls' number fields take focus in Tab order across the three groups, as joined by the panel (see `tab-frame-to-dividers`). |
| Loading | Not applicable: the groups are built synchronously on load; nothing is fetched. |

## Accessibility

- **Role/trait**: Not set in source on the panel; the controls carry their own accessibility.
- **Label requirements**: Each control carries a stable accessibility identifier (see the identifier requirements); the group titles label the groups visually.
- **Announce state changes**: Not applicable: the panel posts no notifications of its own; value changes are the controls' to announce.
- **Keyboard navigation**: Tab and Shift-Tab walk all number fields across the three groups in order (see `tab-frame-to-dividers`, `tab-dividers-to-content`, `shift-tab-reverse`).
- **Minimum tap target**: Not applicable: the panel defines no control of its own; target sizes belong to the spacing control.
- **Minimum contrast ratio**: Not applicable: the panel sets no color.

## Conformance Test Vectors

No test beside the source drives this panel; the spacing control's own tests (layout, accessibility and reset) cover the control. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| spacing-panel-001 | panel-title, panel-icon | Construct the panel and read its descriptor | Title "Spacing"; icon is the rectangle-split-three-columns symbol with no accessibility description |
| spacing-panel-002 | search-keywords, search-before-open | Read the keywords on a panel whose view has never loaded | Exactly the ten keywords in the stated order |
| spacing-panel-003 | three-groups, one-control-per-group, groups-build-on-load | Load the view | Three groups titled in order, each with one spacing control; none exist before load |
| spacing-panel-004 | frame-bound, content-bound | Change the frame control's top value to 12 and the content control's top value to 6 | The frame top setting reads 12 and the content top setting reads 6; neither changes the other |
| spacing-panel-005 | divider-bound | Change the between-columns value to 8 | The between-columns gutter setting reads 8 |
| spacing-panel-006 | live-apply, no-local-store | With a project window open, change a frame value | The open window re-spaces at once; the panel holds no copy of the value |
| spacing-panel-007 | frame-identifier, divider-identifier, content-identifier | Read the three controls' accessibility identifiers | `settings.spacing.frame`, `settings.spacing.dividers`, `settings.spacing.content` |
| spacing-panel-008 | tab-frame-to-dividers, tab-join-after-build | Read the next key view of the frame control's last number field | It is the divider control's first number field |
| spacing-panel-009 | tab-dividers-to-content, shift-tab-reverse | Read the next key view of the divider control's last field and the previous key view of the content control's first field | Next is the content control's first field; previous is the divider control's last field |
| spacing-panel-010 | tab-ends-unjoined | Read the next key view of the content control's last field | No link is set by the panel |
| spacing-panel-011 | help-topics | Read the help content | Four topics in order with titles Frame Spacing, Pane Divider Spacing, Pane Content Spacing, Everywhere |
| spacing-panel-012 | help-divider-body | Read the Pane Divider Spacing body | It states each number is the whole gap and a gap of zero still drags |
| spacing-panel-013 | no-archive-init | Attempt to construct from an archive | The attempt is rejected with a fatal error |

## Edge Cases

- **Null/empty input** (MUST): the panel takes no input; the groups bind to settings that always have defaults, and a bound control refuses to build with an empty settings map (the control's own precondition), so a panel cannot show controls that edit nothing.
- **Boundary values** (MUST): the panel imposes none; each control's range of 0 through 40 points applies. A gap of zero still drags, per the help text.
- **Panel not yet opened** (MUST): the sidebar search sees only the panel's keywords until the view loads (see `search-before-open`).
- **Tab out of the last field** (MUST): control passes to the platform's own key view loop, which is not guaranteed to be meaningful for frame-placed views (see Design Decisions).
- **Theme padding for terminals** (MUST): a theme that carries its own terminal padding overrides the Pane Content Spacing values for terminals only (see `help-content-body`); the panel does not show that override.
- **Concurrent access** (MUST): confined to the UI thread.
- **Error states**: Not applicable: no I/O or throwing operation beyond the controls' own bindings.
- **Offline/disconnected state**: Not applicable: no networking.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Title | string | "Spacing" | Sidebar title |
| Icon | system symbol | rectangle-split-three-columns | Sidebar icon |
| Search keywords | list of strings | ten keywords | Shown to settings search before first open |
| Help topics | four topics | Frame, Pane Divider, Pane Content, Everywhere | Reference prose for the help drawer |
| Frame settings | four edge settings | app-wide frame keys | Bound to the Frame Spacing control |
| Gutter settings | two gutter settings | app-wide gutter keys | Bound to the Pane Divider Spacing control |
| Content settings | four edge settings | app-wide pane content keys | Bound to the Pane Content Spacing control |

## Deep Linking

Not applicable: the panel is reached through the settings window's sidebar; the source defines no URL or route for it.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| Panel title | Spacing | Sidebar title |
| Group title | Frame Spacing | Group above the frame control |
| Group title | Pane Divider Spacing | Group above the divider control |
| Group title | Pane Content Spacing | Group above the content control |
| Help topic titles and bodies | Four topics, see Behavioral Requirements | Help drawer |
| Search keywords | Ten English keywords | Settings search |

- **string-externalization**: NEEDS REVIEW: Not implemented in source. Every title, help body and search keyword is an English string literal, with no localization lookup; evidence needed is the app's localization policy, to settle whether settings panels are in scope for translation.

## Accessibility Options

- **Reduce Motion**: Not applicable: the panel animates nothing.
- **Increase Contrast**: Not applicable: the panel sets no color of its own.
- **Differentiate Without Color**: Not applicable: the panel conveys no state by color.

## Feature Flags

Not applicable: the source contains no feature-flag lookup.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data collected**: Ten integer spacing preferences, edited through the controls.
- **Storage**: The app's user settings store, written by the controls' bindings, not by this panel.
- **Transmission**: Not applicable: nothing leaves the device from this file.
- **Retention**: Until the user settings are cleared or reset through the controls.

## Logging

Not applicable: the source contains no logging call.

## Platform Notes

- **SwiftUI**: Build a `Form` with three `Section`s titled as the groups; each section holds a custom diagram view of four `TextField`s with `.numberFormatter` and `Stepper`s, bound with `@AppStorage` to the ten integer keys, clamped to 0 through 40. Use `.searchable` plus `.searchCompletion` or a `Settings` scene with keyword metadata for the pre-open search. Set `.accessibilityIdentifier` for the three identifiers. SwiftUI focus order is declarative: use `@FocusState` and `.focused` per field in the intended order rather than joining key views.
- **Compose**: Use a `LazyColumn` of three `Card`s titled as the groups, each with four `OutlinedTextField`s using `KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Next)` so the IME Next action walks the fields in order; persist with DataStore Preferences keys. Add the identifiers with `Modifier.testTag("settings.spacing.frame")` and `semantics`. Help topics become an expandable section or a bottom sheet.
- **React/Web**: Render three `<fieldset>`s with `<legend>`s as the group titles, each with `<input type="number" min="0" max="40">` fields in DOM order so Tab and Shift-Tab follow the intended chain by default (no join needed); set `data-testid` or `id` to the three identifiers, and persist to `localStorage` on `input`. Put keywords in a `data-keywords` attribute indexed by the settings search, and the help topics in a `<details>` list.
- **AppKit / UIKit** (source platform): Implemented in `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/SpacingSettingsPanelViewController.swift` as a `@MainActor` public final subclass of the composable settings panel view controller, built with a `SettingsPanelDescriptor` of the title and an `NSImage(systemSymbolName:)`. Controls come from the `SpacingControl.boundToSettings` factory, which preconditions a non-empty settings map for its style, using the `PaneSpacing` edge, gutter and content setting maps. Groups are `ComposableSettings.GroupView`s added with `addGroup` in `viewDidLoad`. The key view loop is set with `nextKeyView` on the first and last number fields because the controls place their fields by frame and the platform's loop works from subview position. `searchKeywords` and `helpContent` are overridden because the base class redeclares them so subclass overrides are reached. `init(coder:)` fails with a fatal error. UIKit has no equivalent settings panel base; use a grouped `UITableViewController` with `UIKeyCommand` Tab handling only if the default focus order is not enough.
- **WinUI 3**: Use a `Page` hosted in a `NavigationView` (or a `SettingsExpander`-based page from the Windows Community Toolkit) with three `SettingsCard` or `Expander` groups headed "Frame Spacing", "Pane Divider Spacing" and "Pane Content Spacing", each holding `NumberBox` controls (`Minimum="0"`, `Maximum="40"`, `SpinButtonPlacementMode="Inline"`) laid out around a diagram `Canvas`. Set `AutomationProperties.AutomationId` to the three identifiers. WinUI's Tab order follows visual tree order, so set `TabIndex` across the three groups in sequence (frame fields, then divider fields, then content fields) and `TabNavigation="Local"` on the page instead of the source's explicit next-key-view join. Persist through `ApplicationData.Current.LocalSettings` and have windows observe changes. Add help topics through a `TeachingTip` or a side `ScrollViewer`, and surface the keywords to the app's settings search through `AutoSuggestBox` metadata.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/SpacingSettingsPanelViewController.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Spacing is split into three groups, each with its own control, instead of one diagram carrying all ten numbers.
**Rationale**: Per the source comment, the groups answer separate questions (room around the panes, between them, inside them), and one diagram carrying all of them made the reader work out which numbers were which.
**Approved**: pending

**Decision**: The panel offers no per-window or per-pane spacing; every window reads the one set of app-wide keys.
**Rationale**: Per the source comment (`dry`), there is exactly one answer to why a pane is spaced as it is, which no per-window control could keep true.
**Approved**: pending

**Decision**: The panel joins the Tab order of the three controls explicitly with next-key-view links.
**Rationale**: Per the source comment, each control answers Tab within itself and hands the key back at either end, and the platform works its key view loop out from where subviews are; these are placed by frame, so left alone Tab out of the bottom number went somewhere that looked like nowhere. Which control follows which is the panel's knowledge.
**Approved**: pending

**Decision**: The panel overrides the search keywords with a fixed list.
**Rationale**: Per the source comment, the sidebar's search only reads the controls of a panel that has been opened, so the panel names what it is about for searches made before anyone opens it.
**Approved**: pending

**Decision**: The panel's English strings are literals without localization lookup.
**Rationale**: No lookup exists in the source; this is recorded as the open question on `string-externalization` pending a localization policy for settings panels.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`keyboard-navigable` and `focus-management` pass because the panel joins the Tab order of its three controls in both directions, so every number field is reachable by keyboard in a defined order. `string-externalization` fails because every user-visible string is a literal (see the open question on `string-externalization`). `separation-of-concerns` passes because the panel owns only naming, grouping, help and Tab order, while values, bindings, clamping and reset live in the spacing control and the pane spacing settings. `unit-test-coverage` fails because no test beside the source builds the panel; the spacing control's own tests cover only the control.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from the macOS `SpacingSettingsPanelViewController` source. |
