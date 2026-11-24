---
id: 1794948f-2bb2-4f25-b9b5-72b1e6306ea1
title: "Inline Chat"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Scrolling message transcript with typing indicator and single-line composer for inline chat interactions."
platforms:
  - typescript
  - web
  - swift
  - macos
tags:
  - chat
  - messaging
  - transcript
depends-on:
  - 46e0a509-8eac-460a-b24a-d39a8b71b02c
  - 98e78d31-2c3a-47dc-a156-435a5732a29f
  - 7d2b41f0-63aa-47d1-94f8-19a06caedc6a
  - e5165b31-6a06-4d79-8fb8-98ba491623b1
related: []
references: []
approved-by: ""
approved-date: ""
---

# Inline Chat

## Overview

An inline chat surface that displays a transcript of committed and in-flight messages, a typing/thinking indicator, and a single-line text input with send affordance. The component sits in a fixed or resizable container, supports engagement-driven sizing (expanding on focus, collapsing when idle), and renders participants' messages on opposite sides (local user on the right, remote on the left). Web source: `packages/web/packages/chat/src/modes/InlineChat.tsx`. Apple source: `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/InlineChatView.swift`.

## Behavioral Requirements

- **render-messages**: Component MUST render an ordered list of committed messages with their full text, preserving order and vertical spacing of 12pt (Apple) or frame default (web).
- **render-drafts**: Component MUST render in-flight drafts (active message compositions) inline with committed messages using the same bubble styling.
- **align-by-participant**: Component MUST render the local participant's messages aligned to the right with a leading spacer (≥60pt on Apple); remote participants' messages aligned to the left.
- **render-thinking-indicator**: Component MUST display a thinking indicator above the input field while a remote participant has an active status, or — as a fallback when no remote participant has an explicit status — a remote participant is typing. The local user's own typing never triggers it (see the **Status prioritizes remote statuses over typing flag** design decision below).
- **render-input-field**: Component MUST display a single-line text input field with a send affordance (button or shortcut) that clears on successful submission.
- **submit-on-return**: Component MUST submit the input text when the user presses Return (web Enter, Apple ⏎).
- **trim-whitespace**: Component MUST reject submission of input containing only whitespace and newlines.
- **auto-scroll-to-bottom**: Component MUST auto-scroll the transcript to the bottom when a new message arrives, unless the user has scrolled more than 40pt away from the bottom; once the transcript is back within 40pt of the bottom, new messages resume auto-scrolling (Apple: see Platform Notes for the tracking mechanism).
- **support-sizing-behavior**: Component MUST accept a sizing configuration defining active and optional inactive height behaviors (`fixed`, `content-hugging`, `minimal`), applied immediately and retained across rebuilds.
- **animate-sizing-transitions**: When `sizing.transition` is `animated`, component MUST apply 0.2s duration sizing transitions between active and inactive states; when `none`, apply instantly.
- **track-engagement**: Component MUST track an internal engaged state: true when the input field has focus, false on Escape or a click outside the view (web `focusin`/`pointerdown`/`Escape` triad; Apple focus/click/Escape).
- **apply-engaged-sizing**: Component MUST apply `sizing.active` when engaged is true and `sizing.inactive` when false (defaulting to `active` if `inactive` is omitted, reproducing fixed sizing).
- **collapse-to-minimal**: When resolved inactive sizing is `{ mode: 'minimal' }`, component MUST collapse the transcript entirely (height 0, scroll view hidden) and display only the input row on disengage; re-expand to active size on re-engage (Apple: see Platform Notes and the **Minimal mode uses exact zero, not isHidden** design decision).
- **respect-max-width**: Component MUST constrain message bubbles to 75% of the transcript scroll view width, with a minimum of 200pt (Apple).
- **render-think-status**: Component MUST display thinking indicator text as configured via `thinkingLabels` (web) or `thinkingIndicator.configure(_:)` (Apple), or fall back to three pulsing dots if not configured.
- **render-think-glyph**: When `thinkingFrames` or `thinkingDoneGlyph` are provided, component MUST render the rotating glyph animation (think phase) and settled glyph (done phase) from those frames.
- **support-status-utterance**: Component MUST display `statusUtterance` (web) or `status.utterance` (Apple) as a transient override of the current thinking indicator text.
- **support-idle-phrase**: Component MUST display `idlePhrase` when no remote participant is active and no `statusUtterance` is set.
- **stream-while-thinking**: On platforms that expose `statusWhileStreaming` (web), component MUST keep the thinking indicator animating while a reply is streaming in, not only while awaiting the first token. On Apple, the indicator already animates for as long as a status is present, independent of a separate streaming flag.
- **fade-older**: Component SHOULD dim each older message proportionally less bright than the one below it when `fadeOlder` is true; dimming is optional if not set.
- **disable-input**: When `inputDisabled` is true, component MUST render the input field but prevent typing and submission, on both web and Apple (see Platform Notes for the underlying mechanism on each platform).
- **support-placeholder**: Component MUST display an optional placeholder string in the input field (web prop, Apple via `chrome.inputPlaceholder`).
- **support-custom-prompt**: Component MUST render an optional prompt glyph before the input (web `❯`, Apple via `chrome.promptGlyph`).
- **support-custom-send-glyph**: Component MUST support an optional custom send affordance glyph or text, falling back to the default send icon when not configured. Apple only (`chrome.sendGlyph`, falling back to the SF Symbol `arrow.up.circle.fill`); web has no equivalent.
- **render-input-divider**: Component SHOULD render a divider (1pt line) between the typing indicator row and input row when configured (Apple `chrome.showsDivider`).
- **support-backdrop**: Component MUST accept an optional backdrop view (Apple `backdrop` property) pinned to all edges, positioned below all other content, and hidden/shown without cost when `showsBackdrop` toggles.
- **start-stop-animated-backdrop**: If a backdrop conforms to `AnimatedBackdrop`, component MUST start its animation when `showsBackdrop` becomes true and stop it when false.
- **support-surface-transparency**: Component MUST apply `surfaceTransparency` (0–100) as a multiplier on the theme's surface color alpha, thinning the surface fill without affecting text or chrome (Apple).
- **support-text-scale**: Component MUST respond to ⌘+, ⌘−, and ⌘0 keyboard events (Apple only) and fire `onTextScaleNudge` callback with +1, −1, or 0 (Apple); scaling applies only to the chat's own `themeScope`, not globally.
- **text-scale-requires-enabled-input**: Text scale shortcuts MUST fire only when the input field is enabled; they do not require the input to have focus. The key equivalent is dispatched down the whole key window's view tree, so the shortcut fires from anywhere in that window as long as the composer accepts typing (input enabled).
- **render-theme-scope**: Component MUST resolve its color palette through a dedicated `themeScope` instance separate from the window's, allowing independent text-size control per chat instance.
- **render-command-activity**: Component MUST render command activity (tool invocations) as `ToolCallPillView` rows below the transcript, above the thinking indicator, in invocation order (Apple).
- **handle-send-errors**: Component SHOULD catch and handle errors from `submitMessage` without crashing or surfacing the error (Apple: silently ignored); web behavior undefined from source.

## Appearance

- **Transcript container**: Transparent background (Apple `drawsBackground = false`), vertical NSStackView with 12pt line spacing (Apple) or CSS gap default.
- **Transcript insets**: 20pt vertical, 16pt horizontal (Apple edges `NSEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)`).
- **Transcript scrollbar**: Vertical scrollbar shown (Apple `hasVerticalScroller = true`); style per platform default.
- **Message bubbles**: Bubble views use `MessageBubbleView` (Apple) or `Transcript` component (web); max width 75% of scroll container (min 200pt); aligned right for local user, left for remote.
- **Bubble spacing**: 12pt vertical gap between consecutive bubbles (Apple `transcriptStack.spacing = 12`).
- **Bubble side inset**: 16pt left and right margin outside bubble (Apple `Self.bubbleSideInset = 16`).
- **Thinking indicator**: Single row above input, inset 12pt left and right (Apple); text and animation per `ThinkingIndicatorView`.
- **Typing indicator animation**: Three pulsing dots (default) or custom glyph rotation.
- **Input row height**: Minimum 44pt touch target (Apple send button 18pt SF symbol + padding).
- **Input row insets**: 14pt vertical, 16pt horizontal (Apple `NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)`).
- **Input field**: Single-line text view with optional corner radius (Apple `chrome.inputCornerRadius`), optional 1pt border (Apple `chrome.showsInputBorder`), block or bar caret per `blinksCaret` setting.
- **Input field placeholder**: Text and color per input styling; default `placeholder` prop value.
- **Prompt glyph**: "❯" (U+276F) by default (Apple), positioned left of input with baseline-drop alignment to center glyph ink on text center; hidden if not configured (Apple `chrome.promptGlyph == nil`).
- **Prompt text color**: User text color from palette (Apple `palette.nsColor(.userText)`).
- **Send button**: Icon `arrow.up.circle.fill` (18pt regular, Apple) or custom glyph; tint per `palette.nsColor(.sendButton)`.
- **Divider**: 1pt line between typing row and input row (Apple `ThemedSeparatorView`); hidden if not configured (Apple `chrome.showsDivider`).
- **Surface fill**: Opaque background color from theme palette (Apple `palette.nsColor(.chatSurface)`), thinned by `surfaceTransparency` multiplier.
- **Backdrop**: Optional NSView behind surface, click-through, pinned to all edges.
- **Min content width**: 232pt (Apple `minContentWidth = minBubbleWidth (200) + bubbleSideInset (16) × 2`).

## States

| State | Appearance change |
|-------|------------------|
| Default (idle, not engaged) | Transcript at `sizing.inactive` height if configured (defaults to `sizing.active` height when `inactive` is omitted); input visible, no focus ring. |
| Engaged (focused, interacting) | Input field has focus ring (platform-dependent); if `inactive` sizing set, transcript expands to active height with 0.2s animation (or instant if `transition: 'none'`). |
| Thinking (remote typing/status) | Thinking indicator animates (dots or custom glyph rotation). |
| Streaming (reply incoming) | If `statusWhileStreaming`, thinking indicator continues animating while transcript updates. |
| Minimal (collapsed, inactive) | Transcript height exactly 0 and hidden; input row remains visible and enabled. |
| Input disabled | Input field renders but does not accept input or send; visual state per platform disabled appearance. |
| Backdrop shown/hidden | Backdrop view visible or hidden; if animated, animation runs or stops. |

## Accessibility

- **Role**: Chat interface / message list. Apple: NSView with `ChatStateObserver` and focus tracking; web: generic div with role deferred to children.
- **Keyboard navigation**: Tab navigates to send button; Return submits from input field; Escape disengages (Apple only).
- **Focus indicators**: Input field displays focus ring when active (platform default).
- **Labels**: Placeholder text in input field conveys purpose; send button has accessibility description (Apple "Send").
- **Screen reader**: Thinking indicator announces "Thinking" or configured status text; message bubbles read via child components (`MessageBubbleView` on Apple, `Transcript` on web).
- **Participant side**: Bubbles are visually separated by side (right = local, left = remote); no explicit role mapping.
- **Minimum tap target**: Send button 18pt (Apple SF symbol, >44×44pt); input field assumed ≥44pt height.
- **Status announcement**: Typing indicator state changes (appears/disappears, text updates) should be announced; implementation deferred to `ThinkingIndicatorView`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| inline-chat-001 | render-messages | Add 3 committed messages to session | All 3 render in order in transcript, spaced 12pt apart |
| inline-chat-002 | render-drafts | Add 1 draft with text and 1 committed message | Draft and message both render as bubbles; draft shows composing state |
| inline-chat-003 | align-by-participant | 1 local message, 1 remote message | Local on right with spacer, remote on left |
| inline-chat-004 | render-thinking-indicator | Set remote participant typing=true | Thinking indicator appears above input with animation |
| inline-chat-005 | render-input-field | Render component | Input field and send button visible, input accepts text |
| inline-chat-006 | submit-on-return | Type "hello" in input, press Return | Message sent, input cleared |
| inline-chat-007 | trim-whitespace | Type "   " (spaces/newlines), press Return | Submission rejected, input not cleared |
| inline-chat-008 | auto-scroll-to-bottom | Transcript at bottom (default state), add a new message | Transcript auto-scrolls to keep the new message visible |
| inline-chat-009 | auto-scroll-to-bottom | User scrolls 50pt away from the bottom, then a new message arrives | Transcript does not auto-scroll to the new message |
| inline-chat-010 | support-sizing-behavior | Set sizing.active to fixed(200pt), sizing.inactive to minimal | On engage, fixed applied; on disengage, minimal applied |
| inline-chat-011 | animate-sizing-transitions | Set transition to animated, disengage | Sizing change animates over 0.2s |
| inline-chat-012 | track-engagement | Click input field | engaged = true |
| inline-chat-013 | track-engagement | Click outside view | engaged = false |
| inline-chat-014 | track-engagement | Press Escape | engaged = false |
| inline-chat-015 | apply-engaged-sizing | Set inactive, disengage | Sizing transitions to inactive |
| inline-chat-016 | collapse-to-minimal | Set inactive to minimal, disengage | Transcript height collapses to 0 and is hidden |
| inline-chat-017 | respect-max-width | Set scroll width to 600pt, add long message | Bubble capped at 450pt (75% of 600) |
| inline-chat-018 | render-think-status | Set thinkingLabels to [("think", "🤔")] | Indicator displays "🤔 think" |
| inline-chat-019 | render-think-glyph | Provide thinkingFrames = [glyph1, glyph2] | Glyphs rotate in thinking indicator |
| inline-chat-020 | support-status-utterance | Set statusUtterance to "Generating..." | Indicator displays "Generating..." (overrides think text) |
| inline-chat-021 | support-idle-phrase | Set idlePhrase to "Ready", no remote activity | Indicator displays "Ready" |
| inline-chat-022 | stream-while-thinking | Set statusWhileStreaming=true, reply streaming | Thinking indicator continues animating during reply |
| inline-chat-023 | fade-older | Set fadeOlder=true, add 3 messages | Messages progressively dimmer from bottom to top |
| inline-chat-024 | disable-input | Set inputDisabled=true | Input renders but does not accept text or send |
| inline-chat-025 | support-placeholder | Set placeholder="Ask anything..." | Input displays placeholder text when empty |
| inline-chat-026 | support-custom-prompt | Set chrome.promptGlyph to "›" | Prompt displays "›" before input |
| inline-chat-027 | support-custom-send-glyph | Set chrome.sendGlyph to "✉️" | Send button displays "✉️" |
| inline-chat-028 | render-input-divider | Set chrome.showsDivider=true | 1pt line visible between thinking row and input row |
| inline-chat-029 | support-backdrop | Set backdrop to NSView | Backdrop visible behind content |
| inline-chat-030 | start-stop-animated-backdrop | Set backdrop to animated view, toggle showsBackdrop | Animation runs when shown, stops when hidden |
| inline-chat-031 | support-surface-transparency | Set surfaceTransparency=50 | Surface fill alpha = theme alpha × 0.5 |
| inline-chat-032 | support-text-scale | Press ⌘+ while input focused (Apple) | onTextScaleNudge fires with +1 |
| inline-chat-033 | text-scale-requires-enabled-input | Press ⌘+ with the input enabled but not focused, e.g. focus elsewhere in the same key window (Apple) | onTextScaleNudge fires with +1 |
| inline-chat-034 | render-theme-scope | Set chat text scale to 150%, open another chat | Only this chat is 150%; other chat unchanged |
| inline-chat-035 | render-command-activity | Add tool invocation to commandActivity | ToolCallPillView renders below transcript |

## Edge Cases

- **Empty messages list**: Component renders transcript container with no bubbles; only typing indicator and input visible.
- **Very long messages**: Bubbles respect max width (75% or 200pt floor) and wrap or truncate per `MessageBubbleView` behavior.
- **Rapid message arrivals**: Multiple messages added in a single update render in one transcript rebuild rather than one per message, auto-scrolling once to the final bottom (Apple: see Platform Notes).
- **Concurrent local and remote typing**: Thinking indicator prioritizes remote participant statuses (sorted by ID); if none has an explicit status, it falls back to whether any remote participant is typing. The local user's own typing never shows the indicator (see the **Status prioritizes remote statuses over typing flag** design decision).
- **Draft with no text**: Drafts with empty text are filtered out and not rendered (Apple: see Platform Notes for the exact filter).
- **Window resize during engagement**: A transcript width change triggers a rebuild on the next layout pass; repeated layouts at the same width do not trigger redundant rebuilds (Apple: see Platform Notes).
- **Click outside while composing**: Escape disengages immediately; a click outside the view disengages only while already engaged and only if the click lands outside the view's bounds (Apple).
- **Text scale nudge without handler**: If `onTextScaleNudge` is nil, shortcuts are passed to parent responder chain (Apple).
- **Backdrop added/removed**: Old backdrop unsubscribed from animation, constraints removed; new backdrop positioned and optionally animated.
- **Missing viewport measurements**: On Apple, a height cap computed before the view has been laid out (bounds height still zero) resolves to zero rather than a negative value; web sizing is deferred until layout.
- **Focus moving to transcript**: On Apple, focus moving into the scrollable transcript does not disengage the component — it stays engaged while the user is reading.
- **Status presence toggling**: A status changing from none to an active `ChatStatus` (or vice versa) updates only the status line, not a full transcript rebuild (performance optimization).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` / `viewModel` | ChatSession / ChatViewModel | required | Active chat session or view model binding |
| `sizing` | InlineChatSizing | `{ active: { mode: 'fixed' } }` | Size behavior active/inactive and transition. Default `fixed` height: web inherits the surrounding CSS (today `.pc-inline` at 50vh, capped at 600px); Apple floors at `>= 200pt` (`defaultTranscriptHeight`). |
| `placeholder` | string | none | Placeholder text in input field |
| `thinkingLabels` | StatusWordPair[] | dots | Custom words and icons for thinking indicator phases |
| `thinkingFrames` | string[] | none | Glyph frames for rotating thinking animation |
| `thinkingDoneGlyph` | string | none | Settled glyph shown after thinking completes |
| `thinkingColorful` | boolean | false | Rotate through random non-green colors while thinking (Apple) |
| `thinkingTint` | StatusTintSpec | none | Which elements (glyph/words/both) are tinted |
| `statusWhileStreaming` | boolean | false | Keep thinking indicator animating during reply stream |
| `idlePhrase` | string | none | Status text shown when no remote activity |
| `statusUtterance` | string \| null | none | Transient status override (takes precedence) |
| `inputDisabled` | boolean | false | Render input but block typing and sending |
| `fadeOlder` | boolean | false | Dim older messages proportionally (web only) |
| `chrome` | InlineChatChrome | defaults | Prompt glyph, send glyph, divider, caret style, border, corner radius, placeholder (Apple) |
| `blinksCaret` | boolean | true | Block caret blinks or stays solid (Apple) |
| `backdrop` | NSView | none | Optional animated or static backdrop (Apple) |
| `showsBackdrop` | boolean | true | Backdrop visibility toggle (Apple) |
| `surfaceTransparency` | number | 0 | Surface opacity reduction 0–100% (Apple) |
| `onTextScaleNudge` | (Int) → Void | none | Callback for ⌘+/−/0 text scale adjustments (Apple) |
| `localParticipantID` | string | required | Participant ID for local user to determine bubble side (Apple) |
| `viewModel.commandActivity` | [CommandActivity] | (view-model state) | Tool invocations rendered as `ToolCallPillView` rows below the transcript (Apple) |
| Bubble side (web) | — | — | Not exposed as a prop on `InlineChat`/`InlineChatView`; which side a message renders on is delegated to the `Transcript` component ([adhsdk.ingredient.chat.components.transcript](cookbook:98e78d31-2c3a-47dc-a156-435a5732a29f)), which this recipe does not define |

## Deep Linking

Not applicable: Component has no deep-linking protocol or URL routing requirements.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `inline-chat.send-button.accessibility-label` | Send | Accessibility description for the send button's SF Symbol (Apple; hardcoded in source, not currently externalized) |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not observed in source: the 0.2s sizing transition, the pulsing-dot thinking animation, and the glyph rotation all run unconditionally, regardless of the system's reduced-motion preference. |
| Increase Contrast | Not applicable: colors resolve entirely through the theme palette (`SemanticPalette`), which this component does not override. |
| Differentiate Without Color | Not applicable: local/remote participant side (right/left) is a structural layout distinction, not a color-only signal. |

## Feature Flags

Not applicable: Component is always enabled; feature flags are application-level concerns, not component-level.

## Analytics

Not applicable: Component does not emit analytics events; analytics instrumentation is delegated to the session/view-model layer and application observability stack.

## Privacy

Not applicable: Component displays user-provided message content and typing activity; no data collection, transmission, or storage is performed by the component itself.

## Logging

Not applicable: Component does not perform logging; the Swift source includes detailed comments indicating debug points (e.g., engagement triad, sizing behavior, text-scale nudges) that could be instrumented by wrapping code, and web version is similarly transparent to caller logging.

## Platform Notes

- **React/Web**: Renders via the `InlineChatView` and `InlineChat` React components. Sizing behavior managed by `useChatSizing` hook. Transcript scrolling via CSS `overflow-y: auto`. Input is a standard `<input>` or `<textarea>` with `onKeyDown` for Return. Thinking indicator uses SVG or CSS animation for the rotating glyph. `statusWhileStreaming` and `inputDisabled` are implemented directly on `InlineChatView`/`InlineChat` (see Configuration), not delegated to the application. Text-scale shortcuts (⌘+/⌘−/⌘0) are Apple-only and have no web equivalent.
- **SwiftUI**: No direct SwiftUI implementation present in source. A SwiftUI binding would wrap the AppKit `InlineChatView` via `NSViewRepresentable`, taking an `@Bindable var viewModel: any ChatViewModel` (Observation's `@Observable`, not the pre-Observation `@ObservedObject`) and a `sizing: InlineChatSizing` value, applying `sizing`/`chrome` changes to the wrapped view in `updateNSView(_:context:)`. Custom styling via SwiftUI `.modifier()`.
- **Compose**: No Compose implementation present in source. On Android, an analogous component would use `LazyColumn` for the transcript with `Message` composables, `TextField` for input, `Spacer(Modifier.weight(1f))` for bottom-align behavior. Sizing transitions via `animateContentSize()` modifier. Thinking indicator animation via `AnimatedVisibility` and `Animatable`.
- **AppKit / UIKit**: Apple source provides AppKit (`NSView`, `NSStackView`, `NSTextField`, `NSScrollView`). For iOS/UIKit, replace `NSView` → `UIView`, `NSStackView` → vertical `UIStackView`, `NSScrollView` → `UIScrollView`, `NSTextField` → `UITextField` (a single-line composer). Layout via `NSLayoutConstraint` (AppKit and UIKit both). Text-scale shortcuts are not available on iOS; implement via a pinch gesture or explicit buttons instead. Engagement tracking: replace `NSEvent.addLocalMonitor` with a `UIGestureRecognizer` (tap outside) and the responder chain (Escape via `UIKeyCommand`). Internally: `sendTapped()` clears the field and submits through `viewModel.submitMessage`; disabling the input sets `inputField.isEnabled = false`; the transcript is rebuilt in `rebuildTranscript()` on every message/draft/command-activity change, filtering out drafts `where !draft.text.isEmpty`; a `lastTranscriptWidth` comparison in `layout()` avoids redundant rebuilds; auto-scroll tracks an `isAtBottom` flag maintained by `transcriptDidScroll()` against a 40pt threshold.
- **WinUI 3**: Use `Microsoft.UI.Xaml.Controls.ListView` for transcript with `ItemsSource` binding to messages. Implement sizing transitions via `Storyboard` animation with 0.2s duration. Input via `TextBox` with `AcceptsReturn="False"` and `KeyDown` event handler for submission. Thinking indicator via custom control with `DispatcherTimer`-driven glyph animation. Message bubbles as templated `ListViewItem`s with conditional alignment via `HorizontalAlignment` (participant ID → Right/Left). Command pills as `ItemsControl` rows below transcript.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/InlineChatView.swift` | unverified |
| web | `packages/web/packages/chat/src/modes/InlineChat.tsx` | unverified |

## Design Decisions

- **One surface fill painted once**
  **Decision**: The chat surface (Apple `palette.nsColor(.chatSurface)`) is painted exactly once, at the root view level (Apple `applyTheme`), and never repeated by sub-containers.
  **Rationale**: Painting the surface once prevents stacking opacity when the surface is translucent, and ensures the `surfaceTransparency` multiplier applies to a single layer rather than compounding across nested fills.
  **Approved**: pending

- **Engagement-driven sizing is opt-in**
  **Decision**: The component defaults to fixed sizing (today's behavior: `>= 200pt` minimum height); engagement tracking and dynamic sizing activate only when `sizing.inactive` is explicitly set.
  **Rationale**: This preserves backward compatibility for call sites that do not need collapsing behavior.
  **Approved**: pending

- **Minimal mode uses exact zero, not isHidden**
  **Decision**: In minimal mode, the transcript height constraint is set to exactly 0 rather than relying on `isHidden` alone.
  **Rationale**: `isHidden` alone leaves AppKit constraints active, which would let the transcript retain its old height behind the hidden view.
  **Approved**: pending

- **Block caret blinking is separate from chrome**
  **Decision**: `blinksCaret` is a user-preference setting (per-reader), kept separate from `chrome.usesBlockCaret`, a design-system choice (per-theme).
  **Rationale**: This separation allows a theme to prefer block carets while the reader independently disables blinking.
  **Approved**: pending

- **Status prioritizes remote statuses over typing flag**
  **Decision**: When multiple participants are active, `refreshStatus()` sorts remote participants by ID and uses the first status value; when no remote participant has an explicit status, it falls back to whether any remote participant is typing. The local participant is filtered out of both checks, so the local user's own `isTyping` flag never drives the indicator.
  **Rationale**: This avoids echoing the user's own activity back at them, matching the equivalent web design pattern.
  **Approved**: pending

- **Click-outside detection uses local monitor**
  **Decision**: Apple's click-outside detection uses `NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown)` rather than a global monitor.
  **Rationale**: The component belongs to a specific window and should not disrupt the rest of the application.
  **Approved**: pending

- **Prompt baseline drop is computed, not hard-coded**
  **Decision**: The prompt glyph's baseline offset (`PromptGlyphAlignment.baselineDrop()`) is derived per font at every theme and text-scale change, rather than hard-coded.
  **Rationale**: The prompt glyph and composed text use different font families and widths, so a shared baseline does not center the ink; the constant must be recomputed whenever either font changes.
  **Approved**: pending

- **Drafts render through same bubble as messages**
  **Decision**: In-flight drafts are adapted to the `Message` protocol (`DraftMessageAdapter`) so they reuse the same `MessageBubbleView` styling as committed messages.
  **Rationale**: Reduces duplication and keeps draft appearance in sync with messages.
  **Approved**: pending

- **Auto-scroll tolerance is 40pt**
  **Decision**: The at-bottom threshold for auto-scroll is 40pt (Apple).
  **Rationale**: Allows minor scroll bounce and interaction without triggering a false "scrolled away" state, while still stopping auto-scroll once the user deliberately scrolls up to read history.
  **Approved**: pending

- **Thinking indicator is not in scrolling transcript**
  **Decision**: The status row sits between the transcript scroll view and the input row, not inside the transcript.
  **Rationale**: Keeps the status line always visible at eye level where the user is typing, even on a long conversation.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.user-safety.content-moderation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f1e3ffdc-3e47-54d5-82c8-a1c266284959) | failed | User Safety |
| [adc.check.user-safety.abuse-prevention](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b5685271-fbb7-5160-aeb5-9884034fc2d4) | failed | User Safety |
| [adc.check.user-safety.harmful-content-filtering](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0ba78b76-8359-58e4-b507-2d5a61848d33) | failed | User Safety |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on: the Apple send button's measured 18pt/>44×44pt hit area versus the input field's unmeasured ("assumed") height; the delegated, unspecified screen-reader roles and web keyboard navigation; the hardcoded "Send" accessibility string and the fixed (non-mirrored) left/right participant sides; the absence in source of Reduce Motion handling, rate limiting, or content moderation around the composer and transcript; and the whitespace-only trim as the sole input validation shown. `separation-of-concerns` is `partial`: the web `InlineChat.tsx` delegates session and sizing logic to `useChatSession`/`useChatSizing` hooks, keeping the component itself presentational, but the Apple `InlineChatView` is a single 815-line `NSView` subclass whose `refreshStatus()` embeds participant-status filtering logic directly in the view rather than a separate coordinator. `unit-test-coverage` passes because both platforms have tests: `__tests__/InlineChat.test.tsx` on the web side and `InlineChatViewTests.swift`/`InlineChatViewSizingTests.swift` on Apple.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Compliance best-practices rows added; noted Apple view mixes status logic vs web's hook split. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and merged duplicate scroll/collapse requirements; moved implementation internals (rebuildTranscript, isAtBottom, lastTranscriptWidth, etc.) to Platform Notes; corrected compliance links, check names and statuses and expanded category coverage; fixed the scroll and Default-state contradictions and the web-parity gaps in status-while-streaming/disable-input; specified whose isTyping drives the thinking indicator; reformatted Design Decisions to the Decision/Rationale/Approved template; added depends-on identifiers, Localization and Accessibility Options content, and the missing commandActivity/bubble-side/default-height configuration entries; deleted scratch arithmetic from Min content width |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web and Apple sources |
