---
id: f8cbc576-a5ef-4e8c-90a0-7d0712b24b72
title: "FlowHero"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Landing page hero section with centered composition, headline, subheading, actions, metadata, and supporting image."
platforms:
  - typescript
  - web
tags:
  - landing-page
  - hero
  - composition
depends-on: []
related:
  - 51d3b1ba-ced7-4c08-8a63-c83094d91299
  - 1675b18e-34d5-4d8e-987f-92697539a5e6
  - feee183a-6488-489e-8e20-c7150bb3e914
  - f98e53f7-ac16-48b0-afa5-544d05bf3f70
  - fae23662-e69b-4472-9c7d-049feadf1211
references: []
approved-by: ""
approved-date: ""
---

# FlowHero

## Overview

FlowHero is a landing page hero section component that presents a centered composition with a mark (image), headline (claim of what the product does), subheading, optional call-to-action buttons, optional metadata, and an optional supporting image below. The component uses semantic HTML and is structured as a `<div>` to avoid creating an unlabeled region in screen reader outlines.

## Behavioral Requirements

- **render-headline**: Component MUST render the `headline` prop as an `<h1>` element.
- **render-subheading**: Component MUST render the `sub` prop as a `<p>` element with class `lp-hero-sub`.
- **render-mark**: Component MUST render the `mark` prop (a ReactNode) without modification, allowing the host to supply its own `<Image>` or `<img>` element.
- **render-actions-when-children-provided**: Component MUST render `children` prop wrapped in a `<div>` with class `lp-hero-actions` when `children` is not `undefined`.
- **not-render-actions-when-children-undefined**: Component MUST NOT render the actions container when `children` is `undefined`.
- **render-metadata-when-provided**: Component MUST render the `meta` prop as a `<p>` element with class `lp-hero-meta` when `meta` is not `undefined`.
- **not-render-metadata-when-undefined**: Component MUST NOT render the metadata paragraph when `meta` is `undefined`.
- **render-shot-when-provided**: Component MUST render the `shot` prop within a `<div>` with class `lp-hero-shot` wrapped in a `Wrap` component when `shot` is not `undefined`.
- **not-render-shot-when-undefined**: Component MUST NOT render the shot container when `shot` is `undefined`.
- **support-optional-id**: Component MUST accept and render an optional `id` prop on the root `<div>`.
- **render-root-element**: Component MUST render a root `<div>` element with class `lp-hero-flow`.
- **render-order**: Within the root `<div>`, a single `Wrap` MUST contain, in order, `mark`, the headline `<h1>`, `sub`, the actions container (when `children` is provided), and the metadata paragraph (when `meta` is provided); the `shot` container (when provided) MUST render after that `Wrap`, inside its own separate `Wrap`.
- **single-per-page**: A page SHOULD contain at most one `FlowHero`, since the component always renders `headline` as an `<h1>`; a second instance produces two top-level headings and breaks the page's heading outline.

## Appearance

- **Layout**: Centered vertical stack composition, with child elements constrained within a `Wrap` container (see **render-order**)
- **Background**: `var(--lp-hero-wash, var(--lp-ground, #101010))` on `.lp-hero-flow` — a hero wash is the single most site-specific surface on the page, so the component sets no default beyond the page ground token
- **Typography**:
  - Headline: `<h1>` semantic heading
  - Subheading: `<p>` with class `lp-hero-sub`
  - Metadata: `<p>` with class `lp-hero-meta`, uppercased by stylesheet
- **Spacing**: Managed by CSS classes (`lp-hero-actions`, `lp-hero-shot`)
- **Mark container**: Rendered as provided (no styling applied by component)

## States

| State | Appearance change |
|-------|------------------|
| Default | — |
| Children provided | Actions container visible below subheading |
| Children undefined | Actions container hidden |
| Metadata provided | Metadata paragraph visible below actions |
| Metadata undefined | Metadata paragraph hidden |
| Shot provided | Shot image container visible below metadata |
| Shot undefined | Shot image container hidden |

## Accessibility

- **Semantic structure**: Uses `<h1>` for headline (main page heading) and `<p>` for subheading and metadata. The root is a `<div>`, not a `<section>`, to avoid creating an unlabeled landmark region in screen reader outlines (see **Design Decisions**).
- **Headline labeling**: Host-supplied `headline` content is expected to describe the product's claim or purpose meaningfully, since it renders as the page's `<h1>` (see **single-per-page**).
- **Subheading relationship**: The `<p>` with class `lp-hero-sub` provides supplementary information; position immediately after the headline creates a logical reading order (see **render-order**).
- **Action buttons**: `children` are expected to be bare, properly labeled `Btn` elements (see [adhsdk.ingredient.landing.blocks.btn](cookbook:1675b18e-34d5-4d8e-987f-92697539a5e6)); the parent `<div class="lp-hero-actions">` is a non-semantic container for layout only.
- **Image alt text**: The `mark` prop is supplied as a ReactNode by the host; the host is responsible for providing appropriate alt text if the mark contains an image.
- **Metadata styling**: Text is uppercased by CSS `text-transform` on the `<p>` the component renders. Hosts cannot override that transform from outside; a host needing non-uppercase content (e.g. a product name) wraps that content in its own child element with an inline style resetting `text-transform`, since the property is inherited and a descendant element can override it.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| flow-hero-001 | render-headline | `{ headline: "{{headline}}" }` | `<h1>{{headline}}</h1>` rendered in component |
| flow-hero-002 | render-subheading | `{ sub: "{{sub}}" }` | `<p class="lp-hero-sub">{{sub}}</p>` rendered in component |
| flow-hero-003 | render-mark | `{ mark: <img src="{{mark_src}}" alt="{{mark_alt}}" /> }` | Image element rendered without modification |
| flow-hero-004 | render-actions-when-children-provided | `{ children: [<Btn>{{action_label}}</Btn>] }` | `<div class="lp-hero-actions">` wraps children and is visible |
| flow-hero-005 | not-render-actions-when-children-undefined | `{ children: undefined }` | `<div class="lp-hero-actions">` is not rendered |
| flow-hero-006 | render-metadata-when-provided | `{ meta: "{{meta}}" }` | `<p class="lp-hero-meta">{{meta}}</p>` rendered in component |
| flow-hero-007 | not-render-metadata-when-undefined | `{ meta: undefined }` | Metadata paragraph is not rendered |
| flow-hero-008 | render-shot-when-provided | `{ shot: <img src="{{shot_src}}" /> }` | Shot image wrapped in `<div class="lp-hero-shot">` and is visible |
| flow-hero-009 | not-render-shot-when-undefined | `{ shot: undefined }` | Shot container is not rendered |
| flow-hero-010 | support-optional-id | `{ id: "{{hero_id}}" }` | Root `<div>` has `id="{{hero_id}}"` attribute |
| flow-hero-011 | render-root-element | `{ headline: "{{headline}}", sub: "{{sub}}" }` | Root element is `<div class="lp-hero-flow">` |
| flow-hero-012 | render-order | `{ mark: <img />, headline: "{{headline}}", sub: "{{sub}}", children: [<Btn>{{action_label}}</Btn>], meta: "{{meta}}", shot: <img /> }` | Inside the first `Wrap`: mark, then `<h1>`, then `<p class="lp-hero-sub">`, then `<div class="lp-hero-actions">`, then `<p class="lp-hero-meta">`, in that DOM order; `<div class="lp-hero-shot">` renders after that `Wrap`, inside a second `Wrap` |
| flow-hero-013 | not-render-actions-when-children-undefined | `{ children: null }` | `<div class="lp-hero-actions">` renders present but empty (`null` is not `undefined`) |
| flow-hero-014 | not-render-metadata-when-undefined | `{ meta: "" }` | `<p class="lp-hero-meta">` renders present but empty (`""` is not `undefined`) |
| flow-hero-015 | not-render-shot-when-undefined | `{ shot: null }` | `<div class="lp-hero-shot">` renders present but empty (`null` is not `undefined`) |

## Edge Cases

- **Null headline or sub**: The component requires both `headline` and `sub` as mandatory props (not optional in the type signature); passing null or undefined violates the type contract. Behavior is undefined if coerced to render.
- **Empty content slots**: `children`, `meta`, and `shot` are gated with `!== undefined`, so only an omitted prop (or an explicit `undefined`) hides its container. `null` and `""` are both `!== undefined`, so they still render an (empty) container — see **not-render-actions-when-children-undefined**, **not-render-metadata-when-undefined**, **not-render-shot-when-undefined**, and vectors flow-hero-013 through flow-hero-015. Hosts that want a section hidden must pass `undefined`, not `null` or `""`.
- **Nested components in mark**: The `mark` prop is rendered as-is; if the host provides complex nested React elements, they render without modification. No validation is performed on the mark's content or structure.
- **Very long text**: Headline and subheading text that exceeds single-line length will wrap per CSS (managed by stylesheet). The component imposes no text truncation or ellipsis.
- **Rich content in headline and sub**: Both `headline` and `sub` accept ReactNode, allowing the host to embed spans, links, or other elements. The component renders them as-is without sanitization.
- **Accessibility opt-out for uppercase meta**: The `meta` text is uppercased by stylesheet CSS on the `<p>` the component renders. Hosts cannot opt out at the component level (there is no prop for it); a host that needs non-uppercase content wraps that content in its own child element with an inline style resetting `text-transform`, since the property is inherited and a descendant can override it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | `string \| undefined` | `undefined` | Optional HTML id attribute on the root `<div>` for linking or styling |
| `mark` | `ReactNode \| undefined` | `undefined` | Optional mark/logo element (host supplies its own `<Image>` or `<img>`) |
| `headline` | `ReactNode` | — | Required: a claim describing what the product does, rendered as `<h1>` |
| `sub` | `ReactNode` | — | Required: one-line subheading under the headline, rendered as `<p class="lp-hero-sub">` |
| `children` | `ReactNode \| undefined` | `undefined` | Optional action buttons (bare `Btn` elements in host's order, wrapped in `<div class="lp-hero-actions">`) |
| `meta` | `ReactNode \| undefined` | `undefined` | Optional metadata line (price, platform floor, availability), rendered as `<p class="lp-hero-meta">` and uppercased by stylesheet |
| `shot` | `ReactNode \| undefined` | `undefined` | Optional supporting image below the composition (typically wrapped in `Bleed` by the host) |

## Deep Linking

Not applicable: FlowHero is a pure composition component and does not handle navigation or deep linking. Deep linking is the responsibility of child elements (buttons) and the host page.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| — | — | All content is supplied by the host via props; the component renders no hardcoded strings. |

`.lp-hero-meta`'s `text-transform: uppercase` is a locale-sensitive casing transform (for example, Turkish's dotted/dotless I changes which letter `i` uppercases to); hosts should not assume it produces identical casing in every locale, and no invariant-culture-style call should be introduced to normalize it — locale-sensitive casing is the correct behavior for user-facing text. Content that must not change case in some locale should use the child-element opt-out described under **Metadata styling** and **Accessibility opt-out for uppercase meta**.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | FlowHero itself renders no animation or transition — `.lp-hero-flow`, `.lp-hero-sub`, `.lp-hero-actions`, `.lp-hero-meta`, and `.lp-hero-shot` define no `transition`/`animation` in `flow.css`. Not applicable to this component. |
| Increase Contrast | Component does not manage contrast; this is managed by the stylesheet and design tokens applied via CSS classes. |
| Differentiate Without Color | Color differentiation is managed by the stylesheet; the component does not rely on color alone for information. |

## Feature Flags

| Flag Key | Default | Description |
|----------|---------|-------------|
| — | — | No feature flags are implemented in this component. |

## Analytics

Not applicable: FlowHero is a composition component with no interactive behavior of its own. Analytics events are the responsibility of child elements (e.g., buttons within `children`).

## Privacy

Not applicable: FlowHero does not collect, store, or transmit any data.

## Logging

Not applicable: FlowHero does not perform logging.

## Platform Notes

- **React/Web**: Source is `packages/web/packages/landing/src/flow/FlowHero.tsx`. The component is a function component that accepts a `FlowHeroProps` interface and returns a `ReactElement`. All props are rendered as ReactNodes to allow the host full control over element structure. The component uses conditional rendering (`{prop !== undefined && <...>}`) to show/hide optional sections — see **not-render-actions-when-children-undefined** and the Edge Cases note on `null`/`""`.

- **SwiftUI**: Translate to a `VStack` composition with optional sections. The headline is a `Text` marked as a heading with `.accessibilityAddTraits(.isHeader)`, with the subheading below it in smaller text, optional buttons in an `HStack` below that, optional metadata text at the bottom of the primary section, and an optional image container below. Use `@ViewBuilder` to conditionally include optional elements. Maintain semantic structure by grouping headline and subheading together visually.

- **Compose**: Implement as a `Column` with vertically stacked elements. Use nullable slot lambdas (e.g. `meta: (@Composable () -> Unit)? = null`) rather than `CompositionLocal` to let optional sections be omitted, with standard `if (condition)` for conditional rendering. Mark the headline `Text` as a heading with `Modifier.semantics { heading() }`. Optional buttons go in a `Row`, optional metadata in a `Text`, and an optional image below.

- **AppKit / UIKit**: On macOS, use an `NSStackView` (vertical orientation) containing: an optional `NSImageView` for the mark, an `NSTextField` for the headline marked as a heading (`accessibilityRole = .heading` / `NSAccessibility.Role.heading`), a subtitle `NSTextField` for the subheading, an optional horizontal `NSStackView` for buttons, an optional metadata `NSTextField`, and an optional `NSImageView`/container for the shot. On iOS, build the same composition with a `UIStackView` (vertical axis) and mark the headline `UILabel` as a heading with `accessibilityTraits = .header`.

- **WinUI 3**: Build the composition using a `StackPanel` (Vertical orientation) containing: optional `Image` for the mark, a `TextBlock` with large font size for the headline with `AutomationProperties.HeadingLevel="Level1"` set (WinUI 3 has no `role` attribute), a `TextBlock` with smaller size for the subheading, an optional horizontal `StackPanel` for buttons, an optional `TextBlock` for metadata (with `TextTransform="UpperCase"` applied), and an optional `Image` or container for the shot. Use `Visibility="Collapsed"` for conditional sections rather than removing elements from the tree.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/flow/FlowHero.tsx` | unverified |

## Design Decisions

- **Decision**: Render a `<div>` (not a `<section>`) as `FlowHero`'s root element.
  **Rationale**: A `<section>` here would create an unlabeled landmark region at the top of every screen reader's outline; the bands below the hero are the page's semantic landmarks. [adhsdk.ingredient.landing.hero](cookbook:fae23662-e69b-4472-9c7d-049feadf1211) makes the same call for the deck's `Hero` component for the same reason.
  **Approved**: pending

- **Decision**: Accept `mark` as a `ReactNode`, not an `<img>`/`<Image>` element.
  **Rationale**: This lets the host supply its own image element with full control over alt text, sizing, and optimization, decoupling the component from image-rendering logic.
  **Approved**: pending

- **Decision**: Gate the `children`, `meta`, and `shot` containers on `!== undefined`.
  **Rationale**: Only `undefined` suppresses a section's container. Passing `null` or an empty string still renders the (empty) container, since neither is excluded by `!== undefined`. Hosts must omit the prop, or pass `undefined` explicitly, to hide a section — see **Edge Cases**.
  **Approved**: pending

- **Decision**: Render `children` as bare `Btn` elements, never wrapped in a `Cta`.
  **Rationale**: `.lp-hero-actions` is already the centered, wrapping flex row; a `Cta` ([adhsdk.ingredient.landing.blocks.cta](cookbook:f98e53f7-ac16-48b0-afa5-544d05bf3f70)) inside it nests a second one whose own 0.75rem gap wins over the hero's own spacing, leaving it inert.
  **Approved**: pending

- **Decision**: Uppercase the `meta` text via CSS `text-transform`, not JavaScript.
  **Rationale**: Hosts cannot override that transform on the `<p>` element itself, since the component renders it, not the host. A host needing non-uppercase content (e.g. a product name) wraps that content in its own child element with an inline style resetting `text-transform`, because the property is inherited and a descendant element can override it.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` and `no-hardcoded-strings` rest on `FlowHero.tsx` rendering `<div>`/`<h1>`/`<p>` with every string passed through as a ReactNode prop, not a literal in source; `text-expansion-tolerance` rests on `flow.css` sizing the headline/sub/meta with `rem`/`ch`/`clamp()`, `text-wrap: balance`/`pretty`, and no truncation or overflow rule; `dynamic-type-support` is `partial` because the CSS uses relative (`rem`) units, which scale with a browser's font-size setting, but the source shows no explicit platform Dynamic Type integration; `contrast-ratio` is `partial` because the actual foreground/background pairing comes from host-supplied `--lp-ink*`/`--lp-hero-wash` tokens the source cannot verify. `separation-of-concerns` is `passed` because the component is pure layout over props with no business logic; `unit-test-coverage` is `passed` because `flow.test.tsx` renders `FlowHero` directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited; corrected the null/empty-string suppression contradiction (only `undefined` hides a section) in Design Decisions and Edge Cases; corrected the uppercase-meta opt-out mechanism (child-element override, not the component's own `<p>`); verified the Reduce Motion claim against `flow.css` and corrected it (component has no motion of its own); linked the no-section-element decision to [adhsdk.ingredient.landing.hero](cookbook:fae23662-e69b-4472-9c7d-049feadf1211); populated `related` with Wrap/Btn/Bleed/Cta/Hero; replaced the made-up compliance checks with catalog-linked accessibility and internationalization checks plus a sourcing sentence; reformatted Design Decisions to Decision/Rationale/Approved; renamed the Platform Notes bullet to React/Web and corrected WinUI/SwiftUI/Compose/AppKit-UIKit heading-semantics APIs; named the hero background's CSS custom property; added `render-order` and `single-per-page` requirements with a matching test vector; added null/empty-string test vectors and fixed vector 011's self-contradictory input; replaced app-specific test-vector copy with `{{placeholder}}` tokens; added a locale-sensitivity note for the meta uppercase transform; fixed an unescaped `\|` breaking the Configuration table |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source analysis |
