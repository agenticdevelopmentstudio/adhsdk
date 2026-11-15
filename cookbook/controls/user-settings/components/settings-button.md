---
id: a05c5131-d626-4e2a-9832-9ba517535971
title: "Settings Button"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A button for the user-settings control family, rendering variant-based `aws-button` styling and passing through standard HTML button attributes."
platforms:
  - typescript
  - web
tags:
  - button
  - interactive
  - ui-control
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Settings Button

## Overview

The Settings Button is a React button component in the `user-settings` control family (`packages/web/packages/controls/src/user-settings/components/SettingsButton.tsx`) that provides a flexible foundation for button controls. It accepts all standard HTML button attributes and supports visual variants through CSS class naming under the `aws-` prefix — this toolkit's CSS namespace for library-authored classes (e.g. `aws-button`, `aws-button--primary`). The component is designed to accommodate application-specific styling via CSS classes while maintaining semantic HTML button structure.

## Behavioral Requirements

- **render-as-button**: Component MUST render as a standard HTML `<button>` element.
- **accept-html-attributes**: Component MUST accept and pass through all standard HTMLButtonElement attributes (onClick, disabled, aria-*, data-*, etc.) via rest props.
- **support-children**: Component MUST render the `children` prop if provided; children MAY be text nodes or React elements.
- **apply-base-class**: Component MUST always include the CSS class `aws-button` on the rendered button element.
- **apply-variant-class**: Component MUST apply a variant-based CSS class in the format `aws-button--{variant}` where variant is the value of the `variant` prop.
- **default-variant**: Component MUST default the `variant` prop to `'primary'` when not provided.
- **closed-variant-set**: Component's `variant` prop MUST be constrained to the closed set `'primary' | 'secondary' | 'destructive'` (the `SettingsButtonVariant` type), so no other string is assignable.
- **default-type**: Component MUST default the HTML `type` attribute to `'button'` when not provided.
- **merge-classname**: Component MUST combine `aws-button`, the variant class, and any custom `className` prop using whitespace separation, filtering out falsy values.
- **consumer-accessible-label**: Consumers MUST give the button an accessible name, either as text content in `children` or through an `aria-label` (or `aria-labelledby`) attribute passed via rest props; the component does not supply one.
## Appearance

The component defines no inline styles. Appearance comes from the `aws-button` and `aws-button--{variant}` rules in the package stylesheet (`user-settings/styles.css`), and the library ships the three variant styles. These are the values:

- **Base (`aws-button`)**: inherited font family at `font-size: 0.875rem`; padding `0.5rem 0.95rem`; corner radius `0.375rem`; `1px` border, transparent unless the variant sets a color; pointer cursor; transitions on `filter`, `background` and `border-color` of 80ms.
- **Primary**: background and border `--aws-accent`; text `--aws-bg`.
- **Secondary**: background `--aws-surface`; border `--aws-border`; text inherited.
- **Destructive**: background `--aws-red-dim`; border and text `--aws-red`.
- **Shadow**: none.
- **Size**: about 35px tall at a 16px root font size (0.875rem text at normal line height, 0.5rem padding top and bottom, 1px border); width follows the content.
## States

| State | Appearance change |
|-------|------------------|
| Default | Appearance determined by the CSS class set (`aws-button`, `aws-button--{variant}`) |
| Hover | Applies only when the button is not disabled (`:hover:not(:disabled)`). Primary: `filter: brightness(1.08)`. Secondary: background `--aws-surface-hover`. Destructive: background `--aws-red` with white text. |
| Focus | `:focus-visible` shows a 2px solid `--aws-accent` outline with a 2px offset; plain `:focus` has no style |
| Active/Pressed | No `:active` style is defined |
| Disabled | `:disabled` sets `opacity: 0.5` and `cursor: not-allowed`; triggered by the `disabled` HTML attribute |
## Accessibility

- **Role**: Implicit button role from native HTML `<button>` element.
- **Label requirements**: See #requirements/consumer-accessible-label.
- **Button type**: Component uses semantic HTML button element, providing built-in keyboard support (Space and Enter keys trigger the button in user agents).
- **Custom attributes**: ARIA attributes (aria-label, aria-pressed, aria-expanded, etc.) pass through rest props to the button element; see #requirements/accept-html-attributes.
- **Minimum tap target**: Minimum tap/click target size is determined by the `aws-button` stylesheet rules; the component enforces no minimum size in code. See Appearance for the resulting size.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| settings-button-001 | render-as-button | No props | Renders `<button>` element in DOM |
| settings-button-002 | default-variant | No variant prop | CSS class `aws-button--primary` is present |
| settings-button-003 | default-type | No type prop | Rendered button has `type="button"` |
| settings-button-004 | apply-base-class | No props | CSS class `aws-button` is present |
| settings-button-005 | apply-variant-class | variant="secondary" | CSS class `aws-button--secondary` is present |
| settings-button-006 | merge-classname | className="custom-class", variant="primary" | Rendered button has classes `aws-button aws-button--primary custom-class` |
| settings-button-007 | support-children | children="Click me" | Rendered button contains text content "Click me" |
| settings-button-008 | support-children | children={<span>React element</span>} | Rendered button contains the React element as child |
| settings-button-009 | accept-html-attributes | onClick handler, disabled={true} | onClick handler is attached and disabled attribute is applied |
| settings-button-010 | accept-html-attributes | aria-label="Settings" | aria-label attribute is applied to button element |
| settings-button-011 | merge-classname | No className, variant="primary" | Rendered button has classes `aws-button aws-button--primary` (no extra spaces) |
| settings-button-012 | closed-variant-set | `variant="invalid"` (type-level, uncast) | TypeScript compilation fails; `'invalid'` is not assignable to type `SettingsButtonVariant \| undefined` (a cast — `variant={'invalid' as SettingsButtonVariant}` — compiles instead, since the literal widens to `string` before the assertion and an assertion only requires comparability, so a cast must not be used as this negative check) |
| settings-button-013 | default-type | type="submit" | Rendered button has `type="submit"` (default overridden) |
| settings-button-014 | merge-classname | className="", variant="primary" | Rendered button has classes `aws-button aws-button--primary` (empty string filtered out, no extra spaces) |

## Edge Cases

- **Undefined children**: When children prop is undefined, the component renders an empty button element (no text or content).
- **Null children**: When children prop is null, the component renders an empty button element.
- **Empty string className**: When className is an empty string, it is filtered out during class merging and does not appear in the final class list.
- **Multiple CSS classes in className prop**: When className contains multiple space-separated classes, all classes are preserved in the merged output.
- **Undefined className**: When className is `undefined`, it is filtered out during class merging. (`className` is typed `string | undefined`, so `false` does not type-check.)
- **Type attribute override**: When a custom `type` prop is passed, it overrides the default `'button'` type.
- **Missing children and empty button**: A button with no children and no text content renders as an empty interactive element; visual appearance depends on CSS (which may apply `::before` or `::after` pseudo-elements or background images).

## Configuration

Not applicable: the component does not provide a configuration object or settings API. Visual and behavioral configuration is achieved through CSS classes (variant) and HTML attributes (type, disabled, etc.).

## Deep Linking

Not applicable: this component is a UI primitive and does not handle navigation or deep linking independently. Deep linking behavior is the responsibility of parent components or application-level routing.

## Localization

Not applicable: the component does not render static text. All user-visible text is supplied via the `children` prop or `aria-label` attribute, allowing parent components to handle localization.

## Accessibility Options

Not applicable: the component inherits accessibility behavior from native HTML buttons and does not implement display options (Reduce Motion, Increase Contrast, Differentiate Without Color). These concerns are addressed by CSS media queries and user agent preferences applied to the button's CSS classes.

## Feature Flags

Not applicable: the component does not implement feature flags or conditional rendering based on configuration flags.

## Analytics

Not applicable: the component does not emit analytics events. Analytics tracking is the responsibility of parent components or event listeners attached via the `onClick` handler passed through rest props.

## Privacy

Not applicable: the component does not collect, store, or transmit data.

## Logging

Not applicable: the component does not produce diagnostic logs.

## Platform Notes

- **SwiftUI**: A SwiftUI implementation would start with `Button(action:label:)` or a custom `ButtonStyle` conformance. Key difference: styling is applied via SwiftUI modifiers (`.buttonStyle()`, `.foregroundColor()`) rather than CSS classes. Variants would be implemented as computed properties or separate `ButtonStyle` types (e.g., `PrimaryButtonStyle`, `SecondaryButtonStyle`) applied via the `.buttonStyle()` modifier.
- **Compose**: An Android Compose implementation would use `Button(onClick:)` from `androidx.compose.material3` or a custom composable. Variants would be implemented as function parameters controlling `colors`, `shape`, and `contentPadding` rather than CSS classes. The `enabled` parameter maps to the `disabled` HTML attribute.
- **React/Web**: Implemented in `packages/web/packages/controls/src/user-settings/components/SettingsButton.tsx`. The component extends `ButtonHTMLAttributes<HTMLButtonElement>` to accept all native HTML button properties. CSS class composition uses the `aws-button` base class and `aws-button--{variant}` variant class. The component is marked `'use client'` for server-side rendering contexts that require explicit client component declaration.
- **AppKit / UIKit**: An AppKit implementation would use `NSButton` with a `bezelStyle` (e.g. `.rounded`, `.regularSquare`) and `controlSize`; variants would be implemented as preset `bezelStyle`/`contentTintColor` combinations. A UIKit implementation would use `UIButton` with `UIButtonConfiguration` (iOS 15+) or custom styling via `setTitleColor()` and `setBackgroundImage()`; variants would be implemented as preset `UIButtonConfiguration` instances or separate factory methods. Neither platform has a native equivalent to HTML's `submit`/`reset` button `type` — those are DOM form-submission semantics with no AppKit/UIKit counterpart; the `type` prop's `'button'` default corresponds to an ordinary tap/click action on both platforms.
- **WinUI 3**: A WinUI 3 implementation would use `Button` from `Microsoft.UI.Xaml.Controls` with variants applied via named `Style` resources, not template selectors. Styling is achieved using XAML `<Style>` definitions with `TargetType="Button"` and `x:Key` matching the variant name (e.g., `"PrimaryButtonStyle"`, `"SecondaryButtonStyle"`). The component's `Style` property binds to `{StaticResource PrimaryButtonStyle}` by default. Content is supplied via the `Content` property (XAML child element); `Padding` and `CornerRadius` are ordinary dependency properties on `Button` (not attached properties) that control spacing and shape. Custom properties (equivalent to React props) are implemented as `DependencyProperty` on a wrapper control or as template parameters passed to a custom control template.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/SettingsButton.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Extend `ButtonHTMLAttributes<HTMLButtonElement>` (minus `children`) and pass all rest props through to the rendered `<button>`, rather than defining a narrow, enumerated prop interface.
**Rationale**: Lets consumers use any native button capability (data attributes, ARIA, event handlers) without the component needing to enumerate them, keeping the component decoupled from visual design decisions.
**Approved**: pending

**Decision**: Style entirely through CSS class names (`aws-button`, `aws-button--{variant}`) rather than inline styles or a styling library; the `variant` prop is a convenience that encodes the `aws-button--{variant}` naming convention while still permitting direct `className` manipulation for advanced customization.
**Rationale**: Keeps the component decoupled from visual design decisions and lets the library ship the three variant styles under the toolkit's `aws-` CSS namespace; consumers customize through `className` or by overriding the `--aws-*` tokens.
**Approved**: pending

**Decision**: Default the `type` attribute to `'button'` rather than inheriting the native HTML default (`'submit'`).
**Rationale**: Prevents accidental form submission when the button is rendered outside an explicit form context, while still letting consumers override it via the `type` prop.
**Approved**: pending

**Decision**: Omit `children` from the `ButtonHTMLAttributes` extension (`Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'children'>`) and declare it as an explicit, typed component prop instead.
**Rationale**: Makes `children` an explicit, documented prop of the component. The `Omit` is redundant for typing: `ButtonHTMLAttributes` already types `children?: ReactNode` (via `DOMAttributes`), so the re-declaration changes nothing at the type level. This is a type signature concern with no runtime behavior, so it has no runtime test vector (see conformance test vector settings-button-012 for the analogous type-level check on `closed-variant-set`).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The native `<button>` element with rest-prop passthrough satisfies screen-reader-support, keyboard-navigable and semantic-markup. `touch-target-size` is `failed`: the shipped stylesheet gives a height of about 35px, under the 44px target of WCAG 2.5.5 (it does meet the 24px minimum of WCAG 2.5.8). `contrast-ratio` is `partial`: with the default tokens, primary text on its accent background is about 8:1, but destructive text on its dim red fill is about 4:1, under 4.5:1. `separation-of-concerns` passed: `SettingsButton.tsx` is pure presentation over props. `unit-test-coverage` is `partial`: `SettingsButton.test.tsx` covers settings-button-001 to 011, 013 and 014; settings-button-012 (the closed variant set) is skipped because it is a compile-time check and vitest does not type-check.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Stated the shipped stylesheet values and real states, added consumer-accessible-label, set touch-target-size to failed and unit-test-coverage to partial, corrected the Omit rationale and variant ownership, and reordered platform notes. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed settings-button-012 to use the uncast variant="invalid" form; the cast form compiles and was a false negative-check example. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, added closed-variant-set as a requirement (variant is already a closed union in source), moved must-omit-children-prop into Design Decisions as a type-level concern, reformatted Design Decisions into Decision/Rationale/Approved entries, replaced the Compliance section with an Accessibility checks table, fixed Platform Notes API accuracy for AppKit/UIKit and WinUI 3, defined the aws- CSS namespace in Overview, added test vectors for type override and empty-string className, dropped the variant-case-sensitivity edge case, rewrote the summary for the user-settings context, and unquoted the created/modified dates |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
