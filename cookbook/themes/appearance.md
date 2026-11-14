---
id: 0f721fc3-0e8f-4a1b-b895-1b1bad370bd0
title: "Appearance"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Appearance preferences (color mode and accessibility choices): defaults, untrusted-input normalization, localStorage cache, and mapping onto the document element."
platforms:
  - typescript
  - web
tags:
  - theme
  - appearance
  - preferences
  - accessibility
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Appearance

## Overview

Appearance is the pure, framework-agnostic logic behind a user's color mode and accessibility display choices. It owns the `AppearancePrefs` shape, the defaults, the normalization of untrusted stored data, the per-browser `localStorage` cache, and the mapping from preferences onto an HTML element (the `dark` class and `data-*` attributes the theme CSS keys off).

"Default" or "auto" means follow the system (or the theme's own default). It is represented by the absence of an attribute, so an unset preference leaves the document pristine and the matching media query (`prefers-color-scheme`, `prefers-reduced-motion`, `prefers-contrast`) governs.

Two consumers share this code so there is one source of truth for the storage key, the defaults and the DOM mapping: the React store (`appearance-store.tsx`) and the pre-paint inline script (`APPEARANCE_PREPAINT_SCRIPT`). The storage key, the enum-pref defaults, the boolean-pref list and the pre-paint script live in a plain `.mjs` file (`appearance-prepaint.mjs`) so a Vite or Next config, which runs in plain Node, can load them. The same file exports an `appearancePrepaint()` Vite plugin that inlines the script at the end of `<head>`.

This recipe describes the logic, not the React store, the settings panel or the server sync that reconcile the cache with the signed-in user's saved preferences; those are separate components.

## Behavioral Requirements

### Data shapes

- **prefs-shape**: `AppearancePrefs` MUST have exactly seven fields: `colorMode`, `reduceMotion`, `contrast`, `textSize`, `spacing`, `focusOutlines` and `underlineLinks`.
- **color-mode-values**: `colorMode` MUST be one of `auto`, `light`, `dark`.
- **reduce-motion-values**: `reduceMotion` MUST be one of `auto`, `on`, `off`.
- **contrast-values**: `contrast` MUST be one of `default`, `high`, `extra-high`.
- **text-size-values**: `textSize` MUST be one of `default`, `small`, `large`, `extra-large`.
- **spacing-values**: `spacing` MUST be one of `compact`, `comfortable`, `spacious`.
- **boolean-pref-values**: `focusOutlines` and `underlineLinks` MUST be booleans.
- **defaults-values**: `APPEARANCE_DEFAULTS` MUST be `colorMode: auto`, `reduceMotion: auto`, `contrast: default`, `textSize: default`, `spacing: compact`, `focusOutlines: false`, `underlineLinks: false`.
- **enum-pref-defaults-shared**: `ENUM_PREF_DEFAULTS` MUST map `reduceMotion` to `auto`, `contrast` to `default`, `textSize` to `default` and `spacing` to `compact`, and MUST be frozen. These are the values that mean "leave the attribute off".
- **bool-prefs-shared**: `BOOL_PREFS` MUST list `focusOutlines` and `underlineLinks`, and MUST be frozen.
- **storage-key**: `APPEARANCE_STORAGE_KEY` MUST be `adh:appearance`.
- **single-definition**: `applyAppearance`, `clearAppearance` and the pre-paint script MUST iterate the same `ENUM_PREF_DEFAULTS` and `BOOL_PREFS` lists, so adding a preference in one place updates all three. Source: the comments on `ENUM_PREF_DEFAULTS` and `PREPAINT_ATTR_LINES`.
- **colormode-not-in-enum-list**: `colorMode` MUST NOT appear in `ENUM_PREF_DEFAULTS`. It is handled separately because it sets a class as well as an attribute.

### normalizeAppearance

- **normalize-returns-copy**: `normalizeAppearance(raw)` MUST return a new `AppearancePrefs` object that starts as a copy of `APPEARANCE_DEFAULTS`, and MUST NOT mutate `APPEARANCE_DEFAULTS`.
- **normalize-non-object**: `normalizeAppearance` MUST return the defaults when `raw` is falsy or not an object (`null`, `undefined`, a string, a number, `false`, `0`).
- **normalize-per-field**: `normalizeAppearance` MUST accept each field independently, copying a field only when its value is a member of that field's allowed set (or a boolean for the two boolean fields), and MUST leave every other field at its default.
- **normalize-drops-unknown**: `normalizeAppearance` MUST ignore keys that are not one of the seven preference names.
- **normalize-no-throw**: `normalizeAppearance` MUST NOT throw for any input.

### Storage cache

- **read-ssr-guard**: `readStoredAppearance()` MUST return a copy of the defaults when `window` is undefined.
- **read-normalizes**: `readStoredAppearance()` MUST read `localStorage` under `APPEARANCE_STORAGE_KEY`, parse the value as JSON, and return it passed through `normalizeAppearance`.
- **read-missing**: `readStoredAppearance()` MUST return the defaults when the key is absent or empty.
- **read-failure**: `readStoredAppearance()` MUST return a copy of the defaults when storage access or JSON parsing throws. The failure is not reported.
- **write-serializes**: `writeStoredAppearance(prefs)` MUST store `JSON.stringify(prefs)` under `APPEARANCE_STORAGE_KEY`.
- **write-ssr-guard**: `writeStoredAppearance` MUST do nothing when `window` is undefined.
- **write-failure**: `writeStoredAppearance` MUST NOT throw when storage throws (private mode, quota). The write is dropped and the failure is not reported. Source: the comment `ignore (private mode / quota)`.
- **write-does-not-normalize**: `writeStoredAppearance` MUST write the object it is given without normalizing it; normalization happens on read.
- **clear-stored**: `clearStoredAppearance()` MUST remove the `APPEARANCE_STORAGE_KEY` entry. It MUST do nothing when `window` is undefined and MUST NOT throw when storage throws.
- **cache-not-truth**: The stored value MUST be treated as a per-browser cache of the signed-in user's preferences, which live on the server. Source: the comments on `clearStoredAppearance` and the pre-paint script. The cache is cleared on sign-out so it does not outlive the session on a shared browser; the caller, not this module, triggers that.

### applyAppearance

- **apply-resolves-dark**: `applyAppearance(el, prefs, systemPrefersDark)` MUST toggle the `dark` class on `el` to `systemPrefersDark` when `prefs.colorMode` is `auto`, to `true` when it is `dark`, and to `false` when it is `light`.
- **apply-colormode-attribute**: `applyAppearance` MUST always set `data-color-mode` to the value of `prefs.colorMode`, including `auto`.
- **apply-enum-attributes**: For each key in `ENUM_PREF_DEFAULTS`, `applyAppearance` MUST set the matching `data-*` attribute (the camelCase key mapped to kebab case, for example `reduceMotion` to `data-reduce-motion`) to the preference value when it differs from the default, and MUST remove the attribute when it equals the default.
- **apply-bool-attributes**: For each key in `BOOL_PREFS`, `applyAppearance` MUST set the matching `data-*` attribute to `always` when the preference is `true`, and MUST remove it when `false`.
- **apply-system-injected**: `applyAppearance` MUST NOT read `matchMedia` itself; the caller passes `systemPrefersDark`. Source: the doc comment, so the hook and the pre-paint script do not each re-read it.
- **apply-all-environments**: `applyAppearance` MUST honor the stored color mode in every environment, production included, with no environment lock. Source: the doc comment records that colour mode was once pinned dark outside local, staging and testing and that the pin was removed.
- **apply-idempotent**: Calling `applyAppearance` repeatedly with the same arguments MUST leave the element in the same state.

### clearAppearance

- **clear-removes-all**: `clearAppearance(el)` MUST remove the `dark` class, delete `data-color-mode`, and delete every `data-*` attribute for every key in `ENUM_PREF_DEFAULTS` and `BOOL_PREFS`.
- **clear-undoes-apply**: After `applyAppearance` followed by `clearAppearance`, the element MUST be byte-for-byte what it was before `applyAppearance`, including unrelated classes and attributes. Source: `clearAppearance.test.ts`.
- **clear-undoes-prepaint**: `clearAppearance` MUST also remove the attributes the pre-paint script writes for default values (`data-color-mode` set to `auto`, and the `dark` class).
- **clear-purpose**: `clearAppearance` exists for sites that mount the preferences on only some routes; a client navigation keeps the same `<html>`, so without it the preferences would follow the reader onto a page that never asked for them.

### Pre-paint script

- **prepaint-iife**: `APPEARANCE_PREPAINT_SCRIPT` MUST be a self-contained IIFE string that reads `localStorage` under `APPEARANCE_STORAGE_KEY`, parses the JSON, and applies the preferences to `document.documentElement` synchronously.
- **prepaint-resolve-dark**: The script MUST set the `dark` class to `false` for stored `light`, `true` for stored `dark`, and to the result of `matchMedia("(prefers-color-scheme: dark)").matches` for anything else, including no stored value.
- **prepaint-colormode-attribute**: The script MUST set `data-color-mode` to the stored `colorMode`, or to `auto` when it is absent or empty.
- **prepaint-attributes**: The script MUST set each enum attribute only when the stored value is present and differs from that key's default, set each boolean attribute to `always` only when truthy, and delete the attribute otherwise. Its attribute statements MUST be generated from `ENUM_PREF_DEFAULTS` and `BOOL_PREFS`.
- **prepaint-no-validation**: The script MUST NOT validate stored values against the allowed sets; it writes any non-default stored string as the attribute value. Stored data is normalized later by `normalizeAppearance` when the store reads it. This differs from `applyAppearance`, which is only ever handed normalized preferences.
- **prepaint-swallows-errors**: The script MUST wrap its whole body in a try/catch that discards the error. If storage is unavailable, or the stored JSON is invalid or is the literal `null`, the script stops where it failed and leaves whatever it had already applied (nothing, for those cases) so the page renders with system defaults.
- **prepaint-position**: The `appearancePrepaint()` Vite plugin MUST inject the script as an inline `<script>` at the end of `<head>` (`injectTo: "head"`), not the start, so `<meta charset>` stays within the first 1024 bytes the browser scans for the encoding.
- **prepaint-plugin-name**: The plugin MUST be named `adh-appearance-prepaint`.

### Concurrency and side effects

- **single-threaded**: All functions are synchronous and run on the browser main thread; they have no async operations and need no locking.
- **side-effects**: `applyAppearance` and `clearAppearance` mutate only the element passed in. The storage functions touch only `localStorage` under `adh:appearance`. Nothing makes a network call; server sync is outside this module.

## Appearance

Not applicable — this is preferences logic and a DOM-attribute mapping, not a visual component. The visual effect of each attribute is defined by the theme CSS (`styles/accessibility.css`, `styles/color-mode-light.css`), which is outside the source given here.

## States

Not applicable — this is preferences logic, not a visual component; it has no visual states. The enum and boolean preferences are data, described under Behavioral Requirements.

## Accessibility

Not applicable — this is preferences logic, not a visual component. It stores and applies the user's accessibility display choices (reduce motion, contrast, text size, spacing, focus outlines, underlined links) but renders no control; the DOM attributes it sets are consumed by the theme CSS.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| appearance-001 | defaults-values, normalize-non-object | `normalizeAppearance(null)` | Equals `APPEARANCE_DEFAULTS`, as a different object |
| appearance-002 | normalize-per-field | `normalizeAppearance({ colorMode: "dark", contrast: "high", textSize: "huge", focusOutlines: true })` | `colorMode: dark`, `contrast: high`, `focusOutlines: true`; `textSize` stays `default`; others default |
| appearance-003 | normalize-per-field | `normalizeAppearance({ focusOutlines: "true", underlineLinks: 1 })` | Both stay `false` |
| appearance-004 | normalize-non-object, normalize-no-throw | `normalizeAppearance("dark")` and `normalizeAppearance(0)` | Defaults, no throw |
| appearance-005 | normalize-drops-unknown | `normalizeAppearance({ theme: "x", spacing: "spacious" })` | `spacing: spacious`; result has exactly the seven keys |
| appearance-006 | read-missing, storage-key | Empty `localStorage`, `readStoredAppearance()` | Defaults |
| appearance-007 | read-normalizes | `localStorage["adh:appearance"] = '{"colorMode":"light","spacing":"nope"}'` | `colorMode: light`, `spacing: compact` |
| appearance-008 | read-failure | `localStorage["adh:appearance"] = "{not json"` | Defaults, no throw |
| appearance-009 | write-failure | `localStorage.setItem` throws a quota error; `writeStoredAppearance(prefs)` | Returns without throwing |
| appearance-010 | write-serializes, clear-stored | Write `prefs`, then `clearStoredAppearance()` | Key holds `JSON.stringify(prefs)` after the write; key absent after the clear |
| appearance-011 | apply-resolves-dark | `applyAppearance(el, { ...defaults, colorMode: "auto" }, true)` | `el` has class `dark`, `data-color-mode="auto"` |
| appearance-012 | apply-resolves-dark | `applyAppearance(el, { ...defaults, colorMode: "light" }, true)` | No `dark` class, `data-color-mode="light"` |
| appearance-013 | apply-enum-attributes, apply-bool-attributes | `applyAppearance(el, defaults, false)` | `el` has only `data-color-mode="auto"`; no other `data-*` attribute |
| appearance-014 | apply-enum-attributes, apply-bool-attributes | `applyAppearance(el, { ...defaults, reduceMotion: "on", contrast: "extra-high", spacing: "spacious", underlineLinks: true }, false)` | `data-reduce-motion="on"`, `data-contrast="extra-high"`, `data-spacing="spacious"`, `data-underline-links="always"`; no `data-focus-outlines` |
| appearance-015 | apply-enum-attributes | Apply a non-default `contrast`, then apply `contrast: default` | `data-contrast` is removed |
| appearance-016 | clear-undoes-apply | Test `clearAppearance leaves the element as it was before applyAppearance` | Element with classes `font-a font-b` and `lang="en"` has identical `outerHTML` after apply-then-clear of every attribute |
| appearance-017 | clear-undoes-prepaint, clear-removes-all | Test `clearAppearance removes the attributes the pre-paint script writes for the defaults too` | `data-color-mode` and the `dark` class are gone |
| appearance-018 | prepaint-resolve-dark, prepaint-colormode-attribute | Run the script with `{"colorMode":"dark"}` stored | `dark` class on `<html>`, `data-color-mode="dark"` |
| appearance-019 | prepaint-resolve-dark, prepaint-colormode-attribute | Run the script with nothing stored and `matchMedia` reporting dark | `dark` class on `<html>`, `data-color-mode="auto"` |
| appearance-020 | prepaint-attributes | Run the script with `{"contrast":"default","textSize":"large","focusOutlines":false}` stored | `data-text-size="large"` only; no `data-contrast`, no `data-focus-outlines` |
| appearance-021 | prepaint-swallows-errors | Run the script with the literal text `null` stored | No exception escapes; `<html>` is left without the `dark` class and without `data-color-mode` |
| appearance-022 | prepaint-no-validation | Run the script with `{"contrast":"bogus"}` stored | `data-contrast="bogus"` is written |
| appearance-023 | prepaint-position, prepaint-plugin-name | `appearancePrepaint().transformIndexHtml()` | One tag, `script`, `children` equal to `APPEARANCE_PREPAINT_SCRIPT`, `injectTo: "head"`; plugin `name` is `adh-appearance-prepaint` |
| appearance-024 | enum-pref-defaults-shared, bool-prefs-shared | `Object.isFrozen` on each of the two exports | `true` for both |

## Edge Cases

- **Non-object stored value**: a stored JSON string, number or array is normalized to a copy of the defaults with no field accepted. `readStoredAppearance` MUST NOT throw.
- **Partial stored object**: a stored object with only some fields keeps the defaults for the missing ones. MUST.
- **Out-of-range enum value**: an unrecognized string for any enum preference falls back to that field's default in `normalizeAppearance`. MUST. The pre-paint script writes it unchanged until the store re-applies normalized preferences (see `prepaint-no-validation`).
- **Wrong type for a boolean**: a string, number or `null` for `focusOutlines` or `underlineLinks` leaves it `false`. MUST.
- **Server-side rendering**: with no `window`, read returns defaults and write and clear do nothing. MUST.
- **Storage blocked, private mode or quota exceeded**: read returns the defaults; write and clear are silent no-ops. MUST. Nothing is logged and the caller receives no signal, so a preference that failed to cache is lost on reload.
- **Stored literal `null`**: `readStoredAppearance` returns the defaults. The pre-paint script throws inside its own try/catch and applies nothing. MUST.
- **Corrupt JSON**: read returns the defaults; the pre-paint script applies nothing. MUST.
- **Concurrent access**: all calls are synchronous on one thread, so they cannot interleave. Two browser tabs share one `localStorage` key and the last write wins; this module has no cross-tab synchronization. This is a fact about the source, not a requirement.
- **Offline or disconnected**: not applicable; the module makes no network requests.
- **Element reuse across routes**: `clearAppearance` MUST restore the element exactly, so a site that wears preferences on only some routes does not leak them onto others.
- **Unrelated element state**: `applyAppearance` and `clearAppearance` MUST NOT touch classes other than `dark` or attributes other than the ones named above.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `APPEARANCE_STORAGE_KEY` | string | `adh:appearance` | `localStorage` key for the cached preferences |
| `APPEARANCE_DEFAULTS` | `AppearancePrefs` | see `defaults-values` | Starting preferences and the fallback for invalid fields |
| `ENUM_PREF_DEFAULTS` | frozen object | see `enum-pref-defaults-shared` | Per-key value meaning "attribute off" |
| `BOOL_PREFS` | frozen string array | `focusOutlines`, `underlineLinks` | Boolean preference keys written as `always` |
| `systemPrefersDark` | boolean | none (caller supplies) | Argument to `applyAppearance`; the already-resolved OS dark preference |
| `el` | `HTMLElement` | none (caller supplies) | Argument to `applyAppearance` and `clearAppearance`; normally `document.documentElement` |

## Deep Linking

Not applicable: the module reads and writes preferences and has no routes or URLs.

## Localization

Not applicable: the module defines no user-facing strings; all values are machine tokens (`dark`, `extra-high`, `always`).

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Stored as `reduceMotion`; `on` and `off` set `data-reduce-motion`, `auto` leaves it off so `prefers-reduced-motion` governs |
| Increase Contrast | Stored as `contrast`; `high` and `extra-high` set `data-contrast`, `default` leaves it off so `prefers-contrast` governs |
| Differentiate Without Color | Not applicable: the module has no preference by that name; the nearest are `underlineLinks` (sets `data-underline-links="always"`) and `focusOutlines` (sets `data-focus-outlines="always"`) |

## Feature Flags

Not applicable: the module reads no flags; its behavior is fixed by the exported constants.

## Analytics

Not applicable: the module emits no events.

## Privacy

- **Data collected**: the user's display preferences (color mode, motion, contrast, text size, spacing, focus outlines, link underlines). No identifiers.
- **Storage**: `localStorage` key `adh:appearance` in the user's browser, as a cache of preferences held on the server for signed-in users.
- **Transmission**: none from this module; the server sync is separate.
- **Retention**: until `clearStoredAppearance` runs (the caller invokes it on sign-out so the cache does not outlive the session on a shared browser) or the user clears site data.

## Logging

Not applicable: the module makes no log calls; storage failures are discarded without a message.

## Platform Notes

- **SwiftUI**: The source platform is web, so translate. Hold the seven preferences in an `@Observable` model persisted with `@AppStorage` or `UserDefaults` under the same key, and apply them with `.preferredColorScheme(_:)` with `nil`, `.light` or `.dark`, where `nil` is `auto`. Read `@Environment(\.accessibilityReduceMotion)`, `\.colorSchemeContrast` and `\.dynamicTypeSize` for the system values. Unlike the source, the system already supplies the follow-the-OS values, so `auto`, `default` and `compact` map to not overriding the environment value rather than to an absent attribute. There is no pre-paint step.
- **Compose**: Keep the preferences in a data class persisted with DataStore (Preferences) and exposed as a `StateFlow`. Resolve `auto` with `isSystemInDarkTheme()` and pass the result into the `MaterialTheme` color scheme, scaling typography by `textSize` and spacing by `spacing`. Read reduced motion from the animator duration scale setting. There are no `data-*` attributes; the default-means-absent rule becomes a nullable override.
- **React/Web**: Source platform. `packages/web/packages/themes/src/appearance.ts` holds the typed API; `appearance-prepaint.mjs` holds the shared constants, the inline script and the Vite plugin so plain-Node configs can import them (`appearance-prepaint.d.mts` declares their types). The hook and store in `appearance-store.tsx` and the CSS in `styles/accessibility.css` and `styles/color-mode-light.css` consume it. The script is a hand-written ES5-style string so it can run inline before any bundle loads.
- **AppKit / UIKit**: Persist with `UserDefaults`. Resolve `auto` by leaving `NSApp.appearance` (AppKit) or `overrideUserInterfaceStyle` (UIKit) unset, and set `.aqua` or `.darkAqua` (AppKit) or `.light` or `.dark` (UIKit) for the explicit modes. Observe `NSWorkspace.accessibilityDisplayShouldReduceMotion` and `accessibilityDisplayShouldIncreaseContrast` on macOS, and `UIAccessibility` equivalents on iOS. Text size and spacing become scale factors applied by the app's own layout code; there is no document element to annotate.
- **WinUI 3**: Persist the record with `Windows.Storage.ApplicationData.Current.LocalSettings` (or a JSON file serialized with `System.Text.Json`) and expose it from a class implementing `INotifyPropertyChanged`. Apply color mode by setting `FrameworkElement.RequestedTheme` on the root element (`ElementTheme.Default`, `Light` or `Dark`); `Default` follows the system, which is the `auto` case. Read system values from `Windows.UI.ViewManagement.UISettings` (`AnimationsEnabled`, `TextScaleFactor`) and `AccessibilitySettings.HighContrast`, and listen to `UISettings.ColorValuesChanged` in place of the `matchMedia` change listener. Express contrast, spacing and text size as `ResourceDictionary` entries (`ThemeDictionaries` with `Default`, `Light`, `Dark` and `HighContrast` keys) swapped at runtime, focus outlines as a custom focus visual resource, and link underlines through `Hyperlink.UnderlineStyle`. Attribute absence has no equivalent; use nullable properties or the `Default` enum member. The source's synchronous `localStorage` becomes `LocalSettings` (synchronous) or `StorageFile` (`async`/`await`).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| ios | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |
| web | `packages/web/packages/themes/src/appearance.ts` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Default and `auto` are represented by the absence of a `data-*` attribute, except `data-color-mode`, which is always set.
**Rationale**: An unset preference leaves the document pristine so the matching `@media` query governs; `colorMode` is always recorded because `applyAppearance` also resolves the `dark` class itself.
**Approved**: pending

**Decision**: The storage key, the pref lists and the pre-paint script live in a plain `.mjs` file, and `appearance.ts` imports and re-exports them.
**Rationale**: A Vite or Next config runs in plain Node before any bundler exists and cannot load TypeScript, yet it needs the script; one definition feeds the config, the script and the browser code.
**Approved**: pending

**Decision**: The pre-paint script reads `localStorage` as a cache, not the truth, and applies it without validation.
**Rationale**: A returning signed-in user repaints in their own color mode with no flash; the truth arrives from the server and corrects the document, and the cache is cleared on sign-out so the next visitor is not handed a stranger's theme. Skipping validation keeps the inline script small, at the cost that a corrupted cache value is written as an attribute until the store normalizes it.
**Approved**: pending

**Decision**: Storage failures on write and clear are discarded, and read failures fall back to defaults, with no log or error returned.
**Rationale**: Private mode and quota errors are routine and must never break rendering; the cost is that a failed cache write is invisible to the caller.
**Approved**: pending

**Decision**: Color mode is honored in every environment, production included.
**Rationale**: It was once pinned dark outside local, staging and testing, when light was an unfinished preview. Every site now reads the signed-in user's saved mode, and a production lock would make the setting silently do nothing where it matters most.
**Approved**: pending

**Decision**: `clearAppearance` exists alongside `applyAppearance` and iterates the same lists.
**Rationale**: A client navigation keeps the same `<html>`, so a site that wears preferences on only some routes must be able to remove exactly what was applied.
**Approved**: pending

**Decision**: The Vite plugin injects the script at the end of `<head>`.
**Rationale**: Prepended, it and the dev server's preamble push `<meta charset>` past the first 1024 bytes, where browsers stop looking for the encoding; a script anywhere in `<head>` still runs before the body paints.
**Approved**: pending

**Decision**: Test coverage for this module is indirect: `clearAppearance.test.ts` exercises `applyAppearance` and `clearAppearance` directly, and `appearanceScope.test.ts` and `AppearanceScope.test.tsx` exercise them through the store. No test file targets `normalizeAppearance`, the storage functions or the pre-paint script, so the vectors for those are derived from the source.
**Rationale**: Records the evidence source for the vectors above, per the source-fidelity guideline.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | privacy-and-data |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | accessibility |

Separation of concerns passes: the pure logic, the plain-Node constants and script, and the React store are three separate files, and the DOM mapping takes the element and the system preference as arguments. Unit-test coverage is partial: `clearAppearance.test.ts` covers apply and clear directly and the scope tests cover the store, but `normalizeAppearance`, the storage functions and the pre-paint script have no direct test. Explicit error handling is partial: storage and parse failures are caught and fall back to defaults, but they are discarded without a signal. Data retention passes because the cache is cleared by `clearStoredAppearance` on sign-out. Reduced motion passes because `reduceMotion` is a stored preference that falls back to the media query when `auto`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Claims verified against source |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
