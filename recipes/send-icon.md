---
id: 4a2dcdee-4d2a-4f3f-a3a5-d243ec2b799b
title: SendIcon
domain: adhsdk://recipes/send-icon
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Static SVG icon depicting a send or forward arrow for messaging and action
  contexts.
platforms:
- typescript
- web
tags:
- icon
- ui
depends-on: []
related:
- adhsdk://recipes/chat-input
references: []
approved-by: ''
approved-date: ''
---

# SendIcon

## Overview

SendIcon is a static, presentation-only SVG icon component that renders a diagonal send/forward arrow. It provides a visual affordance for send, submit, or forward actions in messaging, chat, and form contexts. The component has no interactive behavior, state management, or configuration options.

## Behavioral Requirements

- **render-svg-arrow**: Component MUST render as an SVG element with a `<line>` and a `<polygon>` forming a paper-plane-outline send arrow pointing from lower-left to upper-right (see #appearance/geometry).
- **use-current-color**: Component MUST use `currentColor` for the stroke color, allowing the icon to inherit text color from its parent context.
- **maintain-aspect-ratio**: Component MUST render at a fixed 20×20 size, with the SVG's `width`/`height` attributes matching its viewBox, keeping the arrow square and undistorted. The icon does not grow or shrink when its parent container is resized.
- **remain-static**: Component MUST NOT respond to user interaction, state changes, or dynamic updates; it is a static presentation with no event handlers.

## Appearance

- **Dimensions**: 20×20 pixels (SVG viewBox: 0 0 24 24)
- **Stroke width**: 2 units
- **Stroke linecap**: round
- **Stroke linejoin**: round
- **Fill**: none (stroke only)
- **Stroke color**: currentColor (inherits from parent text color)
- **Geometry**: line from (22, 2) to (11, 13); polygon with points (22, 2), (15, 22), (11, 13), (2, 9), tracing a paper-plane outline (four points, not a filled triangular arrowhead)

## States

Not applicable: SendIcon is a static presentation component with no interactive states. It does not respond to user input, focus, or state changes.

## Accessibility

- **Role**: presentational image; MUST be treated as an icon, not interactive
- **Label requirement**: The component itself MUST NOT have a label or `aria-label`. A containing button or action that uses SendIcon as its visual indicator MUST provide an accessible label for the entire control (e.g., `aria-label="Send message"`).
- **Semantic use**: SendIcon SHOULD be wrapped in a `<button>` or similar interactive control; the label belongs to the wrapper, not the icon itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|-----|-------------|-------|----------|
| send-icon-001 | render-svg-arrow | Render component with no props | SVG renders with `<line>` and `<polygon>` elements visible |
| send-icon-002 | use-current-color | Render in context with `color: red` | Icon stroke appears red (inherits currentColor) |
| send-icon-003 | maintain-aspect-ratio | Render inside a container sized differently than 20×20 (e.g., 40×40) | Icon stays fixed at 20×20 pixels; it does not resize to fill the container, because `width`/`height` are hardcoded on the `<svg>` |
| send-icon-004 | remain-static | Inspect the rendered `<svg>` | No `on*` event-handler attributes are present, no `tabindex` attribute is set, and `pointer-events` is not overridden |
| send-icon-005 | render-svg-arrow, maintain-aspect-ratio | Inspect the rendered `<svg>`'s `viewBox` attribute | `viewBox="0 0 24 24"` — a 24-unit coordinate space rendered into a 20×20 box (`width="20" height="20"`), so the arrow is drawn slightly smaller than its own coordinate grid rather than at 1:1 scale. |

## Edge Cases

- **Empty or null rendering**: Not applicable. SendIcon is a functional component that always renders; it has no inputs to be null or empty.
- **Container scaling**: When the parent container is sized differently than 20×20, the icon does not resize — it stays fixed at 20×20 because `width` and `height` are hardcoded on the `<svg>` element (see **maintain-aspect-ratio**). A caller needing a different size overrides those attributes directly, or wraps the icon and applies a CSS transform.

## Configuration

Not applicable: SendIcon accepts no configuration options. All visual properties (size, stroke width, color) are fixed or inherited from parent context.

## Deep Linking

Not applicable: SendIcon is a presentation component with no deep linking concerns.

## Localization

Not applicable: SendIcon is a visual icon with no text content to localize.

## Accessibility Options

Not applicable: SendIcon is a static graphical element that does not respond to accessibility display options like Reduce Motion or Increase Contrast.

## Feature Flags

Not applicable: SendIcon has no feature flags or conditional rendering.

## Analytics

Not applicable: SendIcon does not emit events or track user interactions.

## Privacy

Not applicable: SendIcon collects no data.

## Logging

Not applicable: SendIcon performs no logging.

## Platform Notes

- **React/Web**: `SendIcon.tsx` in `packages/web/packages/chat/src/components/` renders a 20×20 SVG with `fill="none"`, `stroke="currentColor"`, and `strokeWidth="2"`. The `<line>` and `<polygon>` geometry follows `#appearance/geometry`. No props or state management.

- **SwiftUI**: Implement using `Image(systemName: "paperplane")` — the outline variant, matching the stroke-only design, not `paperplane.fill`. Size it with `.font(.system(size: 20))` or an explicit `.frame(width: 20, height: 20)`, and tint it with `.foregroundStyle(.primary)` (not the deprecated `.foregroundColor`) to inherit the surrounding text color like `currentColor`.

- **Compose**: Draw the geometry from `#appearance/geometry` inside a `Canvas` composable using `drawPath`, styled with `Stroke(width = 2.dp, cap = StrokeCap.Round, join = StrokeJoin.Round)`. Use `LocalContentColor.current` directly as the stroke color — there is no `Color.currentColor` analog — so the icon inherits the surrounding content color. Wrap it in `Box(modifier = Modifier.size(20.dp))` to fix the icon's size to match the web dimensions.

- **AppKit / UIKit**: Implement as a custom `UIView` subclass (`NSView` on AppKit) that draws the `#appearance/geometry` path with `UIBezierPath` / `NSBezierPath`. On UIKit, set the stroke color from `tintColor` so the icon inherits the surrounding tint; on AppKit, set it explicitly from `contentTintColor` (`UIColor.label` / its AppKit equivalents do not pick up the parent's tint). Render at a fixed 20×20 point size to match the web dimensions.

- **WinUI 3**: Implement as a single `<Path>` in XAML with path-markup `Data="M22,2 L11,13 M22,2 L15,22 L11,13 L2,9 Z"` (`<Line>`/`<Polygon>` elements are not valid inside `<Path.Data>`), `StrokeThickness="2"`, `StrokeStartLineCap="Round"`, `StrokeEndLineCap="Round"`, and `StrokeLineJoin="Round"`. Bind `Stroke="{Binding Foreground, RelativeSource={RelativeSource TemplatedParent}}"` instead of a hard-coded brush like `SystemBaseHighBrush`, so the icon inherits the parent's `Foreground`. Set `Width="20"` and `Height="20"` with `Stretch="Uniform"` to preserve the aspect ratio.

## Design Decisions

**Decision**: Render the arrow using `stroke` with `fill="none"`, round line caps, and round line joins, rather than a filled shape.
**Rationale**: A hollow, stroked arrow stays visible at small sizes, scales cleanly, and works on both light and dark backgrounds via `currentColor` inheritance; the round caps and joins soften the shape and make it feel less geometric.
**Approved**: pending

**Decision**: Fix the icon at 20×20 pixels via explicit `width`/`height` attributes on the `<svg>` (viewBox `0 0 24 24`), rather than exposing a size prop.
**Rationale**: A fixed size matches common icon conventions in web UI and avoids the API surface of a size prop. The tradeoff is that the icon does not automatically grow or shrink with its parent container — a caller needing a different size overrides `width`/`height` directly.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | failed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`screen-reader-support` is partial because SendIcon itself supplies no label and relies on a wrapping control to provide one — the reference usage in `ChatInput.tsx` does this correctly with `aria-label="Send"` on its `<button>`. `semantic-markup` fails because the `<svg>` in `SendIcon.tsx` sets no `aria-hidden` or `focusable` attribute, so nothing tells assistive technology to skip this purely decorative graphic. `separation-of-concerns` passes because `SendIcon.tsx` is a pure, prop-less presentational SVG with no logic at all, and `unit-test-coverage` fails because no test exercises it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; resolved the fixed-size vs. scaling contradiction in favor of the source's fixed dimensions; corrected the geometry description and the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes; de-duplicated geometry into Appearance; reformatted Design Decisions; added a real Compliance table; linked the related chat-input recipe; removed the untestable color-fallback and dead comment-only accessibility edge cases |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added a fifth Conformance Test Vector row covering the SVG's viewBox/size mismatch. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
