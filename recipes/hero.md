---
id: fae23662-e69b-4472-9c7d-049feadf1211
title: Hero
domain: adhsdk://recipes/hero
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Landing page hero block with mark, headline, tagline, and call-to-action
  slots.
platforms:
- typescript
- web
tags:
- landing
- hero
depends-on:
- adhsdk://recipes/screen
related:
- adhsdk://recipes/cta
- adhsdk://recipes/trust
- adhsdk://recipes/status-pill
references: []
approved-by: ''
approved-date: ''
---

# Hero

## Overview

The Hero component is a centered landing screen containing a mark (brand image), headline, tagline, and optional child content (CTA buttons, trust badges, status pills). It is the sole centered screen on a landing page and is used to make a single value proposition claim to the visitor.

## Behavioral Requirements

- **render-headline**: Component MUST render the `headline` prop as the primary claim statement within an `<h1>` element.
- **render-tagline**: Component MUST render the `tagline` prop as supporting text within a `<p>` element with class `lp-tag`.
- **accept-mark**: Component MUST accept an optional `mark` prop as a `ReactNode`, allowing the host to supply its own `<Image>` or `<img>` element before the headline.
- **accept-children**: Component MUST accept optional `children` as a `ReactNode` to compose call-to-action, trust, and status pill components below the tagline.
- **support-glow**: Component MUST support a `glow` prop (default `true`) that controls the glow effect on the Screen container.
- **support-id**: Component MUST accept an optional `id` prop to set the HTML `id` attribute for semantic identification.
- **center-content**: Component MUST center all content horizontally and render as a centered Screen (align="center").
- **render-as-div**: Component MUST render the Screen container with `as="div"` to output a non-semantic container, deferring any landmark role to the host — see **root-is-non-semantic** under Design Decisions.
- **hero-styling-class**: Component MUST render with the `lp-hero` class alongside Screen's own `lp-screen` class, so the hero-specific rules in `css/blocks.css` (padding-inline, headline/tagline type) apply.

## Appearance

- **Corner radius**: Inherited from Screen component; no additional radius applied
- **Padding**: Inherited from Screen component and `lp-hero` CSS class
- **Font**: Headline uses `<h1>` default sizing overridden by `.lp-hero h1` (`clamp(1.85rem, 5.2vw, 3.3rem)`, weight 200); tagline uses `<p>` default with `lp-tag` class styling (`1.05rem`)
- **Background**: Inherited from Screen component (centred screen exception, per `css/blocks.css` comment)
- **Foreground/Text**: Headline color is inherited from the page body's ink token (`color: var(--lp-ink, #ededed)`, set in `css/base.css`), with emphasized (`<b>`) text brightened via `.lp-hero h1 b` (`var(--lp-accent-bright, #d8d8d8)`); tagline color is set by `.lp-hero p.lp-tag` (`var(--lp-ink-dim, #a0a0a0)`), with `em` text brightened back to `var(--lp-ink, #ededed)` via `.lp-hero p.lp-tag em`
- **Border**: None
- **Shadow**: Glow effect applied via Screen component when `glow={true}` (default)
- **Min/Max size**: No explicit constraints; inherits Screen sizing

## States

| State | Appearance change |
|-------|------------------|
| Default (glow enabled) | Screen renders with glow effect on Screen component |
| Glow disabled | Screen renders without glow effect when `glow={false}` |

## Accessibility

- **Role**: Non-semantic `<div>` — a `<div>` carries no implicit ARIA role. `Screen`'s `as="div"` is deliberate (see **render-as-div** and the root-is-non-semantic Design Decision): the host MUST wrap Hero in an appropriate semantic landmark (e.g. `<section>`, `<main>`) if the page needs one
- **Label requirements**: Headline (`<h1>`) serves as the primary heading; tagline (`<p>`) provides context
- **Announce state changes**: Not applicable; Hero is a static presentation component with no interactive state changes
- **Minimum tap target**: Not applicable; Hero contains no interactive controls directly. Child components (CTA buttons, etc., each with their own recipe) MUST meet the web target-size minimum of 24×24 CSS px (WCAG 2.5.8 Target Size (Minimum), Level AA) and SHOULD meet 44×44 CSS px (WCAG 2.5.5 Target Size (Enhanced), Level AAA) where feasible
- **Keyboard navigation**: Not applicable; Hero is non-interactive. Child components MUST be keyboard navigable

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| hero-001 | render-headline | `headline="Claim"` | An `<h1>` containing the text "Claim" renders |
| hero-002 | render-tagline | `tagline="Supporting text"` | A `<p class="lp-tag">` containing "Supporting text" renders |
| hero-003 | accept-mark | `mark={<img src="logo.svg" />}` | The mark element renders before the `<h1>` |
| hero-004 | accept-children | `children={<button>CTA</button>}` | The CTA button renders after the tagline |
| hero-005 | support-glow | `glow={true}` | A decorative glow element (`aria-hidden`, no content) renders behind the mark and headline |
| hero-006 | support-glow | `glow={false}` | No glow element renders |
| hero-007 | support-id | `id="hero-section"` | The root element has `id="hero-section"` |
| hero-008 | center-content | Any props | Content renders horizontally centered within the screen |
| hero-009 | render-as-div | Any props | The root element is a non-semantic container (`<div>` on web), never a `<section>` |
| hero-010 | hero-styling-class | Any props | The root carries the hero's own styling identity (`lp-hero` on web) in addition to the generic screen styling |
| hero-011 | accept-mark (edge case: mark omitted) | `mark` undefined | No mark element renders; the `<h1>` and `<p class="lp-tag">` still render as normal |
| hero-012 | accept-children (edge case: children omitted) | `children` undefined | Nothing renders after the tagline |
| hero-013 | render-headline, render-tagline (edge case: empty strings) | `headline=""`, `tagline=""` | An empty `<h1>` and an empty `<p class="lp-tag">` render; no error is thrown |
| hero-014 | render-headline (edge case: nested ReactNode) | `headline={<>Claim <b>emphasized</b></>}` | The nested markup renders inside the `<h1>` unchanged |
| hero-015 | accept-children (edge case: multiple children) | `children={<><Cta/><Trust/><StatusPill/></>}` | All three render, in the given order, after the tagline |
| hero-016 | support-glow (edge case: glow omitted) | `glow` undefined | Same as hero-005: the glow element renders by default |
| hero-017 | render-tagline (edge case: tagline must be phrasing content) | `tagline={<em>Emphasis</em>}` | The inline content renders nested inside the `<p>`; block-level content (e.g. a `<div>`) is out of contract and produces invalid, browser-auto-corrected HTML |

## Edge Cases

- **Mark omitted**: When `mark` is undefined, no image element renders; headline and tagline render as expected. See hero-011.
- **Children omitted**: When `children` is undefined, CTA/trust/status sections are not rendered; headline and tagline render as expected. See hero-012.
- **Empty headline or tagline**: No validation in component; empty or whitespace-only strings render as empty h1/p elements. Host is responsible for providing non-empty content. See hero-013.
- **Headline with ReactNode children**: Headline accepts ReactNode, allowing nested elements (emphasis, links, etc.); host is responsible for semantic correctness. See hero-014.
- **Multiple CTA/trust/status children**: Children prop accepts any ReactNode; host may compose multiple CTA, Trust, and StatusPill components in any order. See hero-015.
- **glow omitted**: Defaults to `true`; glow effect is enabled unless explicitly set to `false`. See hero-016.
- **Tagline must be phrasing content**: `tagline` renders inside a `<p>`, so passing block-level content (e.g. a `<div>`) produces invalid, browser-auto-corrected HTML. Content passed as `tagline` MUST be phrasing content (text, inline elements such as `<em>`/`<a>`) only. See hero-017.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | string (optional) | undefined | HTML id attribute for the root div |
| `mark` | ReactNode (optional) | undefined | Mark/logo image element supplied by host |
| `headline` | ReactNode | required | Primary value proposition claim |
| `tagline` | ReactNode | required | Supporting claim text |
| `children` | ReactNode (optional) | undefined | CTA, Trust, StatusPill components |
| `glow` | boolean | `true` | Enable/disable glow effect on Screen |

## Deep Linking

Not applicable: Hero is a presentation component and does not define deep linking patterns. Host application is responsible for linking if needed.

## Localization

Not applicable: Hero accepts ReactNode props for headline, tagline, and children. The host is responsible for providing localized content.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Nothing in the hero animates: the glow is a static radial gradient (`.lp-glow` in base.css), not a keyframe animation. base.css also carries a `prefers-reduced-motion` reset that sets `animation: none` and `transition: none` on every element of a deck or flow page, so any host-added motion inside the hero stops too. |
| Increase Contrast | Not implemented in source. Behavior undefined. |
| Differentiate Without Color | Not applicable; Hero uses no color-only differentiation. |

## Feature Flags

Not applicable: Hero component has no feature flags. Host application may control visibility via conditional rendering.

## Analytics

Not applicable: Hero component is non-interactive and does not emit analytics events directly.

## Privacy

Not applicable: Hero is a presentation component and does not collect, store, or transmit user data.

## Logging

Not applicable: Hero component has no logging.

## Platform Notes

- **TypeScript/Web**: Defined in `packages/web/packages/landing/src/blocks/Hero.tsx`. Renders a `Screen` component with `align="center"` and `className="lp-hero"`. The component never supplies its own `<Image>` or `<img>` element; the host provides mark via `ReactNode` to avoid a top-level `next/image` dependency.
- **SwiftUI**: Use a `VStack` with `alignment: .center`; apply a `.heroSpacing()` view modifier that sets the vertical gap and horizontal inset (matching `.lp-hero`'s `padding-inline`). Render the mark (`Image`), headline (`Text`, large/thin-weight styling matching the claim treatment), tagline (`Text`, secondary/dimmer styling), and child views in vertical order. Apply a `.heroGlow(_:)` modifier that conditionally places a `RadialGradient` behind the stack via `.background`, matching `.lp-glow`.
- **Compose**: Use a `Column` with `horizontalAlignment: Alignment.CenterHorizontally` and `modifier: Modifier.fillMaxWidth()`. Render the mark (`Image` composable), headline (`Text` with `style: MaterialTheme.typography.headlineLarge`), tagline (`Text` with `style: MaterialTheme.typography.bodyLarge`), and child composables in order. Apply the glow as a `Box` behind the content with a `Brush.radialGradient` background, toggled by the glow boolean.
- **AppKit / UIKit**: **AppKit** — use an `NSStackView` with vertical orientation and `.centerX` alignment. **UIKit** — use a vertical `UIStackView` with `.center` alignment. Render the mark (`NSImageView` / `UIImageView`), headline (`NSTextField` / `UILabel` with a large, light-weight font), tagline (`NSTextField` / `UILabel` with secondary styling), and child views in order. Apply the glow as a `CAGradientLayer` (`type: .radial`) inserted behind the stack's layer, toggled by the glow boolean.
- **WinUI 3**: Use a `StackPanel` with `Orientation: Vertical` and `HorizontalAlignment: Center`. Bind the mark (`Image` control), headline (`TextBlock` with `FontSize: 32` and `FontWeight: Bold`), tagline (`TextBlock` with secondary foreground), and child controls in order. Render the glow as a `Rectangle` (or `Border`) behind the content filled with a native `RadialGradientBrush`, toggled by the glow boolean property — not `DropShadowPanel` (a Community Toolkit control, not a platform primitive, and a shadow rather than the radial-gradient light `.lp-glow` describes).

## Design Decisions

- **Decision**: `mark` is accepted as a `ReactNode` rather than a file path or URL.
  **Rationale**: Defers image loading and styling to the host, avoiding a hard dependency on `next/image`.
  **Approved**: pending

- **Decision**: The component renders as a non-semantic `<div>` (via `Screen as="div"`), not a `<section>`. (root-is-non-semantic)
  **Rationale**: A `<div>` has no implicit role, so this is a deliberate placement choice rather than an accessibility default — it lets the host wrap Hero in whatever semantic landmark (if any) the surrounding page needs.
  **Approved**: pending

- **Decision**: `glow` defaults to `true`.
  **Rationale**: Matches the expected landing-page look; a host can disable it for alternative layouts.
  **Approved**: pending

- **Decision**: No validation or error handling is performed on `headline` or `tagline`.
  **Rationale**: Keeps the component a thin presentational layer; the host is responsible for providing meaningful, well-formed content.
  **Approved**: pending

- **Decision**: A landing page renders at most one Hero.
  **Rationale**: Hero is the page's sole centered screen and its `headline` is the page's single value-proposition claim rendered as an `<h1>`; a second Hero would duplicate that `<h1>` and undermine the page's heading structure.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `Hero.tsx` and its CSS: the root `<div>` carries no ARIA role even though the `<h1>`/`<p>` it wraps remain correctly semantic (semantic-markup: partial); headline/tagline sizes are `rem`-based and scale with the root font-size dial in `css/base.css` (dynamic-type-support: passed); the default `--lp-ink`/`--lp-ink-dim` tokens against `--lp-ground` compute well above WCAG AA but are host-overridable custom properties (contrast-ratio: partial); the Accessibility Options row above documents the `prefers-reduced-motion` reset (reduced-motion: passed); and `headline`/`tagline` are always host-supplied `ReactNode`s with no strings in source, rendered in flexible `ch`-based containers that tolerate expansion without truncation (no-hardcoded-strings, text-expansion-tolerance: passed). `separation-of-concerns` passes because the component is pure presentation over its props, delegating all layout to `Screen`; `unit-test-coverage` passes on `blocks-close.test.tsx`'s dedicated `Hero` suite, which asserts the mark/headline/tagline/children slots and the `glow` toggle.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and updated every citation; corrected the div/section semantics claim and the tap-target unit/citation; reformatted Design Decisions into Decision/Rationale/Approved and added a single-Hero-per-page decision; added a Compliance table plus `depends-on`/`related`; rewrote Conformance Test Vectors to assert observable outcomes (added `hero-styling-class` and a tagline phrasing-content edge case) with full edge-case coverage; fixed the WinUI 3 and AppKit/UIKit platform notes; corrected the headline foreground description; normalized frontmatter date quoting |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
