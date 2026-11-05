---
id: 24f42d31-dd5f-4e1e-a95c-3327e136ad46
title: Settings Panel
domain: adhsdk://recipes/settings-panel
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Multi-pane settings interface with sidebar navigation and grouped section
  support
platforms:
- typescript
- web
tags:
- settings
- navigation
- tabbed-interface
depends-on: []
related:
- adhsdk://recipes/tabs
- adhsdk://recipes/split-view-control
- adhsdk://recipes/view-tab-bar
references: []
approved-by: ''
approved-date: ''
---

# Settings Panel

## Overview

The Settings Panel is a tabbed navigation component that presents multiple settings panes in a sidebar-and-detail layout. It organizes panes into optional sections, auto-manages pane selection, and supports both controlled (parent-managed state) and uncontrolled (component-managed state) modes. A typical use case is an application settings or preferences interface where users navigate between different setting categories.

## Behavioral Requirements

- **sidebar**: The component MUST render a navigation sidebar containing all provided panes as selectable items.
- **detail-area**: The component MUST render a detail area adjacent to the sidebar that displays the body content of the currently selected pane.
- **section-grouping**: The component MUST group panes in the sidebar by their optional `section` property. Panes without a section MUST appear first, followed by grouped sections in insertion order.
- **section-headers**: The component MUST render a visible header for each section whose name is a non-empty string.
- **controlled-selection**: The component MUST accept a `selectedId` prop; when provided, this prop MUST control which pane is displayed, overriding internal state.
- **uncontrolled-selection**: The component MUST manage pane selection internally when `selectedId` is not provided.
- **selection-precedence**: When resolving which pane is selected, the component MUST apply this order: the controlled `selectedId` prop (if provided) takes precedence over everything else; otherwise a persisted selection (`persistKey`) takes precedence over `defaultPaneId`; `defaultPaneId` takes precedence over auto-selecting the first enabled pane. If the pane identified by `selectedId`, the persisted value, or `defaultPaneId` does not exist or is disabled, the component falls through to auto-selecting the first enabled pane (see **auto-select-first-pane**); in controlled mode this fallback invokes `onSelect` but MUST NOT change the displayed pane, since only the parent-owned `selectedId` controls display.
- **auto-select-first-pane**: The component MUST automatically select the first enabled (non-disabled) pane if no pane is currently selected or if the currently selected pane is not in the pane list or is disabled.
- **onselect-callback**: The component MUST invoke the `onSelect` callback with the pane id whenever a pane is selected, regardless of controlled or uncontrolled mode.
- **selected-pane-indicator**: The component MUST mark the selected pane's tab with `aria-selected="true"` and apply a distinct visual indicator (see the React/Web platform note and Appearance for the reference class name).
- **disabled-panes**: The component MUST accept an `isDisabled` flag on each pane; disabled panes MUST NOT be selectable and MUST render with a distinct disabled visual treatment (see the React/Web platform note and Appearance for the reference class name).
- **disabled-pane-selection-guard**: The component MUST NOT allow selection of panes where `isDisabled` is true. Click handlers MUST guard against disabled state.
- **pane-icon**: The component MUST render an icon element if the pane provides an `icon` property; the icon content MUST come from the icon property as-is, unmodified.
- **pane-title**: The component MUST render the pane `title` text as a visible label in the sidebar.
- **persist-selection**: If a `persistKey` prop is provided, the component MUST persist the selected pane id to a per-key persisted store whenever a pane is selected (see the React/Web platform note for the storage key format).
- **restore-persisted-selection**: The component MUST restore and apply the persisted pane id on mount if `persistKey` is provided and a stored value exists, subject to **selection-precedence**.
- **persist-failure-handling**: The component MUST silently ignore any errors when reading from or writing to the persisted store (e.g., due to quota exceeded or disabled storage).
- **pane-registration**: The component MUST provide a context that allows child pane components to register and unregister themselves dynamically.
- **registered-panes-fallback**: When no explicit `panes` prop is provided, the component MUST use panes registered via the context to populate `SettingsPanel.Sidebar`'s rendering.
- **child-mode-rendering**: When in child-mode (no `panes` prop), the component MUST render its `children` directly instead of generating a default sidebar and detail layout; a caller that wants a sidebar in child-mode MUST include `SettingsPanel.Sidebar` explicitly among those children (see **registered-panes-fallback**).
- **tab-panel-linkage**: Each tab button in the sidebar MUST carry an attribute linking it to its panel's id (see the React/Web platform note for the reference attribute/id pattern).
- **panel-labelledby**: Each detail panel rendered by a child pane sets an `aria-labelledby` attribute of the form `<tab-id>-tab`, intended to reference its controlling tab (see the React/Web platform note) — but no tab `<button>` is ever given that id, or any id, so the reference is dangling: it resolves to no element and the tabpanel's accessible name is empty. This is a defect, not a working linkage; see the **Compliance** screen-reader-support entry.

## Appearance

- **Sidebar width**: Not specified in source; platform-dependent.
- **Sidebar background**: Not specified in source; platform-dependent.
- **Detail area background**: Not specified in source; platform-dependent.
- **Pane item padding**: Not specified in source; platform-dependent.
- **Font**: Not specified in source; platform-dependent.
- **Icon spacing**: Icon rendered inline in a `{{app_prefix}}-panel__sidebar-icon` span adjacent to label text.
- **Section header styling**: Rendered as a div with class `{{app_prefix}}-panel__sidebar-section-title`; no default styling specified.
- **Selected state indicator**: Applied via `{{app_prefix}}-panel__sidebar-row--selected` class; visual appearance is CSS-driven.
- **Disabled state styling**: Applied via `{{app_prefix}}-panel__sidebar-row--disabled` class; platform-specific rendering.

## States

| State | Appearance change |
|-------|------------------|
| Default (unselected) | Rendered without `--selected` class; `aria-selected="false"` |
| Selected | Rendered with `--selected` class; `aria-selected="true"` |
| Disabled | Rendered with `--disabled` class; button has `disabled` attribute; click handler blocked |
| Grouped in section | Rendered within a section container with section header |
| Unsectioned | Rendered before all sectioned panes without a section header |

## Accessibility

- **Role**: The sidebar is a `<nav>` with `aria-label="Settings sections"`. Each section's panes are wrapped in a `role="tablist"` container. Each pane item is a `<button>` with `role="tab"`. Each detail area is a `<div>` with `role="tabpanel"`.
- **Label requirements**: Each tab button MUST have visible text via the pane `title`. The nav MUST have an `aria-label`. In child-mode, each tabpanel carries an `aria-labelledby` attribute intended to reference its controlling tab, but the reference is dangling (see **panel-labelledby**): the tab is never given the id it points at, so the tabpanel gets no accessible name from this mechanism. In data-mode, the auto-rendered tabpanel carries neither `id` nor `aria-labelledby` at all.
- **Keyboard navigation**: Users can tab to each tab button and activate with Enter/Space. Disabled buttons are skipped by tab order.
- **Announce selected state**: Screen readers announce `aria-selected="true"` when a pane is selected.
- **Minimum touch target**: Not specified in source. Platform guidelines MUST be followed (44×44pt on iOS, 48×48dp on Android, 40×40px on web per WCAG).
- **Icon semantics**: Icons MUST NOT be the only indicator of pane purpose. A visible `title` label MUST always be present.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| panel-001 | sidebar | `panes=[{id:'a',title:'A'}]` | Sidebar renders with one selectable item labeled 'A' |
| panel-002 | detail-area | `panes=[{id:'a',title:'A',body:'Content'}]` with selection='a' | Detail area renders with text 'Content' |
| panel-003 | section-grouping | `panes=[{id:'a',title:'A',section:null},{id:'b',title:'B',section:'Group1'}]` | Pane 'A' appears first; 'B' appears under 'Group1' header |
| panel-004 | controlled-selection | `panes=[...], selectedId='a', onSelect=jest.fn()`; user clicks pane 'b' | `onSelect('b')` is called, but the displayed pane stays 'a' until the parent updates `selectedId` |
| panel-005 | uncontrolled-selection | `panes=[...]` without `selectedId` | Component manages internal state; first pane auto-selected |
| panel-006 | auto-select-first-pane | `panes=[{id:'a',isDisabled:true},{id:'b',isDisabled:false}]` | Pane 'b' is auto-selected, not 'a' |
| panel-007 | selected-pane-indicator | Selection is pane 'a' | Tab for pane 'a' has `aria-selected="true"` and the selected visual indicator |
| panel-008 | disabled-panes | `panes=[{id:'a',isDisabled:true}]` | Pane 'a' renders with the disabled visual treatment and a disabled control |
| panel-009 | persist-selection | `persistKey='my-settings'`, uncontrolled; user clicks pane 'a' | The persisted store's `my-settings` entry becomes `'a'` |
| panel-010 | restore-persisted-selection | Persisted store has `my-settings='b'`, `panes=[{id:'a'},{id:'b'}]` | On mount, pane 'b' is selected |
| panel-011 | persist-failure-handling | Persisted-store read throws or quota exceeded | Component still renders and functions; no error thrown |
| panel-012 | pane-registration | Child `SettingsPanelPane` mounts and registers | Pane appears in sidebar immediately |
| panel-013 | child-mode-rendering | `children=<div>Custom</div>` without `panes` | Custom div is rendered; default sidebar/detail not rendered |
| panel-014 | tab-panel-linkage | Pane with id='a' selected | Tab button's linking attribute references pane 'a's panel id |
| panel-015 | onselect-callback | User selects pane 'b' | `onSelect('b')` is called exactly once |
| panel-016 | section-headers | `panes=[{id:'a',title:'A',section:'Group1'}]` | A visible header reading 'Group1' renders above pane 'A' |
| panel-017 | pane-icon | `panes=[{id:'a',title:'A',icon:<Icon/>}]` | The icon renders adjacent to the label |
| panel-018 | pane-title | `panes=[{id:'a',title:'Display Name'}]` | The sidebar row's visible label reads 'Display Name' |
| panel-019 | disabled-pane-selection-guard | `panes=[{id:'a',isDisabled:true},{id:'b'}]`; user clicks pane 'a' | `onSelect` is not called for 'a'; selection unchanged |
| panel-020 | registered-panes-fallback | No `panes` prop; two `SettingsPanel.Pane` children register, `SettingsPanel.Sidebar` included among children | Sidebar shows both registered panes |
| panel-021 | selection-precedence (`defaultPaneId`) | `panes=[{id:'a'},{id:'b'}]`, `defaultPaneId='b'`, uncontrolled, no persisted value | Pane 'b' is selected on mount |
| panel-022 | panel-labelledby | Child-mode pane with id='a' selected | The panel's `aria-labelledby` is `aws-pane-a-tab`, but no element carries that id (the tab button has no id); the reference is dangling and the panel's accessible name is empty |

## Edge Cases

- **No panes provided**: When `panes` array is empty or not provided and no child panes register, the component renders an empty sidebar and no detail area. No error is thrown.
- **All panes disabled**: When all panes have `isDisabled: true`, no pane is auto-selected. Attempting to click any pane has no effect.
- **Current selection no longer exists**: When `panes` changes and the currently selected pane id is not in the new list, the first enabled pane is auto-selected.
- **Persisted or default selection now disabled or missing**: The same fallback governs `persistKey`'s stored id and `defaultPaneId`: if the pane either one points to does not exist, or is disabled, on mount, the component falls through to the first enabled pane per **selection-precedence** instead of using the stale or invalid value.
- **Controlled mode with missing pane**: When `selectedId` references a pane that does not exist, no pane is displayed. The detail area is empty but still rendered.
- **Persisted store unavailable**: In SSR or private browsing contexts where the persisted-store access throws, errors are silently caught. Persistence is skipped but the component functions normally.
- **Null section name**: Panes with `section: null` or `section: undefined` are treated identically as unsectioned and grouped together at the start.
- **Empty section name**: Panes with `section: ''` (empty string) are NOT coalesced into the unsectioned group — only `null`/`undefined` are — so they form their own group, separate from unsectioned panes. Because a header only renders for a non-empty section name, that group renders with no visible header at all, which can look like a stray, unlabeled cluster of rows.
- **Duplicate pane ids in `panes`**: The component does not deduplicate the `panes` prop (only registered child panes are deduplicated by id). Entries sharing an id all render as separate sidebar rows; any lookup by id (auto-selection, controlled selection, the detail body) resolves to the first matching entry.
- **Pane without icon**: When a pane does not provide an `icon` property, the icon element is not rendered. Only the label is shown.
- **Rapid selection changes**: When `selectPane` is called multiple times in quick succession, each call invokes `onSelect` and updates the persisted store. The most recent call wins.
- **Child Pane re-registration**: When a child `SettingsPanelPane` component re-registers with different props (e.g., title changes), the pane is removed and re-added, which moves it to the end of the registration order (see Design Decision 4); sidebar position is not preserved across a re-registration.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `panes` | `SettingsPaneEntry[]` | `undefined` | Array of pane descriptors for data-driven mode. Each entry has `id`, `title`, `icon?`, `section?`, `isDisabled?`, `body?`. Mutually exclusive with child-mode. |
| `defaultPaneId` | `string` | `undefined` | The pane id to select on mount if no persisted selection exists and not in controlled mode. |
| `selectedId` | `string` | `undefined` | The controlled pane id. When provided, overrides internal state and auto-selection. |
| `onSelect` | `(id: string) => void` | `undefined` | Callback invoked whenever a pane is selected, in both controlled and uncontrolled modes. |
| `persistKey` | `string` | `undefined` | If provided, the selected pane id is persisted under a key derived from `persistKey` (see the React/Web platform note). |
| `className` | `string` | `undefined` | Additional CSS class to add to the root element alongside the base panel class. |
| `sidebarTitle` | `string` | `undefined` | Optional title displayed at the top of the sidebar. Can be overridden per render via `SettingsPanelSidebar`'s `title` prop. |

## Deep Linking

Not applicable: This component is a UI shell that does not intrinsically handle deep linking. Applications using this component MUST implement their own URL-to-pane-selection mapping by listening to `onSelect` and storing/restoring state as needed.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `settings_panel.nav_label` | "Settings sections" | Accessible label for the sidebar navigation |
| (caller-provided) | — | Each pane `title` is supplied by the caller and must already be localized before it is passed in |
| (caller-provided) | — | The `sidebarTitle` prop is supplied by the caller and must already be localized before it is passed in |
| (caller-provided) | — | Each pane `section` name is supplied by the caller and must already be localized before it is passed in |

## Accessibility Options

- **Reduce Motion**: Not applicable. This component does not animate state transitions; selection changes are instantaneous visual updates.
- **Increase Contrast**: The component does not define any color tokens of its own — the classes it applies (see the React/Web platform note) are unstyled, so honoring a high-contrast or increased-contrast mode is left entirely to the CSS the consumer supplies; there is nothing in the source to verify against.
- **Differentiate Without Color**: The selected state's CSS class and its `aria-selected` attribute both target the same element, but `aria-selected` is an assistive-technology signal, not a visual one. The source defines no CSS, so a non-color visual indicator (weight, marker, background shape, etc.) for the selected row is not guaranteed by the component itself; it depends on the consumer's stylesheet.

## Feature Flags

| Flag Key | Default | Description |
|----------|---------|-------------|
| (none specified in source) | — | This component does not check feature flags; flag control is the caller's responsibility. |

## Analytics

| Event | Properties | When |
|-------|-----------|------|
| (not implemented) | — | The component does not emit analytics events; event tracking is the caller's responsibility via the `onSelect` callback. |

## Privacy

- **Data collected**: None. The component does not collect user data.
- **Storage**: Selection persistence (if `persistKey` is provided) is written to the browser's localStorage as a plain string (the pane id).
- **Transmission**: No data is transmitted. Selection state remains on-device only.
- **Retention**: Persisted selection remains in localStorage indefinitely until explicitly cleared or the user clears browser storage.

## Logging

Subsystem: (not specified in source) | Category: (not specified in source)

Not applicable: This component does not emit log messages. Application code integrating this component may add logging via the `onSelect` callback.

## Platform Notes

- **React/Web**: The source is a React functional component using hooks (`useState`, `useContext`, `useCallback`, `useMemo`, `useRef`, `useEffect`). It provides a compound component pattern via `Object.assign`, with `SettingsPanel.Sidebar` and `SettingsPanel.Pane` as sub-components. Each pane's optional `icon` accepts a `ReactNode` (arbitrary JSX), rendered unmodified. Selected/disabled rows use the classes `{{app_prefix}}-panel__sidebar-row--selected` / `{{app_prefix}}-panel__sidebar-row--disabled` (the reference implementation uses the literal prefix `aws`); each tab button sets `aria-controls="{{app_prefix}}-pane-${paneId}"`, and each child-mode panel sets `id="{{app_prefix}}-pane-${paneId}"` and `aria-labelledby="{{app_prefix}}-pane-${paneId}-tab"`. Persisted selection is written to `localStorage` under the key `{{app_prefix}}-settings:${persistKey}`. Styling is class-based; CSS must be provided separately. Context (`SettingsPanelContext`) is used for state sharing between root, sidebar, and child panes. Note: in data-driven mode (`panes` prop), the root's own auto-rendered detail container does not currently set an `id` or `aria-labelledby` — that wiring exists only via `SettingsPanel.Pane` in child-mode.
- **SwiftUI**: An equivalent implementation would use `NavigationSplitView` for the sidebar-detail layout (or the built-in `Settings` scene for a top-level app settings window), a `@State`/`@StateObject` for selected pane id and pane registration, and `List` rows grouped with `Section` for the sidebar. Persistence would use `@AppStorage` for the persisted-selection equivalence.
- **Compose**: An equivalent would use `rememberSaveable` for persistent selection state, a `mutableStateListOf` for pane registration, and `LazyColumn` for the sidebar list. Grouping by section would be handled by grouping the pane list before rendering. Selected state would drive `NavigationRail` or a custom sidebar composable.
- **AppKit / UIKit**: On macOS, an equivalent would use `NSSplitViewController` with a source-list-style sidebar (`NSOutlineView`/`NSTableView`), or `NSTabViewController` configured in toolbar style for a simpler tabbed settings window. On iOS, a container view controller would manage a sidebar list and a detail container. Selection state would be tracked as a published property in a view model. Pane registration would use a delegate or observer pattern for dynamic panes. Persistence would use `UserDefaults` keyed to the persist key.
- **WinUI 3**: An equivalent would use a XAML split pane control (`SplitView`) or a two-column `Grid` layout. The sidebar would be a `ListView` or `NavigationView` with pane items bound via a collection view model. Selection state would be a property in the code-behind or ViewModel. Grouping by section would be handled via `CollectionViewSource` with grouping enabled. Persistence would use `ApplicationData.Current.LocalSettings` or `StorageFile`. The detail area would be a `Frame` or `ContentPresenter` bound to the selected pane's body content.

## Design Decisions

1. **Decision**: The component automatically selects the first non-disabled pane whenever no pane is selected or the current selection is missing or disabled; in controlled mode this only invokes `onSelect` — it does not alter the displayed pane, since **selection-precedence** gives the controlled `selectedId` prop final say over what is shown.
   **Rationale**: This prevents a state where no content is displayed, ensuring a valid pane is always active in uncontrolled mode and that the parent is notified in controlled mode, without letting the component override parent-controlled display.
   **Approved**: pending

2. **Decision**: Panes without a section are grouped at the start of the sidebar, followed by named sections in insertion order.
   **Rationale**: This prioritizes ungrouped content and provides a consistent structure for sidebar organization.
   **Approved**: pending

3. **Decision**: Read and write operations to the persisted store are wrapped in try/catch; errors (quota exceeded, access denied, private browsing) are silently ignored.
   **Rationale**: This ensures the component remains functional even when persistence is unavailable, rather than throwing and breaking the UI.
   **Approved**: pending

4. **Decision**: `registerPane` filters out any existing registered pane with the same id before appending the new one, so re-registering with updated props (e.g. a title change) replaces rather than duplicates the entry — at the cost of moving that pane to the end of the registration order (see the **Child Pane re-registration** edge case).
   **Rationale**: This allows child panes to re-register with updated props without duplication, using the simplest possible identity rule.
   **Approved**: pending

5. **Decision**: When `selectedId` is provided, it overrides internal state and auto-selection for display purposes (see **selection-precedence**); the component never writes to `internalSelected` while controlled.
   **Rationale**: This ensures parent control over the displayed pane is predictable and reliable.
   **Approved**: pending

6. **Decision**: The `onSelect` callback is invoked on every pane selection — including the auto-select fallback — regardless of controlled or uncontrolled mode.
   **Rationale**: This lets parents track every selection change, which is essential for analytics and for keeping parent-owned state in controlled mode synchronized.
   **Approved**: pending

7. **Decision**: Each tab button links to its corresponding panel via an `aria-controls` attribute (`aws-pane-<id>`), and, in child-mode, the panel sets an `aria-labelledby` attribute pointing at `aws-pane-<id>-tab`, intended as the reverse link back to its tab, per **tab-panel-linkage** and **panel-labelledby**.
   **Rationale**: The forward link (`aria-controls`) does give assistive technology a tab-to-panel association. The reverse link is unfinished: no tab button is ever given the id `aria-labelledby` points at, so it always references a nonexistent element and the tabpanel gets no accessible name from it — see the screen-reader-support gap under **Compliance**.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | failed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [data-retention-policy](agenticdevelopercookbook://compliance/privacy-and-data#data-retention-policy) | partial | Privacy and Data |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | partial | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

These rest on the source: native `<button>`/`role="tab"` elements with `aria-selected` and `aria-controls` give a working screen-reader and keyboard baseline (passed/partial); the source defines no color tokens, contrast handling, dynamic-type accommodation, or minimum hit-target sizing of its own, so those checks can only be partial; the `aria-label="Settings sections"` string is hardcoded in JSX with no localization hook, failing both internationalization string checks; RTL and text-expansion behavior depend entirely on consumer-supplied CSS the source doesn't define; React's native Unicode-safe text rendering satisfies unicode-support; and only a single pane-id string is written to the persisted store with no other data collected, passing data-minimization, while data-retention-policy is partial because retention is stated (Privacy section) but no explicit deletion API is offered. `separation-of-concerns` is partial because persistence is cleanly extracted into `readPersisted`/`writePersisted`, but the auto-select effect and the by-section pane grouping (`SettingsPanelRoot`'s effect, `SettingsPanelSidebar`'s `groups` memo) are computed inline alongside the render logic rather than pulled into their own hooks; `unit-test-coverage` is passed on `SettingsPanel.test.tsx`, which renders the real `SettingsPanel` and asserts default selection, click-to-switch, section grouping, disabled-pane handling, controlled/uncontrolled selection, and localStorage persistence.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | panel-labelledby is a dangling aria-labelledby, not a working link; requirement, panel-022, Accessibility, Decision 7, screen-reader-support corrected. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and added a selection-precedence requirement resolving the auto-select/controlled-mode conflict; moved React/DOM specifics (classes, ids, storage keys) out of Behavioral Requirements and Appearance into the React/Web platform note with `{{app_prefix}}` templating; named concrete SwiftUI (`NavigationSplitView`/`Settings` scene) and AppKit (`NSSplitViewController`/`NSTabViewController`) APIs; replaced the Compliance "Not applicable" with a checks table; reformatted Design Decisions into the three-line Decision/Rationale/Approved form; corrected the Accessibility Options wording for Increase Contrast and Differentiate Without Color; added edge cases for a disabled/missing persisted or default selection, duplicate pane ids, and corrected the empty-section-name edge case; fixed test vectors panel-004 and panel-009 and added seven vectors (panel-016 through panel-022) for previously untested requirements; added related sibling recipes and real localization keys |
| 1.0.0 | 2026-09-22 | (pending) | Initial creation from React SettingsPanelRoot source |
