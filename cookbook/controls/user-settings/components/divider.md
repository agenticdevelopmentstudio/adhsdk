---
id: 89a912f3-f0a0-4896-ba06-a386407ecb15
title: "Divider"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A semantic horizontal line that visually separates content sections."
platforms:
  - typescript
  - web
tags:
  - divider
  - separator
  - layout
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Divider

## Overview

A divider is a horizontal line element that provides visual separation between distinct sections of content. It renders as a semantic `<hr>` element on the web and MAY accept an optional CSS class for custom styling or visual variants.

## Behavioral Requirements

- **hr-element**: The component MUST render as an HTML `<hr>` element.
- **base-class**: The component MUST apply the class `{{app_prefix}}-divider` to the rendered element.
- **extra-class-name**: The component SHOULD accept an optional `className` prop that is appended to the base class.
- **filter-empty-classes**: The component MUST NOT render empty or null class names; class filtering MUST remove falsy values before joining.

## Appearance

- **Border**: A single horizontal line rendered via `border-top: 1px solid`, using the app's subtle border/separator color token; no other border sides are set.
- **Height**: A 1px/1pt hairline — the element carries no intrinsic height beyond the `border-top` line.
- **Margin**: 0.5rem vertical margin (top and bottom), 0 horizontal; the line spans the full width of its container.
- **Background**: None (the line is drawn via `border-top`, not a filled background).
- **Corner radius**: Not applicable; element is a line.
- **Shadow**: None.
- **Min/Max size**: No constraints enforced by the component; the line always spans the full width of its container.

## States

| State | Appearance change |
|-------|------------------|
| Default | Horizontal line with styling from the `{{app_prefix}}-divider` class |

Not applicable: Divider is a static, non-interactive element with no pressed, disabled, focused, or loading states.

## Accessibility

- **Role**: `separator` — the implicit ARIA role of the HTML `<hr>` element; the component adds no explicit `role` attribute.
- **Label requirements**: Not applicable; the `<hr>` element is a semantic separator and requires no additional label or aria-label.
- **Keyboard interaction**: Not applicable; divider is not interactive.
- **Screen reader**: The semantic `<hr>` element is exposed to assistive technology with the `separator` role and is announced as a separator or thematic break.
- **Native platforms**: SwiftUI's `Divider()` and Compose's `HorizontalDivider()` render as non-interactive, decorative elements and are excluded from the accessibility tree by the platform framework's default; AppKit's `NSBox(.separator)` and a UIKit hairline view behave the same way. This matches the non-interactive separator semantics on the web.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| divider-001 | hr-element | No props | Rendered element is `<hr>` |
| divider-002 | base-class | No props | Element has class `{{app_prefix}}-divider` |
| divider-003 | extra-class-name | `className="custom-style"` | Element has classes `{{app_prefix}}-divider custom-style` |
| divider-004 | filter-empty-classes | `className={undefined}` or `className=""` | Element has only `{{app_prefix}}-divider`, no empty values in class list |
| divider-005 | filter-empty-classes | `className="   "` (whitespace only) | Raw class attribute is `"{{app_prefix}}-divider    "` (whitespace preserved, not trimmed); the parsed class list contains only `{{app_prefix}}-divider` — the whitespace-only string is truthy so it passes the filter but yields no additional class token |
| divider-006 | hr-element | No props | Rendered element exposes the implicit ARIA role `separator` |

## Edge Cases

- **Null or undefined className**: Component MUST filter out falsy values; the rendered element receives only `{{app_prefix}}-divider`.
- **Empty string className**: Component MUST filter out empty strings; the rendered element receives only `{{app_prefix}}-divider`.
- **Whitespace-only className**: A string containing only whitespace (e.g. `"   "`) is truthy, so filtering does not remove it. The raw class attribute is not trimmed and includes the literal whitespace verbatim, but split into a class list it contributes no additional token — the effective class list is unchanged (`{{app_prefix}}-divider` only).
- **Multiple class names in className prop**: The string is passed as-is to the class list; whitespace and multiple tokens within the prop are preserved as provided by the caller. className is never trimmed before joining, so leading or trailing whitespace in the caller's string appears verbatim in the resulting attribute (potentially producing consecutive spaces), though this does not change the parsed set of class tokens.
- **No props provided**: Component MUST render with only the `{{app_prefix}}-divider` class.

## Configuration

Not applicable: Divider has no configuration options beyond the optional className prop.

## Deep Linking

Not applicable: Divider is a layout component with no associated deep linking behavior.

## Localization

Not applicable: Divider is a presentational element with no user-facing text.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; divider has no motion or animation. |
| Increase Contrast | The divider's line color comes from a themable separator-color token rather than a fixed value (see **Appearance**), not from the component itself; on native platforms this SHOULD map to a system separator color (e.g. `NSColor.separatorColor`, `UIColor.separator`, `DividerStrokeColorDefaultBrush`) that already adapts automatically when Increase Contrast is enabled. |
| Differentiate Without Color | Not applicable; divider is rendered as a line, not dependent on color alone. |

## Feature Flags

Not applicable: Divider has no feature flags.

## Analytics

Not applicable: Divider is a non-interactive presentational element; no user events to track.

## Privacy

Not applicable: Divider neither collects nor transmits data.

## Logging

Not applicable: Divider requires no diagnostic logging.

## Platform Notes

- **React/Web**: Render as `<hr className={cls} />` where `cls` combines `{{app_prefix}}-divider` with any additional classes via `[base, className].filter(Boolean).join(' ')`; the border, height, and margin come from the `{{app_prefix}}-divider` CSS class. Files: `packages/web/packages/controls/src/user-settings/components/Divider.tsx`.
- **SwiftUI**: Render using the native `Divider()` view, which draws a 1pt separator line in the system separator color and adapts automatically to Dark Mode and Increase Contrast. Use `.frame(height:)` only when a non-default thickness is required.
- **Compose**: Render using the Material 3 `HorizontalDivider()` composable (the older `Divider()` composable is deprecated in Material 3), which draws a horizontal separator line using the current `Material` color scheme's divider/outline color. Apply padding or modifier chains for custom spacing.
- **AppKit / UIKit**: On AppKit, render an `NSBox` with `boxType = .separator`, which draws the native hairline separator in the system separator color. On UIKit, render a hairline `UIView` with `backgroundColor = .separator`, sized to 1pt height via a `heightAnchor` constraint and constrained to span the container horizontally.
- **WinUI 3**: Render a `Rectangle` (or `Border`) with `Height="1"` and `Fill="{ThemeResource DividerStrokeColorDefaultBrush}"`, stretched to span the content width via `HorizontalAlignment="Stretch"` (or `Grid.ColumnSpan` when placed in a multi-column `Grid`); apply vertical spacing via the element's `Margin`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/Divider.tsx` | unverified |

## Design Decisions

**Decision**: Render a semantic `<hr>` element and delegate all visual styling to CSS classes, rather than a styled `<div>`.
**Rationale**: The `<hr>` element is recognized as a separator by assistive technologies, and delegating styling to the `{{app_prefix}}-divider` class plus an optional `className` prop keeps the component minimal while allowing flexible styling.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The `passed` status rests on the component rendering a bare `<hr>` element with no added ARIA overrides, which the browser maps to the correct implicit `separator` role. `separation-of-concerns` passes because `Divider.tsx` renders a bare `<hr>` with no logic of any kind; `unit-test-coverage` fails because the only name-matching test, `splitDivider.test.tsx`, actually exercises a different component (`SplitDivider`), so no test exercises `Divider.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names, templated the hardcoded class prefix, corrected the AppKit/UIKit, Compose, and WinUI 3 platform notes to real native APIs, grounded Appearance in the source CSS, fixed the Accessibility role and Increase Contrast guidance, replaced the duplicate test vector and added a role vector, clarified whitespace handling in Edge Cases, reformatted Design Decisions, and added a Compliance table |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
