---
id: 56828ee6-f522-45da-a9d8-6e1a99adf4e2
title: Help Popover
domain: adhsdk://recipes/help-popover
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A popover panel displaying contextual help, information, or feature announcements
  with a flavor icon, optional title, and body text.
platforms:
- typescript
- web
tags:
- help
- popover
- accessibility
depends-on:
- adhsdk://recipes/popover
related: []
references: []
approved-by: ''
approved-date: ''
---

# Help Popover

## Overview

Help Popover is the content panel portion of a help popover UI pattern. It displays contextual help, informational guidance, or feature announcements next to a trigger control. The component combines a flavor-specific icon (help, information, or what's new), an optional title, and body text inside a positioned popover with an arrow. It is intended for brief, contextual guidance that does not block user interaction with the underlying content.

## Behavioral Requirements

- **entry-prop**: The component MUST accept a `HelpEntry` prop containing the popover content.
- **side-prop**: The component MUST accept an optional `side` prop controlling popover vertical/horizontal positioning (`"top"`, `"bottom"`, `"left"`, or `"right"`), with `"bottom"` as the default.
- **align-prop**: The component MUST accept an optional `align` prop controlling popover alignment along the positioning axis (`"start"`, `"center"`, or `"end"`), with `"start"` as the default.
- **flavor-icon**: The component MUST render an icon corresponding to the flavor value in `entry.flavor`, defaulting to `"info"` if not specified. The three supported flavors are `"help"` (a help/question icon), `"info"` (an information icon), and `"new"` (a sparkle/announcement icon).
- **body-text**: The component MUST render the text from `entry.body` in the popover panel.
- **arrow**: The component MUST render an arrow pointing from the popover to its anchor control.
- **optional-title**: If `entry.title` is provided, the component MUST render it as a distinct, visually emphasized element. If `entry.title` is not provided or is empty, the component MUST NOT render a title section.
- **fixed-width**: The component MUST constrain the popover panel width to 320px.
- **accessible-name**: The component MUST set an accessible name on the popover panel combining the flavor label (Help, Information, or What's new) with the title if present. The pattern MUST be `"{flavor}: {title}"` when title exists, or `"{flavor}"` when title is absent.
- **decorative-icon**: The component MUST mark the flavor icon as decorative to assistive technology, since the flavor information is conveyed by the panel's accessible name.
- **color-tokens**: The component MUST apply the design system color tokens for text: `apt-text` for the title, `apt-text-muted` for the icon and body text.

## Appearance

- **Width**: 320px (fixed)
- **Icon size**: 16px × 16px (Tailwind `size-4` on the web implementation)
- **Icon color**: `apt-text-muted` (design system token for muted text)
- **Icon margin**: 2px top margin, no left/right margin
- **Content gap**: 10px horizontal gap between icon and text block
- **Title font**: font-weight `500` (medium), inherits body size
- **Title color**: `apt-text` (design system token for primary text)
- **Title margin**: 4px bottom margin (creates visual separation from body)
- **Body font**: inherits body size and line-height
- **Body color**: `apt-text-muted` (design system token for muted text)
- **Text block**: `min-w-0` applied on the web implementation so the text column can shrink below its content's intrinsic width inside the flex layout; no truncation is applied — long title or body text wraps instead (see Edge Cases)
- **Arrow**: Rendered by PopoverContent component; inherits popover positioning and alignment

## States

| State | Appearance change |
|-------|------------------|
| Default (closed) | Popover is not rendered; trigger control is visible |
| Open | Popover panel is visible with all content rendered; arrow points to anchor |
| With title | Title paragraph rendered above body text; title is font-medium |
| Without title | Only body text is rendered; no empty space for title |

## Accessibility

- **Role**: Dialog (provided by PopoverContent wrapper; popover panel announces as `role="dialog"`)
- **Accessible name**: Set via `aria-label` on PopoverContent; combines flavor label with title if present (e.g., "Help: Getting Started" or "Information")
- **Icon trait**: Decorative image (via `aria-hidden="true"`); the icon's semantic meaning is captured in the panel's accessible name
- **Keyboard navigation**: Keyboard access to the popover is the responsibility of the trigger control and PopoverContent's dismiss mechanism. On open, PopoverContent (the composed wrapper) focuses and announces the dialog; Help Popover Content itself renders no interactive controls and adds no keyboard behavior beyond the accessible name and content it supplies
- **Screen reader announcement**: On open, screen readers announce the dialog role and accessible name; the title and body text are then available for exploration
- **Minimum tap target**: Not applicable; the component contains no interactive controls. Tap target size is determined by the trigger control that opens the popover.
- **Color contrast**: Text colors (`apt-text`, `apt-text-muted`) are design system tokens; their contrast ratios SHOULD meet WCAG AA standards (requires verification of token definitions)

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| help-001 | entry-prop | `entry={ flavor: "help", title: "Help", body: "This is a help message" }` | Component renders without error; body text "This is a help message" appears in the popover |
| help-002 | flavor-icon | `entry={ flavor: "help", title: "", body: "Text" }` | The icon associated with the "help" flavor renders, marked decorative to assistive technology |
| help-003 | flavor-icon | `entry={ flavor: "info", title: "", body: "Text" }` | The icon associated with the "info" flavor renders, marked decorative to assistive technology |
| help-004 | flavor-icon | `entry={ flavor: "new", title: "", body: "Text" }` | The icon associated with the "new" flavor renders, marked decorative to assistive technology |
| help-005 | flavor-icon | `entry={ flavor: undefined, title: "", body: "Text" }` | The "info" flavor icon renders (default flavor) |
| help-006 | body-text | `entry={ flavor: "info", title: "", body: "Help text content" }` | Body text "Help text content" is rendered in a paragraph using the `apt-text-muted` color token |
| help-007 | optional-title | `entry={ flavor: "info", title: "Getting Started", body: "Learn how to use this feature" }` | Title text "Getting Started" renders as a distinct, visually emphasized element positioned above the body text |
| help-008 | optional-title | `entry={ flavor: "info", title: "", body: "Body only" }` | No title element is rendered; only body text appears |
| help-009 | fixed-width | `entry={ flavor: "info", title: "Title", body: "Longer body text that might wrap across multiple lines should still respect the 320px width constraint" }` | Popover panel renders at a fixed width of 320px |
| help-010 | accessible-name | `entry={ flavor: "help", title: "Getting Started", body: "Text" }` | The popover panel's accessible name is `"Help: Getting Started"` |
| help-011 | accessible-name | `entry={ flavor: "info", title: "", body: "Information text" }` | The popover panel's accessible name is `"Information"` |
| help-012 | decorative-icon | `entry={ flavor: "new", title: "Feature Launch", body: "Text" }` | Icon is marked decorative to assistive technology; screen reader skips the icon and announces the panel's accessible name |
| help-013 | color-tokens | `entry={ flavor: "info", title: "Title", body: "Body" }` | Title uses the `apt-text` color token; icon and body use the `apt-text-muted` color token |
| help-014 | side-prop | `side="top"` | Popover positions above anchor |
| help-015 | side-prop | `side="left"` | Popover positions left of anchor |
| help-016 | side-prop | (side prop not provided) | Popover positions below anchor (`"bottom"` default) |
| help-017 | align-prop | `align="center"` | Popover centers along the positioning axis |
| help-018 | align-prop | `align="end"` | Popover aligns to the end of the positioning axis |
| help-019 | align-prop | (align prop not provided) | Popover aligns to the start of the positioning axis (`"start"` default) |
| help-020 | arrow | (any valid entry) | An arrow renders connecting the popover to the anchor |
| help-021 | optional-title | `entry={ flavor: "info", body: "Body only" }` (title omitted entirely) | No title element is rendered; only body text appears — same outcome as an empty-string title |
| help-022 | flavor-icon | `entry={ flavor: null, title: "", body: "Text" }` | The "info" flavor icon renders (default flavor) |
| help-023 | body-text | `entry={ flavor: "info", title: "", body: "" }` | An empty paragraph is rendered for the body; no error occurs |
| help-024 | flavor-icon | `entry={ flavor: "urgent", title: "", body: "Text" }` (a value outside the `HelpFlavor` union) | Component throws while looking up the icon and label; callers MUST NOT pass a flavor outside `"help" \| "info" \| "new"` |

## Edge Cases

- **Null or undefined entry**: Not applicable; the component does not guard against null `entry` and will error. Callers MUST provide a valid `HelpEntry` prop.
- **Empty body text**: If `entry.body` is an empty string, the component renders an empty paragraph rather than erroring. Callers are responsible for supplying meaningful body text.
- **Empty title**: If `entry.title` is an empty string or omitted, the component MUST NOT render the title section; only the body text is rendered.
- **Null or undefined flavor**: If `entry.flavor` is `undefined` or `null`, the flavor defaults to `"info"` and the Info icon is rendered.
- **Invalid flavor value**: `entry.flavor` is typed as a closed union (`"help" | "info" | "new"`) at compile time. A value outside that union bypasses the type system (e.g., from untyped JavaScript) — the component will error attempting to look up the icon and label in the `FLAVORS` table. Callers MUST ensure flavor is one of the three valid values.
- **Long title text**: Title text longer than approximately 30 characters may wrap to multiple lines; no specific line-clamp or truncation is applied by this component.
- **Long body text**: Body text is not constrained in height or line count; if `entry.body` is very long (e.g., multiple paragraphs), the popover panel will grow vertically. No maximum height or scrolling behavior is defined in this component.
- **Whitespace in entry strings**: Leading or trailing whitespace in `entry.title` or `entry.body` is preserved and rendered as-is; no trimming is performed by this component.
- **Special characters or markup in entry strings**: The component renders entry text as plain text; if `entry.body` or `entry.title` contains HTML markup or special characters (e.g., `<`, `>`), they are not interpreted. The caller is responsible for providing plain-text content.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `"top" \| "bottom" \| "left" \| "right"` | `"bottom"` | Which side of the anchor the popover renders on. |
| `align` | `"start" \| "center" \| "end"` | `"start"` | Alignment of the popover along the positioning axis. |

The component accepts no other configuration beyond the required `entry` prop.

## Deep Linking

Not applicable; Help Popover is a content panel with no independent URL or navigation capability. Deep linking is the responsibility of the trigger control and hosting application.

## Localization

The component owns three hardcoded English strings — the flavor labels `"Help"`, `"Information"`, and `"What's new"` defined in the `FLAVORS` table. These are not rendered as visible on-screen text, but they do reach assistive technology through the popover panel's accessible name, so they are user-facing in that sense. They are not currently externalized to a localization system. `entry.title` and `entry.body` are caller-supplied content; localizing that content is the caller's responsibility.

## Accessibility Options

Not applicable; the component does not respond to platform accessibility display options such as Reduce Motion or Increase Contrast. Motion and contrast are controlled by PopoverContent and the design system color tokens (`apt-text`, `apt-text-muted`).

## Feature Flags

Not applicable; the component is not gated by feature flags.

## Analytics

Not applicable; the component itself does not emit analytics events. Analytics instrumentation (e.g., tracking popover opens, user interactions with the help content) SHOULD be implemented at the trigger control or application level.

## Privacy

Not applicable; the component does not collect, store, or transmit any user data.

## Logging

Not applicable; the component does not emit logs.

## Platform Notes

- **React/Web**: Help Popover Content is implemented as a functional React component using Tailwind CSS for styling and Lucide React for icons (`CircleHelp`, `Info`, `Sparkles`). The component composes `PopoverContent` (a Base UI Popover wrapper) with its `arrow` prop enabled, and must be used together with a `Popover.Trigger` element to be functional. It sets `aria-label` on `PopoverContent` to the flavor label combined with `entry.title` when present, and marks the icon `aria-hidden="true"`. The panel width is constrained via the Tailwind class `w-80`; title/body spacing uses `mb-1` (title bottom margin) and `gap-2.5` (icon/text gap). Import `HelpPopoverContent` from `@adh-sdk/ui/components/help-popover`.
- **SwiftUI**: Implement using SwiftUI's `.popover()` modifier or `Menu` with `Label`. Render an `Image(systemName:)` for the flavor icon (`questionmark.circle`, `info.circle`, or `sparkles` for the three flavors — `help.circle` does not exist as an SF Symbol), a `Text` view for the optional title (`.font(.headline)` or similar emphasis), and a `Text` view for the body. Set `.accessibilityElement(children: .combine)` on the popover container and apply a custom `accessibilityLabel` combining flavor and title as described in Accessibility. Use `.frame(width: 320)` to constrain width to 320pt (`preferredContentSize` is a UIKit API, not available in SwiftUI).
- **Kotlin (Compose)**: Implement using `Popup` or `DropdownMenu` with a `Card` or `Surface` for the panel. Use Material Design 3 icon resources (`HelpOutline`, `Info`, or `AutoAwesome`) for the three flavors. Apply `.width(320.dp)` and use `Row` for the icon+text layout. Set the popover container's `semantics { contentDescription = ... }` combining flavor and title per the Accessibility section. Apply color tokens from the design system (`MaterialTheme.colorScheme.onSurface` for `apt-text`, `MaterialTheme.colorScheme.onSurfaceVariant` for `apt-text-muted`).
- **AppKit / UIKit**: On AppKit, implement as an `NSPopover` presenting an `NSViewController` whose view lays out the icon and text (e.g., with `NSStackView`); use `NSImage(systemSymbolName:)` for SF Symbols. On UIKit, implement as a `UIViewController` (popover presentation controller) or a SwiftUI view bridged via `UIHostingController`. On both, use SF Symbols (`questionmark.circle`, `info.circle`, `sparkles`) for the three flavors — `help.circle` does not exist. Constrain width to 320pt (`preferredContentSize = CGSize(width: 320, height: ...)` on UIKit; the AppKit popover's `contentSize`). Set the accessible label (`accessibilityLabel` on UIKit, `setAccessibilityLabel` on AppKit) combining flavor and title. Apply semantic colors for text (`UIColor.label` / `NSColor.labelColor` for `apt-text`, `UIColor.secondaryLabel` / `NSColor.secondaryLabelColor` for `apt-text-muted`).
- **WinUI 3**: Implement as a `Flyout` with a `FlyoutPresenter` for positioning control (Top, Bottom, Left, Right). Use `FontIcon` with Segoe Fluent Icons glyphs for the three flavors: Help (``), Info (``), and, in place of the nonexistent "Sparkles" glyph, Megaphone (``) for the "new"/announcement flavor. Render a `StackPanel` (Horizontal) containing the icon and a `StackPanel` (Vertical) for title and body text. Set `Width="320"` on the Flyout content (`Flyout` has no `Title` property). Set `AutomationProperties.Name` on the Flyout content, combining flavor and title per Accessibility. Apply Fluent 2 brushes (`TextFillColorPrimaryBrush` for `apt-text`, `TextFillColorSecondaryBrush` for `apt-text-muted`).

## Design Decisions

**Decision**: The flavor icon is marked decorative to assistive technology (`aria-hidden="true"`); flavor is conveyed through the popover panel's accessible name instead.
**Rationale**: This simplifies the accessible name and avoids the flavor being announced twice — once for the icon and once for the panel.
**Approved**: pending

**Decision**: The popover panel width is fixed at 320px.
**Rationale**: Prevents overly wide content and ensures readability; the width matches common content widths in the design system and accommodates most help text without requiring horizontal scroll.
**Approved**: pending

**Decision**: Title is optional and visually emphasized when present.
**Rationale**: When a title is present, `font-medium` weight distinguishes it from body text and provides visual hierarchy. When absent, the component renders only body text without empty space, avoiding visual clutter.
**Approved**: pending

**Decision**: The default flavor is `"info"` when `entry.flavor` is not provided.
**Rationale**: This is the most neutral and widely applicable flavor for general help content.
**Approved**: pending

**Decision**: Default positioning is `side="bottom"`, `align="start"`.
**Rationale**: This positions the popover below the trigger control and aligned to its left edge, a common popover placement that does not obscure the trigger or surrounding content in most contexts.
**Approved**: pending

**Decision**: Text colors are applied via design system tokens (`apt-text`, `apt-text-muted`) rather than hardcoded values.
**Rationale**: This ensures consistency with the application's color scheme and supports light/dark mode switching via token overrides.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Screen-reader-support and semantic-markup rest on the `aria-label`/`aria-hidden="true"` usage visible in `help-popover.tsx`. Contrast-ratio is partial because the component applies the `apt-text`/`apt-text-muted` tokens but the source cannot confirm their contrast values. No-hardcoded-strings fails and string-externalization is partial because the `FLAVORS` table hardcodes the English flavor labels ("Help", "Information", "What's new") with no localization hook, while `entry.title`/`entry.body` are already externalized to the caller. `separation-of-concerns` passes because the component is pure presentation over its `entry`/`side`/`align` props, with the `FLAVORS` lookup as its only non-rendering data; `unit-test-coverage` passes on `help-popover.test.tsx`'s exercise of every flavor, the title/no-title cases, and the dialog's computed accessible name.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: de-webified requirements/test vectors and moved mechanics into Platform Notes, fixed Appearance unit math, resolved title-truncation and focus-attribution contradictions, added test vectors for omitted title/null flavor/empty body/invalid flavor, corrected SwiftUI/AppKit/UIKit/Compose/WinUI platform notes and the React import specifier, filled in Configuration and Compliance tables, corrected the Localization claim, reformatted Design Decisions, renamed requirements to subject-only kebab-case, and added the popover ingredient to depends-on |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation (AI-assisted) |
