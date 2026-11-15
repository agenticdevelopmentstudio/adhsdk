---
id: b3d64a66-ef34-444f-b6b0-449565117d26
title: "Settings Panel"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A two-column settings container: a sidebar of grouped pane tabs beside a detail area, with controlled or uncontrolled selection and optional persistence."
platforms:
  - typescript
  - web
tags:
  - layout
  - navigation
  - settings
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Settings Panel

## Overview

The Settings Panel is the top-level container of the user-settings control family. It lays out a sidebar of pane tabs beside a detail area that shows the body of the selected pane. The CSS namespace for the family is `aws-`, and this component owns the `aws-panel` root class and the `aws-panel__*` element classes.

The component exposes two authoring styles that share one selection model:

- **Compound mode**: the caller supplies children, normally one `SettingsPanel.Sidebar` and several `SettingsPanel.Pane` elements. Each Pane registers itself with the panel and renders its own children only while selected.
- **Data-driven mode**: the caller supplies a non-empty `panes` array of entries (descriptor fields plus a `body`). The panel renders its own sidebar and a detail container with the selected entry's body.

The same selection model serves both styles. Selection is controlled when `selectedId` is supplied and internal otherwise. The selected id can optionally be persisted in browser local storage under a caller-chosen key. The panel auto-selects the first enabled pane when there is no valid selection. The component is a client component (`'use client'`) and ships as `SettingsPanel` with the properties `Sidebar` and `Pane`, plus the exported props type `SettingsPanelProps`.

## Behavioral Requirements

- **compound-mode-children**: The component MUST render its `children` inside the root element when `panes` is absent or empty.
- **data-mode-activation**: The component MUST enter data-driven mode when `panes` is supplied with at least one entry.
- **data-mode-layout**: In data-driven mode the component MUST render the sidebar followed by a detail container with role `tabpanel` and class `aws-panel__detail`.
- **data-mode-ignores-children**: In data-driven mode the component MUST NOT render `children`, even when children are supplied.
- **data-mode-body**: In data-driven mode the detail container MUST contain the `body` of the entry whose `id` equals the selected id, and MUST be empty when no entry matches.
- **data-mode-descriptors**: In data-driven mode the sidebar entries MUST come from the `panes` array with `body` removed, and panes registered by Pane children MUST NOT appear.
- **root-class**: The root element MUST carry the class `aws-panel`, followed by `className` when it is a non-empty string.
- **context-provision**: The component MUST give descendants the selected id, a select function, register and unregister functions, the resolved pane list and the sidebar title.
- **context-required**: `SettingsPanel.Sidebar` and `SettingsPanel.Pane` MUST throw an `Error` with the message `SettingsPanel subcomponents must be rendered inside <SettingsPanel>` when rendered outside a panel.
- **pane-registration**: A Pane MUST register a descriptor made of `id`, `title`, `icon`, `section` and `isDisabled` when it mounts, and MUST register again whenever any of those values change.
- **pane-unregistration**: A Pane MUST unregister its id when it unmounts or before it re-registers.
- **registration-replaces-by-id**: Registering a descriptor whose id is already registered MUST replace the earlier descriptor and place the new one last in the pane list.
- **pane-renders-when-selected**: A Pane MUST render its children only while its id equals the selected id, and MUST render nothing otherwise while staying registered.
- **pane-tabpanel**: A selected Pane MUST render a container with class `aws-panel__detail`, role `tabpanel`, id `aws-pane-` followed by the pane id, and `aria-labelledby` set to `aws-pane-` followed by the pane id and `-tab`.
- **sidebar-nav**: The sidebar MUST render as a `nav` element with the class `aws-panel__sidebar` and the `aria-label` `Settings sections`.
- **sidebar-title**: The sidebar MUST render an `h2` with class `aws-panel__sidebar-title` containing the heading text, where the Sidebar `title` prop wins over the panel `sidebarTitle` prop.
- **sidebar-title-omitted**: The sidebar MUST NOT render a heading element when neither `title` nor `sidebarTitle` is given.
- **sidebar-grouping**: The sidebar MUST group panes by `section`, keeping first-seen order within each group and placing the group of panes without a section first.
- **sidebar-section-title**: The sidebar MUST render a section title element with class `aws-panel__sidebar-section-title` for each named section, and MUST NOT render one for the unsectioned group.
- **sidebar-list-roles**: Each group's list MUST be a `ul` with role `tablist` whose `li` items have role `presentation`.
- **row-element**: Each pane MUST render as a `button` of type `button` with role `tab`, `aria-selected` equal to whether the pane is selected, and `aria-controls` equal to `aws-pane-` followed by the pane id.
- **row-label**: Each row MUST show the pane `title` in a span with class `aws-panel__sidebar-label`.
- **row-icon**: A row MUST render the pane `icon` in a span with class `aws-panel__sidebar-icon` when an icon is given, and MUST NOT render that span otherwise.
- **row-selected-class**: The selected row MUST carry the class `aws-panel__sidebar-row--selected`.
- **row-disabled**: A disabled pane's row MUST carry the `disabled` attribute and the class `aws-panel__sidebar-row--disabled`.
- **row-click-selects**: Clicking an enabled row MUST select that pane.
- **row-click-disabled-ignored**: Clicking a disabled row MUST NOT select the pane and MUST NOT call `onSelect`.
- **initial-selection**: In uncontrolled mode the initial selection MUST be the persisted id when one is readable, otherwise `defaultPaneId`, otherwise none.
- **controlled-selection**: When `selectedId` is not `undefined` the component MUST treat it as the selection and MUST NOT change its internal selection on a click.
- **uncontrolled-selection**: When `selectedId` is `undefined` a click on an enabled row MUST update the internal selection.
- **select-notifies**: A click on an enabled row MUST call `onSelect` with the pane id in both controlled and uncontrolled mode.
- **persist-write**: When `persistKey` is non-empty a click on an enabled row MUST write the pane id to local storage under the key `aws-settings:` followed by `persistKey`, in both controlled and uncontrolled mode.
- **persist-read-once**: The persisted id MUST be read once, when the component first mounts, and not again on later renders.
- **persist-failure-tolerated**: A thrown error from reading or writing local storage MUST be swallowed, with a read failure treated as no persisted value.
- **persist-server-safe**: Reading and writing persistence MUST be skipped when `window` is undefined.
- **auto-select-first-enabled**: When the pane list is non-empty and the selected id is missing, unknown or belongs to a disabled pane, the component MUST select the first enabled pane in list order.
- **auto-select-notifies**: Auto-selection MUST call `onSelect` with the chosen id, in controlled mode as well as uncontrolled mode.
- **auto-select-no-persist**: Auto-selection MUST NOT write to local storage.
- **auto-select-once**: The component MUST NOT call `onSelect` again for the same auto-selected id until the selection has become valid at least once in between.
- **auto-select-none-enabled**: The component MUST NOT select anything when the pane list is empty or every pane is disabled.
- **selection-state-in-context**: The select function in context MUST update internal state only in uncontrolled mode, then call `onSelect`, then write persistence.

## Appearance

- **Corner radius**: Root `0.5rem` (`--aws-radius`); sidebar rows `0.375rem` (`--aws-radius-sm`).
- **Padding**: Sidebar `1rem` vertical × `0.5rem` horizontal; sidebar row `0.45rem` × `0.6rem`; detail area `1.5rem` on all sides (`--aws-content-padding`).
- **Font**: Root uses the themed sans family; sidebar title `1rem`, weight 600; rows `0.875rem`; section titles `0.65rem`, weight 600, uppercase, letter spacing `0.08em`.
- **Background**: Root and detail area use the surface token (`--aws-bg`, default `#0c0c0f`); sidebar uses the raised-surface token (`--aws-surface`, default `#14141a`); hovered row uses `--aws-surface-hover`; selected row uses `--aws-accent-dim`.
- **Foreground/Text**: Root text uses `--aws-text`; section titles use the muted token `--aws-text-muted`; the icon is muted and turns to `--aws-accent` on the selected row.
- **Border**: Root has a 1px solid `--aws-border` border; the sidebar has a 1px right border in `--aws-border`; rows have a 1px transparent border.
- **Shadow**: None.
- **Min/Max size**: Root is `100%` wide, `100%` tall, minimum height `360px`, with overflow hidden; sidebar width `220px` (`--aws-sidebar-width`) and does not shrink; the sidebar and detail area each scroll vertically on overflow; icon box `1rem` × `1rem`.
- **Layout**: Root is a flex row; the sidebar is a flex column with `0.75rem` gap; rows are flex rows with `0.55rem` gap and fill the sidebar width.
- **Theming**: Colors and fonts resolve from the toolkit's `--color-*` and `--font-*` custom properties with literal fallbacks, declared on `.aws-panel` and its sibling family classes and overridable by consumers.

## States

| State | Appearance change |
|-------|------------------|
| Default (row) | Transparent background, transparent border, inherited text color |
| Hover (row, enabled) | Background becomes `--aws-surface-hover`; the hover rule is more specific than the selected rule, so hovering the selected row also shows the hover background in place of the accent tint |
| Selected (row) | Background becomes `--aws-accent-dim`; icon turns to `--aws-accent`; `aria-selected` is true |
| Focused (row) | Keyboard focus shows a 2px solid `--aws-accent` outline with 1px offset (`focus-visible` only) |
| Disabled (row) | Opacity `0.5`, `not-allowed` cursor, no hover background, `disabled` attribute set |
| No selection | Detail area is empty (data-driven mode) or no Pane renders (compound mode); occurs only when no pane is enabled |
| Pressed | Not applicable: the stylesheet defines no active or pressed style for rows. |
| Loading | Not applicable: the panel renders synchronously from props and registrations and has no loading state. |

## Accessibility

- **tab-semantics**: The sidebar rows carry the tab pattern: role `tab` on buttons, role `tablist` on the list, role `presentation` on list items and role `tabpanel` on the detail area. The sidebar is wrapped in a `nav` landmark labelled `Settings sections`.
- **selected-state**: Each row exposes its selection through `aria-selected`; a disabled row is exposed through the native `disabled` attribute.
- **focus-indicator**: Rows show a 2px accent outline on `focus-visible`.
- **tab-order**: Every enabled row is a native `button`, so it is reachable in document order with Tab and activates with Enter or Space. Disabled rows are skipped.
- **arrow-key-navigation**: NEEDS REVIEW: Not implemented in source. The rows use role `tablist` and `tab` but no handler moves selection or focus with arrow, Home or End keys, and there is no roving tabindex. Evidence that would settle it: the ARIA tabs pattern requirement for the target audience, and a keyboard test of the rendered panel.
- **tab-id-linkage**: NEEDS REVIEW: Not implemented in source. Each row sets `aria-controls` to `aws-pane-` plus the pane id and a selected Pane sets `aria-labelledby` to `aws-pane-` plus the pane id plus `-tab`, but no row sets an `id`, so the labelled-by target never exists. In data-driven mode the detail container has no `id` either, so `aria-controls` points at nothing. Evidence that would settle it: an accessibility-tree inspection and an audit with a screen reader.
- **min-tap-target**: NEEDS REVIEW: Not implemented in source. The row height comes from `0.45rem` vertical padding around `0.875rem` text and no minimum target size is declared, so whether it meets 44×44pt on touch devices or the 24×24 CSS pixel WCAG 2.2 minimum cannot be decided from the source. Evidence that would settle it: measured row height at the supported root font sizes.
- **contrast**: NEEDS REVIEW: Not implemented in source. Text, muted text and the selected-row tint come from themable color tokens, so whether they meet the WCAG 2.1 AA ratios of 4.5:1 for text and 3:1 for the focus outline depends on the theme mounted. Evidence that would settle it: a contrast measurement against each shipped theme.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-panel-001 | compound-mode-children, pane-renders-when-selected, auto-select-first-enabled | Compound example with General, Notifications and a disabled Security pane; no `selectedId`, no `defaultPaneId` (test: "selects the first enabled pane by default") | `general body` is in the document; `notifications body` is not |
| settings-panel-002 | row-click-selects, uncontrolled-selection | Same example; click the tab named Notifications (test: "switches pane when sidebar row is clicked") | `notifications body` is shown and `general body` is gone |
| settings-panel-003 | sidebar-grouping, sidebar-section-title, sidebar-nav | Same example; inspect the navigation named `Settings sections` (test: "groups panes by section, unsectioned first") | Exactly one section title, `Preferences`; rows in order General, Notifications, Security |
| settings-panel-004 | row-disabled, row-click-disabled-ignored | Same example; click the Security tab (test: "disables a pane and prevents selection") | The tab is disabled; `security body` never appears |
| settings-panel-005 | controlled-selection, select-notifies | `selectedId="notifications"` with an `onSelect` spy; click the General tab (test: "respects controlled selectedId and calls onSelect on click") | `onSelect` is called with `general`; `notifications body` is still shown |
| settings-panel-006 | persist-write, persist-read-once, initial-selection | `persistKey="t1"`; click Notifications; unmount; mount again with the same key (test: "persists selection to localStorage when persistKey is set") | Storage item `aws-settings:t1` equals `notifications`; the second mount shows `notifications body` |
| settings-panel-007 | data-mode-activation, data-mode-layout, data-mode-body, data-mode-descriptors | `panes` with entries A and B, `sidebarTitle="Account"`, no children; click tab B (test: "renders panes via the data-driven API") | `body a` is shown first; after the click `body b` is shown |
| settings-panel-008 | uncontrolled-selection, select-notifies | Compound panel with panes X and Y and an `onSelect` handler; click tab Y (test: "uncontrolled mode tracks internal selection across clicks") | `y body` is shown |
| settings-panel-009 | context-required | Render `SettingsPanel.Pane` with no panel ancestor | Rendering throws an Error with message `SettingsPanel subcomponents must be rendered inside <SettingsPanel>` (derived from the source; no test beside the source covers it) |
| settings-panel-010 | data-mode-ignores-children | `panes` with entry A and a child element `child text` | `child text` is not in the document; `body a` is |
| settings-panel-011 | auto-select-first-enabled, auto-select-notifies, auto-select-no-persist | Controlled `selectedId="gone"`, panes A (enabled) and B, `persistKey="t2"`, an `onSelect` spy | `onSelect` is called once with `A`; storage item `aws-settings:t2` is absent |
| settings-panel-012 | auto-select-none-enabled | Panes A and B both `isDisabled` | No pane body renders and `onSelect` is not called |
| settings-panel-013 | persist-failure-tolerated | Local storage read and write both throw; `persistKey="t3"`, `defaultPaneId="b"`; click tab A | No error escapes; initial selection is `b`; A becomes selected |
| settings-panel-014 | persist-write, controlled-selection | Controlled `selectedId="a"`, `persistKey="t4"`; click tab B | Storage item `aws-settings:t4` equals `b`; selection stays `a` |
| settings-panel-015 | sidebar-title, sidebar-title-omitted | `Sidebar` with `title="Local"` inside a panel with `sidebarTitle="Global"`; then a panel with neither | The first renders one `h2` reading `Local`; the second renders no `h2` |
| settings-panel-016 | row-icon, row-label | Pane with `icon` set and a pane without | The first row has a span `aws-panel__sidebar-icon`; the second row does not |
| settings-panel-017 | registration-replaces-by-id | Compound panes P, Q, R; change P's `title` | P's row moves after R in the sidebar |
| settings-panel-018 | auto-select-once | Controlled `selectedId="gone"`, parent never updates, `onSelect` spy; rerender twice | `onSelect` is called once, not on each render |

## Edge Cases

- **Null and empty input, empty panes**: With `panes` of length 0 the component MUST behave as compound mode and render children. With no panes at all the sidebar is empty, no selection is made and the detail area is empty.
- **Null and empty input, empty persist key**: An empty or undefined `persistKey` MUST disable both reading and writing.
- **Null and empty input, absent default**: With no `defaultPaneId` and nothing persisted the initial selection is none and auto-selection MUST choose the first enabled pane.
- **Boundary values, all panes disabled**: The component MUST leave the selection unset and MUST NOT call `onSelect`.
- **Boundary values, single pane**: A single enabled pane MUST be auto-selected and rendered.
- **Boundary values, duplicate ids**: In compound mode a second registration with the same id replaces the first. In data-driven mode the array is used as given, so duplicate ids render duplicate rows with the same React key; the source defines no handling for that.
- **Stale selection, persisted id no longer exists**: A persisted or default id with no matching pane MUST be replaced by the first enabled pane, and the replacement is not written back to storage.
- **Selected pane becomes disabled or removed**: The component MUST auto-select the first enabled pane and call `onSelect`.
- **Controlled selection pointing at a disabled pane in data-driven mode**: The detail area looks the entry up by id without checking `isDisabled`, so the disabled pane's body renders while the auto-selection effect asks the parent to move away; in compound mode the selected disabled Pane also renders its children. A parent that ignores `onSelect` keeps seeing that body.
- **Concurrent access**: Registration and unregistration use functional state updates, so several Panes mounting in the same commit all register. Auto-selection runs in an effect after render, so one extra render can show the stale selection first.
- **Error states, storage unavailable or full**: Storage errors MUST be swallowed silently; selection still works but does not persist, and the user receives no notice.
- **Error states, subcomponent outside the panel**: `Sidebar` and `Pane` MUST throw the Error described in context-required.
- **Controlled parent that never updates**: Clicks still call `onSelect` and write persistence, but the displayed pane does not change.
- **Compound mode without a Sidebar child**: No sidebar is rendered, because compound mode only renders what the caller supplies.
- **Server rendering**: Persistence is skipped when `window` is undefined, so server output uses `defaultPaneId`, and the effect-driven registration means compound-mode sidebars are empty on the first render pass.
- **Offline or disconnected state**: Not applicable: the component performs no network calls and keeps its state in memory and in local storage.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | `ReactNode` | none | Compound-mode content; ignored when `panes` is non-empty |
| `panes` | array of pane entries | none | Data-driven entries with `id`, `title`, optional `icon`, optional `section`, optional `isDisabled` and a `body` |
| `defaultPaneId` | `string` | none | Initial selection in uncontrolled mode when nothing is persisted |
| `selectedId` | `string` | none | Makes selection controlled when not `undefined` |
| `onSelect` | `(id: string) => void` | none | Called on user selection and on auto-selection |
| `persistKey` | `string` | none | Enables local-storage persistence under `aws-settings:<persistKey>` |
| `className` | `string` | none | Extra class on the root element |
| `sidebarTitle` | `string` | none | Heading shown at the top of the sidebar |
| `Sidebar` `title` | `string` | none | Heading override for a `SettingsPanel.Sidebar` element |
| `Pane` props | `id`, `title`, `icon`, `section`, `isDisabled`, `children` | `id` and `title` required | Descriptor fields for a `SettingsPanel.Pane` element, plus its body |

## Deep Linking

Not applicable: the component reads and writes no URL. Selection lives in props, internal state or local storage, as `SettingsPanel.tsx` shows, and a caller that wants a URL-addressable pane uses `selectedId` and `onSelect`.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hard-coded) | `Settings sections` | `aria-label` of the sidebar navigation |
| caller-supplied | pane `title`, section name, `sidebarTitle` | Visible text, supplied by the caller |

- **no-hardcoded-strings**: NEEDS REVIEW: Not implemented in source. The `Settings sections` label is a literal in the component and cannot be replaced by a prop. Evidence that would settle it: the localization policy for built-in accessibility labels in this control family.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the panel's styles define no transition or animation. |
| Increase Contrast | The panel defines no `prefers-contrast` or forced-colors rules; colors come only from themable tokens, so any response is the theme's. |
| Differentiate Without Color | The selected row is shown by a tinted background and an accent-colored icon, and also exposed as `aria-selected`; the row has no icon-independent visual marker, so a pane without an icon is distinguished visually by tint only. |

## Feature Flags

Not applicable: `SettingsPanel.tsx` reads no flags and has no gated behavior.

## Analytics

Not applicable: the component emits no events; callers observe selection through `onSelect`.

## Privacy

- **Data collected**: The id of the last selected pane, only when `persistKey` is set.
- **Storage**: Browser local storage under `aws-settings:<persistKey>`; it is not encrypted.
- **Transmission**: None; the value never leaves the browser.
- **Retention**: Until the caller or user clears site storage; the component never deletes it.

## Logging

Not applicable: the component logs nothing; storage errors are caught and discarded without a log line.

## Platform Notes

- **SwiftUI**: Start from `NavigationSplitView` with a `List` of rows selected through a `selection` binding for the sidebar and the selected pane's body as the detail column; section grouping maps to `Section` headers and disabled rows to `.disabled(true)`. On macOS the idiomatic form is the `Settings` scene with a `TabView`. Controlled versus uncontrolled selection maps to a `Binding` versus `@State`, and persistence to `@SceneStorage` or `@AppStorage` keyed by `persistKey`. Keyboard navigation and accessibility roles come from the system list, so the arrow-key gap in the web source does not carry over.
- **Compose**: Start from a `Row` with a `NavigationRail` or a `LazyColumn` of `NavigationDrawerItem` entries beside a content `Box`; use `rememberSaveable` for the selected id (persistence across restarts needs DataStore keyed by `persistKey`). Section titles are non-clickable header items; a disabled pane maps to `enabled = false`. Material 3 supplies the 48dp minimum touch target and selection semantics through `Modifier.selectable` with `Role.Tab` where the tab pattern is wanted. Auto-selection is a `LaunchedEffect` keyed on the pane list.
- **React/Web**: Implemented in `packages/web/packages/controls/src/user-settings/components/SettingsPanel.tsx` with types in `types.ts` and context in `context.ts` beside it, and styles in `styles.css` using the `aws-panel` classes. It is a `'use client'` component; consumers import it from the user-settings index together with the `SettingsPanelProps` type. Compound mode relies on effect-driven registration, so a server render of compound mode has an empty sidebar. Tests are in `__tests__/SettingsPanel.test.tsx`.
- **AppKit / UIKit**: On AppKit start from `NSSplitViewController` with a source-list `NSOutlineView` (`selectionHighlightStyle = .sourceList`, group rows for sections) and an `NSTabViewController` or a container view controller for the detail, or `NSTabViewController` with `tabStyle = .toolbar` for a preferences window. On UIKit use `UISplitViewController` with a `UICollectionView` list using `UICollectionLayoutListConfiguration` and sidebar appearance; disabled rows return false from `shouldSelectItemAt`. Selection is delegate and data-source driven rather than a prop, and persistence uses `UserDefaults`.
- **WinUI 3**: Start from `NavigationView` with `PaneDisplayMode="Left"` and `SelectionChanged` driving a `ContentControl` or `Frame` for the detail; `NavigationViewItemHeader` renders the section titles and `NavigationViewItemSeparator` separates groups, and `NavigationViewItem` takes the icon through its `Icon` property and the label through `Content`. Disabled panes use `IsEnabled="False"`, which `NavigationViewItem` renders with the Disabled visual state. The controlled and uncontrolled pair maps to a `SelectedItem` binding (`Mode=TwoWay`) versus unbound selection, and `OpenPaneLength="220"` matches the 220px sidebar. A `TabView` or `Pivot` is the alternative when the tab pattern is wanted, but `NavigationView` supplies the left-sidebar keyboard model (arrow keys between items) that the web source lacks. Persist the selected tag with `ApplicationData.Current.LocalSettings` keyed by `persistKey`, and apply `FocusVisualPrimaryBrush` to match the accent focus ring.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/SettingsPanel.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Support compound mode and data-driven mode in one component, with `panes` taking precedence and `children` ignored when `panes` is non-empty.
**Rationale**: A single selection model serves both authoring styles, and the data-driven mode is the simpler call site for static panes. The source comment says children "override" in data-driven mode, but the code never renders them, so the recipe records the behavior and not the comment.
**Approved**: pending

**Decision**: Panes register themselves through context in compound mode instead of the panel scanning its children.
**Rationale**: The sidebar can sit anywhere in the tree and Panes can be wrapped by other components. The cost is that the sidebar fills in after the first effect pass, and a pane that re-registers moves to the end of the list.
**Approved**: pending

**Decision**: Persist the selected id in local storage under a caller-supplied key, read once at mount, written only on user selection, and silent on any storage error.
**Rationale**: Remembering the last pane should never break the panel when storage is disabled or full. Auto-selection is not written back because it is a correction and not a user choice.
**Approved**: pending

**Decision**: Auto-select the first enabled pane whenever the current selection is missing or disabled, guarded so it calls `onSelect` once per target id.
**Rationale**: The guard stops an infinite loop when a controlled parent does not apply the change. It also means a controlled parent that never updates keeps a stale selection while still being told once.
**Approved**: pending

**Decision**: Use the tab roles (`tablist`, `tab`, `tabpanel`) on a sidebar of buttons inside a `nav` landmark.
**Rationale**: It exposes selection state to assistive technology. The source stops short of the full tabs pattern (no arrow-key handling, dangling id references), which is why the open questions on `arrow-key-navigation` and `tab-id-linkage` exist.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` is partial because one file holds selection state, persistence, pane registration, auto-selection and rendering for the root, the sidebar and the pane, although context and types are split into their own modules. `unit-test-coverage` passed because `SettingsPanel.test.tsx` has a passing test for every vector, settings-panel-001 to settings-panel-018. `keyboard-navigable` is partial because every enabled row is a native button reachable with Tab, yet the tab roles carry no arrow-key behavior. `semantic-markup` is partial because the navigation landmark, tab roles and `aria-selected` are present while the `aria-controls` and `aria-labelledby` targets are missing. `no-hardcoded-strings` fails because the sidebar navigation label is a literal in the component.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (SettingsPanel.test.tsx, 18 of 18 vectors); unit-test-coverage now passed. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
