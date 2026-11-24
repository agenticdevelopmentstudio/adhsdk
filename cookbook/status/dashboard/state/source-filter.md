---
id: 3f2ae6c1-bc07-40ab-b15c-bb4b8c77986b
title: "Source Filter"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "State holding the issue-source multi-select filter, starting with every source selected, with a toggle that adds or removes one."
platforms:
  - typescript
  - web
tags: []
depends-on: []
related:
  - dcfe8ed6-2129-44ea-a084-eb30b640c0e3
references: []
approved-by: ""
approved-date: ""
---

# Source Filter

## Overview

Source Filter is client-only state that holds which issue sources a filtered pane shows. The selectable sources are a fixed list of eight values (dns, http, glitchtip, vercel, vercel-runtime, cloudflare-pages, railway, crunchy). The selection starts with every source selected, and a toggle operation adds or removes one source. The selection is kept in browser local storage under a key the caller supplies, so it survives a reload. Separate uses with different keys share nothing.

It is described as the source-set toggle state shared by every filtered pane (active problems, recently resolved, activity), extracted so the three panes can't drift in how they filter. In the current source, the activity panel is the only consumer. It applies the filter only when more than one source exists and lets through rows with no platform.

Use it wherever a view needs a persisted, per-key multi-select over the fixed issue-source list. It has no visual surface of its own.

## Behavioral Requirements

### Public operation

- **signature**: Source Filter MUST take one argument, the storage key under which the selection is kept, and MUST return an object with exactly two fields: `sources` (the set of selected sources) and a toggle operation that takes one source and returns nothing.
- **source-type**: The toggle operation's parameter MUST be one of the eight fixed source values. The type signature is the caller precondition. Source Filter does no runtime membership check.
- **toggle-identity-unstable**: The toggle operation MUST be a new function value each time Source Filter is used, because the source does not give it a stable identity. A consumer that lists it in a dependency list re-runs every time.
- **sources-immutability**: Each toggle MUST produce a new set instance and MUST NOT mutate the previous one, so a consumer that compares `sources` by reference sees every change.

### Initial state

- **default-all-selected**: On the first use of each mount, `sources` MUST contain every one of the eight fixed sources, in their defined order, until a stored selection is restored.
- **seed-decoupled**: The seeded set MUST be a copy of the fixed source list. Mutating it MUST NOT alter the fixed source list, and the reverse also holds.

### Toggle

- **toggle-flip**: The toggle operation MUST remove a source from the selection when it is present and add it when it is absent.
- **toggle-order**: A source added by the toggle operation MUST come after the existing members in the set's iteration order.
- **toggle-may-empty**: The toggle operation MUST allow the selection to become empty. There is no minimum of one selected source.
- **toggle-functional-update**: The toggle operation MUST derive the next selection from the latest state, so several toggles in one batch of updates compose instead of overwriting each other.
- **toggle-no-error**: The toggle operation MUST NOT throw and MUST NOT return a value. A storage failure is swallowed (see write-failure-ignored).

### Ordering, concurrency and scope

- **single-threaded**: All state updates run on a single execution thread, so toggles cannot interleave. Updates apply in the order they are issued.
- **updater-pure**: The set computation MUST build the next set from the previous one without mutating it. The environment MAY apply the update more than once for the same input, and each application returns an equivalent set and writes the same stored value.
- **per-instance-state**: Each use MUST hold its own selection. A toggle in one use MUST NOT change another concurrent use, unless both use the same storage key.
- **persisted-per-key**: The selection MUST be persisted as a JSON array of its members, in iteration order, in browser local storage under the storage key the caller passes. Each filtered pane passes its own key, so each pane's choice survives a reload.
- **deferred-hydration**: The first render MUST show the default all-selected set. After that render, Source Filter MUST read the stored value once per key and, when it decodes, replace the selection with it, so a server render and the first paint match.
- **decode-known-sources**: When hydrating, Source Filter MUST accept only a JSON array and MUST keep only the members that are known source values, dropping any other entry. A stored value that is not an array MUST be ignored and the default kept.
- **read-failure-keeps-default**: When the storage read throws or the stored value is not valid JSON, Source Filter MUST keep the default selection and MUST NOT propagate the error.
- **write-failure-ignored**: When the storage write throws, the toggle MUST still apply the new in-memory selection and MUST NOT propagate the error.
- **no-side-effects**: Source Filter MUST NOT make network requests, log, start timers, or subscribe to anything. Its only storage access is one read per key and one write per toggle.
- **client-only**: Source Filter MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

## Appearance

Not applicable — this is an in-memory state concept, not a visual component.

## States

Not applicable — this is an in-memory state concept, not a visual component.

## Accessibility

Not applicable — this is an in-memory state concept, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input / Precondition | Action | Expected |
|----|-------------|----------------------|--------|----------|
| source-filter-001 | signature, default-all-selected | Fresh mount | Use Source Filter and read the first result | `sources` equals `{dns, http, glitchtip, vercel, vercel-runtime, cloudflare-pages, railway, crunchy}` (size 8), iterating in that order. The toggle operation is a function. |
| source-filter-002 | default-all-selected | Fresh mount | Check whether `sources` contains `"cloudflare-pages"` | `true` |
| source-filter-003 | toggle-flip, sources-immutability | Default state | Call the toggle operation with `"http"` | `sources` has 7 members and no `http`. It is a different set instance from before. |
| source-filter-004 | toggle-flip, toggle-order | State after source-filter-003 | Call the toggle operation with `"http"` | `sources` has 8 members and iterates `dns, glitchtip, vercel, vercel-runtime, cloudflare-pages, railway, crunchy, http`. |
| source-filter-005 | toggle-may-empty | Default state | Call the toggle operation once for each of the 8 sources | `sources` is an empty set (size 0). No error is thrown. |
| source-filter-006 | toggle-functional-update | Default state | Call the toggle operation with `"dns"` and with `"railway"` in one batch of updates | `sources` has 6 members, neither `dns` nor `railway`. |
| source-filter-007 | toggle-functional-update | Default state | Call the toggle operation with `"vercel"` twice in one batch | `sources` is back to all 8 members (the two toggles cancel). |
| source-filter-008 | seed-decoupled | Default state | Call the toggle operation with `"dns"`, then read the fixed source list | The fixed source list still has 8 entries and includes `"dns"`. |
| source-filter-009 | per-instance-state | Two separate uses | Call the toggle operation with `"glitchtip"` in the first | The first use has 7 members. The second still has 8. |
| source-filter-010 | persisted-per-key, deferred-hydration | One use with storage key `pane` toggled to `{dns}` only | Stop using it and start again with the same key | The selection is written to storage under `pane` as `["dns"]`, and the new use's `sources` is `{dns}`. |
| source-filter-011 | toggle-identity-unstable | Any state | Force a re-render and compare the returned toggle operation with the previous one | Not reference-equal. `sources` IS reference-equal when no toggle occurred. |
| source-filter-012 | client-only | Source Filter is loaded in a server-only rendering context | Render it | It is unavailable there: the module is marked for client execution only |

## Edge Cases

- **Empty selection**: toggling off every source MUST give an empty set. For the activity panel, this hides every row that has a known `platform` whenever more than one source exists. Rows whose `platform` is null or missing still show, because the consumer lets them through.
- **Unknown source value**: the source type rules this out at compile time. A value forced in some other way MUST be added to or removed from the in-memory set like any other value, because Source Filter does no runtime check. The set's size can then exceed 8; on the next hydration the unknown value is dropped.
- **Source added to the fixed list later**: new mounts MUST include it in the default. A use that is already mounted does not pick it up until it starts again.
- **Rapid repeated toggles**: each call MUST flip membership once, based on the latest queued state (source-filter-007).
- **Update applied more than once for the same input**: the result MUST be the same as a single application, because the update has no side effects.
- **Reload or remount**: the selection MUST be restored from local storage under the same key after the first render (see source-filter-010). Until then the default all-selected set shows.
- **Stored value that is not recognised**: a stored value that is not valid JSON, or not an array, MUST leave the default selection. Unknown entries inside a stored array MUST be dropped; the known ones are kept.
- **Storage unavailable**: a read or write that throws MUST be swallowed. The default stays on read failure, and the in-memory selection still changes on write failure.
- **Server render**: Source Filter MUST render the default all-selected set on a server-rendering pass. It touches storage only after the first render.
- **Null or empty input, timeouts, cancellation, network loss**: not applicable. The storage key is a required string, and the only I/O is synchronous local storage.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Fixed source list | list of source values | `["dns", "http", "glitchtip", "vercel", "vercel-runtime", "cloudflare-pages", "railway", "crunchy"]` | The default selection and its initial iteration order. Mirrors the server's own issue-source list. |
| Source type | closed enumeration | same 8 values | The type-checked domain of the toggle operation's argument. |
| Storage key | string | none (required) | The local-storage key the selection is kept under. The activity panel passes `adh-status-sources-<kind>`, one key per pane. |

Source Filter reads no environment variables or settings keys.

## Deep Linking

Not applicable: Source Filter never reads or writes the URL, so the selection cannot be reached by a link.

## Localization

Not applicable: Source Filter has no user-facing strings. Display labels live with the consumer that renders them.

## Accessibility Options

Not applicable: Source Filter renders nothing and reads no display preference.

## Feature Flags

Not applicable: no flag gates Source Filter. It always returns a selection seeded from the fixed source list.

## Analytics

Not applicable: Source Filter emits no analytics events.

## Privacy

Not applicable: Source Filter holds only a set of source identifiers. It stores that list in browser local storage on the device under the caller's key and transmits nothing.

## Logging

Not applicable: Source Filter makes no log calls and has no failure path to log.

## Platform Notes

- **React/Web** (source): `packages/web/packages/status-web/src/hooks/use-source-filter.ts`. It takes a `storageKey` and delegates to the shared `usePersistedState` hook (`use-persisted-state.ts`) with the default `new Set(ISSUE_SOURCES)`, a decoder that keeps only known source strings from a stored array, and an encoder that stores `[...set]`. `usePersistedState` starts at the default, hydrates from `localStorage` in an effect, and writes inside its state setter, catching storage errors. `toggleSource` is a plain arrow function with no `useCallback`. The updater copies `prev` into a new `Set` before flipping membership, so React sees a new reference; React MAY call that updater twice in development Strict Mode, which is why the update itself must stay pure. The `"use client"` directive marks it as a Next.js client module. Its sibling `useEnvFilter` follows the same persisted shape. `ActivityPanel` passes `adh-status-sources-<kind>` as the key. `row-model.test.ts` asserts the default seed ("useSourceFilter's default seed selects every ISSUE_SOURCES member") via `new Set(ISSUE_SOURCES).has(...)`, independent of the hook itself.
- **SwiftUI**: Start from a `@MainActor @Observable` model with `var sources: Set<IssueSource>` seeded from `IssueSource.allCases` (make `IssueSource` a `String`-backed `CaseIterable` enum) and a `toggle(_:)` method. Use `@State` for per-view ownership so each view gets its own instance. Swift `Set` is unordered, so keep an ordered array, or sort by `allCases` index, if iteration order matters.
- **Compose**: Start from `remember { mutableStateOf(IssueSource.entries.toSet()) }`, or a `ViewModel` holding `MutableStateFlow<Set<IssueSource>>`. Update with `update { if (s in it) it - s else it + s }` so each change produces a new immutable set. Kotlin's `setOf`/`toSet` keep insertion order (`LinkedHashSet`), which matches the source.
- **AppKit / UIKit**: A `@MainActor` model class with `@Published var sources: Set<IssueSource>` (Combine) or a delegate callback, seeded from `IssueSource.allCases`. Persist the selection per key (for example in `UserDefaults`) to match the source.
- **WinUI 3**: Start from a view-model class implementing `INotifyPropertyChanged` (or CommunityToolkit.Mvvm `ObservableObject` with `[ObservableProperty]`). Expose an `IssueSource` enum, an `IReadOnlySet<IssueSource> Sources` property seeded from `Enum.GetValues<IssueSource>()`, and a `ToggleSource(IssueSource s)` method or `RelayCommand<IssueSource>`. Replace the whole set on each toggle (`var next = new HashSet<IssueSource>(Sources); if (!next.Remove(s)) next.Add(s); Sources = next;`) so `PropertyChanged` fires and bindings that compare by reference update, matching the source's copy-on-write. Bind each source's `ToggleButton` or `CheckBox` `IsChecked` through a converter or a per-item wrapper, or use an `ObservableCollection` of item view-models each with a bool `IsSelected`. `HashSet<T>` does not guarantee order, so use a `List<IssueSource>` with membership checks if order matters. Everything runs on the UI thread (`DispatcherQueue`), so no `Task`/`async` is needed. Persist the selection per key as a JSON array (for example in `ApplicationData.LocalSettings` with `System.Text.Json`), and ignore read and write failures.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/status-web/src/hooks/use-source-filter.ts` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Start with every source selected, and allow the selection to become empty.

**Rationale**: The source is documented as starting with all sources selected, toggling one adds or removes it. No minimum is enforced. The activity panel keeps the result usable by bypassing the filter when only one source exists, and by letting through rows that have no platform.

**Approved**: pending

**Decision**: The selection is persisted per pane under a caller-supplied storage key.

**Rationale**: The source delegates to a shared persisted-state hook, the same one the sibling Environment Filter follows, so each pane's choice survives a reload. It was in-memory only in an earlier version of this spec, and that is no longer the case. The first render shows the default and storage is read afterwards, so a server render and the first paint agree.

**Approved**: pending

**Decision**: Extract the toggle into a shared concept even though only one pane uses it today.

**Rationale**: The source is documented as existing so the three panes can't drift in how they filter, naming active problems, recently resolved and activity. In the given source only the activity panel imports it, so the documentation describes the intended set of consumers, not the current one. Source Filter's own contract is unaffected.

**Approved**: pending

**Decision**: The toggle operation is not memoised.

**Rationale**: The source defines it as a plain function created on each render. Its one consumer passes it only to interaction handlers, never to a dependency list, so the changing identity has no observable effect there.

**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | privacy-and-data |

The hook holds only selection state. Row filtering and label rendering live in `ActivityPanel`, so state and presentation are kept apart. `use-source-filter.dom.test.tsx` renders `useSourceFilter` and covers source-filter-001 to 011. Coverage is partial because source-filter-012 (client-only module) is skipped: jsdom cannot host a server component boundary. Storage read and write failures are caught and ignored, and the in-memory choice still applies. It keeps only source identifiers, in memory and in local storage on the device, and sends nothing anywhere.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Match recipe to source: eight sources, storage-key argument, persisted selection |
| 1.1.1 | 2026-10-04 | Mike Fullerton | One client-only requirement, worded the same across the dashboard state specs, with a test vector; the web module's "use client" directive is noted in Platform Notes. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to status/dashboard/state/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |
</content>
