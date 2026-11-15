---
id: 54f9d317-9ec0-485e-b916-6c8bf2216873
title: "Cover All Control"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Compact pair of chevron buttons, collapse all and expand all, that each enable only when pressing it would visibly change the stack of lists."
platforms:
  - typescript
  - web
tags:
  - control
  - collapse
  - expand
  - stack
depends-on: []
related:
  - 0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8
  - aaebd90e-991f-4133-a12d-0783586eae5a
references: []
approved-by: ""
approved-date: ""
---

# Cover All Control

## Overview

Cover All Control is a small segmented control of two icon buttons set in one bordered frame. The left button, drawn as three left-pointing chevrons (`<<<`), collapses every list in a stack of lists; the right button, three right-pointing chevrons (`>>>`), expands them all. It is used by the hierarchical topic detail and hierarchical menu detail layouts, which show a stack of lists side by side and let the user cover (collapse) a list to a narrow strip.

The control decides nothing about the stack. The host passes `canCollapse` and `canExpand`, and the control disables a half when its flag is false. The source states the rule the host follows: each half is enabled only when pressing it would visibly change the stack, so a half that could do nothing is shown disabled rather than hidden.

## Behavioral Requirements

- **group-container**: The component MUST render both buttons inside one bordered frame, collapse button first and expand button second, with a thin vertical divider between them.
- **collapse-button**: The component MUST render a collapse-all button labelled "Collapse all lists", drawn as three overlapped left-pointing chevrons.
- **expand-button**: The component MUST render an expand-all button labelled "Expand all lists", drawn as three overlapped right-pointing chevrons.
- **collapse-enabled-flag**: The collapse button MUST be enabled when `canCollapse` is true and disabled when it is false.
- **expand-enabled-flag**: The expand button MUST be enabled when `canExpand` is true and disabled when it is false.
- **flags-independent**: Each button's enabled state MUST depend only on its own flag.
- **collapse-callback**: Activating an enabled collapse button MUST call `onCollapseAll` once with no arguments.
- **expand-callback**: Activating an enabled expand button MUST call `onExpandAll` once with no arguments.
- **disabled-inert**: A disabled button MUST NOT call its callback when activated.
- **always-present**: The component MUST render both buttons at all times and MUST NOT hide a button because it is disabled.
- **tooltip-matches-label**: Each button MUST show its label as a hover tooltip (a title), identical to its accessible name.
- **button-type**: Both buttons MUST be plain buttons that do not submit a surrounding form.
- **glyph-decorative**: The chevron glyphs and the divider MUST be hidden from assistive technology, since the label names the action.
- **group-semantics**: The frame MUST be exposed as a group named "Collapse or expand all lists".
- **hook-attribute**: The frame MUST carry the attribute `data-htd-cover-all` so a host or test can find it.
- **focus-ring**: A button that receives keyboard focus MUST show a 2px ring in the gold accent at 40% opacity, with the browser default outline removed.
- **stateless**: The component MUST hold no state of its own and MUST NOT decide when a half is enabled.

## Appearance

- **Frame**: Flex row (`flex`), items centred, 1px border in the theme border color (`border-apt-border`), `rounded` corners, does not shrink (`shrink-0`).
- **Buttons**: Each half has 4px horizontal and 2px vertical padding (`px-1 py-0.5`), muted text color (`text-apt-text-muted`), full text color on hover when enabled. The left half rounds its left corners (`rounded-l`); the right half rounds its right corners (`rounded-r`).
- **Glyph**: Three lucide chevrons of 14px, the second and third pulled back by 8px (`-ml-2`) so they overlap into one `<<<` or `>>>` mark.
- **Divider**: 1px wide, 16px tall, in the theme border color, between the two buttons.
- **Disabled**: 35% opacity, default cursor, text stays muted on hover.
- **Min/Max size**: None; the size is the content size.

## States

| State | Appearance change |
|-------|------------------|
| Both enabled | Both halves at full opacity; hover brightens the half under the pointer |
| Collapse disabled | Left half at 35% opacity with default cursor; right half unchanged |
| Expand disabled | Right half at 35% opacity with default cursor; left half unchanged |
| Both disabled | Both halves at 35% opacity |
| Hover | An enabled half's text color moves from muted to full text color; a disabled half does not change |
| Focused (keyboard) | 2px gold ring at 40% opacity around the focused half |
| Pressed (active) | Not applicable: the source defines no `:active` style |
| Loading | Not applicable: the control has no loading state |

## Accessibility

- **group-name**: The frame MUST be a group named "Collapse or expand all lists".
- **button-name**: Each button's accessible name MUST be its explicit label ("Collapse all lists", "Expand all lists"), because the glyph is hidden and no text is visible.
- **disabled-announced**: A disabled button MUST be announced as disabled and MUST be skipped by the Tab order.
- **keyboard-operation**: Both buttons are native buttons, so Tab reaches an enabled one and Enter or Space activates it.
- **focus-ring-visible**: A keyboard-focused button MUST show the focus ring.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. Each half is a 14px chevron row with 4px by 2px padding, roughly 34px by 18px, below the 44x44 CSS px platform minimum; settling it needs the rendered size at the production theme and a decision on whether this dense toolbar control is held to that minimum (WCAG 2.2 floor is 24x24 CSS px).
- **contrast-ratio**: NEEDS REVIEW: Not implemented in source. Muted text on the page background, and the disabled state at 35% opacity, depend on theme tokens; whether either meets 3:1 for a non-text control needs measured token values per theme.

## Conformance Test Vectors

`coverAllControl.test.tsx` renders the control by itself and has one test per vector. The host stacks also exercise it: `hierarchicalTopicDetail.test.tsx` ("`<<<` / `>>>` collapse and expand every list", including the hierarchical menu variant, and "is not in the narrow layout") and `detailTitle.test.tsx`, which finds the control by `[data-htd-cover-all]`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ca-001 | collapse-callback, collapse-button (test: `<<<` / `>>>` collapse and expand every list) | `canCollapse=true`; click "Collapse all lists" | `onCollapseAll` called once; in the host every list becomes covered |
| ca-002 | expand-callback, expand-button (test: `<<<` / `>>>` collapse and expand every list) | `canExpand=true`; click "Expand all lists" | `onExpandAll` called once; in the host every list opens |
| ca-003 | collapse-enabled-flag, expand-enabled-flag, flags-independent | `canCollapse=false`, `canExpand=true` | Collapse button disabled; expand button enabled |
| ca-004 | collapse-enabled-flag, expand-enabled-flag, flags-independent | `canCollapse=true`, `canExpand=false` | Collapse button enabled; expand button disabled |
| ca-005 | disabled-inert | `canCollapse=false`; click the collapse button | `onCollapseAll` is not called |
| ca-006 | always-present | Both flags false | Both buttons still rendered, both disabled |
| ca-007 | group-semantics, hook-attribute (test: detailTitle.test.tsx finds `[data-htd-cover-all]`) | Default render | A group named "Collapse or expand all lists" carrying `data-htd-cover-all` |
| ca-008 | tooltip-matches-label, button-name | Default render | Collapse button title and name are both "Collapse all lists"; expand "Expand all lists" |
| ca-009 | glyph-decorative | Default render | The chevron wrapper and divider are `aria-hidden` |
| ca-010 | button-type | Default render inside a form | Clicking either button does not submit the form |
| ca-011 | group-container | Default render | Collapse button precedes the divider, the divider precedes the expand button |
| ca-012 | stateless | Rerender with new flags | The enabled states follow the new flags immediately; nothing persists between renders |

## Edge Cases

- **Both disabled**: A stack in which every list is covered and none of the covers can be lifted by a click (the host sets `canCollapse` false because nothing is open, and `canExpand` false because the covers are width pressure) shows both halves disabled, still in place. See ca-006.
- **Both enabled**: A mixed stack, where some lists are covered and some are open, enables both halves.
- **Disabled activation**: A disabled button cannot be activated, so a stray click does nothing. See ca-005.
- **Rapid activation**: Each activation of an enabled half calls its callback once; the control does not debounce, and the host's flags decide whether the next click is still possible.
- **Narrow layout**: The host does not render the control at all in its narrow layout (test: "is not in the narrow layout"); the control has no narrow-width behavior of its own.
- **Missing callbacks or flags**: All four props are required; the source does not default any of them.
- **Concurrent access**: Not applicable: the control is a synchronous render of props and holds no shared mutable state.
- **Error states and offline**: Not applicable: the control makes no network or storage calls.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `canCollapse` | `boolean` | (required) | Enables the collapse-all button when true. |
| `canExpand` | `boolean` | (required) | Enables the expand-all button when true. |
| `onCollapseAll` | `() => void` | (required) | Called when the collapse-all button is activated. |
| `onExpandAll` | `() => void` | (required) | Called when the expand-all button is activated. |

## Deep Linking

Not applicable: the control is an inline toolbar widget with no route; the host owns any state it drives.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `cover_all.group_label` | "Collapse or expand all lists" | Group name of the frame |
| `cover_all.collapse` | "Collapse all lists" | Collapse button name and tooltip |
| `cover_all.expand` | "Expand all lists" | Expand button name and tooltip |

All three strings are hardcoded English with no override prop. The chevrons point left to collapse and right to expand in every layout direction: the source uses `ChevronLeft` and `ChevronRight` directly, `rounded-l` on the left half and `rounded-r` on the right half, and no logical-direction classes, so a right-to-left layout would not mirror them.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the source defines no animation or transition. |
| Increase Contrast | Not handled: the control has no contrast-preference branch; contrast depends on theme tokens (see the open question on `contrast-ratio`). |
| Differentiate Without Color | The disabled state is carried by opacity and the cursor and by the native disabled state, not by hue. |

## Feature Flags

Not applicable: the source has no flag lookup.

## Analytics

Not applicable: the source emits no events; a host that wants analytics instruments `onCollapseAll` and `onExpandAll`.

## Privacy

- **Data collected**: None.
- **Storage**: None.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the source performs no logging.

## Platform Notes

- **SwiftUI**: Source platform is web, so this is translation guidance. Use a `ControlGroup` of two `Button`s with `Image(systemName: "chevron.left.3")` and `"chevron.right.3"` (or `chevron.backward.3` and `chevron.forward.3` to mirror under right-to-left), `.disabled(!canCollapse)` and `.disabled(!canExpand)`, `.accessibilityLabel` set to the two strings, and `.help` for the tooltip on macOS. Wrap in `.accessibilityElement(children: .contain)` with the group label.
- **Compose**: A `Row` inside a `Surface` with a 1.dp border and a rounded shape, holding two `IconButton`s with `enabled = canCollapse` and `enabled = canExpand`, `Icon(contentDescription = null)` on the glyph and `Modifier.semantics { contentDescription = ... }` on the button. A 1.dp by 16.dp `VerticalDivider` sits between them. Use `Modifier.semantics { isTraversalGroup = true }` plus a `contentDescription` for the group, and `Modifier.minimumInteractiveComponentSize()` if the touch-target question is settled in favor of the platform minimum.
- **React/Web**: `packages/web/packages/ui/src/blocks/cover-all-control.tsx`, a client component using lucide `ChevronLeft` and `ChevronRight` through an internal `TripleChevron` and the `cn` helper; the frame is `role="group"` with `data-htd-cover-all`. It is used by `hierarchical-topic-detail.tsx` and `hierarchical-menu-detail.tsx`.
- **AppKit / UIKit**: On macOS use an `NSSegmentedControl` with `trackingMode = .momentary` and two segments carrying `NSImage(systemSymbolName: "chevron.left.3")` and the right equivalent, `setEnabled(_:forSegment:)` to follow the flags, and `setToolTip(_:forSegment:)`. On iOS use a `UIStackView` of two `UIButton`s, `isEnabled` bound to the flags, with `accessibilityLabel` set and the stack marked as an `accessibilityContainer` with the group label.
- **WinUI 3**: A bordered `Grid` (`BorderThickness="1"`, `BorderBrush="{ThemeResource ControlStrokeColorDefaultBrush}"`, `CornerRadius="4"`) with three columns: `Button` (`x:Name="CollapseAll"`, `IsEnabled` bound to `CanCollapse`, `Padding="4,2"`, `Background="Transparent"`, `BorderThickness="0"`, `CornerRadius="4,0,0,4"`), a `Rectangle` divider (`Width="1"`, `Height="16"`, `Fill` the same stroke brush, `AutomationProperties.AccessibilityView="Raw"`), and the matching expand `Button` with `CornerRadius="0,4,4,0"`. The glyph is a `FontIcon` using Segoe Fluent Icons `ChevronLeft` (U+E76B) repeated three times in a `StackPanel` with `Margin="-8,0,0,0"` on the second and third. `AutomationProperties.Name` carries the two labels and `ToolTipService.ToolTip` the same text; the `Grid` takes `AutomationProperties.Name` for the group. Visual states are the stock `Button` states (`Normal`, `PointerOver`, `Pressed`, `Disabled`); override the `Disabled` foreground and set the control's `Opacity` through a `VisualState` setter to 0.35 to match, and use the `FocusVisualPrimaryBrush` for the gold ring.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/cover-all-control.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Each half is disabled, not hidden, when pressing it would change nothing.
**Rationale**: The source comment states that each half is enabled only when clicking would visibly change the stack, and the stack decides; keeping both buttons in place stops the toolbar from shifting as the stack changes.
**Approved**: pending

**Decision**: The control takes its two flags and callbacks from the host and holds no state.
**Rationale**: Whether a list is covered, and how many lists are open, is the stack's knowledge: the consumers compute `canCollapseAll` and `canExpandAll` from the covered state of each list, so the control stays a pure view of those two facts.
**Approved**: pending

**Decision**: The `<<<` glyph is three overlapped lucide chevrons instead of an icon.
**Rationale**: The source comment states that lucide has no triple chevron, so the glyph is composed from three overlapped chevrons, pulled back by 8px each.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Screen-reader, keyboard, focus and semantic-markup pass because the control uses a named group, native buttons with explicit names, the native disabled state, a visible focus ring and hidden decorative glyphs. Touch-target-size fails because each half is about 34px by 18px, below the platform minimum (see the open question on `touch-target-size`); contrast-ratio is partial because the token values live in the theme (see the open question on `contrast-ratio`). The two string checks fail because all three labels are English literals with no override, and rtl-layout-support is partial because the chevrons and corner rounding use physical directions. Separation-of-concerns passes because the host decides when each half is enabled. Unit-test-coverage is passed because `coverAllControl.test.tsx` renders the control alone and covers all twelve vectors; the host layouts also exercise it through `hierarchicalTopicDetail.test.tsx` and `detailTitle.test.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (coverAllControl.test.tsx, 12 of 12 vectors); unit-test-coverage now passed. |
