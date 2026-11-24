---
id: 5e401b96-7157-4c5b-a623-b90dde372231
title: "Section Header"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A layout header for content sections with title, optional eyebrow label, help popover, and action slots."
platforms:
  - typescript
  - web
tags:
  - layout
  - header
  - structure
depends-on:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
  - fd3575ab-c4a4-480d-84ff-317a282bc359
related: []
references: []
approved-by: ""
approved-date: ""
---

# Section Header

## Overview

A section header is a layout component that anchors a content area with a prominent title, an optional descriptive eyebrow label, contextual help, and action controls. Commonly used to introduce major sections of a dashboard or content view. The component organizes a left section (title and eyebrow) and right section (actions and help) in a horizontal flex layout with clear visual hierarchy. A header that names its whole pane can opt in with `paneTitle`, and inside a detail stack its title then moves up into the stack's detail strip (see the Detail Title ingredient, [adhsdk.ingredient.ui.blocks.detail-title](cookbook:fd3575ab-c4a4-480d-84ff-317a282bc359)), leaving the eyebrow, actions and help in the pane.

## Behavioral Requirements

"Empty," for the `eyebrow`, `help`, and `actions` props below, means any JavaScript falsy value — `undefined`, `null`, `false`, or the empty string `""` — since each slot is guarded by a truthy check (`{prop && ...}`) in the source. This definition is also used by the Configuration table below.

- **render-title**: Unless the title is hoisted (see pane-title-hoisted), the component MUST render the `title` prop content as an h2 heading.
- **pane-title-opt-in**: The `paneTitle` prop MUST default to false; a header without it MUST draw its own title in place even inside a detail stack, because a pane can head several sections with this one component.
- **pane-title-hoisted**: When `paneTitle` is true and the enclosing detail stack accepts the title, the component MUST hand `title` to the stack's detail strip through `useDetailTitle` (see [adhsdk.ingredient.ui.blocks.detail-title](cookbook:fd3575ab-c4a4-480d-84ff-317a282bc359)) and MUST NOT draw the h2 in the pane.
- **hoisted-keeps-chrome**: While the title is hoisted, the component MUST still render `eyebrow`, `actions` and `help` in their usual places.
- **hoisted-bare-collapse**: While the title is hoisted and `eyebrow`, `help` and `actions` are all empty, the component MUST render only the hand-off and no wrapper element, so nothing of it remains in the pane.
- **last-pane-title-wins**: When two or more `paneTitle` headers register in one stack, the one that registered last MUST hold the strip, and each earlier one MUST draw its h2 in place (the registration rule is **pane-hoisted-rule** in [adhsdk.ingredient.ui.blocks.detail-title](cookbook:fd3575ab-c4a4-480d-84ff-317a282bc359)).
- **title-fallback-inline**: When `paneTitle` is true but no stack accepts the title (no enclosing stack or slot, the title suppressed for a hidden pane, the server render, or another header registered later), the component MUST draw the h2 inline as it would without `paneTitle`.
- **support-eyebrow**: The component MUST render the `eyebrow` prop when it is provided and non-empty; when `eyebrow` is empty, the eyebrow slot MUST NOT be rendered.
- **support-help**: The component MUST render a help trigger button when the `help` prop is provided and non-empty; when `help` is empty, the help trigger button MUST NOT be rendered.
- **support-actions**: The component MUST render the `actions` prop content when it is provided and non-empty; when `actions` is empty, the actions slot MUST NOT be rendered.
- **apply-custom-class**: The component MUST apply the `className` prop to the root container if provided, except in the hoisted-bare-collapse case (see **hoisted-bare-collapse**), where there is no root container and `className` is silently dropped.
- **display-help-popover**: When the help trigger button is activated — by click, or by keyboard Enter or Space while focused — the component MUST display a popover containing the `help` prop content, positioned below and aligned to the end (right edge). See the **escape-closes** and **return-focus-on-close** requirements of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) for how the popover closes and returns focus, and the **aria-expanded** requirement of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) for its open/closed toggle state.
- **label-help-trigger**: The help trigger button MUST have an accessible label "About this section" via the `aria-label` attribute.
- **maintain-layout-order**: Left section (title area) MUST be positioned before right section (actions and help) in visual and DOM order.

## Appearance

- **Layout**: Flex container (`flex items-start justify-between gap-4`). The left section (title/eyebrow) has no flex-shrink override, so by default it may shrink and its content may wrap; the right section (actions/help) is `shrink-0` and never shrinks, so actions and the help trigger are never compressed.
- **Left section spacing**: Vertical stack with `space-y-1` between eyebrow and title.
- **Eyebrow font**: Monospace, 0.65rem (10.4px), uppercase, tracking-wider, color uses `apt-text-dim` semantic token.
- **Title font**: Monospace, text-sm (14px), font-medium (500 weight), tracking-wide, color uses `apt-gold` semantic token.
- **Help button**: Uses `quietControlClass` for muted styling; icon is 16×16px CircleHelp (lucide-react).
- **Help popover**: Width of 288px (`w-72`), capped at the available width by the Popover's `max-w-(--available-width)`, positioned at `bottom` and aligned to `end` (right edge).
- **Hoisted title**: When hoisted, the pane holds no h2; the title is drawn by the detail strip's own title cell, with its styling.
- **Right section spacing**: Flex with `gap-2` between actions and help button; `shrink-0` prevents flex shrinking.

## States

| State | Appearance change |
|-------|------------------|
| Default (no eyebrow, no help, no actions) | Title only, left-aligned. |
| With eyebrow | Eyebrow rendered above title in dim monospace. |
| With help | Help trigger button displayed in right section; interactive. |
| With actions | Actions rendered in right section before help button. |
| Help popover open | Popover appears below the help trigger, aligned to the end (right edge), with the `help` content visible. |
| Custom className | Additional classes merged with root container. |
| `paneTitle` with a stack that takes the title | Title leaves the pane for the detail strip; eyebrow, actions and help stay. |
| `paneTitle` with nothing else to show | No element is left in the pane. |

## Accessibility

- **Semantic heading**: Title is rendered as an `<h2>` to establish document outline hierarchy.
- **Help button label**: `aria-label="About this section"` describes the button purpose for screen readers.
- **Popover keyboard**: The help trigger is activated by click, Enter, or Space. Opening, closing (Escape or an outside interaction), and returning focus to the trigger are the underlying Popover component's behavior — see the **escape-closes** and **return-focus-on-close** requirements of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)).
- **Text content**: Eyebrow and title content are read as-is; no additional aria-labels required if text is meaningful.
- **title-contrast**: NEEDS REVIEW: Not implemented in source. The title uses the `apt-gold` token and the eyebrow `apt-text-dim` at 0.65rem; the source states no contrast ratio against the surface in any theme, so a per-theme measurement against 4.5:1 (WCAG 1.4.3) would settle it.
- **Hoisted heading**: When hoisted, the heading semantics come from the strip's title cell (`role="heading"`, `aria-level="2"`), not from an h2 in the pane.
- **Icon-only button**: Help button contains only an icon; `aria-label` is REQUIRED to provide accessible name.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| section-header-001 | render-title | `title="All ecosystems"` | h2 heading with text "All ecosystems" rendered in left section |
| section-header-002 | support-eyebrow | `eyebrow="Section"`, `title="Title"` | Eyebrow text rendered above title in dim monospace; title rendered below in gold monospace |
| section-header-003 | support-eyebrow | `title="Title"` (no eyebrow) | Only title rendered; eyebrow slot absent from DOM |
| section-header-004 | support-help | `help={<div>Help content</div>}`, `title="Title"` | Help button visible in right section |
| section-header-005 | support-help | `title="Title"` (no help) | Help button not rendered |
| section-header-006 | display-help-popover | Help button present, user clicks help trigger | Popover appears; popover content (help prop) is visible; popover positioned below trigger, aligned right |
| section-header-007 | display-help-popover | Help button present, user presses Enter on focused help trigger | Popover opens (same as click) |
| section-header-008 | label-help-trigger | Help button rendered | Button has `aria-label="About this section"` |
| section-header-009 | support-actions | `actions={<button>Action</button>}`, `title="Title"` | Actions content rendered in right section, before help button |
| section-header-010 | support-actions | `title="Title"` (no actions) | Actions slot absent from DOM |
| section-header-011 | apply-custom-class | `className="my-custom-class"`, `title="Title"` | Root container has both default flex classes and "my-custom-class" |
| section-header-012 | maintain-layout-order | All props provided | Left section (title area) precedes right section (actions + help) in visual layout; justified to opposite edges |
| section-header-013 | display-help-popover | Help button present, user presses Space on focused help trigger | Popover opens (same as click/Enter) |
| section-header-014 | display-help-popover | Popover open, user presses Escape | Popover closes and focus returns to the help trigger (per the **escape-closes** and **return-focus-on-close** requirements of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))) |
| section-header-015 | display-help-popover | Help button activated a second time while the popover is open | Popover closes; toggle state is reflected via `aria-expanded` (per the **aria-expanded** requirement of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))) |
| section-header-016 | pane-title-hoisted, pane-title-opt-in (test: "carries a SectionHeader marked paneTitle, and leaves an unmarked one where it is") | In a detail stack: `<SectionHeader paneTitle title="Providers" />` and `<SectionHeader title="Sign-in methods" />` | The strip's title cell holds "Providers"; the pane's text does not contain "Providers" but does contain "Sign-in methods" |
| section-header-017 | pane-title-opt-in | `<SectionHeader title="Title" />` inside a detail stack | The h2 "Title" is drawn in the pane and the strip is not given it |
| section-header-018 | hoisted-keeps-chrome | `paneTitle title="Providers" eyebrow="Auth" help={...}` in a detail stack | Strip holds "Providers"; the pane holds the eyebrow "Auth" and the help trigger, and no h2 |
| section-header-019 | hoisted-bare-collapse | `paneTitle title="Providers"` alone in a detail stack | Nothing is drawn in the pane; the root flex container is absent |
| section-header-020 | title-fallback-inline | `paneTitle title="Providers"` outside any stack | The h2 "Providers" is drawn inline |
| section-header-021 | last-pane-title-wins | Two `paneTitle` headers registered in one stack | The last to register is in the strip; the other draws its h2 in place |

The tests are in `sectionHeader.test.tsx`, one per vector (001 to 021). `detailTitle.test.tsx` also covers the `paneTitle` case of vector 016.

## Edge Cases

- **Empty title string**: The component does not validate `title`; passing an empty string still renders an `<h2>`, which is present in the DOM but conveys no accessible name to screen reader users. Callers MUST supply non-empty `title` content — Section Header itself performs no such check.
- **Very long title**: Title renders without an explicit wrap constraint. Because the left section has no flex-shrink override while the right section is `shrink-0`, the left section shrinks first as available width tightens, so a long title wraps onto multiple lines once space is insufficient.
- **Very long help content**: The popover has a width of 288px (capped at the available width) and no max-height constraint in the source, so the panel grows to fit the content rather than scrolling.
- **Help button focus during popover open**: Escape closes the popover and returns focus to the trigger (the **escape-closes** and **return-focus-on-close** requirements of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **Multiple rapid help button activations**: The Popover trigger toggles open/closed state on activation, reflected via `aria-expanded` (the **aria-expanded** requirement of the popover ingredient ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **Actions slot too wide**: Actions element shares right section with help button; if actions exceed available space, layout depends on actions' own flex properties. The right section container applies `shrink-0`, so it does not shrink to accommodate overflow.
- **Hoisted bare header drops className**: In the bare-collapse case the component returns only the hand-off, so a `className` passed to it has no element to land on.
- **Custom className conflicts**: If `className` prop contains flex or positioning classes, they merge via `cn()` utility; later classes may override defaults (standard Tailwind precedence).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | ReactNode | (required) | Content displayed as section heading; rendered as h2 unless hoisted by `paneTitle` |
| `eyebrow` | ReactNode \| undefined | undefined | Optional label above title; not rendered when empty (see Behavioral Requirements) |
| `help` | ReactNode \| undefined | undefined | Optional help content displayed in popover; help button not rendered when empty (see Behavioral Requirements) |
| `actions` | ReactNode \| undefined | undefined | Optional action controls rendered in right section; not rendered when empty (see Behavioral Requirements) |
| `className` | string \| undefined | undefined | Additional CSS classes merged with root container |
| `paneTitle` | boolean | false | Marks the header that names the pane, so its title moves into the stack's detail strip |

## Deep Linking

Not applicable: Section Header is a layout primitive without associated routes or deep-link targets.

## Localization

The `title`, `eyebrow`, `help`, and `actions` props accept content supplied — and localized — by the calling component; Section Header performs no text lookup of its own. The one exception is the help trigger's accessible name, which is hardcoded in the source as `aria-label="About this section"` (English only, not externalized to a resource file) — see Compliance. The eyebrow's `uppercase` CSS text-transform is also a locale-sensitive display transform (it can mis-case characters such as German "ß" or Turkish dotted/dotless "i"), not a locale-invariant operation.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Popover open/close transitions, if any, are the underlying Popover component's concern — see accessibility-options ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)). |
| Increase Contrast | No component-specific support; parent theme applies contrast adjustments to `apt-gold` and `apt-text-dim` tokens. |
| Differentiate Without Color | Eyebrow and title rely on monospace font weight and size for differentiation, not color alone. |

## Feature Flags

Not applicable: Section Header is a foundational layout component with no feature-gating.

## Analytics

Not applicable: Section Header is a layout primitive and does not track user interactions; analytics for help popover interaction delegated to parent component or Popover implementation.

## Privacy

Not applicable: Section Header does not collect, store, or transmit user data.

## Logging

Not applicable: Section Header does not emit application logs.

## Platform Notes

- **SwiftUI**: Use a `VStack` for the left section (eyebrow above title as `Text` views) and an `HStack` for the right section (actions leading, help button trailing), with a `Spacer()` between the two sections inside the outer `HStack` so they are pushed to opposite edges, matching `justify-between`. Title uses `.font(.system(size: titleSize, weight: .medium, design: .monospaced))` with `@ScaledMetric var titleSize: CGFloat = 14` (the source's 14px `text-sm`; the `.body` text style is about 17pt and would not match) and the gold semantic color; for `paneTitle`, publish the title through a `PreferenceKey` that the detail strip reads (see [adhsdk.ingredient.ui.blocks.detail-title](cookbook:fd3575ab-c4a4-480d-84ff-317a282bc359)), leaving eyebrow, actions and help in place; eyebrow uses the dim secondary text color. The help trigger is a `Button` — not a `PopoverButton`, which is not a SwiftUI type — with a `.popover(isPresented:)` modifier attached to that button (not to the top-level `HStack`), so the popover anchors to the trigger.

- **Compose**: Use a `Row` (horizontal flex) as the root container with `verticalAlignment = Alignment.Top` and `modifier = Modifier.fillMaxWidth()`. The left section is a `Column` with title and optional eyebrow `Text` composables, using `FontFamily.Monospace` (not a "default serif family") and the semantic gold color; for `paneTitle`, register the title with the stack through a `CompositionLocal` so the detail strip draws it (see [adhsdk.ingredient.ui.blocks.detail-title](cookbook:fd3575ab-c4a4-480d-84ff-317a282bc359)); give the left `Column` `Modifier.weight(1f)` so it takes the remaining space, matching `justify-between`. The right section is a `Row` for actions and the help button. The help button uses an `IconButton` wrapping a CircleHelp icon; clicking it opens a `Popup` or `DropdownMenu` — not `PopupMenu`, which is not a Compose API — anchored to the button, showing the help content.

- **React/Web**: The source is `packages/web/packages/ui/src/blocks/section-header.tsx`, built from `Popover`, `PopoverTrigger` and `PopoverContent` in `components/popover`, `quietControlClass` from `lib/quiet-control`, `cn` from `lib/utils`, the lucide `CircleHelp` icon and `useDetailTitle` from `blocks/detail-title`; its only test coverage is `__tests__/detailTitle.test.tsx`.

- **AppKit / UIKit**: Use `NSStackView` (AppKit) or `UIStackView` (UIKit) with `axis = .horizontal`, `alignment = .top`, `distribution = .fill`. Give the left stack a lower content-hugging priority than the right stack so the two sections are pushed apart, matching `justify-between`. The left stack contains the title `NSTextField` (AppKit) or `UILabel` (UIKit) and optional eyebrow label, both using the system monospace font (`.monospacedSystemFont(ofSize:weight:)`) and the gold semantic color. For `paneTitle`, register the title with the stack's view controller so the detail strip's label shows it (see %s). The right stack contains optional actions and the help button (`NSButton` / `UIButton`). The help button uses the SF Symbol `questionmark.circle` (not `circle.fill.badge.questionmark`, which does not exist) and triggers a popover with the help text via `NSPopover` (AppKit) or a `UIPopoverPresentationController` (UIKit).

- **WinUI 3**: Use a `Grid` with two columns (`*` for the left section, `Auto` for the right) as root, rather than a horizontal `StackPanel`, which cannot push its two sections apart. The left column is a `StackPanel` with `Orientation="Vertical"` containing a `TextBlock` for the title (a theme monospace resource such as Cascadia Mono, not a hardcoded `"Courier New"`, so it respects the active theme; `Foreground="{ThemeResource GoldBrush}"`) and an optional eyebrow `TextBlock` with secondary text color. The right column is a `StackPanel` with `Orientation="Horizontal"` for actions and the help button. The help button uses an `AppBarButton` or standard `Button` with a `SymbolIcon` (question-mark glyph or equivalent) and sets `AutomationProperties.Name` so assistive technology announces its purpose; for `paneTitle`, publish the title through a shared view-model that the stack's strip binds to (see [adhsdk.ingredient.ui.blocks.detail-title](cookbook:fd3575ab-c4a4-480d-84ff-317a282bc359)); clicking the help button opens a `Flyout` or `TeachingTip` to display the help content at the trigger's position — note that `TeachingTip` does not by itself trap focus, so an explicit `Flyout` with its own focus handling may be required where trapping matters.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/section-header.tsx` | confirmed (2.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Title and eyebrow use a monospace font.
**Rationale**: Creates visual distinction and hierarchy, aligned with a technical/data-focused design system; reinforces the component's use in dashboards and structured content.
**Approved**: pending

**Decision**: The section title uses the `apt-gold` semantic color token.
**Rationale**: Gold conveys prominence and primary hierarchy, distinguishing the title from standard text.
**Approved**: pending

**Decision**: The help trigger uses `quietControlClass` for muted styling.
**Rationale**: Keeps the help button visually subordinate to content, preventing distraction while remaining discoverable for users who need it.
**Approved**: pending

**Decision**: The help popover is 288px wide (`w-72`), capped at the available width.
**Rationale**: Ensures readability of help text without forcing unnecessary wrapping.
**Approved**: pending

**Decision**: The help popover is positioned below and aligned to the end (right edge) of the trigger.
**Rationale**: Follows standard popover conventions, avoids overlap with the title, and keeps the trigger button visible.
**Approved**: pending

**Decision**: The root container uses `justify-between` to left-justify the title area and right-justify actions/help.
**Rationale**: Creates a clear visual separation between content (left) and controls (right).
**Approved**: pending

**Decision**: Hoisting the title is opt-in through `paneTitle`, never automatic.
**Rationale**: A pane such as Authentication heads two sections with this one component, so only the header that names the pane may leave it.
**Approved**: pending

**Decision**: `title` is a required prop.
**Rationale**: Title is not optional because the component's purpose is to introduce a section; a section header without a title is meaningless.
**Approved**: pending

**Decision**: `eyebrow`, `help`, and `actions` are optional.
**Rationale**: Accommodates simple use cases (title-only headers) without requiring conditional rendering at call sites.
**Approved**: pending

**Decision**: The title's heading level is fixed at `<h2>`; there is no `level` or `as` prop to change it.
**Rationale**: The source hardcodes `<h2>` in every usage. This is a known limitation: nesting a Section Header inside content that already has an `<h2>` ancestor will produce an incorrect document outline. A future revision could add a `level`/`as` prop; until then, callers are responsible for keeping Section Header at a consistent outline depth.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The source renders a native `<h2>` and a native button with `aria-label="About this section"` (passed screen-reader-support, keyboard-navigable, semantic-markup); it uses `apt-*` semantic color tokens and rem-based Tailwind text sizing whose actual contrast and font-scaling behavior cannot be confirmed from this file alone (partial contrast-ratio, dynamic-type-support); it delegates focus return and Escape handling to the Popover component without specifying the help button's own hit-area size (partial focus-management, touch-target-size); and it hardcodes the English string `"About this section"` with no localization mechanism (failed no-hardcoded-strings, string-externalization). `separation-of-concerns` passes because `section-header.tsx` is pure presentation composed from its `eyebrow`/`title`/`help`/`actions` props with no business logic, and `unit-test-coverage` passes because `sectionHeader.test.tsx` has one passing test for each of the 21 conformance vectors, including the eyebrow, actions, help popover and `paneTitle` cases.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-14 | Mike Fullerton | Verified against source: corrected behavior, states and platform notes |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Qualified bare #accessibility fragments to popover's full agenticdeveloperkit URI; fixed 6 refs. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; cited the popover ingredient by requirement fragment instead of crediting behavior to "the Popover component" and added it to depends-on/related; reformatted Design Decisions into Decision/Rationale/Approved triplets and added one for the fixed h2 heading level; rewrote Compliance from "Not applicable" into a real table; fixed the flex-shrink/wrap contradiction between Appearance and Edge Cases; expanded help-popover keyboard coverage (Space, Escape, focus return, toggle) with new test vectors; corrected nonexistent APIs in the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes; rewrote Localization to name the hardcoded aria-label and the locale-sensitive uppercase transform; defined "empty" once for the optional ReactNode props and reused it in Configuration; clarified how an empty title is actually handled. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
