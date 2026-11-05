---
id: ea565474-df7a-42bd-9613-5dd0cd861911
title: Card
domain: adhsdk://recipes/card
type: ingredient
version: 1.2.3
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A bordered content container — a composable, slot-based family of six
  components (Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter).
platforms:
- typescript
- web
tags:
- component
- card
- container
- ui
depends-on: []
related:
- agenticdevelopercookbook://guidelines/cookbook/ui/platform-design-languages
- adhsdk://recipes/landing-card
references: []
approved-by: ''
approved-date: ''
---

# Card

## Overview

`Card` groups related content inside a single visually-bounded container.

The UI Card family (`packages/web/packages/ui/src/components/card.tsx`) is a compound, slot-based family of six independently composable components (`Card`, `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`), each a styled `<div>` that forwards `className` and other props. The UI `Card` itself imposes no required child structure — callers assemble whichever slots they need.

## Behavioral Requirements

UI Card family (`packages/web/packages/ui/src/components/card.tsx`):

- **export-six-slot-components**: The UI Card family MUST export exactly six components: `Card`, `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, `CardFooter`.
- **render-div-root**: Each of the six UI Card family components MUST render a `div` as its root element.
- **set-data-slot-attribute**: Each of the six UI Card family components MUST set a `data-slot` attribute on its root element identifying its role (`card`, `card-header`, `card-title`, `card-description`, `card-content`, `card-footer`, respectively).
- **merge-classname-prop**: Each of the six UI Card family components MUST merge a caller-supplied `className` prop with its own default class list via the `cn` utility, rather than discarding either.
- **forward-rest-props**: Each of the six UI Card family components MUST spread all other received props onto its rendered root `div` element.
- **compose-any-slot-subset**: Consumers MAY include any subset and ordering of `CardHeader`, `CardTitle`, `CardDescription`, `CardContent`, and `CardFooter` inside `Card`, since `Card` itself renders only the props (including `children`) it receives, without requiring any specific slot structure.
- **always-renders-default-div**: The UI Card family MUST render its default-classed `<div>` regardless of whether children are supplied, per the unconditional `{...props}`/`children` spread in each component.
- **card-corner-radius**: The `Card` root MUST use the `rounded-xl` Tailwind utility for its corner radius; no sub-slot sets its own corner radius.
- **card-vertical-padding**: The `Card` root MUST use vertical padding `py-6` and sets no horizontal padding of its own.
- **slot-horizontal-padding**: `CardHeader`, `CardContent`, and `CardFooter` MUST each add horizontal padding `px-6`.
- **card-children-gap**: `Card` MUST use `gap-6` between its top-level children.
- **header-children-gap**: `CardHeader` MUST use `gap-1.5` between its own children.
- **title-font-weight**: `CardTitle` MUST use `font-semibold` with `leading-none`.
- **description-font-size**: `CardDescription` MUST use `text-sm`.
- **card-background**: The `Card` root MUST use the `bg-apt-bg` token.
- **card-text-color**: `Card` and `CardTitle` MUST use the `text-apt-text` token.
- **description-text-color**: `CardDescription` MUST use `text-apt-text-muted`.
- **card-border**: The `Card` root MUST use `border` (the Tailwind default 1px width) with the `border-apt-border` color token.
- **card-shadow**: The `Card` root MUST use `shadow-sm`.

## Appearance

The UI Card family expresses appearance by class name rather than by literal value, and the class name is the requirement — it names Tailwind utilities and `apt-*` design tokens inline.

- **Corner radius** (#requirements/card-corner-radius):
  - UI Card family: the `Card` root uses the `rounded-xl` Tailwind utility; no sub-slot sets its own corner radius.
- **Padding** (#requirements/card-vertical-padding, #requirements/slot-horizontal-padding, #requirements/card-children-gap, #requirements/header-children-gap):
  - UI Card family: the `Card` root uses vertical padding `py-6` and sets no horizontal padding of its own; `CardHeader`, `CardContent`, and `CardFooter` each add horizontal padding `px-6`. `Card` uses `gap-6` between its top-level children and `CardHeader` uses `gap-1.5` between its own children.
- **Font** (#requirements/title-font-weight, #requirements/description-font-size):
  - UI Card family: `CardTitle` uses `font-semibold` with `leading-none`; `CardDescription` uses `text-sm`. `Card`, `CardHeader`, `CardContent`, and `CardFooter` set no font utility and inherit from their ancestor. No literal point size appears in the source; the Tailwind scale step is the specification.
- **Background** (#requirements/card-background):
  - UI Card family: the `Card` root uses the `bg-apt-bg` token; no sub-slot sets a background.
- **Foreground/Text** (#requirements/card-text-color, #requirements/description-text-color):
  - UI Card family: `Card` and `CardTitle` use the `text-apt-text` token; `CardDescription` uses `text-apt-text-muted`. `CardHeader`, `CardContent`, and `CardFooter` set no text color and inherit `text-apt-text` from the `Card` root.
- **Border** (#requirements/card-border):
  - UI Card family: the `Card` root uses `border` (the Tailwind default 1px width) with the `border-apt-border` color token; no sub-slot has its own border.
- **Shadow** (#requirements/card-shadow):
  - UI Card family: the `Card` root uses `shadow-sm`; no sub-slot has its own shadow.
- **Min/Max size**: The UI Card family does not constrain width or height: the `Card` sets no sizing utility, so it fills the inline size its parent gives it and sizes to its content in the block direction.

## States

Not applicable: Card is a static, non-interactive container and does not define any interactive states beyond the default render state.

## Accessibility

- **Role/trait**: The UI Card family sets no explicit ARIA `role`. It renders a plain `<div>` (`<div data-slot="card" ...>`), which carries no implicit interactive role — it is a generic, non-interactive container.
- **Label requirements**: The UI Card family's `CardTitle` renders a plain `<div data-slot="card-title">` with no heading semantics, and the source sets no `aria-labelledby`, `aria-label`, or a grouping role on the container. The family exposes neither a heading role nor an accessible name or labelled group for its title text; any heading or label association is left entirely to the caller to add.
- **Announce state changes**: Not applicable: Card has no interactive states to announce.
- **Minimum tap target**: Not applicable: Card is not an interactive element — no `onClick`/`onPress` handler exists.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| card-001 | [export-six-slot-components](#requirements/export-six-slot-components) | `import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }` (UI Card family) | All six imports resolve to defined function exports. |
| card-002 | [render-div-root](#requirements/render-div-root) | Render each of the six UI Card family components with no props | Each renders a `<div>` as its outermost node. |
| card-003 | [set-data-slot-attribute](#requirements/set-data-slot-attribute) | Render `<Card />`, `<CardHeader />`, `<CardTitle />`, `<CardDescription />`, `<CardContent />`, `<CardFooter />` | Each rendered root `div` carries its matching `data-slot` value (`card`, `card-header`, `card-title`, `card-description`, `card-content`, `card-footer`). |
| card-004 | [merge-classname-prop](#requirements/merge-classname-prop) | `<Card className="extra-class" />` | The rendered root `div`'s `class` attribute contains both `extra-class` and the component's default classes (e.g. `rounded-xl`). |
| card-005 | [forward-rest-props](#requirements/forward-rest-props) | `<Card data-testid="x" />` | The rendered root `div` carries `data-testid="x"`. |
| card-006 | [compose-any-slot-subset](#requirements/compose-any-slot-subset) | `<Card><CardContent>Only content</CardContent></Card>` (Header/Title/Description/Footer omitted) | Renders without error, containing only the `CardContent` slot's markup. |
| card-007 | [always-renders-default-div](#requirements/always-renders-default-div) | `<Card />` (UI Card family, no children) | Renders an empty `<div data-slot="card">` carrying its default classes; nothing in source prevents an empty card. |
| card-008 | [card-corner-radius](#requirements/card-corner-radius) | `<Card />` | The rendered root `div`'s `class` attribute contains `rounded-xl`. |
| card-009 | [card-vertical-padding](#requirements/card-vertical-padding) | `<Card />` | The rendered root `div`'s `class` attribute contains `py-6` and no horizontal padding utility. |
| card-010 | [slot-horizontal-padding](#requirements/slot-horizontal-padding) | `<CardHeader />` | The rendered root `div`'s `class` attribute contains `px-6`. |
| card-011 | [slot-horizontal-padding](#requirements/slot-horizontal-padding) | `<CardContent />` | The rendered root `div`'s `class` attribute contains `px-6`. |
| card-012 | [slot-horizontal-padding](#requirements/slot-horizontal-padding) | `<CardFooter />` | The rendered root `div`'s `class` attribute contains `px-6`. |
| card-013 | [card-children-gap](#requirements/card-children-gap) | `<Card />` | The rendered root `div`'s `class` attribute contains `gap-6`. |
| card-014 | [header-children-gap](#requirements/header-children-gap) | `<CardHeader />` | The rendered root `div`'s `class` attribute contains `gap-1.5`. |
| card-015 | [title-font-weight](#requirements/title-font-weight) | `<CardTitle />` | The rendered root `div`'s `class` attribute contains `font-semibold` and `leading-none`. |
| card-016 | [description-font-size](#requirements/description-font-size) | `<CardDescription />` | The rendered root `div`'s `class` attribute contains `text-sm`. |
| card-017 | [card-background](#requirements/card-background) | `<Card />` | The rendered root `div`'s `class` attribute contains `bg-apt-bg`. |
| card-018 | [card-text-color](#requirements/card-text-color) | `<Card />` | The rendered root `div`'s `class` attribute contains `text-apt-text`. |
| card-019 | [card-text-color](#requirements/card-text-color) | `<CardTitle />` | The rendered root `div`'s `class` attribute contains `text-apt-text`. |
| card-020 | [description-text-color](#requirements/description-text-color) | `<CardDescription />` | The rendered root `div`'s `class` attribute contains `text-apt-text-muted`. |
| card-021 | [card-border](#requirements/card-border) | `<Card />` | The rendered root `div`'s `class` attribute contains `border` and `border-apt-border`. |
| card-022 | [card-shadow](#requirements/card-shadow) | `<Card />` | The rendered root `div`'s `class` attribute contains `shadow-sm`. |

## Edge Cases

- **Null/empty input — UI Card family**: No component performs prop validation. `Card` rendered with no children renders an empty `<div>` with its default classes — nothing in source prevents an empty card (#requirements/always-renders-default-div), per the unconditional `{...props}`/`children` spread in each component.
- **Boundary values**: Not applicable: The source exposes no numeric/length-constrained input (no min/max props, no character limits).
- **Concurrent access**: Not applicable: The UI Card family components are stateless, pure render functions with no internal state and no shared mutable resource; there is nothing to serialize.
- **Error states**: Not applicable: Card is a presentational container with no error-handling responsibility; errors would originate from child content, not the container itself.
- **Offline/disconnected state**: Not applicable: The source performs no network request; all six components are purely local rendering functions.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` | `string` | `undefined` | UI Card family (all six components). Additional classes merged with each component's default classes via `cn`. |
| *(rest props)* | native `div` attributes | none | UI Card family (all six components). Any other native `div` attribute is forwarded to the root element via prop spreading. |

## Deep Linking

Not applicable: Card is a layout primitive, not a navigable screen or route target.

## Localization

Not applicable: the UI Card family defines no built-in copy or default string. All visible text (the slot content passed into the family) is fully supplied by the caller as props/children. There is no string key defined anywhere in the source file.

## Accessibility Options

Not applicable as a behavior the component implements: the source does not branch on an accessibility display option. The table records what each option therefore means for this component.

| Option | Behavior |
|--------|----------|
| Reduce Motion | No transition or animation is applied in the source; nothing to disable under Reduce Motion. |
| Increase Contrast | No high-contrast variant is defined. Contrast comes from whatever the `apt-*` tokens resolve to for the active theme; the components themselves do not branch on the setting. |
| Differentiate Without Color | The card conveys no information by color: structure is carried by the border and the slot layout, so there is no color-only distinction to differentiate. |

## Feature Flags

Not applicable: Card renders unconditionally; the source does not read or gate a feature flag.

## Analytics

Not applicable: Card is a presentational container and does not emit analytics events. Event tracking, if needed, is the responsibility of content or parent components that consume the card.

## Privacy

- **Data collected**: None. The source file collects, stores, or transmits no data; it is purely presentational and receives all content via props/children.
- **Storage**: Not applicable — the source contains no storage code.
- **Transmission**: Not applicable — the source performs no network request.
- **Retention**: Not applicable — no data is collected or stored.

## Logging

Not applicable: Card does not perform logging; it is a presentational component with no internal state or event lifecycle to track.

## Platform Notes

- **SwiftUI**: No native `Card` primitive exists; compose a `VStack` (`HStack` for a footer-like row) inside a container view, applying `.background()`, `.clipShape(RoundedRectangle(cornerRadius:))`, `.overlay(RoundedRectangle().stroke())`, and `.shadow()` to reproduce the UI Card family's `bg-apt-bg`/`rounded-xl`/`border-apt-border`/`shadow-sm`. Map `CardHeader`/`CardTitle`/`CardDescription`/`CardContent`/`CardFooter` to nested `VStack`/`Text` views, using `VStack(spacing:)` for the `gap-6`/`gap-1.5` rhythm and `.padding(.horizontal)`/`.padding(.vertical)` for the `px-6`/`py-6` split, since SwiftUI has no `data-slot`-style attribute mechanism. Add `.accessibilityElement(children: .contain)` with `.accessibilityLabel()` on the container and `.accessibilityAddTraits(.isHeader)` on the title to supply the group and heading semantics the web source leaves unset.
- **Compose**: Use Material 3's `androidx.compose.material3.Card` as the base container, configuring its `shape`, `colors`, `border`, and `elevation` parameters to match `rounded-xl`/`bg-apt-bg`/`border-apt-border`/`shadow-sm`; note that M3's default `Card` is filled and elevated, so an outlined, near-flat look needs `OutlinedCard` or an explicit `CardDefaults.cardElevation`. Nest `Column`/`Row` composables for the header/content/footer slots, using `Arrangement.spacedBy()` for `gap-6`/`gap-1.5` and `Modifier.padding()` for `px-6`/`py-6`. Use `Modifier.semantics(mergeDescendants = true)` plus `heading()` on the title composable to recover the semantics the source's plain `div` does not carry.
- **React/Web**: This is the source platform; implement as given — the UI Card family as the six `cn`-composed Tailwind `div` components shown in source.
- **AppKit / UIKit**: No native card container exists. Compose an `NSView` (an `NSBox`, or a plain `NSView` with `wantsLayer = true`) or a `UIView`, setting `layer.cornerRadius` with `layer.masksToBounds`, `layer.borderWidth`/`layer.borderColor`, and `layer.shadowOpacity`/`shadowRadius`/`shadowOffset` to reproduce corner radius, border, and shadow — note that a single layer cannot both mask and cast a shadow, so use a wrapper view for the shadow and an inner masked view for the rounded fill. Lay the header/title/description/content/footer out as an `NSStackView`/`UIStackView`, with `spacing` standing in for `gap-6`/`gap-1.5` and `layoutMargins` for `px-6`/`py-6`, since neither framework has a `data-slot` equivalent. Set `isAccessibilityElement = false` on the container and `accessibilityTraits = .header` on the title label to recover the `<h3>` semantics.
- **WinUI 3**: Use a `Border` wrapping a `StackPanel` (or `Grid`) as the root, setting `CornerRadius`, `BorderBrush`/`BorderThickness`, and `Background` to the theme resources standing in for `rounded-xl`/`border-apt-border`/`bg-apt-bg`, and apply a `ThemeShadow` through the root element's `Shadow` and `Translation` properties to approximate `shadow-sm`. Nest `StackPanel`s for the header, content, and footer slots, with the footer panel using `Orientation="Horizontal"` and `VerticalAlignment="Center"` to match the source's `flex items-center`. WinUI 3 has no flexbox `gap`, so reproduce `gap-6`/`gap-1.5` with `StackPanel.Spacing` (or an explicit `Margin` on each child inside a `Grid`), and express the source's `py-6`/`px-6` split as `Padding` on the root `Border` for the vertical axis plus `Padding` on each slot panel for the horizontal axis. There is no `data-slot` equivalent: give each slot an `x:Name`, or define the whole card as a templated `ContentControl` whose `ControlTemplate` exposes `Header`, `Content`, and `Footer` `ContentPresenter`s. The card is non-interactive, so set `IsTabStop="False"` and define no `VisualStateManager` states for pointer, press, or focus; set `AutomationProperties.Name` on the root and `AutomationProperties.HeadingLevel="Level3"` on the title `TextBlock` to supply heading semantics the source does not set.

## Design Decisions

**Decision**: State the Tailwind utility classes and `apt-*` design tokens themselves as the Appearance requirement, rather than resolving them to literal pixel or color values.
**Rationale**: The UI Card family expresses every color and size as a Tailwind utility class or an `apt-*` design token (e.g. `bg-apt-bg`, `border-apt-border`, `text-apt-text-muted`) rather than as a literal value. `packages/web/packages/ui/src/components/card.tsx` states the intent directly: "The family Card — mirrors hub's component (apt-* tokens, generous 6-unit rhythm) so the shared library and hub render identically." The token indirection is load-bearing and MUST NOT be flattened into hard-coded values; an implementation conforms by using the named token, and the concrete pixel or color value is whatever the project's Tailwind and token configuration binds to it.
**Approved**: pending

**Decision**: Document no invented accessibility behavior beyond what the source sets.
**Rationale**: The UI Card family sets no ARIA role, label association, or tap target, because it is not an interactive control in source — it is a static container. This ingredient does not invent accessibility behavior that is not present in the code (see Accessibility).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The source sets no explicit ARIA role or heading semantics for the UI Card family's `CardTitle`, leaving any heading role or accessible name to the caller to add (semantic-markup: partial), and expresses color and type only as unresolved `apt-*` tokens or Tailwind classes whose rendered contrast and text scaling cannot be confirmed from source alone (contrast-ratio, dynamic-type-support: partial); the source file defines no single string literal, so all visible text passes through as caller-supplied props/children (no-hardcoded-strings: passed). Best-practices statuses rest on the UI `Card` family being pure presentation over `className`/props with no embedded logic (separation-of-concerns: passed), and on no test exercising this `card.tsx` directly — the candidate tests exercise the unrelated landing `Card`/`ResourceCard` components (unit-test-coverage: failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.3 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.2.2 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.1 | 2026-09-22 | Mike Fullerton | Narrowed to the UI Card family; Landing Card has its own recipe |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename all requirement names to subject-only kebab-case and promote Appearance and the two load-bearing Edge Case MUSTs to named requirements with matching conformance vectors; add per-class-token Appearance vectors and a kicker `null`/`""` vector; link Test Vector requirements to their `#requirements/<name>` fragments; convert Compliance to a check table; move the misplaced cross-repo reference from `references` to `related`; quote the source comments cited in Design Decisions with file:line citations and reformat every decision into the three-line Decision/Rationale/Approved form; drop the vacuous States table and say "ingredient" instead of "recipe" throughout; tighten `children-after-title` to "immediately after" to match its test vector. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | State the Tailwind utilities, `apt-*` tokens and `lp-card`/`lp-card__kicker` class names as the appearance contract in place of unresolved-value placeholders; answer the sizing, kicker-guard and accessibility-option questions directly from source; fill the Accessibility Options table; add automation, semantics and layout detail to every platform note. One open accessibility question about the family's non-heading title is left for the reviewer. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from `packages/web/packages/landing/src/blocks/Card.tsx` and `packages/web/packages/ui/src/components/card.tsx`. |
