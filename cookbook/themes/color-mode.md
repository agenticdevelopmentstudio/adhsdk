---
id: 3bff70de-bfca-4bfd-b112-2a6044416ddc
title: "Color Mode"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "ColorModeProvider and useColorMode: auto, light or dark choice persisted in localStorage and applied to the document as a dark class and a data attribute."
platforms:
  - typescript
  - web
tags:
  - theme
  - color-mode
  - appearance
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Color Mode

## Overview

Color Mode is the legacy, Provider-based color-mode context of the customer-facing toolkit. `ColorModeProvider` holds the user's choice (`auto`, `light` or `dark`), resolves `auto` against the operating system's `prefers-color-scheme` setting, persists the choice in `localStorage`, and writes the result onto the document root. `useColorMode` gives descendants the choice, the resolved mode, a setter and a cycle operation.

The source's header comment states that the ADH chrome and sites use a newer, Provider-free appearance system instead (`appearance.ts` and `appearance-store.tsx`, storage key `adh:appearance`, attribute `data-color-mode`), that the two are intentionally separate, and that they must not both be mounted on one document. This recipe covers only the legacy context.

## Behavioral Requirements

### Types and exports

- **color-mode-type**: `ColorMode` MUST be exactly one of `auto`, `light` or `dark`.
- **resolved-color-mode-type**: `ResolvedColorMode` MUST be exactly one of `light` or `dark`, never `auto`.
- **context-value-shape**: The value returned by `useColorMode` MUST carry `mode` (a `ColorMode`), `resolved` (a `ResolvedColorMode`), `setMode(mode)` and `cycle()`.
- **provider-props**: `ColorModeProvider` MUST accept `children`, an optional `storageKey` and an optional `defaultMode`.
- **client-only-module**: The module MUST be marked `'use client'`, so a server-component framework treats it as client code.

### Initial mode

- **initial-mode-from-storage**: On first render the provider MUST use the value stored under `storageKey` when it is exactly `light`, `dark` or `auto`.
- **initial-mode-from-legacy-key**: When `storageKey` equals the default `adh-sdk:color-mode` and nothing valid is stored under it, the provider MUST read the pre-rename key `agentic-toolkit:color-mode` and use its value when valid.
- **legacy-key-only-for-default**: The provider MUST NOT read `agentic-toolkit:color-mode` when a custom `storageKey` is supplied.
- **initial-mode-default**: When no valid stored value is found, the provider MUST use `defaultMode`, which defaults to `auto`.
- **invalid-stored-value-ignored**: A stored value other than `light`, `dark` or `auto` MUST be treated as absent.
- **no-window-initial-mode**: When `window` is undefined (server render), the stored-value read MUST return nothing, so the initial mode is `defaultMode`.

### Resolution

- **resolve-explicit-mode**: When `mode` is `light` or `dark`, `resolved` MUST equal `mode`.
- **resolve-auto-from-system**: When `mode` is `auto`, `resolved` MUST be `dark` if the media query `(prefers-color-scheme: dark)` matches and `light` otherwise.
- **system-dark-initial**: The provider MUST read the media query once during the first render, and MUST treat the system as not dark when `window` is undefined.
- **system-change-listener**: The provider MUST subscribe to `change` events on the `(prefers-color-scheme: dark)` media query after mount and update `resolved` when `mode` is `auto`.
- **system-listener-cleanup**: The provider MUST remove its media query listener on unmount.

### Document effects

- **dark-class**: The provider MUST add the class `dark` to `document.documentElement` when `resolved` is `dark` and remove it when `resolved` is `light`.
- **appearance-mode-attribute**: The provider MUST set `data-appearance-mode` on `document.documentElement` to the current `mode` (`auto`, `light` or `dark`), not to the resolved value.
- **no-attribute-removal**: The provider MUST NOT remove the `dark` class or `data-appearance-mode` attribute when it unmounts; the source has no cleanup for them.
- **changed-event**: After each change of `mode` or `resolved`, including the first effect run on mount, the provider MUST dispatch a `CustomEvent` named `awt:appearance-changed` on `window`.
- **no-document-effects**: When `document` is undefined the provider MUST skip the class and attribute writes, and when `window` is undefined it MUST skip the event dispatch.

### Persistence

- **persist-explicit-mode**: When `mode` is `light` or `dark`, the provider MUST write it to `localStorage` under `storageKey`.
- **persist-auto-removes**: When `mode` is `auto`, the provider MUST remove `storageKey` from `localStorage` rather than write `auto`.
- **persist-on-first-render**: The persistence effect runs on mount as well as on change, so a mode chosen from the default or the legacy key MUST be written (or removed) under `storageKey` immediately after the first render.
- **legacy-key-not-cleaned**: The provider MUST NOT write to or remove `agentic-toolkit:color-mode`; the legacy key is read only.
- **storage-failure-silent**: A throwing `localStorage` read, write or remove MUST be caught and ignored (the source marks each catch `/* ignore */`), with no log or other signal; the choice then fails to persist while state and document effects continue.

### Operations

- **set-mode**: `setMode(mode)` MUST replace the current mode with the given `ColorMode`; the source performs no validation of the argument beyond its TypeScript type.
- **cycle-order**: `cycle()` MUST advance the mode through the fixed order `auto`, `dark`, `light`, then back to `auto`.
- **cycle-fallback**: When the current mode is not found in the cycle order, `cycle()` MUST fall back to `auto`.
- **cycle-event**: The provider MUST listen on `window` for an event named `awt:appearance-cycle` and call `cycle()` for each one received, after mount.
- **cycle-event-cleanup**: The provider MUST remove the `awt:appearance-cycle` listener on unmount.
- **stable-callbacks**: `cycle` MUST keep a stable identity across renders, and the context value MUST be memoized on `mode`, `resolved` and `cycle`.

### Consumption

- **hook-requires-provider**: `useColorMode` MUST throw an `Error` with the message `useColorMode must be used within a <ColorModeProvider>` when called outside a provider.
- **single-appearance-system**: A document MUST NOT mount both this provider and the newer appearance system, which uses `adh:appearance` and `data-color-mode`; the source documents this as a caller precondition and does not detect a violation.

### Ordering and concurrency

Not applicable: the provider is a React client component whose state changes run on the single JavaScript thread; effects for one `mode` or `resolved` change run in declaration order (document writes, then persistence), and no operation is asynchronous.

## Appearance

Not applicable — this is a context provider and hook, not a visual component. It renders only its children; its visible effect is the `dark` class and `data-appearance-mode` attribute that stylesheets elsewhere select on.

## States

Not applicable — this is a context provider and hook, not a visual component. The three modes and two resolved values are logical state, specified under Behavioral Requirements.

## Accessibility

Not applicable — this is a context provider and hook, not a visual component. The accessible toggle that consumes it is a separate control (`AppearanceModeToggle`); this module only follows the operating system's color-scheme preference when the mode is `auto`.

## Conformance Test Vectors

The only test beside the source that exercises the provider is `AppearanceModeToggle.test.tsx` in the controls package, which wraps a toggle in `ColorModeProvider`; vectors 001 and 002 derive from its behavior and the rest from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| color-mode-001 | initial-mode-default, cycle-order | `AppearanceModeToggle.test.tsx` "exposes an aria-label that changes after a click": empty storage, system light, default props; the toggle calls `cycle()` once | `mode` goes `auto` to `dark`; the consumer's rendered label differs before and after |
| color-mode-002 | context-value-shape, hook-requires-provider | `AppearanceModeToggle.test.tsx` "renders a button with the awt-appearance-mode-toggle class" (the toggle renders inside `ColorModeProvider`); the same consumer rendered with no provider (derived from the source, not tested) | inside: `useColorMode` returns the context value; outside: throws `useColorMode must be used within a <ColorModeProvider>` |
| color-mode-003 | initial-mode-from-storage, invalid-stored-value-ignored | `localStorage['adh-sdk:color-mode']` is `dark`, then is `purple` | first render mode is `dark`; with `purple` the mode is `auto` |
| color-mode-004 | initial-mode-from-legacy-key, legacy-key-only-for-default, legacy-key-not-cleaned | only `localStorage['agentic-toolkit:color-mode']` is `light`; once with the default key and once with `storageKey="x"` | default key: mode `light` and `adh-sdk:color-mode` becomes `light`, legacy key untouched; custom key: mode `auto` |
| color-mode-005 | resolve-auto-from-system, dark-class | mode `auto`, `matchMedia('(prefers-color-scheme: dark)').matches` is true | `resolved` is `dark`, `document.documentElement` has class `dark`, `data-appearance-mode` is `auto` |
| color-mode-006 | system-change-listener | mode `auto`; the media query fires `change` with `matches: false` after being true | `resolved` becomes `light` and the `dark` class is removed |
| color-mode-007 | resolve-explicit-mode, appearance-mode-attribute | `defaultMode="light"` while the system is dark | `resolved` is `light`, no `dark` class, `data-appearance-mode` is `light` |
| color-mode-008 | persist-explicit-mode, persist-auto-removes | `setMode('dark')` then `setMode('auto')` | storage holds `dark` after the first call; the key is absent after the second |
| color-mode-009 | cycle-order, cycle-fallback | `cycle()` called four times from `auto` | modes are `dark`, `light`, `auto`, `dark` |
| color-mode-010 | cycle-event | `window.dispatchEvent(new CustomEvent('awt:appearance-cycle'))` from `auto` | mode becomes `dark` |
| color-mode-011 | changed-event | provider mounts, then `setMode('light')` | `awt:appearance-changed` is dispatched once on mount and once after the change |
| color-mode-012 | storage-failure-silent | `localStorage.getItem` and `setItem` throw | provider renders with `defaultMode`, `setMode` still updates state and the document, no exception reaches the caller |
| color-mode-013 | no-window-initial-mode, no-document-effects | server render with `window` undefined | mode is `defaultMode`, `systemDark` is false, no document access occurs |

## Edge Cases

- **Empty or missing storage** (MUST): with no stored value the mode is `defaultMode`; with `defaultMode` omitted it is `auto`.
- **Unrecognised stored value** (MUST): a stored string that is not `light`, `dark` or `auto`, for example an empty string, is ignored and the fallback chain continues to the legacy key and then `defaultMode`.
- **Unreadable storage** (MUST): when `localStorage` throws on read, write or remove (disabled storage, quota, privacy mode), the error is caught and discarded; state and document effects continue and only persistence is lost. See `storage-failure-silent`.
- **Non-auto defaultMode loses the auto choice** (MUST): because `auto` is persisted by removing the key, a provider whose `defaultMode` is `light` or `dark` restores that default on the next load even when the user last chose `auto`.
- **Legacy key resurrects after auto** (MUST): with the default `storageKey`, choosing `auto` removes `adh-sdk:color-mode` but not `agentic-toolkit:color-mode`, so a surviving legacy value is read again on the next load.
- **Server render and hydration** (MUST): on the server the initial mode is `defaultMode` and `systemDark` is false; the client initializer reads real storage and the real media query, so the first client render can differ from the server markup.
- **Cross-tab changes** (not provided): the provider has no `storage` event listener, so a choice made in another tab is not picked up until reload.
- **Both appearance systems mounted** (precondition): the two systems write different keys and attributes and the source does not guard against mounting both, so the document would carry both sets.
- **Unmount** (MUST): listeners are removed, but the `dark` class, `data-appearance-mode` attribute and stored value remain.
- **Concurrent calls** (MUST): `setMode` and `cycle` use React state updates; `cycle` uses the functional updater, so several `cycle()` calls in one batch each advance the mode.
- **Invalid mode through `setMode`** (not validated): an untyped caller can pass any string; it becomes `mode`, `resolved` becomes that string, and it is written to storage and discarded as invalid on the next load.
- **Network and offline**: not applicable; the provider performs no network access.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storageKey` | `string` | `adh-sdk:color-mode` | `localStorage` key for the persisted choice; the legacy fallback applies only to the default |
| `defaultMode` | `ColorMode` | `auto` | Mode used when nothing valid is stored |
| `children` | `ReactNode` | required | Subtree that receives the context |

Fixed constants: cycle order `auto`, `dark`, `light`; legacy key `agentic-toolkit:color-mode`; cycle event `awt:appearance-cycle`; changed event `awt:appearance-changed`; media query `(prefers-color-scheme: dark)`; document class `dark`; document attribute `data-appearance-mode`.

## Deep Linking

Not applicable: the module reads no URL and registers no routes.

## Localization

The only string is the thrown message `useColorMode must be used within a <ColorModeProvider>`, hardcoded in English and not externalised; it is a developer error, not user-facing text.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (hardcoded) | `useColorMode must be used within a <ColorModeProvider>` | Error thrown by `useColorMode` outside a provider |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the module animates nothing. |
| Increase Contrast | Not applicable: the module selects light or dark only and reads no contrast preference. |
| Differentiate Without Color | Not applicable: the module has no visual output. |

In `auto` mode it follows the operating system's `prefers-color-scheme` setting live.

## Feature Flags

Not applicable: the module reads no feature flag.

## Analytics

Not applicable: the module emits no analytics. Its `awt:appearance-changed` window event is an in-page notification for other code, not a telemetry event.

## Privacy

- **Data collected**: the user's color-mode preference only.
- **Storage**: `localStorage` under `storageKey`, only for `light` or `dark`; `auto` removes the key.
- **Transmission**: none; the value never leaves the browser.
- **Retention**: until the user chooses `auto`, clears site data, or the browser evicts storage; the legacy key is never cleaned up by this code.

## Logging

Not applicable: the module makes no log calls; storage errors are discarded without logging.

## Platform Notes

- **SwiftUI**: Start from `@AppStorage` or `UserDefaults` for the stored choice and `@Environment(\.colorScheme)` for the system value; apply the resolved mode with `.preferredColorScheme(nil)` for auto and `.light` or `.dark` otherwise. There is no document element or class, and no cross-component window event; use a shared `ObservableObject` or the Observation framework instead.
- **Compose**: Hold the mode in a `ViewModel` or `rememberSaveable` with DataStore persistence, resolve auto with `isSystemInDarkTheme()`, and pass the result to `MaterialTheme` with a dark or light color scheme. System changes recompose automatically, so no listener is needed.
- **React/Web**: The source is `packages/web/packages/themes/src/colorMode.tsx`, a `'use client'` module re-exported from the themes package and imported by the controls package as `@adh-sdk/themes/colorMode`. It uses `createContext`, `useState` initializers, `matchMedia` and `localStorage` guarded by `typeof window` and `typeof document`. Its hydration risk comes from reading storage in a state initializer.
- **AppKit / UIKit**: Persist with `UserDefaults` and apply the resolved mode through `NSApplication.appearance` (set to `NSAppearance(named: .darkAqua)`, `.aqua` or nil for auto) on macOS, or `overrideUserInterfaceStyle` on `UIWindow` on iOS. System changes arrive through KVO on `effectiveAppearance` or `traitCollectionDidChange`.
- **WinUI 3**: Store the choice with `ApplicationData.Current.LocalSettings` (or `Windows.Storage.ApplicationDataContainer`), keep it in a class implementing `INotifyPropertyChanged`, and apply it by setting `FrameworkElement.RequestedTheme` on the root element to `ElementTheme.Default` (auto), `Light` or `Dark`. For auto, read `UISettings.GetColorValue(UIColorType.Background)` and subscribe to `UISettings.ColorValuesChanged`, marshalling to the UI thread through `DispatcherQueue.TryEnqueue`. Resource dictionaries use `ThemeDictionaries` keyed `Light` and `Dark`, which replace the CSS `dark` class. The window-event cycle command maps to an `ICommand` bound to a toggle button, and the cycle order is a plain array indexed modulo three.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/themes/src/colorMode.tsx` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Persist `auto` by removing the stored key instead of writing `auto`.
**Rationale**: Inferred from the source, which removes the key when `mode` is `auto`; it keeps storage empty for users who never chose, but it makes `defaultMode` and the legacy key take effect again after an `auto` choice.
**Approved**: pending

**Decision**: Keep the pre-rename key `agentic-toolkit:color-mode` as a read-only fallback for the default `storageKey`.
**Rationale**: The source comment says builds from before the SDK rename stored the same choice there; reading it preserves users' choices without a migration step, at the cost of never deleting the old value.
**Approved**: pending

**Decision**: Keep this Provider-based context separate from the newer appearance system and forbid mounting both.
**Rationale**: The header comment states the two use different keys and attributes and the legacy one stays until the toolkit migrates; `useAppearancePreferences` is canonical for ADH.
**Approved**: pending

**Decision**: Cycle in the order `auto`, `dark`, `light`.
**Rationale**: The `CYCLE` constant fixes the order; the source gives no reason, so the order is recorded as observed.
**Approved**: pending

**Decision**: Broadcast changes and accept cycle requests through `window` events (`awt:appearance-changed`, `awt:appearance-cycle`).
**Rationale**: Inferred from the source: it lets non-React code and unrelated components react to or trigger a cycle without sharing the context.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | platform-compliance |

The provider keeps one concern: it owns the mode, resolution, persistence and document attributes, and leaves the toggle control and the stylesheets to other modules, so separation of concerns passes. No test sits beside `colorMode.tsx`; the only test that touches it is the controls package's `AppearanceModeToggle.test.tsx`, which covers a small part of the behavior, so unit-test coverage fails. Misuse outside a provider throws a clear error, but storage failures are discarded without a signal, so explicit error handling is partial. Following `prefers-color-scheme` and offering an explicit override satisfies platform theming.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
