---
id: d6ff2cc3-89c8-4744-b3f4-7262e45a3414
title: Help Content
domain: adhsdk://recipes/help-content
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Context provider and hook for distributing localized help entries keyed by
  component id.
platforms:
- typescript
- web
tags:
- help
- context
- localization
depends-on: []
related:
- adhsdk://recipes/help-enabled
references: []
approved-by: ''
approved-date: ''
---

# Help Content

## Overview

HelpContent is a React context provider and hook system for distributing site-specific help text to UI components. A HelpContentProvider publishes a dictionary of help entries (keyed by component id) to its descendants; consuming components retrieve entries by id using the useHelpEntry hook. Each entry supports an optional title, required body text, and an optional flavor that categorizes the help type (help, info, or new).

## Behavioral Requirements

- **provide-context**: HelpContentProvider MUST create and provide a React context containing a SiteHelp dictionary to all descendant components.
- **accept-help-data**: HelpContentProvider MUST accept a `help` prop of type `Record<string, HelpEntry>`.
- **pass-children**: HelpContentProvider MUST render its `children` prop unchanged within the context provider.
- **retrieve-entry-by-id**: useHelpEntry MUST retrieve and return the HelpEntry object for a given id string from the context.
- **return-undefined-on-missing-id**: useHelpEntry MUST return undefined when the id does not exist in the help dictionary or no HelpContentProvider is mounted.
- **no-throw-on-missing-entry**: useHelpEntry MUST NOT throw an error when called without a provider or with an unknown id.
- **exclude-inherited-properties**: useHelpEntry MUST return undefined for an id that is not an own property of the help dictionary, even when that id names an inherited `Object.prototype` member (e.g. `constructor`, `toString`). A suggested implementation is `Object.hasOwn`, rather than a bare index lookup.
- **support-three-flavors**: The HelpFlavor type MUST support exactly three values: "help", "info", "new".
- **default-flavor-to-info**: HelpEntry's `flavor` property is optional; when it is absent, a consumer reading the entry MUST treat it as `"info"`. useHelpEntry returns the entry unchanged — a TypeScript interface cannot carry a runtime default — so the default is applied by the consumer, not by the hook.
- **support-optional-title**: HelpEntry MUST accept an optional `title` property; it MAY be omitted.
- **require-body**: HelpEntry MUST require a `body` property as a non-optional field.
- **accept-string-body**: HelpEntry `body` MUST be a string, not a ReactNode or JSX element.

## Appearance

Not applicable: HelpContent is a data provider component with no visual rendering. It publishes help text as data for downstream UI components to display.

## States

Not applicable: HelpContent is a stateless data provider component with no interactive or display states.

## Accessibility

Not applicable: HelpContent is a context provider component that has no direct user interaction or visual interface. Accessibility is the responsibility of consuming components that render the help entries it provides.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| help-content-001 | provide-context, accept-help-data, pass-children | Render `<HelpContentProvider help={{id1: {body: "text"}}} children={<Child />} />` | Child component renders and can access context via useHelpEntry |
| help-content-002 | retrieve-entry-by-id | Call `useHelpEntry("known_id")` with provider mounted and entry present | Returns HelpEntry object with `body` property |
| help-content-003 | return-undefined-on-missing-id | Call `useHelpEntry("unknown_id")` with provider mounted but no matching entry | Returns undefined |
| help-content-004 | return-undefined-on-missing-id | Call `useHelpEntry("any_id")` with `<HelpContentProvider help={{}}>` mounted | Returns undefined for any id, since the dictionary has no entries |
| help-content-005 | no-throw-on-missing-entry | Call `useHelpEntry("any_id")` with no HelpContentProvider mounted | Returns undefined; does not throw |
| help-content-006 | exclude-inherited-properties | Call `useHelpEntry("constructor")` with provider containing only user-defined entries | Returns undefined; inherited Object.prototype properties are excluded |
| help-content-007 | support-three-flavors | Pass `{body: "text", flavor: "help"}` to HelpEntry | Accepted without type error |
| help-content-008 | support-three-flavors | Pass `{body: "text", flavor: "info"}` to HelpEntry | Accepted without type error |
| help-content-009 | support-three-flavors | Pass `{body: "text", flavor: "new"}` to HelpEntry | Accepted without type error |
| help-content-010 | default-flavor-to-info | Retrieve a HelpEntry with no `flavor` property specified | useHelpEntry returns the entry unchanged with `flavor` equal to `undefined`; a consumer reading the entry MUST treat the missing `flavor` as `"info"` |
| help-content-011 | support-optional-title | Pass HelpEntry without `title` property | Entry is valid and accepted; `title` is `undefined` |
| help-content-012 | support-optional-title | Pass HelpEntry with `title: "How this works"` | Entry is valid and accepted; `title` is returned unchanged as `"How this works"` |
| help-content-013 | require-body | Attempt to create HelpEntry without `body` property | Type error; body is required |
| help-content-014 | accept-string-body | Pass `{body: "plain text"}` | Accepted; JSX or ReactNode is not accepted for `body` |
| help-content-015 | accept-string-body | Pass `{body: "multiline\ntext"}` | Accepted; JSX or ReactNode is not accepted for `body` |

## Edge Cases

- **No provider mounted**: useHelpEntry called without a HelpContentProvider ancestor returns undefined; no error is thrown. This is intentional: the first consumer is in the header on every page of every site, so throwing would turn a typo into a white screen.
- **Prototype pollution prevention**: useHelpEntry("constructor") or other inherited property names return undefined because Object.hasOwn filters to owned properties only, preventing SiteHelp object literals from accidentally returning constructor or other inherited functions.
- **Empty help dictionary**: HelpContentProvider mounted with empty `help={{}}` causes useHelpEntry to return undefined for any id queried. See **return-undefined-on-missing-id**.
- **Help data prop changes**: HelpContentProvider passes `help` straight through as the context value without memoizing it. If a caller supplies a new object reference on every render (for example, an inline object literal), context consumers re-render on every parent render even though the entries themselves did not change. Callers SHOULD hold `help` in a stable reference (a module-level constant, or a value the caller memoizes) to avoid those unnecessary re-renders; HelpContentProvider itself does not memoize the prop.

## Configuration

### HelpContentProvider props

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| help | `Record<string, HelpEntry>` | — | A dictionary of help entries keyed by component id. Required for HelpContentProvider. |

### HelpEntry fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| title | string | undefined | Optional heading for a help entry. Omitted for entries with no title. |
| body | string | — | The help text content. Required for every HelpEntry. |
| flavor | "help" \| "info" \| "new" | "info" | Flavor tag categorizing the type of help content. See **default-flavor-to-info** for where the default is applied. |

## Deep Linking

Not applicable: HelpContent is a data provider component, not a routable page or interactive element.

## Localization

- **body field**: The `body` property is a plain string, not JSX or ReactNode. This is intentional: many consuming site configs are authored as `.ts` modules without JSX support and cannot express ReactNode values. Localization of help text is handled by the consuming application over its own per-locale help content file.
- **title field**: The optional `title` property is also a plain string for the same reason.
- **flavor field**: The `flavor` property is not localized; it is a semantic tag for the UI layer to interpret.

## Accessibility Options

Not applicable: HelpContent is a context provider component with no visual rendering or accessibility controls. Consuming components implement accessibility for displayed help content.

## Feature Flags

Not applicable: HelpContent component has no feature flag implementation in the source.

## Analytics

Not applicable: HelpContent component does not implement analytics event tracking. Consuming components that render help entries are responsible for any analytics integration.

## Privacy

Not applicable: HelpContent distributes site configuration help text declared in the consuming application's site definition. No personal data is collected, stored, or transmitted by this component.

## Logging

The `useHelpEntry` hook does not implement logging or console warnings itself; it returns `undefined` when an entry is not found. Consuming components (such as `<HelpEnabled>`) are responsible for warning to the console when an unknown id is requested, preventing downstream components from rendering popovers with undefined content.

## Platform Notes

- **SwiftUI**: Implement as a SwiftUI Environment value providing an immutable dictionary of help entries. Create a `HelpEntry` struct mirroring the TypeScript interface with optional `title`, required `String` body, and `HelpFlavor` enum (info, help, new) with info as default. Expose via `@Environment(\.helpEntries) var helpEntries: [String: HelpEntry]`, mounted with `.environment(\.helpEntries, helpDictionary)` at the app root to parallelize the document-level provider placement. A lookup for a missing id (`helpEntries[id]`) naturally returns `nil`, matching **return-undefined-on-missing-id**; a Swift dictionary has no prototype chain, so no inherited-key filtering (see **exclude-inherited-properties**) is needed.

- **Compose**: Implement as a CompositionLocal providing a `(String) -> HelpEntry?` lookup function backed by an immutable `Map<String, HelpEntry>`. Define `HelpEntry` data class with optional title, required String body, and `HelpFlavor` enum (INFO, HELP, NEW) with INFO default. Create `val LocalHelpEntries = compositionLocalOf<(String) -> HelpEntry?> { { null } }` and mount at the composition root via `CompositionLocalProvider(LocalHelpEntries provides { id -> helpMap[id] }) { ... }`. Consuming components access via `LocalHelpEntries.current?.invoke(id)`. `helpMap[id]` returns `null` for a missing key, matching **return-undefined-on-missing-id**; a Kotlin `Map` has no prototype chain, so no inherited-key filtering (see **exclude-inherited-properties**) is needed.

- **React/Web**: HelpContentProvider is a React function component wrapping React.createContext and Context.Provider. useHelpEntry is a React hook using useContext to retrieve data. The component uses "use client" directive and is appropriate for client-side React patterns (Next.js App Router). Mounted at the document level rather than passed to individual components because some sites replace the shared header entirely, so props to the header would miss them.

- **AppKit / UIKit**: Create a `HelpEntry` struct with optional `title: String?`, required `body: String`, and `flavor: HelpFlavor` enum (info, help, new) with info as default. Build an immutable `[String: HelpEntry]` dictionary once and inject it down the view/controller hierarchy — through each view controller's initializer, or via a single dependency container handed to the window's root view controller — rather than a mutable global singleton. A lookup is `entries[id]`, returning `nil` for an unknown id, matching **return-undefined-on-missing-id**.

- **WinUI 3**: Create `public class HelpEntry { public string? Title { get; init; } public required string Body { get; init; } public HelpFlavor Flavor { get; init; } = HelpFlavor.Info; }` and `public enum HelpFlavor { Info, Help, New }`. Build an immutable `IReadOnlyDictionary<string, HelpEntry>` once and inject it into the window/page hierarchy — through a constructor parameter, or a value handed down from the window's root — rather than a mutable static singleton. Look up entries with `Entries.TryGetValue(id, out var entry)`, never by indexing: indexing throws `KeyNotFoundException` on a missing key, which would violate **no-throw-on-missing-entry**.

## Design Decisions

- **Decision**: `body` and `title` are plain strings, not `ReactNode`.
  **Rationale**: Site configs are commonly authored as `.ts` modules without JSX support and cannot hold JSX expressions; a string keeps that configuration format available.
  **Approved**: pending

- **Decision**: `useHelpEntry` returns `undefined` for an unknown id or when no provider is mounted, rather than throwing.
  **Rationale**: The first consumer is in the header on every page of every site, so a throw here would turn a typo into a white-screen failure that cascades to every page.
  **Approved**: pending

- **Decision**: `useHelpEntry` uses `Object.hasOwn` to exclude inherited properties (e.g. `constructor`, `toString`) rather than a bare index lookup.
  **Rationale**: `SiteHelp` is a plain object literal and inherits from `Object.prototype`; a bare index access would return function objects for those inherited names instead of `undefined`.
  **Approved**: pending

- **Decision**: `HelpContentProvider` is mounted at the document level rather than passed as a prop to the header component.
  **Rationale**: Some hosts replace the shared header entirely with their own; a prop-based approach would reach only the shared header and miss a replaced one.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`useHelpEntry`'s `Object.hasOwn` check rejects ids that would otherwise resolve to inherited `Object.prototype` members instead of treating them as valid lookups, and `HelpContentProvider`/`HelpEntry` store only the id-keyed help text a caller supplies, nothing beyond it. `separation-of-concerns` passes because the module is pure context/data plumbing with no rendering of its own, and `unit-test-coverage` passes on `help-content.test.tsx`'s direct exercise of `useHelpEntry`, including the inherited-`Object.prototype`-id edge cases.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; fix default-flavor-to-info to describe the consumer-applied default with a matching vector; correct Object.hasOwnProperty citation to Object.hasOwn; rewrite AppKit/UIKit and WinUI 3 notes for immutable dependency injection and non-throwing lookup, scope SwiftUI guidance to the SwiftUI bullet, and add SwiftUI/Compose parity notes; generalize unsourced consumer counts in Localization and Design Decisions; reformat Design Decisions to Decision/Rationale/Approved; replace the Compliance placeholder with a checks table; split Configuration into provider props and entry fields; drop the untested null-id edge case and replace the duplicate-entry edge case with a prop-memoization note; split folded flavor/body vectors and add optional-title and empty-dictionary vectors; add tags and a related cross-reference to HelpEnabled |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Fix Logging section to reflect actual source behavior; add Platform Notes translation guidance for SwiftUI, Compose, AppKit/UIKit, WinUI 3 |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
