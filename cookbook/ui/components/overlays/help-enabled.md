---
id: fcb8a0a4-2446-46f9-99bb-49b0317529d4
title: "HelpEnabled"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Interactive text wrapper that reveals a hover/focus badge and opens contextual help in a popover on click or activation."
platforms:
  - typescript
  - web
tags:
  - help
  - popover
  - inline-help
depends-on:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
  - 56828ee6-f522-45da-a9d8-6e1a99adf4e2
  - d6ff2cc3-89c8-4744-b3f4-7262e45a3414
related: []
references: []
approved-by: ""
approved-date: ""
---

# HelpEnabled

## Overview

HelpEnabled wraps text or labels to make them interactive help triggers. Hovering over or focusing the element reveals a small information badge; clicking or activating the element opens a popover displaying the help content. This component is designed for inline help on headlines, labels, and other text regions where additional context is valuable without blocking the primary content.

## Behavioral Requirements

- **renders-children**: Component MUST render the provided `children` prop as the primary text content.
- **renders-badge**: Component MUST render an Info icon badge adjacent to the children.
- **marks-badge-data-slot**: Component MUST apply `data-slot="help-enabled-badge"` to the Info icon badge.
- **accepts-id-prop**: Component MUST accept an `id` prop (string) to look up help content in the help store.
- **opens-popover-on-trigger**: Component MUST open a Popover containing help content when the trigger element is clicked or activated.
- **shows-popover-content**: Component MUST render a HelpPopoverContent component with the retrieved help entry inside the Popover.
- **accepts-fallback**: Component MUST accept an optional `fallback` prop (string) to display when no help entry exists for the given `id`.
- **wraps-fallback-as-info-entry**: When `fallback` is provided and no stored entry exists for `id`, Component MUST wrap the fallback string in a HelpEntry with `flavor: "info"` before rendering it in the popover.
- **suppresses-warning-when-fallback-given**: Component MUST NOT emit the missing-entry console warning when a `fallback` prop is provided, even though `id` has no stored entry.
- **accepts-classname**: Component MUST accept an optional `className` prop and apply it to the root element.
- **renders-plain-text-fallback**: When no help entry exists for the `id` and no `fallback` is provided, component MUST render the children as plain text in a span element without opening a popover.
- **marks-plain-text-variant**: Component MUST apply `data-slot="help-enabled-plain"` to the span when rendering the plain text fallback variant.
- **preserves-layout-on-missing-entry**: Component MUST preserve the `className` prop on the plain text fallback to maintain layout and styling applied by the caller.
- **warns-on-missing-entry**: Component MUST emit a console warning once per missing help `id` (throttled by `id`, not per render) indicating the missing help entry.
- **marks-interactive-variant**: Component MUST apply `data-slot="help-enabled"` to the PopoverTrigger element when rendering the interactive variant.
- **badge-hidden-by-default**: Component MUST render the Info badge at 0 opacity by default so it does not reflow the layout.
- **shows-badge-on-hover**: Component MUST transition the badge to 70% opacity when the user hovers over the trigger element.
- **shows-badge-on-focus**: Component MUST transition the badge to 70% opacity when the trigger element receives keyboard focus.
- **shows-badge-when-popover-open**: Component MUST transition the badge to 70% opacity when the popover is open.
- **marks-badge-aria-hidden**: Component MUST apply `aria-hidden="true"` to the Info badge icon.

## Appearance

- **Layout**: Inline flex container with horizontal gap, items vertically centered.
- **Gap**: 1 unit (0.25rem) between children and badge.
- **Padding**: Horizontal 0.25rem, vertical 0 (internal spacing for focus ring).
- **Badge size**: 12×12 pixels (size-3 in Tailwind; equivalent to 0.75rem).
- **Badge shrink**: Badge does not grow or shrink beyond its natural size.
- **Corner radius**: Small rounded corners (rounded-sm; 0.125rem).
- **Background color (default)**: Transparent.
- **Background color (hover/focus)**: `apt-surface-2`.
- **Border**: None.
- **Focus ring**: 2px ring in `apt-gold/40` (gold at 40% opacity) around the trigger element.
- **Focus ring outline**: None (outline set to outline-none to avoid double focus indicators).
- **Badge opacity (default)**: 0 (fully transparent).
- **Badge opacity (hover/focus/open)**: 0.7 (70% opaque).
- **Transitions**: Colors and opacity transition smoothly.

## States

| State | Appearance change |
|-------|------------------|
| Default | Badge opacity 0; no background color |
| Hover | Background changes to `apt-surface-2`; badge opacity transitions to 0.7 |
| Keyboard Focus | Background changes to `apt-surface-2`; badge opacity transitions to 0.7; focus ring appears (`ring-apt-gold/40`) |
| Popover Open | Badge opacity transitions to 0.7 (via `group-data-[popup-open]` selector) |
| No Help Entry (Plain Text) | Renders as plain span; no background, no badge, no focus ring styling |

## Accessibility

- **Role**: The interactive variant (with help entry) acts as a button that opens a popover. The component does not explicitly set role; it relies on Popover and PopoverTrigger to establish the correct semantics.
- **Label**: The trigger element contains the children text as its accessible label.
- **Screen reader announcement of the trigger**: HelpEnabled does not itself set `aria-haspopup`/`aria-expanded` or an accessible description beyond the children text; it delegates that to `PopoverTrigger` (Base UI's `Popover.Trigger`), which applies `aria-haspopup` and `aria-expanded` automatically to the element it renders. The accessible name remains only the children text — no additional description such as "Show help" is added.
- **Badge accessibility**: The Info icon badge is marked `aria-hidden="true"` as it is a visual affordance that duplicates the interactive nature of the parent element.
- **Focus**: The trigger element is focusable via keyboard (Tab key) and displays a visible focus indicator (gold ring).
- **Popover context**: The help content is announced by the popover's own accessibility attributes (out of scope for this component).
- **Plain text variant**: When rendered as plain text (no help entry, no fallback), the element is not interactive and does not receive focus.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| help-enabled-001 | renders-children | `<HelpEnabled id="test-id">Help Text</HelpEnabled>` with valid help entry | "Help Text" appears in the document |
| help-enabled-002 | renders-badge, marks-badge-data-slot | `<HelpEnabled id="test-id">Help Text</HelpEnabled>` with valid help entry | Info icon badge is rendered next to the text with `data-slot="help-enabled-badge"` |
| help-enabled-003 | accepts-id-prop | `<HelpEnabled id="unique-id">Text</HelpEnabled>` with a stored entry `{ body: "Stored help" }` for `"unique-id"` | The popover shows "Stored help" — the entry stored for `unique-id` |
| help-enabled-004 | opens-popover-on-trigger | User clicks the trigger element | Popover opens and displays help content |
| help-enabled-005 | shows-popover-content | `<HelpEnabled id="test-id">Text</HelpEnabled>` with valid entry `{ body: "Help", flavor: "info" }` | HelpPopoverContent is rendered inside the Popover with the entry |
| help-enabled-006 | accepts-fallback, wraps-fallback-as-info-entry, suppresses-warning-when-fallback-given | `<HelpEnabled id="no-entry" fallback="Fallback help">Text</HelpEnabled>` with no stored entry | Popover opens with fallback text in an `info` flavor entry; no console warning is emitted |
| help-enabled-007 | accepts-classname | `<HelpEnabled id="test-id" className="custom-class">Text</HelpEnabled>` with valid entry | `custom-class` is applied to the PopoverTrigger root element |
| help-enabled-008 | renders-plain-text-fallback | `<HelpEnabled id="no-entry">Text</HelpEnabled>` with no stored entry and no fallback | Renders as plain text in a span; no popover opens |
| help-enabled-009 | marks-plain-text-variant | `<HelpEnabled id="no-entry">Text</HelpEnabled>` with no stored entry and no fallback | span element has `data-slot="help-enabled-plain"` attribute |
| help-enabled-010 | preserves-layout-on-missing-entry | `<HelpEnabled id="no-entry" className="layout-class">Text</HelpEnabled>` with no entry and no fallback | `layout-class` is preserved on the plain text span |
| help-enabled-011 | warns-on-missing-entry | First render of `<HelpEnabled id="unknown">Text</HelpEnabled>` with no entry and no fallback | Console outputs warning: `[HelpEnabled] no help entry for id "unknown" — rendering plain text` |
| help-enabled-012 | warns-on-missing-entry | Second render of `<HelpEnabled id="unknown">Text</HelpEnabled>` in same session | No additional console warning (warning throttled by id) |
| help-enabled-013 | marks-interactive-variant | `<HelpEnabled id="test-id">Text</HelpEnabled>` with valid entry | PopoverTrigger root has `data-slot="help-enabled"` attribute |
| help-enabled-014 | badge-hidden-by-default | Component renders with valid entry | Badge's computed opacity is 0 |
| help-enabled-015 | shows-badge-on-hover | User hovers over trigger element | Badge's computed opacity transitions to 0.7 |
| help-enabled-016 | shows-badge-on-focus | User tabs to trigger element with keyboard | Badge's computed opacity transitions to 0.7 |
| help-enabled-017 | shows-badge-when-popover-open | Popover is open | Badge's computed opacity is 0.7 |
| help-enabled-018 | marks-badge-aria-hidden | Component renders badge | Info icon has `aria-hidden="true"` |

## Edge Cases

- **Missing help entry, no fallback**: Renders plain text span. Caller's layout styles are preserved so the UI does not reflow. Console warning is emitted once.
- **Missing help entry, with fallback**: Popover opens with fallback text in an `info` flavor entry. No console warning is emitted because a fallback is provided.
- **Empty children prop**: Component will render an empty inline flex container with only the badge visible. This is allowed; the component does not validate input.
- **Very long children text**: Component does not limit text length. Layout depends on caller-provided `className` and page context.
- **Popover open, element removed from DOM**: Popover state is managed by the Popover component; behavior follows Popover's unmount logic.
- **Multiple renders with same `id` and no entry**: Warning is throttled by id; only one warning emitted per session even if component mounts/unmounts multiple times.
- **Touch devices (no hover)**: The badge's default reveal relies on `hover`, and touch devices have no hover state, so the badge does not become visible from touch input alone. It still reveals on keyboard focus (e.g., assistive technology's virtual cursor) and once the popover is open, and the trigger remains reachable by tapping it even while the badge sits at 0 opacity. This is an accepted limitation of the hover-based affordance, not a bug.

## Configuration

Not applicable: HelpEnabled accepts configuration via props (`id`, `children`, `className`, `fallback`), not via separate configuration objects or settings.

## Deep Linking

Not applicable: HelpEnabled is not a navigable destination and does not define URL patterns.

## Localization

Not applicable: HelpEnabled does not render hardcoded strings. Help content is retrieved via `useHelpEntry(id)` and managed by the help store. Fallback text is supplied by the caller as a string prop.

## Accessibility Options

- **Reduce Motion**: The component does not disable or gate its opacity/background transitions when the system's Reduce Motion preference is on. Tailwind's `transition-*` utility classes do not automatically honor `prefers-reduced-motion` — that requires an explicit `motion-reduce:` variant, which this component does not apply. This is a known gap in the current implementation.
- **Increase Contrast**: Badge color at `opacity-70` may not meet WCAG AA contrast on all backgrounds. See Design Decisions: "Badge contrast not guaranteed".
- **Differentiate Without Color**: The badge is an icon shape (Info symbol), not solely color- or opacity-based, so its meaning does not depend on a user perceiving color or the opacity change.

## Feature Flags

Not applicable: HelpEnabled does not define feature flags. Help content retrieval is controlled by the help store (out of scope for this component).

## Analytics

Not applicable: HelpEnabled does not emit analytics events. Event tracking for help interactions is delegated to the Popover or HelpPopoverContent components.

## Privacy

Not applicable: HelpEnabled does not collect or transmit user data. The `id` prop is a lookup key for the help store and does not expose personal information.

## Logging

Subsystem: none (browser console) | Category: HelpEnabled

| Event | Level | Message |
|-------|-------|---------|
| Missing help entry | warn | `[HelpEnabled] no help entry for id "<id>" — rendering plain text` |

Emitted once per missing `id` per session (see **warns-on-missing-entry**); never emitted when a `fallback` is supplied (see **suppresses-warning-when-fallback-given**).

## Platform Notes

- **React/Web**: HelpEnabled is a React functional component exported from `packages/web/packages/ui/src/components/help-enabled.tsx`. It uses Tailwind CSS for styling, the `lucide-react` library for the Info icon, and internal Popover and HelpPopoverContent components. The file starts with the `"use client"` directive, which marks it as a React Server Components client boundary, not a server-side-rendering compatibility shim. The badge's opacity states are implemented with Tailwind `group` variants: `opacity-0` by default, `group-hover:opacity-70` on hover, `group-focus-visible:opacity-70` on keyboard focus, and `group-data-[popup-open]:opacity-70` while the popover is open, all driven by the plain `transition-opacity` utility with no `motion-reduce:` guard.
- **SwiftUI**: SwiftUI does have a direct Popover API — use `.popover(isPresented:)` on the trigger to present the help content. Build the trigger from a `Button` (or a `Text` with `.onTapGesture`), and replicate the hover/focus badge reveal by animating the Info image's `.opacity` between 0 and 0.7 driven by `.onHover` (macOS) and `@FocusState` (keyboard). Apply `.accessibilityHidden(true)` to the badge's `Image` to hide it from VoiceOver.
- **Compose**: Build with a `Row` or `Surface` composable wrapping the text, made clickable via `Modifier.clickable()` to open the popover, and paired with a `remember { MutableInteractionSource() }` plus `Modifier.hoverable(interactionSource)` to detect pointer hover on non-touch input. Implement badge visibility changes via `animateFloatAsState` for opacity. Hide the badge from accessibility services with `Icon(imageVector = ..., contentDescription = null)` — passing `contentDescription = null` to `Icon` is how Compose marks it decorative, not `Modifier.semantics { contentDescription = null }`.
- **AppKit / UIKit**: Use a custom `NSButton` (AppKit) or `UIButton` subclass (UIKit) as the trigger, overlaying the Info badge as a small `CALayer` or `NSImageView`/`UIImageView`. Present the help content with `NSPopover` on AppKit or a view controller presented via `UIPopoverPresentationController` on UIKit. Implement hover detection via `NSTrackingArea` (AppKit) or a hover-based `UIHoverGestureRecognizer` (UIKit, pointer input only). Hide the badge image from accessibility clients (`isAccessibilityElement = false` / AppKit's `NSAccessibility.isElement = false`), and use `UIAccessibility.isVoiceOverRunning` only to adjust behavior that genuinely differs for VoiceOver users.
- **WinUI 3**: Use a `Grid` or `StackPanel` (horizontal orientation) as the root, hosting a `TextBlock` for the children and a `FontIcon` (from Segoe MDL2 Assets, its `Glyph` property set to the info glyph) for the badge — `Glyph` is a property of `FontIcon`, not a control on its own. Wrap in a `Button` to make it interactive. Bind badge opacity to a `VisualState` (default, hover, focus) using `VisualStateManager`. The button's `Click` event opens a `Flyout` (WinUI's equivalent to a popover). Use the `AutomationProperties.HelpText` attached property on the button, and set `AutomationProperties.AccessibilityView` to `Raw` on the `FontIcon` to hide it from automation readers.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/help-enabled.tsx` | unverified |

## Design Decisions

**Horizontal inline layout with gap**

**Decision**: The component uses `inline-flex items-center gap-1` to position the badge adjacent to the text without adding extra line height or block layout.
**Rationale**: This keeps the help affordance compact and preserves the caller's line metrics.
**Approved**: pending

**Badge transparency by default**

**Decision**: The Info badge is rendered but fully transparent (`opacity-0`) so that its presence does not reflow the layout when invisible; revealing it on hover/focus is a smooth transition without layout shift.
**Rationale**: A badge that mounts/unmounts on hover would shift surrounding layout; keeping it always mounted and only changing its opacity avoids that.
**Approved**: pending

**Warning throttling by id, not per-render**

**Decision**: Missing help entries emit a warning once per unique `id` per session (not per render).
**Rationale**: The component may be rendered multiple times on the same page, and per-render warnings would produce console noise without additional value.
**Approved**: pending

**Fallback as HelpEntry, not plain text**

**Decision**: When a fallback string is provided, it is wrapped in a HelpEntry object with flavor `"info"` so that it flows through the same rendering pipeline as stored entries.
**Rationale**: This keeps the implementation simple and consistent — one rendering path for both stored and fallback content.
**Approved**: pending

**Preserve className on plain text variant**

**Decision**: When help is not available and no fallback is provided, the component preserves the caller's `className` on the plain text span.
**Rationale**: Caller-specific layout styles (e.g., centering, ellipsis clipping) must not be lost due to the missing help entry.
**Approved**: pending

**data-slot attributes for variant detection**

**Decision**: The component applies `data-slot="help-enabled"` and `data-slot="help-enabled-plain"` to distinguish interactive and plain text variants in CSS and for testing.
**Rationale**: This avoids requiring pseudo-class selectors or attribute mutations to detect state.
**Approved**: pending

**Focus ring uses gold token**

**Decision**: The focus indicator uses `ring-apt-gold/40` (gold at 40% opacity) for consistency with other interactive controls in the design system (the `quietControlClass` pattern).
**Rationale**: This token is shared with chevrons, split dividers, dialog close buttons, and collapse toggles, so keyboard focus reads the same way across the family.
**Approved**: pending

**Badge contrast not guaranteed**

**Decision**: The Info badge's hover/focus/open opacity (`opacity-70`) is not verified against every possible caller-supplied background; contrast sufficiency is left to the design system's color tokens (`apt-surface-2`, `apt-gold/40`) rather than guaranteed by this component.
**Rationale**: HelpEnabled is a layout/behavior wrapper, not a color-token owner; enforcing contrast for arbitrary backgrounds would require knowledge of the surrounding page that this component does not have.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source directly: the trigger's accessible name is children-only text with `aria-haspopup`/`aria-expanded` left to `PopoverTrigger` rather than confirmed here (partial); Tab focus and the visible gold ring are implemented (passed); badge contrast at `opacity-70` is called out in Accessibility Options as unverified against arbitrary backgrounds (partial); no `motion-reduce:` guard exists on any transition (failed); focus/overlay handling is delegated entirely to Popover rather than managed here (partial); the console warning is a static string plus a non-PII `id` lookup key (passed for logging and privacy); and no user-visible string is hardcoded — help copy and fallback text both arrive as props/store data (passed). `separation-of-concerns` is partial because the fallback-resolution decision (`stored ?? fallback`) and the warn-once `Set` bookkeeping sit inline in the component body rather than in an extracted hook; `unit-test-coverage` passes on `help-enabled.test.tsx`'s exercise of the badge, the popover open, the plain-text/fallback paths, and the once-per-id warning.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: resolved the hover/focus vs. click trigger contradiction in the summary and Overview; corrected the Reduce Motion, SwiftUI Popover, Compose accessibility, "use client", and WinUI `Glyph` claims; renamed all requirements to subject-only kebab-case and added badge-data-slot, fallback-wrapping, and warning-suppression requirements; moved Tailwind class names out of the badge-visibility requirements and test vectors into the React/Web platform note; added tags and depends-on, converted Design Decisions to the Decision/Rationale/Approved form and added a contrast decision, added the Compliance table, and rewrote Logging; fixed the test 003 implementation-coupled assertion and the test 017 requirement-name mismatch; and replaced the incoherent "fallback without id" edge case with a touch-device edge case |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
