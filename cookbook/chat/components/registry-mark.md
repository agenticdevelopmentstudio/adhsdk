---
id: f8e3d2a1-4c9b-4d7e-8f2b-a5c3e7b1d4f6
title: "Registry Mark"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Credential mark linking a persona to its registry profile, displayed as a @ symbol with AI star accent."
platforms:
  - typescript
  - web
tags:
  - persona
  - registry
  - credential
depends-on:
  - 447d0e33-c66e-4bf9-8511-e7823bdbcf9b
  - 960a1577-bf48-4d56-a93f-aa690853f64f
related:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
  - 6c034a7a-3a43-4da6-bc1a-0cbc39f32cc4
references:
  - https://www.jetbrains.com/lp/mono/
  - https://github.com/JetBrains/JetBrainsMono/blob/master/OFL.txt
approved-by: ""
approved-date: ""
---

# Registry Mark

## Overview

The Registry Mark is a visual credential indicator linking a persona chat to its profile on the Agentic Persona Registry. Rendered as a @ symbol with an AI star — the toolkit's four-pointed, concave-sided accent glyph used to mark AI/agentic credentials — embedded in its counter, positioned at the top-right corner of a persona chat frame, straddling the frame boundary. The mark tints with inherited color (registry house color or persona hue) and uses ADH gold for the star accent. Optional popover content (e.g., persona bio, link to full profile) displays on hover and focus.

## Behavioral Requirements

- **render-link**: Component MUST render as a hyperlink (`<a>`) to the persona's `profileUrl` with `target="_blank"` and `rel="noopener noreferrer"`.
- **new-window-disclosure**: Component SHOULD expose (via the required `label` prop, or via additional visually hidden text) that activating the link opens a new tab, since the link always sets `target="_blank"`.
- **accessible-name**: Component MUST set the link's `aria-label` attribute to the `label` prop.
- **render-at-glyph**: Component MUST render an @ symbol using the JetBrains Mono glyph (weight 400), embedded as SVG path data.
- **render-star**: Component MUST render a four-pointed AI star positioned inside the @ counter, filled with hex `#c4a35a`.
- **tint-glyph-with-currentcolor**: Component MUST apply `fill="currentColor"` to the @ glyph, allowing ancestor elements to tint the mark via CSS `color` property.
- **preserve-anchor-geometry**: Component MUST position the @ glyph so its center anchor point aligns with the host's top-right corner (50% X, -50% Y offset via CSS variables).
- **tip-sibling-of-link**: When the popover span is rendered, it MUST be a sibling of the link under the root `pc-registry-mark` span, never a descendant of the `<a>`, so interactive content in `tip` is not nested inside the link.
- **render-optional-popover**: Component MUST conditionally render a popover span when `tip` prop is provided; omit the span when `tip` is undefined.
- **popover-visible-on-focus-or-hover**: Component (via its companion `registry-mark.css`) MUST keep `.pc-rm-tip` visible while the pointer is over the mark or `:focus-visible` is present anywhere within it — including on an interactive element inside the popover — so the popover does not close while a caller tabs into it. The component performs no JS-based focus management of its own; the mechanism is the CSS `:has(:focus-visible)` selector plus a pointer bridge (`.pc-rm-tip::after`).
- **hide-svg-from-accessibility-tree**: Component MUST set `aria-hidden="true"` on the SVG element.
- **support-classname**: Component MUST accept and apply an optional `className` prop, merging it with the required internal class `pc-registry-mark`.
- **memoize-rendering**: Component MUST use React `memo()` to prevent re-renders when props remain unchanged, minimizing re-renders during parent token streaming.

**Host integration (caller obligations)**

- **stable-tip-reference**: Callers MUST pass a stable `tip` reference (e.g. a module-level constant), not an inline JSX expression, so the component's `memo()` wrapper (see **memoize-rendering**) does not re-render on every streamed token.
- **clip-safe-placement**: The host MUST render the mark as a sibling of the chat view inside a `position: relative` wrapper, outside `.persona-chat` (whose `overflow: hidden` would clip the overhang), or set `clip={false}` on an ancestor `ViewportShell`.
## Appearance

- **Size**: SVG viewBox is 5, 1, 14, 22 (width 14 units, height 22 units). Rendered size is controlled by the companion CSS custom property `--pc-rm-size` (default `34px` wide; height follows automatically via `aspect-ratio: 14 / 22`, i.e. `34×53.4px`). A caller override such as `--pc-rm-size: 56px` yields `56×88px`, keeping the artwork's 14:22 ratio at any density.
- **Glyph**: JetBrains Mono @ (weight 400), embedded as precise SVG path, no live font dependency.
- **Star**: Four-pointed concave star (N/E/S/W points, independent x/y radii rx=4.0, ry=6.6, centered at 14.1, 12.2).
- **Glyph fill**: `currentColor` (inherits tint from ancestor).
- **Star fill**: `#c4a35a` — ADH gold, the toolkit's fixed brand-accent color reserved for AI/registry credential marks (hex literal, not a theme token; see Design Decisions).
- **Positioning anchor**: Center point of @ glyph is (12, 12) in viewBox; CSS custom props `--pc-rm-anchor-x: 50%` and `--pc-rm-anchor-y: -50%` place this anchor at host's top-right corner.
- **Popover offset**: Popover (when rendered) displays above the mark, positioned via CSS (not inline).

## States

| State | Appearance change |
|-------|------------------|
| Default | @ glyph and star both visible; no drop-shadow bloom; popover (`.pc-rm-tip`) hidden (`opacity: 0`, `visibility: hidden`) |
| Hover (link) | Companion CSS (`registry-mark.css`) applies `drop-shadow(0 0 4px currentColor)` to the @ glyph and a matching gold bloom (`--pc-rm-adh-gold`) to the star; the popover becomes visible |
| Focus (link, `:focus-visible`) | Same bloom as Hover, plus a `1px` outline on the link (`.pc-rm-link:focus-visible`); the popover becomes visible |
| Focus with popover open | Popover (`.pc-rm-tip`) is visible and keyboard-reachable, and stays open via the companion CSS's `:has(:focus-visible)` selector (plus a pointer bridge, `.pc-rm-tip::after`) even once focus moves onto a link inside it — see **popover-visible-on-focus-or-hover** |

## Accessibility

- **Role**: The underlying `<a>` element provides the link role (implicit).
- **Label**: Required `label` prop is set as the link's `aria-label` attribute (see **accessible-name**), providing an accessible name (e.g., "Visit X's profile on the registry"). Because the link always opens in a new tab, `label` SHOULD also disclose that — see **new-window-disclosure**.
- **SVG accessibility**: SVG has `aria-hidden="true"` to remove it from the accessibility tree; the link's accessible name suffices.
- **Keyboard navigation**: Link is keyboard-reachable; on `:focus-visible` the companion CSS outlines the link and reveals the popover (see States).
- **Popover keyboard access**: When `tip` content is provided, it contains interactive elements (links); the popover stays visible and keyboard-reachable while focus is anywhere within the mark, via the companion CSS's `:has(:focus-visible)` rule — see **popover-visible-on-focus-or-hover**. The component performs no JS-based focus management (no trapping, no programmatic redirects).
- **Minimum touch target**: The target is at least 44×44 CSS px. The default `--pc-rm-size` of `34px` makes the link `34×53.4px`, so its width does not meet the target at the default size and the component adds no padding or hit-area extension; a host must raise `--pc-rm-size` to at least `44px` to conform.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| registry-mark-001 | render-link | `profileUrl="https://registry.example.com/user/alice"` | Link href is `https://registry.example.com/user/alice`, target is `_blank`, rel includes `noopener noreferrer` |
| registry-mark-002 | accessible-name | `label="Visit Alice's profile"` | Link's `aria-label` attribute equals `"Visit Alice's profile"` |
| registry-mark-003 | render-at-glyph | Default render | The `<path class="pc-rm-glyph">` inside the SVG has `d` equal to the `AT_GLYPH` constant in `RegistryMark.tsx` (the JetBrains Mono weight-400 "@" outline) |
| registry-mark-004 | render-star | Default render | The `<path class="pc-rm-gold">` has `d` equal to the `STAR` constant in `RegistryMark.tsx` and `fill="#c4a35a"` |
| registry-mark-005 | tint-glyph-with-currentcolor | Ancestor has `style="color: #ff0000"` | `.pc-rm-glyph` path has `fill="currentColor"`, renders red |
| registry-mark-006 | preserve-anchor-geometry | Default render | The root `<span class="pc-registry-mark">` carries inline style `--pc-rm-anchor-x: 50%; --pc-rm-anchor-y: -50%` and computed `transform: translate(50%, -50%)`; combined with the artwork's own center (viewBox point 12,12), this places the @ glyph's center exactly on the top-right corner of the span's border box |
| registry-mark-007 | render-optional-popover | `tip="Bio text here"` | Span with class `pc-rm-tip` containing the tip content is in DOM |
| registry-mark-008 | render-optional-popover | `tip={undefined}` | No `pc-rm-tip` span in DOM |
| registry-mark-009 | hide-svg-from-accessibility-tree | Default render | SVG has `aria-hidden="true"` |
| registry-mark-010 | support-classname | `className="custom-class"` | Root span has both `pc-registry-mark` and `custom-class` classes |
| registry-mark-011 | memoize-rendering | Parent re-renders with referentially-identical props (including a stable `tip`) | A render-count spy (e.g. a ref incremented inside a thin non-memoized wrapper around `RegistryMark`) shows no additional render |
| registry-mark-012 | popover-visible-on-focus-or-hover | Tab moves focus onto a link rendered inside `tip` | `.pc-rm-tip` computed style shows `visibility: visible` and `opacity: 1` (via the companion CSS `:has(:focus-visible)` rule) |
| registry-mark-013 | stable-tip-reference | Host guidance: parent re-renders passing the same `tip` object reference, then a fresh inline JSX `tip` | No additional render with the stable reference; a render with the inline `tip` (this checks the host contract, not component behavior, and extends vector 011 with a `tip` present) |
| registry-mark-014 | clip-safe-placement | Mark rendered as a sibling of the chat frame inside a `position: relative` ancestor, with no intervening `overflow: hidden` | The mark's `getBoundingClientRect()` extends outside the sibling chat frame's border box at the top-right corner, unclipped |
| registry-mark-015 | tip-sibling-of-link | `tip=<a href="https://example.com">more</a>` | The `pc-rm-tip` span is a child of the root `pc-registry-mark` span and a sibling of `a.pc-rm-link`; no `pc-rm-tip` element is inside the `a.pc-rm-link` |
## Edge Cases

- **Empty or missing label**: If `label` is empty string or undefined, the link will have no accessible name. Implementations SHOULD validate and provide a default or error; this is a source gap.
- **Missing profileUrl**: If `profileUrl` is empty string, the link's href will be empty (current: `<a href="">`). Clicking navigates to the current page. Implementations SHOULD reject empty or invalid URLs.
- **Long tip content**: If `tip` contains very long text or many nested elements, the popover may exceed viewport bounds. The companion `registry-mark.css` caps the popover's width at `240px` but sets no maximum height, overflow handling or viewport containment, so very tall content can extend past the viewport.
- **Tip contains interactive content**: See **popover-visible-on-focus-or-hover** — the popover stays open, and its links stay keyboard-reachable, while focus is anywhere within the mark, via the companion CSS's `:has(:focus-visible)` rule and a pointer bridge (`.pc-rm-tip::after`), not JS-based focus management.
- **Ancestor overflow:hidden**: See **clip-safe-placement** — rendering the mark inside a container with `overflow: hidden` (e.g. `.persona-chat` itself, or an unconfigured `ViewportShell`) clips the popover and the overhanging @.
- **Ancestor with no position context**: The mark's CSS positioning relies on an ancestor with `position: relative` (per source comment). If missing, the mark will position relative to the nearest positioned ancestor (default browser behavior).
- **Concurrent render streaming**: See **stable-tip-reference** — an unstable `tip` (e.g. an inline JSX expression) defeats the component's memoization and causes a re-render on every streamed token.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `profileUrl` | string | (required) | Hyperlink target; persona's profile URL on the registry |
| `label` | string | (required) | Accessible name for the link (e.g., "Visit X's profile on the registry") |
| `tip` | ReactNode | undefined | Optional popover content shown on hover and focus; omit for no popover |
| `className` | string | undefined | Optional CSS class name(s) to merge with internal `pc-registry-mark` class |

## Deep Linking

Not applicable: this component is itself a link, not a deep-link target.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none) | (none) | The `label` prop is the only user-facing string, passed by the caller; the component does not define localization strings |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not respected: the companion `registry-mark.css` applies its hover/focus bloom (`filter` transition) and popover fade/slide transitions unconditionally; neither is gated behind `prefers-reduced-motion` |
| Increase Contrast | Not applicable: the @ glyph and star colors come from `currentColor` (host-controlled) and a fixed hex; the component and its companion CSS define no separate high-contrast styling |
| Differentiate Without Color | Not applicable: the mark conveys no state through color alone — the @ glyph and star are always both present regardless of tint |

## Feature Flags

Not applicable: the component has no feature-flag integration.

## Analytics

Not applicable: the component does not emit analytics events. Event tracking is the responsibility of the host or the link's native click behavior.

## Privacy

- **Data collected**: None. The component itself collects no data.
- **Transmission**: When the link is clicked, the browser navigates to `profileUrl` with `target="_blank"`; transmission is handled by the browser and the target server.
- **Retention**: N/A — no data is retained by the component.

## Logging

Not applicable: the component does not emit debug or error logs.

## Platform Notes

- **React/Web**: Renders in `packages/web/packages/chat/src/components/RegistryMark.tsx`. Props: `profileUrl`, `label`, `tip`, `className`. Memoized export. The @ glyph, the AI star, and the corner-anchor math all derive from the single geometry block at the top of the file (`VIEW`, `AT_CENTER`, `AT_GLYPH`, `STAR`) — the canonical source every other platform draws from (see Design Decisions). Styles live in the companion `css/components/registry-mark.css`, which also owns the hover/focus bloom and the popover reveal; it ships with the mark and is opt-in per host, not a generic host stylesheet.
- **SwiftUI**: Draw the @ glyph and the AI star as a `Shape` built from the same path data as `RegistryMark.tsx` (`AT_GLYPH`/`STAR`), never from a system font. Tint the @ with `.foregroundStyle`/`.foregroundColor` (inherits like `currentColor`); fill the star with the ADH gold literal. Position with `.offset` or alignment so the shape's own (12,12) center lands on the host's top-right corner, matching **preserve-anchor-geometry**. Provide an optional popover or overlay for `tip` content, visible on hover/focus.
- **Compose**: Draw the @ glyph and the AI star as a `Path` in a `Canvas`/custom `Painter` built from the same path data as `RegistryMark.tsx` — not `Text`, since the glyph is artwork, not a font run. Tint the @ with `LocalContentColor.current`; fill the star with the ADH gold literal. Position in a `Box` with `Alignment.TopEnd`, offset so the path's own (12,12) center lands on the corner. Optional `Popup` for `tip` content, visible on hover/focus.
- **AppKit / UIKit**: Render the @ glyph and star as a custom `NSView` (macOS) or `UIView` (iOS), drawing both with Core Graphics (`CGPath`) built from the same path data as `RegistryMark.tsx`. Tint the @ with the view's `tintColor`; fill the star with the ADH gold literal. Position in the host's top-right using Auto Layout or frame geometry so the artwork's (12,12) center lands on the corner. Wrap in an `NSButton`/`UIButton` with target/action linking to `profileUrl`. Optional popover (macOS `NSPopover`) or `UIPopoverPresentationController` (iPad) for `tip` content.
- **WinUI 3**: Render the @ glyph as a `Path` in XAML (or a custom control with `CompositionVisuals` for performance) built from the same path data as `RegistryMark.tsx`; overlay a second `Path` for the star, filled with the ADH gold literal. Tint the @ using the `Foreground` brush (inherited from ancestor). Position using `Grid.Column`/`VerticalAlignment="Top"`/`HorizontalAlignment="Right"` with margin so the artwork's (12,12) center lands on the corner. Wrap in a `HyperlinkButton` with `NavigateUri` set to `profileUrl`. Optional `Flyout` for `tip` content, with `Placement="Top"`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/components/RegistryMark.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: The @ is embedded as an SVG path (the exact JetBrains Mono weight-400 outline) rather than rendered as live `<text>` with a font dependency.
**Rationale**: This ensures the mark carries its own shape and never depends on the host having the font loaded, guaranteeing consistent rendering across environments. The outline comes from JetBrains Mono, which is licensed under the SIL Open Font License 1.1 (see `references`).
**Approved**: pending

**Decision**: The star is filled with the ADH gold hex literal `#c4a35a` rather than a CSS variable or theme token.
**Rationale**: The registry accent must not dissolve into the host skin and must remain recognizable and distinct regardless of the host's color theme. The same constant is injected as the `--pc-rm-adh-gold` custom property on the root span, which the companion CSS reads for the star's hover/focus bloom (with the hex as a CSS-only fallback), so the SVG fill and the bloom share one source.
**Approved**: pending

**Decision**: The @ glyph is tinted by `fill="currentColor"` (inherited from ancestor CSS `color`), not a dedicated color prop.
**Rationale**: This allows the mark to adapt to the persona's hue or registry house color without requiring a prop, keeping the component's prop surface minimal.
**Approved**: pending

**Decision**: The component is wrapped in React `memo()`.
**Rationale**: The host chat re-renders on every streamed token, but the mark's props are static after mount; memoization prevents unnecessary re-renders as long as callers pass a stable `tip` (see **stable-tip-reference**).
**Approved**: pending

**Decision**: The star uses independent x/y radii (`rx=4.0`, `ry=6.6`) rather than a uniform radius.
**Rationale**: This lets it fill the @ counter's tall-narrow opening without spilling past the glyph into the ring, maintaining visual balance and legibility.
**Approved**: pending

**Decision**: The `tip` is rendered as a plain conditional `<span className="pc-rm-tip">`, styled entirely by the companion `registry-mark.css`, rather than composed from the toolkit's own `@adh-sdk/popover` (`InlinePopover`).
**Rationale**: `InlinePopover` is a JS-driven, click-to-toggle popover (title + description + action links) anchored to interactive content; this mark needs a passive, CSS-only hover/focus tooltip with zero JS and zero added client bundle, so a static credential mark stays static. The two have a different interaction model, trigger, and accessibility timing — sharing one abstraction would bend both out of shape, so they are kept separate on purpose (see `registry-mark.css`).
**Approved**: pending

**Decision**: Every platform port draws the @ glyph and the AI star from the exact geometry defined once in `RegistryMark.tsx` (`AT_GLYPH`, `STAR`, `VIEW`, `AT_CENTER`) — never re-derived or hand-traced independently per platform.
**Rationale**: The glyph outline and the anchor math are precision-sensitive (see **preserve-anchor-geometry**); an independently re-derived path on another platform risks visual drift from the canonical mark. Single-sourcing the path data guarantees a pixel-identical mark everywhere.
**Approved**: pending

**Decision**: Record the absence of `prefers-reduced-motion` gating on the hover/focus bloom and popover transitions as accepted debt for now.
**Rationale**: The companion `registry-mark.css` applies the `filter` transition and the popover fade/slide unconditionally, and Compliance records reduced-motion as failed; whether to gate them in the mark's CSS or leave it to the host is not yet settled.
**Approved**: pending

**Decision**: Record the fixed `11px` popover text, which does not scale with the user's text size, as accepted debt for now.
**Rationale**: `.pc-rm-tip` sets `font-size: 11px` in the companion CSS, and Compliance records dynamic-type support as failed; switching to `rem` units is not yet decided.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The `passed` statuses rest on the native `<a>`/`aria-hidden`/`aria-label` markup in `RegistryMark.tsx` and on it defining no strings of its own; screen-reader-support and keyboard-navigable are partial because the popover is not associated with the link through `aria-describedby`, and the source has no way to dismiss the hover/focus popover (for example with Escape); the `failed` and `partial` statuses rest on the companion `registry-mark.css`, whose hover/focus bloom and popover transitions are not gated behind `prefers-reduced-motion`, whose `.pc-rm-tip` text is fixed at `11px` (not scalable), and whose tip/star colors depend on the host-supplied `currentColor`, so contrast cannot be verified in isolation. `RegistryMark.tsx` renders SVG geometry over props with no business logic or data access (separation-of-concerns passed); `RegistryMark.test.tsx` directly exercises the link/label, the tip popover content, the no-tip case, and the className/custom-property merge (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Lint fixes: added the tip-sibling-of-link requirement and vector, moved the two host obligations under a host-integration heading, replaced copied SVG paths in vectors with the AT_GLYPH and STAR constants, added JetBrains Mono and OFL references, explained the --pc-rm-adh-gold variable, recorded reduced-motion and fixed-text-size debt as Decisions, corrected the touch-target unit and default, downgraded screen-reader-support and keyboard-navigable to partial, and renamed the React/Web note. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; promoted the stable-tip, clip-safe-placement, and popover-focus obligations out of Edge Cases into named Behavioral Requirements; reworked Design Decisions into Decision/Rationale/Approved form and added a single-sourced-path-data decision with a grounded rationale for not using `@adh-sdk/popover`; fixed Platform Notes so every port draws from the same path data instead of a system font; corrected States and Accessibility Options to match the companion CSS's actual hover/focus/motion behavior; rebuilt Compliance with real catalog checks; inlined exact path data in the glyph/star vectors and reworded the anchor and memoization vectors to assert observable outcomes; added `depends-on`/`related` cross-references; defined ADH gold and AI star on first use; unquoted `modified`. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from source analysis |
