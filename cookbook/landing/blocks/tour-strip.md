---
id: 1d701cc5-5822-4465-8ad5-413e6b0c31fc
title: "Tour Strip"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Full-viewport screen opening a guided tour stop with navigation and optional pillar content."
platforms:
  - typescript
  - web
tags:
  - tour
  - navigation
  - landing
depends-on:
  - 07c437af-a291-4356-bd83-c896bd4facde
  - 51d3b1ba-ced7-4c08-8a63-c83094d91299
related:
  - 01947259-4883-44e1-a047-6b4e463cb422
references: []
approved-by: ""
approved-date: ""
---

# Tour Strip

## Overview

The Tour Strip is a full-viewport screen component that introduces a single stop within a guided tour. It displays a header identifying the tour step, a primary promise or headline, optional multi-column pillar content (title and body), and conditional back/next navigation links. The component cannot control where a host page places it, so it is the host's responsibility to render Tour Strip as the first screen on a tour page, before any hero or other content, so a reader arriving mid-tour is oriented immediately; the **render-as-tour-screen** requirement below covers only what the component itself controls — rendering as a full-viewport `Screen` with id `tour` and class `lp-tour`.

## Behavioral Requirements

- **render-eyebrow**: Component MUST render an eyebrow text containing the step number, total steps, and eyebrow label in the format `Step {step} of {total} · {eyebrow}`.
- **render-promise**: Component MUST render the promise content as a paragraph element.
- **render-as-tour-screen**: Component MUST render as a full-viewport `Screen` with id `tour` and class `lp-tour`.
- **render-pillars-when-provided**: When `pillars` array is provided and non-empty, component MUST render each pillar with title and body in a dedicated card element.
- **render-back-navigation**: When `back` step is provided, component MUST render a link containing the step label and optional note, with a left arrow indicator.
- **render-next-navigation**: When `next` step is provided, component MUST render a link containing the step label and optional note, with a right arrow indicator.
- **omit-navigation-when-absent**: Component MUST NOT render back navigation link when `back` prop is undefined; MUST NOT render next navigation link when `next` prop is undefined.
- **steps-container-always-renders**: Component MUST render the `lp-tour__steps` container element regardless of whether `back` or `next` is provided, even when both are absent.
- **hide-arrow-from-assistive-tech**: Component MUST mark arrow indicators as decorative with `aria-hidden="true"`.
- **accept-react-node-promise**: The `promise` prop MUST accept any valid React node, in practice limited to phrasing content since it renders inside a `<p>` wrapper (see Edge Cases).
- **accept-note-on-navigation-steps**: Both `back` and `next` step objects MUST accept an optional `note` property to display explanatory text below the step label.

## Appearance

- **Layout**: Full viewport, wrapped in `Screen` and `Wrap` components for consistent site layout
- **Eyebrow**: Renders with class `lp-eyebrow`; inherits color and typography from eyebrow styling
- **Promise paragraph**: Renders with class `lp-tour__promise`; serves as primary visual hierarchy element
- **Pillar cards**: Each renders with class `lp-card` containing `<h3>` title and `<p>` body; organized in grid under class `lp-tour__pillars`
- **Navigation steps container**: Renders with class `lp-tour__steps`
- **Navigation links**: Each renders with class `lp-tour__step` plus direction modifier (`lp-tour__step--back` or `lp-tour__step--next`)
- **Arrow indicators**: Render with class `lp-tour__arrow` using Unicode arrows (← for back, → for next)
- **Typography in navigation**: Step label renders in `<b>` (bold); optional note renders in `<em>` (emphasis)

## States

| State | Condition |
|-------|-----------|
| Default | Both back and next navigation present |
| First step | No back navigation; next navigation present |
| Last step | Back navigation present; no next navigation |
| Single step | Neither back nor next navigation present |
| No pillars | Pillars array absent or empty |
| With pillars | Pillars array provided with one or more items |

## Accessibility

- **Screen container**: Component renders within the shared `Screen` ingredient (a `<section>` by default) carrying `id="tour"`. Without an accessible name (`aria-label` or `aria-labelledby`), this section is not exposed to assistive technology as a landmark region — see Compliance.
- **Semantic navigation**: Navigation links use standard `<a>` elements with `href` attributes; not marked as buttons. They sit inside a plain `<div className="lp-tour__steps">`, not a `<nav>` landmark, so assistive technology reaches them as ordinary links rather than through a named navigation region.
- **Arrow decorative status**: Left and right arrow characters are marked `aria-hidden="true"` as they are visual indicators duplicating semantic link content
- **Label clarity**: Navigation step labels (the `<b>` text) provide clear, concise descriptions of destination
- **Note clarification**: Optional note text in `<em>` provides clarification of what the reader gains by following the link
- **Pillar structure**: Pillar cards render with semantic heading (`<h3>`) and paragraph (`<p>`) to convey structure to assistive technology
- **Eyebrow context**: Eyebrow text provides step progress context to all users
- **Touch targets**: This recipe sets no touch-target minimum for inline links that might appear inside `promise` content — that's the caller's typography choice. The back/next step links this component renders are block-level anchors; the source does not specify their spacing, which is controlled entirely by CSS.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tour-001 | render-eyebrow | `eyebrow: "Masterbrand Overview"`, `position: { step: 1, total: 3 }` | Eyebrow text reads "Step 1 of 3 · Masterbrand Overview" |
| tour-002 | render-promise | `promise: "Welcome to the tour"` | Promise text renders inside a `<p>` with class `lp-tour__promise` |
| tour-003 | render-as-tour-screen | All required props provided | Component renders within `Screen` with `id="tour"` and class `lp-tour` |
| tour-004 | render-pillars-when-provided | `pillars: [{ title: "Design", body: "..." }, { title: "Code", body: "..." }, { title: "Ship", body: "..." }]` | Three cards render under `lp-tour__pillars` div, each with title in `h3` and body in `p` |
| tour-005 | omit-navigation-when-absent, steps-container-always-renders | `back: undefined`, `next: undefined` | No navigation links render; `lp-tour__steps` div is still present but contains no links |
| tour-006 | render-back-navigation | `back: { href: "/tour/prev", label: "Previous", note: "See how it started" }` | Link renders with class `lp-tour__step--back`, left arrow with `aria-hidden="true"`, label in `<b>`, note in `<em>` |
| tour-007 | render-next-navigation | `next: { href: "/tour/next", label: "Next", note: "Continue deeper" }` | Link renders with class `lp-tour__step--next`, right arrow with `aria-hidden="true"`, label in `<b>`, note in `<em>` |
| tour-008 | accept-note-on-navigation-steps | `back: { href: "...", label: "...", note: undefined }` | Note element does not render when `note` is undefined; link still renders with label and arrow |
| tour-009 | hide-arrow-from-assistive-tech | Navigation links present | Both arrow `<span>` elements have `aria-hidden="true"` attribute |
| tour-010 | accept-react-node-promise | `promise: <>Multiline <strong>promise</strong> with fragments</>` | Fragment and child elements render correctly within promise paragraph |
| tour-011 | render-pillars-when-provided | `pillars: []` | Pillars section (`lp-tour__pillars` div) does not render |
| tour-012 | render-pillars-when-provided | `pillars: undefined` | Pillars section does not render; no `lp-tour__pillars` div in output |
| tour-013 | omit-navigation-when-absent | `back: { href: "/tour/prev", label: "Previous" }`, `next: undefined` | Only the back link renders inside `lp-tour__steps`; no next link is present (Last step state) |

## Edge Cases

- **Empty pillars array**: When `pillars` is provided but has zero length, the entire pillars section does not render (conditional on `length > 0`).
- **Undefined pillars**: When `pillars` prop is undefined, no pillar rendering occurs and no error is thrown; this is the normal state for a leaf site (see Design Decisions).
- **Missing navigation**: When both `back` and `next` are undefined (e.g., a single-stop tour or an isolated view), the navigation container still renders but contains no links.
- **Out-of-range position values**: The component does not validate `position.step` or `position.total` (for example `step` less than 1, `step` greater than `total`, a non-integer, or `total` less than or equal to 0); it renders whatever the format string produces (e.g., "Step 0 of 3") without throwing or clamping.
- **Block-level promise content**: Because `promise` renders inside a `<p>` element, passing block-level content (a heading, a `<div>`, etc.) produces invalid HTML nesting; callers should limit `promise` to phrasing content such as text, `<strong>`, `<em>`, or inline fragments.
- **Single instance per page**: The `id="tour"` on the root `Screen` is hardcoded, not exposed as a prop, so only one Tour Strip should render per page; a second instance would produce a duplicate DOM id.
- **Long eyebrow text**: No maximum length is enforced in the component; rendering and wrapping behavior are determined by CSS styling.
- **Long step labels**: Navigation label text length is not constrained; truncation or wrapping is controlled by CSS.
- **Long note text**: Optional note text has no length limit; layout behavior defers to CSS styling for the `<em>` element.
- **Complex promise content**: The `promise` prop accepts any React node; nested components, fragments, or HTML elements render as provided by the caller.
- **Pillar with missing fields**: If a pillar object lacks `title` or `body`, or either is empty string, those fields render as-is (no fallback text or placeholder).

## Configuration

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `eyebrow` | string | Yes | — | Text label for the tour step (e.g., "Introduction"). Rendered in step progress header. |
| `promise` | ReactNode | Yes | — | Primary headline or message for this tour stop. Accepts any valid React node for composability. |
| `position` | object | Yes | — | Object with `step` (current step number, 1-indexed) and `total` (total steps in tour). Used for progress display. |
| `pillars` | TourPillar[] | No | undefined | Optional array of pillar cards, each with `title` (string) and `body` (string). Omitted or empty array disables pillar rendering. |
| `back` | TourStep | No | undefined | Optional navigation step for previous tour stop, with required `href` (string) and `label` (string), and optional `note` (string). When undefined, back link does not render. |
| `next` | TourStep | No | undefined | Optional navigation step for next tour stop, with required `href` (string) and `label` (string), and optional `note` (string). When undefined, next link does not render. |

## Deep Linking

Not applicable: routing is owned by the host application. `back` and `next` hrefs are supplied by the caller's router; this component does not define or manage its own URL scheme.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| N/A | "Step {step} of {total} · " | Hardcoded English progress prefix built inline in the source, not read from a resource file. The `eyebrow`, `promise`, and step `label`/`note` strings are supplied by the caller and can be localized there. |

The `←`/`→` arrow glyphs are hardcoded Unicode characters and do not mirror for right-to-left locales; see Compliance.

## Accessibility Options

Not applicable: Component renders static layout and navigation with no motion, audio, or dynamic display options to respond to. Navigation links use standard `<a>` elements which inherit platform focus management; no component-specific accessibility preferences apply.

## Feature Flags

Not applicable: Component has no feature flag gating or conditional rendering controlled by flag state.

## Analytics

Not applicable: Component does not emit analytics events directly. Analytics instrumentation (view, click) is managed by the hosting page or router based on navigation link interactions.

## Privacy

Not applicable: Component does not collect, store, or transmit user data beyond standard navigation tracking inherited from link semantics.

## Logging

Not applicable: Component does not emit log messages or events.

## Platform Notes

- **React/Web**: TourStrip is a functional component receiving props and rendering JSX. Styling is applied via CSS classes (`lp-tour`, `lp-tour__promise`, `lp-tour__pillars`, `lp-tour__steps`, `lp-tour__step`, `lp-tour__step--back`, `lp-tour__step--next`, `lp-tour__arrow`, `lp-card`, `lp-eyebrow`). Layout is managed by parent `Screen` and `Wrap` components for site-wide consistency. Navigation state (back/next presence) is determined by the router or tour orchestrator; the component is stateless.
- **SwiftUI**: Translate to a full-screen view containing a top section for eyebrow text and promise headline, optional pillar cards in a grid (`VStack` or `LazyVGrid`), and bottom navigation buttons styled as links. Since `href` is a URL string rather than a typed navigation value, use `Link(destination:)` for the back/next hrefs, or delegate to the host app's router/URL-handling abstraction — `NavigationLink` is for value-based navigation within a `NavigationStack` and doesn't fit a raw URL. Conditional rendering (`if back != nil`) handles absent navigation steps.
- **Compose**: Implement as a Composable function receiving the same data model. Use `LazyVerticalGrid` or `Column` for layout; render eyebrow and promise in a top section, pillar `Card` composables in a grid, and `TextButton` or `ClickableText` for navigation links. Platform-appropriate spacing and colors apply. State management (current step, tour walk) is external.
- **AppKit / UIKit**: Build a view controller or view containing a vertical stack with eyebrow label, promise view (rendered from the app's own content model, not HTML), optional pillar cards in a collection view or table, and bottom navigation buttons or text views styled as links. Use Auto Layout for responsive layout. Route the back/next hrefs through platform link handling (`UIApplication.shared.open(url:)` / `NSWorkspace.shared.open(url:)`) or the host's router; navigation is managed by the hosting navigation controller or router.
- **WinUI 3**: Implement as a XAML UserControl with a `StackPanel` (vertical) or `Grid` for layout. Eyebrow renders as a `TextBlock`; promise as rich text or `TextBlock`. Pillars render as a `GridView` or `ItemsControl` of cards, each a `Border` with nested `TextBlock` elements. Navigation links are `HyperlinkButton` elements styled to match web appearance (arrow glyphs, underline state). Use `Visibility` binding to show/hide back and next buttons based on props.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/TourStrip.tsx` | unverified |

## Design Decisions

**Decision**: The eyebrow (step progress) renders before the promise headline.
**Rationale**: A reader arriving mid-tour needs to know where they are in the walk before engaging with the page's pitch; ordering the progress indicator first minimizes disorientation.
**Approved**: pending

**Decision**: Pillars and navigation render lower within this single full-viewport screen, after the eyebrow and promise, rather than being the first thing shown.
**Rationale**: Keeping the reader's initial focus on orientation and the headline, before offering supporting detail or a way onward, reduces cognitive load on entry without requiring more than one viewport.
**Approved**: pending

**Decision**: Back/next navigation renders as plain anchors (`<a>`) rather than styled buttons.
**Rationale**: Plain links reduce visual weight and read as a progression between related pages in the tour walk, rather than a panel or modal control.
**Approved**: pending

**Decision**: Pillars are optional and populated only on the hub ("masterbrand") site's tour; individual product ("leaf") sites in the same site network omit them.
**Rationale**: A leaf site's tour stays focused on that site's single call to action; the masterbrand site is the one place a multi-pillar overview is worth showing.
**Approved**: pending

**Decision**: `back` and `next` steps accept an optional `note` shown below the label.
**Rationale**: Naming the benefit of proceeding, or returning, reduces the reader's hesitation when deciding whether to follow the link.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: native `<a>` elements carrying visible text labels give screen-reader-support and keyboard-navigable a pass; the arrows are correctly `aria-hidden` but the steps sit in a plain `div` rather than a `<nav>` landmark, so semantic-markup is partial; touch-target-size is partial because spacing is left entirely to CSS the source doesn't show; and the hardcoded `Step {step} of {total} ·` string plus the fixed, non-mirroring `←`/`→` glyphs fail no-hardcoded-strings and rtl-layout-support. `separation-of-concerns` passes because `TourStrip.tsx` is pure presentation over its props with no business logic, and `unit-test-coverage` passes on `TourStrip.test.tsx`'s exercise of its position text, sibling links, pillar rendering, and back/next omission.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; split the first-screen requirement into a testable claim plus a host-integration note; added steps-container-always-renders; removed the missing-href edge case now that TourStep requires href/label; added position-value, block-content, and single-instance edge cases; added tour-011 through tour-013 test vectors and fixed the tour-002 invalid-HTML input and the tour-003 quote typo; corrected the Screen-landmark and navigation-region accessibility claims and reworded the touch-target bullet; documented the hardcoded progress string and non-mirroring arrows in Localization; reformatted Compliance with linked, lowercase-status checks; reformatted Design Decisions into decision/rationale/approved entries and defined masterbrand/leaf-site terms; corrected the SwiftUI and AppKit/UIKit platform notes for URL-based navigation and dropped the WinUI 3 motion suggestion; marked Deep Linking not applicable to host-owned routing; added depends-on (Screen, Wrap) and related (Landing Card) links. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
