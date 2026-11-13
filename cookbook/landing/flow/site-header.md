---
id: 93e8b186-b7a6-41c5-90a8-21b67a47ef72
title: "Site Header"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A flow page header with wordmark, optional navigation, and optional call-to-action that scrolls away with page content."
platforms:
  - typescript
  - web
tags:
  - header
  - navigation
  - responsive
  - flow-page
depends-on:
  - 4d2b7231-1235-49e9-8b7d-1e7507c6eba7
related: []
references: []
approved-by: ""
approved-date: ""
---

# Site Header

## Overview

A header component for flow pages that displays a wordmark, optional inline navigation, and optional call-to-action. The header scrolls away with page content, unlike fixed headers. Below the breakpoint, the inline navigation is hidden and navigation is provided through a drawer. The component manages the state of its drawer child when the viewport crosses the breakpoint.

## Behavioral Requirements

- **render-header**: Component MUST render a `<header>` element containing all provided content.
- **render-brand**: Component MUST render the `brand` prop as a child of a `.lp-site-brand` div if provided.
- **render-bar-nav**: Component MUST render navigation links from `barLinks` (or `links` if `barLinks` is not provided) in a `<nav>` element with `aria-label` defaulting to "Site" whenever `bar` is `'nav'`.
- **bar-nav-visible-at-breakpoint**: The `<nav>` element rendered under **render-bar-nav** MUST be visible at the breakpoint or wider and hidden below it via a CSS media query, while remaining present in the DOM at every width.
- **render-action**: Component MUST render the `action` prop in a `.lp-site-action` div if provided.
- **hide-bar-nav**: Component MUST NOT render the inline navigation bar when `bar` is `'drawer'` at any viewport width.
- **real-anchors**: Component MUST render navigation links as real `<a>` elements with `href` attributes, so they remain discoverable to crawlers and reachable through an assistive-technology link rotor even when **bar-nav-visible-at-breakpoint**'s media query hides them below the breakpoint.
- **drawer-visibility**: Component MUST always mount a `NavChrome` component in a drawer wrapper; the wrapper is hidden via CSS at the breakpoint or wider when `bar` is `'nav'`, and stays visible at every width when `bar` is `'drawer'`.
- **omit-brand-from-drawer**: Component MUST NOT pass the `brand` prop to `NavChrome` in the drawer.
- **reset-drawer-state**: Component MUST remount `NavChrome` when the drawer wrapper transitions from visible to hidden (the viewport growing from narrower than the breakpoint to at-or-wider than it), to reset `NavChrome`'s internal state.
- **pass-full-links**: Component MUST always pass the complete `links` array to `NavChrome`, regardless of which links are shown in the bar.
- **support-bar-prop**: Component MUST accept a `bar` prop that is either `'nav'` (default) or `'drawer'`.

## Appearance

- **Breakpoint**: 62rem — referred to below as *the breakpoint*.
- **Header layout**: Horizontal flexbox row containing brand, navigation, and action.
- **Bar height**: Determined by child component heights (brand, nav links, action).
- **Navigation alignment**: At or above the breakpoint with `bar='nav'`, the brand sits at the left end while the navigation links and the action bunch together at the right end — `flow.css` pushes the nav flush against the action with `margin-left: auto`, not to the bar's center. Below the breakpoint (where the inline nav and action are hidden) and at every width when `bar='drawer'`, the brand is centered in the bar instead.
- **Link styling**: The inline navigation links are `SiteHeader`'s own `<a>` elements (a sibling of the `NavChrome` wrapper, not rendered through it), so they cannot inherit `NavChrome`'s styling. `flow.css` gives them their own styling directly: `color: var(--lp-ink-dim, #a0a0a0)` at `0.88rem`, no underline, brightening to `var(--lp-ink, #ededed)` on hover with a `0.18s` color transition.
- **Drawer styling**: Inherits from NavChrome.
- **Scrolling**: Header scrolls away with page content (not fixed).
- **Responsive layout**: At the breakpoint, the inline navigation becomes visible via a CSS media query; below it, the `<nav>` stays in the DOM but is hidden by that same query (not removed) under `bar='nav'`.

## States

| State | Appearance change |
|-------|------------------|
| Default | Brand, nav links, action visible at wide viewport; drawer shown at narrow viewport |
| bar='drawer' | Brand visible, nav links never shown, burger always visible |
| Viewport narrower than the breakpoint | Inline nav bar hidden, drawer visible |
| Viewport at or wider than the breakpoint (bar='nav') | Inline nav bar visible, drawer wrapper hidden |

## Accessibility

- **Header role**: Component renders a semantic `<header>` element.
- **Navigation label**: The `<nav>` element inside the bar MUST have an `aria-label` attribute, defaulting to "Site" unless overridden via `navLabel` prop from `NavChromeProps`.
- **Link announcements**: Navigation links are real `<a>` elements, allowing screen readers to discover them.
- **Duplicate prevention**: Navigation links in the drawer are not duplicated in the bar under `bar='drawer'`, avoiding duplicate link destinations that assistive technology would discover.
- **Drawer management**: Focus trap and `inert` handling are delegated to `NavChrome`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-header-001 | render-header | `{ brand: <div>Logo</div>, links: [{ href: '/', label: 'Home' }], bar: 'nav' }` | Header element renders with brand div visible |
| site-header-002 | render-bar-nav, bar-nav-visible-at-breakpoint | `{ barLinks: [{ href: '/', label: 'Home' }], links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport at the breakpoint or wider | Nav element with aria-label="Site" is present and visible, with links rendered as anchors |
| site-header-002b | render-bar-nav, bar-nav-visible-at-breakpoint | Same props as site-header-002, viewport narrower than the breakpoint | Nav element is present in the DOM (queryable) but not visible (`display: none`) |
| site-header-003 | render-action | `{ links: [{ href: '/', label: 'Home' }], action: <button>Sign up</button>, bar: 'nav' }`, viewport at the breakpoint or wider | Action div renders with button visible |
| site-header-004 | hide-bar-nav, drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'drawer' }` at all widths | Inline nav element does not render; drawer renders at all widths |
| site-header-005 | real-anchors | `{ links: [{ href: '/about', label: 'About' }], barLinks: [{ href: '/about', label: 'About' }] }` | Each link renders as `<a href="/about">About</a>` |
| site-header-006 | omit-brand-from-drawer | `{ brand: <div>Logo</div>, links: [{ href: '/', label: 'Home' }] }` | NavChrome receives no brand prop |
| site-header-007 | reset-drawer-state | Viewport resizes from narrower than the breakpoint to at-or-wider than it, with the drawer open | NavChrome remounts, drawer state resets |
| site-header-008 | pass-full-links | `{ barLinks: [short links], links: [all links] }`, viewport at the breakpoint or wider | NavChrome receives full `links` array; drawer shows all links |
| site-header-009a | support-bar-prop | `{ links: [{ href: '/', label: 'Home' }], bar: 'drawer' }` | Burger shown at every width; inline nav hidden |
| site-header-009b | support-bar-prop | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }` (default), viewport at the breakpoint or wider | Inline nav shown |
| site-header-010 | drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport narrower than the breakpoint | Drawer wrapper is present and visible (not `display: none`) |
| site-header-011 | drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport at the breakpoint or wider | Drawer wrapper remains in the DOM but is hidden via CSS (`display: none`) |

## Edge Cases

- **No brand prop**: Component renders the header without a brand div.
- **No links provided**: NavChrome and the nav bar receive an empty array; the component still renders but shows no navigation items.
- **No action prop**: The action div is not rendered.
- **Viewport resize across the breakpoint with the drawer open**: A `ResizeObserver` on the drawer wrapper detects the transition from visible to hidden (narrow to wide, under `bar='nav'`) and remounts `NavChrome` via a generation-counter increment, clearing its internal open state. The remount fires only on that visible-to-hidden transition, not when the wrapper is already hidden. See **reset-drawer-state**.
- **bar='drawer' never triggers a remount**: The drawer wrapper is never hidden in this mode, so the visible-to-hidden transition the observer watches for never happens. See **drawer-visibility**.
- **barLinks defaults to links**: If `barLinks` is not provided, it defaults to `links`, so the same links array is used in both the bar and the drawer.
- **NavChrome state persistence**: `NavChrome` owns its open state and exposes no public API to close it; remounting is the only way to reset that state, which is why the generation counter is used.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `brand` | `ReactNode` | `undefined` | Wordmark or branding element rendered in the header bar |
| `links` | `NavChromeProps['links']` | Required | Array of navigation links; always passed to the drawer |
| `barLinks` | `NavChromeProps['links']` | `links` | Array of navigation links for the inline bar only (at the breakpoint or wider); shorter than the full list, typically |
| `action` | `ReactNode` | `undefined` | Call-to-action element pinned to the right of the bar (visible at the breakpoint or wider only) |
| `bar` | `'nav' \| 'drawer'` | `'nav'` | Navigation mode: `'nav'` shows the inline links at the breakpoint or wider; `'drawer'` keeps the burger at every width |
| `footer` | `NavChromeProps['footer']` | `undefined` (no footer rendered) | Footer content passed through to `NavChrome`'s drawer |
| `navLabel` | `NavChromeProps['navLabel']` | `'Site'` | `aria-label` for the inline `<nav>` element, and passed through to `NavChrome`'s own drawer `<nav>` |

## Deep Linking

Not applicable: SiteHeader is a container component that does not define deep linking behavior. Deep linking is handled by child components (NavChrome, links) or the page that hosts the header.

## Localization

Not applicable: SiteHeader does not render any text content of its own. All text is provided via props (brand, links, action, navLabel) by the host application.

## Accessibility Options

- **Reduce Motion**: Not applicable; SiteHeader does not animate. Scrolling behavior is provided by the browser. NavChrome handles Reduce Motion for its drawer animations.
- **Increase Contrast**: SiteHeader has no Increase-Contrast-specific behavior, but it is not colorless: `flow.css` sets the inline nav links' own text color and hover color directly (see **Link styling**), rather than inheriting from `NavChrome` or the parent.
- **Differentiate Without Color**: Not applicable; SiteHeader does not use color as a sole means of conveying information.

## Feature Flags

Not applicable: SiteHeader is a presentation component and does not implement feature flags.

## Analytics

Not applicable: SiteHeader is a container component and does not emit analytics events. Analytics are handled by child components (NavChrome, links) or the page.

## Privacy

Not applicable: SiteHeader does not collect, store, or transmit any personal data.

## Logging

Not applicable: SiteHeader does not emit logs.

## Platform Notes

- **TypeScript/Web**: Source files are `SiteHeader.tsx` and `flow.css`. The breakpoint is 62rem, enforced by a CSS media query in `flow.css` (not JavaScript). A `ResizeObserver` on the wrapper element observes the CSS display decision rather than duplicating the breakpoint condition in JavaScript. The component renders real `<a>` anchor elements for navigation links to preserve crawler discoverability and assistive-technology navigation.
- **SwiftUI**: Reimplement natively — do not wrap the web component. Use a `ScrollView` so the header scrolls away with the page content, matching the source's non-fixed behavior. Switch between the inline nav row and the drawer based on `horizontalSizeClass` (compact maps to the drawer, regular maps to the inline nav), mirroring the breakpoint's role in the web source.
- **Compose**: Map the web layout to a `Column` with a `Row` header. Use `currentWindowAdaptiveInfo()` / `WindowSizeClass` to determine the available width in dp and pick a breakpoint equivalent to 62rem (there is no `62.rem` unit in Compose); conditional rendering of the nav row replaces the CSS media query. The drawer behavior maps to Compose's `ModalNavigationDrawer`.
- **AppKit / UIKit**: Reimplement natively — do not embed a `WKWebView`. Use `NSStackView` (macOS) or `UIStackView` (iOS) for the horizontal layout. On iOS, use `registerForTraitChanges` to react to size-class changes (`traitCollectionDidChange` is deprecated); on macOS, observe the view's frame or the window's resize notifications, since there is no size-class API on that platform. Manage drawer state with a property observer or a Combine published property that responds to size changes.
- **WinUI 3**: Use a `StackPanel` with `Orientation="Horizontal"` for the header row. Responsive layout uses `VisualStateManager` with an `AdaptiveTrigger` whose `MinWindowWidth` is set in effective pixels (WinUI has no rem unit) to the breakpoint's equivalent. The drawer uses `NavigationView` or a custom `UserControl` with a `Popup` for modal behavior.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/flow/SiteHeader.tsx` | unverified |

## Design Decisions

**Decision**: The header scrolls away with page content rather than staying fixed.
**Rationale**: Flow pages have varied band backgrounds, and a fixed header would have to render opaque over all of them to stay legible, which would permanently cover the diagonal-seam geometry the layout is built on. A header that scrolls away with the hero costs a reader one flick back to the top and keeps the seams intact.
**Approved**: pending

**Decision**: Use a `ResizeObserver` on the drawer wrapper element instead of duplicating the breakpoint with `matchMedia` in JavaScript.
**Rationale**: The wrapper's visibility is decided by the CSS media query in `flow.css`; observing the wrapper's bounding box lets the observer read that decision rather than restating the breakpoint a second time in JavaScript, keeping the CSS as the single source of truth if the breakpoint value changes.
**Approved**: pending

**Decision**: Remount `NavChrome` (via a generation counter) only on the narrow-to-wide transition, when the drawer wrapper goes from visible to hidden.
**Rationale**: `NavChrome` owns its open state internally and exposes no way to close it. Left open across a resize past the breakpoint, its Tab-trap listener would stay attached to a `display: none` subtree and block Tab on the rest of the page; remounting on the way out drops the listener with the component. See **reset-drawer-state**.
**Approved**: pending

**Decision**: `brand` is never passed to `NavChrome` in the drawer.
**Rationale**: The header already displays the brand; rendering it a second time inside the drawer's own bar would draw a duplicate wordmark.
**Approved**: pending

**Decision**: Navigation links are real `<a>` elements that stay in the DOM even where CSS hides them, rather than being removed or duplicated.
**Rationale**: Below the breakpoint, the bar's `<nav>` stays in the DOM and is hidden purely by the CSS media query (see **bar-nav-visible-at-breakpoint**), so a crawler or an assistive-technology link rotor can still discover the destinations. Under `bar='drawer'`, the links are not rendered in the bar at all — a JSX conditional, not a CSS hide — so the drawer's copy is the only destination discovered, avoiding duplicate in-page links.
**Approved**: pending

**Decision**: `barLinks` is optional and defaults to `links`.
**Rationale**: A host with few enough links to fit both the bar and the drawer need not supply two lists; a host with many sections can pass a shorter `barLinks` for the bar while the drawer still receives the full `links` array (see **pass-full-links**).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `SiteHeader.tsx` rendering a semantic `<header>` element, a `<nav>` element with an `aria-label` (defaulting to `'Site'`), and real `<a>` anchors for every navigation link — native landmarks and native anchors are screen-reader-discoverable and keyboard-focusable without additional ARIA. `separation-of-concerns` passes because `SiteHeader` composes the existing `NavChrome` for the drawer/burger behavior and only adds its own bar/wordmark/action layout, rather than reimplementing navigation chrome. `unit-test-coverage` passes because `site-header.test.tsx` imports `SiteHeader` directly and asserts on brand/nav/action rendering, the `bar='nav'`/`'drawer'` variants, and the breakpoint-driven centering and scroll behavior.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from SiteHeader.tsx web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; merged the two drawer-mounting requirements and split bar-links rendering from visibility; fixed the remount-direction contradiction and vector 007 to match; reworded real-anchors and Design Decision 5 to match the CSS-hiding behavior; defined the breakpoint once and referenced it by name elsewhere; dropped source-code citations from Edge Cases; split test vector 009 and added missing `links` inputs and breakpoint coverage; replaced Compliance with an accessibility table; converted Design Decisions to Decision/Rationale/Approved form and genericized Design Decision 1; corrected the Compose, AppKit/UIKit, WinUI, and SwiftUI platform notes and removed the web-embedding options; added `tags` and a `depends-on` entry for NavChrome; fixed `hide-bar-nav`'s RFC 2119 casing. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Corrected nav alignment/link-styling/Increase-Contrast per flow.css (right-packed, colored links). |
