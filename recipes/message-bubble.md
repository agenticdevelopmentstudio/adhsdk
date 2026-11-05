---
id: 46e0a509-8eac-460a-b24a-d39a8b71b02c
title: Message Bubble
domain: adhsdk://recipes/message-bubble
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A themed chat message display for a single message with text, metadata, delivery
  state, and optional rich content.
platforms:
- typescript
- web
- swift
- macos
- ios
tags:
- chat
- messaging
- ui-component
depends-on: []
related:
- adhsdk://recipes/transcript
- adhsdk://recipes/markdown-renderer
references: []
approved-by: ''
approved-date: ''
---

# Message Bubble

## Overview

A display component for a single chat message. Renders an avatar slot, the sender's name (accessibility only), message text as markdown, timestamp, delivery status, and optionally rich content, tool-call indicators, and a caller-controlled detail indicator. On Web, the bubble can also be clickable, show a selected state, and expose a connector anchor for three-pane mode. The bubble's appearance (fill, border, text color) is determined by semantic theme roles: user vs. persona. Supports streaming (composing) and failed delivery states. On platforms with theme support, repaints live on theme change.

## Behavioral Requirements

- **sender-name-accessible**: The component MUST include the sender's name in the accessibility tree, even when it is not visually displayed.
- **text-content-rendered**: The component MUST render the message's text content whenever it is non-empty.
- **timestamp-display**: When a timestamp is present, the component MUST display it in the locale's preferred hour cycle and ordering, with the hour zero-padded to two digits.
- **composing-caret**: When `deliveryStatus` is `.composing`, the component MUST append a streaming caret character (U+258B) to the text.
- **failed-state-indicator**: When `deliveryStatus` is `.failed`, the component MUST display the failure reason and apply a failure border (1pt, danger color) to the bubble.
- **failure-announced-on-web**: On Web, the component MUST place the failure reason inside a `role="alert"` container so assistive technology announces it automatically when it appears.
- **theme-by-sender-role**: The component MUST apply the appropriate semantic theme colors based on whether the sender is the local user or a persona.
- **size-to-content**: The component's bubble width MUST NOT exceed the caller-provided maximum width; text MUST wrap rather than overflow horizontally at that width, and the bubble MUST shrink to fit shorter content.
- **flat-theme-fill**: When a theme provides no fill (alpha ≤ 0.001), the component MUST render as a flat line (no background, no padding, no corner radius), even when a bubble border role is declared.
- **optional-theme-border**: When a theme declares a bubble border role with visible alpha and the bubble is neither flat nor in a failed state, the component MUST apply a 1pt border in the declared color.
- **rich-content-rendering**: The component MAY render rich content items (images, etc.) inline after the text.
- **rich-content-load-gating**: On platforms that preload rich-content images, the component MUST defer rendering the entire bubble, including its text, until every image has finished loading.
- **detail-indicator**: The component MAY display an optional detail indicator (e.g., arrow) controlled by the caller, and MUST invoke the caller-provided callback when the indicator is activated.
- **tool-call-pills**: The component MAY render an inline status pill for each tool call attached to the message (started, completed, or failed).
- **avatar-slot-rendered**: The component MUST render an avatar slot for every message, even when the sender has no avatar image, so that a transcript's left edge stays aligned.
- **connector-anchor**: On Web in three-pane mode, the component MAY render a connector anchor when the message declares a popover and its transcript index is known.
- **selected-state**: On Web, the component MAY apply a selected visual state (`.pc-message-selected`) when the caller marks the message as selected.
- **container-click-handler**: On Web, the component MAY invoke a caller-provided click handler when the bubble container is clicked or tapped.

## Appearance

- **Corner radius**: 12pt (when themed with fill; 0 when flat)
- **Padding**: 8pt vertical × 12pt horizontal (when themed with fill; 0 when flat)
- **Font**: Message text uses the theme's body font; timestamp uses caption font
- **Background**: Determined by theme (user bubble vs. persona bubble role)
- **Foreground/Text**: Determined by theme (user text vs. persona text role)
- **Border**: Optional, 1pt, declared by theme bubble border role; or 1pt danger color when failed
- **Shadow**: None.
- **Min/Max size**: Bubble width constrained to a caller-provided maximum

## States

| State | Appearance change |
|-------|------------------|
| Default | Themed background, text in theme color, no border (unless theme declares one — see **optional-theme-border**) |
| Streaming (composing) | Caret appended to text (see **composing-caret**); on macOS, opacity does not change; streaming is a transient state |
| Failed | 1pt danger border; failure reason appended below text in caption font, danger color (see **failed-state-indicator**; announced on Web via **failure-announced-on-web**) |
| Flat theme | No background fill, no padding, no corner radius; text sits flush with message container edge (see **flat-theme-fill**) |
| Selected (web only) | `.pc-message-selected` class applied; appearance determined by theme CSS (see **selected-state**) |

## Accessibility

- **Role**: Generic container (not a button or interactive control; the component itself is not focusable)
- **Label**: Sender name is provided via a visually-hidden span so screen readers announce who sent the message before reading the text
- **State announcement**: See **failure-announced-on-web** — on Web, the failure reason sits inside a `role="alert"` container and is announced automatically when it appears. On macOS and iOS, delivery-status changes (streaming, failed) are not announced through any live region or accessibility notification; the border and appended text are the only indicators there. Compose and WinUI 3 implementations SHOULD follow the Web pattern (an assertive live region) for parity.
- **Minimum tap target**: Not applicable; this component is a display-only container, not an interactive control. Optional detail indicators provided by the caller SHOULD meet platform tap-target minimums
- **Color dependence**: Sender role (user vs. persona) is distinguished by color; themes that lack sufficient contrast or declare no fill may make the distinction unavailable to color-blind users. The component itself does not provide an alternative, non-color cue (e.g., icon, position) — see **contrast-ratio** in Compliance. Web implementation uses CSS classes that themes can override; Apple implementation checks theme's declared colors and geometry

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| bubble-001 | sender-name-accessible | Message with sender name "Alice" | Sender name appears in accessibility tree (screen reader announces "Alice: ") |
| bubble-002 | text-content-rendered | Message text "Hello, world" | Text content appears in bubble |
| bubble-003 | timestamp-display | Message timestamp 2026-09-22T14:30:00 in en_US locale | Displays as "02:30 PM" (hour zero-padded to two digits) |
| bubble-004 | timestamp-display | Message timestamp 2026-09-22T09:05:00 in en_US locale | Displays as "09:05 AM" (hour zero-padded to two digits) |
| bubble-005 | composing-caret | Message with deliveryStatus .composing | Caret U+258B appended to text |
| bubble-006 | failed-state-indicator | Message with deliveryStatus .failed("Network error") | 1pt danger border on bubble; failure reason appears below text in caption font |
| bubble-007 | theme-by-sender-role | Message from local user | Bubble uses userBubble theme role; text uses userText role |
| bubble-008 | theme-by-sender-role | Message from persona | Bubble uses personaBubble theme role; text uses personaText role |
| bubble-009 | size-to-content | Long message text that wraps at maxWidth 300pt | Bubble width is ≤ 300pt; text wraps without horizontal overflow |
| bubble-010 | flat-theme-fill | Theme with personaBubble.alpha ≤ 0.001 | No background fill, no padding, no corner radius |
| bubble-011 | optional-theme-border | Theme declares personaBubbleBorder with alpha > 0.001; bubble not flat, not failed | 1pt border in declared color appears on bubble |
| bubble-012 | optional-theme-border | Theme does not declare a bubble border role | No border is applied |
| bubble-013 | rich-content-rendering | Message with content array [image1, image2], all images loaded | Rich content items appear after text |
| bubble-014 | rich-content-rendering | Message with empty content array | No rich content rendered |
| bubble-015 | detail-indicator | showDetailArrow=true, onDetailArrowClick provided | Detail-indicator button renders with aria-label "Show details"; activating it calls onDetailArrowClick |
| bubble-016 | rich-content-load-gating | Message with content array containing an image still loading | Bubble does not render (no output) until all images finish loading |
| bubble-017 | tool-call-pills | Message with one tool call, status "started" | A pill reading "Calling {name}…" renders inline before the text |
| bubble-018 | avatar-slot-rendered | Message from a sender with no avatar | An empty, aria-hidden avatar element still renders in the gutter |
| bubble-019 | connector-anchor | Message with a popover set and an index provided (web, three-pane mode) | A connector anchor element renders after the bubble |
| bubble-020 | selected-state | isSelected=true (web) | `.pc-message-selected` class is applied to the message container |
| bubble-021 | container-click-handler | onClick provided (web), container clicked | The caller-provided onClick handler is invoked |
| bubble-022 | text-content-rendered | Message with empty text "" | Sender name, timestamp, avatar slot, and any rich content/failure reason still render; no visible text |
| bubble-023 | timestamp-display | Message with timestamp = nil | Timestamp line is omitted; other content still renders |
| bubble-024 | flat-theme-fill, optional-theme-border | Theme with alpha ≤ 0.001 fill but a declared bubble border role | No border renders; flat-theme-fill's suppression takes precedence over optional-theme-border |
| bubble-025 | failed-state-indicator, flat-theme-fill | Theme with alpha ≤ 0.001 fill and deliveryStatus .failed | Failure border still renders even though the theme is flat; padding and corner radius remain zero |
| bubble-026 | composing-caret, failed-state-indicator | Message re-rendered with deliveryStatus changing from .composing to .failed | Caret is no longer present; failure border and reason appear instead |
| bubble-027 | failure-announced-on-web | Web: message with deliveryStatus .failed("Network error") | Failure reason renders inside `role="alert"`; screen reader announces it when it appears |
| bubble-028 | failed-state-indicator, optional-theme-border | Theme declares a bubble border role and deliveryStatus is .failed | Border renders in the danger color; the declared border role is not applied while failed |

## Edge Cases

- **Empty text**: Message with empty or nil text still renders the sender name, timestamp, avatar slot, and any rich content or failure reason (see **text-content-rendered**, vector bubble-022).
- **Missing timestamp**: Message with nil timestamp omits the timestamp line; bubble still renders text and other content (see **timestamp-display**, vector bubble-023).
- **Long text**: Text that exceeds maxWidth wraps and the bubble expands vertically; measurement ensures the bubble is never wider than maxWidth (see **size-to-content**).
- **Very short text**: Single character or emoji text renders at the bubble's own measured size — no separate minimum width is enforced; padding is applied normally when the theme is not flat.
- **Theme change during rendering**: On platforms with live theme repainting (Apple), the bubble repaints synchronously; caller is responsible for triggering repaints when theme changes.
- **Flat theme transition**: When a theme's fill alpha transitions from > 0.001 to ≤ 0.001 (or vice versa), padding and corner radius update; no animation.
- **Multiple delivery statuses**: The component handles one status per render; if a message transitions from composing to failed, it must be re-rendered with the new status (see vector bubble-026).
- **Rich content load delay**: See **rich-content-load-gating** — the Web implementation renders nothing until every image in the content array has finished loading; callers must handle the interval where the component is not yet mounted.
- **Avatar/sender mark**: See **avatar-slot-rendered** — the avatar div is always rendered but may be empty when the sender has no avatar; themes can style the empty case with `.pc-avatar:empty`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `maxWidth` | number (pt/px) | required, caller-provided | Maximum bubble width; content wraps and the bubble sizes down to fit within it (see **size-to-content**) |
| `showDetailArrow` | boolean | `false` | Whether to render the optional detail-indicator button (see **detail-indicator**) |
| `onDetailArrowClick` | callback | none | Invoked when the caller activates the detail-indicator button |
| `isSelected` | boolean (web only) | `false` | Applies the `.pc-message-selected` visual state (see **selected-state**) |
| `onClick` | callback (web only) | none | Invoked when the message container is clicked or tapped (see **container-click-handler**) |
| `index` | number (web only) | none | Message's position in the transcript; required to render a connector anchor when `message.popover` is set (see **connector-anchor**) |

## Deep Linking

Not applicable: Message bubbles are display elements within a conversation view, not standalone deep-linkable destinations.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `message_bubble.detail_button.label` | "Show details" | Aria label for the optional detail-indicator button (Web); currently hardcoded in `MessageBubble.tsx` rather than sourced from a resource file — see **no-hardcoded-strings** in Compliance |
| `message_bubble.failure.reason` | — (caller-provided) | Failure reason text comes from `deliveryStatus.failed(reason)`; the component renders it verbatim and does not localize it — the caller is responsible for localizing the reason before passing it in |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Streaming caret and state transitions are not animated; no change needed |
| Increase Contrast | Component respects theme colors; themes that support high-contrast modes will render at increased contrast automatically. Caller is responsible for ensuring theme provides sufficient contrast |
| Differentiate Without Color | Component uses color to distinguish user vs. persona; themes that support this mode must provide additional visual cues (position, icon, typography). Component does not enforce this |

## Feature Flags

Not applicable: This component has no feature flags.

## Analytics

Not applicable: Component is display-only with no user interaction. Optional interactive elements (detail arrow, container click) are left to the caller to track.

## Privacy

Not applicable: Component renders data provided by caller; it does not collect, transmit, or store any data.

## Logging

Not applicable: This component performs no logging.

## Platform Notes

- **Web** (React/TypeScript): `MessageBubble.tsx` uses semantic HTML (`div`, `button`, `span`) with CSS classes for styling. Avatar and visually-hidden sender name are wrapped separately (**avatar-slot-rendered**, **sender-name-accessible**). Tool call pills are rendered inline (**tool-call-pills**). Detail arrow is a button with `aria-label` (**detail-indicator**). Timestamp is inline in caption font (**timestamp-display**). Failure reason is in a `div role="alert"` (**failure-announced-on-web**). Rich content rendering is gated on `useAllImagesLoaded` (**rich-content-load-gating**); connector anchors are conditionally rendered when a popover and index are present (**connector-anchor**). The container's `onClick` and `isSelected` props back **container-click-handler** and **selected-state**. All styling deferred to CSS in `base.css` and theme files.

- **SwiftUI**: Build from a `VStack`/`ZStack` container sized via `.frame(maxWidth:)`. Conform to the `Themeable` protocol and observe palette changes with a `ThemePaletteObserver`, mirroring the AppKit/UIKit sources' `applyTheme(_:)` pattern rather than an `@Themeable` attribute (SwiftUI has no such attribute). Measure text with SwiftUI's own text layout, or size an `NSAttributedString`/`AttributedString` via `boundingRect` the way the Apple sources do. Support `.composing` and `.failed` delivery statuses by appending to the rendered text, matching `MessageBubbleView.applyTheme`. Render the sender name via `.accessibilityLabel` or `.accessibilityElement(children: .combine)` so it reaches the accessibility tree without a visible label. Support flat themes by conditionally zeroing padding and corner radius when the theme's fill alpha is ≤ 0.001, as `MessageBubbleView.isFlat` does.

- **Compose** (Android/Kotlin): Build from a `Surface` or `Card` composable for the bubble container. Map the semantic `userBubble` / `personaBubble` / `userText` / `personaText` theme roles explicitly onto Compose color values via a custom `CompositionLocal` holding the semantic palette, rather than Material Design 3's own color-role slots — bubble theming stays governed by **theme-by-sender-role**, not Material's user/persona-agnostic palette. Support streaming and failed states by appending to the composed text, matching the Apple sources. Measure text with `TextMeasurer`. Render the sender name in a `Modifier.semantics { contentDescription = ... }` block for accessibility. Observe palette changes via that same custom `CompositionLocal` (not `LocalCompositionLocals`, which is not a real Compose API). Support flat themes by conditionally omitting the `Surface` background, padding, and corner radius when the theme's fill alpha is ≤ 0.001.

- **AppKit / UIKit** (macOS/iOS): Source `MessageBubbleView` (macOS) and `MobileMessageBubbleView` (iOS) use `NSView` / `UIView` with theme observer pattern. Both measure text at `applyTheme` time and apply measurement as layout constraint constants. macOS uses `NSTextView` for selectable text; iOS uses `UILabel`. Timestamp on macOS spans a new line, right-aligned for the local user and left-aligned for a persona, using a locale-derived pattern widened to a two-digit hour (see Design Decisions); iOS inlines it with a two-space separator and a hard-coded `HH:mm` format — a 24-hour clock that ignores the locale, so iOS does not currently conform to **timestamp-display** and should adopt macOS's locale-derived approach. Both use `NSAttributedString` to build themed text with the markdown renderer. Streaming caret and failure reason are appended to the attributed string. Failure border is 1pt on `layer`, applied even on a flat theme (see vector bubble-025). Flat themes are detected by checking the theme's fill alpha; padding and corner radius are zeroed when flat (macOS only — see **flat-theme-fill**).

- **WinUI 3** (Windows): Start from a `StackPanel` (vertical) or nested grid for layout. Use WinUI's `TextBlock` for the sender name, kept out of the visual layout (e.g., zero size or clipped to 1×1) rather than `Visibility="Collapsed"` — a collapsed element is removed from the UI Automation tree entirely, which would break **sender-name-accessible** — and set `AutomationProperties.Name` on the bubble's root container so the name still reaches assistive technology. Use `RichTextBlock` or `TextBlock` for message text (wrap enabled). Add a `TextBlock` for timestamp below text. For failed state, add a `Border` element around the bubble with `BorderBrush` bound to a danger color theme resource; append a `TextBlock` for the failure reason. For streaming state, append the caret character to the text. Apply `CornerRadius` to the bubble container (StackPanel or Grid wrapped in a Border). Support theme changes by binding `Background`, `Foreground`, and `BorderBrush` to theme resource dictionaries; update bindings when theme changes. Measure text width via `TextBlock.Measure(availableSize)` and read `DesiredSize` after the layout pass, rather than an undefined `TextRenderingCore` API.

## Design Decisions

**Decision**: The streaming caret uses the block character U+258B (▋), appended directly into the same attributed/text string as the message rather than as a separate animated element.
**Rationale**: A static, easily measured character fits inline with the text and gives visual feedback that a message is still composing without requiring animated state changes; because it is part of the same string, the measurement pass automatically includes it, so the caret can never overhang the bubble.
**Approved**: pending

**Decision**: Timestamps use one locale-aware rule everywhere: derive the pattern from the locale's own hour-cycle template (`toLocaleTimeString` on Web; `DateFormatter.dateFormat(fromTemplate: "jmm", ...)` on macOS) and widen a single-digit hour field to two digits, leaving the separator, ordering, and AM/PM marker as the locale wrote them.
**Rationale**: The locale, not the implementation, decides the hour cycle and ordering; the two-digit hour width is the one fixed constraint Web and macOS already share. iOS's current hard-coded `"HH:mm"` format does not follow this rule — it forces a 24-hour clock on every reader regardless of locale — and is a known non-conformance to bring in line with macOS's approach, not a second valid behavior.
**Approved**: pending

**Decision**: The failure reason is rendered as appended text (below the message, in caption font and danger color) rather than as a separate element or icon.
**Rationale**: Provides context — what went wrong — beyond the visual border cue; the reason itself is always caller-provided via `deliveryStatus.failed(reason)`, so the component never invents wording.
**Approved**: pending

**Decision**: A theme that declares no bubble fill (alpha ≤ 0.001) is treated as "no bubble": padding and corner radius are zeroed and the message renders as a flat transcript line.
**Rationale**: Avoids invisible boxes in themes like `terminal` or `crt-monitor` that deliberately omit bubble styling; the geometry (padding, radius) is treated as part of the bubble, so a theme opting out of fill also opts out of the geometry built around it.
**Approved**: pending

**Decision**: The avatar slot is always rendered, even when the sender has no avatar image, and the sender's name is rendered only into the accessibility tree via a visually-hidden element.
**Rationale**: Keeps the left-edge gutter aligned across every message in a transcript that mixes senders with and without avatars; a conditionally-rendered avatar div would shift the text column depending on the sender. Hiding the sender name visually (rather than omitting it) still exposes it to screen readers without introducing a visible name into themes that were drawn without one.
**Approved**: pending

**Decision**: When rich content includes images, the Web implementation withholds the entire bubble render — including the message text — until every image has finished loading.
**Rationale**: Matches how `useAllImagesLoaded` gates the component today and keeps image layout from reflowing the bubble after first paint. This is the required behavior (see **rich-content-load-gating**), not an incidental gap; callers must be prepared for the component to render nothing while content is loading, including the case where it unmounts before loading completes.
**Approved**: pending

**Decision**: The optional bubble border is applied only when a theme explicitly *declares* a border role (`palette.declares(borderRole)`), not merely when resolving that role produces a visible color.
**Rationale**: Every role resolves to *some* color when a theme omits it, so checking the resolved color alone would draw a hairline border around every bubble in every theme; checking declaration instead limits the border to themes (`charcoal`, `techy`, `fishlamp`, `mikefullerton`) that opted in.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [locale-aware-formatting](agenticdevelopercookbook://compliance/internationalization#locale-aware-formatting) | partial | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on: the Web source's `role="alert"` failure container, `aria-label` detail button, and `aria-hidden` avatar (screen-reader-support, semantic-markup, keyboard-navigable — the only interactive elements, the detail button and container click, are native/keyboard-operable); theme-supplied colors that the source cannot verify for contrast or Dynamic Type scaling, and the component's own lack of a non-color sender cue (contrast-ratio, dynamic-type-support); the detail-arrow button's size being deferred to CSS with no explicit minimum in source (touch-target-size); macOS's locale-derived timestamp pattern versus iOS's hard-coded 24-hour format (locale-aware-formatting); the component rendering arbitrary caller-provided Unicode text (including emoji) without special-casing (unicode-support); the "Show details" aria-label being written directly in `MessageBubble.tsx` rather than sourced from a resource key (string-externalization, no-hardcoded-strings); and macOS's timestamp alignment being hardcoded to `.right`/`.left` rather than a logical leading/trailing direction (rtl-layout-support); web delegates image-load state and content rendering to `useAllImagesLoaded`/`RichContent`, but both native views build the full attributed string — including delivery-status text and locale-aware time formatting — directly inline in `applyTheme` rather than a separate formatter (separation-of-concerns: partial), while `MessageBubble.test.tsx`, `MessageBubbleViewTests.swift`, and `MobileMessageBubbleViewTests.swift` each meaningfully exercise this component's theme, markdown, failure, and timestamp behavior (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web, macOS, and iOS sources |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; added requirements and vectors for tool-call pills, avatar slot, connector anchor, selected state, container click, and rich-content load gating; fixed the timestamp zero-padding contradiction and marked iOS non-conforming; corrected unsupported WinUI 3/Compose API citations and the sender-name automation bug; resolved the Web/Apple failure-announcement contradiction; reformatted Design Decisions and localization keys; replaced the Compliance and Configuration placeholders with real tables; added related cross-references |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
