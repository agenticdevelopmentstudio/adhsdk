---
id: c97bebaf-9e6d-49a7-a4bb-90e8e0ea0181
title: "Spinner"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Indeterminate loading indicator that animates continuously to show async operations in progress."
platforms:
  - typescript
  - web
tags:
  - loading
  - progress
  - ui
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Spinner

## Overview

The Spinner is an indeterminate loading indicator rendered as an animated icon. It communicates to users that an async operation is in progress without showing a specific completion percentage. The React/Web reference implementation wraps the Lucide `Loader2` icon and applies a continuous spin animation. Size and color are customizable via className; the component defaults to a 1rem (16px) icon with muted text color.

## Behavioral Requirements

- **render-indicator**: Component MUST render a circular indeterminate loading indicator (the React/Web reference implementation uses Lucide's `Loader2` icon — see Platform Notes).
- **spin-animation**: Component MUST apply a continuous spinning animation to the icon; the component does not itself query `prefers-reduced-motion` (see Accessibility Options — Reduce Motion, and Edge Cases).
- **accept-classname**: Component MUST accept and apply a custom `className` prop that overrides or extends the default styling.
- **accept-props**: Component MUST accept and forward all valid React props accepted by the underlying Lucide `Loader2` component.
- **aria-label**: Component MUST set `aria-label="Loading"` to communicate the spinner's purpose to assistive technology. The label is a fixed English string, not a configurable prop (see Localization, Design Decisions).
- **status-role**: Component MUST set `role="status"` to indicate this is a live status region that announces loading state.
- **default-size**: Component MUST default to 1rem (16px) size unless `className` supplies a size-overriding utility.
- **default-color**: Component MUST default to the muted-foreground text color token unless `className` supplies a color-overriding utility (the React/Web reference implementation uses `text-apt-text-muted` — see Platform Notes).

## Appearance

- **Size**: Default 1rem (16px); customizable via `size-*` Tailwind classes in `className`
- **Color**: Default muted text color (`text-apt-text-muted`); customizable via `text-*` Tailwind classes in `className`
- **Animation**: Continuous 360° rotation; no pause or reverse
- **Corner radius**: None (circular icon, no radius applied)
- **Padding**: None
- **Border**: None
- **Shadow**: None

## States

Not applicable: Spinner is a stateless loading indicator with no interactive states (pressed, disabled, focused). It is purely an animated visual indicator.

## Accessibility

- **Role**: `status` — identifies this as a live region for status updates
- **Label**: `aria-label="Loading"` — communicates the purpose to screen readers
- **Announce state**: No change announcements needed; aria-label is static throughout the component lifecycle
- **Keyboard interaction**: Not applicable; component is not interactive
- **Minimum tap target**: Not applicable; component is not interactive and should not be tappable (44×44pt minimum does not apply)

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| spinner-001 | render-indicator | `<Spinner />` | A circular indeterminate spinner icon is visible on screen (rendered via Lucide `Loader2` in the reference implementation) |
| spinner-002 | spin-animation | `<Spinner />` | Rendered element has a non-empty computed `animation-name` (Tailwind's `animate-spin` keyframe), indicating continuous rotation |
| spinner-003 | accept-classname | `<Spinner className="size-8 text-red-500" />` | Icon renders 2rem (32px) in red color, overriding defaults |
| spinner-004 | accept-props | `<Spinner data-testid="loading-indicator" />` | `data-testid` attribute is present on rendered element and accessible via DOM queries |
| spinner-005 | aria-label | `<Spinner />` rendered in a page | The rendered element exposes an accessible name of `"Loading"` (via the `aria-label` attribute), queryable through the accessibility tree (e.g. `getByRole('status', { name: 'Loading' })`) |
| spinner-006 | status-role | `<Spinner />` rendered in the DOM | Element has `role="status"` in its DOM attributes |
| spinner-007 | default-size | `<Spinner />` with no `className`, or a `className` that omits a `size-*` utility | Icon renders at exactly 1rem (16px) width and height |
| spinner-008 | default-color | `<Spinner />` with no `className`, or a `className` that omits a `text-*` color utility | Icon color matches the design system's muted text token (`text-apt-text-muted`) |

## Edge Cases

- **className provided without a matching size or color utility**: When `className` is undefined, falsy, empty, or does not include a `size-*`/`text-*` utility, `tailwind-merge` leaves the corresponding default (1rem size, muted color) unaffected. Behavior: MUST use the default for whichever axis (size, color) `className` doesn't override, without error.
- **Very large classname overrides**: When `className` includes extreme size values (e.g., `size-96`), the component MUST render at that size without clipping or overflow issues (layout depends on parent container). Behavior: MUST render without error; parent container is responsible for containing the size.
- **Reduced-motion preference enabled**: The component does not query `prefers-reduced-motion` itself, so the Tailwind `animate-spin` class keeps animating even when the OS/browser motion-reduction setting is enabled. Behavior: the animation continues to run; a caller who needs to honor the preference must override it via `className` (e.g. a `motion-reduce:` utility) — see Accessibility Options.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` | `string` | `undefined` | Additional or overriding Tailwind classes (e.g., `"size-8 text-green-500"`). Merged with default classes via `cn()` utility. |
| `...props` | `React.ComponentProps<typeof Loader2>` | `undefined` | Any valid prop accepted by Lucide's `Loader2` component (e.g., `strokeWidth`, `data-*` attributes, event handlers). |

## Deep Linking

Not applicable: Spinner is a stateless UI component and does not represent a navigable screen or deep link target.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| _(none — hardcoded, not externalized)_ | `"Loading"` | `aria-label` on the rendered icon, announced to assistive technology; not exposed as a configurable or localizable prop (see Design Decisions) |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The plain `animate-spin` Tailwind utility does NOT respect `prefers-reduced-motion` on its own — Tailwind only suppresses the animation when composed with a `motion-safe:`/`motion-reduce:` variant, which this component does not use. The spinner keeps animating even when the OS/browser motion-reduction setting is enabled; a caller who needs to honor that preference must override the animation via `className` (see Edge Cases). |
| Increase Contrast | Not directly implemented in component. Foreground and background contrast depends on the parent container's background and the `text-apt-text-muted` color token; teams using the component SHOULD ensure the muted text color meets WCAG AA 4.5:1 contrast ratio against the background. Custom `className` overrides (e.g., `text-black` or `text-white`) can be used to achieve higher contrast if needed. |
| Differentiate Without Color | Not applicable. The component conveys loading state via motion (spin animation) and the aria-label, not by color alone. |

## Feature Flags

Not applicable: Component has no feature flags in the source code. Enablement is controlled by conditional rendering at the call site.

## Analytics

Not applicable: Component does not instrument analytics events. Callers are responsible for tracking loading state events if needed.

## Privacy

Not applicable: Component does not collect, store, or transmit any data.

## Logging

Not applicable: Component does not perform any logging. Callers may add logging around the component's lifecycle if needed for debugging.

## Platform Notes

- **React/Web**: Rendered via Lucide's `Loader2` icon component (the reference implementation). Accepts all React and Lucide props via `{...props}` (typed `React.ComponentProps<typeof Loader2>`). Animation is provided by Tailwind CSS's `animate-spin` utility. The `cn()` utility (`clsx` composed with `tailwind-merge`) merges default and custom classnames; `tailwind-merge` is what makes the caller's classes win over the defaults. No framework-specific state or hooks are used internally; the component is a pure presentational wrapper.

- **SwiftUI**: Start from `ProgressView()` with `.progressViewStyle(.circular)`; SwiftUI drives the indeterminate spin automatically while the view is visible, matching **spin-animation**. Apply the muted text color token via `.foregroundStyle(...)` and size it to 16pt by default (e.g. via `.controlSize()`/`.scaleEffect()`). There is no equivalent to React's `className` prop; use environment modifiers (`.foregroundStyle()`, `.font()`, `.scaleEffect()`) instead, and `.accessibilityLabel("Loading")` for the assistive-technology label (see **aria-label**).

- **Compose** (Kotlin/Android): Start from `CircularProgressIndicator()`, which animates indeterminately on its own — Compose has no `LocalAnimationTimeMillis` API to configure this. Set `modifier = Modifier.size(16.dp)` for the default size and pass the muted-foreground token directly via the composable's `color` parameter (Compose has no `Modifier.tint()`). To support custom properties like the web component's `className` merging, accept a `Modifier` parameter and compose it with the defaults.

- **AppKit / UIKit** (macOS/iOS): Use `NSProgressIndicator` (macOS) with `style = .spinning`, then call `startAnimation(_:)` to begin the spin; or `UIActivityIndicatorView(style: .medium)` (iOS) and call `startAnimating()` — the two platforms expose different method names for the same action. Size defaults to 16pt; color defaults to the muted text color token via the view's tint/appearance. No direct equivalent to React's `className` or `...props` forwarding; instead, create a wrapper that exposes individual properties (`size`, `color`, `isAnimating`) and applies them via settable view properties.

- **WinUI 3** (Windows): Use `ProgressRing` with `IsIndeterminate="True"`. Size it to 16×16 DIP (device-independent pixels, roughly equivalent to 16px on 96 DPI). Set `Foreground` to the muted text color token. `ProgressRing` animates automatically once `IsIndeterminate` is true and exposes no separate spin-animation property to configure. To support custom styling, expose a `Style` property that consumers can override via XAML or code-behind; this provides the equivalent of the React component's `className` flexibility.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/spinner.tsx` | unverified |

## Design Decisions

- **Decision**: The component renders an indeterminate spinner (no progress percentage), not a determinate progress bar.
  **Rationale**: The source code and comment explicitly state "Indeterminate loading spinner." A determinate progress bar serves a different use case (showing completion percentage) and is not in scope.
  **Approved**: pending

- **Decision**: The component renders the Lucide icon directly, with no wrapping `<div>` or other container.
  **Rationale**: This keeps the DOM minimal and lets the caller control layout and spacing via the parent container's styling.
  **Approved**: pending

- **Decision**: Default classes are merged with the caller's `className` via `cn()` (`clsx` + `tailwind-merge`).
  **Rationale**: `tailwind-merge` resolves Tailwind class precedence correctly, so the caller's classes override the defaults. This lets callers customize size and color without needing to know the default class names.
  **Approved**: pending

- **Decision**: The component forwards all remaining props to the underlying `Loader2` component via `{...props}` instead of whitelisting individual props.
  **Rationale**: This lets callers add event handlers (if `Loader2` supports them), data attributes, or other HTML attributes without the Spinner component needing to explicitly whitelist each one — the same extensibility the `className` customization provides.
  **Approved**: pending

- **Decision**: The `aria-label` is hardcoded to `"Loading"` rather than exposed as a prop.
  **Rationale**: The source code does not expose the label as a prop. Callers who need a different or localized label would need to render the `Loader2` icon directly with a custom label instead of using this component.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

These statuses rest on the source directly: `role="status"` and a static `aria-label="Loading"` are set on the `Loader2` element itself with no wrapper (syntactically valid ARIA, but the source gives no independent way to verify it's reliably announced, hence `partial` for semantic-markup/screen-reader-support), contrast depends entirely on the caller's background (hence `partial` for contrast-ratio), the plain `animate-spin` class has no `motion-safe:`/`motion-reduce:` handling (hence `failed` for reduced-motion), and the `"Loading"` string is hardcoded with no externalization mechanism (hence `failed` for the two internationalization checks). `separation-of-concerns` passes because `spinner.tsx` is a pure presentational wrapper around `Loader2` with no business logic, and `unit-test-coverage` fails because no test file in the repository imports or renders `Spinner`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; separated Lucide/Tailwind specifics out of behavioral requirements into Platform Notes; corrected invented/wrong Platform Notes APIs (Compose, AppKit/UIKit, SwiftUI, cn()); fixed Reduce Motion/Edge Cases contradiction over `prefers-reduced-motion`; reworded untestable test vectors and dropped the unmeasurable specificity edge case; reworded default-size/default-color for override precision; fixed `React.ComponentProps<typeof Loader2>` configuration type; converted Design Decisions to Decision/Rationale/Approved triples; replaced Compliance and Localization "Not applicable" with populated tables; fixed frontmatter `modified` date-format mismatch |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from React source |
