---
id: ca0fb28f-7f22-4fde-a291-ecfde846f5c3
title: "Pagination"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Controlled Prev / Page X of Y / Next pager on the shared Button; renders nothing at one page, disables the edges."
platforms:
  - typescript
  - web
tags:
  - component
  - pagination
  - pager
  - navigation
  - ui
depends-on:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
related: []
references: []
approved-by: ""
approved-date: ""
---

# Pagination

## Overview

The shared `Pagination` in `@adh-sdk/ui` — the list pager used above and below
paged surfaces in the host application. It is a compact `Prev` / "Page X of Y" / `Next` control: a
centered `nav` landmark holding two shared `Button`s (`variant="outline"`,
`size="sm"`) around a mono caption.

It is fully **controlled**: the host owns `page` and `totalPages` and receives
`onPageChange(nextPage)` when a button is clicked — the pager renders the host's truth
and requests a change rather than keeping its own counter. When there is only one page
(`totalPages <= 1`) it renders nothing, so call sites never wrap it in their own
`{totalPages > 1 && …}` conditional. The `Prev` button is disabled on the first page
and `Next` on the last, so an out-of-range request can never be issued from the edges.

A single export ships from `@adh-sdk/ui/components/pagination`: the `Pagination`
component. It carries `"use client"` (it composes the client `Button`) but holds no
internal state — the displayed page is always the `page` prop.

## Behavioral Requirements

- **hides-when-single-page**: When `totalPages` is `<= 1`, the component MUST render nothing.
- **renders-pagination-landmark**: The component MUST render a `nav` element with `aria-label="Pagination"`.
- **shows-page-caption**: The component MUST render a `Page {page} of {totalPages}` caption reflecting the current props.
- **disables-prev-on-first**: When `page <= 1`, the component MUST disable the `Prev` button.
- **disables-next-on-last**: When `page >= totalPages`, the component MUST disable the `Next` button.
- **pages-backward**: Clicking `Prev` MUST call `onPageChange` with `page - 1`.
- **pages-forward**: Clicking `Next` MUST call `onPageChange` with `page + 1`.
- **controlled-page**: The component MUST reflect the `page` prop directly and MUST NOT advance the page on its own — a new page appears only when the host re-renders with a new `page`.
- **forwards-classname**: The component MUST merge a consumer `className` onto the `nav` via `cn()`.

## Appearance

```
[ Prev ]     Page 3 of 5     [ Next ]
 outline      mono, muted      outline
 size sm      xs caption       size sm
```

- Row: `nav` with `flex items-center justify-center gap-2`, centered; extra classes
  merge via `cn()` through `className`.
- `Prev` / `Next`: the shared `Button` with `variant="outline"` and `size="sm"`, plain
  text labels.
- Caption: `<span>` with `px-1 font-mono text-xs text-apt-text-muted`, reading
  `Page {page} of {totalPages}`.
- Disabled edge buttons inherit `Button`'s disabled treatment (`opacity-50`,
  `pointer-events-none`).
- Token-driven (`apt-text-muted`); no raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| Single page (`totalPages` ≤ 1) | Renders nothing |
| First page (`page` ≤ 1) | `Prev` disabled (dimmed, non-interactive); `Next` enabled |
| Middle page | Both `Prev` and `Next` enabled |
| Last page (`page` ≥ `totalPages`) | `Next` disabled; `Prev` enabled |
| Hover / focus / pressed | Inherited from `Button` outline (background lift, focus-visible ring, press dip) |

## Accessibility

- The pager is a `<nav aria-label="Pagination">` landmark, so assistive tech can jump
  straight to it and tell it apart from other `nav`s on the page.
- `Prev` and `Next` are real buttons with visible text labels (no icon-only
  ambiguity), disabled through the native `disabled` attribute at the bounds — so AT
  announces them as unavailable and skips them in the focus order.
- The `Page X of Y` caption is visible, textual position that anyone can read; it is
  plain text with no `aria-live` attribute, so a page change is **not** announced to a
  screen reader automatically — an assistive-technology user must return focus to the
  caption (or navigate through it) to learn the new page number.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | hides-when-single-page | render `<Pagination page={1} totalPages={1} onPageChange={fn} />` | renders nothing (empty container) |
| T2 | renders-pagination-landmark, shows-page-caption | `page={1} totalPages={3}` | a `nav[aria-label="Pagination"]` containing the caption `"Page 1 of 3"` |
| T3 | disables-prev-on-first | `page={1} totalPages={3}` | `Prev` button is disabled |
| T4 | pages-forward | `page={1} totalPages={3}`, click `Next` | `onPageChange` called with `2` |
| T5 | disables-next-on-last, shows-page-caption | `page={3} totalPages={3}` | caption `"Page 3 of 3"`; `Next` button disabled |
| T6 | pages-backward | `page={3} totalPages={3}`, click `Prev` | `onPageChange` called with `2` |
| T7 | controlled-page | rerender from `page={1}` to `page={2}` (`totalPages={3}`) | caption updates to `"Page 2 of 3"`; neither button disabled |
| T8 | forwards-classname | `className="mt-4"` | `nav` element carries the `mt-4` class |
| T9 | hides-when-single-page | `page={1} totalPages={0}` | renders nothing (empty container) |
| T10 | shows-page-caption, disables-next-on-last | `page={5} totalPages={3}` | caption `"Page 5 of 3"`; `Next` button disabled |
| T11 | disables-prev-on-first | `page={1} totalPages={3}` | `Next` button is enabled |
| T12 | disables-next-on-last | `page={3} totalPages={3}` | `Prev` button is enabled |

## Edge Cases

- `totalPages` of `1` or `0` collapses the whole pager to `null`; hosts must rely on
  that and not add their own visibility guard.
- At the bounds the edge button is `disabled`, so `onPageChange(0)` or
  `onPageChange(totalPages + 1)` can never fire from a click — the component protects
  the edges by disabling rather than by clamping the emitted number.
- An out-of-range `page` from the host (e.g. `page={5}` with `totalPages={3}`) is
  reflected faithfully: the caption shows `"Page 5 of 3"` and `Next` stays disabled
  (`5 >= 3`); clamping the page into range is the host's responsibility, not the pager's.
- Being controlled, nothing changes visually on click until the host applies the new
  `page` — `onPageChange` is a request, not a self-mutation.
- The component performs no validation on `page` or `totalPages`. A `NaN` value fails
  both the `<=` and `>=` bounds checks, so neither `Prev` nor `Next` is disabled and the
  caption renders the literal text `"NaN"`; a negative or non-integer value is compared
  and displayed exactly as given (e.g. `page={-3}` disables `Prev` since `-3 <= 1`, and
  `page={2.5}` renders `"Page 2.5 of 5"`). Passing well-formed integers is the host's
  responsibility.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `page` | `number` | required | Current 1-based page; drives the caption and which edge is disabled. |
| `totalPages` | `number` | required | Total page count; `<= 1` renders nothing. |
| `onPageChange` | `(page: number) => void` | required | Called with the requested page (`page ± 1`) when `Prev`/`Next` is clicked. |
| `className` | `string` | — | Extra classes merged onto the `nav` via `cn()`. |

## Deep Linking

Not applicable: pagination is a presentational control within a list surface and does not represent an independent navigation destination. The host owns the page state and URL routing.

## Localization

The component renders hard-coded English UI chrome — `"Prev"`, `"Next"`, and the
`"Page {page} of {totalPages}"` caption — directly in JSX. These strings are
user-facing: a sighted user reads them and a screen reader announces the button
labels, so they are not exempt from localization simply because they are "chrome"
rather than content. The source has no `labels` prop, formatter, or other override
mechanism, so a host rendering `Pagination` in a non-English UI displays this English
text as-is; supplying localized labels is the host's responsibility until the
component grows one.

## Accessibility Options

The component uses semantic `nav` and `button` elements with standard focus and
keyboard interaction. It does not apply transitions, transforms, or animations, so
there is nothing for Reduce Motion to affect. It does not use color alone to convey
state (disabled buttons use the native `disabled` attribute, not color). Contrast and
Dynamic Type are both inherited: the component sets no font size or color itself
beyond the muted-caption text token, so contrast comes from that token and from the
family `Button`'s styling, and text scaling comes from the browser/OS text-size
setting acting on that same inherited styling.

## Feature Flags

Not applicable: the component has no conditional behavior or experimental features requiring feature flags. The three button states (enabled, disabled at bounds, missing at single page) are all determined by the `page` and `totalPages` props.

## Analytics

Not applicable: `Pagination` is a presentational control; paging semantics, session tracking, and any analytics belong to the host that owns the list and the `page` state, not the pager itself.

## Privacy

Not applicable: the component does not collect, store, or transmit any user data. It receives `page` and `totalPages` as numbers and emits page-change requests; no personal information is processed.

## Logging

No logging. `Pagination` is a presentational control; paging semantics and any event tracking belong to the host that owns the list and the `page` state, not the pager.

## Platform Notes

- **React/Web**: File `packages/web/packages/ui/src/components/pagination.tsx`. Carries `"use client"` because it composes the client `Button` and renders on the browser; holds no internal state. Composes the shared `Button` (outline/sm variant); no bespoke UI chrome. Layout is flexbox (`flex items-center justify-center gap-2`) with Tailwind utilities; token-driven via `apt-text-muted` for the caption. Demo in `ui-showcase` (Composite controls group); `PaginationDemo` component owns the page state.

- **SwiftUI**: Start from an `HStack` containing two `Button` views and a `Text` view. The equivalent structure is a controlled component receiving `page`, `totalPages`, and an `onPageChange` closure. Buttons default to SwiftUI's native button style (e.g. `.buttonStyle(.bordered)`); the family `Button`'s outline/small look is available as an optional match to the web appearance, not the default. Collapse the entire stack to `EmptyView()` when `totalPages <= 1` — the render-nothing behavior every platform shares. Disable the leading (previous) button when `page <= 1` and the trailing (next) button when `page >= totalPages`, with each button's accessible name matching its visible text (`"Prev"` / `"Next"`), the same accessible-name convention every other platform uses. The caption displays `"Page \(page) of \(totalPages)"` in a monospace font with muted text color; it scales with Dynamic Type automatically through SwiftUI's default font styles, so no extra modifier is required.

- **Compose**: Build from a `Row` composable containing two `Button` composables (using the family Button style or Material Button) and a `Text` displaying the page caption. The pattern is identical to React: fully controlled, host owns state. Return `null` when `totalPages <= 1`. Buttons are disabled based on page bounds (`page <= 1` for back, `page >= totalPages` for forward), with each button's accessible name matching its visible text (`"Prev"` / `"Next"`). Use `Modifier.fillMaxWidth()` and `horizontalArrangement = Arrangement.Center` for centering. Caption uses monospace font (`FontFamily.Monospace`) and muted text color. The `onClick` lambdas call the `onPageChange` callback with `page - 1` or `page + 1` respectively.

- **AppKit / UIKit**: Assemble an `NSStackView` (macOS) or `UIStackView` (iOS) with `axis = .horizontal`, `alignment = .center`, `distribution = .fill`, and `spacing = 8pt`; center the stack view itself within its container via Auto Layout constraints (matching the web row's `justify-center`). Add two `NSButton` / `UIButton` instances defaulting to the platform's native bordered button style — the family `Button`'s outline appearance is available as an optional match to the web look, not the default — separated by an `NSTextField` / `UILabel` showing the page caption. The component is fully controlled: update the button `isEnabled` state based on page bounds, hide the entire stack (`isHidden = true`) when `totalPages <= 1`, and update the label text when `page` changes; because stack views remove hidden subviews from layout, this behaves like the render-nothing behavior on every other platform, taking no space. Avoid custom `drawRect` styling; use the platform's standard button appearance APIs for a native look and correct accessibility behavior. The caption uses a monospace system font (e.g., `NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)` on macOS) at 11pt with muted text color.

- **WinUI 3**: Build from a `StackPanel` with `Orientation="Horizontal"` and `HorizontalAlignment="Center"`. Include two `Button` elements defaulting to the standard Fluent `Button` appearance — the outline appearance is available as an optional match to the web look, not the default — and a `TextBlock` for the page caption. Bind button `IsEnabled` to computed properties based on page bounds. Use `Visibility.Collapsed` when `totalPages <= 1`; unlike hiding via opacity, `Collapsed` removes the element from layout entirely, matching the render-nothing behavior on every other platform (it does not "preserve layout"). Set each button's `AutomationProperties.Name` to match its visible text (`"Prev"` / `"Next"`) — the same accessible-name convention every other platform uses, not distinct strings like "Previous page" / "Next page". The caption renders as `"Page {page} of {totalPages}"` using `FontFamily="Cascadia Mono"` at 11pt with a muted text color token from the Fluent 2 palette. Bind `Text` and button states to backing properties so the host can drive page changes through property binding.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/pagination.tsx` | unverified |

## Design Decisions

**Decision**: Pagination is fully controlled — `page`, `totalPages`, and `onPageChange` are all inputs.
**Rationale**: The pager renders the host's truth and requests a change, so it stays in lockstep with URL/query state the host already tracks instead of forking a second counter.
**Approved**: pending

**Decision**: The component renders `null` at `totalPages <= 1` rather than leaving that check to the host.
**Rationale**: Collapsing itself when there is a single page means every call site is just `<Pagination …/>` with no surrounding `{totalPages > 1 && …}`, so the visibility rule lives in exactly one place.
**Approved**: pending

**Decision**: `Prev`/`Next` are disabled at the bounds (`page <= 1`, `page >= totalPages`) rather than clamping the emitted page number.
**Rationale**: Disabling at the edges means an out-of-range request can't be issued at all; the component trusts the host to keep `page` in range rather than second-guessing it.
**Approved**: pending

**Decision**: Use a two-button `Prev`/`Next` pager with a `Page X of Y` caption rather than a numbered page strip.
**Rationale**: This stays compact and predictable for the list surfaces it serves, avoiding the layout churn of a windowed page-number row.
**Approved**: pending

**Decision**: Compose the shared `Button` (outline/sm) for both controls rather than building bespoke buttons.
**Rationale**: The pager inherits the family focus ring, disabled treatment, and press feel for free.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-touch-targets](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/96ee76d6-3d8d-5293-87c9-af3666bee301) | partial | Platform Compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | partial | Platform Compliance |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on: the source's native `nav`/`button` elements and visible-text button
labels (`screen-reader-support`, `keyboard-navigable`, `semantic-markup`); its
token-driven, hex-free styling that composes the shared `Button` rather than a bespoke
control (`platform-theming`, `native-controls-preference`); the absence, in this file,
of a computed pixel size, contrast value, or platform design-language audit for
`dynamic-type-support`, `contrast-ratio`, `touch-target-size`, `platform-touch-targets`,
and `platform-design-language` (all delegated to the family `Button` and inherited
tokens, unverifiable from this source alone); the CSS flex-row layout's un-audited
behavior under `dir="rtl"` for `rtl-layout-support`; and the hard-coded `"Prev"`,
`"Next"`, and `"Page {page} of {totalPages}"` strings, interpolated with no
`Intl`/formatter call, for `string-externalization`, `no-hardcoded-strings`, and
`locale-aware-formatting`. `separation-of-concerns` passes because `Pagination`
does one thing — render Prev/label/Next for a controlled `page`/`totalPages` —
composing the shared `Button` rather than duplicating its styling.
`unit-test-coverage` passes because `stat.test.tsx`'s `Pagination` suite covers
rendering nothing for a single page, disabling Prev/Next at the boundaries, and
paging both directions.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Restored on-main 1.0.0 row (recipe); added best-practices Compliance rows. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: correct the Localization and caption-announcement claims to match the source; reformat Design Decisions and the Compliance table (add Internationalization and Platform Compliance checks); make platform-native controls the default in Platform Notes and align accessible names/collapse behavior across platforms; fix incorrect platform APIs; add edge case and T9–T12 test vectors for invalid/out-of-range input; shorten summary and generalize the Overview's app reference. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Add all required template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy); expand Platform Notes to provide translation guidance for all five platforms (SwiftUI, Compose, React/Web, AppKit/UIKit, WinUI 3); update to review status. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the controlled Prev/Next Pagination pager on shared Button. |
