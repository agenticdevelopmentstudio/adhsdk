---
id: a56695f3-0205-4c9b-b724-53be608de2f0
title: "Alert"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Inline, non-modal callout — a bordered, tonal box with an optional icon, title, and description; five color variants: default, info, success, error, accent."
platforms:
  - typescript
  - web
tags:
  - ui
  - alert
  - feedback
depends-on: []
related:
  - 550f00f7-bfb2-415e-9b15-bd5dce015500
references: []
approved-by: ""
approved-date: ""
---

# Alert

## Overview

Alert (`packages/web/packages/ui/src/components/alert.tsx`) is an inline,
non-modal callout: a bordered, tonal box with an optional leading icon, a
title, and a description. Per the source comment, it is themed entirely from
`apt-*` status tokens. The module exports four names: `Alert` (the root
container), `AlertTitle` and `AlertDescription` (two positioned text
sub-components), and `alertVariants` (the standalone `cva` styling function).
Layout is CSS grid: the root reserves a first column for an optional icon and
a second column (`col-start-2`) for `AlertTitle`/`AlertDescription`; the
column layout only widens to make room for an icon when a direct `<svg>`
child is present.

## Behavioral Requirements

- **alert-role**: Alert MUST render its root element with
  `role="alert"`.
- **alert-data-slot**: Alert MUST render its root element with
  `data-slot="alert"`.
- **default-variant**: Alert MUST apply the `default`
  variant's styling when no `variant` prop is supplied.
- **five-variants**: Alert MUST support exactly five `variant`
  values: `default`, `info`, `success`, `error`, `accent`.
- **merge-classname-alert**: Alert MUST merge a caller-supplied
  `className` with the selected variant's base classes rather than
  replacing them.
- **forward-div-props-alert**: Alert MUST forward all received props
  other than `variant` to its root `<div>`; `className` is not passed
  through unchanged — it is merged with the variant's base classes (see
  **merge-classname-alert**) rather than dropped.
- **widen-grid-when-icon-present**: When Alert has a direct `<svg>`
  child, Alert MUST change its grid-template-columns from `0 1fr` to
  `1.25rem 1fr` and MUST add a column gap between them.
- **size-icon-child**: Alert MUST render any direct `<svg>` child at a
  fixed size of `1rem` × `1rem` and MUST offset it `0.125rem` downward from
  its row's top edge.
- **place-title-column-two**: AlertTitle MUST render in the grid's
  second column (`col-start-2`).
- **style-title-medium-weight**: AlertTitle MUST render its text with
  medium font weight.
- **merge-classname-title**: AlertTitle MUST merge a
  caller-supplied `className` with its base classes rather than replacing
  them.
- **forward-div-props-title**: AlertTitle MUST forward all received
  props other than `className` to its root `<div>`; `className` is not
  passed through unchanged — it is merged with the base classes (see
  **merge-classname-title**) rather than dropped.
- **place-description-column-two**: AlertDescription MUST render in
  the grid's second column (`col-start-2`).
- **style-description-small-muted**: AlertDescription MUST render its
  text at the `text-sm` size in the muted text color.
- **merge-classname-description**: AlertDescription MUST merge
  a caller-supplied `className` with its base classes rather than
  replacing them.
- **forward-div-props-description**: AlertDescription MUST forward
  all received props other than `className` to its root `<div>`;
  `className` is not passed through unchanged — it is merged with the base
  classes (see **merge-classname-description**) rather than dropped.
- **export-alert-variants**: The module MUST export `alertVariants` as
  a function usable independently of the `Alert` component.
- **compose-title-and-description-as-children**: Alert SHOULD be
  composed with `AlertTitle` and/or `AlertDescription` as children so their
  content aligns in the shared second grid column alongside an optional
  icon (see Design Decisions for rationale and the conditions under which a
  caller may deviate).
- **render-without-icon-title-or-description**: Alert MAY be rendered
  with no icon, no `AlertTitle`, and no `AlertDescription`; the root
  element places no constraint on child type or count.
- **accept-any-icon-element**: Alert MAY receive any element that
  renders as a literal `<svg>` tag as a leading child to trigger the
  icon-aware grid/sizing behavior; see Design Decisions > Icon detection via
  CSS `:has()`, not an icon prop, for the mechanism and rationale.

## Appearance

- **Corner radius**: `rounded-lg` (design-token corner radius; exact px
  value comes from the project's Tailwind theme, which is not part of this
  source file).
- **Padding**: `py-3 px-4` — 0.75rem vertical × 1rem horizontal.
- **Font**: Alert body text `text-sm` (0.875rem); `AlertTitle` adds
  `font-medium`; `AlertDescription` is also `text-sm`.
- **Background**: variant-dependent — `bg-apt-surface` (default),
  `bg-apt-blue/10` (info), `bg-apt-green/10` (success), `bg-apt-red/10`
  (error), `bg-apt-gold/10` (accent). Resolved colors are defined by the
  `apt-*` design tokens, not by this source file.
- **Foreground/Text**: `text-apt-text` for every variant (the text color
  class does not change per variant); `AlertDescription` specifically uses
  `text-apt-text-muted`. The icon color does vary per variant (see Border,
  below).
- **Border**: `border` (1px, Tailwind's default border width), color
  variant-dependent — `border-apt-border` (default), `border-apt-blue/40`
  (info), `border-apt-green/40` (success), `border-apt-red/40` (error),
  `border-apt-gold/40` (accent). The same color token also tints the
  variant's icon (`[&>svg]:text-apt-*`), except `default`, whose icon uses
  `text-apt-text-muted` instead of a status color.
- **Shadow**: None. No `shadow-*` class appears in `alertVariants`.
- **Min/Max size**: `w-full` (100% of container width); no explicit
  min/max height or width beyond that.
- **Layout**: `grid`, `items-start`, `gap-y-0.5` (0.125rem) between grid
  rows; `grid-cols-[0_1fr]` by default, widening to
  `grid-cols-[1.25rem_1fr]` with `gap-x-3` (0.75rem) when a direct `<svg>`
  child is present (`has-[>svg]:...`).

## States

| State | Appearance change |
|-------|------------------|
| Default | The variant's static appearance (see Appearance). This is the component's only state. |

Not applicable: Alert is a static, non-interactive presentational component; pressed, disabled, focused, and loading states do not apply.

## Accessibility

- Role/trait: `role="alert"` on the root element, for every variant.
  `AlertTitle` and `AlertDescription` carry no ARIA role of their own — they
  are plain `<div>`s identified only by their `data-slot` attribute.
- Label requirements: Not applicable: AlertTitle and AlertDescription are unstyled, positioned grid cells; callers provide content and manage any labeling strategy independently.
- Announce state changes: `role="alert"` makes the root an implicit ARIA
  live region (assertive, atomic, per the ARIA specification), so
  assistive technology announces the element's text content when it is
  inserted into the DOM or when that content changes. `alert.tsx` adds no
  further state-change handling beyond this native role behavior (no
  `aria-live` override, no imperative announce call).
- Minimum tap target: Not applicable: Alert is a non-interactive presentational container with no interactive controls or tap targets of its own.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| alert-001 | alert-role | `<Alert>Text</Alert>` | Rendered root node has attribute `role="alert"`. |
| alert-002 | alert-data-slot | `<Alert>Text</Alert>` | Rendered root node has attribute `data-slot="alert"`. |
| alert-003 | default-variant | `<Alert>Text</Alert>` (no `variant` prop) | Root node's border color resolves to the `apt-border` token and its background resolves to the `apt-surface` token — the `default` variant's tone (see Appearance for the token mapping). |
| alert-004 | five-variants | Render with `variant` set to each of `default`, `info`, `success`, `error`, `accent` in turn | Each render succeeds; the root node's border and background color tokens match the rendered variant's documented tone (see Appearance for the full `variant` → token mapping). |
| alert-005 | merge-classname-alert | `<Alert className="custom">Text</Alert>` | Root node's rendered styling includes both the caller-supplied custom class and the variant's base visual styling (corner radius, border, background) — the custom addition is combined with, not a replacement for, the base styling. |
| alert-006 | forward-div-props-alert | `<Alert id="my-alert" data-testid="my-alert">Text</Alert>` | Root node has attributes `id="my-alert"` and `data-testid="my-alert"`. |
| alert-007 | widen-grid-when-icon-present | `<Alert><svg data-testid="icon" />Text</Alert>` | Root node's computed `grid-template-columns` is `1.25rem 1fr` (widened from the no-icon baseline), with a column gap applied between the two columns. Requires a real browser or Playwright — computed `grid-template-columns` cannot be resolved from utility classes in jsdom. |
| alert-008 | size-icon-child | `<Alert><svg data-testid="icon" /></Alert>` | The rendered direct `<svg>` child has a computed width and height of `1rem` (16px) each, and is offset `0.125rem` downward from its row's top edge via a vertical translate. Requires a real browser or Playwright — these are resolved computed styles, not class-list membership. |
| alert-009 | place-title-column-two | `<AlertTitle>Title</AlertTitle>` | Rendered node's computed `grid-column-start` is `2`. |
| alert-010 | style-title-medium-weight | `<AlertTitle>Title</AlertTitle>` | Rendered node's computed `font-weight` is medium (500). |
| alert-011 | merge-classname-title | `<AlertTitle className="custom">Title</AlertTitle>` | Rendered node's styling includes both the caller-supplied custom class and its base grid placement (`grid-column-start: 2`) — combined, not replaced. |
| alert-012 | forward-div-props-title | `<AlertTitle id="t1">Title</AlertTitle>` | Rendered node has attribute `id="t1"`. |
| alert-013 | place-description-column-two | `<AlertDescription>Desc</AlertDescription>` | Rendered node's computed `grid-column-start` is `2`. |
| alert-014 | style-description-small-muted | `<AlertDescription>Desc</AlertDescription>` | Rendered node's text renders at the `text-sm` size token (0.875rem) in the muted text color token (`apt-text-muted`). |
| alert-015 | merge-classname-description | `<AlertDescription className="custom">Desc</AlertDescription>` | Rendered node's styling includes both the caller-supplied custom class and its base grid placement (`grid-column-start: 2`) — combined, not replaced. |
| alert-016 | forward-div-props-description | `<AlertDescription id="d1">Desc</AlertDescription>` | Rendered node has attribute `id="d1"`. |
| alert-017 | export-alert-variants | Import `alertVariants` and call `alertVariants({ variant: "success" })` without rendering `<Alert>` | Returns a class string whose resolved styling includes the `success` variant's border and background color tokens (`apt-green`), independent of any rendered `<Alert>` element. |
| alert-018 | compose-title-and-description-as-children | `<Alert><AlertTitle>T</AlertTitle><AlertDescription>D</AlertDescription></Alert>` | Both children render inside the same root grid container, each with computed `grid-column-start: 2`; the root's computed `row-gap` is `0.125rem` (`gap-y-0.5`), producing visible stacking between them. |
| alert-019 | Edge case: attribute-override quirk | `<Alert role="status" data-slot="banner">Text</Alert>` | Root node's `role` attribute resolves to `"status"` and `data-slot` resolves to `"banner"` — the caller's explicit props silently override the component's own `role="alert"` / `data-slot="alert"` defaults (see Edge Cases). |
| alert-020 | widen-grid-when-icon-present | `<Alert>Text</Alert>` (no `<svg>` child) | Root node's computed `grid-template-columns` is `0px 1fr` — the no-icon baseline — and no column gap is applied. Requires a real browser or Playwright. |
| alert-021 | Edge case: boundary values | `alertVariants({ variant: "bogus" as any })` (bypassing the `VariantProps` type) | Returns only the shared base classes (layout, padding, corner radius, text size); no variant-specific border, background, foreground, or icon-color classes are included, and it does not fall back to the `default` variant's tone (see Edge Cases). |

## Edge Cases

- **Null and empty input**: `<Alert />` with no children MUST render an
  empty, bordered/padded `<div role="alert">` without throwing — `children`
  is not required by `React.ComponentProps<"div">`. `variant={undefined}`
  MUST behave identically to omitting the prop (falls back to `default`
  per **default-variant**).
- **Boundary values**: A `variant` value outside the five accepted
  literals (only reachable by bypassing the `VariantProps` TypeScript
  type, e.g. from untyped/unchecked data): `class-variance-authority`'s
  lookup finds no match for an unrecognized key, so it omits that
  variant's entire class string — border, background, foreground, and
  icon-color classes all drop out together — while the shared base classes
  (layout, padding, corner radius, text size) still apply. It does NOT
  fall back to the `default` variant's classes: `defaultVariants: {
  variant: "default" }` only substitutes when `variant` is omitted or
  `undefined`, not when it is set to an invalid value. See
  #test-vectors/alert-021.
- **Concurrent access**: Not applicable. `Alert`, `AlertTitle`, and
  `AlertDescription` are stateless, side-effect-free function components
  with no internal state, refs, or shared mutable resources.
- **Error states**: Alert performs no fallible operation (no network
  call, no parsing, no file/database I/O) and contains no `try`/`catch` or
  error-boundary logic. Any rendering failure surfaces as a standard React
  rendering error, not Alert-specific behavior.
- **Offline or disconnected state**: Not applicable. Alert performs no
  network communication.
- **Attribute-override quirk**: If a caller explicitly passes a `role` or
  `data-slot` prop, that value overrides the component's own
  `role="alert"` / `data-slot="alert"` attributes, because `{...props}` is
  spread in JSX after those two attributes on the root `<div>` — JSX's
  last-attribute-wins rule applies, so the default can be silently
  replaced. See #test-vectors/alert-019.
- **Icon detection is structural, not type-based**: See Design Decisions
  > Icon detection via CSS `:has()`, not an icon prop.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `variant` | enum: `default` \| `info` \| `success` \| `error` \| `accent` | `default` | Selects the tone (border/background/icon color) of the alert. |
| `className` | `string` | none | Additional classes merged with the component's computed classes. Available on `Alert`, `AlertTitle`, and `AlertDescription` independently. |
| `...props` | `React.ComponentProps<"div">` | none | Any other native `<div>` attribute or event handler; forwarded to the root element of `Alert`, `AlertTitle`, or `AlertDescription`. |

## Deep Linking

Not applicable: Alert is a non-navigable presentational primitive with no routing or deep-linking capability.

## Localization

Alert defines no string constants of its own. All text content (title,
description, and any other content) is supplied by the caller as children;
there are no localization keys owned by this component.

## Accessibility Options

Not applicable: Alert is a static presentation component with no animations or responsive feature-toggle behavior; accessibility display options do not affect its appearance.

## Feature Flags

Not applicable: Alert.tsx contains no feature-flag or conditional-rendering logic.

## Analytics

Not applicable: Alert is a non-interactive presentational component with no analytics instrumentation in the source.

## Privacy

- **Data collected**: None. The component contains no data collection,
  storage, or transmission logic.
- **Storage**: None. No storage mechanism is present in the source.
- **Transmission**: None. No network or data-transmission logic is
  present in the source.
- **Retention**: Not applicable. No data is collected or retained.

## Logging

Not applicable: Alert.tsx contains no logging or console calls.

## Platform Notes

- **SwiftUI**: Use a `VStack` or custom container to compose the alert. Apply borders and background colors using `.border()` and `.background()` modifiers. SwiftUI has no built-in "alert" `AccessibilityRole`/trait for a static live-region view — combine the icon/title/description into one element with `.accessibilityElement(children: .combine)`, and post an `AccessibilityNotification.Announcement` when the view appears to mirror `role="alert"`'s implicit live-region announcement.
- **Compose**: Use a `Box` or `Surface` composable for the container with `.border()` and `.background()` modifiers for styling. Stack title and description content vertically inside. Compose's `Role` semantics class has no `Alert` value (only `Button`, `Checkbox`, `Switch`, `RadioButton`, `Tab`, `Image`, `DropdownList`); apply `Modifier.semantics { liveRegion = LiveRegionMode.Assertive }` instead — Compose's equivalent of an assertive ARIA live region.
- **React/Web**: Implemented as a behavioral contract with `packages/web/packages/ui/src/components/alert.tsx` as the reference implementation: a `<div>` styled with Tailwind utility classes composed via `class-variance-authority` (`cva`), a CSS grid layout that widens via a `:has(>svg)` selector when an icon is present, and `default` as the `cva` `defaultVariants` value. `AlertTitle`/`AlertDescription` are separate `<div>`s placed in the grid's second column. The test vectors above assert platform-neutral tokens and computed styles; on this implementation those resolve to: `default`/`info`/`success`/`error`/`accent` border+background+icon-color → `border-apt-border bg-apt-surface [&>svg]:text-apt-text-muted`, `border-apt-blue/40 bg-apt-blue/10 [&>svg]:text-apt-blue`, `border-apt-green/40 bg-apt-green/10 [&>svg]:text-apt-green`, `border-apt-red/40 bg-apt-red/10 [&>svg]:text-apt-red`, `border-apt-gold/40 bg-apt-gold/10 [&>svg]:text-apt-gold` respectively; corner radius → `rounded-lg`; grid placement → `col-start-2`; title weight → `font-medium`; description size/color → `text-sm text-apt-text-muted`; icon-aware grid/gap → `has-[>svg]:grid-cols-[1.25rem_1fr] has-[>svg]:gap-x-3` (no-icon baseline `grid-cols-[0_1fr]`); icon sizing/offset → `[&>svg]:size-4 [&>svg]:translate-y-0.5`; row spacing → `gap-y-0.5`.
- **AppKit / UIKit**: Use a custom `NSView` (macOS) or `UIView` (iOS) subclass or a `NSStackView`/`UIStackView` for layout. Apply a border via `layer.borderWidth` and `layer.borderColor`. Neither `NSAccessibility.Role` (AppKit) nor `UIAccessibilityTraits` (UIKit) defines an "alert" role/trait; compose title/description views vertically, and, to mirror `role="alert"`'s announcement behavior, post `NSAccessibility.post(element:, notification:, userInfo:)` with `.announcementRequested` (AppKit) or call `UIAccessibility.post(notification: .announcement, argument:)` (UIKit) when the alert appears. No native inline-alert control exists; `NSAlert` is modal-only.
- **WinUI 3**: Fluent 2's `InfoBar` control is the closest conformant starting point — it is the built-in inline, non-modal notification control, with a `Severity` property (`Informational`/`Success`/`Warning`/`Error`) that drives its icon and tint, plus built-in `Title` and `Message` properties occupying roughly the role of `AlertTitle`/`AlertDescription`. This differs from the source in three ways: (1) `InfoBar` ships a built-in close button (`IsClosable`) and open/close state, while the web `Alert` is always-visible with no dismiss affordance at all; (2) `InfoBar`'s four `Severity` values map onto `info`/`success`/`error`, but there is no `Severity` equivalent for the source's `default` (neutral) or `accent` (gold) variants — those two would need a custom `Style` rather than a built-in `Severity`; (3) the source's icon-aware grid reflow (present only when a caller supplies an `<svg>` child) has no equivalent in `InfoBar`, which always reserves icon space based on `Severity`/`IconSource`, not on child presence.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/alert.tsx` | unverified |

## Design Decisions

**Decision**: Detect and react to a leading icon structurally, via a CSS
`:has(>svg)` selector, rather than through a dedicated `icon` prop.
**Rationale**: `alert.tsx` has no icon prop; its icon-aware grid widening
and icon sizing are driven entirely by a `has-[>svg]` selector matching any
direct `<svg>` child. This is why `AlertTitle`/`AlertDescription` are plain
`col-start-2` siblings rather than named slots — the whole layout is
structural (presence/absence of an `<svg>` child), not prop-driven. See
#requirements/accept-any-icon-element and Edge Cases > Icon detection is
structural, not type-based.
**Approved**: pending

**Decision**: Differentiate the five variants by border/background/icon
tone color alone, with no secondary non-color cue.
**Rationale**: Across `default`/`info`/`success`/`error`/`accent`, the
source's only differentiator besides an optional caller-supplied icon is
the border/background/icon tone color; the body text color
(`text-apt-text`) is identical for every variant. An icon-less alert
therefore communicates its severity through color alone.
**Approved**: pending

**Decision**: Record the attribute-override quirk as documented behavior
rather than fixing it.
**Rationale**: Because `{...props}` is spread after `role`/`data-slot` in
the root `<div>`'s JSX (see Edge Cases), a caller can silently override
either attribute. This ingredient documents the source's actual behavior
rather than the behavior a defensive implementation would have.
**Approved**: pending

**Decision**: Recommend, but do not enforce, composing `Alert` with
`AlertTitle`/`AlertDescription` rather than arbitrary children.
**Rationale**: `AlertTitle`/`AlertDescription` exist solely to place text
in the grid's second column alongside an optional icon; using them is not
enforced — `Alert` accepts arbitrary children — but a caller who deviates
(e.g. a raw `<p>` instead of `AlertDescription`) must add `col-start-2`
manually to stay aligned with an icon, since `Alert` itself applies no
column placement to unrecognized children. See
#requirements/compose-title-and-description-as-children.
**Approved**: pending

**Decision**: Treat this `Alert` (the inline, non-modal callout from
`alert.tsx`) and the `alert-and-dialog` recipe's modal confirm-dialog as
unrelated implementations despite the shared name.
**Rationale**: This cookbook also contains an `alert-and-dialog` recipe
describing a *different*, modal confirm-dialog component that happens to
share the word "Alert." The `Alert` documented here is the inline,
non-modal callout from `alert.tsx`; the two are unrelated implementations
(see `related` in the frontmatter).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

These statuses rest on `alert.tsx`'s explicit `role="alert"`/`data-slot="alert"` markup and its complete absence of any hardcoded, non-caller-supplied user-facing string (grounds for the `passed` marks); the resolved contrast and rem-scaling values depend on the `apt-*` design tokens and Tailwind theme, which are not defined in this source file (grounds for the `partial` marks). Best-practices statuses rest on `alert.tsx` being pure presentation over `cva` variants with no embedded logic (separation-of-concerns: passed), and on no test in the suite exercising `Alert`/`AlertTitle`/`AlertDescription` directly — the candidate tests exercise unrelated components (unit-test-coverage: failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: dropped RFC-2119 prefixes from requirement names; rewrote test-vector assertions as platform-neutral observable behavior/tokens and moved literal Tailwind classes into the React/Web platform note; reworded the forward-div-props-* requirements to reflect that className is merged rather than dropped; added boundary-value, attribute-override-quirk, and no-icon-baseline test vectors; corrected the boundary-value edge case to state cva's single actual outcome; fixed the alert-018 gap-y-0.5 assertion to target the root node; corrected the SwiftUI/Compose/AppKit-UIKit platform notes' accessibility API citations; collapsed duplicate icon-detection prose into cross-references to Design Decisions; reformatted Design Decisions into the three-line Decision/Rationale/Approved form; replaced the empty Localization table with its sentence; added the alert-and-dialog domain to related; replaced "This recipe" with "ingredient"; and replaced the Compliance section's "Not applicable" with an evaluated checks table |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
