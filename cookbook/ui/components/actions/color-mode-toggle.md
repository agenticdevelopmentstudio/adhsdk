---
id: 7b54db6e-755d-4665-a091-d34cfcaac146
title: "Color Mode Toggle"
type: ingredient
version: 1.3.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A controlled toggle button that cycles between light, dark, and automatic (system) color modes."
platforms:
  - typescript
  - web
tags:
  - theme
  - appearance
  - toggle
depends-on: []
related:
  - 46e077a8-1171-4564-9781-7997ff76813a
references: []
approved-by: ""
approved-date: ""
---

# Color Mode Toggle

## Overview

The Color Mode Toggle is a button component that allows users to cycle between three color modes: **auto** (follow system preference), **dark**, and **light**. The component is presentation-only — it accepts the current mode as a prop and notifies the parent via a callback when the user requests a change. This design allows the component to be used in any context where color mode preference needs to be controlled, regardless of where that preference is stored (user account, localStorage, application state).

The component visually indicates the current mode with three icon states (Sun for light, Moon for dark, RefreshCw refresh icon for auto). When the mode is "auto", the component queries the system's `prefers-color-scheme` to determine and display the currently active effective mode.

Not to be confused with [adhsdk.ingredient.controls.appearance-mode-toggle](cookbook:46e077a8-1171-4564-9781-7997ff76813a), a separate ingredient with the same three-state cycling shape that binds a different, legacy document contract (`data-appearance-mode` plus an `awt:appearance-cycle` event) for one demo site. See Design Decisions for why the two stay separate.

## Behavioral Requirements

- **render-button**: Component MUST render as a `<button>` element with `type="button"`.
- **render-three-icons**: Component MUST render three SVG icons (Sun, Moon, and RefreshCw refresh) simultaneously, with CSS controlling visibility based on mode.
- **accept-mode-prop**: Component MUST accept a `mode` prop with value "auto", "dark", or "light".
- **accept-on-change-callback**: Component MUST accept an `onChange` callback prop that receives the next mode in the cycle when the button is pressed.
- **cycle-modes**: Component MUST cycle modes in order: auto → dark → light → auto when clicked.
- **support-class-name**: Component MUST accept an optional `className` prop to apply custom styling (e.g., host button identity).
- **read-system-dark-preference**: When `mode` is "auto", component MUST query `window.matchMedia("(prefers-color-scheme: dark)")` to determine the effective mode.
- **listen-to-system-changes**: Component MUST subscribe to changes in the system dark mode preference and update the displayed effective mode without requiring props to change.
- **provide-aria-label**: Component MUST set an `aria-label` attribute that includes the current mode and the next mode in cycle, provided after client hydration.
- **provide-title-attribute**: Component MUST set a `title` attribute (tooltip) that describes the current mode and how to switch, provided after client hydration.
- **defer-label-until-mounted**: Component MUST NOT populate the real `aria-label`/`title` text on server-side rendering. `aria-label` MUST render the placeholder `"Theme"` during SSR and the client's first render; `title` MUST be omitted (`undefined`) until the component mounts. Both populate with their full text on the next render after mount.
- **handle-missing-match-media**: When `window.matchMedia` is unavailable (server-side rendering or older browsers), component MUST treat system dark mode as false.
- **host-html-attribute-sync**: The host application MUST keep `data-color-mode` (`"auto"` | `"dark"` | `"light"`) and the `dark` class on `<html>` synchronized with `mode` and the resolved effective mode. The component's own CSS (`.adh-color-mode-toggle__*`) reads only those host-controlled attributes to decide which icon and the auto-mode badge are visible — it does not read the `mode` prop for that purpose.

## Appearance

- **Icon size**: 20×20px (`1.25rem`, set by the `.adh-color-mode-toggle > svg` CSS rule) for the Sun and Moon icons; size is controlled by CSS `width`/`height`, not by `strokeWidth`.
- **Stroke width**: 2 for Sun/Moon, 3 for the RefreshCw badge — a thicker line keeps the smaller badge glyph legible.
- **Auto-mode badge**: RefreshCw renders as a 10×10px (`0.625rem`) corner overlay, absolutely positioned at the bottom-right of the button and colored `var(--color-accent)`. It is shown only when `data-color-mode="auto"` is present on `<html>`, layered on top of whichever of Sun/Moon is currently visible; otherwise it is hidden.
- **Color**: Icons inherit the text color of the button's scope; determined by CSS based on `data-color-mode` or `.dark` class on document root
- **Padding**: None — component is a bare icon button with no internal spacing
- **Background**: None by default — host application supplies button styling via className
- **Border**: None by default
- **Corner radius**: None
- **Shadow**: None
- **Visibility logic**: CSS rules (`.adh-color-mode-toggle__*` selectors, in `styles/components.css`) determine which icon is visible based on the `data-color-mode` attribute on `<html>` and presence of `.dark` class. That stylesheet is a required runtime dependency — see Design Decisions.

## States

| State | Appearance change | Trigger |
|-------|------------------|---------|
| Default (no interaction) | All three icons present in DOM; CSS determines which is visible based on mode | Initial render |
| Hover | Depends on host button styling (passed via className) | User moves pointer over button |
| Pressed/Active | Depends on host button styling (passed via className) | User clicks button |
| Focused | Depends on host button styling (passed via className) | User tabs to button or clicks it |
| Disabled | Not supported by component | N/A |

## Accessibility

- **Role**: Button (implicit from `<button>` element)
- **Label requirement**: `aria-label` MUST communicate the current mode and the next mode in the cycle. Before hydration (SSR and the client's first render) it is the placeholder `"Theme"`. After the component mounts it becomes `Theme: {mode}. Click to switch to {next}.` for `light`/`dark`, or `Theme: Auto (currently {resolved}). Click to switch to dark.` for `auto` (the next mode from `auto` is always `dark`), where `{resolved}` is `light` or `dark` from the system preference.
- **Title**: Tooltip text MUST be `undefined` until the component mounts, then read `Following system ({resolved})` for `auto` mode, or `Light mode — click for auto` / `Dark mode — click for light` for explicit modes.
- **Touch target size**: The component itself is an icon button and relies on the host's button styling to meet platform touch target minimums (44×44pt on iOS, 48×48dp on Android, platform-appropriate for web).
- **Keyboard navigation**: Button MUST be keyboard accessible and focusable (inherent from `<button>` element).
- **Announcement of state**: The accessible name (`aria-label`) MUST update synchronously with `mode` — in the same render — so assistive technology reads the current value whenever it next queries the element. The component places no requirement on how or when a screen reader announces the change; that is outside its control.
- **No color-only information**: The three different icons (Sun, Moon, RefreshCw) serve as distinct visual indicators, not relying on color alone.

## Conformance Test Vectors

| ID | Requirements | Input | Expected | Notes |
|----|-------------|-------|----------|-------|
| cmt-001 | render-button | Render component with mode="light" | HTML contains `<button type="button">` element | |
| cmt-002 | render-three-icons | Render component | Three SVG icons present in DOM (Moon, Sun, RefreshCw) | CSS controls which is visible |
| cmt-003 | accept-mode-prop | mode="auto" | Component accepts and does not throw | |
| cmt-004 | accept-mode-prop | mode="dark" | Component accepts and does not throw | |
| cmt-005 | accept-mode-prop | mode="light" | Component accepts and does not throw | |
| cmt-006 | cycle-modes | mode="auto" clicked once | onChange called with "dark" | |
| cmt-007 | cycle-modes | mode="dark" clicked once | onChange called with "light" | |
| cmt-008 | cycle-modes | mode="light" clicked once | onChange called with "auto" | |
| cmt-009 | support-class-name | className="my-custom-class" passed | Element has class "my-custom-class" applied | |
| cmt-010 | read-system-dark-preference | mode="auto" and system prefers dark | Effective mode is "dark" | Via matchMedia query |
| cmt-011 | read-system-dark-preference | mode="auto" and system prefers light | Effective mode is "light" | Via matchMedia query |
| cmt-012 | listen-to-system-changes | mode="auto" and system changes from light to dark | aria-label updates to reflect new effective mode | Should reflect change without prop change |
| cmt-013 | provide-aria-label | After client mount with mode="light" | aria-label is exactly "Theme: light. Click to switch to auto." | |
| cmt-014 | provide-aria-label | After client mount with mode="auto" | aria-label is exactly "Theme: Auto (currently light). Click to switch to dark." (system prefers light) or "Theme: Auto (currently dark). Click to switch to dark." (system prefers dark) | Next mode from auto is always "dark" |
| cmt-015 | provide-title-attribute | After client mount with mode="light" | title contains "Light mode — click for auto" | Tooltip text |
| cmt-016 | provide-title-attribute | After client mount with mode="dark" | title contains "Dark mode — click for light" | Tooltip text |
| cmt-017 | provide-title-attribute | After client mount with mode="auto" | title contains "Following system (light)" or "Following system (dark)" | Based on system preference |
| cmt-018 | defer-label-until-mounted | Server-side render mode="light" | aria-label is "Theme" only | No specific mode in SSR HTML |
| cmt-019 | defer-label-until-mounted | After hydration mode="light" | aria-label becomes "Theme: light. Click to switch to auto." | Updated after mount |
| cmt-020 | handle-missing-match-media | mode="auto" in environment without matchMedia | Component does not throw; treats system as light mode | |
| cmt-021 | host-html-attribute-sync | Render with mode="light" while host sets `data-color-mode="dark"` and `.dark` on `<html>` | Moon icon visible, Sun icon hidden, badge hidden — icon selection follows the host's `<html>` attributes, not the `mode` prop | Demonstrates the coupling the requirement makes explicit |

## Edge Cases

- **Null mode or missing prop**: Not applicable. Component interface requires `mode` to be one of three specific values; type safety enforces this in TypeScript.
- **Null onChange or missing prop**: Not applicable. Component interface requires `onChange` to be a callback function; the component must be used with both props provided.
- **System preference changes during auto mode**: When mode is "auto", component MUST subscribe to the `change` event on the matchMedia query and update the resolved effective mode. No prop change from parent is required; the update happens internally via `useSyncExternalStore`.
- **matchMedia not available (SSR/server context)**: Component MUST treat system dark mode as `false` and must not throw. The `getServerSystemDark()` function returns false on server.
- **matchMedia available but event support missing (legacy Safari < 14)**: Component MUST proactively check for `addEventListener` support on the MediaQueryList object. If unavailable, the component MUST return an empty unsubscribe function and continue rendering.
- **Rapid successive clicks**: Each click calls `onChange` with the next mode in the cycle. The parent is responsible for debouncing or managing state; the component imposes no rate limits.
- **Component unmounts while system preference listener is active**: The `useSyncExternalStore` subscription cleanup (returned unsubscribe function) MUST properly remove the event listener.
- **Hydration mismatch**: The component uses `mounted` state to prevent hydration mismatches. Server-side and on the client's first render, `aria-label` is set to the placeholder `"Theme"` and `title` is omitted (`undefined`). After the `mounted` effect runs, the real labels populate without re-rendering the HTML structure.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mode` | "auto" \| "dark" \| "light" | (required) | The current color mode preference. Parent must provide this; not stored in component state. |
| `onChange` | (next: ColorMode) => void | (required) | Callback invoked when user clicks button. Receives the next mode in the cycle. |
| `className` | string | undefined | Optional CSS class name to apply to the button element. Used to integrate the button's styling with the host application's button identity. |

## Deep Linking

Not applicable. The Color Mode Toggle is a control component that does not itself navigate or manage routes.

## Localization

Not applicable. All user-facing text (aria-label, title tooltip) is hardcoded in English and derived from the mode values. A parent application wishing to localize this text would need to wrap the component or use a custom implementation.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Component does not apply transitions on mode change; mode changes are instantaneous. |
| Increase Contrast | Not applicable: Component is an unstyled icon button relying on host application styling via `className` prop. Contrast adjustments are the host's responsibility. |
| Differentiate Without Color | Component uses three distinct icon shapes (Sun for light, Moon for dark, RefreshCw for auto) as the primary visual indicator, plus complete text labels in `aria-label` and `title` attributes, ensuring mode is communicated without relying solely on color. |

## Feature Flags

Not applicable. The component has no feature flags or toggles. It is always enabled and always cycles through all three modes.

## Analytics

Not applicable. The component does not emit any analytics events. The parent application is responsible for tracking user interactions with this component if desired.

## Privacy

Not applicable. The component does not collect, store, transmit, or retain any user data. It only reads the system's `prefers-color-scheme` setting, which is a public browser API call.

## Logging

Not applicable. The component does not emit any log messages.

## Platform Notes

- **React/Web**: Implementation provided in `packages/web/packages/ui/src/components/color-mode-toggle.tsx`. Uses `useState` for client-only `mounted` gate, `useEffect` for mount detection, and `useSyncExternalStore` to subscribe to `prefers-color-scheme` media query without causing hydration mismatches. Icons imported from `lucide-react`. CSS classes `.adh-color-mode-toggle` and `.adh-color-mode-toggle__*` are applied; visual rendering delegated to `styles/components.css`. Component is a client-side rendered button (`"use client"` directive).

- **SwiftUI**: A SwiftUI equivalent would take `mode: Binding<ColorMode>` (or a `mode` value plus an `onChange` closure) rather than owning the mode in `@State`, preserving the source's controlled contract. It would read the resolved system appearance via `@Environment(\.colorScheme)`. The three icons would be `Image` views with conditional visibility based on `mode`/resolved appearance. Accessibility would use `.accessibilityLabel()` and `.accessibilityHint()` modifiers with the same label templates as the source.

- **Compose (Android/Kotlin)**: A Compose equivalent would take `mode: ColorMode` and `onModeChange: (ColorMode) -> Unit` as parameters rather than a `MutableState`, preserving the same controlled contract. System color scheme would be read via `isSystemInDarkTheme()`. Three `Icon` composables would be rendered with conditional visibility. Accessibility would use `Modifier.semantics { role = Role.Button; contentDescription = ... }` with the same label templates as the source.

- **AppKit / UIKit**: An `NSButton`/`UIButton` subclass would render three `NSImageView`/`UIImageView` subviews, toggling visibility based on `mode`/resolved appearance, with `mode` supplied by the caller and changes reported via target-action or a closure rather than owned internally. System appearance would be read via `traitCollection.userInterfaceStyle` (UIKit) or `NSApp.effectiveAppearance` (AppKit) — `UIAppearance`/`NSAppearance` are styling-proxy APIs that configure an appearance, not detect the current one. Accessibility would use `UIAccessibility` (UIKit) or `NSAccessibility` (AppKit) to set the same label text as the source.

- **WinUI 3**: A WinUI 3 implementation would use a Button with three FontIcon children, binding visibility to the mode state via converters or code-behind. System dark mode would be detected via `UISettings` class listening to the `ColorValuesChanged` event. Accessibility would use `AutomationProperties.Name` and `AutomationProperties.HelpText` attached properties. The component would inherit from `Button` or be a custom control template that cycles mode on click.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/color-mode-toggle.tsx` | unverified |

## Design Decisions

**Decision**: The component is a controlled control — it receives the current `mode` via a prop and emits change requests via `onChange`; it owns no mode or storage state itself.
**Rationale**: This keeps the component independent of any specific state-management or storage layer, so it can be used in header chrome, sidebars, or settings panels and wired to local storage, a user account, Redux, Zustand, or any other store. The source's own comment explicitly warns against baking in a dependency on a specific theme context.
**Approved**: pending

**Decision**: The mode cycle order (auto → dark → light → auto) is fixed and not configurable.
**Rationale**: Users expect a single toggle button to walk a consistent sequence. The order is encoded in the `NEXT_MODE` map rather than an array walked with modular arithmetic, making every mode's successor total and explicit.
**Approved**: pending

**Decision**: `aria-label`/`title` render placeholder/omitted values until the component mounts on the client, then switch to their real text on the next render.
**Rationale**: Neither value the component needs to word the label correctly is available during server rendering: the `mode` a parent supplies during SSR is often a guess (the true preference commonly lives in a client-only store such as `localStorage`), and even when `mode` is known, resolving `"auto"` requires `window.matchMedia`, which does not exist on the server. Gating on a `mounted` state — `false` on both the server and the client's first render, then `true` after a `useEffect` — guarantees the server and client agree on the placeholder, avoiding a hydration mismatch; the real label then appears on the very next client render. `useSyncExternalStore` is a separate mechanism: it supplies the resolved system-dark value once mounted so that value itself doesn't render wrong then correct in an effect, but it does not control when the label text appears.
**Approved**: pending

**Decision**: The component reads `prefers-color-scheme: dark` through `useSyncExternalStore`, not `useState` + `useEffect`.
**Rationale**: `useSyncExternalStore` is React's designated pattern for subscribing to a store outside React's own state (here, `window.matchMedia`). It gives the first client render the correct value immediately, rather than rendering with a wrong value and correcting it in a later effect.
**Approved**: pending

**Decision**: The component applies no styles of its own beyond one structural class (`adh-color-mode-toggle`, plus any host `className`) and three icon-part classes; all colors, sizing, and icon-visibility rules live in CSS.
**Rationale**: This lets a host fully restyle the button and its icons — including the host's own button identity via `className` — without forking the component per design system. Correctness depends on that CSS: `.adh-color-mode-toggle__*` in `styles/components.css` is what actually decides which icon, and the auto-mode badge, is visible, so that stylesheet is a required runtime dependency of this component, not an optional layer the host may omit.
**Approved**: pending

**Decision**: On a `MediaQueryList` without `addEventListener` (Safari < 14, which shipped only the legacy `addListener`/`removeListener`), the component returns a no-op unsubscribe and renders using `mode` alone, without system-preference tracking, rather than falling back to `addListener`.
**Rationale**: The check probes for the modern API rather than assuming it, for the same reason the host's own appearance store does. Supporting the legacy `addListener` path would mean carrying and testing a second, deprecated subscription mechanism for a browser version past its support window; the component instead degrades gracefully to a static `mode`-only render, keeping the subscription logic to one code path.
**Approved**: pending

**Decision**: `ColorModeToggle` and the separate [adhsdk.ingredient.controls.appearance-mode-toggle](cookbook:46e077a8-1171-4564-9781-7997ff76813a) ingredient are not merged, despite both being a three-state (auto/dark/light) cycling icon button.
**Rationale**: They bind to two different, incompatible document contracts. This component's CSS reads `data-color-mode`/`.dark` on `<html>`, driven by a controlled `mode` prop and the family's own appearance store. `AppearanceModeToggle` reads `data-appearance-mode` and dispatches an `awt:appearance-cycle` custom event for a separate, legacy appearance system still used by one demo site. Merging them would change that site's live document contract, not just its markup, so they stay separate until that site migrates.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The source renders a native `<button>` with an always-present, mount-aware `aria-label` and no custom ARIA roles (passed on screen-reader-support, keyboard-navigable, and semantic-markup); it delegates icon color and hit-area sizing entirely to host CSS the source itself cannot verify (partial on contrast-ratio and touch-target-size); and `title()` plus the `aria-label` template are literal English strings baked into the component with no externalization mechanism (failed on both internationalization checks). separation-of-concerns passes because the system-dark subscription and label text (`subscribeSystemDark`, `getSystemDark`, `title()`) are factored out of the component into standalone functions, and unit-test-coverage passes because `colorModeToggle.test.tsx` exercises the mode cycle, the accessible name, OS resolution of `auto`, the server-rendered markup, and the host `className` merge with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Renamed 3 non-kebab requirements to subject-only kebab (onChange/className/matchMedia forms). Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.3.0 | 2026-09-23 | Mike Fullerton | Renamed every requirement to subject-only kebab-case, dropping the old prefix everywhere it is cited. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: distinguished this component from Appearance Mode Toggle in Design Decisions and `related`; added a host `<html>` attribute-sync requirement and test vector; corrected the SSR label/title, appearance sizing, and legacy-fallback design decisions; reformatted Design Decisions to Decision/Rationale/Approved; replaced Compliance with a check table; fixed aria-label/title test-vector consistency; corrected the SwiftUI, Compose, and AppKit/UIKit platform notes |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Revise Accessibility Options: convert to table format; clarify Reduce Motion as not applicable (no transitions applied); add guidance on Increase Contrast and Differentiate Without Color |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source code |
