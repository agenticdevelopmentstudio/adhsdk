---
id: 054522c7-53c8-45e4-9003-8c317a93b674
title: Document Identity Field
domain: adhsdk://recipes/document-identity-field
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Text inputs for document title and slug with optional availability checking.
platforms:
- typescript
- web
tags:
- form
- input
- document-metadata
depends-on:
- adhsdk://recipes/field
- adhsdk://recipes/input
related: []
references: []
approved-by: ''
approved-date: ''
---

# Document Identity Field

## Overview

A compound field that captures the two values that identify a document: its human-readable title and its URL-safe slug. The slug initially tracks title edits through a user-supplied slugify function; once the user manually edits the slug, it decouples and stays as edited. An optional availability checker reports whether the current slug is free, in progress, or taken.

## Behavioral Requirements

- **render-two-inputs**: Component MUST render two text inputs, one for title and one for slug.
- **render-title-label**: Component MUST render a label for the title input (default text "Title", customizable via `titleLabel` prop).
- **render-slug-label**: Component MUST render a label for the slug input (default text "Slug", customizable via `slugLabel` prop).
- **accept-title-prop**: Component MUST accept `title` string prop and display it in the title input.
- **accept-slug-prop**: Component MUST accept `slug` string prop and display it in the slug input.
- **title-change-callback**: Component MUST call `onTitleChange` callback with the new string when the user edits the title input.
- **slug-change-callback**: Component MUST call `onSlugChange` callback with the new string when the user edits the slug input.
- **slug-follows-title**: Component MUST call `onSlugChange` when the user edits the title, passing the result of applying the `slugify` function to the new title, if the slug has not been manually edited.
- **stop-auto-slugify-after-manual-edit**: Component MUST stop auto-generating the slug from the title once the user has manually edited the slug; on subsequent title edits, the slug remains unchanged until the component is remounted (e.g., with a new `key`) — there is no in-place reset.
- **accept-slugify-function**: Component MUST accept a `slugify` function prop that takes a title string and returns a slug string, used to derive the slug from title edits.
- **accept-verdict**: Component MUST accept an optional `verdict` prop (SlugVerdict type) with properties `status` ("idle" | "checking" | "available" | "unavailable") and `reason` (string or null).
- **display-status-message**: Component MUST display a status message corresponding to the verdict status: null for "idle", "Checking…" for "checking", "Available" for "available", "Unavailable" for "unavailable".
- **display-verdict-reason**: Component MUST display `verdict.reason` when present and non-null, replacing the default status message; the reason is displayed for all non-idle statuses.
- **announce-status-changes**: Component MUST announce verdict status changes and reason text to assistive technology using an `aria-live="polite"` region.
- **accept-disabled-prop**: Component MUST accept an optional `disabled` boolean prop (default false); when true, both inputs MUST be disabled.
- **container-class-name**: Component MUST accept an optional `className` string prop and apply it to the container element.
- **position-status-in-slug-row**: Component MUST render the status message as a sibling element to the slug input within the same row, not below or above it.
- **use-monospace-slug-font**: Component MUST render the slug input's text in a monospace font, at a smaller size than the title input.

## Appearance

- **Container**: Vertical stack, full width, rows separated by a 12pt gap; part of the shared field-label-column group.
- **Row layout**: Each row places a right-aligned caption in the shared label column beside its control (inline field layout), not above it.
- **Title input**: Text input; inherits the platform's default height, padding, border, and font.
- **Slug input**: Text input; font is monospace at roughly 0.8× the title input's font size.
- **Status message**: Text, roughly 0.75× the body font size, colored by tone (muted, success, or error), positioned beside the slug input with an ~8pt gap.
- **Gap between rows**: 12pt.

Reference implementation (`document-identity-field.tsx`): the container uses Tailwind's `gap-3` (12px); the slug input uses `text-[0.8rem]`; the status message uses `text-xs` (0.75rem) and an 8px (`gap-2`) offset from the slug input.

## States

| State | Appearance change |
|-------|------------------|
| Default | Title and slug inputs render with inherited platform styles; status message is null or not rendered |
| Verdict: checking | Status message displays "Checking…" in muted tone |
| Verdict: available | Status message displays "Available" in success tone |
| Verdict: unavailable | Status message displays the reason (or "Unavailable") in error tone |
| Slug touched | Slug no longer auto-follows title; once touched, a title edit alone changes neither the slug nor the verdict |
| Disabled | Both inputs are disabled; text is grayed; cursor is not-allowed; user cannot edit |

## Accessibility

- **Role**: Compound form control presenting two text inputs
- **Title input label**: Associated via the shared `<label>` element that implicitly wraps both caption and input; the title's accessible name never changes, so implicit wrapping is safe.
- **Slug input label**: Associated via `aria-labelledby` pointing to a `<span id>` containing only the label text — a different technique than the title's, because the slug row's implicit `<label>` also wraps the status span; without `aria-labelledby` the slug input's accessible name would grow, and mutate, with every verdict. `aria-describedby` then carries the verdict as a description, which is allowed to change.
- **Status announcement**: Rendered in an `aria-live="polite"` region; region is unconditionally mounted in DOM so changes are announced
- **Status as description**: Slug input uses `aria-describedby` pointing to status message element when status is present
- **Minimum tap target**: Both inputs inherit minimum touch target size from Input component (platform default, typically 44×44pt on iOS, 48×48dp on Android)
- **Keyboard navigation**: Both inputs are keyboard accessible; Tab navigates title → slug in document order. The status message is never focusable and takes no place in the Tab sequence; it is announced through the `aria-live` region instead.
- **Focus management**: Each input receives focus independently; focus is not trapped or redirected
- **High contrast**: Status message colors derive from tone tokens (muted, success, error) which meet WCAG AA contrast requirements
- **Color not alone**: Slug status is communicated by text and color; unavailable vs. available is text-differentiated, not color-only

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-id-001 | render-two-inputs | Component mounted with title="Test" slug="test" | Title and slug inputs both render |
| doc-id-002 | render-title-label, render-slug-label | Component with default labels | "Title" caption sits beside the title input in the shared label column; "Slug" caption sits beside the slug input in the same column |
| doc-id-003 | accept-title-prop | title="Custom Title" | Title input value is "Custom Title" |
| doc-id-004 | accept-slug-prop | slug="custom-slug" | Slug input value is "custom-slug" |
| doc-id-005 | title-change-callback | User types "New" in title input | onTitleChange callback fires with the new title string on each keystroke |
| doc-id-006 | slug-change-callback | User types "new-slug" in slug input | onSlugChange fires once per keystroke; the last call receives the full string "new-slug" |
| doc-id-007 | slug-follows-title | title="" slug="" not touched, slugify=(t)=>t.toLowerCase(); user types "Hello World" | onTitleChange and onSlugChange both fire; slug becomes "hello world" |
| doc-id-008 | stop-auto-slugify-after-manual-edit | User types "Hello" (slug becomes "hello"), then manually edits slug to "custom", then title changes to "New" | Slug remains "custom", does not become "new" |
| doc-id-009 | accept-verdict | verdict={{status:"available", reason:null}} | Status message displays "Available" |
| doc-id-010 | display-verdict-reason | verdict={{status:"unavailable", reason:"Already taken"}} | Status message displays "Already taken", not "Unavailable" |
| doc-id-011 | announce-status-changes | verdict changes from idle to checking to available | aria-live region content changes, assistive tech announces "Checking…" then "Available" |
| doc-id-012 | accept-disabled-prop | disabled=true | Both title and slug inputs have disabled attribute; user cannot edit either |
| doc-id-013 | position-status-in-slug-row | Component rendered | Status message is horizontally adjacent to slug input (same row), not below it |
| doc-id-014 | use-monospace-slug-font | Component rendered | Slug input uses a monospace font at a smaller size than the title input |
| doc-id-015 | container-class-name | className="custom-class" | Container element's class list includes "custom-class" in addition to its own layout classes |
| doc-id-016 | render-title-label, render-slug-label | titleLabel="Document Name" slugLabel="URL Slug" | Title caption reads "Document Name"; slug caption reads "URL Slug" |
| doc-id-017 | display-status-message | verdict left at default ({status:"idle", reason:null}) | Status message renders no text (null) in the slug row |
| doc-id-018 | announce-status-changes | verdict={{status:"unavailable", reason:"Already taken"}} | Slug input's aria-describedby references the status element's id; the status element's text is "Already taken" |

## Edge Cases

- **Empty title, slug not touched**: If title is empty string and slugify returns empty, slug input value is empty; `useSlugAvailability` does not trigger a check when its `slug` argument is empty, so no verdict changes for an empty slug.
- **Null reason in verdict**: If verdict.reason is not present or is null, status message displays the default text for the status (e.g., "Available"), not null or "undefined".
- **Verdict for stale slug**: `useSlugAvailability` stamps each answer with the slug (and optional `subject`) it was asked about and discards an answer whose stamp no longer matches the current question. This discarding is the hook's responsibility, not the component's: the component itself has no notion of a verdict's age — it only ever receives and displays whichever verdict its `verdict` prop currently holds, whether that verdict comes from `useSlugAvailability` or from a caller-supplied source.
- **Checker throws**: If the slug availability checker passed to `useSlugAvailability` throws, the hook's verdict reverts to idle; the component does not display a distinct error state for this case, since it cannot distinguish "the network is down" from "the slug is taken."
- **Remount with same document ID, different slug**: If the component is remounted (key changes), the touched state resets to false and slug begins following title again.
- **Title and slug both disabled**: Inputs remain readable; their values are displayed but not editable.
- **Verdict arrives after user stops editing slug**: Status message updates to reflect new verdict even after user moves focus away; aria-live region ensures announcement.
- **Very long title**: Slug input is flex-1, so it grows to fill available space; title input grows equally. Very long titles are not truncated by the component itself (handled by input or container constraints).
- **Verdict reason longer than status slot**: Reason text is displayed in full without truncation; overflow behavior is inherited from container (may wrap or scroll, depending on layout).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | string | (required) | Current title value |
| `onTitleChange` | (title: string) => void | (required) | Callback fired when user edits title |
| `slug` | string | (required) | Current slug value |
| `onSlugChange` | (slug: string) => void | (required) | Callback fired when user edits slug |
| `slugify` | (title: string) => string | (required) | Function to derive slug from title on title changes |
| `verdict` | SlugVerdict | `{ status: "idle", reason: null }` | Availability status for current slug, with optional reason text |
| `titleLabel` | string | "Title" | Label text for title input |
| `slugLabel` | string | "Slug" | Label text for slug input |
| `disabled` | boolean | false | If true, both inputs are disabled |
| `className` | string | undefined | Additional CSS class applied to container element |

## Deep Linking

Not applicable: This component is a form control, not a routable page or screen. Deep linking is the responsibility of the host application.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `titleLabel` | "Title" | Label for title input; passed as a prop, so callers can localize it |
| `slugLabel` | "Slug" | Label for slug input; passed as a prop, so callers can localize it |
| `statusText.checking` | "Checking…" | Verdict status while availability check is in progress; hardcoded in source, not exposed as a prop |
| `statusText.available` | "Available" | Verdict status when slug is available; hardcoded in source, not exposed as a prop |
| `statusText.unavailable` | "Unavailable" | Verdict status when slug is unavailable; overridden by verdict.reason if present; hardcoded in source, not exposed as a prop |

`titleLabel` and `slugLabel` are props, so callers can localize them. The three status strings are not: they live in a `STATUS_TEXT` map inside the component and are not exposed through any prop, so a caller cannot localize "Checking…", "Available", or "Unavailable" without patching the component. A caller can only work around this for the "unavailable" case by supplying a localized `verdict.reason`, which replaces the default text. The component does not load a translation table.

## Accessibility Options

- **Reduce Motion**: Not applicable: Component has no animations.
- **Increase Contrast**: Slug status message colors (success, error, muted) inherit from tone tokens, which adjust for high-contrast mode in the design system.
- **Differentiate Without Color**: Slug status is communicated by text content ("Checking…", "Available", verdict.reason) in addition to color; verdict text is sufficient to convey status without color.

## Feature Flags

Not applicable: Component is always rendered when mounted; no feature flag controls its visibility or behavior.

## Analytics

Not applicable: Component does not generate analytics events. Host application SHOULD track user edits (onTitleChange, onSlugChange) and verdict changes (verdict prop updates) as needed for application analytics.

## Privacy

Not applicable: Component handles no sensitive data. Title and slug values are application data passed by the host; component does not encrypt, persist, or transmit them.

## Logging

Not applicable: No logging is implemented in the source code.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/document-identity-field.tsx`. Exports `DocumentIdentityField` component and `useSlugAvailability` hook. Uses Field layout="inline" for label alignment and Input component for text fields. Slug availability hook manages debouncing (default 350ms) and stale verdict dismissal. Component uses Tailwind utilities (cn, toneTextClass) for styling.

- **SwiftUI**: Start from a single `Form` (or plain `VStack`) with two `LabeledContent`-style rows (a fixed-width caption beside its control) for title and slug — not two separate `Form` sections. Title field uses the default font; slug field uses `Font.system(.body, design: .monospaced)` at a smaller size. Use `@State` to track `touched` (slug manually edited). On title change, if not touched, call slugify and update slug. Render status text conditionally after the slug field based on verdict status. SwiftUI has no `.accessibilityLiveRegion` modifier; post `AccessibilityNotification.Announcement(statusText).post()` whenever the verdict's status or reason changes so VoiceOver announces it.

- **Compose**: Start from a Column with two Row elements for field layout. Use TextField for both inputs; slug field has fontFamily set to FontFamily.Monospace at a smaller fontSize. Manage touched state with remember { mutableStateOf(false) }. On title change, if not touched, call slugify. Render status text after slug input using Text with appropriate color from the tone system; announce changes with `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` on that Text — not by wrapping it in a LazyColumn, which has no bearing on accessibility announcements.

- **AppKit / UIKit**: On iOS (UIKit), use a `UIStackView` (axis: `.vertical`) containing two row `UIStackView`s (axis: `.horizontal`). Use `UILabel` for captions, `UITextField` for inputs. Title field has font `.systemFont(ofSize: UIFont.labelFontSize)`; slug field has font `.monospacedSystemFont(ofSize: 0.8 * UIFont.labelFontSize, weight: .regular)`. Track touched with a target on the slug field's `.editingChanged` control event, not a gesture recognizer (a gesture recognizer does not observe text edits). On title change, if not touched, call slugify. Render status in a `UILabel` positioned after the slug input; there is no `accessibilityLiveRegion` property on iOS, so post `UIAccessibility.post(notification: .announcement, argument: statusText)` whenever the verdict's status or reason changes. On macOS (AppKit), use an `NSStackView` (orientation: `.vertical`) containing two row `NSStackView`s (orientation: `.horizontal`), with an editable `NSTextField` for each input and a non-editable, non-bezeled `NSTextField` for captions and status; give the slug field's font `NSFont.monospacedSystemFont(ofSize: NSFont.labelFontSize * 0.8, weight: .regular)`. Track touched from the field delegate's `controlTextDidChange`, and post status changes with `NSAccessibility.post(element:, notification: .announcementRequested, userInfo: [.announcement: statusText])`.

- **WinUI 3**: Use a StackPanel (Orientation="Vertical", Spacing="12"). Render two rows, each a Grid with three columns (`auto, *, auto`) for caption, input, and status, so the status has its own column and does not collide with the input. Title input: TextBox with FontSize inherited. Slug input: TextBox with FontFamily="Consolas" (or the platform's monospace font), FontSize bound to a fraction (≈0.8×) of the title's rather than a hardcoded value. Track touched in a view-model flag set only by user-initiated edits — `TextChanged` alone is unreliable because it also fires for programmatic updates. For the status TextBlock (in the third column), set `AutomationProperties.LiveSetting="Polite"` (there is no `AccessibilityLive` property), with `Foreground` bound to a `SolidColorBrush` for the success/error/muted tokens.

## Design Decisions

**Decision**: The component uses session state (`touched`) to track whether the user has manually edited the slug; once touched, the slug follows the title no further.
**Rationale**: This lets auto-generation from title edits continue until the user takes control, preserving intentional slug customization across later title rewrites. Touched state does not persist across remount; opening a new document (a different `key`) resets the behavior, matching the use case where documents are opened and closed within a session and users expect the slug to start fresh for each one.
**Approved**: pending

**Decision**: The component receives `verdict` as a prop rather than owning the slug-checking logic itself.
**Rationale**: This lets the host manage the checker (API call), debouncing, and stale-verdict dismissal, separating concerns and enabling shared truth: the host's Save button and the field's display both read the same verdict. The `useSlugAvailability` hook is exported for convenience, but the component does not require its use; hosts may provide verdicts computed any way they choose.
**Approved**: pending

**Decision**: The status message is rendered unconditionally in the DOM (even when its text is null) as an `aria-live="polite"` region.
**Rationale**: The region must exist before its content changes, or assistive technology has nothing to have observed the mutation on; mounting it together with its first content risks the first verdict update — often "Unavailable", the one most critical to hear — going unannounced. Status text prioritizes the reason over the default status label, so implementors can provide detailed feedback without duplicating the word "Unavailable".
**Approved**: pending

**Decision**: The slug input uses a smaller, monospace font to visually distinguish it from the human-readable title.
**Rationale**: This reinforces that the slug is a technical identifier (e.g., a URL path component) and may not match the title exactly.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`passed` rests on the ARIA wiring and relative font units visible in `document-identity-field.tsx` (`aria-live`, `aria-labelledby`, `aria-describedby`, and the relative units `text-[0.8rem]`/`text-xs`); `contrast-ratio` and `touch-target-size` are `partial` because those values are inherited from the tone tokens and the `Input` component rather than verified in this file; the internationalization statuses rest on the `STATUS_TEXT` map in the same source, which externalizes `titleLabel`/`slugLabel` as props but hardcodes the status text itself. `separation-of-concerns` passes because the debounce/stale-verdict logic lives in the exported `useSlugAvailability` hook, not in the `DocumentIdentityField` component itself. `unit-test-coverage` passes because `documentIdentityField.test.tsx` imports and exercises both `DocumentIdentityField` and `useSlugAvailability` directly, including the FOLLOW-rule and stale-verdict behavior.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they are cited; corrected platform-notes API errors in SwiftUI, Compose, UIKit, AppKit, and WinUI 3; fixed test-vector inaccuracies and added vectors for className, custom labels, idle verdict, and aria-describedby; reformatted Design Decisions to the three-line convention form; corrected compliance check names and statuses and added internationalization checks; clarified the differing title/slug labelling techniques and the non-focusable status message; attributed debounce/stale-verdict/throw behavior in Edge Cases to `useSlugAvailability` rather than the component; corrected the localization claim about status-text props; expressed Appearance in platform-neutral terms with the web values as a reference implementation; added `depends-on` entries for `field` and `input`. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Logging section: replaced invented Subsystem/table with Not applicable (no logging in source). |
