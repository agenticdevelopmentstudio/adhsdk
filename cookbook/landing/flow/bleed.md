---
id: feee183a-6488-489e-8e20-c7150bb3e914
title: "Bleed"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Layout component that extends a child element past the content column toward one page edge, creating a visual crop effect."
platforms:
  - typescript
  - web
tags:
  - layout
  - positioning
depends-on: []
related:
  - e0b59d60-0a56-4bf4-85cb-fb0e58170f8e
references: []
approved-by: ""
approved-date: ""
---

# Bleed

## Overview

Bleed extends a child element past the content column boundary toward one page edge, creating the visual effect of the element being cropped by the viewport rather than sitting politely inside the measure. This produces a "window onto something larger" visual metaphor: a frame with air on both sides reads as a picture of an app, while a frame the page edge cuts reads as the app itself. The component uses margin (not transform) to achieve this, forcing the neighboring column to surrender space. It is only meaningful inside a clipping ancestor; see the **Missing clipping parent** edge case.

## Behavioral Requirements

- **render-div**: Component MUST render a single `div` element.
- **accept-children**: Component MUST render all content passed via the `children` prop into the `div`.
- **accept-side-prop**: Component MUST accept a `side` prop with string values `"left"` or `"right"`, defaulting to `"right"`.
- **apply-base-class**: Component MUST apply the class `lp-bleed` to the rendered `div`.
- **side-class**: Component MUST apply a class `lp-bleed--{side}` to the rendered `div`, where `{side}` is the value of the `side` prop.
- **accept-class-name-prop**: Component MUST accept an optional `className` prop and append it to the rendered `div`.
- **falsy-class-filter**: Component MUST NOT output empty strings or undefined values in the class list; falsy class names MUST be filtered before joining.
- **bleed-offset**: At a viewport width of `62rem` or more, `.lp-bleed--right` MUST set `margin-right` and `.lp-bleed--left` MUST set `margin-left` to `calc(-1 * var(--lp-bleed, clamp(2.5rem, 10vw, 9rem)))`, so the offset is 10% of the viewport width, never less than `2.5rem` and never more than `9rem` unless the host sets `--lp-bleed`. The opposite side keeps no margin.
- **bleed-breakpoint**: Below `62rem` the offset MUST NOT apply: a bleed is a no-op and the frame sits in the column like any other content. `62rem` matches the `.lp-split` breakpoint so a bleeding shot and its split change together.
- **bleed-min-width**: `.lp-bleed` MUST set `min-width: 0` so that the bled element can shrink inside a flex or grid parent.
## Appearance

- **Layout mechanism**: The component applies no inline styling itself; the crop's margin, direction, and distance are defined by the `lp-bleed` and `lp-bleed--{side}` CSS classes, as named in **bleed-offset**, **bleed-breakpoint** and **bleed-min-width**: at `62rem` and wider the `side` edge gets a negative margin of `var(--lp-bleed, clamp(2.5rem, 10vw, 9rem))`, and below that nothing changes.
- **Mechanism, not magnitude**: Per the **Margin over transform** design decision, the crop is achieved with `margin`, not `transform`, so the neighboring column surrenders space. The component itself only applies the class names; the margin distance and the narrow-width behavior come from the stylesheet requirements above.
- **Clipping dependency**: The overhang needs a clipping ancestor — see the **Missing clipping parent** edge case and the `Band` ingredient ([adhsdk.ingredient.landing.flow.band](cookbook:e0b59d60-0a56-4bf4-85cb-fb0e58170f8e)).

## States

Not applicable: Bleed is a static layout component with no interactive states (pressed, focused, disabled, etc.). It does not respond to user input or change state based on application logic.

## Accessibility

Bleed itself renders a generic, role-less `div` and makes no accessibility-tree changes; assistive-technology behavior is otherwise inherited entirely from `children`. However, because the component's purpose is to let content run into a visually clipped page edge:

- **No essential content in the crop**: Content placed in the bled region SHOULD be decorative only. Because the overhang is cropped by the ancestor's `overflow-x: clip`, essential text or an interactive control placed there risks being visually cut off, even where it may remain present in the accessibility tree.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| bleed-001 | render-div | `<Bleed>Content</Bleed>` | Renders a `div` element containing "Content" |
| bleed-002 | apply-base-class | `<Bleed>Content</Bleed>` | Rendered `div` has class `lp-bleed` |
| bleed-003 | side-class, accept-side-prop | `<Bleed side="left">Content</Bleed>` | Rendered `div` has class `lp-bleed--left` |
| bleed-004 | side-class, accept-side-prop | `<Bleed side="right">Content</Bleed>` | Rendered `div` has class `lp-bleed--right` |
| bleed-005 | accept-side-prop | `<Bleed>Content</Bleed>` (no side prop) | Rendered `div` has class `lp-bleed--right` (default) |
| bleed-006 | accept-class-name-prop | `<Bleed className="custom">Content</Bleed>` | Rendered `div` has classes `lp-bleed`, `lp-bleed--right`, `custom` |
| bleed-007 | falsy-class-filter, accept-class-name-prop | `<Bleed className="">Content</Bleed>` | Rendered `div` has classes `lp-bleed`, `lp-bleed--right` (empty className excluded) |
| bleed-008 | accept-children | `<Bleed><span>Text</span><button>Click</button></Bleed>` | Rendered `div` contains both `span` and `button` elements |
| bleed-009 | accept-children | `<Bleed>{null}</Bleed>` | Renders successfully with no content (`null` child) |
| bleed-011 | accept-class-name-prop | `<Bleed className="custom-one custom-two">Content</Bleed>` | Rendered `div` has classes `lp-bleed`, `lp-bleed--right`, `custom-one custom-two` (space-separated value appended as-is) |
| bleed-012 | accept-children | `<Bleed><>Content</></Bleed>` | Rendered `div` contains "Content" (fragment's children render inside the `div`) |
| bleed-013 | falsy-class-filter, accept-class-name-prop | `<Bleed>Content</Bleed>` (no `className` prop, so it is `undefined`) | Rendered `div` has exactly the classes `lp-bleed` and `lp-bleed--right`, with no literal `undefined` and no trailing space |
| bleed-014 | bleed-offset | Render `<Bleed side="right">Content</Bleed>` with the stylesheet loaded, in a real browser at a 1280px viewport | Computed `margin-right` is `-128px` (10vw, inside the `2.5rem` to `9rem` clamp) and computed `margin-left` is `0px` |
| bleed-015 | bleed-offset | Render `<Bleed side="left">Content</Bleed>` with the stylesheet loaded, in a real browser at a 1280px viewport | Computed `margin-left` is `-128px` and computed `margin-right` is `0px` |
| bleed-016 | bleed-breakpoint | Render `<Bleed>Content</Bleed>` with the stylesheet loaded, in a real browser at a 700px viewport | Computed `margin-right` is `0px` (the offset sits behind the `62rem` breakpoint) |
## Edge Cases

- **Empty children**: `<Bleed>{null}</Bleed>` renders the `div` with no content; see **accept-children** (bleed-009).
- **Undefined `className`**: excluded from the class list before joining; see **falsy-class-filter** (bleed-013). An empty string is excluded the same way (bleed-007). `null` is outside the `string` type and is not a supported input.
- **Side values outside the typed union**: not a supported input, and the result is unspecified by this recipe. The source does no validation and renders `lp-bleed--{value}`, but a port need not match that.
- **Multiple class names in `className`**: a space-separated value (e.g. `"custom-one custom-two"`) is appended as-is, unmodified; see **accept-class-name-prop** (bleed-011).
- **React.Fragment as child**: `<Bleed><>Content</></Bleed>` is valid; the fragment's children render inside the `div`; see **accept-children** (bleed-012).
- **Missing clipping parent**: if Bleed is not rendered inside an ancestor with `overflow-x: clip` (e.g. `.lp-band`; see the `Band` ingredient, [adhsdk.ingredient.landing.flow.band](cookbook:e0b59d60-0a56-4bf4-85cb-fb0e58170f8e)), the overhang widens the document instead of appearing cropped. This is the canonical statement of the `overflow-x: clip` prerequisite; the other sections point here. It is an environmental prerequisite that Bleed cannot detect or enforce on its own.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `'left' \| 'right'` | `'right'` | Direction toward which to extend the child element past the content column |
| `children` | `ReactNode` | — | Required, but may be any `ReactNode`, including `null`. Child content to render inside the bleed container |
| `className` | `string` | `undefined` | Optional. Additional CSS class names to apply to the rendered `div` |

## Deep Linking

Not applicable: Bleed is a layout component with no deep-linking behavior or URL state. It is a presentation wrapper, not a navigable destination.

## Localization

Not applicable: Bleed contains no text strings or localizable content. It is a layout wrapper that renders whatever content is passed via `children`.

## Accessibility Options

Not applicable: Bleed is a layout wrapper that does not respond to accessibility display options (e.g., Reduce Motion, Increase Contrast). Any accessibility options affecting the content are handled by the rendered children, not by Bleed itself.

## Feature Flags

Not applicable: Bleed MUST NOT read feature flags or vary its rendering by configuration flags.

## Analytics

Not applicable: Bleed MUST NOT emit analytics events or telemetry.

## Privacy

Not applicable: Bleed collects no data, stores no state, and transmits no information. It is a stateless layout component.

## Logging

Not applicable: Bleed MUST NOT write logs or debug output.

## Platform Notes

- **SwiftUI**: Implement a custom `Layout` (the `Layout` protocol) that reports extra width toward the bleed edge, or apply a negative `.padding()` on the given side so the child pushes into the neighboring column the way CSS `margin` does. Do not use `.offset()`: it repositions the view visually without reclaiming layout space from siblings, which is exactly the transform-based approach the **Margin over transform** design decision rejects. Clip the ancestor with `.clipped()` to match `overflow-x: clip`.

- **Compose**: Implement with a custom `Layout` composable (or `Modifier.layout`) that measures the child wider than its slot and places it offset toward the bleed edge, so the sibling composables are actually pushed aside. `Modifier.offset()` / `absoluteOffset()` alone only repositions the child without affecting the measured layout, so it does not reproduce the effect. Clip the ancestor with `Modifier.clipToBounds()` to match `overflow-x: clip`. The `side` parameter maps to which edge the extra measured width is added toward.

- **React/Web**: The component renders a `div` with class names joined from `['lp-bleed', `lp-bleed--${side}`, className]` after filtering falsy values. It accepts `side`, `children`, and `className` as props. It relies on a clipping ancestor; see the **Missing clipping parent** edge case.

- **AppKit / UIKit**: Implement a custom view (subclass of `NSView` or `UIView`) that uses a negative leading/trailing Auto Layout constraint (or a negative frame margin) on the given side so the child's layout genuinely extends past the content column — the same role CSS `margin` plays. A positioning transform would move the view visually without giving up the space, so it does not qualify. Use `clipsToBounds` on the parent to crop the overhang, equivalent to `overflow-x: clip`.

- **WinUI 3**: Implement using a `Grid` or custom `Panel` with a negative `Margin` on the given side (`Margin.Left` or `Margin.Right`) so the child's layout slot genuinely extends past the content column. Set `UIElement.Clip` to a `RectangleGeometry` on the parent to crop the overhang, equivalent to `overflow-x: clip`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/flow/Bleed.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Use CSS `margin` rather than CSS `transform` to extend the child element past the content column.
**Rationale**: `margin` forces the neighboring column to surrender space, creating the intended visual hierarchy; a `transform` would move the element visually without affecting layout, leaving space in the neighboring column and defeating the "crop by viewport" effect.
**Approved**: pending

**Decision**: Filter out falsy class names (empty strings, `null`, `undefined`) before joining the class list.
**Rationale**: Prevents unintended class concatenation (e.g., a stray double space from an empty `className`) and keeps the rendered class list clean.
**Approved**: pending

**Decision**: Do not validate that `side` is one of the expected values (`'left'` or `'right'`).
**Rationale**: TypeScript's `'left' | 'right'` type covers the supported surface, which keeps the component simple and delegates validation to the caller. What a value outside the type renders is unspecified (see the **Side values outside the typed union** edge case).
**Approved**: pending

**Decision**: Assume Bleed is rendered inside a container with `overflow-x: clip` (e.g. `.lp-band`, see the `Band` ingredient).
**Rationale**: Enforcing the clip inside Bleed would couple Bleed to a specific parent component; see the **Missing clipping parent** edge case for what happens without it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The source renders a plain, role-less `div` with no ARIA misuse (semantic-markup); it is a non-focusable wrapper that adds no tab stops and does not change the keyboard order of its children (keyboard-navigable); the advice to keep the bled area decorative-only is under **Accessibility**. Best-practices statuses rest on `Bleed` being pure presentation over its `side`/`children`/`className` props with no embedded logic (separation-of-concerns: passed), and on `flow-conformance.test.tsx` covering bleed-001 to bleed-013 (unit-test-coverage: partial). Vectors bleed-014 to bleed-016 are skipped: they need real layout and media queries, which jsdom lacks.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Made side-passthrough an unspecified edge case and dropped bleed-010, added named offset, breakpoint and min-width requirements with vectors, an undefined-className vector, deduplicated the clip prerequisite, reordered and relabelled the platform notes, and corrected compliance statuses. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; added a `side-passthrough` requirement documenting the unvalidated `side` passthrough as undefined-by-the-type behavior; filled in Appearance and Accessibility with real content; fixed the `bleed-009` test-vector bug and added vectors for previously uncovered edge cases; replaced the Compliance section with a real check table; corrected the Platform Notes to layout-affecting mechanisms consistent with the margin-over-transform decision and fixed the WinUI 3 API citation; reformatted Design Decisions into the three-line form; linked the `Band` ingredient in `related`. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
