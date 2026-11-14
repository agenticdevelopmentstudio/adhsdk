---
id: f8e3d2a1-4c9b-4d7e-8f2b-a5c3e7b1d4f6
title: "Registry Mark"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
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
references: []
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
- **render-optional-popover**: Component MUST conditionally render a popover span when `tip` prop is provided; omit the span when `tip` is undefined.
- **popover-visible-on-focus-or-hover**: Component (via its companion `registry-mark.css`) MUST keep `.pc-rm-tip` visible while the pointer is over the mark or `:focus-visible` is present anywhere within it — including on an interactive element inside the popover — so the popover does not close while a caller tabs into it. The component performs no JS-based focus management of its own; the mechanism is the CSS `:has(:focus-visible)` selector plus a pointer bridge (`.pc-rm-tip::after`).
- **hide-svg-from-accessibility-tree**: Component MUST set `aria-hidden="true"` on the SVG element.
- **support-classname**: Component MUST accept and apply an optional `className` prop, merging it with the required internal class `pc-registry-mark`.
- **memoize-rendering**: Component MUST use React `memo()` to prevent re-renders when props remain unchanged, minimizing re-renders during parent token streaming.
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
- **Minimum touch target**: Parent container should ensure the link is at least 44×44pt (this is a constraint on the host layout, not enforced by the component).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| registry-mark-001 | render-link | `profileUrl="https://registry.example.com/user/alice"` | Link href is `https://registry.example.com/user/alice`, target is `_blank`, rel includes `noopener noreferrer` |
| registry-mark-002 | accessible-name | `label="Visit Alice's profile"` | Link's `aria-label` attribute equals `"Visit Alice's profile"` |
| registry-mark-003 | render-at-glyph | Default render | The `<path class="pc-rm-glyph">` inside the SVG has `d="M12.49 22Q10.64 22 9.27 21.23Q7.9 20.46 7.15 19.03Q6.4 17.61 6.4 15.7V8.3Q6.4 6.35 7.11 4.93Q7.82 3.52 9.13 2.76Q10.45 2 12.27 2Q13.92 2 15.12 2.64Q16.32 3.28 16.96 4.48Q17.6 5.67 17.6 7.33V16.67H16.05V15.48H15.45L15.86 15.04Q15.86 15.87 15.23 16.38Q14.6 16.89 13.55 16.89Q12.14 16.89 11.39 16.03Q10.64 15.17 10.64 13.52V10.91Q10.64 9.26 11.39 8.4Q12.14 7.54 13.55 7.54Q14.6 7.54 15.23 8.05Q15.86 8.57 15.86 9.41L15.55 8.96H16.08L15.86 7.43V7.33Q15.86 6.09 15.45 5.24Q15.03 4.39 14.24 3.96Q13.45 3.52 12.27 3.52Q10.32 3.52 9.23 4.78Q8.14 6.04 8.14 8.3V15.7Q8.14 17.87 9.3 19.12Q10.47 20.37 12.49 20.37H14.01V22ZM14.12 15.52Q15.01 15.52 15.43 14.98Q15.86 14.43 15.86 13.3V10.89Q15.86 9.87 15.43 9.39Q15.01 8.91 14.12 8.91Q13.25 8.91 12.82 9.4Q12.38 9.89 12.38 10.91V13.52Q12.38 14.54 12.82 15.03Q13.25 15.52 14.12 15.52Z"` — the exact JetBrains Mono weight-400 "@" outline from `RegistryMark.tsx` |
| registry-mark-004 | render-star | Default render | The `<path class="pc-rm-gold">` has `d="M14.10,5.60 Q15.22,10.35 18.10,12.20 Q15.22,14.05 14.10,18.80 Q12.98,14.05 10.10,12.20 Q12.98,10.35 14.10,5.60 Z"` and `fill="#c4a35a"` |
| registry-mark-005 | tint-glyph-with-currentcolor | Ancestor has `style="color: #ff0000"` | `.pc-rm-glyph` path has `fill="currentColor"`, renders red |
| registry-mark-006 | preserve-anchor-geometry | Default render | The root `<span class="pc-registry-mark">` carries inline style `--pc-rm-anchor-x: 50%; --pc-rm-anchor-y: -50%` and computed `transform: translate(50%, -50%)`; combined with the artwork's own center (viewBox point 12,12), this places the @ glyph's center exactly on the top-right corner of the span's border box |
| registry-mark-007 | render-optional-popover | `tip="Bio text here"` | Span with class `pc-rm-tip` containing the tip content is in DOM |
| registry-mark-008 | render-optional-popover | `tip={undefined}` | No `pc-rm-tip` span in DOM |
| registry-mark-009 | hide-svg-from-accessibility-tree | Default render | SVG has `aria-hidden="true"` |
| registry-mark-010 | support-classname | `className="custom-class"` | Root span has both `pc-registry-mark` and `custom-class` classes |
| registry-mark-011 | memoize-rendering | Parent re-renders with referentially-identical props (including a stable `tip`) | A render-count spy (e.g. a ref incremented inside a thin non-memoized wrapper around `RegistryMark`) shows no additional render |
| registry-mark-012 | popover-visible-on-focus-or-hover | Tab moves focus onto a link rendered inside `tip` | `.pc-rm-tip` computed style shows `visibility: visible` and `opacity: 1` (via the companion CSS `:has(:focus-visible)` rule) |
| registry-mark-013 | stable-tip-reference | Parent re-renders passing the same `tip` object reference and otherwise-identical props | A render-count spy shows no additional render (same mechanism as **memoize-rendering**, exercised with a `tip` present) |
| registry-mark-014 | clip-safe-placement | Mark rendered as a sibling of the chat frame inside a `position: relative` ancestor, with no intervening `overflow: hidden` | The mark's `getBoundingClientRect()` extends outside the sibling chat frame's border box at the top-right corner, unclipped |

## Edge Cases

- **Empty or missing label**: If `label` is empty string or undefined, the link will have no accessible name. Implementations SHOULD validate and provide a default or error; this is a source gap.
- **Missing profileUrl**: If `profileUrl` is empty string, the link's href will be empty (current: `<a href="">`). Clicking navigates to the current page. Implementations SHOULD reject empty or invalid URLs.
- **Long tip content**: If `tip` contains very long text or many nested elements, the popover may exceed viewport bounds. CSS in host's popover-bloom styling SHOULD include overflow handling (this component does not constrain tip size).
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

- **Source (React/Web)**: Renders in `packages/web/packages/chat/src/components/RegistryMark.tsx`. Props: `profileUrl`, `label`, `tip`, `className`. Memoized export. The @ glyph, the AI star, and the corner-anchor math all derive from the single geometry block at the top of the file (`VIEW`, `AT_CENTER`, `AT_GLYPH`, `STAR`) — the canonical source every other platform draws from (see Design Decisions). Styles live in the companion `css/components/registry-mark.css`, which also owns the hover/focus bloom and the popover reveal; it ships with the mark and is opt-in per host, not a generic host stylesheet.
- **SwiftUI**: Draw the @ glyph and the AI star as a `Shape` built from the same path data as `RegistryMark.tsx` (`AT_GLYPH`/`STAR`), never from a system font. Tint the @ with `.foregroundStyle`/`.foregroundColor` (inherits like `currentColor`); fill the star with the ADH gold literal. Position with `.offset` or alignment so the shape's own (12,12) center lands on the host's top-right corner, matching **preserve-anchor-geometry**. Provide an optional popover or overlay for `tip` content, visible on hover/focus.
- **Compose**: Draw the @ glyph and the AI star as a `Path` in a `Canvas`/custom `Painter` built from the same path data as `RegistryMark.tsx` — not `Text`, since the glyph is artwork, not a font run. Tint the @ with `LocalContentColor.current`; fill the star with the ADH gold literal. Position in a `Box` with `Alignment.TopEnd`, offset so the path's own (12,12) center lands on the corner. Optional `Popup` for `tip` content, visible on hover/focus.
- **AppKit / UIKit**: Render the @ glyph and star as a custom `NSView` (macOS) or `UIView` (iOS), drawing both with Core Graphics (`CGPath`) built from the same path data as `RegistryMark.tsx`. Tint the @ with the view's `tintColor`; fill the star with the ADH gold literal. Position in the host's top-right using Auto Layout or frame geometry so the artwork's (12,12) center lands on the corner. Wrap in an `NSButton`/`UIButton` with target/action linking to `profileUrl`. Optional popover (macOS `NSPopover`) or `UIPopoverPresentationController` (iPad) for `tip` content.
- **WinUI 3**: Render the @ glyph as a `Path` in XAML (or a custom control with `CompositionVisuals` for performance) built from the same path data as `RegistryMark.tsx`; overlay a second `Path` for the star, filled with the ADH gold literal. Tint the @ using the `Foreground` brush (inherited from ancestor). Position using `Grid.Column`/`VerticalAlignment="Top"`/`HorizontalAlignment="Right"` with margin so the artwork's (12,12) center lands on the corner. Wrap in a `HyperlinkButton` with `NavigateUri` set to `profileUrl`. Optional `Flyout` for `tip` content, with `Placement="Top"`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/components/RegistryMark.tsx` | unverified |

## Design Decisions

**Decision**: The @ is embedded as an SVG path (the exact JetBrains Mono weight-400 outline) rather than rendered as live `<text>` with a font dependency.
**Rationale**: This ensures the mark carries its own shape and never depends on the host having the font loaded, guaranteeing consistent rendering across environments.
**Approved**: pending

**Decision**: The star is filled with the ADH gold hex literal `#c4a35a` rather than a CSS variable or theme token.
**Rationale**: The registry accent must not dissolve into the host skin and must remain recognizable and distinct regardless of the host's color theme.
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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The `passed` statuses rest on the native `<a>`/`aria-hidden`/`aria-label` markup in `RegistryMark.tsx` and on it defining no strings of its own; the `failed` and `partial` statuses rest on the companion `registry-mark.css`, whose hover/focus bloom and popover transitions are not gated behind `prefers-reduced-motion`, whose `.pc-rm-tip` text is fixed at `11px` (not scalable), and whose tip/star colors depend on the host-supplied `currentColor`, so contrast cannot be verified in isolation. `RegistryMark.tsx` renders SVG geometry over props with no business logic or data access (separation-of-concerns passed); `RegistryMark.test.tsx` directly exercises the link/label, the tip popover content, the no-tip case, and the className/custom-property merge (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; promoted the stable-tip, clip-safe-placement, and popover-focus obligations out of Edge Cases into named Behavioral Requirements; reworked Design Decisions into Decision/Rationale/Approved form and added a single-sourced-path-data decision with a grounded rationale for not using `@adh-sdk/popover`; fixed Platform Notes so every port draws from the same path data instead of a system font; corrected States and Accessibility Options to match the companion CSS's actual hover/focus/motion behavior; rebuilt Compliance with real catalog checks; inlined exact path data in the glyph/star vectors and reworded the anchor and memoization vectors to assert observable outcomes; added `depends-on`/`related` cross-references; defined ADH gold and AI star on first use; unquoted `modified`. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from source analysis |
