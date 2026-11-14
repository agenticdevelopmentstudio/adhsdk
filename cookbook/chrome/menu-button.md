---
id: e82102a9-a60c-4498-aba3-7cd5a33ade3c
title: "Menu Button"
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A button that toggles between a hamburger menu icon and a close icon, with accessible label."
platforms:
  - typescript
  - web
tags:
  - ui
  - button
  - navigation
depends-on: []
related:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
references: []
approved-by: ""
approved-date: ""
---

# Menu Button

## Overview

A button that displays and toggles between a hamburger menu icon (three stacked bars) and a close icon (two bars crossed). The icon state is controlled by a prop; the bars are rendered as plain DOM elements rather than SVG, allowing them to animate and inherit the button's text color. The component requires an accessible name and extends standard HTML button attributes. See `packages/web/packages/chrome/src/MenuButton.tsx` for the component and `packages/web/packages/chrome/src/css/base.css` for the geometry and hit-area values behind the specifics below.

## Behavioral Requirements

- **button-element**: Component MUST render as an HTML `<button>` element with `type="button"`.
- **accessible-label**: Component MUST accept a required `label` prop that is used as the button's accessible name via `aria-label`.
- **menu-icon-default**: Component MUST display three bars (hamburger icon) when no `icon` prop is provided or when `icon="menu"`.
- **close-icon-variant**: Component MUST display two bars crossed (close icon) when `icon="close"`.
- **button-attribute-passthrough**: Component MUST pass through all standard `HTMLButtonElement` attributes (e.g., `disabled`, `onClick`, `className`, `data-*` attributes).
- **menu-button-class**: Component MUST apply the CSS class `menu-button` to the button element.
- **close-variant-class**: Component MUST apply the CSS class `menu-button--close` to the button element when `icon="close"`.
- **custom-classname**: Component MUST allow custom CSS classes to be added via a `className` prop and combine them with the component's internal classes.
- **plain-element-bars**: Component MUST render bars as plain `<span>` elements with class `mb-bar` rather than as an SVG, to enable animation and color inheritance.
- **relative-positioning**: The button MUST be `position: relative` so the 44×44px `::after` hit-area pseudo-element centers on it correctly (`packages/web/packages/chrome/src/css/base.css`).
- **bar-geometry**: Each bar MUST be 16px wide (`--menu-bar-width`) and 1px thick (`--menu-bar-thickness`), with fully rounded ends (`border-radius: 999px`), stacked with a 4px gap (`--menu-bar-gap`) inside a 32×32px box (`--menu-size`). Thickness, gap and the resulting 5px pitch (thickness + gap) MUST all be whole-number CSS pixels, so every bar rounds to the same device-pixel thickness regardless of device-pixel ratio or the button's fractional position; the button's 1px top padding keeps the 11px stack on whole pixels inside the even-height box (`packages/web/packages/chrome/src/css/base.css`).
- **bar-current-color**: Each bar MUST use `background: currentColor`, so a consumer themes the icon by setting `color` on the button.
- **bar-transition**: Each bar MUST apply `transition: 0.25s` (all properties), which animates the `rotate()` transform applied to the first and last bar when toggling to the close state; no `prefers-reduced-motion` override exists (see the `reduced-motion` check in [Compliance](#compliance)).
- **close-bars-overlaid**: In the close state, the two bars MUST share one grid cell (`grid-area: 1 / 1`) and be rotated +45deg (first) and -45deg (last), so the X survives any change to bar thickness or gap.
## Appearance

- **Bar rendering**: Bars are plain HTML elements (`<span>`) with class `mb-bar`, not SVG.
- **Bar quantity**: Three bars in menu state, two bars in close state.
- **Bar dimensions**: See **bar-geometry** in [Behavioral Requirements](#requirements/bar-geometry): 16px wide, 1px thick, 4px gap, 5px pitch, in a 32×32px box.
- **Bar colour**: See [bar-current-color](#requirements/bar-current-color).
- **Bar transition**: See [bar-transition](#requirements/bar-transition).
- **Close icon derivation**: In close state, the close icon (X shape) is derived from the two bars via CSS rotation/transform; the component does not render separate markup for the X (see [close-bars-overlaid](#requirements/close-bars-overlaid)).
- **Background**: No background specified in component; inherits from button styling context.
- **Border**: No border specified in component; inherits from button styling context.
- **Shadow**: No shadow specified in component; inherits from button styling context.

## States

| State | Appearance change |
|-------|------------------|
| Default (menu) | Three stacked bars |
| Close | Two bars crossed (via CSS transform) |
| Disabled | Standard HTML button disabled styling (subject to CSS) |
| Focused | Browser default focus styling; `css/base.css` defines no `:focus-visible` rule, so the zero-border, no-background button shows only the UA outline (see the `focus-visible` note in Compliance) |
| Pressed/Active | Standard HTML button active styling (subject to CSS) |

## Accessibility

- **Role**: Button (implicit from `<button>` element).
- **Accessible name**: MUST be provided via the required `label` prop, which is applied as `aria-label`. The button has no visible text, so an accessible name is required.
- **Icon symbol**: Hamburger menu and close icons are purely visual; the accessible name provided by `label` replaces them functionally (e.g., "Menu" or "Close menu").
- **Keyboard navigation**: Button is fully keyboard accessible via standard `<button>` element behavior; may be activated via Space or Enter keys.
- **Assistive technology**: Screen readers will announce the button's accessible name and role.
- **Toggle state (consumer-managed)**: The component itself tracks no open/closed state. When used to toggle a menu, the composing screen SHOULD pass `aria-expanded` and `aria-controls` (referencing the menu it opens) through the button's pass-through props, and SHOULD update `label` to match the current state (e.g. "Open menu" / "Close menu").
- **Minimum tap target**: The button's visible icon box is 32×32px (`--menu-size`), but the button exposes a 44×44 CSS px hit area via an absolutely positioned `::after` pseudo-element (`--menu-hit: 44px`), centred on the button because `.menu-button` is `position: relative` (`packages/web/packages/chrome/src/css/base.css`; see [relative-positioning](#requirements/relative-positioning)). This meets the 44×44 CSS px target size used for the web; the Apple HIG's 44×44pt equivalent is covered in the platform notes.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| menu-button-001 | button-element | Render with default props | Button element with `type="button"` is rendered |
| menu-button-002 | accessible-label | `label="Menu"` | `aria-label="Menu"` is present on button element |
| menu-button-003 | menu-icon-default | No `icon` prop | Three `<span class="mb-bar">` elements render |
| menu-button-004 | close-icon-variant | `icon="close"` | Two `<span class="mb-bar">` elements render |
| menu-button-005 | menu-button-class | Default render | Button has class `menu-button` |
| menu-button-006 | close-variant-class | `icon="close"` | Button has classes `menu-button` and `menu-button--close` |
| menu-button-007 | custom-classname | `className="custom-class"` | Button includes `custom-class` in its class list |
| menu-button-008 | button-attribute-passthrough | `onClick={handler}` | Handler is invoked on button click |
| menu-button-009 | button-attribute-passthrough | `disabled={true}`, then simulate a click | Button has the `disabled` attribute; the `onClick` handler is not invoked |
| menu-button-010 | menu-icon-default, close-icon-variant | Toggle `icon` prop from `'menu'` to `'close'` | Bar count changes from three to two; `menu-button--close` class is added |
| menu-button-011 | plain-element-bars | Render with default props | Each `.mb-bar` element's tag name is `SPAN`; no `<svg>` element is present |
| menu-button-012 | menu-icon-default | `icon="menu"` (explicit) | Three `<span class="mb-bar">` elements render, same as the default |
| menu-button-014 | custom-classname | No `className` prop | Button's `class` attribute is exactly `menu-button` with no extra whitespace or empty tokens |
| menu-button-015 | relative-positioning | Default render | `.menu-button` computed `position` is `relative`; the `::after` element's computed size is 44×44px |
| menu-button-016 | accessible-label | `label` prop omitted (bypassing the type system) | No `aria-label` attribute is present on the button |
| menu-button-017 | accessible-label | `label=""` | `aria-label=""` is present; the button has an empty accessible name |
| menu-button-018 | custom-classname, close-variant-class | `icon="close" className="custom-class"` | Button's `class` attribute is `menu-button menu-button--close custom-class` |
| menu-button-019 | bar-geometry | Default render, read `getComputedStyle` of each `.mb-bar` | `width` is `16px`, `height` is `1px`, `border-radius` resolves from `999px` |
| menu-button-020 | bar-geometry | Default render, read `getComputedStyle` of `.menu-button` | `width` and `height` are `32px`, `row-gap` is `4px` |
| menu-button-021 | bar-current-color | Set `color: rgb(255, 0, 0)` on the button | Each `.mb-bar` computed `background-color` is `rgb(255, 0, 0)` |
| menu-button-022 | bar-transition | Default render, read `getComputedStyle` of a `.mb-bar` | `transition-duration` is `0.25s` |
| menu-button-023 | close-bars-overlaid | `icon="close"`, read `getComputedStyle` of each `.mb-bar` | Both bars have `grid-area` `1 / 1`; the first has a rotate(45deg) transform and the last rotate(-45deg) |
## Edge Cases

- **No label prop**: `label` is a required, non-optional `string` prop with no default, so omitting it is a TypeScript compile-time error; the component performs no runtime check. A caller outside TypeScript's reach that omits it renders a button with `aria-label={undefined}` — a button with no accessible name.
- **Icon prop invalid value**: Component expects `icon` to be `'menu'` or `'close'`, but the type is not enforced at runtime. The third bar and the `menu-button--close` class are gated independently — the third bar on `icon === 'menu'`, the class on `icon === 'close'` — so a value that is neither (e.g., `icon="hamburger"`) renders neither the full three-bar menu icon nor the close variant: only two bars, uncrossed, with no `menu-button--close` class. This is an artifact of the two independent gates, not a documented fallback, so no conformance vector locks it in.
- **Empty string label**: An empty `label=""` satisfies the type requirement but results in an inaccessible button with no meaningful name. The component accepts this but the caller SHOULD provide a meaningful label.
- **Disabled state interaction**: When disabled, the button MUST NOT respond to clicks; this is standard HTML button behavior and does not depend on component logic.
- **Multiple class combinations**: Component combines `menu-button`, the conditional `menu-button--close`, and any custom `className` prop. Classes are filtered and joined with spaces; empty strings are removed (see menu-button-014 and menu-button-018).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `icon` | `'menu' \| 'close'` | `'menu'` | Controls which icon is displayed: `'menu'` for three bars or `'close'` for two bars |
| `label` | `string` | (required) | Accessible name for the button; used as `aria-label` |
| `className` | `string` | `undefined` | Optional. Custom CSS class(es) to add to the button element |
| `...rest` | `HTMLButtonElement` attributes | N/A | All standard button attributes (e.g., `disabled`, `onClick`, `data-*`) are passed through |

## Deep Linking

Not applicable: This is a UI control with no deep-linking semantics. Deep linking is handled by the page or component that contains the menu button.

## Localization

Not applicable: The component accepts the `label` string from the caller, so localization is the responsibility of the consuming application. The component itself contains no user-facing strings and performs no locale-sensitive transforms.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not supported: `css/base.css` defines no `prefers-reduced-motion` override, so the `0.25s` bar transition runs at full speed regardless of the setting. |
| Increase Contrast | Not supported: `css/base.css` defines no `prefers-contrast` override; bar color is fixed to `currentColor`. |
| Differentiate Without Color | Not applicable: The icon is purely visual and the accessible name is always provided via `aria-label`. |

## Feature Flags

Not applicable: Component contains no feature flag logic.

## Analytics

Not applicable: Component emits no analytics events. Analytics instrumentation is the responsibility of the consuming application via `onClick` or other event handlers.

## Privacy

Not applicable: Component stores and transmits no personal data. The `label` string is provided by the caller and is a UI string only.

## Logging

Not applicable: Component performs no logging.

## Platform Notes

- **React/Web**: Implemented in React as a functional component (`packages/web/packages/chrome/src/MenuButton.tsx`). Bars are `<span>` elements with class `mb-bar`; the close icon is derived from the bars via CSS transform (rotation). Styling is external to the component and defined in `packages/web/packages/chrome/src/css/base.css`, including the `position: relative` and 44×44px `::after` hit area. The component accepts all standard `HTMLButtonElement` attributes via prop spread.
- **SwiftUI**: Prefer the system glyphs first: `Image(systemName: "line.3.horizontal")` for the menu state and `Image(systemName: "xmark")` for the close state, both taking the button's color via `.foregroundStyle` (`.foregroundColor` is deprecated). Reserve a custom bar-based rendering — three `Capsule().frame(width: 16, height: 1)` shapes, two rotated for the close state — for cases that need the animated bar-to-X morph the source implements. Respect `@Environment(\.isEnabled)` for disabled state, and give the tap target a minimum 44×44pt frame independent of the icon's own size.
- **Compose**: Implement as `IconButton { Column { Box(Modifier.size(16.dp, 3.dp).background(LocalContentColor.current, CircleShape)) … } }`, applying `Modifier.graphicsLayer { rotationZ = ... }` to the first and last bar for the close state. Use `LocalContentColor` to inherit the button's color. Respect Compose's `enabled` state, and size the `IconButton`'s minimum touch target to 48dp.
- **AppKit / UIKit**: Prefer the system glyphs first: `UIImage(systemName: "line.3.horizontal")` (UIKit) / `NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription:)` (AppKit) for menu, and `"xmark"` for close, tinted via `tintColor`. Reserve a custom view with three `UIView`/`NSView` bars and `CABasicAnimation` rotation for the animated morph. Handle `isEnabled` and `isHighlighted` states, accept the label for `accessibilityLabel`, and give the control a minimum 44×44pt hit area (e.g. by enlarging the tappable frame beyond the visible icon, as `packages/web/packages/chrome/src/css/base.css`'s `::after` does).
- **WinUI 3**: Prefer the system glyphs first: a `FontIcon` using the Segoe Fluent Icons `GlobalNavigationButton` glyph for the menu state and `Cancel` for the close state, with `Foreground` inheriting the button's text color. Reserve a custom `StackPanel` of `Rectangle` bars with `RotateTransform` for the animated morph. Set `AutomationProperties.Name` for accessibility, respect `IsEnabled`, and ensure the `Button`'s minimum interactive size meets the platform's 44×44 effective pixel guidance.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chrome/src/MenuButton.tsx` | confirmed (1.2.2) |

## Design Decisions

1. **Decision**: Render the bars as plain `<span>` elements rather than SVG.
   **Rationale**: Plain DOM boxes let the bar geometry live in CSS custom properties (`--menu-bar-thickness`, `--menu-bar-gap`, `--menu-bar-width`) that a consumer can retune, and let the 0.25s transition and the rotation act on the same elements. Colour inheritance is not the differentiator, since SVG could also use `currentColor`. Unverified: the source does not record whether SVG was tried or measured.
   **Approved**: pending

2. **Decision**: Derive the close icon from the two bars via CSS rotation rather than rendering separate markup for the X.
   **Rationale**: Rotating the existing bars keeps the component's JSX simpler and ensures that any change to bar geometry (thickness, spacing) automatically updates both the menu and close icons consistently.
   **Approved**: pending

3. **Decision**: Render bars conditionally — three in menu state, two in close state — rather than always rendering three and hiding one with CSS.
   **Rationale**: No hidden DOM node is left behind: a CSS-hidden third bar would still occupy the grid and add a gap row unless `display: none` were also applied, and the close state's overlay of two bars in one grid cell relies on there being exactly two children.
   **Approved**: pending

4. **Decision**: Keep all animation logic in CSS; the component renders static markup only.
   **Rationale**: This keeps the component lightweight and makes animations easy to customize or disable, e.g. for `prefers-reduced-motion` — which `css/base.css` does not currently implement (see **reduced-motion** in Compliance).
   **Approved**: pending

5. **Decision**: Require the `label` prop with no default value.
   **Rationale**: The button has no visible text, so an accessible name is necessary for the component to be usable by assistive technologies.
   **Approved**: pending

6. **Decision**: Perform no runtime check on `label`; rely on the required TypeScript prop.
   **Rationale**: The source renders `aria-label={label}` directly, so a caller outside the type system that omits or empties `label` gets a button with no accessible name and no warning. The recipe records this as the current behavior, not an endorsement.
   **Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `packages/web/packages/chrome/src/MenuButton.tsx` (the required `label` prop rendered as `aria-label` on a native `<button>`, with no custom ARIA roles needed) and `packages/web/packages/chrome/src/css/base.css` (`position: relative` plus the 44px `::after` hit area satisfy touch-target-size; the absence of any `prefers-reduced-motion` rule fails reduced-motion). `separation-of-concerns` passes: the component is a single-purpose presentational element (bars in, click-through button out) with no owned business logic or state beyond the `icon` prop it renders from. `unit-test-coverage` passes: `packages/web/packages/chrome/src/__tests__/MenuButton.test.tsx` covers every conformance vector.

Focus visibility has no requirement and no vector: `packages/web/packages/chrome/src/css/base.css` defines no `:focus-visible` style, so the icon-only button relies on the browser's default outline, which a consumer's reset may remove. This is a gap, not a pass.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-11-14 | Mike Fullerton | Corrected the bar geometry to match css/base.css (1px bars, 4px gap, 5px pitch), moved Appearance MUSTs into named requirements with five computed-style vectors, rewrote Design Decisions 1 and 3, recorded the no-runtime-label-check as Decision 6, dropped the vector that locked in the invalid-icon behavior, recorded the missing focus-visible style in Compliance, and switched to repo-relative paths and fragment links. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Invalid icon renders 2 uncrossed bars, no close class, not a menu-icon fallback (bug logged). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename must-* requirements to subject-only kebab-case and drop the redundant icon-toggle requirement, add a relative-positioning requirement and vector for the hit area, correct the Reduce Motion/Increase Contrast claims against css/base.css, reformat Design Decisions to Decision/Rationale/Approved, replace the Compliance section with a real table, fix vector 009 and add the missing conformance vectors, recommend native platform glyphs first in Platform Notes and rename Web to React/Web, resolve the no-label edge case contradiction, add the consumer-managed aria-expanded/aria-controls guidance, and add button to related |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Resolve review markers: bar dimensions and tap target sourced from css/base.css |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from MenuButton.tsx source |
