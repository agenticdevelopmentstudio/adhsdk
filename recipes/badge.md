---
id: 245c45fe-4724-4a8c-bfef-0049e09c18e1
title: Badge
domain: adhsdk://recipes/badge
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'Small pill-shaped status/tone label rendered as a span with six color variants:
  neutral, accent, orange, blue, success, error.'
platforms:
- typescript
- web
tags:
- ui
- badge
- status-indicator
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Badge

## Overview

Badge is a small, non-interactive status/tone label rendered as an inline
`<span>`. Per the source comment, it is "a 1:1 match of the deployed header
badge (`.adh-header__badge`)": a pill-shaped, mono-spaced, uppercase chip
with a 1px border, sized to sit inline with surrounding text or controls.
Callers select one of six variants named for their tone color. Two of those
names, `success` and `error`, read as status semantics, but `badge.tsx`
attaches no pass/fail meaning to them beyond the tone itself — any semantic
meaning is the caller's convention, and color is the only signal Badge
provides for it (see Design Decisions and Accessibility Options).

## Behavioral Requirements

- **render-as-span**: Badge MUST render its root element as a `<span>`.
- **set-data-slot-attribute**: Badge MUST set a `data-slot` attribute
  with the value `"badge"` on its root element.
- **support-six-variants**: Badge MUST support exactly six `variant`
  values: `neutral`, `accent`, `orange`, `blue`, `success`, `error`.
- **default-neutral-variant**: Badge MUST use the `neutral` variant
  when no `variant` prop is supplied.
- **apply-no-tone-classes-on-unrecognized-variant**: Badge MUST apply no
  tone (border/text color) classes when `variant` is set to a value outside
  the six accepted literals (reachable only by bypassing the
  `VariantProps` TypeScript type). This is the `class-variance-authority`
  library's documented behavior: `defaultVariants` resolves an `undefined`
  prop, not an invalid one, so an unmatched variant key falls through with
  no tone classes applied.
- **render-pill-shape**: Badge MUST render with fully rounded
  (pill-shaped) corners.
- **render-transparent-background**: Badge MUST render with a
  transparent background.
- **render-bordered**: Badge MUST render with a visible border on all
  sides.
- **share-tone-color-between-border-and-text**: For the `accent`,
  `orange`, `blue`, `success`, and `error` variants, Badge MUST render its
  border color and its text color using the same tone color. The default
  `neutral` variant is an exception in the source: its border and text
  colors resolve from two different tokens (see Appearance and Edge Cases).
- **uppercase-text**: Badge MUST render its text content transformed to
  uppercase.
- **prevent-text-wrapping**: Badge MUST prevent its content from
  wrapping onto multiple lines.
- **apply-inline-child-spacing**: Badge MUST apply a fixed gap between
  its inline children (e.g., an icon and a label).
- **size-nested-icons**: Badge MUST render any nested SVG element at a
  fixed size and MUST prevent that SVG from shrinking below that size.
- **forward-span-props**: Badge MUST forward all props other than
  `className` and `variant` to the underlying `<span>` element.
- **merge-caller-classname**: Badge MUST merge a caller-supplied
  `className` with its own computed classes rather than replacing them.
- **render-without-children**: Badge MAY be rendered with no children.
- **include-icon-content**: Badge MAY contain an icon (SVG) alongside or
  instead of text content.

## Appearance

- **Corner radius**: Fully rounded (pill) — `rounded-full`.
- **Padding**: 0.15rem vertical × 0.45rem horizontal (`py-[0.15rem]
  px-[0.45rem]`).
- **Font**: Monospace family, weight 500 (medium), size 0.6rem, line-height
  1.4, letter-spacing 0.08em, text transformed to uppercase.
- **Background**: Transparent.
- **Foreground/Text**: Variant tone color (see table below).
- **Border**: 1px (default border width), color equal to the variant's tone
  color for `accent`, `orange`, `blue`, `success`, and `error`. For the
  default `neutral` variant the border color (`apt-border`) differs from the
  text color (`apt-text-dim`) — see the tone-color table below and Edge
  Cases.
- **Shadow**: None. No shadow classes are applied by the source.
- **Min/Max size**: None specified. The component is `inline-flex` with no
  explicit width or height constraints; it sizes to its content.
- **Layout**: `inline-flex`, children vertically centered
  (`items-center`), 0.25rem gap between children (`gap-1`), content does not
  wrap (`whitespace-nowrap`).
- **Nested icon sizing**: Any descendant `<svg>` is rendered at 0.75rem
  (`size-3`) and does not shrink (`shrink-0`).

**Variant tone colors:**

| Variant | Border / text color token |
|---------|---------------------------|
| `neutral` (default) | `apt-border` (border) / `apt-text-dim` (text) |
| `accent` | `apt-gold` |
| `orange` | `apt-orange` |
| `blue` | `apt-blue` |
| `success` | `apt-green` |
| `error` | `apt-red` |

## States

Not applicable: Badge is a static, non-interactive presentational component
with no pressed, disabled, focused, or loading states.

## Accessibility

Not applicable: Badge is a static, non-interactive presentational component
rendered as a `<span>`. It carries no semantic content beyond what the caller
provides as text children; accessibility requirements (keyboard navigation,
screen reader announcements, focus states) apply only when Badge wraps
interactive content supplied by its caller. Color-perception concerns for the
tone variants themselves are covered under Accessibility Options below.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| badge-001 | render-as-span | `<Badge>Text</Badge>` | Rendered root DOM node's tag name is `span`. |
| badge-002 | set-data-slot-attribute | `<Badge>Text</Badge>` | Rendered root node has attribute `data-slot="badge"`. |
| badge-003 | support-six-variants | `<Badge variant="neutral">Text</Badge>` | Computed border color and computed text color are DIFFERENT: border matches `apt-border`, text matches `apt-text-dim` (the `neutral` variant does not share a tone color between them; see Edge Cases). Web implementation note: classes `border-apt-border text-apt-text-dim`. |
| badge-004 | support-six-variants | `<Badge variant="accent">Text</Badge>` | Computed border color and computed text color are equal and match the `accent` tone token. Web implementation note: classes `border-apt-gold text-apt-gold`. |
| badge-005 | support-six-variants | `<Badge variant="orange">Text</Badge>` | Computed border color and computed text color are equal and match the `orange` tone token. Web implementation note: classes `border-apt-orange text-apt-orange`. |
| badge-006 | support-six-variants | `<Badge variant="blue">Text</Badge>` | Computed border color and computed text color are equal and match the `blue` tone token. Web implementation note: classes `border-apt-blue text-apt-blue`. |
| badge-007 | support-six-variants | `<Badge variant="success">Text</Badge>` | Computed border color and computed text color are equal and match the `success` tone token. Web implementation note: classes `border-apt-green text-apt-green`. |
| badge-008 | support-six-variants, share-tone-color-between-border-and-text | `<Badge variant="error">Text</Badge>` | Computed border color and computed text color are equal and match the `error` tone token. Web implementation note: classes `border-apt-red text-apt-red`. |
| badge-009 | default-neutral-variant | `<Badge>Text</Badge>` (no `variant` prop) | Computed border color matches `apt-border` and computed text color matches `apt-text-dim`, identical to explicitly passing `variant="neutral"` (badge-003); border and text do NOT match each other here. Web implementation note: classes `border-apt-border text-apt-text-dim`. |
| badge-010 | apply-no-tone-classes-on-unrecognized-variant | `<Badge variant={"bogus" as any}>Text</Badge>` | Rendered root node has no computed border or text tone color applied beyond the browser/user-agent default (no tone classes or styles are present). |
| badge-011 | render-pill-shape | `<Badge>Text</Badge>` | Computed `border-radius` is at least half the rendered element's height (fully rounded). Web implementation note: class `rounded-full`. |
| badge-012 | render-transparent-background | `<Badge>Text</Badge>` | Computed `background-color` is transparent (`transparent` or `rgba(0,0,0,0)`). Web implementation note: class `bg-transparent`. |
| badge-013 | render-bordered | `<Badge>Text</Badge>` | Computed border width is greater than `0` on all four sides. Web implementation note: class `border`. |
| badge-014 | uppercase-text | `<Badge>text</Badge>` | Rendered text is presented in uppercase (computed `text-transform: uppercase`, or, where no casing style exists, the displayed string equals the locale-aware uppercase transform of the input). Web implementation note: class `uppercase`. |
| badge-015 | prevent-text-wrapping | `<Badge>A very long label</Badge>` | Content stays on a single line (computed `white-space: nowrap`). Web implementation note: class `whitespace-nowrap`. |
| badge-016 | apply-inline-child-spacing | `<Badge><svg data-testid="icon" />Label</Badge>` | Computed gap between the icon and label is a fixed, non-zero value (0.25rem in the reference implementation). Web implementation note: class `gap-1`. |
| badge-017 | size-nested-icons | `<Badge><svg data-testid="icon" /></Badge>` | Rendered `<svg>` element's computed width and height equal a fixed size (0.75rem/12px in the reference implementation) and do not shrink below that size when the flex container compresses. Web implementation note: classes `size-3 shrink-0`. |
| badge-018 | forward-span-props | `<Badge id="my-badge" title="tip">Text</Badge>` | Rendered root node has attributes `id="my-badge"` and `title="tip"`. |
| badge-019 | merge-caller-classname | `<Badge className="custom-class">Text</Badge>` | Rendered root node's class list includes both `custom-class` and the component's own pill-shape class (e.g. `rounded-full`) — neither replaces the other. |
| badge-020 | render-without-children | `<Badge />` | Renders an empty `<span>` with `data-slot="badge"` and no children, without throwing. |
| badge-021 | include-icon-content | `<Badge><svg data-testid="icon" />Label</Badge>` | Renders both the `<svg>` icon and the `Label` text as children of the root `<span>`, sized/spaced per badge-016 and badge-017. |

## Edge Cases

- **Null and empty input**: `<Badge />` with no children MUST render an
  empty `<span>` without throwing (see **render-without-children**); the
  source performs no required-children validation. Passing
  `variant={undefined}` MUST behave identically to omitting the prop (falls
  back to `neutral` per **default-neutral-variant**).
- **Boundary values**: A `variant` value outside the six accepted literals
  (only reachable by bypassing the `VariantProps` TypeScript type, e.g. from
  untyped/unchecked data) is resolved by the `class-variance-authority`
  library, whose implementation is not part of `badge.tsx`. Passing an
  unrecognized variant key results in no variant classes being applied to
  the root element (see **apply-no-tone-classes-on-unrecognized-variant**).
- **Concurrent access**: Not applicable. Badge is a stateless,
  side-effect-free presentational function component with no internal
  state, refs, or shared mutable resources.
- **Error states**: Badge performs no fallible operations (no network
  calls, no parsing, no file/database I/O) and contains no `try`/`catch` or
  error-boundary logic. Any rendering failure would surface as a standard
  React rendering error, not Badge-specific behavior.
- **Offline or disconnected state**: Not applicable. Badge performs no
  network communication.
- **`neutral` variant's border/text token mismatch**: For five of the six
  variants (`accent`, `orange`, `blue`, `success`, `error`), the source's
  `cva` variant table pairs the border and text class with the same tone
  token (e.g. `border-apt-gold text-apt-gold`). The default `neutral`
  variant does not: it pairs `border-apt-border` with `text-apt-text-dim`,
  two different design tokens that resolve to different computed colors in
  every shipped theme (see badge-003/badge-009). This is logged as a
  source inconsistency, not a documented design choice.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `variant` | enum: `neutral` \| `accent` \| `orange` \| `blue` \| `success` \| `error` | `neutral` | Selects the tone (border/text color) of the badge. |
| `className` | `string` | none | Additional CSS classes merged with the component's computed classes. |
| `...props` | `React.ComponentProps<"span">` | none | Any other native `<span>` attribute or event handler; forwarded to the root element. |

## Deep Linking

Not applicable: Badge is a non-navigable presentational primitive with no
routing or deep-link logic.

## Localization

Badge defines no string constants of its own. All text content is supplied
by the caller as `children`; there are no localization keys owned by this
component. Badge does, however, impose a visual uppercase transform on that
caller-supplied text (see **uppercase-text**). On the web this is a CSS
`text-transform: uppercase`, a display-only transform that does not mutate
the underlying string or run any locale-sensitive case-folding. On a
platform port that instead uppercases the string itself, that transform is
locale-sensitive (e.g. Turkish `i`/`İ` casing) and MUST use the current
user/system locale rather than an invariant or ordinal casing call — see the
corrected WinUI 3 and AppKit/UIKit guidance in Platform Notes.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — Badge has no animations or motion effects. |
| Increase Contrast | Not applicable — Badge renders fixed tone colors from the design system; it provides no separate high-contrast variant of its own. |
| Differentiate Without Color | Gap: Badge communicates variant identity solely through the shared border/text tone color (see Design Decisions); the source provides no icon, pattern, or label difference as a secondary cue. Callers SHOULD supply distinguishing `children` text (e.g. the word "Error") rather than relying on tone alone when the distinction must survive a color-perception limitation. |

## Feature Flags

Not applicable: Badge is a foundational UI primitive with no feature-flag
references in the source.

## Analytics

Not applicable: Badge is a foundational presentational component with no user
interaction or telemetry instrumentation.

## Privacy

Badge collects no data. The component contains no data collection, storage,
transmission, or retention logic. All content and behavior is determined by
the caller's supplied children and props.

## Logging

Not applicable: Badge is a foundational presentational component with no
logging or diagnostic instrumentation.

## Platform Notes

- **SwiftUI**: Start from a `Text` view with `.padding(...)` and an
  `.overlay(RoundedRectangle(cornerRadius: .infinity).strokeBorder(color,
  lineWidth: 1))` (or `.border`) to achieve the pill shape and tone-color
  border, uppercasing the string with a locale-aware call (e.g.
  `text.uppercased(with: Locale.current)`, not the bare `.uppercased()`) per
  Localization before it is passed to `Text`. Represent `variant` as a plain,
  non-`@State` parameter — an enum with the six cases — since Badge holds no
  internal state; apply its tone color via a switch or dictionary lookup on
  `.foregroundColor` and the border stroke color. SwiftUI has no built-in
  `cva`-like composition library, so the variant-to-color mapping must be
  explicit.

- **Compose**: Use a `Surface` composable with `shape =
  RoundedCornerShape(percent = 50)` for the pill outline, `border =
  BorderStroke(1.dp, color)` for the 1px tone-colored border, and `color =
  Color.Transparent` for the transparent background (`Surface` takes
  `color`, not `background`; a plain `Box` would instead use
  `Modifier.background(Color.Transparent)`). Nest a `Text` with `fontFamily =
  FontFamily.Monospace`, `fontSize = 9.6.sp`, `fontWeight =
  FontWeight.Medium`, `letterSpacing = 0.08.em`, and the string uppercased
  before render via a locale-aware call — `text.uppercase(Locale.current)`
  (Compose's `Text` has no `textTransform` parameter). Compose layout
  composables (`Row`, `Box`) provide the spacing and sizing equivalent to the
  web component's inline-flex and gap properties.

- **React/Web**: The contract above — pill shape, transparent background,
  1px border sharing its color with the text for five of the six variants
  (the default `neutral` variant is the exception; see Edge Cases),
  uppercase mono type, no-wrap inline-flex layout, and fixed icon sizing —
  is satisfied by a `<span>`
  styled with Tailwind utility classes composed via `class-variance-authority`
  (`cva`), with `variant` selecting one of six predefined class sets and
  `neutral` as the `cva` `defaultVariants` value. The root element is
  `inline-flex` with `items-center`, `gap-1`, and `whitespace-nowrap` for
  layout; nested SVGs are sized with `[&_svg]:size-3 [&_svg]:shrink-0`.
  `packages/web/packages/ui/src/components/badge.tsx` is the reference
  implementation of this contract.

- **AppKit / UIKit**: Use an `NSStackView` (macOS) or `UIStackView` (iOS) in
  horizontal axis, with `alignment = .center` and `spacing = 4pt` (equivalent
  to the web component's `gap-1`). Set `layer.cornerRadius` to half the frame
  height for the pill shape and `layer.borderWidth = 1`. Nest an
  `NSTextField` or `UILabel` for the text, setting `font =
  .monospacedSystemFont(ofSize: 9.6, weight: .medium)`, and applying a
  locale-aware uppercase transform (`.uppercased(with: Locale.current)`)
  rather than the bare, locale-blind form. Variant selection is a switch on
  a variant property that binds `layer.borderColor` and `textColor`
  separately per variant — the same tone color for `accent`, `orange`,
  `blue`, `success`, and `error`, but two different colors for `neutral`
  (`apt-border` for the border, `apt-text-dim` for the text; see Edge
  Cases) — rather than a single shared `toneColor` for all six.

- **WinUI 3**: No conformant `Badge` control ships in WinUI 3. The closest
  starting point is a `Border` (for the pill shape via `CornerRadius`, 1px
  `BorderBrush`, and transparent `Background`) wrapping a `TextBlock` (for
  the mono, letter-spaced, uppercase label). Unlike the source's
  `cva`-driven variant system, WinUI 3 has no built-in multi-variant style
  composition, so the six tone variants would need a custom `Style` per tone
  (or a converter bound to a `variant` property) rather than a single
  reusable class list. Set `TextBlock.CharacterSpacing` to `80` (equivalent
  to 0.08em) and `TextBlock.Text = text.ToUpper(CultureInfo.CurrentUICulture)`
  — not `ToUpperInvariant()`, which is the wrong call for user-facing text —
  for locale-aware uppercase rendering. Use a `StackPanel` in horizontal
  orientation with `Spacing = 4` to nest an optional icon alongside text.

## Design Decisions

- **Decision**: The `variant` names (`neutral`, `accent`, `orange`, `blue`,
  `success`, `error`) are tone/color names, not semantic status names.
  Although the deployed header this badge matches uses `orange` for
  "Development Preview" and `blue` for "Coming Soon" per the source comment,
  `badge.tsx` itself has no awareness of that mapping, and `success`/`error`
  carry no built-in pass/fail semantics beyond their tone.
  **Rationale**: Keeps the component a reusable, unopinionated presentational
  primitive; any semantic meaning attached to a given tone is the caller's
  convention, not a guarantee of this component.
  **Approved**: pending

- **Decision**: Border color and text color use the same tone token for
  `accent`, `orange`, `blue`, `success`, and `error` (see
  **share-tone-color-between-border-and-text**) — a direct, unconditional
  mapping in the source's `cva` variant table for those five entries, not a
  configurable option. The default `neutral` variant is the exception: its
  `cva` entry pairs `border-apt-border` with `text-apt-text-dim`, two
  different tokens that resolve to different colors in every shipped theme,
  despite the source's own header comment describing "border + text sharing
  the tone colour" for every variant (see Edge Cases; logged as a source
  inconsistency, not treated as a MUST here).
  **Rationale**: Makes five of the six variants read as a single-tone outline
  chip rather than a filled badge; the `neutral` mismatch appears to be an
  authoring oversight rather than an intentional exception.
  **Approved**: pending

- **Decision**: Variant identity is communicated solely through the
  border/text tone color (e.g. `border-apt-gold`/`text-apt-gold` for
  `accent`), with no secondary non-color cue (icon, pattern, or label
  difference) distinguishing one variant from another; "Differentiate
  Without Color" is not addressed by the source.
  **Rationale**: The source is a minimal presentational primitive with no
  room in its markup for a second visual channel; callers that need a
  non-color cue SHOULD supply it via distinguishing `children` text (e.g.
  the word "Error") rather than relying on tone alone.
  **Approved**: pending

- **Decision**: Badge text renders at 0.6rem, below common minimum-legible
  body-text guidance (~0.875rem/14px).
  **Rationale**: Per the source comment, Badge is "a 1:1 match of the
  deployed header badge (`.adh-header__badge`)"; exact visual parity with
  the already-shipped header chip was prioritized over generic
  minimum-type-size guidance for this compact, non-primary-reading status
  chip.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | partial | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`semantic-markup` and `unicode-support` pass because the source renders a
plain `<span>` with no ARIA misuse and passes `children` through unprocessed
with no Unicode-unsafe string operations. `contrast-ratio` and
`dynamic-type-support` are partial because the source fixes tone colors and
a 0.6rem type size (see Design Decisions) but the source alone cannot show
the computed contrast ratio against an arbitrary background or confirm
system font-scaling behavior. `text-expansion-tolerance` is partial because
`whitespace-nowrap` with no max-width means long translated text is never
truncated, but the source also cannot show whether it overflows a
caller-constrained layout. Best-practices statuses rest on `Badge` being
pure presentation over `cva` variants with no embedded logic
(separation-of-concerns: passed), and on no test in the suite exercising
`Badge` directly — the candidate tests exercise unrelated components
(unit-test-coverage: failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | share-tone-color-between-border-and-text, badge-003/badge-009, and the tone Design Decision now scope the MUST to 5 variants; neutral's border/text token mismatch documented as a source bug. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names and updated every citation; added an unrecognized-variant requirement and test vector; replaced the Compliance placeholder with an accessibility/internationalization checks table; split test vectors to assert computed properties (with class names kept as web implementation notes) and added vectors for the two MAY requirements and the unrecognized-variant edge case; corrected the Compose/SwiftUI Platform Notes to real APIs and reformatted Design Decisions into the three-line convention, adding one for the 0.6rem type size; resolved the Accessibility Options contradiction with Design Decisions on color-only differentiation; added a locale-aware casing note to Localization and replaced invariant-culture casing calls in WinUI 3 and AppKit/UIKit guidance; corrected the domain to the ingredients/ui/components path; reworded the React/Web Platform Note as a contract citing the source as reference implementation |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Apply completeness rules; replace over-used review markers with "Not applicable" statements and provide platform translation guidance |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
