---
id: 112f2150-3fcd-416c-bd25-b40f729b8ef2
title: "Appearance Store"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A client-side external store for appearance preferences: cache, repaint of the document, route scopes, OS colour-scheme following, sign-in adopt and sign-out reset."
platforms:
  - typescript
  - web
tags:
  - theme
  - appearance
  - preferences
  - store
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Appearance Store

## Overview

The appearance store is the one in-memory holder of the user's `AppearancePrefs` (colour mode, reduce motion, contrast, text size, spacing, focus outlines, underline links) on a web page. It is a module-level external store read through `useSyncExternalStore`, so no React Context or Provider is needed. A change made through it is cached in `localStorage`, painted onto `<html>` as the `dark` class and `data-*` attributes, and announced to subscribed components. The module also owns the single OS colour-scheme listener that re-resolves colour mode `auto`.

`localStorage` is only a per-browser cache. The truth lives on the server, and the consuming application reconciles the two through `adoptAppearance` (sign-in: the server's prefs win) and `resetAppearance` (sign-out: back to the OS setting, cache cleared). Neither call is made from inside this module. The module makes no network call itself.

A site that wears the prefs on only some routes mounts a scope (`mountAppearanceScope`, or the `AppearanceScope` component) on those routes. Once any scope has mounted, the store paints `<html>` only while at least one scope is mounted.

The pure logic it builds on (the defaults, normalisation, the storage reads and writes, `applyAppearance`, `clearAppearance`) lives in `appearance.ts` and is shared with the pre-paint script; this recipe specifies only the store layered over it.

## Behavioral Requirements

### Public surface

- **exports**: The module MUST export `mountAppearanceScope`, `AppearanceScope`, `adoptAppearance`, `resetAppearance`, `useAppearancePreferences` and the `UseAppearancePreferences` interface (`prefs: AppearancePrefs`, `set: (patch: Partial<AppearancePrefs>) => void`). The package index re-exports all of them.
- **client-only-module**: The module MUST carry the `"use client"` directive, because it holds module state and calls React hooks.
- **no-provider**: The store MUST work without a Provider or Context: every reader sees the same module-level state.

### Reading the preferences

- **lazy-snapshot**: The first read of the snapshot MUST load the prefs with `readStoredAppearance()` and hold the result; later reads MUST return that same object until a commit replaces it.
- **snapshot-stability**: The snapshot returned between commits MUST be the identical object (reference equality), as `useSyncExternalStore` requires.
- **server-snapshot**: The server snapshot MUST be `APPEARANCE_DEFAULTS`, so server rendering and the first client render agree.
- **hook-shape**: `useAppearancePreferences()` MUST return an object `{ prefs, set }` that keeps its identity while `prefs` is unchanged; `set` MUST keep its identity for the lifetime of the component.
- **hook-subscribes**: A component using the hook MUST re-render after every commit that replaces the snapshot.
- **subscribe-unsubscribe**: `subscribe(listener)` MUST add the listener to a set, and the function it returns MUST remove that listener.

### Writing the preferences

- **set-merges**: `set(patch)` MUST commit the current snapshot with `patch` spread over it, so unspecified fields keep their value.
- **set-caches**: `set(patch)` MUST write the merged prefs to `localStorage` under `APPEARANCE_STORAGE_KEY`.
- **set-not-validated**: `set(patch)` MUST NOT validate or normalise the patch; the `Partial<AppearancePrefs>` type is the only guard. (Stored values are normalised on read by `readStoredAppearance`; patches are not.)
- **adopt-wholesale**: `adoptAppearance(prefs)` MUST replace the held prefs with `prefs` entirely, not merge, and MUST write them to `localStorage`.
- **adopt-not-validated**: `adoptAppearance` MUST NOT normalise its argument. The caller is expected to pass a complete `AppearancePrefs`; the in-repo caller `AppearanceSync` runs `normalizeAppearance` first.
- **reset-defaults**: `resetAppearance()` MUST replace the held prefs with a fresh copy of `APPEARANCE_DEFAULTS` (colour mode `auto`, `compact` spacing, every other pref at its default).
- **reset-clears-cache**: `resetAppearance()` MUST remove the `localStorage` entry rather than overwrite it, so the next visitor on a shared browser does not inherit the previous user's theme through the pre-paint script.
- **commit-order**: Every commit MUST, in this order: replace the held prefs, write or clear the cache, paint the document if allowed, then notify every listener.
- **notify-sync**: Listeners MUST be called synchronously inside the commit, in set insertion order.
- **cache-failure-silent**: A failed `localStorage` write or removal (private mode, quota) MUST NOT stop the commit: the held prefs, the paint and the notification still happen. `writeStoredAppearance` and `clearStoredAppearance` swallow the error with an explanatory comment, so the failure is not signalled.

### Painting the document

- **paint-call**: When a commit paints, it MUST call `applyAppearance(document.documentElement, next, systemDark)` where `systemDark` is the OS dark-scheme query's `matches`, or `false` when no query exists.
- **paint-needs-document**: A commit MUST NOT paint when `document` is undefined (server); it still updates state, cache and listeners.
- **paints-rule**: The store MUST paint only when the site is unscoped or at least one scope is mounted: always on a site that never mounted a scope, and only while a scope is mounted on a site that has.
- **colour-mode-everywhere**: Colour mode MUST be honoured in every environment; the store applies no environment-based lock (the comment on `applyAppearance` records that production once pinned dark).

### OS colour-scheme following

- **os-listener-once**: At module load, on the client, the store MUST attach exactly one `change` listener to the `(prefers-color-scheme: dark)` media query, shared by the whole app and never removed.
- **os-listener-guards**: The module MUST NOT throw at load when `window` is undefined, when `window.matchMedia` is not a function, or when the query has no `addEventListener` (Safari before 14 has only `addListener`). In those hosts there is no OS signal, and `auto` resolves to light.
- **os-change-repaint**: On an OS change the store MUST repaint only when the held prefs exist, their colour mode is `auto`, and painting is allowed by the paints rule.
- **os-change-explicit-mode**: On an OS change the store MUST NOT repaint when the colour mode is `light` or `dark`.
- **os-change-unread**: On an OS change before any snapshot has been read (nothing held), the store MUST do nothing.
- **os-other-prefs-css**: Reduced motion and contrast MUST NOT need JavaScript on an OS change; the CSS `@media` queries handle them, so only the `dark` class is re-resolved.

### Scopes

- **scope-mount-arms**: `mountAppearanceScope()` MUST mark the site as scoped for the rest of the page's life and increment the mounted count.
- **scope-first-paint**: When the mount takes the count from 0 to 1, it MUST paint the snapshot the store holds now (reading the cache if nothing is held yet), so a commit made while no scope was mounted becomes visible.
- **scope-nested**: Mounts MUST nest: with two scopes mounted, painting continues until both have released.
- **scope-last-release-clears**: The release that takes the count to 0 MUST call `clearAppearance(document.documentElement)`.
- **scope-release-once**: The release function MUST count only once; calling it again MUST do nothing.
- **scope-unmounted-no-paint**: While no scope is mounted on a scoped site, a commit MUST still update the held prefs and the cache and notify listeners, but MUST NOT paint `<html>`.
- **scope-unscoped-paints**: A site that never mounts a scope MUST keep painting on every commit and every OS change.
- **scope-component**: `AppearanceScope` MUST render nothing (`null`) and MUST mount a scope in a layout effect with an empty dependency list, releasing it on unmount.
- **scope-needs-document**: `mountAppearanceScope` MUST be called only where `document` exists (a layout effect). Called with no `document`, it throws; no guard is provided.

## Appearance

Not applicable — this is a preference store with no visual surface of its own, not a visual component. The visual result is produced by the CSS that reads the attributes `applyAppearance` sets.

## States

Not applicable — this is a preference store, not a visual component. Its runtime state is the held prefs, the `scoped` flag and the `scopesMounted` count, specified under Behavioral Requirements.

## Accessibility

Not applicable — this is a preference store, not a visual component. It carries the user's accessibility choices to the document (see Accessibility Options).

## Conformance Test Vectors

Vectors AS-001 to AS-008 are asserted by `appearanceScope.test.ts`, `AppearanceScope.test.tsx` or `clearAppearance.test.ts`; AS-009 to AS-016 are derived from the source and have no test beside them.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| AS-001 | scope-mount-arms, scope-first-paint, scope-last-release-clears, os-change-repaint | `appearanceScope.test.ts` "an OS scheme change after the scope unmounts leaves html alone": OS light; mount a scope; `adoptAppearance` with colour mode `auto`, contrast `high`; release; flip the OS to dark | After adopt `data-contrast` is `high`; after release `<html>` carries no `data-color-mode`, no `dark` class and no `data-contrast`; after the flip it is still unpainted |
| AS-002 | scope-unmounted-no-paint, adopt-wholesale, set-caches | `appearanceScope.test.ts` "a commit that resolves after the scope unmounts is cached but not painted": mount and release a scope; `adoptAppearance` with colour mode `dark`; then `resetAppearance()` | After adopt `<html>` is unpainted and `localStorage["adh:appearance"]` parses to colour mode `dark`; after reset `<html>` is still unpainted |
| AS-003 | scope-first-paint | `appearanceScope.test.ts` "mounting the scope again paints what the store holds now": mount and release; `adoptAppearance` with colour mode `dark`; mount again | `<html>` has the `dark` class and `data-color-mode="dark"` |
| AS-004 | scope-nested, scope-release-once, scope-last-release-clears | `appearanceScope.test.ts` "keeps painting until the last of two scopes unmounts, and a release runs once": mount twice; adopt dark; call the first release twice | `dark` class still present; after the second release `<html>` is unpainted |
| AS-005 | scope-first-paint, os-change-repaint | `appearanceScope.test.ts` "a scope mounted with nothing stored follows the OS when it flips": OS light, nothing stored; mount a scope; flip the OS dark, then light | Initially no `dark` class and `data-color-mode="auto"`; `dark` class after the first flip; gone after the second |
| AS-006 | scope-unscoped-paints, paints-rule | `appearanceScope.test.ts` "a site that never mounts a scope keeps painting on commit and on an OS change": no scope; adopt colour mode `auto` with contrast `high`; flip the OS dark | `data-contrast="high"` and no `dark` class after adopt; `dark` class after the flip |
| AS-007 | scope-component, scope-last-release-clears, scope-unmounted-no-paint | `AppearanceScope.test.tsx`: render `<AppearanceScope/>`; adopt dark with contrast `high`; unmount; adopt dark again | While mounted: `dark` class and `data-contrast="high"`; after unmount no `dark`, `data-color-mode` or `data-contrast`; after the second adopt still no `dark` class |
| AS-008 | scope-last-release-clears | `clearAppearance.test.ts` (the function the last release calls): apply every pref to an element, then clear it | The element's `outerHTML` equals its value before apply; `data-color-mode="auto"` and `dark` set by the pre-paint script are also removed |
| AS-009 | os-change-explicit-mode | Unscoped site, adopt colour mode `light`, flip the OS dark | No `dark` class; the listener makes no repaint |
| AS-010 | reset-defaults, reset-clears-cache | Unscoped site, `adoptAppearance` with colour mode `dark`, then `resetAppearance()` | The `localStorage` entry is absent, the snapshot equals `APPEARANCE_DEFAULTS` in value, and `<html>` follows the OS (no `dark` class when the OS is light) |
| AS-011 | set-merges, set-caches, hook-subscribes | Hook mounted with defaults; call `set({ contrast: "high" })` | `prefs.contrast` is `high`, every other field is unchanged, the stored JSON holds the merged object, and the component re-renders once |
| AS-012 | server-snapshot | Render on the server (no `window`) | The hook returns `APPEARANCE_DEFAULTS`; no paint, no error |
| AS-013 | os-listener-guards | Load the module with `window.matchMedia` undefined | The import does not throw; `adoptAppearance` with colour mode `auto` paints no `dark` class |
| AS-014 | os-listener-guards | Load the module with a query object that has no `addEventListener` | The import does not throw and no OS change is followed |
| AS-015 | cache-failure-silent | `localStorage.setItem` throws; call `adoptAppearance(prefs)` | No exception; the snapshot equals `prefs`, `<html>` is painted and listeners are notified |
| AS-016 | os-change-unread | Fresh module, no read, OS flips | No repaint and no error |

## Edge Cases

- **Nothing stored**: With no cache entry, `readStoredAppearance` returns the defaults, so the first snapshot is colour mode `auto`. The store MUST accept this (it is the signed-out state).
- **Stored JSON is corrupt or has unknown or wrongly typed fields**: `readStoredAppearance` returns the defaults on a parse error and `normalizeAppearance` drops unrecognised values, so the snapshot is always a complete `AppearancePrefs`. This applies to reads only.
- **A partial or wrongly typed value reaches `set` or `adoptAppearance`**: it is stored and painted as given. The type signature is the only guard, so a caller outside TypeScript is responsible for passing valid values.
- **Reset when never signed in**: `resetAppearance()` on a browser that never signed in changes nothing visible: the defaults replace the defaults and the (absent) cache is cleared. Listeners are still notified.
- **Adopt resolves after the reader left a scoped route**: The prefs are cached and held but not painted (AS-002); the next scope mount paints them (AS-003). The store MUST NOT paint a page that never asked for the prefs.
- **A scope is mounted before any prefs are read**: The mount's snapshot read loads the cache. This is what arms OS following for a site that only mounts a scope (AS-005).
- **Release called twice**: counted once, so the mounted count never drops below the number of live scopes.
- **Boundary, scope count 0 to 1 to 0**: paint on the first mount, clear on the last release. Only the 0 to 1 and 1 to 0 transitions touch `<html>`; a second mount paints nothing new.
- **Concurrent calls**: Not applicable as parallelism: the module runs on the single browser thread, and every commit is a synchronous run of replace, cache, paint and notify. Two commits from separate calls resolve in call order; the last one wins, and a late-resolving `adoptAppearance` overwrites an earlier `set`.
- **Another tab changes the prefs**: The store attaches no `storage` event listener, so a change in another tab reaches this tab only through its next read after a reload. This is an absent feature, not a gap in a stated contract.
- **A listener throws during notification**: The error propagates out of the commit and later listeners are not called; the held prefs, cache and paint have already happened.
- **OS signal unavailable**: With no `matchMedia`, `auto` resolves to light and no OS change is ever observed (os-listener-guards).
- **Offline or server unreachable**: Not applicable: the store makes no network call; the server round-trip belongs to the caller (`AppearanceSync`, which reports a fetch failure and leaves the pre-paint result in place).
- **Storage unavailable**: Private mode or a full quota loses the cache write silently (cache-failure-silent); the page keeps the in-memory prefs until reload.
- **No `document` (server render)**: commits skip the paint (paint-needs-document); `mountAppearanceScope` is not called there because layout effects do not run on the server.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `APPEARANCE_STORAGE_KEY` | string constant | `adh:appearance` | The `localStorage` key holding the cached prefs, defined in `appearance-prepaint.mjs` and shared with the pre-paint script |
| `APPEARANCE_DEFAULTS` | `AppearancePrefs` | colour mode `auto`, reduce motion `auto`, contrast `default`, text size `default`, spacing `compact`, focus outlines `false`, underline links `false` | Used for the server snapshot and by `resetAppearance` |
| `(prefers-color-scheme: dark)` | media query | read from `window.matchMedia` once at module load | The OS signal for colour mode `auto`; absent means light |
| Scope mounting | caller choice | none (site is unscoped) | A site opts in to route-scoped painting by mounting `AppearanceScope` or calling `mountAppearanceScope`; there is no way to opt back out |

## Deep Linking

Not applicable: the store is a preference holder with no routes or URLs; scopes follow the caller's mounted routes, not a URL scheme.

## Localization

Not applicable: the store carries no user-facing strings; its values are enumerated tokens such as `auto`, `dark` and `high`, which the settings UI that consumes them labels.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Carried as the `reduceMotion` pref (`auto`, `on`, `off`) and painted as `data-reduce-motion`; `auto` removes the attribute so the `prefers-reduced-motion` media query governs. The store does not listen for that query. |
| Increase Contrast | Carried as the `contrast` pref (`default`, `high`, `extra-high`) and painted as `data-contrast`; `default` leaves the attribute off so `prefers-contrast` governs. The store does not listen for that query. |
| Differentiate Without Color | The store has no colour-only signal. It carries the `focusOutlines` and `underlineLinks` prefs, painted as `data-*="always"`. |

## Feature Flags

Not applicable: the module reads no flag; scoping is chosen by the caller mounting a scope.

## Analytics

Not applicable: the module emits no event and calls no analytics client.

## Privacy

- **Data collected**: The user's appearance choices (colour mode, motion, contrast, text size, spacing, focus outlines, underline links). None of it identifies the person.
- **Storage**: In memory for the page's life and in `localStorage` under `adh:appearance` as the JSON of `AppearancePrefs`. The store never writes anywhere else.
- **Transmission**: The store sends nothing off the device. The server copy is read and written by the consuming application.
- **Retention**: The cache lasts until sign-out, when `resetAppearance` removes it so the next person on a shared browser does not inherit the previous user's theme. A browser that never signs out keeps it indefinitely.

## Logging

Not applicable: the module makes no log call. The storage helpers swallow storage errors with a comment and no log, and the in-repo caller reports a fetch failure through its own `captureException`.

## Platform Notes

- **SwiftUI**: Not the source platform. Start from an `@Observable` (or `ObservableObject`) model owned by the app, persisted with `UserDefaults` under a key such as `adh.appearance`, and read `@Environment(\.colorScheme)` for the OS scheme. There is no document to paint: the model sets `.preferredColorScheme` and Dynamic Type or spacing values on the root view, and a route scope becomes applying that modifier only inside the scoped view hierarchy. Clear the `UserDefaults` key on sign-out.
- **Compose**: Not the source platform. Hold the prefs in a `ViewModel` exposing a `StateFlow<AppearancePrefs>`, persist with DataStore (Preferences), resolve `auto` with `isSystemInDarkTheme()`, and pass the result into `MaterialTheme`; scope by wrapping only the scoped navigation graph in the themed composable. DataStore writes are asynchronous, unlike the synchronous `localStorage` write here.
- **React/Web**: Source platform. Files: `packages/web/packages/themes/src/appearance-store.tsx` (this store), `appearance.ts` (defaults, normalisation, storage helpers, `applyAppearance`, `clearAppearance`) and `appearance-prepaint.mjs` (the storage key, the pref lists and the pre-paint script). Specific to the source: module-level state shared by every importer, `useSyncExternalStore` with a server snapshot, one OS listener attached at module load, and `useLayoutEffect` for scopes so the paint lands before the browser's.
- **AppKit / UIKit**: Not the source platform. Use `UserDefaults` for the cache and `NSApp.appearance` (AppKit) or `UIWindow.overrideUserInterfaceStyle` (UIKit) for colour mode, observing `NSApp.effectiveAppearance` with KVO or `traitCollectionDidChange` for the OS flip. A route scope maps to setting the override on the window or view controller that owns the scoped screens and clearing it when they leave.
- **WinUI 3**: Not the source platform. Keep the store as a singleton class implementing `INotifyPropertyChanged` that exposes the prefs (an immutable record) and raises `PropertyChanged` on commit. Persist with `ApplicationData.Current.LocalSettings` (an `ApplicationDataContainer`) and remove the key on sign-out. Resolve `auto` from `UISettings` (`UISettings.ColorValuesChanged` fires on an OS theme flip; `GetColorValue(UIColorType.Background)` gives the current scheme) and set `FrameworkElement.RequestedTheme` (`ElementTheme.Light`, `Dark` or `Default`) on the window's root element; `Default` is the `auto` case. Scopes map to setting `RequestedTheme` on the root of only the scoped `Frame` or page and restoring `Default` when it unloads. Text size and spacing become resource dictionary values merged into `Application.Resources`. `UISettings.ColorValuesChanged` runs on a background thread, so marshal to the UI thread with `DispatcherQueue.TryEnqueue` before repainting; unlike the browser there is no single-thread guarantee. Contrast follows `AccessibilitySettings.HighContrast`, which the store here leaves to CSS.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/themes/src/appearance-store.tsx` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Hold the preferences in a module-level external store read with `useSyncExternalStore` instead of a React Context and Provider.
**Rationale**: The pre-paint script already applies the cached prefs before hydration, so no Provider is needed to supply first values. The module is imported by every site through the shared auth provider, so it must add no mounting requirement. The in-source comment states both reasons.
**Approved**: pending

**Decision**: Treat `localStorage` as a cache of the server's prefs, and make `adoptAppearance` replace rather than merge.
**Rationale**: The prefs follow the person across the family's many domains, so the server is the truth. A merge could leave another user's cached value in a field the server left unset. The in-source comment gives this reason.
**Approved**: pending

**Decision**: `resetAppearance` clears the cache instead of writing the defaults.
**Rationale**: Leaving a stored value would let the next person on that browser inherit the previous user's theme through the pre-paint script.
**Approved**: pending

**Decision**: Once any scope has mounted, paint only while a scope is mounted.
**Rationale**: The OS listener lives for the whole app, and `adoptAppearance` can resolve after the reader left a scoped route. A client navigation keeps the same `<html>`, so painting then would put the prefs on a page (the site template's frame) that never asked for them. A site that never mounts a scope keeps the earlier always-paint behavior.
**Approved**: pending

**Decision**: Probe `window.matchMedia` and the query's `addEventListener` at module scope instead of calling them.
**Rationale**: The module is in every site's import graph and runs this at load; a missing `matchMedia` (a jsdom test renderer was the case that caught it) or a Safari before 14 query with only `addListener` would make the import throw over a cosmetic preference. Absent means no OS signal, so `auto` resolves to light.
**Approved**: pending

**Decision**: Re-resolve only the `dark` class on an OS change; leave reduced motion and contrast to CSS media queries.
**Rationale**: Those two prefs have `auto` and `default` values that remove their attributes, so the browser's own queries govern with no JavaScript.
**Approved**: pending

**Decision**: Do not validate `set` patches or `adoptAppearance` input, and do not listen for `storage` events.
**Rationale**: Normalisation happens at the boundary that receives untrusted data (the cache read, and `AppearanceSync` before adopting); the store trusts its typed callers. Cross-tab sync is absent from the source. Both are recorded here as facts so a port does not assume them.
**Approved**: pending

**Decision**: Colour mode is honoured in every environment, production included.
**Rationale**: Per the comment on `applyAppearance`, a production lock to dark would make the saved setting do nothing where it matters most, now that every site reads it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | reliability |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | privacy-and-data |

`separation-of-concerns` passes: the store holds state, scopes and notification, while defaults, normalisation, storage access and DOM mapping sit in `appearance.ts` and the pre-paint module, shared with the pre-paint script. `unit-test-coverage` is `partial`: the scope tests, `AppearanceScope.test.tsx` and `clearAppearance.test.ts` cover scoping, OS following and clearing, but no test covers the hook, `set` merging, the server snapshot, the missing-`matchMedia` guards or a failing `localStorage`. `explicit-error-handling` is `partial`: storage failures are swallowed deliberately and with a comment, and neither the store nor the helpers signal them, though the in-memory state stays correct. `graceful-degradation` passes: a missing `matchMedia`, a missing `addEventListener` and an unavailable `localStorage` all fall back to the OS-light or in-memory behavior without throwing. `data-retention-policy` passes: the cache is removed on sign-out by design and its lifetime is stated.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
