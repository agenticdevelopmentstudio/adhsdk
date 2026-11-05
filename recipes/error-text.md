---
id: c9e70ad4-89c9-4c44-a2d6-a64da32a64af
title: Error Text
domain: adhsdk://recipes/error-text
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Canonical inline error display component for validation and alert messages
platforms:
- typescript
- web
tags:
- error-text
- alerts
- form-validation
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Error Text

## Overview

Error Text is the single, canonical component for displaying inline error messages and validation failures across all surfaces in the web platform. Every validation message, form error, and thrown message renders using this component to ensure consistent styling, accessibility, and behavior. The component conditionally renders only when an error is present. Two variants are provided: `ErrorText` renders as a paragraph for most contexts, and `DialogErrorText` renders as a block-displayed span for use inside dialog descriptions where paragraph nesting is not permitted.

## Behavioral Requirements

- **render-when-error-present**: The component MUST render an element with `role="alert"` when the `error` prop is a non-empty string, signaling to assistive technologies that the content is a time-sensitive alert or error message.
- **render-nothing-when-error-absent**: The component MUST return `null` and render nothing when the `error` prop is `null`, `undefined`, or an empty string.
- **include-error-text-content**: The component MUST render the exact text from the `error` prop as the element's text content.
- **apply-error-color**: The component MUST apply the design system's error color token to the rendered element by default, and this color MUST NOT be overridden by a caller-supplied `className`. See Design Decision **color-and-role-non-negotiable**.
- **default-text-size**: The component applies the design system's small text-size token to the rendered element by default. Callers MAY override the size via `className` for dense layouts; overriding the size MUST NOT affect the error color or the alert role.
- **support-classname-prop**: The component MUST accept an optional `className` prop and merge it with the default classes using the `cn()` utility function.
- **error-text-render-as-paragraph**: The `ErrorText` variant MUST render the alert as a `<p>` element.
- **dialog-error-text-render-as-span**: The `DialogErrorText` variant MUST render the alert as a `<span>` element with block-level display, to create a line-break effect without nesting `<p>` inside `<p>`.
- **dialog-error-text-top-margin**: The `DialogErrorText` variant MUST apply the design system's small top-margin token to provide vertical spacing from the dialog description text.

## Appearance

- **Element Type**: `ErrorText` renders as `<p>`; `DialogErrorText` renders as `<span class="block">`
- **Text Size**: `text-sm` (14px or equivalent per Tailwind design system)
- **Text Color**: `text-apt-red` (error color token from design system)
- **Spacing**: No padding applied by component. `DialogErrorText` applies `mt-2` (top margin). Outer spacing is controlled by the caller via the `className` prop.
- **Display**: `block` display applied only to `DialogErrorText`; `ErrorText` uses default paragraph block behavior
- **Font Weight**: Inherits from system (not specified)
- **Line Height**: Inherits from system (not specified)
- **Background**: Transparent
- **Border**: None
- **Shadow**: None

## States

Not applicable: Error Text is a static, non-interactive display element with no internal state management. It renders when an error is present and returns null when absent; there are no pressed, focused, loading, or disabled states.

## Accessibility

- **Role**: The component sets `role="alert"` to signal to screen readers that the content is an alert or error message that requires immediate attention.
- **Text Content as Label**: The error message itself is the accessible label; no additional `aria-label` or `aria-labelledby` is required because the text is visible and announced.
- **Screen Reader Announcement**: When an error appears, screen readers announce it as an alert. When the error is dismissed (component returns null), the text is no longer present in the DOM. This relies on the container itself being visible when the error mounts; see the **Zero-width or hidden parent container** edge case for the one sequence where announcement is not guaranteed.
- **Keyboard Interaction**: Error Text is not keyboard-interactive; it is a passive text display. Focus management and form submission behavior are the responsibility of the containing form or surface.
- **Color and Meaning**: The message is communicated both by the red color (`text-apt-red`) and the text content. The text content provides a redundant signal for users with color vision deficiency and ensures the message is not color-dependent.

## Conformance Test Vectors

| ID | Requirements | Input | Action | Expected |
|----|-------------|-------|--------|----------|
| error-text-001 | render-when-error-present, error-text-render-as-paragraph | `error="Username is required"`, variant: `ErrorText` | Render component | A `<p role="alert">` element appears with text "Username is required" |
| error-text-002 | render-nothing-when-error-absent | `error={null}` | Render component | Component returns `null`; no element is rendered |
| error-text-003 | render-nothing-when-error-absent | `error={undefined}` | Render component | Component returns `null`; no element is rendered |
| error-text-004 | render-nothing-when-error-absent | `error=""` | Render component | Component returns `null`; no element is rendered |
| error-text-005 | include-error-text-content | `error="Invalid email format"` | Render component; inspect text | Text content of the element is exactly "Invalid email format" |
| error-text-006 | apply-error-color, default-text-size | `error="Error message"` | Render component; inspect classList | The element includes both `text-sm` and `text-apt-red` classes in its class attribute |
| error-text-007 | render-when-error-present | `error="Error"` | Render component; inspect attributes | The element has `role="alert"` attribute |
| error-text-008 | support-classname-prop | `error="Error"`, `className="px-4"` | Render component; inspect classList | The element includes `px-4` in its class attribute, merged with the default classes via `cn()` |
| error-text-009 | dialog-error-text-render-as-span | `error="Error"`, variant: `DialogErrorText` | Render component; inspect element type | A `<span>` element is rendered, not `<p>` |
| error-text-010 | dialog-error-text-top-margin, dialog-error-text-render-as-span, apply-error-color, default-text-size | `error="Error"`, variant: `DialogErrorText` | Render component; inspect classList | The span includes `mt-2`, `block`, `text-sm`, and `text-apt-red` classes |
| error-text-011 | render-nothing-when-error-absent | `error={null}`, variant: `DialogErrorText` | Render component | Component returns `null`; no element is rendered |
| error-text-012 | support-classname-prop | `error="Error"`, `className="px-4"`, variant: `DialogErrorText` | Render component; inspect classList | The span includes `px-4` merged with the default classes (`mt-2`, `block`, `text-sm`, `text-apt-red`) via `cn()` |
| error-text-013 | default-text-size, apply-error-color | `error="Error"`, `className="text-xs"` | Render component; inspect classList | The element's class attribute includes `text-xs` in place of the default `text-sm` — `tailwind-merge` resolves the conflicting size utility in favor of the caller's class — while `text-apt-red` remains present and unaffected |
| error-text-014 | render-when-error-present | `error="Error"`, parent container `display: none` | Render component; inspect DOM | The `role="alert"` element is present in the DOM despite the hidden parent; this vector does not assert screen-reader announcement timing once the container becomes visible |

## Edge Cases

- **Null or undefined error**: When `error` is `null` or `undefined`, the component returns `null` and renders nothing. No error is thrown. (MUST)
- **Empty string error**: When `error` is an empty string (`""`), the component returns `null` because empty string is falsy in JavaScript. This prevents rendering an empty, invisible alert element. (MUST)
- **Whitespace-only error**: If `error` is a string containing only whitespace (e.g., `" "` or `"\n"`), the component renders the whitespace as text content. Callers SHOULD trim error messages at the call site to avoid empty-appearing alerts; this is a data validation issue, not a component issue. (SHOULD)
- **Very long error text**: The component renders the full error text without truncation. Text wrapping and overflow are determined by the container's CSS and dimensions, which the caller controls. (MUST)
- **HTML markup and special characters in error text**: If `error` contains HTML markup (e.g., `<b>error</b>`) or special characters (`&`, `<`, `>`, `"`), the component renders them as literal text, not as HTML — JSX text content is escaped automatically by React, and the component does not use `dangerouslySetInnerHTML`. This is inherited from React's rendering model rather than component-specific logic, so no RFC 2119 tag applies here.
- **className override of text size**: When `className="text-xs"` is passed, `cn()` (`clsx` + `tailwind-merge`) resolves the conflicting Tailwind size utility in favor of the caller's class, so only `text-xs` remains in the rendered class attribute — not both `text-sm` and `text-xs`. See **default-text-size**. Callers SHOULD verify that the resulting text size is legible and acceptable in their layout. (SHOULD)
- **Paragraph nesting error**: The standard `ErrorText` renders a `<p>` tag. It MUST NOT be used as a child of another `<p>` tag because HTML does not permit nested paragraphs; the browser will auto-close the outer paragraph. Use `DialogErrorText` in dialog descriptions or other `<p>` contexts. (MUST)
- **Zero-width or hidden parent container**: If the parent container has `display: none` or `visibility: hidden`, the error text is not visible but is still present in the DOM. Announcement by screen readers when the container later becomes visible is not guaranteed: a `role="alert"` live region reliably announces content that changes after the region is already mounted, not content that was already present when the region first mounted (see **render-when-error-present**). Callers that need a guaranteed announcement in this sequence SHOULD re-trigger it — for example, by updating the text again after the container becomes visible. (SHOULD)

## Configuration

Not applicable: Error Text has no configuration options beyond the two required props (`error` and optional `className`). There are no feature flags, toggles, or runtime configuration.

## Deep Linking

Not applicable: Error Text is a display primitive component with no deep linking capability or URL patterns. It is rendered as part of other surfaces.

## Localization

Not applicable: Error Text does not contain any user-facing strings that require localization. The error message text is provided by the caller and is assumed to be already localized at the point of use.

## Accessibility Options

Not applicable: Error Text does not respond to system-level accessibility display options such as Reduce Motion, Increase Contrast, or Differentiate Without Color. It is a static text display that inherits styling from the design system's color and type tokens.

## Feature Flags

Not applicable: Error Text has no feature flags. It is always enabled and available for use in any context.

## Analytics

Not applicable: Error Text does not emit analytics events. It is a passive, stateless display component. Analytics for error frequency, types, and user interactions is the responsibility of the form or surface that produces the error.

## Privacy

Not applicable: Error Text does not collect, store, or transmit data. The error text is provided by the caller and is rendered and destroyed within the component lifecycle; no data is persisted.

## Logging

Not applicable: Error Text does not perform any logging. Diagnostic or debugging logs for errors are the responsibility of the calling code.

## Platform Notes

- **React/Web (TypeScript)**: The source implementation is a React functional component with TypeScript prop types, using the `cn()` utility (`clsx` + `tailwind-merge`) to combine Tailwind classes. `ErrorText` renders `<p role="alert">` with the error-color token (`text-apt-red`) and the default small-text token (`text-sm`), plus any caller-provided `className` overrides. `DialogErrorText` renders `<span role="alert">` with `block` display, the top-margin token (`mt-2`), and the same `text-sm text-apt-red` treatment, plus overrides. Both return `null` when `error` is falsy. `cn()`'s `tailwind-merge` step resolves a caller override that conflicts with the default size class (e.g., `text-xs` replaces `text-sm`) in favor of the caller's class — this is how dense surfaces like the DM composer and notification inbox get a smaller size — but no caller overrides the color or role, per Design Decision **color-and-role-non-negotiable**. (Files: `packages/web/packages/ui/src/components/error-text.tsx`)
- **SwiftUI (Apple)**: An equivalent component would render a `Text` view with red color (mapping the error color token to SwiftUI's `Color` system). To signal the alert, post `AccessibilityNotification.Announcement(errorText).post()` when the error text appears — there is no persistent-alert trait equivalent to a web live region. For dialog contexts, consider `Text` inside a `VStack` with top padding to mimic the span layout.
- **Compose (Kotlin/Android)**: A Compose equivalent would render a `Text` composable with red color from the design system palette. Apply `Modifier.semantics { liveRegion = LiveRegionMode.Assertive }` (there is no `Role.Alert` in Compose) so the text is announced as it appears. For dialog contexts, use `Text` inside a `Column` with `Modifier.padding(top = 8.dp)` (equivalent to the top-margin token) and `Modifier.fillMaxWidth()` for block layout.
- **AppKit / UIKit (Apple)**: On macOS/iOS, render a `UILabel` or `NSTextField` with red text color. To announce the alert, post `UIAccessibility.post(notification: .announcement, argument: errorText)` on iOS, or the NSAccessibility announcement equivalent (`NSAccessibility.post(element:, notification: .announcementRequested, userInfo:)`) on macOS, when the error text appears — `.updatesFrequently` is a trait for elements whose value changes often, not an alert signal, so it is not used here. For dialog contexts, use a `UIStackView` or `NSStackView` with appropriate vertical spacing and layout constraints.
- **WinUI 3**: Render a `TextBlock` with red `Foreground` color from the design system. Set `AutomationProperties.LiveSetting = AutomationLiveSetting.Assertive` and raise `AutomationEvents.LiveRegionChanged` (via `UIElementAutomationPeer.RaiseAutomationEvent`) whenever the text changes, so Narrator announces it; `AutomationProperties.Name`/`AutomationId` do not drive screen-reader announcements and are not used for this purpose. For dialog contexts, place the `TextBlock` in a `StackPanel` with `Margin` `0,8,0,0` (top margin equivalent to the top-margin token) and `HorizontalAlignment` set to `Stretch` for block-like layout.

## Design Decisions

**canonical-home**

**Decision**: Error Text is the single, authoritative component for all inline error and validation messages across the platform. Styling (color and text size), the alert role, and the conditional render logic live in exactly one place.
**Rationale**: Consolidating ownership prevents drift across surfaces. If a surface needs a different visual treatment for errors, that need signals a review of whether Error Text should be extended, or whether the surface genuinely requires a different component, rather than a silent fork of the styling.
**Approved**: pending

**two-variants-one-treatment**

**Decision**: `ErrorText` and `DialogErrorText` share the same color and text-size treatment; the only difference between them is the rendered element (`<p>` vs. `<span class="block">`).
**Rationale**: HTML forbids nesting `<p>` inside `<p>`, so the element choice is a structural constraint, not a design choice — treatment stays uniform while structure adapts to context.
**Approved**: pending

**classname-layout-flexibility**

**Decision**: The `className` prop lets callers add padding/margin and, per **default-text-size**, adjust text size in dense layouts (e.g., `text-xs` in the DM composer and notification inbox) without requiring a new component variant.
**Rationale**: `cn()` merges caller classes with the defaults, so metric overrides are possible while the core treatment defined in **apply-error-color** is preserved by convention.
**Approved**: pending

**color-and-role-non-negotiable**

**Decision**: The error color and the `role="alert"` attribute are the two parts of the treatment that callers must never change; text size may be overridden, color and role may not.
**Rationale**: `role="alert"` is a fixed JSX attribute, outside `className`, so it cannot be overridden through this component's public API at all. The color token, by contrast, passes through `cn()`'s `tailwind-merge` step and could technically be overridden by a conflicting color class — this is prevented by convention and code review, not by a runtime guard, so a caller needing a different color (e.g., yellow for warning, blue for info) is signaling that the message is not an error and should use a different component.
**Approved**: pending

**null-return-over-empty-element**

**Decision**: When no error is present, the component returns `null` rather than rendering an empty, invisible alert element.
**Rationale**: Reduces DOM noise and prevents screen reader users from encountering empty alerts.
**Approved**: pending

**span-variant-for-dialogs**

**Decision**: `DialogErrorText` renders a `<span>` with block display instead of a second `<p>`-based treatment.
**Rationale**: Dialog descriptions render as `<p>` tags (per Base UI convention), and HTML forbids nesting `<p>` inside `<p>` — the browser would auto-close the outer paragraph. A block-displayed `<span>` preserves the same line-by-line layout while respecting that structural rule; the top-margin token (see **dialog-error-text-top-margin**) separates it from the description text.
**Approved**: pending

**alert-role-for-screen-reader-announcement**

**Decision**: Both variants set `role="alert"` so screen readers are notified when the error text appears.
**Rationale**: In dialogs particularly, the error text changes dynamically under a focus trap with no other visual affordance calling attention to it, making the alert role the most reliable notification available — though see the **render-when-error-present** edge case on hidden containers for the one sequence where that reliability doesn't hold.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Status rests on the source: `role="alert"` and the element's classes are read directly from `error-text.tsx`, so `semantic-markup` passes; the actual color and font-size *values* behind the error-color and text-size tokens are defined in the design system's token files, not in this component's source, so `contrast-ratio` and `dynamic-type-support` are `partial`; and `no-hardcoded-strings`/`unicode-support` pass because the component never embeds a literal user-facing string of its own — `error` is caller-supplied and rendered as plain JSX text content. `separation-of-concerns` is `passed` because both exports are pure presentation over a caller-supplied `error` string with no logic beyond a truthy guard; `unit-test-coverage` is `passed` because `errorText.test.tsx` renders both `ErrorText` and `DialogErrorText` directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web implementation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: folded duplicate requirements (alert role, dialog treatment) into their survivors; renamed all requirements to subject-only kebab-case; split the color/size requirement so it matches the documented `className` override policy, grounded in `cn()`'s `tailwind-merge` behavior; moved Tailwind class names out of Behavioral Requirements and into the React/Web platform note; corrected the SwiftUI, UIKit/AppKit, Compose, and WinUI 3 accessibility-announcement APIs; hedged two edge cases that stated uncertain screen-reader/DOM behavior as fact; reformatted Design Decisions into named Decision/Rationale/Approved entries; added a Compliance table; added test vectors for `className` merging on `DialogErrorText`, the size-override behavior, and the hidden-container DOM-presence case |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
