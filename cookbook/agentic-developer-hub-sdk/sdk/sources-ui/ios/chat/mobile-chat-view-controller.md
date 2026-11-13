---
id: f6d46f16-65a6-4d19-80c7-1fc8b4d323fd
title: "Mobile Chat"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
summary: "Full-screen chat surface with scrolling transcript, thinking indicator, and single-line composer for mobile devices."
platforms:
  - typescript
  - web
  - swift
  - ios
tags:
  - chat
  - messaging
  - mobile
depends-on:
  - 98e78d31-2c3a-47dc-a156-435a5732a29f
  - 0ae70642-28e7-436a-b934-0b445652ac09
  - 46e0a509-8eac-460a-b24a-d39a8b71b02c
  - 7d2b41f0-63aa-47d1-94f8-19a06caedc6a
related:
  - 1794948f-2bb2-4f25-b9b5-72b1e6306ea1
references: []
copyright: 2026 Mike Fullerton
license: MIT
approved-by: ""
approved-date: ""
---

# Mobile Chat

## Overview

Mobile Chat is a full-screen chat surface that displays a scrolling transcript of committed and in-progress messages, a persistent status line for remote typing and thinking states, and a single-line composer for user input. It presents to the user as an overlay (web) or replaces the host view (iOS) and can be opened and closed with optional animations. The component is designed for phone-sized screens where the chat surface occupies the entire available space and keyboard presentation is critical.

## Behavioral Requirements

- **render-transcript**: Component MUST render all messages from the chat session's message array in a scrolling transcript, ordered chronologically from oldest to newest.
- **render-active-drafts**: Component MUST render non-empty active drafts from the session's `activeDrafts` array inline within the transcript, styled identically to committed messages.
- **align-messages-by-sender**: Component MUST align messages from the local participant to the right side of the screen and messages from remote participants to the left side.
- **auto-scroll-on-new-content**: Component MUST scroll the transcript to the bottom when new messages or drafts arrive, provided the user's scroll position is less than 40pt from the bottom at the moment of arrival; a scroll position at or beyond that 40pt threshold suppresses auto-scroll so the user can keep reading history.
- **focus-input-on-open**: Component MUST focus the text input field after ~350ms once the component becomes visible on screen, to trigger the native keyboard presentation.
- **display-thinking-indicator**: Component MUST display a status line above the composer showing the current status of all remote participants; when no remote status exists but typing indicators are present, the component MUST display a default thinking animation (three pulsing dots).
- **validate-message-before-send**: Component MUST reject (not send) any message input that contains only whitespace or is empty.
- **clear-input-after-send**: Component MUST clear the text input field immediately after the user successfully sends a message.
- **send-on-return-key**: Component MUST submit the current input message when the user presses the Return key while focused on the text input.
- **send-on-button-tap**: Component MUST submit the current input message when the user taps the send button.
- **theme-color-reapplication**: Component MUST reflect the active theme's chat surface and divider colors, reapplying them whenever the theme changes while the surface is visible — not only once, at the moment it opens.
- **support-close-button**: Component MUST provide a close affordance that triggers the `onClose` callback when activated. Web renders this as a button in the surface's own header; iOS delegates the affordance to the presenting host, which calls `close(animated:)` (see Platform Notes).
- **custom-close-label**: Component SHOULD allow the host to customize the text label of the close affordance via a `closeLabel` prop (default: "← back"). This applies where the component owns the affordance — web's header button; iOS has no equivalent affordance in this source.

## Appearance

- **Corner radius**: None; full-screen on iOS, overlay on web with system-defined styling.
- **Padding**: Transcript stack: 20pt top/bottom, 16pt left/right. Input row: 14pt top/bottom, 16pt left/right. Status row: 16pt left/right.
- **Font**: Input field placeholder: system default (UITextField default). Message bubbles: delegated to `MobileMessageBubbleView`.
- **Background**: Chat surface: `chatSurface` semantic color token. Status row: transparent (inherits surface). Divider: `border` semantic color token.
- **Foreground/Text**: Input field text and placeholder: system default. Send button: system image "arrow.up.circle.fill" (tinted).
- **Border**: Divider between status row and input row: 1pt solid border color.
- **Shadow**: None; surfaces are flat.
- **Min/Max size**: Transcript stack width: equal to the transcript container width (iOS: `UIScrollView` bounds width; web: the overlay's `.persona-chat` container width). Max bubble width: 75% of that container width, or 200pt (iOS) / 200px (web) minimum, whichever is larger.

## States

| State | Appearance change |
|-------|------------------|
| Default | Surface visible with all content rendered; input field ready for typing. |
| Open (animated) | iOS: surface `view.alpha` animates 0 → 1 over 0.25s. Web: `.pc-mobile-overlay` slides in, `transform: translateX(100%)` → `translateX(0)`, over 0.3s. |
| Closed (animated) | iOS: surface `view.alpha` animates 1 → 0 over 0.25s. Web: the overlay slides back out via the reverse transform transition. |
| Input focused | Native keyboard is presented (platform-specific). |
| Thinking/typing remote | Status line shows remote participant's current status or default pulsing indicator. |
| Message composing | Active draft appears in transcript with `.composing` delivery status. |

## Accessibility

- **Role/trait**: Main container is a view controller (iOS) or div with role `region` (web). Input field is a text field / input[type="text"]. Send button is a button. Close affordance is a button (web's `pc-mobile-close` header button); on iOS the presenting host supplies equivalent chrome (see Platform Notes).
- **Label requirements**: Input field MUST have a visual or programmatic label or placeholder indicating it accepts message text (placeholder "Type a message..." suffices). The close affordance's accessible label MUST describe the action in words (e.g., "Back" or "Close chat") and MUST NOT rely on the "←" glyph alone, since screen readers can read the raw arrow character literally; where the visible text is the default "← back", the accessible name given to assistive technology MUST differ from that literal string. Send button MUST have a label describing its action (e.g., "send").
- **Announce state changes**: Status line updates (typing, thinking) SHOULD be announced to screen readers. Message arrival SHOULD trigger an announcement if the transcript is off-screen.
- **Minimum tap target**: All buttons (close, send) MUST have a touch target of at least 44×44pt on iOS per Apple HIG.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mobile-chat-001 | render-transcript | Session with 5 messages | All 5 messages appear in transcript in chronological order. |
| mobile-chat-002 | render-active-drafts | Session with 1 draft with text="hello" | Draft appears in transcript styled identically to committed messages. |
| mobile-chat-003 | render-active-drafts | Session with 1 draft with text="" (empty) | Draft is not rendered. |
| mobile-chat-004 | align-messages-by-sender | Message from localParticipantID | Message bubble aligns to right with spacer on left. |
| mobile-chat-005 | align-messages-by-sender | Message from remote participant | Message bubble aligns to left. |
| mobile-chat-006 | auto-scroll-on-new-content | Transcript at bottom; new message arrives | Scroll automatically moves to bottom to show new message. |
| mobile-chat-007 | auto-scroll-on-new-content | Transcript scrolled up so distance from bottom is 39pt; new message arrives | Scroll auto-scrolls to bottom (39pt is within the 40pt threshold). |
| mobile-chat-008 | auto-scroll-on-new-content | Transcript scrolled up so distance from bottom is 41pt; new message arrives | Scroll remains where the user positioned it (41pt is beyond the 40pt threshold). |
| mobile-chat-009 | focus-input-on-open | Surface becomes visible | Input field receives focus after ~350ms; native keyboard is presented (tappable). |
| mobile-chat-010 | display-thinking-indicator | Remote participant has active status (not nil) | Status line shows the remote participant's status text/animation. |
| mobile-chat-011 | display-thinking-indicator | No remote status; typing indicators exist | Status line shows default pulsing dots. |
| mobile-chat-012 | display-thinking-indicator | No remote status; no typing indicators | Status line is hidden or shows nothing. |
| mobile-chat-013 | validate-message-before-send | User enters "   " (whitespace only); taps send | Message is not sent; input field is not cleared. |
| mobile-chat-014 | validate-message-before-send | User enters "" (empty); taps send | Message is not sent. |
| mobile-chat-015 | validate-message-before-send | User enters "hello"; taps send | Message is sent and input field is cleared. |
| mobile-chat-016 | clear-input-after-send | Input field has text "hello"; user sends | Input field text becomes empty. |
| mobile-chat-017 | send-on-return-key | Input field focused with text "hello"; user presses Return | Message is sent; input field is cleared. |
| mobile-chat-018 | validate-message-before-send, send-on-return-key | Input field focused with text "   " (whitespace only); user presses Return | Message is not sent; input field retains its text. |
| mobile-chat-019 | send-on-button-tap | Input field has text "hello"; user taps send button | Message is sent; input field is cleared. |
| mobile-chat-020 | support-close-button | User activates the close affordance | `onClose` callback is invoked (web); on iOS, the host calls `close(animated:)`. |
| mobile-chat-021 | custom-close-label | closeLabel prop set to "dismiss" (web) | Close button displays "dismiss" text. |
| mobile-chat-022 | theme-color-reapplication | Surface open; active theme changes | Chat surface background and divider colors update immediately, without requiring the surface to close and reopen. |
| mobile-chat-023 | send-on-button-tap | User taps send with "first", then immediately taps send again with "second" | Both messages are submitted independently; the second send does not wait for the first, and no debouncing occurs. |
| mobile-chat-024 | render-transcript | Scroll view width changes (rotation/resize) while scrolled away from the bottom | Transcript rebuilds with a recalculated max bubble width; scroll position is preserved since the surface was not at the bottom. |

## Edge Cases

- **Empty message array**: When the session has no messages and no active drafts, the transcript is empty but renders without error. The status line still shows thinking/typing indicators if remote participants have them.
- **Null or missing localParticipantID**: If `localParticipantID` does not match any message sender, all messages align to the left (treated as remote).
- **Concurrent message and status updates**: If a message arrives simultaneously with a typing status change, both the transcript rebuild and status refresh occur without visual flicker or dropped updates.
- **Keyboard interruption (iOS)**: If the input field loses focus (for example, the host dismisses the keyboard, or the user taps outside the field), the field itself remains mounted; tapping it re-presents the keyboard. This source does not configure `UIScrollView.keyboardDismissMode`, so no swipe-to-dismiss gesture is enabled by default.
- **Scrolling while new messages arrive**: Auto-scroll is suppressed once the distance from the bottom reaches or exceeds the 40pt threshold (see **auto-scroll-on-new-content**); scroll direction or velocity does not affect the check, only the distance at the moment a new message arrives.
- **Very long messages**: Message bubble width is capped at 75% of the transcript container width, or 200pt (iOS) / 200px (web) minimum, whichever is larger. Text wrapping is delegated to the bubble view.
- **Rapid-fire message sends**: If the user sends multiple messages in quick succession, each message is submitted independently; no debouncing occurs.
- **Theme change while open**: Surface responds to theme changes and reapplies colors immediately (see **theme-color-reapplication**).
- **Screen rotation (iOS) or window resize (web)**: Transcript is rebuilt to recalculate max bubble width; scroll position is preserved if scroll is not at bottom; otherwise scrolls to bottom with new messages.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` / `viewModel` | ChatSession / any ChatViewModel | required | Backing chat session (web) or view model (iOS) providing messages, active drafts, and status. |
| `localParticipantID` | string | required | (iOS only, constructor parameter) Participant ID used to align bubbles left/right, since `ChatViewModel` itself has no notion of "me". Web derives local/remote through the session `useChatSession` builds from `backend`/`persona`/`user`. |
| `backend` | ChatBackend | required | (web only, `MobileChat` wrapper) Backend passed to `useChatSession` to construct the session. |
| `persona` | ChatParticipant | required | (web only) The remote persona participant. |
| `user` | ChatParticipant | undefined | (web only) The local user participant. |
| `welcomeMessage` | string | undefined | (web only) Optional greeting message seeded into the session. |
| `open` | boolean | required | (web only) Controls surface visibility; the web component is fully prop-controlled. iOS instead exposes `open(animated:)`/`close(animated:)` methods (see Platform Notes). |
| `onClose` | () => void | required | (web only) Invoked when the close button is tapped. iOS has no close button or callback in this source (see Platform Notes). |
| `closeLabel` | string | `"← back"` | (web only) Text of the close button. iOS has no equivalent in this source. |

## Deep Linking

Not applicable: Mobile Chat displays active chat state from the session passed to it; it does not handle URL navigation or resolve deep links on its own. Navigation to open the chat is the host's responsibility.

## Localization

Mobile Chat has two user-facing strings, both currently hardcoded rather than externalized: the input placeholder ("Type a message...", both web and iOS) and the close affordance's default label ("← back", web only). The `closeLabel` prop already lets a web host override that string per locale; the placeholder is not exposed as a prop on either platform today, so it SHOULD be added as an overridable/localizable parameter — mirroring `closeLabel` — rather than staying hardcoded in source. Thinking-indicator text is already externalized: it comes from the host-authored `ChatStatusWordPair` configured on `thinkingIndicator`, not from this component's own strings.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | iOS's 0.25s `view.alpha` fade (`open(animated:)`/`close(animated:)`) and web's 0.3s slide transition (`.pc-mobile-overlay` transform) both run unconditionally in this source — neither checks `UIAccessibility.isReduceMotionEnabled` (iOS) nor the `prefers-reduced-motion` media query (web). Implementations MUST check the platform's reduced-motion signal and make the transition instant when it is enabled. |
| Increase Contrast | Divider and surface colors are determined by the semantic palette; implementations MUST ensure the `border` and `chatSurface` tokens meet WCAG AA contrast requirements when Increase Contrast is enabled. |
| Differentiate Without Color | Message alignment (left/right) is the primary distinction between local and remote messages; color MUST NOT be the only differentiator. |

## Feature Flags

Not applicable: Mobile Chat does not check feature flags or have internal toggles; feature control is managed by the host's feature flag system, which decides whether to render the component at all.

## Analytics

Not applicable: this source does not call any analytics or telemetry API. Neither `MobileChatViewController` nor `MobileChatView`/`MobileChat` contains an event-tracking call. A host that wants analytics for this surface would add its own instrumentation around `open(animated:)`/`close(animated:)`, `sendTapped()`/`submitMessage()`, and the close action.

## Privacy

- **Data collected**: Messages and drafts are collected from the session's `ChatViewModel`; the component does not collect user input beyond what the session provides. Send failures are caught but not logged.
- **Storage**: All message and draft data is stored in the session's memory; the component maintains no local persistence.
- **Transmission**: Message submission is delegated to the view model's `submitMessage()` method; the component does not directly transmit data.
- **Retention**: Messages are retained for the lifetime of the session; closing the component does not clear the session history.

## Logging

Not applicable: this source does not call any logging API. No `Logger`/`os.log` usage appears in `MobileChatViewController`, and the web source performs no console or telemetry logging either. Send failures are caught (see Privacy) but not logged anywhere in this source.

## Platform Notes

- **Web (React)**: Source files `packages/web/packages/chat/src/modes/MobileChat.tsx` define two components: `MobileChat` (wrapper, manages session) and `MobileChatView` (presentation, uses `Transcript` and `ChatInput` subcomponents). The overlay div uses classname `pc-mobile-overlay` with `open` class when visible; `css/modes/mobile.css` slides it in via `transform: translateX(100%)` → `translateX(0)` over 0.3s, rather than a fade. Input is focused via `useRef` after a 350ms `setTimeout` to trigger the iOS keyboard. The component is prop-controlled (`open` boolean, `onClose` callback) and renders its own header with a `pc-mobile-close` button showing `closeLabel`.
- **SwiftUI**: Not implemented in source. A native SwiftUI implementation would use `ScrollViewReader` with a `LazyVStack` for the transcript — scrolling to the last message's id when the tracked offset is within the 40pt threshold — a `TextField` bound to the composer text with `.onSubmit` wired to the same send action as the Return-key and button paths, and the existing `MobileThinkingIndicatorView`/`ChatStatusWordPair` vocabulary surfaced through a small SwiftUI wrapper around just that indicator, not the whole controller.
- **Compose**: Not implemented in source. An Android implementation would mirror the iOS structure using Compose-native APIs: a `LazyColumn` for the transcript with a bubble composable per item (scrolling via `LazyListState.animateScrollToItem` when within the 40dp threshold), a status row hosting a thinking-indicator composable, a 1dp `Divider`, and a `TextField` for the composer with its trailing icon acting as the send button. The status line would be updated via `ChatViewModel.statuses`, with `typingParticipants` as a fallback.
- **AppKit / UIKit**: Source file `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/iOS/Chat/MobileChatViewController.swift` defines `MobileChatViewController: UIViewController`. Its view lays out four constrained subviews: a `UIScrollView` (transcript) containing a `UIStackView` (bubble stack), a `UIView` status row containing `MobileThinkingIndicatorView`, a 1pt `UIView` divider, and a `UIStackView` input row with `UITextField` and `UIButton`. Message bubbles are left-aligned; local user messages get a leading spacer to right-align. `open(animated:)`/`close(animated:)` fade `view.alpha` over 0.25s and track a private `isOpen` flag so tests or a host can assert presentation state without depending on the containing navigation/presentation context. `applyTheme(_:)` sets the `chatSurface`/`border` colors on the controller's own view, the status row, and the divider — never inside a child view, so a translucent theme's surface color is never doubled into a lighter band — and it re-runs on every `ThemePaletteObserver` callback, not only when the surface opens. This source has no header or close button of its own: `onClose`/`closeLabel` are a web-only surface, and a UIKit host supplies its own dismissal chrome (e.g., a navigation back button) and calls `close(animated:)` directly. It likewise has no explicit `becomeFirstResponder()` call; focus-after-open (~350ms once visible) is implemented in the web source via `useEffect`/`setTimeout`, and a UIKit host presenting this controller is expected to trigger focus on the same timing. The controller observes `ChatViewModel` and rebuilds the transcript (recalculating max bubble width) on `.messagesChanged`, `.activeDraftsChanged`, `.typingChanged`, or a `viewDidLayoutSubviews` width change greater than 1pt.
- **WinUI 3**: Not implemented in source. A Windows implementation would use a `Grid` with row definitions (`Auto` for the status row and divider, `*` for the transcript, `Auto` for the input row) so the surface fills the screen — a `StackPanel` cannot stretch a middle child to fill the remaining space. The transcript would use a `ScrollViewer` wrapping an `ItemsControl`/`ItemsRepeater`; the status row, a `TextBlock`-based thinking indicator; and the composer, a `TextBox` with `AcceptsReturn="False"` set in XAML (not a constructor argument — that property only controls whether Enter inserts a newline) paired with a `Button` for send, with Return-key submission wired through the `TextBox.KeyDown` event. Message alignment would use `HorizontalAlignment.Left`/`Right` based on sender. The close affordance would live in a `CommandBar` or `AppBarButton` supplied by the host page, mirroring the "host supplies chrome" approach used on iOS. The component would bind to `ChatViewModel.Messages`/`ActiveDrafts` via `INotifyCollectionChanged` and to a status property via `INotifyPropertyChanged`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/iOS/Chat/MobileChatViewController.swift` | unverified |
| web | `packages/web/packages/chat/src/modes/MobileChat.tsx` | unverified |

## Design Decisions

**Decision**: Delay focusing the input field by ~350ms after the surface becomes visible, rather than focusing immediately.
**Rationale**: Focusing immediately (e.g., in `viewDidLoad`) is too early — the keyboard animation doesn't reliably appear before the view hierarchy has settled. A 350ms delay lets the hierarchy settle first; this mirrors web chat surfaces that focus on mount with the same delay.
**Approved**: pending

**Decision**: Render the thinking/typing indicator in its own `statusRow` above the composer, outside the scrolling transcript.
**Rationale**: This keeps the status line visible above the keyboard on mobile, where the transcript commonly scrolls out of view. Web mirrors this with `.pc-typing` as a sibling of `.pc-transcript`, not a child.
**Approved**: pending

**Decision**: Auto-scroll to new content only when the user's scroll position is within 40pt of the bottom.
**Rationale**: This accommodates accidental small scrolls or swipes while still respecting an intentional read of history. A stricter threshold (1-2pt) would re-center on nearly every new message; a looser one (100pt+) would miss intentional history reads.
**Approved**: pending

**Decision**: Filter active drafts with empty (zero-length) text out of the transcript.
**Rationale**: A user typing and then clearing the field shouldn't create visual noise. Once the draft text becomes non-empty, it appears immediately in the transcript (live drafting).
**Approved**: pending

**Decision**: Make the send button touch-only, with no keyboard shortcut beyond the Return key in the input field.
**Rationale**: The source provides no modifier-key path (e.g., Cmd+Return on macOS, Ctrl+Return on web); adding one is deferred to a follow-up rather than invented here.
**Approved**: pending

**Decision**: Delegate individual message rendering, styling, and delivery-status display to `MobileMessageBubbleView` (iOS) and the `Transcript` component (web).
**Rationale**: Mobile Chat concerns itself only with layout, scrolling, and session-state updates, not message presentation.
**Approved**: pending

**Decision**: Ship without command-activity pills (`ToolCallPillView`) on mobile; only the thinking indicator appears in the status row.
**Rationale**: Deferring pills lets Mobile Chat ship without full feature parity with the desktop surface — a customer who wants them can file that as a follow-up rather than blocking on a half-parity port.
**Approved**: pending

**Decision**: Submit messages with an empty `attachments` array; no attachment picker or preview UI exists yet.
**Rationale**: The source calls `submitMessage(text:attachments:)` with `attachments: []`. A future revision can add an attachment picker once one is built, rather than this recipe documenting UI that doesn't exist.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source shown: Return-key submission and tap-to-send both work but no other keyboard path exists, so keyboard navigation is partial; close/send buttons are system-default sized, so touch-target-size passes; surface and divider colors come from semantic palette tokens whose contrast is set by the theme system rather than verified in this component, so contrast-ratio is partial; the open/close animations run unconditionally with no reduced-motion check, so reduced-motion fails; the placeholder and default close label are hardcoded rather than externalized, so both internationalization checks fail; the component collects no more than the session already holds, so data-minimization passes; and the composer validates non-empty input but delegates message-content rendering and sanitization to `MobileMessageBubbleView`/`Transcript`, so input-sanitization is partial; web delegates session/state logic to `useChatSession` and iOS delegates business logic to the injected `ChatViewModel`, with both sources owning only UI construction and wiring (separation-of-concerns: passed), and `MobileChat.test.tsx` and `MobileChatViewControllerTests.swift` both meaningfully exercise construction, transcript rebuild, and send/receive flows (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web and iOS sources |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and moved UIKit-only theme/open-state details out of Behavioral Requirements into Platform Notes; reformatted Design Decisions to Decision/Rationale/Approved and resolved the opaque "Task 8" reference; rewrote Compliance with linked, one-word-category checks; corrected unverified Reduce Motion, Analytics, and Logging claims to match what the source actually does; wrote real Configuration and Localization sections in place of "Not applicable"; fixed the auto-scroll threshold wording, split its test vector, and gave bubble-width a single basis with per-platform units; corrected the Compose, WinUI 3, SwiftUI, and AppKit/UIKit platform notes; added missing test vectors for theme reapplication, whitespace-only Return, rapid-fire sends, and resize/rotation, and gave vector 016 concrete input |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
