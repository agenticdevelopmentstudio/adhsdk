---
id: bff3f332-25d0-468d-b6e6-0b668323030c
title: "Pulse Rule"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A one-pixel horizontal rule in the accent colour that fades at both ends and slowly breathes, for under a hero's name."
platforms:
  - typescript
  - web
tags:
  - landing
  - divider
  - animation
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Pulse Rule

## Overview

Pulse Rule is a horizontal rule drawn in the accent colour that slowly breathes: its opacity rises and falls on a repeating cycle. The source describes it as "the hairline under a hero's name". It renders a single `<hr>` element and takes one optional prop, `className`. All of its look, the gradient, the animation and the reduced-motion behavior, lives in the `.lp-pulse-rule` rule of `blocks.css`; the component only emits the element and its class.

Placement (width, margins) belongs to the caller, which supplies it through `className`; how the rule looks belongs to this component. It is a server component: the breathing is a CSS animation, so no client script is involved, and the client barrel does not re-export it.

## Behavioral Requirements

- **render-hr**: The component MUST render exactly one `<hr>` element and no other element.
- **kit-class**: The `<hr>` MUST carry the class `lp-pulse-rule`.
- **append-class-name**: When a non-empty `className` is given, the component MUST append it after `lp-pulse-rule`, separated by a single space, so the class attribute is `lp-pulse-rule <className>`.
- **no-class-name**: When `className` is absent or an empty string, the class attribute MUST be exactly `lp-pulse-rule`, with no trailing space.
- **class-name-appended-not-replaced**: A caller-supplied `className` MUST NOT replace `lp-pulse-rule`.
- **no-other-props**: The component MUST accept no prop other than `className`; it takes no children and sets no inline style or attribute beyond `class`.
- **server-component**: The component MUST be exported from the server barrel and MUST NOT be exported from the client barrel.
- **hairline-height**: The rule MUST be drawn 1px tall with no border.
- **accent-gradient**: The rule's background MUST be a 90-degree linear gradient from transparent, through the accent color `--lp-accent` at 50%, to transparent, so it fades to nothing at both ends.
- **accent-fallback**: When `--lp-accent` is not defined, the rule SHOULD fall back to `#9a9a9a`.
- **breathing-animation**: The rule MUST run the `lp-pulse-rule-breathe` animation with `ease-in-out` timing, repeating indefinitely.
- **breathing-opacity**: The animation MUST hold opacity at the floor value at 0% and 100% of the cycle and at 1 at 50%.
- **period-property**: The cycle length MUST be read from `--lp-pulse-rule-period`, defaulting to 6s when the property is not set.
- **floor-property**: The opacity floor MUST be read from `--lp-pulse-rule-floor`, defaulting to 0.35 when the property is not set.
- **reduced-motion-rest**: Under `prefers-reduced-motion: reduce`, the rule MUST have no animation and MUST sit at opacity 1.
- **compositor-only-animation**: The animation SHOULD change opacity alone, never a color, so the rule can breathe indefinitely without triggering repaints.

## Appearance

- **Corner radius**: None; the rule is a flat 1px line.
- **Padding**: None; spacing is the caller's, supplied through `className`. The stylesheet sets no margin, so the browser's default `<hr>` margin applies unless the caller overrides it.
- **Font**: Not applicable: the element renders no text.
- **Background**: `linear-gradient(90deg, transparent, var(--lp-accent, #9a9a9a) 50%, transparent)`. The stylesheet comment explains the symmetry: a rule that starts solid and trails off has a left edge, and this one is drawn under centred type.
- **Foreground/Text**: Not applicable: the element renders no text.
- **Border**: `border: 0`, which removes the default `<hr>` border so the gradient is the only visible mark.
- **Shadow**: None.
- **Min/Max size**: Height is fixed at `1px`. Width is not set by the component; the caller sets it through `className`.
- **Motion**: `lp-pulse-rule-breathe`, `ease-in-out`, `infinite`. Opacity goes from `--lp-pulse-rule-floor` (default 0.35) at 0% to 1 at 50% and back to the floor at 100%. A full cycle takes `--lp-pulse-rule-period` (default 6s).

## States

The rule is inert: it has no pressed, disabled, focused or loading state, and no prop or event changes its appearance.

| State | Appearance change |
|-------|------------------|
| Default | Breathing: opacity cycles between the floor (0.35 by default) and 1 over the period (6s by default) |
| Reduced motion | At rest at opacity 1, no animation (`prefers-reduced-motion: reduce`) |
| Pressed | Not applicable: the rule is not interactive and has no pressed state |
| Disabled | Not applicable: the rule is not a control and has no disabled state |
| Focused | Not applicable: an `<hr>` is not focusable and the source adds no `tabIndex` |
| Loading | Not applicable: the rule does no asynchronous work |

## Accessibility

- **Role**: The component renders a native `<hr>`, which the browser exposes as a separator; the source adds no ARIA attribute.
- **Label requirements**: Not applicable: the rule carries no text and is not interactive, so it needs no label.
- **Announce state changes**: Not applicable: the animation changes only opacity and no state is announced.
- **Minimum tap target**: Not applicable: the rule is not interactive, so no touch or click target is involved.
- **reduced-motion-support**: The rule MUST stop animating and sit at full opacity when the reader has asked for reduced motion. The stylesheet comment gives the reason: "a reader who has asked for less motion has not asked for a fainter page".
- **separator-exposure**: The component renders a native `<hr>` and adds no `role`, `aria-hidden` or other ARIA attribute, so a browser exposes it as a separator and a screen reader may announce it beneath the hero name. The source does not mark the hairline as presentation.
- **rule-contrast**: NEEDS REVIEW: Not implemented in source. The source cannot say whether the 1px accent hairline, faded to transparent at both ends and at 0.35 opacity at its floor, meets any contrast threshold against the host's background; a contrast measurement against the host theme's accent and surface colors would settle it.

## Conformance Test Vectors

Vectors 001 to 003 and 007 to 009 are drawn from the `PulseRule` tests in `hero-nav.test.tsx` (`is an <hr> with the kit class, the caller's appended`, `ships from the server barrel, a server component, and the client barrel re-exports nothing of it` and `breathes in the accent, and rests at full strength for reduced motion`). The other vectors follow from the component and `blocks.css`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pulse-rule-001 | render-hr, kit-class, no-class-name | Render `PulseRule` with no props | The container holds an `<hr>` whose class attribute is exactly `lp-pulse-rule` (test: `is an <hr> with the kit class, the caller's appended`) |
| pulse-rule-002 | append-class-name, class-name-appended-not-replaced | Render `PulseRule` with `className="ad-hero-rule"` | The `<hr>` class attribute is exactly `lp-pulse-rule ad-hero-rule` (same test) |
| pulse-rule-003 | server-component | Import the server barrel and the client barrel | `typeof server.PulseRule` is `function`; `'PulseRule' in client` is false (test: `ships from the server barrel...`) |
| pulse-rule-004 | no-class-name | Render `PulseRule` with `className=""` | The class attribute is exactly `lp-pulse-rule`, with no trailing space |
| pulse-rule-005 | render-hr | Render `PulseRule` with no props | The container has exactly one child element and it is an `<hr>` |
| pulse-rule-006 | hairline-height, accent-gradient, breathing-animation | Read `blocks.css` | The `.lp-pulse-rule` rule sets `height: 1px`, `border: 0`, a gradient that uses `var(--lp-accent, #9a9a9a)` at 50%, and an infinite `ease-in-out` animation named `lp-pulse-rule-breathe` |
| pulse-rule-007 | breathing-animation, breathing-opacity | Read `blocks.css` | The stylesheet contains `@keyframes lp-pulse-rule-breathe` (test: `breathes in the accent, and rests at full strength for reduced motion`) |
| pulse-rule-008 | reduced-motion-rest | Read `blocks.css` | Under `@media (prefers-reduced-motion: reduce)`, `.lp-pulse-rule` sets `animation: none` and `opacity: 1` (same test) |
| pulse-rule-009 | period-property, floor-property | Render the rule with `--lp-pulse-rule-period: 12s` and `--lp-pulse-rule-floor: 0.6` set on the element | The cycle takes 12s and opacity bottoms out at 0.6; with neither set, the cycle takes 6s and the floor is 0.35 |
| pulse-rule-010 | accent-fallback | Render the rule where `--lp-accent` is undefined | The gradient's centre color is `#9a9a9a` |

## Edge Cases

- **Empty className**: An empty string is falsy in the source's conditional, so the class attribute is exactly `lp-pulse-rule`. The component MUST NOT emit a trailing space.
- **Undefined className**: Omitting the prop gives the same output as an empty string. The component MUST render without error.
- **Boundary values**: The floor and period are plain custom properties and the source clamps neither. A floor of 1 flattens the breathing to a constant opacity; a floor of 0 lets the rule disappear at the ends of each cycle; a very short period speeds the pulse accordingly. The source does not guard these values, and a translation SHOULD pass them through unchanged.
- **Missing accent property**: When `--lp-accent` is not defined the gradient falls back to `#9a9a9a`, so the rule MUST still render a visible grey hairline.
- **Reduced motion**: Under `prefers-reduced-motion: reduce` the rule MUST be at rest at opacity 1, even when `--lp-pulse-rule-floor` is set.
- **Concurrent access**: Not applicable: the component is a pure function of its props with no shared or mutable state.
- **Error states and offline**: Not applicable: the component makes no network, file or storage calls, so it has no dependency that can fail or disconnect.
- **Null input**: `className` is typed as an optional string; the source adds no guard for `null`, and a `null` value is falsy and would render the bare class.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` | string (prop, optional) | none | Appended after `lp-pulse-rule`; carries the caller's placement such as width and margins |
| `--lp-pulse-rule-period` | CSS time (custom property) | `6s` | Length of one breathing cycle; set on the element or an ancestor to slow the rule |
| `--lp-pulse-rule-floor` | CSS number (custom property) | `0.35` | Opacity at the low point of the cycle; set it higher to flatten the pulse, lower to deepen it |
| `--lp-accent` | CSS color (custom property) | `#9a9a9a` | Colour at the centre of the gradient; shared with the rest of the landing kit |

The host stylesheets `site-template/src/css/bridge.css` and `adh/src/styles/adh-landing-bridge.css` both set the period to `6s` and the floor to `0.35`.

## Deep Linking

Not applicable: the rule is a static decorative element with no navigation or link target.

## Localization

Not applicable: the component renders no text and contains no string literals.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Honored: under `prefers-reduced-motion: reduce` the animation is removed and opacity is set to 1 |
| Increase Contrast | Not applicable: the source has no `prefers-contrast` rule for the rule, which draws in `--lp-accent` at whatever contrast the host theme gives it |
| Differentiate Without Color | Not applicable: the rule is decorative and carries no meaning that depends on its colour |

## Feature Flags

Not applicable: the component has no flag check or conditionally gated behavior.

## Analytics

Not applicable: the component fires no events and has no instrumentation.

## Privacy

- **Data collected**: None.
- **Storage**: None.
- **Transmission**: None; nothing leaves the page.
- **Retention**: Not applicable: no data is kept.

## Logging

Not applicable: the component performs no logging or debug output.

## Platform Notes

- **SwiftUI**: Not the source platform. Draw a `Rectangle` (or `Divider` styled with a foreground gradient) 1pt tall and fill it with a `LinearGradient` of clear, accent and clear stops along the horizontal axis. Drive the breathing with `withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true))` on an opacity state. This differs from the source in that the cycle is a CSS keyframe loop (floor, then 1 at 50%, then floor), while SwiftUI reverses a one-way animation, so the 3-second duration is the half-cycle that matches the 6-second period. Read `@Environment(\.accessibilityReduceMotion)` and skip the animation at opacity 1. Add `.accessibilityHidden(true)` since the line is decorative.
- **Compose**: Not the source platform. Use a `Box` with `Modifier.height(1.dp)` and `Modifier.background(Brush.horizontalGradient(listOf(Color.Transparent, accent, Color.Transparent)))`. Animate alpha with `rememberInfiniteTransition()` and `animateFloat` between the floor and 1 using `infiniteRepeatable(tween(3000, easing = FastOutSlowInEasing), RepeatMode.Reverse)`. Android has no media query; read the system animator duration scale (a value of 0 means the user disabled animations) and hold alpha at 1. Mark the box with `Modifier.clearAndSetSemantics {}`.
- **React/Web**: The source platform. `packages/web/packages/landing/src/blocks/PulseRule.tsx` is a server component that returns `<hr className=... />`; the look is the `.lp-pulse-rule` rule, the `lp-pulse-rule-breathe` keyframes and the reduced-motion media query in `packages/web/packages/landing/src/css/blocks.css`. The server barrel exports it and the client barrel does not. The two custom properties are set per host in the bridge stylesheets. Build any port from the stylesheet and not from the component, since the component carries no visual logic.
- **AppKit / UIKit**: Not the source platform. Use a 1pt-high `NSView` or `UIView` with a `CAGradientLayer` (clear, accent, clear; `startPoint` (0, 0.5), `endPoint` (1, 0.5)), and animate the view's layer `opacity` with a `CABasicAnimation` that has `autoreverses = true`, `repeatCount = .infinity` and `easeInEaseOut` timing, with a 3-second duration. A layer opacity animation stays on the compositor, as in the source. Check `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` on macOS or `UIAccessibility.isReduceMotionEnabled` on iOS and set opacity to 1 with no animation.
- **WinUI 3**: Not the source platform. WinUI has no `<hr>`; start from a `Rectangle` with `Height="1"` and `HorizontalAlignment="Stretch"`, filled with a `LinearGradientBrush` (`StartPoint="0,0.5"`, `EndPoint="1,0.5"`) of three `GradientStop` entries: transparent at 0, the accent colour (`{ThemeResource SystemAccentColor}`, a Color rather than a brush) at 0.5, transparent at 1. Animate `Opacity` with a `Storyboard` holding a `DoubleAnimation` (`From` the floor, `To` 1, `Duration="0:0:3"`, `AutoReverse="True"`, `RepeatBehavior="Forever"`, `EasingFunction` a `SineEase` with `EasingMode="EaseInOut"`) started from `Loaded`; animating `Opacity` keeps it on the composition thread, as the source does with CSS. There is no media query, so read `UISettings.AnimationsEnabled` and, when it is false, stop the storyboard and set `Opacity="1"`. Because the rule is decorative, set `AutomationProperties.AccessibilityView="Raw"` so Narrator skips it, and expose the period and floor as dependency properties on a `UserControl` with defaults of 6 seconds and 0.35.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/PulseRule.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The look is split into a stylesheet class and two custom properties (`--lp-pulse-rule-period` and `--lp-pulse-rule-floor`) rather than variant props.
**Rationale**: The `blocks.css` comment says "Two custom properties rather than two variants": a host that wants a slower or shallower rule sets a property on the element, and the component needs no prop for it.
**Approved**: pending

**Decision**: `className` is appended to `lp-pulse-rule` and never replaces it.
**Rationale**: The source comment states the split: placement (width, margins) is the caller's, and how the rule looks is this component's.
**Approved**: pending

**Decision**: The gradient fades to transparent at both ends instead of starting solid.
**Rationale**: The `blocks.css` comment explains that a rule that starts solid and trails off has a left edge, and this one is drawn under centred type.
**Approved**: pending

**Decision**: The breathing animates opacity and not a colour ramp.
**Rationale**: The `blocks.css` comment says opacity is compositor-only, so the rule can breathe for as long as the page is open without asking for a paint.
**Approved**: pending

**Decision**: Under reduced motion, the rule rests at full opacity (1) and not at the floor.
**Rationale**: The `blocks.css` comment says "a reader who has asked for less motion has not asked for a fainter page".
**Approved**: pending

**Decision**: The component is a server component with no client code.
**Rationale**: The source comment says the breathing is a CSS animation, so nothing needs to run in the browser, and the test asserts that the client barrel re-exports nothing of it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | passed | Performance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Reduced motion passes because `blocks.css` removes the animation and sets opacity 1 under `prefers-reduced-motion: reduce`. Semantic markup is partial: the component renders a native `<hr>`, but it does not mark the decorative line as presentation, which `separator-exposure` records as the source's behavior. Animation frame rate passes because the keyframes change only opacity, which the stylesheet comment identifies as compositor-only. No-hardcoded-strings passes because the component renders no text. Separation of concerns passes because `PulseRule.tsx` only emits the element and class while all appearance lives in `blocks.css`. Unit-test coverage passes: `hero-nav.test.tsx` has a passing test for every vector, pulse-rule-001 to pulse-rule-010. The render vectors check the DOM; the stylesheet vectors (pulse-rule-006 to pulse-rule-010) assert the rule text in `blocks.css`, including the `6s` and `0.35` defaults and the `#9a9a9a` fallback, because jsdom computes no animation or gradient.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (hero-nav.test.tsx, 10 of 10 vectors); unit-test-coverage now passed. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation from source code |
