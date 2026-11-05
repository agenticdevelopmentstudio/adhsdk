---
id: d80699f9-1020-4f8a-85ce-f6406e765631
title: Site Footer
domain: adhsdk://recipes/site-footer
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A semantic footer landmark that wraps page footer content in a constrained
  layout column.
platforms:
- typescript
- web
tags:
- footer
- landmark
- layout
- landing
depends-on:
- adhsdk://recipes/wrap
related:
- adhsdk://recipes/band
references: []
approved-by: ''
approved-date: ''
---

# Site Footer

## Overview

The Site Footer is a structural footer component that renders a semantic HTML `<footer>` landmark element containing page footer content. It applies a fixed CSS class and optional custom classes, and wraps its content in a layout column (Wrap) to constrain width and maintain consistency with other page sections. Unlike Band and Wrap, the footer owns its own visual chrome directly — background, text color, font size, and a top hairline border all live on `.lp-site-foot` itself. It reserves space for the dock clearance like other band components and is positioned as the last element beneath the dock.

## Behavioral Requirements

- **render-footer-landmark**: Component MUST render an HTML `<footer>` element.
- **apply-lp-site-foot-class**: Component MUST apply the CSS class `lp-site-foot` to the footer element.
- **accept-children**: Component MUST accept and render ReactNode children.
- **wrap-children-in-layout-column**: Component MUST wrap children in a Wrap component to provide constrained layout.
- **accept-custom-class**: Component MAY accept an optional `className` prop to apply additional CSS classes.
- **merge-classes**: When a custom `className` is provided, component MUST apply both `lp-site-foot` and the custom class name to the footer element, separated by a space, and MUST filter out falsy values (`className={undefined}`, `className={false}`, or `className=""`); it does not trim whitespace-only strings and performs no de-duplication.
- **apply-footer-chrome**: Component's stylesheet (`.lp-site-foot`) MUST set its own vertical padding (`clamp(3rem, 6vw, 5rem)` top; the same value plus `var(--lp-dock-clear, 0px)` on the bottom), a `1px` top hairline border, a `var(--lp-ground)` background, `var(--lp-ink-dim)` text color, and a `0.86rem` font size — none of this is inherited from `Wrap` or from descendants.
- **style-descendant-links**: Component's stylesheet MUST style descendant `<a>` elements (`.lp-site-foot a`) with a non-default link color (`var(--lp-ink)`), no text-decoration underline, and a hairline bottom border, plus a hover state that swaps the border color to `var(--lp-accent)`, so a host's footer links never fall back to the browser's default blue underline against the dark ground.
- **style-credit-sub-lines**: Component's stylesheet MUST style descendant `<small>` elements (`.lp-site-foot small`) with a reduced font size (`0.72rem`) and letter-spacing (`0.04em`), for copyright or attribution sub-lines within a credit line.

## Appearance

- **Corner radius**: None
- **Padding**: `clamp(3rem, 6vw, 5rem)` top; the same clamp value plus `var(--lp-dock-clear, 0px)` on the bottom. Set directly by `.lp-site-foot` in `flow.css` — not inherited from `Wrap` or from descendants (see **apply-footer-chrome**).
- **Font**: `0.86rem`, set by `.lp-site-foot` itself; not inherited.
- **Background**: `var(--lp-ground, #101010)`, set by `.lp-site-foot` itself — the component does not leave background to its children.
- **Foreground/Text**: `var(--lp-ink-dim, #a0a0a0)`, set by `.lp-site-foot` itself. Descendant links override to `var(--lp-ink, #ededed)` via `.lp-site-foot a` (see **style-descendant-links**).
- **Border**: `1px solid var(--lp-hairline, rgba(255, 255, 255, 0.1))` top hairline, set by `.lp-site-foot` itself.
- **Shadow**: None applied by component
- **Min/Max size**: Full width; constrained content width via the `Wrap` component, which handles horizontal centering and max measure only — it does not contribute the padding, background, border, color, or font described above.

## States

Not applicable: component is stateless and does not render interactive or state-dependent content.

## Accessibility

- **Role**: Landmark (`<footer>` renders the implicit `contentinfo` role)
- **Landmark exposure**: The `<footer>` element only exposes the `contentinfo` landmark role when it is NOT nested inside `article`, `section`, `main`, `aside`, or `nav`. `Flow` renders its own children (the page's bands) inside a `<main class="lp-flow">`, so a host MUST render `SiteFooter` as a sibling of the page's `Flow` container itself — outside that `<main>` — and not merely alongside the individual bands as one of `Flow`'s own children, or the footer loses its `contentinfo` role. The component itself renders only the element and does not enforce where it is mounted.
- **Label requirements**: No explicit ARIA labeling required; a page normally has one `<footer>` landmark, so no accessible name is needed to disambiguate it.
- **Keyboard navigation**: Not applicable; the component itself renders no interactive elements — see **style-descendant-links** for the descendant links it styles but does not create.
- **Touch target size**: Not applicable; component is a container, not an interactive control.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-footer-001 | render-footer-landmark | Render component with no props | Output contains a `<footer>` element |
| site-footer-002 | apply-lp-site-foot-class | Render component with no props | Footer element's `class` attribute contains `lp-site-foot` |
| site-footer-003 | accept-children | Render with `children="Footer content"` | Footer element contains text "Footer content" |
| site-footer-004 | wrap-children-in-layout-column | Render with children | Footer's direct child is a `<div>` with class `lp-wrap`, and that `div` contains the children |
| site-footer-005 | merge-classes | Render with `className="custom-footer"` | Footer element's `class` attribute is exactly `lp-site-foot custom-footer` |
| site-footer-006 | merge-classes | Render with `className={undefined}` | Footer element's `class` attribute is exactly `lp-site-foot` |
| site-footer-007 | merge-classes | Render with `className=""` | Footer element's `class` attribute is exactly `lp-site-foot` (empty string is falsy and filtered) |
| site-footer-008 | apply-footer-chrome | Render component | Footer element's computed style has a `1px` top border, `background-color` equal to the `--lp-ground` token, `color` equal to the `--lp-ink-dim` token, and `font-size: 0.86rem` |
| site-footer-009 | apply-footer-chrome | Render component with `--lp-dock-clear` set to a non-zero value on an ancestor | Footer element's computed `padding-bottom` equals `clamp(3rem, 6vw, 5rem)` plus the `--lp-dock-clear` value |
| site-footer-010 | style-descendant-links | Render with `children={<a href="#">Credit</a>}` | Descendant `<a>` element's computed style has no underline text-decoration, a `1px` bottom border, and `color` equal to the `--lp-ink` token |
| site-footer-011 | style-credit-sub-lines | Render with `children={<small>© 2026</small>}` | Descendant `<small>` element's computed `font-size` is `0.72rem` |

## Edge Cases

- **Empty children**: Component MUST render a valid `<footer>` element even when children are empty or null.
- **Null className**: When `className` is `undefined` or not provided, component MUST apply only the `lp-site-foot` class; the `undefined` value is filtered out because it is falsy.
- **Whitespace-only className**: An empty string (`''`) is falsy, so it is filtered out, leaving only `lp-site-foot`. A whitespace-only string (e.g. `' '`) is truthy in JavaScript, so it is NOT filtered — it is joined into the class list as-is. The component only filters falsy values; it does not trim or validate whitespace, and performs no de-duplication.

## Configuration

Not applicable: component accepts only React props `children` and optional `className`; no configuration options exist.

## Deep Linking

Not applicable: component is a layout container and does not handle routing or deep link resolution.

## Localization

Not applicable: component renders no user-facing text; all content is provided by children.

## Accessibility Options

Not applicable: component has no interactive states or visual styling that would respond to accessibility display options such as Reduce Motion, Increase Contrast, or Differentiate Without Color.

## Feature Flags

Not applicable: component has no conditional rendering or feature-gated behavior.

## Analytics

Not applicable: component is non-interactive and does not emit user interaction events.

## Privacy

Not applicable: component does not collect, store, or transmit any data.

## Logging

Not applicable: component has no internal operations, async behavior, or error states that would require logging.

## Platform Notes

- **Source (TypeScript/React)**: Implemented in `packages/web/packages/landing/src/flow/SiteFooter.tsx`. Accepts `children` (ReactNode, required) and `className` (string, optional). Returns JSX rendering an HTML `<footer>` element with merged class names and Wrap-wrapped children. The `lp-site-foot` class is the fixed style hook; custom classes are composed via `['lp-site-foot', className].filter(Boolean).join(' ')`. All visual chrome (padding, dock clearance, background, border, color, font size, and the descendant link/small styling) lives in `flow.css` on `.lp-site-foot` and its descendant selectors, not in the component itself.

- **SwiftUI**: Implement as a `View` that renders a full-width container with an inner content stack constrained to the same max-width measure used by the `Wrap` port, and apply the container's own background, foreground color, font, and top hairline divider directly (mirroring `.lp-site-foot`, not delegating them to the content column). Add bottom padding equal to the host's dock-clearance inset (an environment value or parameter the host supplies). There is no `.footer` accessibility trait or built-in `SiteFooterStyle` modifier to reach for; use a plain container View and rely on the platform mapping a suitably placed container to the "content info" accessibility landmark, or a dedicated accessibility container element if the platform version supports one.

- **Compose**: On Android, implement a footer as a Composable that uses `Box` or `Column` with `Modifier.fillMaxWidth()` to span the full width, its own background/content color/typography applied directly (not inherited), and internal padding — including a bottom inset bound to the dock-clearance value — to reserve dock clearance. The content parameter accepts a `@Composable` lambda to render arbitrary children within a max-width content column matching `Wrap`.

- **AppKit / UIKit**: Implement the footer as the LAST arranged subview of the scrolling content (an arranged subview at the end of a `UIStackView`/`NSStackView` inside the scroll view), not as a view pinned to the screen's safe area — pinning it there would make it fixed, but the source footer scrolls with the page and is simply the final thing in it. Give the footer's own layer/background, text color, font, and top hairline border directly, and add bottom spacing equal to the dock clearance so a fixed dock never permanently covers it. Constrain an inner content view to the same max width as the `Wrap` port.

- **WinUI 3**: Implement as a `Grid` row (or `StackPanel`) spanning the full width of the page's root layout, with its own `Background`, `Foreground`, `FontSize`, and a `BorderThickness`/`BorderBrush` top hairline set directly on that row — not inherited from the content column. Wrap content in an inner `Grid`/`Border` with `MaxWidth` bound to the same measure token used by the `Wrap` port. Bind the row's bottom `Padding` to a dock-clearance resource (the WinUI equivalent of `--lp-dock-clear`) so content is not covered by a docked control at the bottom of the window. Apply no `CornerRadius`, matching Appearance's "Corner radius: None".

## Design Decisions

**Decision**: `.lp-site-foot` sets its own background, foreground color, font size, top border, and padding — including dock clearance — directly, rather than delegating any of it to `Wrap` or inheriting it from descendants.
**Rationale**: `Wrap` only constrains content width (see `wrap.md`); the footer needs a full-width band of chrome (ground color, hairline, dimmed ink) independent of that content column, matching the visual treatment of the rest of the page's bands.
**Approved**: pending

**Decision**: Dock clearance (`var(--lp-dock-clear)`) is applied unconditionally to both `.lp-band:last-child`'s bottom padding and `.lp-site-foot`'s bottom padding; on a page that has both a last band and a footer, both pay it.
**Rationale**: `flow.css`'s comment above `.lp-band:last-child` explains that only the last thing in the document — the one thing a fixed host dock can permanently cover, since everything before it can still be scrolled past — strictly needs the clearance: `.lp-site-foot` carries it for a host with a footer, and the `.lp-band:last-child` pair carries it for a host with none. The two rules are not conditioned on each other, so a host with both pays the last band's clearance a second time; the source's own comment accepts that as the safe direction, since the failure it guards against (content trapped under the dock) is worse than one band's worth of extra scroll space.
**Approved**: pending

**Decision**: The component composes `Wrap` non-configurably to constrain content width, the same pattern `Band` uses.
**Rationale**: Keeps horizontal measure consistent with the rest of the page's structural blocks without giving a caller a way to opt out per instance.
**Approved**: pending

**Decision**: `className` merging filters only falsy values (`Boolean` truthiness) and performs no trimming or de-duplication.
**Rationale**: `['lp-site-foot', className].filter(Boolean).join(' ')` is the entire implementation; documenting exactly that behavior — including the whitespace-only string case it does not handle — keeps the contract honest rather than promising validation the source does not do.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`semantic-markup` passes because the component always renders a real `<footer>` element, which carries the correct implicit `contentinfo` landmark role when placed as a direct page-level child (see **Accessibility**). `contrast-ratio` is partial because `flow.css` pairs `--lp-ground`/`--lp-ink-dim` for the footer body and `--lp-ink`/`--lp-ground` for its links (see **Appearance**), but the actual rendered contrast depends on whichever values a host supplies for those custom properties, which the source neither computes nor verifies. `separation-of-concerns` passes because `SiteFooter.tsx` is pure presentation, wrapping its children with no business logic. `unit-test-coverage` is partial because `flow.test.tsx`'s `SiteFooter` block asserts only on the `.lp-site-foot a` CSS rule, not on the component's own render output — no test calls `render(<SiteFooter>)` directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed landmark bullet to require SiteFooter be a Flow sibling; corrected dock-clearance double-pay decision. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; rewrote Appearance and Design Decisions from `flow.css` to correct the padding/background/border/font/dock-clearance claims and cite the source; added requirements and test vectors for the descendant link and small styling and for the footer's own chrome and dock clearance; narrowed the whitespace-only className edge case and merge-classes requirement to falsy-value filtering only; folded the untested duplicate-class claim out of the test vectors and added vectors for the Wrap child, className="", and dock-clearance padding; added a landmark-exposure note requiring direct page-level placement; reformatted Design Decisions into Decision/Rationale/Approved records; corrected the WinUI 3, SwiftUI, and AppKit/UIKit platform notes; rebuilt Compliance as a linked passed/partial table; added tags, depends-on, and related |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source |
