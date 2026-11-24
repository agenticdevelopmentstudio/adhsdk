---
id: 53a37583-e86d-41ca-8dd2-8394ba530091
title: "Shot"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A macOS-style window frame that displays screenshots, clips, or a visually distinct placeholder."
platforms:
  - typescript
  - web
tags:
  - layout
  - screenshot
  - frame
depends-on: []
related:
  - e268fe4f-8e83-4189-b1d2-105cd177308c
references: []
approved-by: ""
approved-date: ""
---

# Shot

## Overview

Shot renders a macOS window frame around visual content—screenshots, video clips, or images. When media is not provided, it displays an obviously unfinished placeholder with optional status text and a caption, designed to make an unfinished frame obvious (the check is for `undefined` only; see Design Decisions). The component applies no transformation to the media; it renders exactly what the host provides.

## Behavioral Requirements

- **frame-chrome**: Component MUST render a macOS-style window frame: a title bar with three decorative dots (styled after macOS traffic lights, uniformly colored) and a window title.
- **title-in-bar**: Component MUST display the `title` prop text in the frame's title bar.
- **media-verbatim**: When `media` is provided, component MUST render it exactly as passed, with no transformation, processing, or motion handling.
- **placeholder-when-no-media**: When `media` is `undefined` (or the prop is omitted), component MUST render an obviously unfinished placeholder frame. Any other value, including `null` and `false`, is treated as media and renders no placeholder.
- **caption-in-placeholder**: Component MUST render the `caption` prop as text content in the placeholder.
- **pending-label-above-caption**: When `pendingLabel` is provided, component MUST render it above the caption in the placeholder; when omitted, the placeholder displays only the caption.
- **falsy-pending-label-omitted**: When `pendingLabel` is a falsy `ReactNode` (`""`, `false`, `null`), it MUST NOT render visible content — the same visible result as when it is omitted.
- **pending-label-verbatim**: Component MUST render `pendingLabel` exactly as passed without transformation.

## Appearance

- **Frame background**: Dark, `var(--lp-raise, #1c1c1c)` — the same macOS-style chrome on every platform (see **WinUI 3** in Platform Notes).
- **Title bar**: `.lp-shot__bar`, a flex row (0.45rem gap, 0.55rem/0.75rem padding) with a bottom hairline border and a `linear-gradient(var(--lp-raise), var(--lp-shot-bar-shade))` background.
- **Dots**: Three `.lp-shot__dot` circles, 10×10px, all colored with the same `var(--lp-shot-dot, rgba(237, 237, 237, 0.22))` — decorative traffic-light styling; the three dots are not functionally distinct red/yellow/green.
- **Title text**: `.lp-shot__name`, left-aligned immediately after the dots in the flex row (`margin-left: 0.4rem`), 0.7rem, letter-spaced, `var(--lp-ink-dim, #a0a0a0)`.
- **Placeholder**: `.lp-shot__placeholder`, a 45° repeating diagonal hatch (`var(--lp-shot-hatch, rgba(216, 216, 216, 0.05))`) to signal incompleteness.
- **Placeholder text**: The caption is wrapped in a `<b>` element, but CSS overrides it to normal weight (`font-weight: 400`), lowercase, `var(--lp-ink-dim, #a0a0a0)` — visually normal weight despite the `<b>` tag.
- **Pending label**: Rendered as plain text directly inside `.lp-shot__placeholder`, above the caption; it has no dedicated style rule, so it inherits the placeholder's own base text (0.78rem, uppercase, 0.14em letter-spacing, `var(--lp-accent, #9a9a9a)`) rather than a distinct smaller font weight.

## States

Not applicable: Shot is a presentational container with no interactive states. It does not respond to user input, maintain focus, or occupy pressed, disabled, or focused states.

## Accessibility

- **Role**: `.lp-shot` is a plain `<div>` with no ARIA role; no interactive role is required since Shot has no interactive elements.
- **Label**: The `title` prop is rendered as ordinary visible text content in `.lp-shot__name`, so screen readers announce it as text when they reach it; no explicit `aria-label` is applied, and none is needed since the title is real text rather than an icon or image standing in for one.
- **Alt text**: Host is responsible for adding alt text to any `<img>` or `<video>` elements passed via the `media` prop; Shot renders media without modification.
- **Placeholder accessibility**: The three dots (`.lp-shot__dot`) are empty `<span>` elements with no text content, so screen readers announce nothing for them without requiring `aria-hidden`. The caption is real text (`<b>{caption}</b>`) inside the placeholder and is announced normally; `pendingLabel`, when provided, is announced the same way since it too is plain text content.
- **Touch target**: Not applicable; Shot contains no interactive elements.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| shot-001 | frame-chrome | title="My App" | Renders `.lp-shot` with a `.lp-shot__bar` containing three `.lp-shot__dot` spans and a title |
| shot-002 | title-in-bar | title="MyWindow" | "MyWindow" appears as text in `.lp-shot__name` |
| shot-003 | media-verbatim | `media={<img src="x.png" />}` | The `<img>` element is rendered directly as the child of `.lp-shot`, replacing the placeholder; no wrapping element, no CSS class added |
| shot-004 | placeholder-when-no-media | media undefined | `.lp-shot__placeholder` renders with the diagonal hatch background instead of media |
| shot-005 | caption-in-placeholder | caption="Screenshot pending" | Placeholder contains "Screenshot pending" inside a `<b>` element |
| shot-006 | pending-label-above-caption | pendingLabel="Capture in progress" | "Capture in progress" renders before (above) the `<b>` caption inside `.lp-shot__placeholder` |
| shot-007 | pending-label-above-caption | pendingLabel undefined | Placeholder renders only the `<b>` caption; no pending-label content precedes it |
| shot-008 | pending-label-verbatim | `pendingLabel={<span className="custom">Loading</span>}` | Renders the `<span>` with its class unmodified |
| shot-009 | falsy-pending-label-omitted | pendingLabel="" | No visible pending-label text renders; placeholder shows only the caption |
| shot-010 | media-verbatim | `media={<video src="x.mp4" />}` | `.lp-shot__placeholder` is absent; only the given `<video>` element renders |
| shot-011 | caption-in-placeholder | caption="" | Placeholder renders an empty `<b>` element; no caption text is visible |
| shot-012 | title-in-bar | title="" | `.lp-shot__name` renders empty; the frame and dots still display |

| shot-013 | falsy-pending-label-omitted | `pendingLabel={false}` | No visible pending-label text renders; placeholder shows only the caption |
| shot-014 | falsy-pending-label-omitted | `pendingLabel={null}` | No visible pending-label text renders; placeholder shows only the caption |
| shot-015 | placeholder-when-no-media | `media={null}` | No `.lp-shot__placeholder` renders; the frame shows the title bar only |
| shot-016 | placeholder-when-no-media | `media={false}` | No `.lp-shot__placeholder` renders; the frame shows the title bar only |
## Edge Cases

- **Media is undefined (or the prop is omitted)**: Placeholder renders; this is the design's primary state until a capture exists. The check is `media === undefined`, not a general falsy/nullish check: passing `media={null}` or `media={false}` takes the `media` branch and renders nothing, leaving a bare title bar with no placeholder and no caption — a host that wants the placeholder must leave `media` undefined (e.g. `capture ?? undefined`, not `capture ?? null`).
- **Caption is empty string**: Placeholder still renders with an empty caption area.
- **PendingLabel is empty string or falsy**: See **falsy-pending-label-omitted**; no visible content renders and the placeholder shows only the caption, the same visible result as pendingLabel being omitted.
- **Title is empty string**: Renders with an empty title bar; frame still displays.
- **Media is a complex nested component tree**: Rendered as-is without interaction or state management by Shot.
- **Media is a video element without preload/autoplay attributes**: Shot does not apply Reduce Motion behavior; host or a wrapper component (for example the `Clip` ingredient ([adhsdk.ingredient.landing.blocks.clip](cookbook:e268fe4f-8e83-4189-b1d2-105cd177308c))) must handle motion preferences.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `string` | — (required) | Window title text drawn in the frame's title bar. |
| `caption` | `string` | — (required) | Text rendered as the placeholder's caption when `media` is absent; also the string the host should reuse for `media`'s alt/aria text. |
| `pendingLabel` | `ReactNode` | `undefined` | Status line rendered above the caption in the placeholder; omitted (or falsy), the placeholder shows only the caption. |
| `media` | `ReactNode` | `undefined` | Content (e.g. an `<img>`, `<video>`, or this package's `Clip`) rendered in place of the placeholder, exactly as given with no transformation. |

## Deep Linking

Not applicable: Shot is a presentational layout component without navigation or routing responsibilities.

## Localization

Not applicable: Shot renders only props provided by the host. All text (title, caption, pendingLabel) originates from the host and is the host's responsibility to localize.

## Accessibility Options

- **Dynamic Type / responsive text scaling**: Title, caption, and pendingLabel text are sized in `rem` units (`.lp-shot__name` at 0.7rem, `.lp-shot__placeholder` at 0.78rem), so they scale with the browser's root font size and zoom level; Shot does not fix pixel sizes or otherwise disable scaling.
- **Reduce Motion**: Not applicable; Shot itself renders no animation (see **media-verbatim** and the Clip recipe for motion handling of media).
- **Increase Contrast**: Not addressed; colors are fixed CSS custom properties (`--lp-ink-dim`, `--lp-accent`, `--lp-raise`) with no separate high-contrast variant.
- **Differentiate Without Color**: Not applicable; no information in the frame or placeholder is conveyed by color alone.

## Feature Flags

Not applicable: Shot has no conditional behavior or feature flags.

## Analytics

Not applicable: Shot is a presentational container with no user interaction and generates no events.

## Privacy

Not applicable: Shot does not collect, store, or transmit data.

## Logging

Not applicable: Shot performs no operations requiring diagnostic logging.

## Platform Notes

- **React/Web**: Component defined in `packages/web/packages/landing/src/blocks/Shot.tsx`. Renders a `<div class="lp-shot">` containing a title bar (`.lp-shot__bar`) with three dots (`.lp-shot__dot`) and title text (`.lp-shot__name`), followed by either the placeholder (`.lp-shot__placeholder`, containing `pendingLabel` then a `<b>` caption) or `media`. When `media` is provided it is rendered directly as `.lp-shot`'s only remaining child — not wrapped in any additional element, and never a sibling of the placeholder, which is not rendered in that case. Styles are external CSS; Shot applies no inline styles. For autoplaying video or motion-sensitive content, host should use the `Clip` ingredient ([adhsdk.ingredient.landing.blocks.clip](cookbook:e268fe4f-8e83-4189-b1d2-105cd177308c)), exported from `@adh-sdk/landing/client`, or the `usePrefersReducedMotion` hook to respect `prefers-reduced-motion`.
- **SwiftUI**: Use a `VStack` or `ZStack` wrapping a custom overlay view that draws the macOS window chrome (title bar with traffic light dots, title text). Place the content view (or a placeholder image with a hatching pattern) in the main body. Bind the optional `media` property to conditional rendering of content vs. placeholder. Title and caption are `String` properties; optional label is a generic `View`. Use fixed colors, not system colors, so the chrome matches the web: bar gradient from `#1c1c1c` to `rgba(16, 16, 16, 0.6)`, three dots in `rgba(237, 237, 237, 0.22)`, title in `#a0a0a0` at 0.7 of body size.
- **Compose**: Build with `Column` or `Box` containing a header composable that renders the title bar (horizontal row of three `Surface` circles, all filled with `Color(0x38EDEDED)` (the web's `rgba(237, 237, 237, 0.22)`), and `Text` for the title) and a content area. Compose has no built-in hatch drawable; render the placeholder's diagonal hatch with `Modifier.drawBehind { }` drawing repeating diagonal lines on the `DrawScope`, or by tiling a small hatch `ImageBitmap` as the background brush. Media is a nullable slot. Caption and pendingLabel are optional `@Composable` parameters. Use fixed colors, not Material 3 theme tokens, so the chrome is the same on every platform: frame `#1c1c1c`, title text `#a0a0a0`.
- **AppKit / UIKit**: On macOS, wrap the content in a custom `NSView` that draws the window chrome (frame border, title bar with traffic lights, title text) using `NSBezierPath` and `CAShapeLayer`. On macOS, the placeholder is an `NSView` with a repeating diagonal hatch drawn in `draw(_:)`, and media is an `NSView` or `NSImageView`. On iOS, draw the same macOS-style frame, not a native iOS chrome: use a rounded `UIView` containing a title-bar view with three equal dots and the title label (fixed colors as above), a placeholder `UIView` whose hatch is a Core Graphics pattern color, and media as a `UIView` or `UIImageView`.
- **WinUI 3**: Implement using a `Grid` with two rows: title bar (top) and content area (bottom). Title bar is a `StackPanel` with three `Ellipse` shapes and a `TextBlock` for the title, on a dark background matching the same macOS-style chrome used on every other platform — not the Windows system chrome aesthetic. WinUI 3 has no built-in pattern/hatch brush: render the placeholder's diagonal hatch with a Win2D `CanvasControl` (`Microsoft.Graphics.Canvas.UI.Xaml`) drawing repeating diagonal lines, or tile a small hatch bitmap with an `ImageBrush`, with an overlay `TextBlock` for caption and pendingLabel. For the title bar background, use a hardcoded `SolidColorBrush` or `LinearGradientBrush` from `#1c1c1c` to `#101010` (not a system theme brush, which would change with the system theme), with the title in `#a0a0a0` and the three dots in `#38EDEDED`. Use conditional binding or `VisualStateManager` to toggle placeholder vs. media state.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Shot.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Shot renders `media` exactly as passed, applying no transformation, processing, or optimization.
**Rationale**: The host (landing or feature page) owns the content strategy — optimizing images, deferring video load, and handling accessibility are the host's responsibility. Shot's responsibility is framing, not transformation.
**Approved**: pending

**Decision**: The placeholder is a mandatory visual state, not an optional one — when `media` is absent, an obviously unfinished frame (diagonal hatch background) renders to prevent shipping an incomplete capture by accident.
**Rationale**: The source JSDoc for `media` states: "Absent renders the placeholder frame — deliberately, obviously unfinished, so one shipped by accident is caught rather than mistaken for a screenshot of a product that looks like that."
**Approved**: pending

**Decision**: The placeholder check is a deliberate `media === undefined`, not a nullish or falsy check.
**Rationale**: A host that passes `media={null}` or `media={false}` has made an explicit choice to render nothing there, and Shot renders `media` verbatim. The cost is that the unfinished-frame safeguard does not catch those values: they leave a bare title bar with no placeholder, so a host that wants the placeholder must leave `media` undefined (`capture ?? undefined`).
**Approved**: pending

**Decision**: The caption in the placeholder is rendered in a `<b>` element that the stylesheet resets to normal weight.
**Rationale**: This is how the source is written, and the `<b>` gives the CSS a hook for the caption. It carries no emphasis meaning, but assistive technology may read it as emphasis, so `semantic-markup` stays partial; a port SHOULD use a plain `<span>` (or its platform's plain text element) instead.
**Approved**: pending

**Decision**: Shot does not apply Reduce Motion handling itself; for autoplaying video or motion-sensitive clips, hosts use the package's `Clip` component or the `usePrefersReducedMotion` hook.
**Rationale**: Keeping motion-preference handling out of Shot lets Shot stay a simple frame while `Clip` (or a host driving its own element) owns the two cooperating halves that reduced-motion handling requires.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `Shot.tsx` and its CSS: text sizes are set in `rem` (`.lp-shot__name` 0.7rem, `.lp-shot__placeholder` 0.78rem), so `dynamic-type-support` passes; foreground/background colors are CSS custom properties with fallback values whose final computed contrast depends on the host theme, so `contrast-ratio` is partial; and the component applies no explicit ARIA roles or `aria-hidden`, relying on the dots being empty (no accessible name) and the title/caption/pendingLabel being ordinary text nodes, so `semantic-markup` is partial. `separation-of-concerns` passes: `Shot` is a pure presentational function with no business logic, data fetching, or state, rendering exactly the `media`/`caption`/`pendingLabel` props it is given. `unit-test-coverage` passes: `shot.test.tsx` has one passing test for each of shot-001 to shot-016, covering the `<img>` and `<video>` media variants and the falsy/empty caption, title and pendingLabel edge cases.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Restated placeholder-when-no-media in terms of undefined, added design decisions for the undefined check and the caption b element, linked Clip as an ingredient, added vectors for null/false media and pendingLabel, and gave native ports fixed chrome colors and definite macOS and iOS guidance. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed Media-is-null/undefined edge case: the placeholder check is media === undefined only; media={null}/{false} renders nothing. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and added falsy-pending-label-omitted with a vector, added vectors for media-present/empty-caption/empty-title, corrected Compose/UIKit/WinUI 3 Platform Notes APIs and macOS-chrome parity, resolved the media-wrapping contradiction between Platform Notes and shot-003, reformatted Design Decisions and quoted the source JSDoc instead of pointing at it, replaced Compliance/Configuration/Accessibility Options "Not applicable" with a grounded table, grounded Appearance in actual CSS values, reworded summary, and added Clip to related |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from Shot.tsx source |
