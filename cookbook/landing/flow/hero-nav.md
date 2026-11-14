---
id: 2f844d32-25e5-4140-b3b0-045d21728a6f
title: "HeroNav"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "A page's table of contents as one centred line of plain anchors under a hero, separated by drawn bars and swept once by a text lens."
platforms:
  - typescript
  - web
tags:
  - navigation
  - landing
  - links
  - animation
depends-on: []
related:
  - f8cbc576-a5ef-4e8c-90a0-7d0712b24b72
  - b5b27bc2-99b2-469e-9dd4-e446b0157444
references: []
approved-by: ""
approved-date: ""
---

# HeroNav

## Overview

HeroNav is the line of words under a hero's name: a page's table of contents rendered as one centred row of links. The host passes the rows (the doc comment suggests `indexRows(page)`, so a row cannot name a band the page does not have or miss one it does) and an accessible name for the `nav`. Each row is a plain anchor with no click handler, so the hrefs work the same with JavaScript off. A drawn `|` separator sits between adjacent links. The only script is a text lens (`useTextLens` from `@adh-sdk/textlens`) that is started once, two seconds after mount, and then sweeps a moving highlight back and forth along the links indefinitely (8000 ms per pass, the lens default): glyphs within 55px of the highlight are tinted from the colour token `--lp-ink-dim` toward `--lp-accent-bright`, scaled up to 125% and blurred up to 0.35px. The lens replaces each link's text with one span per character and holds still while the pointer is over a link. The component is a client component (`'use client'`) and ships from the client barrel only. `flow.css` styles it under `.lp-hero-nav`.

## Behavioral Requirements

- **nav-landmark**: The component MUST render a single `nav` element with the class `lp-hero-nav`.
- **nav-label**: The component MUST set the `nav` element's `aria-label` to the `label` prop.
- **link-per-row**: The component MUST render one `a` element with the class `lp-hero-nav__link` for each entry in `rows`.
- **link-order**: The component MUST render the links in the order of `rows`.
- **link-href**: The component MUST set each link's `href` to its row's `href`.
- **link-text**: The component MUST render each row's `label` as its link's text.
- **plain-anchors**: The component MUST NOT attach a click handler to a link, so navigation does not depend on JavaScript.
- **separator-between**: The component MUST render one `span` with the class `lp-hero-nav__sep` and the text `|` before every link except the first.
- **separator-hidden**: The component MUST set `aria-hidden="true"` on each separator.
- **no-edge-separators**: The component MUST NOT render a separator before the first link or after the last link, so the nav's first and last children are both links.
- **separator-drawn**: The component SHOULD draw separators as elements rather than as borders, because a border would also draw at the ends of a wrapped line.
- **lens-selector**: The component MUST bind the text lens to the nav element with the selector `.lp-hero-nav__link`.
- **lens-delay**: The component MUST start the lens sweep 2000 ms after mount.
- **lens-colors**: The component MUST pass the lens the token names `--lp-ink-dim` as `fromColor` and `--lp-accent-bright` as `toColor`, as token names rather than resolved colour values.
- **lens-reduced-motion**: The lens MUST NOT animate when the user prefers reduced motion; the component leaves `respectReducedMotion` at the lens default, which is true.
- **client-only**: The component MUST be exported from the client barrel and MUST NOT be exported from the server barrel.
- **phone-separators**: Below a viewport width of 640px (`max-width: 640px`) the separators MUST be hidden (`display: none`).
- **phone-gap**: Below a viewport width of 640px the nav MUST space its links with a `column-gap` of `1.2rem`.
- **mono-font**: The nav MUST be set in `var(--lp-font-mono, ui-monospace, "SF Mono", monospace)`.
- **focus-ring**: A link that receives `:focus-visible` MUST show a 2px outline in `--lp-accent` (fallback `#9a9a9a`) offset by 3px.
- **hover-color**: A hovered or `:focus-visible` link SHOULD take the colour `--lp-accent-bright` (fallback `#d8d8d8`), where the sweep lands.

## Appearance

All values come from the `.lp-hero-nav` rules in `flow.css`.

- **Layout**: A wrapping flex row (`display: flex`, `flex-wrap: wrap`) with `align-items: center` and `justify-content: center`.
- **Font**: `var(--lp-font-mono, ui-monospace, "SF Mono", monospace)`, 0.8rem, `letter-spacing: 0.12em`, `text-transform: uppercase`.
- **Link**: `display: inline-block`, `position: relative`, padding `8px 0`, no underline (`text-decoration: none`), `cursor: pointer`, colour `var(--lp-ink-dim, #a0a0a0)`, with `transition: color 0.3s`.
- **Link hover and focus-visible**: Colour `var(--lp-accent-bright, #d8d8d8)`.
- **Link focus ring**: `outline: 2px solid var(--lp-accent, #9a9a9a)` with `outline-offset: 3px`, on `:focus-visible` only.
- **Separator**: Colour is `--lp-ink-dim` (fallback `#a0a0a0`) mixed 60% with transparent via `color-mix`, padding `0 0.75rem`, `user-select: none`.
- **Phone width (max 640px)**: Separators are `display: none`; the nav gets `column-gap: 1.2rem`.
- **Background, border, shadow, corner radius**: None; the nav draws none of these.
- **Min/Max size**: None set; the row is as wide as its links and wraps at its container's width.

## States

| State | Appearance change |
|-------|------------------|
| Default | Links in `--lp-ink-dim`, separators between them. |
| Sweeping | After the 2000 ms start delay the lens runs back and forth along the links without stopping, tinting glyphs near it from `--lp-ink-dim` toward `--lp-accent-bright` and scaling them up to 125%; it holds still (glyphs at rest) while the pointer is over a link, and does not run under reduced motion. |
| Hover | Link colour becomes `--lp-accent-bright`, animated by `transition: color 0.3s`. |
| Focused | Link colour becomes `--lp-accent-bright` and a 2px `--lp-accent` outline appears (`:focus-visible` only). |
| Phone width | Separators are removed and links are spaced by a 1.2rem column gap. |
| Pressed | Not applicable: `flow.css` has no `:active` rule for the links. |
| Disabled | Not applicable: the component has no disabled prop and renders only plain anchors. |
| Loading | Not applicable: rows are passed in synchronously and nothing is fetched. |

## Accessibility

- **role**: The `nav` element exposes the navigation landmark; each row is a native link.
- **label**: The `nav` takes its accessible name from the required `label` prop, which the doc comment says is the host's copy.
- **separators**: Separators are `aria-hidden="true"`, so assistive technology reads only the links.
- **keyboard**: Links are native anchors, reachable by Tab and activated by Enter with no script.
- **focus-visible**: A 2px accent outline with a 3px offset shows on `:focus-visible`.
- **reduced-motion**: The lens sweep is skipped when `prefers-reduced-motion: reduce` matches, by the lens's default of respecting it.
- **contrast**: NEEDS REVIEW: Not implemented in source. The links are `--lp-ink-dim` text at 0.8rem, and neither this source nor `flow.css` states a contrast ratio for that token against the page background; a contrast check of the host's token values would settle it.
- **target-size**: NEEDS REVIEW: Not implemented in source. A link's height is its 0.8rem text plus 8px of padding above and below, with no width or height floor, and the source cannot decide whether that meets the 44×44pt Apple HIG or 24×24 CSS px WCAG 2.2 target size; measuring the rendered links would settle it.

## Conformance Test Vectors

Vectors derive from `hero-nav.test.tsx` in the landing package's `__tests__` folder, where a test is named.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hero-nav-001 | nav-landmark, nav-label, link-per-row, link-order, link-href, link-text | Test "is a labelled nav of plain anchors, one per row, in order": rows `#work` Work and `#contact` Contact, label "Sections" | `nav.lp-hero-nav` has `aria-label` "Sections"; two `a.lp-hero-nav__link` give href and text `#work`/Work then `#contact`/Contact. |
| hero-nav-002 | separator-between, separator-hidden | Test "draws a hidden separator between rows and none at the ends": three rows | Two `.lp-hero-nav__sep` elements, each `aria-hidden="true"`. |
| hero-nav-003 | no-edge-separators | Same test, three rows | The nav's first and last element children both have class `lp-hero-nav__link`. |
| hero-nav-004 | lens-selector, lens-colors | Test "sweeps its links with the lens, from the dim ink to the bright accent": render with two rows | The most recent lens call has selector `.lp-hero-nav__link`, `fromColor` `--lp-ink-dim`, `toColor` `--lp-accent-bright`. |
| hero-nav-005 | client-only | Test "ships from the client barrel only": import both barrels | `client.HeroNav` is the component; `'HeroNav' in server` is false. |
| hero-nav-006 | phone-separators, phone-gap | Test "drops its separators at phone width, where the row wraps": parse `flow.css`, read the `(max-width: 640px)` media rules | `.lp-hero-nav__sep` has `display: none`; `.lp-hero-nav` has `column-gap: 1.2rem`. |
| hero-nav-007 | mono-font | Test "is set in the kit mono": read the `.lp-hero-nav {` rule | It contains `font-family: var(--lp-font-mono, ui-monospace, "SF Mono", monospace);`. |
| hero-nav-008 | link-per-row, separator-between | Test "is styled by the kit: flow.css carries its rules": read `flow.css` | It contains the rules `.lp-hero-nav {`, `.lp-hero-nav__sep {`, `.lp-hero-nav__link {`. |
| hero-nav-009 | link-per-row, no-edge-separators | Failure mode: `rows` is `[]` | The nav renders with its `aria-label` and no links or separators; the lens finds no elements and starts nothing. |
| hero-nav-010 | separator-between, no-edge-separators | One row only | One link and no separator. |

The `lens-delay`, `lens-reduced-motion`, `plain-anchors`, `focus-ring` and `hover-color` requirements have no automated vector in the test file. `lens-delay` is checkable by inspecting the options the lens receives (`startDelay: 2000`); the remaining four are verified by reading the source and `flow.css`. The `separator-drawn` SHOULD is a construction rule and has no test.

## Edge Cases

- **Empty rows** (MUST): With `rows=[]` the component renders an empty `nav` that still carries its `aria-label`; `useTextLens` finds no matching elements and returns without creating a lens.
- **Single row** (MUST): One row renders one link and no separator, because the separator renders only when `index > 0`.
- **Boundary at 640px** (MUST): At a viewport of 640px or narrower the phone rules apply; at 641px the separators and no column gap apply.
- **Wrapped line** (MUST): Wrapping at desktop width, where separators still show, can leave a `|` at a line end; the component does not detect wrapping, and the phone rule removes separators only below the breakpoint.
- **Duplicate hrefs** (SHOULD): Each fragment is keyed by `row.href`, so two rows with the same href collide on key. The source does not deduplicate; the host SHOULD pass unique hrefs, as `indexRows(page)` does by construction.
- **Empty label or href** (SHOULD): The source does not validate row fields; an empty `label` renders an empty link and an empty `href` renders an anchor to the current page.
- **Lens restart** (MUST): The lens hook keeps a `swept` flag. If its effect re-runs after the first sweep (an option or the ref changes), the new lens starts with a 0 ms delay instead of 2000 ms, so the delay applies only to the first sweep.
- **Unmount before the delay** (MUST): The hook clears its timer and destroys the lens on cleanup, so unmounting within the first 2000 ms starts no sweep.
- **Reduced motion** (MUST): With `prefers-reduced-motion: reduce`, the lens `start` is a no-op and links stay in their resting colour.
- **JavaScript disabled** (MUST): The anchors, labels and hrefs render and work; only the sweep is lost.
- **Concurrent access**: Not applicable: the component is a stateless render with one ref, and no shared mutable state is touched by more than one caller.
- **Offline or disconnected**: Not applicable: the component makes no network request; the anchors navigate as the browser does.
- **Server rendering**: The source marks the file `'use client'` and ships it from the client barrel only; the nav markup itself is plain, and the lens starts only in an effect.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rows` | `NavLink[]` (`{ href: string; label: string }`) | required | The links, in order; the page's own sections, such as `indexRows(page)`. |
| `label` | `string` | required | The `nav`'s accessible name; copy that the host owns. |

The lens options (selector, 2000 ms start delay, colour tokens) are fixed in the component and are not props. The tokens `--lp-ink-dim`, `--lp-accent-bright`, `--lp-accent` and `--lp-font-mono` are resolved where the row is mounted, so repainting the tokens repaints the sweep.

## Deep Linking

Not applicable: the component defines no URL patterns of its own. It renders the `href` values it is given; the tests use in-page fragments such as `#work` and `#contact`.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `label` prop | Host-supplied | The `nav`'s accessible name; the test passes "Sections". |
| `rows[].label` | Host-supplied | Each link's text; displayed uppercase by `text-transform`. |
| separator | `\|` | A literal bar that is `aria-hidden`; it is not a translatable string. |

All visible copy is supplied by the host. Layout direction is not handled specially: the row is a flex row, so it follows the document's writing direction by default.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The lens sweep does not run when `prefers-reduced-motion: reduce` matches (the lens default). The `transition: color 0.3s` on hover is not gated by a reduced-motion rule in `flow.css`. |
| Increase Contrast | Not applicable: `flow.css` has no `prefers-contrast` rule for the nav. |
| Differentiate Without Color | Not applicable: links are told apart by position and separators, and the hover and focus states change colour plus a focus outline on `:focus-visible`. |

## Feature Flags

Not applicable: the component reads no flag and renders whenever it is mounted.

## Analytics

Not applicable: the component emits no events and has no click handler.

## Privacy

Not applicable: the component collects, stores and transmits nothing. It renders the `rows` and `label` it is given and makes no network request.

## Logging

Not applicable: the component writes no log output.

## Platform Notes

- **SwiftUI**: Use a wrapping horizontal layout, such as a custom `Layout` or a flow layout over `ForEach`, of `Link` views (or `Button` with `.buttonStyle(.plain)`) in `.font(.system(.footnote, design: .monospaced))` with `.textCase(.uppercase)` and `.tracking`. Draw the bar as a `Text("|")` with `.accessibilityHidden(true)` rather than a divider, and omit it on the first item. The sweep has no direct equivalent; animate `foregroundStyle` from a dim to an accent colour in a repeating highlight that starts after a delay, gated on `accessibilityReduceMotion`. Apple's HIG recommends 44×44pt targets, which the web padding does not reach.
- **Compose**: Use `FlowRow` with `horizontalArrangement = Arrangement.Center` and a `Text` per row with `Modifier.clickable(role = Role.Button)` or a link-annotated `AnnotatedString`. Insert a separator `Text("|")` with `Modifier.clearAndSetSemantics {}` between items, and drop it below a 640dp width. Use `FontFamily.Monospace`, `letterSpacing = 0.12.em`, and `animateColorAsState` for the repeating sweep, skipped when animator duration scale is 0. Material 3 asks for 48dp targets.
- **React/Web**: The source platform. Files are `packages/web/packages/landing/src/flow/HeroNav.tsx` (the component), `packages/web/packages/landing/src/css/flow.css` (the `.lp-hero-nav` rules) and the barrel line in `src/client.ts`. It is a client component because `useTextLens` needs an effect and a ref; the markup itself is plain `nav` and `a` elements, so it works with JavaScript off. The two sweep colours are token names resolved at mount, not colour values. The test file mocks `@adh-sdk/textlens` and reads `flow.css` as text to check rules.
- **AppKit / UIKit**: Use an `NSStackView` (AppKit) or a `UIStackView` or compositional layout (UIKit) of link-styled buttons or `NSTextField` links with `allowsEditingTextAttributes`, a monospaced font and `kern` for letter spacing, and a hidden-from-accessibility `|` label (`setAccessibilityElement(false)`). Wrapping needs a custom layout because stack views do not wrap. Drive the sweep with `CABasicAnimation` on `foregroundColor` after a 2 s delay, skipped when `NSWorkspace.accessibilityDisplayShouldReduceMotion` or `UIAccessibility.isReduceMotionEnabled` is true.
- **WinUI 3**: Compose an `ItemsRepeater` with a `UniformGridLayout` or a `StackLayout` of `Orientation="Horizontal"`, or a `WrapPanel` from the Windows Community Toolkit, set to `HorizontalAlignment="Center"`. Each row is a `HyperlinkButton` (with `NavigateUri` for an external target or a `Click` handler that calls `Frame.Navigate` or scrolls to the named section) using `FontFamily="Consolas"`, `FontSize` 12, `CharacterSpacing="120"` and an uppercase transform applied in the data. Set the separator `TextBlock` with `Text="|"`, `AutomationProperties.AccessibilityView="Raw"` and `IsHitTestVisible="False"`, and bind its `Visibility` to a visual state that collapses it below 640 effective pixels via an `AdaptiveTrigger` with `MinWindowWidth="641"`. Wrap the group in a `ContentControl` or `Grid` with `AutomationProperties.LandmarkType="Navigation"` and `AutomationProperties.Name` bound to the label. `HyperlinkButton`'s visual states (`Normal`, `PointerOver`, `Pressed`, `Disabled`) restyle through its `Foreground` theme resources, so map `--lp-ink-dim` to the normal foreground and `--lp-accent-bright` to `PointerOver`, and rely on the built-in keyboard focus visual (`FocusVisualPrimaryBrush`) for the focus ring. Run the repeating sweep with a `Storyboard` containing a `ColorAnimation` on `SolidColorBrush.Color`, started after a 2 s `BeginTime`, and skip it when `UISettings.AnimationsEnabled` is false. Fluent 2 asks for a 32px minimum target and Windows touch guidance is 40×40 epx, so pad the button's `MinHeight` accordingly.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/flow/HeroNav.tsx` | confirmed (1.1.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Render the links as plain anchors with no click handler, and let the lens be the only script.
**Rationale**: The doc comment says the hrefs then work the same with JavaScript off; navigation is a table of contents and needs no script.
**Approved**: pending

**Decision**: Draw separators as `span` elements, `aria-hidden`, rather than a border.
**Rationale**: The source comment says a border would also draw at the ends of a wrapped line; an element can be omitted before the first link, and being hidden keeps assistive technology reading only the links.
**Approved**: pending

**Decision**: Remove the separators and use a 1.2rem column gap below 640px.
**Rationale**: The `flow.css` comment says that when the row wraps a bar lands at the end of one line or the start of the next with nothing on its far side, and the test cites mikefullerton's contact row as the precedent.
**Approved**: pending

**Decision**: Pass the lens colour token names (`--lp-ink-dim`, `--lp-accent-bright`) rather than resolved values.
**Rationale**: The doc comment says the names are resolved where the row is mounted, so a repaint of the tokens repaints the sweep.
**Approved**: pending

**Decision**: Start the sweep 2000 ms after mount, once.
**Rationale**: The doc comment says the lens says the line is alive and worth clicking; the delay lets the hero settle first. The lens, once started, keeps sweeping back and forth (the doc comment's phrase "swept once" describes the single start, not a single pass). The 2000 ms value is stated in the source without a recorded reason, and the hook applies it to the first sweep only (a later effect run uses 0 ms).
**Approved**: pending

**Decision**: Take `rows` as a prop shaped like the page's own sections instead of a free list.
**Rationale**: The doc comment says `indexRows(page)` is meant to be passed so a row cannot name a band the page lacks or miss one it has.
**Approved**: pending

**Decision**: SHOULD requirements (separators as elements; hover colour) follow the source's comments and CSS.
**Rationale**: Deviation is allowed because the nav still works with borders or another hover colour; the cost is a dangling bar on wrapped lines and a hover that no longer lands where the sweep does.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | platform-compliance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

The component keeps its concerns apart: markup in `HeroNav.tsx`, appearance in `flow.css`, the sweep in `@adh-sdk/textlens`, and the link data and label in the host. Its test file covers structure, separators, the lens options, the barrel and the CSS rules, which is the basis for `unit-test-coverage` passing, though the 2000 ms delay has no test. It uses a native `nav` and anchors, so semantic markup and keyboard access pass. Reduced motion is partial: the sweep respects it through the lens default, but the 0.3s colour transition on hover is not gated. Touch target size is partial: links carry only 8px of vertical padding and no minimum width or height, and the open question on `target-size` records the gap. Theming passes because the colours are token names with fallbacks. No-hardcoded-strings passes because all visible copy is supplied by the host; the only literal is the `aria-hidden` bar.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-14 | Mike Fullerton | Initial creation from source |
