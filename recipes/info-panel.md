---
id: 2ad7c681-6a9e-43ae-a9d9-b448939d3455
title: InfoPanel
domain: adhsdk://recipes/info-panel
type: ingredient
version: 1.3.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A themable dashboard panel: bordered card with a standard header ([icon] title count · center · actions) over a content-sized or fill+scroll body."
platforms:
- typescript
- web
tags:
- component
- panel
- dashboard
- card
- ui
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# InfoPanel

## Overview

`InfoPanel` (`@adh-sdk/ui`) is the standard dashboard panel: a bordered,
rounded card with a consistent header over a body that is either **content-sized**
(a stat card) or a **fill + scroll** pane (a list). It is generic on purpose — the
host supplies whatever goes in the header slots and the body (icons, copy buttons,
filter controls, progress bars, rows) — so every dashboard panel across the
platform shares one frame and one header rhythm.

Header anatomy (single row):

```
[icon] [title] [count] [titleAfter]  …flex…  [center]  …flex…  [actions]
```

The header has a shared minimum height (`INFO_PANEL_HEADER_HEIGHT`, 41px), also
exported, so sibling panels laid side by side on a rail line their headers up even
when their content differs.

Two symbols ship from `@adh-sdk/ui/blocks/info-panel`:

- `InfoPanel` — the component.
- `INFO_PANEL_HEADER_HEIGHT` — the shared default header height, exported so hosts
  can align other, non-`InfoPanel` chrome to the same baseline.

## Behavioral Requirements

- **titled-header**: The component MUST render a header row containing the `title`, preceded by `icon` when provided and immediately followed by `titleAfter` when provided.
- **count-when-positive**: The component MUST render the `count` after the title only when it is provided and greater than zero, and MUST hide it otherwise.
- **header-slot-placement**: The component MUST place `center` in a centered, flexible header slot and `actions` in a right-justified header slot.
- **actions-right-justified-without-center**: When `actions` is present and `center` is absent, the component MUST push the actions to the right edge of the header.
- **shared-header-height**: The component MUST give the header a minimum height equal to `INFO_PANEL_HEADER_HEIGHT` so sibling panels' headers align.
- **content-sized-by-default**: By default (`scroll` false) the component MUST size the panel to its content and MUST NOT scroll the body.
- **fill-and-scroll-on-scroll**: When `scroll` is true, the component MUST let the panel flex to fill its track and MUST make the body scroll vertically when its content overflows.
- **body-ref-exposure**: The component MUST attach `bodyRef` to the scrolling body element so the host can tail or anchor it.
- **label-region**: The component MUST expose the panel as a labeled region whenever an accessible name can be computed — `ariaLabel` when provided, else `title` when it is a string. It leaves the region unnamed only when `title` is a non-string node and no `ariaLabel` is given (see Edge Cases, "Non-string title").
- **mode-default-padding**: The component MUST apply body padding defaulting by mode (card vs scroll) and MUST use `bodyPadding` when provided.
- **layout-prop-passthrough**: The component MUST apply caller-supplied `flex` and `maxHeight` to the outer element for host-controlled sizing.
- **host-attribute-passthrough**: The component MUST spread remaining host attributes (`data-*`, `id`, event handlers) onto the outer `<section>`, without overriding the computed accessible name: an explicit `ariaLabel` prop takes precedence over a raw `aria-label` present in the spread attributes, which in turn takes precedence over the string `title` fallback.

## Appearance

Content-sized card (default):

```
┌───────────────────────────────────────────────┐
│ [◆] Title  12          ⟨center⟩        ⟨actions⟩│  header, min-height 41
├───────────────────────────────────────────────┤
│ content sized to its children (no scroll)       │
└───────────────────────────────────────────────┘
```

Fill + scroll (`scroll`):

```
┌───────────────────────────────────────────────┐
│ [◆] Title  128         ⟨center⟩        ⟨actions⟩│
├───────────────────────────────────────────────┤
│ rows…                                         ▲ │
│ rows…                                         █ │  body scrolls; panel flexes to fill
│ rows…                                         ▼ │
└───────────────────────────────────────────────┘
```

- **Corner radius**: 10px on the outer container; content clips to it (the outer
  overflow is hidden).
- **Border**: 1px, theme border color; the same color underlines the header as a
  divider.
- **Background / Foreground**: theme surface and text colors, consistent across
  light and dark.
- **Header height**: minimum 41px (`INFO_PANEL_HEADER_HEIGHT`), so sibling panels
  on a rail line up even when their content differs; a flex child can shrink
  below its content in scroll mode so the body — not the panel — scrolls.
- **Header text**: title is small, semibold, non-wrapping; count is dim, 11px
  monospace.
- **Body padding**: 12px vertical / 16px horizontal by default in card mode; 8px
  top / 16px sides / 10px bottom by default in scroll mode; either default is
  fully replaced by `bodyPadding` when supplied.
- **Outer layout**: flex `0 0 auto` (card, content-sized) or `1 1 0` (scroll,
  fills its track).
- Styled entirely with theme tokens; no raw colors, no forced overrides. See the
  **React/Web** platform note for the exact utility classes.

## States

| State | Appearance change |
|---|---|
| Content-sized (default) | outer `flex: 0 0 auto`; body `flex-none`, no scroll |
| Fill + scroll (`scroll`) | outer `flex: 1 1 0` + `min-h-0`; body `flex-auto overflow-y-auto` |
| No icon | title starts the header (leading glyph slot omitted) |
| Count 0 / absent | count hidden |
| No center | actions block gains `ml-auto` to sit at the right edge |
| Center present | center fills the middle; actions sit to its right |
| `maxHeight` / `flex` set | outer element uses the caller's layout numbers |

## Accessibility

- The panel renders as a `<section>` with an accessible name: `ariaLabel` when
  given, else the `title` when it is a string, so the panel is a labeled landmark
  region.
- The leading `icon` is decorative and marked `aria-hidden`, so assistive tech reads
  the title rather than an unlabeled glyph.
- In scroll mode the body is a real scroll container (`overflow-y-auto`). The
  source gives the div itself no `tabIndex`, so keyboard reachability depends on
  focusable content the host renders inside it — not every browser makes an
  unfocusable overflow container keyboard-scrollable on its own (see
  **keyboard-navigable** in Compliance).
- Color and contrast come from the `apt-*` theme tokens, consistent across light and
  dark themes and every site.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | titled-header | `title="Fleet"`, `icon=<I/>`, `titleAfter=<Copy/>` | header shows icon, then "Fleet", then the copy control |
| T2 | count-when-positive | `count={12}` | "12" rendered after the title |
| T3 | count-when-positive | `count={0}` (or omitted) | no count rendered |
| T4 | header-slot-placement | `center=<Bar/>`, `actions=<Gear/>` | center in the centered slot, actions in the right slot |
| T5 | actions-right-justified-without-center | `actions=<Gear/>`, no `center` | the actions block's right edge equals the header's inner right edge (no center spacer needed to achieve it) |
| T6 | shared-header-height | render two panels | both headers have `min-height: 41px` and align — **Playwright/E2E**: jsdom has no real layout to assert alignment against |
| T7 | content-sized-by-default | default (`scroll` unset) | outer `flex: 0 0 auto`; body has no `overflow-y-auto` |
| T8 | fill-and-scroll-on-scroll | `scroll` with overflowing content | outer `flex: 1 1 0`; body `overflow-y-auto` and scrolls — **Playwright/E2E**: jsdom does not lay out or scroll content |
| T9 | body-ref-exposure | pass a `bodyRef` | the ref resolves to the scrolling body element |
| T10 | label-region | `title="Fleet"`, no `ariaLabel` | `<section aria-label="Fleet">` |
| T11 | label-region | non-string `title`, `ariaLabel="Fleet"` | `<section aria-label="Fleet">` |
| T12 | mode-default-padding | `scroll` vs card, no `bodyPadding` | body padding `8px 16px 10px` (scroll) vs `12px 16px` (card) |
| T13 | layout-prop-passthrough | `flex="2 1 0"`, `maxHeight={400}` | outer style carries that flex and `max-height: 400px` |
| T14 | host-attribute-passthrough | `data-testid="panel"`, `data-kind="monitor"` | outer `<section>` carries both attributes; `aria-label` still defaults from `title` |
| T15 | host-attribute-passthrough | `title="Fleet"` (string), rest `aria-label="FromRest"`, `ariaLabel="Explicit"` | `<section aria-label="Explicit">` — the `ariaLabel` prop wins over both the rest `aria-label` and the string `title` |
| T16 | host-attribute-passthrough | `title="Fleet"` (string), rest `aria-label="FromRest"`, no `ariaLabel` prop | `<section aria-label="FromRest">` — the rest attribute wins over the string `title` fallback when `ariaLabel` is absent |
| T17 | count-when-positive | `count={-3}` | no count rendered (negative is treated as not positive) |
| T18 | label-region | non-string `title`, no `ariaLabel` | `<section>` has no `aria-label` — the known gap (see Edge Cases, "Non-string title") |

## Edge Cases

- **Non-string title**: when `title` is a node (not a string) and no `ariaLabel` is
  given, the region has no accessible name — hosts SHOULD pass `ariaLabel` in that
  case.
- **Actions without center**: the actions container is given `ml-auto` only when
  `center` is absent, so it still hugs the right edge without a center spacer.
- **Count exactly 0**: treated as "nothing to show" and hidden (only `> 0` renders),
  so an empty list's panel doesn't show a "0".
- **Scroll flex child**: `min-h-0` is applied in scroll mode so the panel can shrink
  below its content inside a flex parent and let the body — not the panel — scroll.
- **Body padding override**: `bodyPadding` fully replaces the mode default; hosts
  needing edge-to-edge content (e.g. a table) pass `bodyPadding="0"`.
- **maxHeight with card mode**: a content-sized card given a `maxHeight` will clip via
  the outer `overflow-hidden`; use `scroll` to make the body scroll within that cap.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `title` | `ReactNode` | — (required) | Header title. |
| `children` | `ReactNode` | — (required) | Body content. |
| `icon` | `ReactNode` | — | Leading glyph before the title (decorative, `aria-hidden`). |
| `titleAfter` | `ReactNode` | — | Rendered immediately after the title (e.g. a copy button). |
| `count` | `number` | — | Dim count after the title; hidden when absent or ≤ 0. |
| `center` | `ReactNode` | — | Centered header slot (e.g. a progress bar). |
| `actions` | `ReactNode` | — | Right-justified header slot (e.g. filter + gear). |
| `scroll` | `boolean` | `false` | Fill + scroll body; false = content-sized card. |
| `flex` | `string` | `scroll ? "1 1 0" : "0 0 auto"` | Outer flex shorthand. |
| `maxHeight` | `string \| number` | — | Outer max height. |
| `bodyPadding` | `string` | `scroll ? "8px 16px 10px" : "12px 16px"` | Body padding. |
| `bodyRef` | `Ref<HTMLDivElement>` | — | Ref to the scrolling body element. |
| `ariaLabel` | `string` | `title` if string | Accessible region name. |
| `className` / `style` | `string` / `CSSProperties` | — | Merged onto the outer `<section>`. |
| …rest | `Omit<HTMLAttributes<HTMLElement>, "title">` | — | Remaining host attributes (`data-*`, `id`, handlers) spread onto the outer `<section>`. |

`INFO_PANEL_HEADER_HEIGHT` (= 41) is exported so hosts can align non-`InfoPanel`
chrome to the same header baseline.

## Deep Linking

Not applicable: `InfoPanel` is a presentational container component that wraps host-supplied content. Deep linking routes are the responsibility of the host application and the content it renders within the panel.

## Localization

Not applicable: `InfoPanel` contains no user-facing strings. The `title`, `titleAfter`, icon, `center`, and `actions` slots are entirely host-owned; any localization of content in those slots is the host's responsibility.

## Accessibility Options

Not applicable: The component does not respond to accessibility display options (e.g., Reduce Motion, Increase Contrast). The component's visual styling is controlled by the `apt-*` theme tokens, and the host's content determines any motion or contrast behavior.

## Feature Flags

Not applicable: No feature flags are defined in the component source. The component is always available and all behavioral modes (`scroll`, `flex`, padding overrides) are unconditionally enabled.

## Analytics

No analytics. `InfoPanel` is a presentational container; any data-loading or
interaction telemetry belongs to the host content it wraps.

## Privacy

Not applicable: The component collects no data. It is a purely presentational container that renders host-supplied content. No telemetry, logging, or data collection occurs.

## Logging

No logging. `InfoPanel` performs no I/O and emits no log statements of its own —
the flex, padding, and `aria-label` values it computes are pure render output,
not events. The panel does not wrap or filter any logging the host performs
inside the slots it renders.

## Platform Notes

- **SwiftUI**: Create a custom `View` that composes a header `HStack` — leading icon, title, trailing `titleAfter`, centered content, right-aligned actions — given `.frame(minHeight: 41)` (a floor, not a fixed height, so sibling headers align while still growing for taller content; no `GeometryReader` needed) above a body that conditionally wraps content in a `ScrollView` when `scroll` is true.
- **Compose**: Build with a `Column` holding a `Row` for the header (`weight` and `align` modifiers for the slots) above a body. Apply `Modifier.weight(1f).fillMaxHeight()` to the body only when `scroll` is true — applying it unconditionally would make card mode fill its track too — and wrap the body in a scrollable container in that same branch. Use `Box` and `Row` compositions for the slot layout and card styling.
- **React/Web**: File: `packages/web/packages/ui/src/blocks/info-panel.tsx`. Outer: `flex flex-col overflow-hidden rounded-[10px] border border-apt-border bg-apt-surface text-apt-text`, plus `min-h-0` in scroll mode. Header: `flex flex-none items-center gap-2` with a bottom border and `min-height: 41px` (`INFO_PANEL_HEADER_HEIGHT`); title `text-sm font-semibold whitespace-nowrap`; count `font-mono text-[11px] text-apt-text-dim`. Body: `flex-none` (card) or `min-h-0 flex-auto overflow-y-auto` (scroll). All colors and surfaces come from the `apt-*` token classes; React's `Ref` API exposes the body element. Template and host props determine all header slot content.
- **AppKit / UIKit**: Implement as a `UIView` (iOS) or `NSView` (macOS) subclass composing an `NSStackView` (macOS) or `UIStackView` (iOS) with a header view constrained to `>= 41pt` (a floor, matching the min-height design decision, not a fixed height) above a scrollable content view; conditionally wrap it in `NSScrollView` / `UIScrollView` when scroll mode is enabled. For body padding, `UIStackView` (UIKit) can use `layoutMargins` with `isLayoutMarginsRelativeArrangement = true`; `NSStackView` (AppKit) has no such property — use its `edgeInsets` instead.
- **WinUI 3**: Use a custom `UserControl` with a `Grid` of two rows, `Auto` and `*` — a vertical `StackPanel` would give both rows unlimited height and the `ScrollViewer` would never scroll. Put a `Border` in the `Auto` row for the header, with `MinHeight="41"` (or bound to the constant, not a fixed `Height`) and a `ScrollViewer` in the `*` row (conditionally visible/enabled by scroll mode). Style header and body using theme resources for borders, backgrounds, and text. The ScrollViewer's `Content` property holds the body content; set `ScrollViewer.VerticalScrollBarVisibility` to `Auto` in scroll mode and hide it in card mode.

## Design Decisions

**Decision**: One frame, host-owned slots — the panel fixes the border, radius,
surface, and header rhythm but leaves every slot (`icon`, `title`, `titleAfter`,
`count`, `center`, `actions`, body) to the host.
**Rationale**: So a stat card and a scrolling list share one component instead
of two bespoke frames.
**Approved**: pending

**Decision**: Shared, exported header height — export
`INFO_PANEL_HEADER_HEIGHT` as a `min-height`, not a fixed height.
**Rationale**: Header alignment across sibling panels on a rail requires a
common baseline; a `min-height` lets headers align while still growing for
taller content.
**Approved**: pending

**Decision**: Two body modes on one prop — `scroll` switches both the outer
flex (`0 0 auto` vs `1 1 0` + `min-h-0`) and the body (`flex-none` vs
`flex-auto overflow-y-auto`).
**Rationale**: So "stat card" and "fill + scroll list" are a single boolean
rather than two components.
**Approved**: pending

**Decision**: `apt-*` tokens over inline hex — the panel uses the central
token utilities instead of the older inline-style + hex-fallback layer.
**Rationale**: The panel themes correctly on every site this way; the
fallback layer was dropped once `@source` guaranteed the utilities exist
everywhere.
**Approved**: pending

**Decision**: `bodyRef` for tail/anchor — expose the scrolling body element
through a ref.
**Rationale**: Lets hosts implement scroll-to-bottom / anchoring without the
panel owning that behavior.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`platform-theming` is `passed`: the source styles exclusively with `apt-*`
theme tokens (no raw hex, no `!important`), which theme correctly in light and
dark. `semantic-markup` is `partial`: the `<section>` gets a computed
`aria-label` and the leading icon is `aria-hidden`, but the source leaves the
region unnamed for a non-string `title` with no `ariaLabel` (see
**label-region**). `keyboard-navigable` is `partial`: the scroll body is a
real `overflow-y-auto` container, but the source adds no `tabIndex` to it, so
keyboard reachability depends on focusable content the host renders inside.
`separation-of-concerns` is `passed`: the component is pure presentation over
its header/body slot props, with only the trivial `aria-label` precedence
computed inline. `unit-test-coverage` is `partial`: `infoPanel.test.tsx`
exercises only the host-attribute passthrough and the `aria-label` precedence
chain, with no test covering the icon, count, center, actions, or scroll-mode
rendering.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the header anatomy, content-sized vs fill+scroll body, and the shared header-height alignment. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | Host-attribute passthrough: remaining HTML attributes spread onto the root `<section>` (data-* tagging without a wrapper). |
| 1.2.0 | 2026-09-22 | Claude Haiku 4.5 | Complete recipe sections: add Deep Linking, Localization, Accessibility Options, Feature Flags, Privacy; expand Platform Notes with translation guidance for all five platforms; set status to review. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case everywhere they're cited; resolve the label-region contradiction with Edge Cases and state the aria-label precedence, with new test vectors T15-T18; correct the keyboard-scrollable overclaim; write a Logging statement distinct from Analytics; reformat Design Decisions and Compliance to the canonical forms; fix WinUI 3's Grid/MinHeight, the SwiftUI/AppKit min-height wording, AppKit-vs-UIKit padding APIs, and Compose's scroll-gated fillMaxHeight; mark T6/T8 as Playwright/E2E and reword T5 behaviorally; rewrite Appearance in neutral terms and move Tailwind classes into the React/Web note; drop the unsupported "manages layout state" phrase from Privacy. |
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
