---
id: 1c49339e-0b46-449d-86de-eb4a4166d6a5
title: "Badge"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Small uppercase mono status chip: a transparent pill with a 1px border and text sharing one tone color; six variants, neutral by default."
platforms:
  - typescript
  - web
tags:
  - ui
  - badge
  - status
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Badge

## Overview

The shared `Badge` in `@adh-sdk/ui`: a status chip, "a 1:1 match of the deployed header badge (`.adh-header__badge`)" per the source comment. It is a transparent, pill-shaped `span` with a 1px border, set in uppercase mono type, where the border and the text share one tone color. Six tones are offered through a `variant` prop: `neutral`, `accent`, `orange`, `blue`, `success` and `error`. The source comment says the first four mirror the header: neutral, accent, orange for Development Preview and blue for Coming Soon.

The source exports two names: the `Badge` component and `badgeVariants`, the class-variance-authority function that builds its class string, so other elements can borrow the look. `Badge` is a stateless presentational element. It accepts every prop a `span` accepts and spreads them onto the element after its own attributes.

## Behavioral Requirements

- **renders-span**: The component MUST render a `span` element.
- **marks-slot**: The component MUST set `data-slot="badge"` on the rendered element.
- **default-neutral**: With no `variant`, the component MUST apply the `neutral` variant (`border-apt-border text-apt-text-dim`).
- **neutral-tone**: The `neutral` variant MUST use the `apt-border` border color and the `apt-text-dim` text color.
- **accent-tone**: The `accent` variant MUST use `apt-gold` for both border and text.
- **orange-tone**: The `orange` variant MUST use `apt-orange` for both border and text.
- **blue-tone**: The `blue` variant MUST use `apt-blue` for both border and text.
- **success-tone**: The `success` variant MUST use `apt-green` for both border and text.
- **error-tone**: The `error` variant MUST use `apt-red` for both border and text.
- **transparent-fill**: The component MUST have a transparent background in every variant.
- **pill-shape**: The component MUST have fully rounded corners (`rounded-full`).
- **hairline-border**: The component MUST draw a border whose width is the Tailwind `border` default of 1px.
- **uppercase-mono-type**: The component MUST render its text in the mono font family, uppercase, at `0.6rem`, weight 500 (`font-medium`), line height 1.4 and letter spacing `0.08em`.
- **no-wrap**: The component MUST NOT wrap its content onto a second line (`whitespace-nowrap`).
- **inline-flex-layout**: The component MUST lay out as `inline-flex` with items centered and a `gap-1` gap between children.
- **padding**: The component MUST pad its content `0.45rem` horizontally and `0.15rem` vertically.
- **sizes-svg-children**: The component MUST size any descendant `svg` to `size-3` and MUST NOT let it shrink (`shrink-0`).
- **merges-classname**: The component MUST pass `className` into the variant function so a consumer class is merged through `cn()` with the variant classes.
- **spreads-props**: The component MUST spread all remaining `span` props onto the element.
- **exports-variants**: The module MUST export `badgeVariants` alongside `Badge`.

## Appearance

- **Corner radius**: fully rounded (`rounded-full`, a pill).
- **Padding**: `0.15rem` vertical × `0.45rem` horizontal (`py-[0.15rem] px-[0.45rem]`).
- **Font**: mono family, weight 500, `0.6rem`, uppercase, line height 1.4, letter spacing `0.08em`.
- **Background**: transparent (`bg-transparent`).
- **Foreground/Text**: the tone color (see the tone requirements): `apt-text-dim` for `neutral`, otherwise the same `apt-*` color as the border.
- **Border**: 1px, solid by the Tailwind default, in the tone color (`apt-border` for `neutral`).
- **Shadow**: none.
- **Min/Max size**: no constraints; the chip is as wide as its content because it does not wrap. Icons are `size-3` (0.75rem).

Layout is `inline-flex items-center gap-1`.

## States

| State | Appearance change |
|-------|------------------|
| Default | `neutral` variant: `apt-border` border, `apt-text-dim` text |
| Variant `accent` / `orange` / `blue` / `success` / `error` | Border and text both recolor to the tone's `apt-*` color |
| Pressed | Not applicable: Badge is a static `span` with no pressed styling. |
| Disabled | Not applicable: Badge has no disabled styling and is not a control. |
| Focused | Not applicable: Badge is not focusable and has no focus styling. |
| Loading | Not applicable: Badge has no loading styling. |

## Accessibility

- **Role/trait**: none is set; the element is a plain `span`, so it is read as text in the document flow.
- **Label requirements**: the visible children are the accessible content. The component adds no `aria-label`; a consumer MAY pass one, because all `span` props are spread.
- **State announcements**: Not applicable: Badge has no internal state that changes.
- **Tap target**: Not applicable: Badge is not interactive, so the 44×44pt minimum does not apply.
- **Not focusable**: the element has no `tabindex` and no handlers of its own.
- **contrast**: NEEDS REVIEW: Not implemented in source. The `apt-*` tone colors are drawn at 0.6rem on whatever surface the badge sits on, and the source does not state a contrast ratio; measuring each tone token against the surfaces it is used on would settle whether WCAG 2.1 AA (4.5:1) is met.

## Conformance Test Vectors

No test file sits beside `badge.tsx`. The vectors are derived from the source class strings.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| badge-001 | renders-span, marks-slot | render `<Badge>Beta</Badge>` | a `span` with `data-slot="badge"` and text `Beta` |
| badge-002 | default-neutral, neutral-tone | render `<Badge>Beta</Badge>` | class contains `border-apt-border` and `text-apt-text-dim` |
| badge-003 | accent-tone | `variant="accent"` | class contains `border-apt-gold` and `text-apt-gold` |
| badge-004 | orange-tone | `variant="orange"` | class contains `border-apt-orange` and `text-apt-orange` |
| badge-005 | blue-tone | `variant="blue"` | class contains `border-apt-blue` and `text-apt-blue` |
| badge-006 | success-tone | `variant="success"` | class contains `border-apt-green` and `text-apt-green` |
| badge-007 | error-tone | `variant="error"` | class contains `border-apt-red` and `text-apt-red` |
| badge-008 | merges-classname | `className="ml-2"` | class contains `ml-2` and the neutral tone classes |
| badge-009 | spreads-props | `id="b1" title="Preview"` | element has `id="b1"` and `title="Preview"` |
| badge-010 | uppercase-mono-type, no-wrap, pill-shape | any render | class contains `uppercase`, `font-mono`, `whitespace-nowrap`, `rounded-full` |
| badge-011 | sizes-svg-children | child `svg` inside | class contains `[&_svg]:size-3` and `[&_svg]:shrink-0` |
| badge-012 | exports-variants | `badgeVariants({ variant: "error" })` | returns a string containing `border-apt-red` |

## Edge Cases

- **Empty children.** With no children the element still renders as a padded, empty bordered pill.
- **Long text.** Because `whitespace-nowrap` is set, long text does not wrap and can overflow a narrow container; the component sets no `max-width` or truncation.
- **Unknown variant.** `variant` is typed to the six keys. A value outside them (possible from untyped code) matches no variant entry, so the badge gets the base classes and no tone color.
- **Variant `undefined`.** An explicit `undefined` falls back to `neutral` through `defaultVariants`.
- **Consumer overrides.** `className` is passed through `badgeVariants` and then `cn()`, so a consumer class that conflicts with a base class is merged by `cn()` rather than simply appended.
- **Prop order.** `{...props}` is spread after `data-slot` and `className`, so a consumer `data-slot` replaces the default.
- **Icons.** An `svg` child is forced to `size-3` regardless of its own size attributes by the `[&_svg]` selector.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `variant` | `"neutral" \| "accent" \| "orange" \| "blue" \| "success" \| "error"` | `"neutral"` | Selects the tone color applied to border and text. |
| `className` | `string` | none | Extra classes merged with the variant classes. |
| other `span` props | `React.ComponentProps<"span">` | none | Spread onto the rendered `span` (children, id, title, aria attributes, handlers). |

## Deep Linking

Not applicable: Badge is a static `span` with no navigation behavior or URL.

## Localization

Not applicable: Badge renders no strings of its own; the text is the consumer's `children`, and a consumer supplies it already localized. The source applies `uppercase` by CSS only, so the stored text keeps its original case.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Badge has no animation or transition. |
| Increase Contrast | Not applicable: Badge reads no contrast preference; colors come from the `apt-*` tokens. |
| Differentiate Without Color | Not applicable: Badge adds no icon or pattern per tone. The meaning is carried by the consumer's text, and color alone is not guaranteed to carry it. |

## Feature Flags

Not applicable: Badge is a primitive library component; the source contains no flag check, and flagging belongs to consuming applications.

## Analytics

Not applicable: Badge is static, has no handlers and emits no events.

## Privacy

- **Data collected**: None.
- **Storage**: None.
- **Transmission**: None; the component renders consumer text locally.
- **Retention**: Not applicable.

## Logging

Not applicable: Badge has no logic that could fail or branch, and the source logs nothing.

## Platform Notes

- **SwiftUI**: Compose a `Text` with `.textCase(.uppercase)`, `.font(.system(size: 9.6, weight: .medium, design: .monospaced))` and `.tracking(0.08 * 9.6)`, then `.padding(.horizontal, 7).padding(.vertical, 2.4)` and `.overlay(Capsule().stroke(tone, lineWidth: 1))` with `.foregroundStyle(tone)`. Use an `HStack(spacing: 4)` when an icon is present.
- **Compose**: Use a `Surface` or `Box` with `shape = CircleShape` (or `RoundedCornerShape(50)`) and `border = BorderStroke(1.dp, tone)`, `color = Color.Transparent`, holding a `Text` in `FontFamily.Monospace` at 9.6.sp, `FontWeight.Medium`, `letterSpacing = 0.08.em`, with the string uppercased by `.uppercase()`. Material 3 `AssistChip` and `SuggestionChip` are interactive, so start from a plain `Surface` for an inert chip.
- **React/Web**: Source is `packages/web/packages/ui/src/components/badge.tsx`: a function component over `React.ComponentProps<"span">`, with the classes built by `cva` from `class-variance-authority` and merged by `cn()` from `../lib/utils`. Tones come from Tailwind `apt-*` color tokens. There is no `"use client"` directive and no state, so it renders in server components. It sets `data-slot="badge"` for styling hooks.
- **AppKit / UIKit**: There is no native chip view. Use an `NSTextField` (AppKit) or `UILabel` (UIKit) in a view with `layer.cornerRadius` set to half the height, `layer.borderWidth = 1`, `layer.borderColor` from the tone, a transparent background, uppercase text and a monospaced system font with `kern` of `0.08 * fontSize` set through the attributed string. Padding needs a container view or custom drawing; `UILabel` has no padding property.
- **WinUI 3**: Build it from a `Border` with `CornerRadius` set to half the height (for example 9 for an 18px chip), `BorderThickness="1"`, `BorderBrush` bound to a tone `SolidColorBrush`, `Background="Transparent"` and `Padding="7,2.4"`, wrapping a `StackPanel Orientation="Horizontal" Spacing="4"`. Inside, a `TextBlock` with `FontFamily="Consolas"`, `FontSize="9.6"`, `FontWeight="Medium"`, `CharacterSpacing="80"` (thousandths of an em, so 0.08em is 80) and `Foreground` the tone brush; uppercase the text in the view model or a converter because `TextBlock` has no text-case property. Icons go in a `FontIcon` at 12 x 12. A `Border` is not a tab stop, which matches the source. Take tone brushes from `ThemeResource` dictionaries so Light, Dark and HighContrast themes each supply a value. `InfoBadge` is the native badge control, but it is a filled dot or number and does not match this outlined text chip.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/badge.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The chip is transparent with the border and text sharing a single tone color, rather than a filled background.
**Rationale**: The source comment states it is a 1:1 match of the deployed header badge, which is drawn this way.
**Approved**: pending

**Decision**: Badge is a plain `span` with `variant` as its only own prop, and it spreads the remaining `span` props.
**Rationale**: It stays a non-interactive label that consumers can extend with ids, titles and aria attributes without new API.
**Approved**: pending

**Decision**: The module exports `badgeVariants` as well as `Badge`.
**Rationale**: The class builder can then be applied to other elements that need the same look, such as a link styled as a badge.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` passes because the badge is a plain `span` that exposes its text to assistive technology and adds no misleading role. `separation-of-concerns` passes: `Badge` only maps a variant to classes through `cva` and renders a `span`, with class merging delegated to `cn()` from `../lib/utils`. `unit-test-coverage` passes: `badge.test.tsx` covers every vector, badge-001 through badge-012.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (badge.test.tsx, 12 of 12 vectors); unit-test-coverage now passed. |
