---
id: e626a6fc-0d60-4ba5-a42a-d1849d7e1506
title: "Search Dialog Connected"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Connected wrapper that binds SearchDialog to the current site's search index, navigation, and site config."
platforms:
  - typescript
  - web
tags:
  - search
  - dialog
  - connected-component
depends-on:
  - 88dc87c9-8058-446d-9513-acfa618c950f
related: []
references: []
approved-by: ""
approved-date: ""
---

# Search Dialog Connected

## Overview

SearchDialogConnected is a connected wrapper component that provides a SearchDialog instance with data from the application's content, site configuration, and routing context. It derives the search state from a search index, maps section labels from site navigation, and handles selection by navigating to the chosen entry's URL slug and closing the dialog. Use this component to render a fully wired search dialog without manual state management.

## Behavioral Requirements

- **forwarded-props**: Component MUST accept and forward all SearchDialogProps except `state`, `onSelect`, and `sectionLabels` as specified by SearchDialogConnectedProps. `onClose` specifically is required (typed as `() => void`, not optional) because the selection handler below calls it directly.
- **search-state**: Component MUST compute search state by calling `useSearchState(searchIndex)` where searchIndex is obtained from `useContent()`.
- **section-labels**: Component MUST compute a mapping from section key to section label by iterating `nav.sections` from `useSiteConfig()`.
- **select-navigates**: Component MUST handle selection by calling `navigate(entry.slug)` (from `useCurrentRoute()`) and then calling the forwarded `onClose` callback.
- **renders-dialog**: Component MUST render the SearchDialog component with all computed values and forwarded props, passing computed state, mapped sectionLabels, and the selection handler.

## Appearance

Not applicable: SearchDialogConnected is a connected wrapper component that does not define visual appearance. All visual rendering is delegated to the SearchDialog component.

## States

SearchDialogConnected holds no state of its own — it defines no `useState`. The query text, result list, and selected index live in the `SearchState` returned by `useSearchState`; whether the dialog is open is owned by the caller via the forwarded `open` prop.

## Accessibility

SearchDialogConnected defines no UI elements of its own. It MUST forward `open`, `onClose` and the other SearchDialogProps (including any accessibility-related props) to SearchDialog unchanged, and all other accessibility concerns are the responsibility of the SearchDialog component that it wraps.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| search-dialog-connected-001 | forwarded-props | SearchDialogConnectedProps with `open: true`, a custom `onClose` handler and `placeholder: "Find"` | SearchDialog receives `open`, `onClose` and `placeholder` with the same values and the same function reference for `onClose` |
| search-dialog-connected-002 | search-state | Content context provides a searchIndex containing an entry titled "Install" and the user types "install" | The rendered SearchDialog lists the "Install" entry, showing its state comes from that index |
| search-dialog-connected-003 | section-labels | useSiteConfig returns nav with three sections: {key: 'guides', label: 'Guides'}, {key: 'api', label: 'API Reference'}, {key: 'examples', label: 'Examples'} | sectionLabels prop passed to SearchDialog contains {'guides': 'Guides', 'api': 'API Reference', 'examples': 'Examples'} |
| search-dialog-connected-004 | select-navigates | User selects entry with slug 'my-page' and component has onClose prop | navigate('my-page') is called, then onClose() is called in sequence |
| search-dialog-connected-005 | renders-dialog | Component invoked with any valid SearchDialogConnectedProps | The rendered output is exactly the SearchDialog (`role="dialog"` root when `open: true`), with the section labels and selection behavior of the other vectors applied |
| search-dialog-connected-006 | section-labels | useSiteConfig returns nav with an empty sections array | sectionLabels passed to SearchDialog is {} and SearchDialog renders without error |
| search-dialog-connected-007 | section-labels | `nav.sections` contains two sections with the same `key`, labelled "First" then "Second" | The label for that key passed to SearchDialog is "Second" (the last entry wins) |
| search-dialog-connected-008 | select-navigates | `navigate` throws when the user selects an entry | The exception propagates and `onClose()` is not called |
## Edge Cases

- **Empty sections array**: When nav.sections is empty, sectionLabels MUST be an empty object; SearchDialog receives valid (empty) sectionLabels and renders without error.
- **Zero-entry searchIndex**: `useContent()` types `searchIndex` as a required, non-optional `SearchIndex`, always constructed by `ContentProvider` via `createSearchIndex(entries)` — this component never receives a null or undefined index, so it performs no defensive check of its own. An index built from zero entries still renders normally: `index.query()` returns an empty results array and SearchDialog shows no results rather than crashing.
- **Missing entry.slug on selection**: `SiteEntry.slug` is typed as a required `string`, and SearchDialog only ever calls `onSelect` with an entry drawn from `state.results`, whose entries come from that same typed `SiteEntry[]`. `entry.slug` is therefore guaranteed by the type system; this case cannot occur.
- **Duplicate section key**: When two entries in `nav.sections` share a `key`, the label map keeps the later entry's label (last entry wins), because the map is filled by assignment in order.
- **navigate throws**: Selection calls `navigate(entry.slug)` and then `onClose()` with no `try`/`finally`. If `navigate` throws, the exception propagates and `onClose` is not called.
## Configuration

Not applicable: SearchDialogConnected accepts only pass-through props forwarded to SearchDialog; it does not define its own configuration options.

## Deep Linking

Not applicable: SearchDialogConnected does not handle deep linking directly. Navigation is delegated to the navigate() function from useCurrentRoute(), which is responsible for deep link handling.

## Localization

Not applicable: SearchDialogConnected does not define localized strings. Section labels are sourced from site configuration (nav.sections), and all other text is delegated to SearchDialog.

## Accessibility Options

Not applicable: SearchDialogConnected is a wrapper component with no direct UI elements. All accessibility option handling is delegated to the SearchDialog component.

## Feature Flags

Not applicable: The source code contains no feature flag logic or conditional rendering.

## Analytics

Not applicable: The source code contains no analytics event tracking or telemetry.

## Privacy

Not applicable: SearchDialogConnected is a data-connection component that does not collect, store, or transmit data. Data handling is the responsibility of useSearchState and useContent().

## Logging

Not applicable: The source code contains no logging or debug output.

## Platform Notes

- **React/Web**: SearchDialogConnected is defined in `packages/web/packages/controls/src/search-dialog/SearchDialogConnected.tsx`. It is a client component ('use client'). It uses four hooks from @adh-sdk/model: useContent (for searchIndex), useSiteConfig (for nav.sections), useCurrentRoute (for navigate), and useSearchState (for search state derivation). The sectionLabels are memoized on `nav.sections` via useMemo, so they are recomputed only when `nav.sections` changes.
- **SwiftUI**: A thin container view that reads the search index, site navigation, and router via `@Environment` injection (not local `@State`, which would make the container own that data), derives search state and section labels, and passes them to a presentational `SearchDialog` view — mirroring the web split of `SearchDialogConnected` around `SearchDialog`. It performs no search algorithm or list construction of its own; selection calls the environment's navigation function, then dismisses the presented dialog.
- **Compose**: A stateful composable that reads `searchIndex` from a ViewModel or repository and `nav.sections` from a `SiteConfigRepository` via dependency injection, derives search state and the section-label map with `remember` / `derivedStateOf`, and composes a presentational `SearchDialog` composable with those values plus a select callback. It binds no list or search field itself; selection calls `NavController.navigate(entry.slug)`, then dismisses via the same state that shows the dialog.
- **AppKit / UIKit**: A thin controller — an `NSWindowController` on macOS, a `UIViewController` on iOS — that reads the search index, navigation, and router from injected services, derives search state and section labels, and hands them to a presentational search surface: an `NSSearchField`-backed panel on macOS, or a `UISearchController`-backed view on iOS. It performs no list binding or search-controller delegate work of its own; selection navigates via the injected router, then dismisses the presentational dialog.
- **WinUI 3**: A thin control that reads the search index, navigation, and router from injected services (DI or a ViewModel), derives search state and the section-label map, and passes them to a presentational search surface built from `ContentDialog` hosting an `AutoSuggestBox` — supplying the derived items, labels, and a selection callback rather than binding its own `ItemsControl`/`ListView` or handling `SelectionChanged` itself. Selection navigates via the injected `INavigationService`, then calls the dialog's `Hide()`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/search-dialog/SearchDialogConnected.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: SearchDialogConnected is a thin connected wrapper; all presentation — layout, list rendering, input handling — is delegated to a presentational SearchDialog component.
**Rationale**: Keeps SearchDialog reusable with different data sources (testing, alternative content), while SearchDialogConnected orchestrates the integration with the application's standard data layer.
**Approved**: pending

**Decision**: `sectionLabels` is computed with `useMemo` keyed on `nav.sections`, but the selection handler passed as `onSelect` is defined inline and is not wrapped in `useCallback`.
**Rationale**: `useMemo` avoids recomputing the label map when unrelated props cause the wrapper to re-render. The selection handler needs no referential stability because SearchDialog never uses it as an effect or memoization dependency — it is only invoked directly from a keyboard or click handler.
**Approved**: pending

**Decision**: Selection handling calls `navigate(entry.slug)` before calling `onClose()`.
**Rationale**: The observable contract is that the route change is requested before the close is signalled, so `navigate` is called first and `onClose` second. The source does not show a visible gap that the other order would cause, so no stronger claim is made.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Keyboard handling, focus management, and ARIA structure live entirely in SearchDialog and useSearchState; this wrapper forwards `open`, `onClose`, and the rest of SearchDialogProps unmodified (see **forwarded-props**), so the source shows it does not break that behavior but, as a pass-through layer, cannot itself demonstrate full conformance. `separation-of-concerns` passes because this component only wires data hooks (`useContent`, `useSiteConfig`, `useCurrentRoute`, `useSearchState`) and delegates all rendering to `SearchDialog`, and `unit-test-coverage` passes because every vector (search-dialog-connected-001 to 008) has a passing test: `SearchDialogConnected.test.tsx` covers 002, 004 and 005 with real providers, and `SearchDialogConnected.props.test.tsx` replaces `SearchDialog` to observe the props handed to it (001, 003, 004, 006, 007, 008).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; corrected Platform Notes native APIs and rewrote them as thin wrappers around a presentational SearchDialog per platform; fixed the searchIndex and entry.slug edge cases to match their type guarantees; added test vectors for renders-dialog and the empty-sections case; clarified States and the onClose requirement; split Design Decisions into Decision/Rationale/Approved entries; added a Compliance table; added a depends-on link to search-dialog.
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Restated the navigate-before-close rationale as a contract, marked unit-test-coverage partial and cited the one covering test, made Accessibility and the vectors checkable, fixed the platform notes, and added duplicate-key and navigate-throws edge cases with vectors. |
