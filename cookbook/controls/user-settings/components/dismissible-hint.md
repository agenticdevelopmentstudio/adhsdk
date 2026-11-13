---
id: 17398d3a-df67-44c6-89c5-0edfc09bff7c
title: "Dismissible Hint"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A hint component with persistent dismissal state stored in localStorage."
platforms:
  - typescript
  - web
tags:
  - hint
  - dismissible
  - notification
  - local-storage
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Dismissible Hint

## Overview

A dismissible hint displays contextual information to the user with a close button. The dismissal state persists across sessions in browser local storage. When the user closes the hint, it is hidden and its dismissed state is remembered by unique identifier.

## Behavioral Requirements

- **accept-id-prop**: Component MUST accept a required string `id` prop that uniquely identifies this hint instance.
- **render-children**: Component MUST render the `children` prop as the hint's text content.
- **render-close-button**: Component MUST render a close button that, when clicked, dismisses the hint and persists the dismissal state.
- **render-close-glyph**: Component MUST render the close button with the literal text content "×".
- **persist-dismissal-state**: Component MUST persist dismissal state to browser localStorage with the key `{{app_prefix}}-hint-dismissed:<id>` set to the value `1`.
- **load-dismissal-state-on-mount**: Component MUST load dismissal state from localStorage on mount using the hint's `id` and set initial visibility accordingly.
- **not-render-when-dismissed**: Component MUST render as `null` if the dismissal state in localStorage indicates the hint has been previously dismissed.
- **handle-missing-localstorage**: Component MUST silently treat any localStorage read or write error as a failure and continue without throwing. On read error, the component MUST treat the hint as not dismissed (render normally). On write error, the component MUST still update its in-memory dismissed state to hidden for the current render, even though the value did not persist.
- **accept-classname-prop**: Component MUST accept an optional `className` prop and apply it to the container element, merged with the base class `{{app_prefix}}-hint`.
- **apply-note-role**: Component MUST render the container with `role="note"` for semantic accessibility.
- **label-close-button**: Component MUST render the close button with `aria-label="Dismiss"`.

## Appearance

Not applicable: Component styling is entirely CSS-driven; the source code provides no hardcoded visual specifications. The component outputs class names (`{{app_prefix}}-hint`, `{{app_prefix}}-hint__text`, `{{app_prefix}}-hint__close`) that are styled by external CSS.

## States

| State | Appearance change |
|-------|------------------|
| Shown (initial or first visit) | Hint container and text visible; close button visible |
| Dismissed (user clicked close or dismissal state loaded) | Container renders as null; element removed from DOM |

## Accessibility

- Role: `note` — semantic container for informational content.
- Close button label: `aria-label="Dismiss"` — announces button purpose to screen readers.
- Minimum tap target: This is a web-only ingredient; per WCAG 2.5.8 (Target Size Minimum) interactive targets SHOULD be at least 24×24 CSS px, with 44×44 CSS px recommended for comfortable use. Visual tap target size is determined by CSS; the source sets no explicit dimensions.
- Keyboard navigation: The close button MUST be keyboard-navigable as a standard `<button>` element; user can Tab to it and press Enter or Space to dismiss (see **dismissible-hint-010**).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| dismissible-hint-001 | accept-id-prop, render-children | `<DismissibleHint id="test-hint">Example hint text</DismissibleHint>` | Container with `role="note"` renders; text "Example hint text" is visible |
| dismissible-hint-002 | render-close-button, label-close-button, render-close-glyph | Render with close button visible | Button with `aria-label="Dismiss"` and text content "×" is present |
| dismissible-hint-003 | persist-dismissal-state | Click close button; inspect localStorage | Entry `{{app_prefix}}-hint-dismissed:test-hint=1` exists in localStorage |
| dismissible-hint-004 | load-dismissal-state-on-mount | localStorage already contains `{{app_prefix}}-hint-dismissed:test-hint=1`; mount component | Component renders as null; nothing displayed |
| dismissible-hint-005 | not-render-when-dismissed | Click close button; inspect the DOM immediately, in the same session, without remounting | Container is removed from the DOM immediately after the click |
| dismissible-hint-006 | accept-classname-prop | `<DismissibleHint id="test" className="custom-class">text</DismissibleHint>` | Container has class list containing both `{{app_prefix}}-hint` and `custom-class` |
| dismissible-hint-007 | handle-missing-localstorage | localStorage.getItem raises exception during read | Component treats hint as not dismissed; renders normally |
| dismissible-hint-008 | handle-missing-localstorage | localStorage.setItem raises exception on close button click | Component's in-memory state updates (local state shows as dismissed) but localStorage write silently fails |
| dismissible-hint-009 | apply-note-role | Render component | Container div has `role="note"` |
| dismissible-hint-010 | render-close-button, label-close-button | Tab to close button (keyboard focus); press Enter or Space | Hint dismisses, same as a pointer click — the native `<button>` element responds to Enter/Space activation |

## Edge Cases

- **localStorage unavailable (private browsing, quota exceeded, or access denied)**: Reading throws exception → component treats as not dismissed and renders (see **handle-missing-localstorage**). Writing throws exception → in-memory state still updates so the hint appears dismissed in the current session, but state is not persisted. User will see the hint again on page reload or next session.
- **Initial render before dismissal state loads**: `dismissed` state starts as `false` on every mount (client and server); the `useEffect` that reads localStorage runs after the first paint. A hint that was previously dismissed is therefore visible for one paint before the next render hides it. The source does not use a synchronous read or a lazy initializer to avoid this — the brief flash is the actual, expected behavior of the mount-effect approach.
- **SSR context (window undefined)**: `readDismissed` returns false and `writeDismissed` returns early. Component renders on server as not dismissed; on client hydration, reads dismissal state and may re-render as dismissed (same flash described above).
- **Empty or missing children**: Component renders container and close button with no text content (children is optional). Display depends on CSS.
- **Missing or empty id prop**: `id` is typed as a required `string`, so omitting it fails TypeScript type checking at compile time. An empty string (`id=""`) still satisfies the type and is accepted at runtime: the component reads and writes the deterministic key `{{app_prefix}}-hint-dismissed:` (empty suffix), so every hint with an empty `id` shares that one dismissal entry. The source performs no further validation of `id`'s contents.
- **Multiple instances with same id**: All instances sharing an `id` read and write the same localStorage entry. Dismissing one instance does not notify the others in the same session — the source has no `storage` event listener or shared store, so the other instances keep their own in-memory `dismissed` state and stay visible until they remount or the page reloads, at which point they read the dismissed value and render as `null`. This lack of same-session sync is the source's actual behavior.
- **id changed after mount**: The effect's dependency on `id` makes it re-run whenever `id` changes, calling `readDismissed` again. The `dismissed` state is fully replaced by the new id's stored value; it does not carry over the old id's state. A hint dismissed under the old `id` reappears if the new `id` is not (yet) dismissed, and vice versa.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| id | string | (required) | Unique identifier for this hint instance; used as suffix for localStorage key. |
| children | ReactNode | undefined | Hint text or content to display. |
| className | string | undefined | Additional CSS class to merge with `{{app_prefix}}-hint` base class. |

## Deep Linking

Not applicable: Dismissible hints are not navigation endpoints; they are informational UI elements without associated URLs or deep linking patterns.

## Localization

Applicable: the component renders one hardcoded, non-localizable, user-facing string — the close button's `aria-label="Dismiss"` (see **label-close-button**). The "×" close glyph (see **render-close-glyph**) is a symbol, not translatable text, and needs no localization. `children` is caller-supplied content and localizing it is the caller's responsibility.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded, no prop) | "Dismiss" | Close button `aria-label` |

The source exposes no prop to override or localize this string. The **Hardcoded English aria-label** Design Decision below records that other-platform implementations SHOULD make it an optional, localizable label rather than hardcoding it, since the source itself does not provide that hook.

## Accessibility Options

- **Reduce Motion**: The component does not animate and is not affected by prefers-reduced-motion. No change in behavior.
- **Increase Contrast**: The component provides no built-in contrast-aware styling. Contrast is managed by CSS; implementations SHOULD ensure the close button and text meet WCAG AA contrast requirements on light and dark backgrounds.
- **Differentiate Without Color**: The close button uses a visible "×" symbol, not color alone, to indicate its function. The aria-label provides text for screen readers.

## Feature Flags

Not applicable: Component has no runtime feature flag configuration in the source code.

## Analytics

Not applicable: Component generates no analytics events.

## Privacy

- **Data collected**: Dismissal state (boolean) stored with a unique hint id as localStorage key.
- **Storage**: Browser localStorage, local to the device and origin.
- **Transmission**: No data leaves the device; localStorage is not sent to a server.
- **Retention**: Dismissal state persists in localStorage until the user clears browser data or the site's storage is manually deleted by the user.

## Logging

Not applicable: Component logs no diagnostic messages.

## Platform Notes

- **SwiftUI**: Use `@AppStorage("{{app_prefix}}-hint-dismissed:<id>")` bound to a `Bool` for the dismissed flag (default `false`). Use a plain `Button` — not `Environment(\.dismiss)`, which dismisses presentations rather than an inline view, and not `deprecatedAction`, which is not a real API — whose action sets the `@AppStorage` value to `true`. Render `EmptyView()` when dismissed.
- **Compose**: Use `remember { mutableStateOf(false) }` for the dismissed flag. Persist via Jetpack `DataStore` (preferred) or `context.getSharedPreferences(name, Context.MODE_PRIVATE)` — `PreferenceManager.getDefaultSharedPreferences` is deprecated — keyed by `{{app_prefix}}-hint-dismissed:<id>`. Use `LaunchedEffect(id)` to load state on composition. Emit nothing when dismissed.
- **React/Web**: This is the source implementation. See source code in packages/web/packages/controls/src/user-settings/components/DismissibleHint.tsx. Uses React hooks (useState, useEffect) and browser localStorage.
- **AppKit / UIKit**: Use a plain view or view controller (not SwiftUI's `@State`/`@Published`) that reads `UserDefaults.standard` for key `{{app_prefix}}-hint-dismissed:<id>` in `viewDidLoad`/`viewWillAppear`; if already dismissed, remove the hint view from its superview or set `isHidden = true` before it is shown, rather than returning `nil` from a view. On the close control's action, write `true` to `UserDefaults.standard` for that key, then remove the view or set `isHidden = true`. Use `NSButton` (AppKit) or `UIButton` (UIKit) with an accessibility label of "Dismiss".
- **WinUI 3**: Implement `INotifyPropertyChanged` (or use CommunityToolkit.Mvvm's `ObservableObject` base class — `ObservableObject` alone is not a WinUI primitive) with a backing `Dismissed` property. Persist to `ApplicationData.Current.LocalSettings.Values` keyed `{{app_prefix}}-hint-dismissed:<id>`. Use a `Button` with `Content="×"` and `AutomationProperties.Name="Dismiss"`. Bind visibility with `x:Bind` through an inverted bool-to-`Visibility` converter (`true` → `Collapsed`).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/DismissibleHint.tsx` | unverified |

## Design Decisions

- **Decision**: Silently ignore localStorage read/write failures instead of surfacing an error.
  **Rationale**: This prioritizes resilience over error reporting. In an inaccessible environment (private browsing, quota exceeded), the hint simply reappears on every visit rather than breaking the page. The source chose silent degradation over logging to a telemetry service or falling back to an in-memory store.
  **Approved**: pending

- **Decision**: Render a literal "×" character as the close affordance rather than an icon or a "Close" text label.
  **Rationale**: "×" is a widely understood visual convention for dismissible UI. Implementations on other platforms MAY substitute a platform-idiomatic close affordance (e.g., the iOS system close symbol, Material Design's close icon) while preserving the semantic `aria-label="Dismiss"`.
  **Approved**: pending

- **Decision**: Hardcode the close button's `aria-label` to the English string "Dismiss" rather than exposing it as a configurable/localizable prop.
  **Rationale**: The source has no localization plumbing, so adding a `dismissLabel` prop would be behavior this recipe does not describe. Implementations that need localization SHOULD add an optional label prop that defaults to a localized "Dismiss" string — see **Localization** above.
  **Approved**: pending

- **Decision**: Store dismissal as the single-character string `"1"` rather than a boolean or JSON value.
  **Rationale**: This is a minimal storage choice. The comparison `getItem(...) === '1'` treats any missing or mismatched value as "not dismissed," so no separate presence check is needed.
  **Approved**: pending

- **Decision**: Document the localStorage key and CSS class prefix as the template variable `{{app_prefix}}` (e.g. `{{app_prefix}}-hint-dismissed:<id>`, `{{app_prefix}}-hint`) rather than the literal `aws-` string found in the source file.
  **Rationale**: Per this cookbook's Template Variables convention, consumer-specific literals must not be hardcoded into a shared recipe; `aws-` is specific to the source application. Every platform port MUST use the same `<prefix>-hint-dismissed:<id>` key scheme so dismissal state stays consistent across ports.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | Privacy and Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Accessibility statuses rest on the container's `role="note"`, the button's `aria-label="Dismiss"`, and native `<button>` keyboard operability, versus type scaling/contrast/tap-target sizing which the source leaves entirely to external CSS it does not define. Privacy and Data statuses rest on the single boolean flag persisted per id, with retention documented above. Internationalization statuses rest on the hardcoded English `aria-label` (not externalized) versus React's native Unicode-safe rendering of caller-supplied `children`. `separation-of-concerns` passes because dismissal persistence lives in the standalone `readDismissed`/`writeDismissed` helpers rather than inline in the component; `unit-test-coverage` passes because `components.test.tsx` imports `DismissibleHint` directly and exercises dismissal and persistence-across-remount with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; fix write-failure state contradiction; template the aws- prefix as {{app_prefix}}; add render-close-glyph requirement and a keyboard test vector; rewrite the duplicate remount vector as an immediate-hide vector; correct the tap-target citation to WCAG 2.5.8; correct SwiftUI/Compose/AppKit-UIKit/WinUI 3 API references; clarify flash-on-mount, multi-instance, and id-change edge cases; reformat Design Decisions; mark Localization applicable; expand and link the Compliance table |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Fix marker on id prop: state type safety behavior from source |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
