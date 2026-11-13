---
id: 5e401b96-7157-4c5b-a623-b90dde372231
title: "Section Header"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
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
related:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
references: []
approved-by: ""
approved-date: ""
---

# Section Header

## Overview

A section header is a layout component that anchors a content area with a prominent title, an optional descriptive eyebrow label, contextual help, and action controls. Commonly used to introduce major sections of a dashboard or content view. The component organizes a left section (title and eyebrow) and right section (actions and help) in a horizontal flex layout with clear visual hierarchy.

## Behavioral Requirements

"Empty," for the `eyebrow`, `help`, and `actions` props below, means any JavaScript falsy value — `undefined`, `null`, `false`, or the empty string `""` — since each slot is guarded by a truthy check (`{prop && ...}`) in the source. This definition is also used by the Configuration table below.

- **render-title**: The component MUST render the `title` prop content as an h2 heading.
- **support-eyebrow**: The component MUST render the `eyebrow` prop when it is provided and non-empty; when `eyebrow` is empty, the eyebrow slot MUST NOT be rendered.
- **support-help**: The component MUST render a help trigger button when the `help` prop is provided and non-empty; when `help` is empty, the help trigger button MUST NOT be rendered.
- **support-actions**: The component MUST render the `actions` prop content when it is provided and non-empty; when `actions` is empty, the actions slot MUST NOT be rendered.
- **apply-custom-class**: The component MUST apply the `className` prop to the root container if provided.
- **display-help-popover**: When the help trigger button is activated — by click, or by keyboard Enter or Space while focused — the component MUST display a popover containing the `help` prop content, positioned below and aligned to the end (right edge). See accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) and accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) for how the popover closes and returns focus, and accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) for its open/closed toggle state.
- **label-help-trigger**: The help trigger button MUST have an accessible label "About this section" via the `aria-label` attribute.
- **maintain-layout-order**: Left section (title area) MUST be positioned before right section (actions and help) in visual and DOM order.

## Appearance

- **Layout**: Flex container (`flex items-start justify-between gap-4`). The left section (title/eyebrow) has no flex-shrink override, so by default it may shrink and its content may wrap; the right section (actions/help) is `shrink-0` and never shrinks, so actions and the help trigger are never compressed.
- **Left section spacing**: Vertical stack with `space-y-1` between eyebrow and title.
- **Eyebrow font**: Monospace, 0.65rem (10.4px), uppercase, tracking-wider, color uses `apt-text-dim` semantic token.
- **Title font**: Monospace, text-sm (14px), font-medium (500 weight), tracking-wide, color uses `apt-gold` semantic token.
- **Help button**: Uses `quietControlClass` for muted styling; icon is 16×16px CircleHelp (lucide-react).
- **Help popover**: Fixed width of 288px (`w-72`), positioned at `bottom` and aligned to `end` (right edge).
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

## Accessibility

- **Semantic heading**: Title is rendered as an `<h2>` to establish document outline hierarchy.
- **Help button label**: `aria-label="About this section"` describes the button purpose for screen readers.
- **Popover keyboard**: The help trigger is activated by click, Enter, or Space. Opening, closing (Escape or an outside interaction), and returning focus to the trigger are the underlying Popover component's behavior — see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)) and accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)).
- **Text content**: Eyebrow and title content are read as-is; no additional aria-labels required if text is meaningful.
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
| section-header-014 | display-help-popover | Popover open, user presses Escape | Popover closes and focus returns to the help trigger (per accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)), accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))) |
| section-header-015 | display-help-popover | Help button activated a second time while the popover is open | Popover closes; toggle state is reflected via `aria-expanded` (per accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))) |

## Edge Cases

- **Empty title string**: The component does not validate `title`; passing an empty string still renders an `<h2>`, which is present in the DOM but conveys no accessible name to screen reader users. Callers MUST supply non-empty `title` content — Section Header itself performs no such check.
- **Very long title**: Title renders without an explicit wrap constraint. Because the left section has no flex-shrink override while the right section is `shrink-0`, the left section shrinks first as available width tightens, so a long title wraps onto multiple lines once space is insufficient.
- **Very long help content**: The popover has a fixed width (288px) and no max-height constraint in the source, so the panel grows to fit the content rather than scrolling.
- **Help button focus during popover open**: Escape closes the popover and returns focus to the trigger (accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d)), accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **Multiple rapid help button activations**: The Popover trigger toggles open/closed state on activation, reflected via `aria-expanded` (accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **Actions slot too wide**: Actions element shares right section with help button; if actions exceed available space, layout depends on actions' own flex properties. The right section container applies `shrink-0`, so it does not shrink to accommodate overflow.
- **Custom className conflicts**: If `className` prop contains flex or positioning classes, they merge via `cn()` utility; later classes may override defaults (standard Tailwind precedence).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | ReactNode | (required) | Content displayed as section heading; rendered as h2 |
| `eyebrow` | ReactNode \| undefined | undefined | Optional label above title; not rendered when empty (see Behavioral Requirements) |
| `help` | ReactNode \| undefined | undefined | Optional help content displayed in popover; help button not rendered when empty (see Behavioral Requirements) |
| `actions` | ReactNode \| undefined | undefined | Optional action controls rendered in right section; not rendered when empty (see Behavioral Requirements) |
| `className` | string \| undefined | undefined | Additional CSS classes merged with root container |

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

- **SwiftUI**: Use a `VStack` for the left section (eyebrow above title as `Text` views) and an `HStack` for the right section (actions leading, help button trailing), with a `Spacer()` between the two sections inside the outer `HStack` so they are pushed to opposite edges, matching `justify-between`. Title uses `.font(.system(.body, design: .monospaced))` with the gold semantic color; eyebrow uses the dim secondary text color. The help trigger is a `Button` — not a `PopoverButton`, which is not a SwiftUI type — with a `.popover(isPresented:)` modifier attached to that button (not to the top-level `HStack`), so the popover anchors to the trigger.

- **Compose**: Use a `Row` (horizontal flex) as the root container with `verticalAlignment = Alignment.Top` and `modifier = Modifier.fillMaxWidth()`. The left section is a `Column` with title and optional eyebrow `Text` composables, using `FontFamily.Monospace` (not a "default serif family") and the semantic gold color; give the left `Column` `Modifier.weight(1f)` so it takes the remaining space, matching `justify-between`. The right section is a `Row` for actions and the help button. The help button uses an `IconButton` wrapping a CircleHelp icon; clicking it opens a `Popup` or `DropdownMenu` — not `PopupMenu`, which is not a Compose API — anchored to the button, showing the help content.

- **AppKit / UIKit**: Use `NSStackView` (AppKit) or `UIStackView` (UIKit) with `axis = .horizontal`, `alignment = .top`, `distribution = .fill`. Give the left stack a lower content-hugging priority than the right stack so the two sections are pushed apart, matching `justify-between`. The left stack contains the title `NSTextField` (AppKit) or `UILabel` (UIKit) and optional eyebrow label, both using the system monospace font (`.monospacedSystemFont(ofSize:weight:)`) and the gold semantic color. The right stack contains optional actions and the help button (`NSButton` / `UIButton`). The help button uses the SF Symbol `questionmark.circle` (not `circle.fill.badge.questionmark`, which does not exist) and triggers a popover with the help text via `NSPopover` (AppKit) or a `UIPopoverPresentationController` (UIKit).

- **WinUI 3**: Use a `Grid` with two columns (`*` for the left section, `Auto` for the right) as root, rather than a horizontal `StackPanel`, which cannot push its two sections apart. The left column is a `StackPanel` with `Orientation="Vertical"` containing a `TextBlock` for the title (a theme monospace resource such as Cascadia Mono, not a hardcoded `"Courier New"`, so it respects the active theme; `Foreground="{StaticResource GoldBrush}"`) and an optional eyebrow `TextBlock` with secondary text color. The right column is a `StackPanel` with `Orientation="Horizontal"` for actions and the help button. The help button uses an `AppBarButton` or standard `Button` with a `SymbolIcon` (question-mark glyph or equivalent) and sets `AutomationProperties.Name` so assistive technology announces its purpose; clicking it opens a `Flyout` or `TeachingTip` to display the help content at the trigger's position — note that `TeachingTip` does not by itself trap focus, so an explicit `Flyout` with its own focus handling may be required where trapping matters.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/section-header.tsx` | unverified |

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

**Decision**: The help popover has a fixed width of 288px (`w-72`).
**Rationale**: Ensures readability of help text without forcing unnecessary wrapping.
**Approved**: pending

**Decision**: The help popover is positioned below and aligned to the end (right edge) of the trigger.
**Rationale**: Follows standard popover conventions, avoids overlap with the title, and keeps the trigger button visible.
**Approved**: pending

**Decision**: The root container uses `justify-between` to left-justify the title area and right-justify actions/help.
**Rationale**: Creates a clear visual separation between content (left) and controls (right).
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
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The source renders a native `<h2>` and a native button with `aria-label="About this section"` (passed screen-reader-support, keyboard-navigable, semantic-markup); it uses `apt-*` semantic color tokens and rem-based Tailwind text sizing whose actual contrast and font-scaling behavior cannot be confirmed from this file alone (partial contrast-ratio, dynamic-type-support); it delegates focus return and Escape handling to the Popover component without specifying the help button's own hit-area size (partial focus-management, touch-target-size); and it hardcodes the English string `"About this section"` with no localization mechanism (failed no-hardcoded-strings, string-externalization). `separation-of-concerns` passes because `section-header.tsx` is pure presentation composed from its `eyebrow`/`title`/`help`/`actions` props with no business logic, and `unit-test-coverage` fails because no test file in the repository renders or exercises `SectionHeader`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Qualified bare #accessibility fragments to popover's full agenticdeveloperkit URI; fixed 6 refs. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; cited the popover ingredient by requirement fragment instead of crediting behavior to "the Popover component" and added it to depends-on/related; reformatted Design Decisions into Decision/Rationale/Approved triplets and added one for the fixed h2 heading level; rewrote Compliance from "Not applicable" into a real table; fixed the flex-shrink/wrap contradiction between Appearance and Edge Cases; expanded help-popover keyboard coverage (Space, Escape, focus return, toggle) with new test vectors; corrected nonexistent APIs in the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes; rewrote Localization to name the hardcoded aria-label and the locale-sensitive uppercase transform; defined "empty" once for the optional ReactNode props and reused it in Configuration; clarified how an empty title is actually handled. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
