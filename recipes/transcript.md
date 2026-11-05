---
id: 98e78d31-2c3a-47dc-a156-435a5732a29f
title: Transcript
domain: adhsdk://recipes/transcript
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A scrollable container that renders a sequence of chat messages with optional
  typing indicator and fade-to-transparent gradient for older messages.
platforms:
- typescript
- web
tags:
- chat
- messaging
- transcript
- scroll
depends-on:
- adhsdk://recipes/message-bubble
- adhsdk://recipes/typing-indicator
related: []
references:
- https://www.w3.org/TR/wai-aria-1.2/#log
- https://www.w3.org/TR/wai-aria-1.2/#region
approved-by: ''
approved-date: ''
---

# Transcript

## Overview

Transcript is a scrollable message container component that displays a linear sequence of chat messages (rendered via MessageBubble), an in-progress typing indicator, and optional decorative elements (message popovers, detail arrows, fade gradient). It maintains scroll position at the bottom as messages arrive and automatically handles focus management for keyboard navigation.

## Behavioral Requirements

- **render-messages**: Component MUST render all messages in the `messages` array, with each message passed to a `MessageBubble` child component.
- **scroll-to-bottom-on-message-arrival**: When the message count changes, component MUST scroll the container to the bottom — but only when the reader is already at (or within a small threshold of) the bottom. If the reader has scrolled up to read earlier messages, new arrivals MUST NOT force the view back down.
- **scroll-to-bottom-on-typing-change**: Component MUST scroll the container to the bottom whenever `isTyping` changes, in either direction, subject to the same near-bottom condition as **scroll-to-bottom-on-message-arrival**.
- **render-typing-indicator**: Component MUST render a `TypingIndicator` child component when `isTyping` is `true`, unless suppressed by the `suppressTypingIndicator` prop.
- **keyboard-focusable**: Component container MUST be keyboard-focusable to enable arrow-key scrolling when no visible scrollbar affordance is present.
- **announce-as-region**: Component container MUST be exposed to assistive technology as a named landmark region with a non-empty accessible name, so screen reader users can navigate directly to the scrollback area.
- **accessible-label**: Component MUST accept an optional `label` prop that sets the container's accessible name; if omitted, MUST default to `"Conversation transcript"`.
- **message-selection**: Component MUST pass an `isSelected` flag to each `MessageBubble` based on whether the message's index matches the optional `selectedIndex` prop.
- **click-callback-passthrough**: Component MUST pass the `onMessageClick` callback to `MessageBubble` if provided; if not provided, `MessageBubble` MUST receive no click callback.
- **popover-rendering**: Component MUST render the result of `renderPopover(message)` immediately after the corresponding `MessageBubble` if both `renderPopover` and `message.popover` are truthy.
- **detail-arrows**: When `showDetailArrows` is `true`, component MUST show the detail arrow on a `MessageBubble` only when that message's `popover` is truthy (no arrow otherwise, and never when `showDetailArrows` is `false`). If `onDetailArrowClick` is provided, it MUST be passed through to every `MessageBubble` regardless of whether that message has a `popover`.
- **thinking-props-passthrough**: Component MUST forward `thinkingLabels`, `thinkingFrames`, `thinkingDoneGlyph`, `thinkingColorful`, and `thinkingTint` to the `TypingIndicator` child unchanged. `TypingIndicator` owns the resulting behavior (default dot pattern, default animation, default settled glyph, colorful flashing, tint targeting) — see `adhsdk://recipes/typing-indicator`.
- **fade-older**: Component SHOULD apply a fade gradient/mask via the `pc-transcript--fade` class when `fadeOlder` is `true`.
- **fade-anchor-viewport**: When the fade is applied, it MUST anchor to the viewport bottom: the newest (lowest) message stays fully opaque while older messages become increasingly transparent as they rise toward the top of the visible area.
- **fade-restores-on-scroll**: Scrolling any message back into the readable (bottom) zone MUST restore that message to full opacity.
- **custom-class**: Component MUST append the `className` prop to the container's class list if provided, allowing external style overrides.
- **message-identity-stability**: Component MUST preserve each message's view identity across re-renders, keyed by `message.id` (on Web, React's `key` prop — see Platform Notes).

## Appearance

- **Container height**: fills available space; typically a fixed-height or flex-layout container within a larger chat UI.
- **Overflow**: vertical scroll only; horizontal scroll not expected.
- **Message spacing**: determined by `MessageBubble` styling; Transcript does not add extra padding between messages.
- **Fade gradient** (when `fadeOlder` is true): viewport-anchored opacity mask from fully transparent at the top to fully opaque at the bottom; older messages approach transparency as they scroll toward the top; no explicit duration specified for the fade transition (governed by scroll position, not animation timing).
- **Typing indicator spacing**: rendered below all messages with standard line height; inherits typography from `TypingIndicator`.

## States

| State | Appearance change |
|-------|------------------|
| Default (messages, no typing) | All messages visible at full opacity; no typing indicator; scrolled to bottom. |
| Typing | All messages visible; TypingIndicator rendered below messages; scrolled to bottom. |
| Typing suppressed | Messages visible; no typing indicator even though `isTyping` is true (via `suppressTypingIndicator` prop). |
| Message selected | Corresponding MessageBubble receives `isSelected={true}` and applies its selected-state styling. |
| Fade mode active | Older messages progressively fade toward top; bottom messages remain opaque; fade is viewport-anchored, not message-relative. |
| Empty messages array | Container renders with no child bubbles; typing indicator may still be visible if `isTyping` is true. |

## Accessibility

- **Role**: `region` — marks the container as a named landmark so screen reader users can navigate to the scrollback area.
- **Label**: aria-label set to the `label` prop value (or default "Conversation transcript"); allows the region to announce its purpose.
- **Focus management**: the scroll container is made keyboard-focusable so arrow keys can scroll it without a visible scrollbar. If the UI hides the scrollbar (e.g., a theme that uses a fade gradient instead), this focusable container ensures keyboard users are not locked out of scrollback — it is a focus target, not a focus trap; focus is never forced onto it and never held there.
- **Message bubbles**: each MessageBubble is responsible for its own semantics (e.g., button roles, labels for interactive elements); Transcript does not add semantic roles to individual messages.
- **Typing indicator**: TypingIndicator is responsible for announcing its own state; Transcript does not manage screen-reader announcements for typing.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| transcript-001 | render-messages | `messages=[{id: "1", ...}, {id: "2", ...}]` | Both messages render as MessageBubble children in order. |
| transcript-002 | scroll-to-bottom-on-message-arrival | Reader is at the bottom. Initial render with 3 messages, then append a 4th message. | Scroll position moves to bottom; new message is in view. |
| transcript-003 | scroll-to-bottom-on-typing-change | Reader is at the bottom. 5 messages rendered, `isTyping` changes from `false` to `true`. | Scroll position moves to bottom; TypingIndicator becomes visible. |
| transcript-004 | render-typing-indicator | `isTyping={true}`, `suppressTypingIndicator={false}` | TypingIndicator is rendered in the DOM. |
| transcript-005 | render-typing-indicator | `isTyping={true}`, `suppressTypingIndicator={true}` | TypingIndicator is not rendered in the DOM. |
| transcript-006 | keyboard-focusable | User presses Tab to navigate; transcript container is in tab order. | Container receives keyboard focus. |
| transcript-007 | announce-as-region | Container renders; screen reader reads the DOM. | Screen reader announces a region landmark with the accessible-name text. |
| transcript-008 | accessible-label | `label` prop not provided. | Default label "Conversation transcript" is set as the accessible name. |
| transcript-009 | accessible-label | `label="Chat history"` | Accessible name is set to "Chat history". |
| transcript-010 | message-selection | `selectedIndex={1}`, messages array has 3 items. | MessageBubble at index 1 receives `isSelected={true}`; others receive `isSelected={false}`. |
| transcript-011 | click-callback-passthrough | `onMessageClick={callback}` provided. | Click events on MessageBubbles are passed to the callback with the message index. |
| transcript-012 | click-callback-passthrough | `onMessageClick` not provided. | MessageBubble receives no click callback; clicks have no effect. |
| transcript-013 | popover-rendering | Message has `popover` truthy and `renderPopover` provided. | Popover is rendered immediately after the MessageBubble. |
| transcript-014 | popover-rendering | Message has `popover` falsy or `renderPopover` not provided. | No popover is rendered. |
| transcript-015 | detail-arrows | `showDetailArrows={true}`, message has `popover` truthy. | MessageBubble receives `showDetailArrow={true}` and detail arrow is visible. |
| transcript-016 | detail-arrows | `showDetailArrows={false}` or message has no `popover`; `onDetailArrowClick` provided. | MessageBubble receives `showDetailArrow={false}` (arrow not shown); the `onDetailArrowClick` callback is still passed through, it is simply never triggered. |
| transcript-017 | thinking-props-passthrough | `thinkingLabels` array provided. | TypingIndicator receives the labels and renders them instead of default dots. |
| transcript-018 | thinking-props-passthrough | `thinkingFrames` array provided. | TypingIndicator receives the frames and cycles through them for animation. |
| transcript-019 | thinking-props-passthrough | `thinkingDoneGlyph` string provided. | TypingIndicator uses the glyph when `isTyping` becomes false. |
| transcript-020 | thinking-props-passthrough | `thinkingColorful={true}` and `isTyping={true}` | TypingIndicator flashes non-green colors during thinking. |
| transcript-021 | thinking-props-passthrough | `thinkingTint` object provided. | TypingIndicator applies tint to the specified elements (glyph, words, or both). |
| transcript-022 | fade-older | `fadeOlder={true}`, messages visible in viewport. | Fade is applied: the oldest visible message is more transparent than the newest (on Web, signaled by the `pc-transcript--fade` class — see Platform Notes). |
| transcript-023 | fade-older | `fadeOlder={false}` | No fade is applied; all messages render at full opacity (on Web, the `pc-transcript--fade` class is absent). |
| transcript-024 | custom-class | `className="custom-class"` | The container includes `custom-class` in its class list. |
| transcript-025 | message-identity-stability | Messages re-render with same IDs. | Each message retains its view identity across the re-render (no unnecessary remount); on Web this is React's `key={message.id}` (see Platform Notes). |
| transcript-026 | scroll-to-bottom-on-message-arrival | Reader has scrolled up away from the bottom (outside the near-bottom threshold); a new message arrives. | Scroll position remains where the reader left it; the view does not jump to the new message. |
| transcript-027 | fade-anchor-viewport | `fadeOlder={true}`; multiple messages; reader scrolls so an older message sits near the top of the viewport. | The older message near the top is more transparent than the newest message at the bottom; opacity tracks position in the viewport, not position in the message stack. |
| transcript-028 | fade-restores-on-scroll | `fadeOlder={true}`; a faded (older) message is scrolled down into the bottom of the viewport. | That message's opacity returns to fully opaque once it is within the readable (bottom) zone. |
| transcript-029 | message-selection | `selectedIndex={-5}` (out of range, negative), messages array has 3 items. | No message receives `isSelected={true}`; component does not error. |

## Edge Cases

- **Empty messages array**: Component renders the container and typing indicator (if not suppressed) even with no messages. The scrollback area is empty but focusable and keyboard-navigable.
- **selectedIndex out of range**: If `selectedIndex` is greater than or equal to the messages array length, no message receives `isSelected={true}` (all receive `isSelected={false}`). Component does not error.
- **selectedIndex is -1**: No message receives `isSelected={true}`. This is the default when the prop is omitted.
- **selectedIndex is less than -1**: Same behavior as -1 — no message receives `isSelected={true}`, and the component does not error.
- **isTyping true with empty messages array**: Typing indicator renders at the top of an otherwise empty container. Scroll position is at the bottom (no content to scroll to, so it is naturally at bottom).
- **Reader scrolled away from bottom**: If the transcript is not at (or within a small threshold of) the bottom when a new message arrives or `isTyping` changes, the view remains where the reader left it; arrival does not force a jump. Scrolling back near the bottom resumes auto-follow.
- **Rapid message arrivals**: If messages arrive faster than scroll-to-bottom can complete while the reader is at the bottom, the container remains scrolled to bottom — the underlying scroll observer re-triggers on every mutation, so it keeps pace with each new message.
- **fadeOlder with single message**: Single message remains at full opacity; fade gradient has no effect (no older messages to fade).
- **fadeOlder and scroll to top**: User scrolls to the top of the transcript to read the oldest message. That message transitions from faded to fully opaque as it enters the readable zone; no jarring opacity shift (the mask tracks scroll position continuously, not a discrete state change).
- **suppressTypingIndicator with isTyping true**: TypingIndicator is not rendered even though the component is aware typing is in progress; scroll-to-bottom still occurs on `isTyping` changes.
- **renderPopover returns null or undefined**: If renderPopover is called but returns null or undefined, nothing is rendered after the MessageBubble (React skips falsy children).
- **message.popover is falsy but renderPopover is provided**: No popover is rendered; renderPopover is not called.
- **onDetailArrowClick on message with no popover**: MessageBubble receives `showDetailArrow={false}` even if `showDetailArrows={true}`, so the detail arrow itself is not rendered — but if `onDetailArrowClick` was provided, the callback is still wired to that message; it simply has no arrow to trigger it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `messages` | `ChatMessage[]` | required | Array of message objects to render. |
| `isTyping` | `boolean` | required | Whether the remote participant is currently typing. |
| `selectedIndex` | `number` | `-1` | Index of the message to mark as selected; optional. |
| `onMessageClick` | `(index: number) => void` | `undefined` | Callback fired when a message is clicked; optional. |
| `renderPopover` | `(message: ChatMessage) => ReactNode` | `undefined` | Function to render a popover for each message; optional. |
| `showDetailArrows` | `boolean` | `false` | Whether to show detail arrows on messages that have a popover. |
| `onDetailArrowClick` | `(index: number) => void` | `undefined` | Callback fired when a detail arrow is clicked; optional. |
| `className` | `string` | `undefined` | Custom CSS class to append to the container. |
| `thinkingLabels` | `readonly StatusWordPair[]` | `undefined` | Word pairs for the typing indicator (falls back to dots if not provided). |
| `thinkingFrames` | `readonly string[]` | `undefined` | Animation frames for the typing indicator glyph. |
| `thinkingDoneGlyph` | `string` | `undefined` | Settled glyph to render when typing completes. |
| `thinkingColorful` | `boolean` | `false` | Whether to flash random non-green colors while typing. |
| `thinkingTint` | `StatusTintSpec` | `undefined` | Specification for which elements (glyph, words, both) receive tint while typing. |
| `suppressTypingIndicator` | `boolean` | `false` | If `true`, do not render the typing indicator even when `isTyping` is true. |
| `label` | `string` | `"Conversation transcript"` | Accessible name for the scroll region. |
| `fadeOlder` | `boolean` | `false` | Whether to apply a viewport-anchored fade gradient to older messages. |

## Deep Linking

Not applicable: Transcript is a message container component, not a top-level view. Deep linking is handled by the containing chat application, not by this component.

## Localization

The `label` prop's default value, `"Conversation transcript"`, is a user-facing string hardcoded in source (`Transcript.tsx`). It is only correct for the `en` locale; a host application MUST supply a localized `label` for other locales rather than relying on the default. The `thinkingLabels` prop is supplied by the parent application and is assumed to already be localized when passed through. Transcript performs no locale-aware formatting itself (no dates, numbers, currencies, or plurals).

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the `fadeOlder` mask is a function of scroll position, not a timed animation — there is no motion for `prefers-reduced-motion` to suppress (see Appearance: the fade has no animation duration, only scroll-linked opacity). |
| Increase Contrast | The `fadeOlder` mask reduces message *opacity*; it does not introduce a color of its own to adjust. Legibility of a faded (older) message is bounded by the active theme's text/background contrast ratio at that opacity level, which Increase Contrast affects the same way it affects any other themed content. |
| Differentiate Without Color | Not applicable; Transcript does not use color alone to convey meaning. Typing status is announced via the TypingIndicator's content and `aria-label`, not color. |

## Feature Flags

Not applicable: Transcript has no built-in feature flags. A parent application may conditionally render or configure the component, but Transcript itself does not gate any behavior.

## Analytics

Not applicable: Transcript does not emit analytics events. Click events and arrow-click events are delegated to parent-provided callbacks (`onMessageClick`, `onDetailArrowClick`). The parent application is responsible for logging and analytics.

## Privacy

Not applicable: Transcript does not collect, store, transmit, or log user data. It is a stateless view component that renders data provided by the parent application.

## Logging

Not applicable: Transcript has no logging. It does not emit debug, info, warn, or error messages.

## Platform Notes

- **Source platform (Web/React)**: Component is implemented in `packages/web/packages/chat/src/components/Transcript.tsx`. It uses React hooks (`useRef`, `useScrollToBottom`) to manage scroll position — `useScrollToBottom` only follows new content when the reader is already within ~30px of the bottom — and combines styled `MessageBubble` and `TypingIndicator` children. The container carries `tabIndex={0}` for keyboard focus and `role="region"` / `aria-label` for the landmark name. Each message is rendered with React's `key={message.id}` to preserve DOM identity across re-renders. CSS class names follow the `pc-*` convention (e.g., `pc-transcript`, and `pc-transcript--fade` when `fadeOlder` is `true`); the fade itself is a CSS `mask-image` linear gradient over alpha (`css/base.css`), an opacity mask, not a color gradient.
- **SwiftUI**: Implement as a `ScrollViewReader` containing a `VStack` of message views. Use the `onChange` modifier on the message count and on `isTyping` to scroll to the bottom message ID, but only when the view is already scrolled near the bottom (track this with a small `ScrollView` offset/threshold check, mirroring `scroll-to-bottom-on-message-arrival` / `scroll-to-bottom-on-typing-change`). Apply a `LinearGradient` alpha mask ramping from 0.0 at the top to 1.0 at the bottom when `fadeOlder` is true; the gradient anchor must be relative to the scroll container's visible bounds, not the message stack's bounds. Expose the same prop interface (converted to Swift types); `isTyping` is a plain `let isTyping: Bool` — Transcript never writes back to it, so it is not a `@Binding`.
- **Compose (Android)**: Implement as a `LazyColumn` with `state.animateScrollToItem()` called when `messages.size` changes or `isTyping` changes, gated on the list state already being near the bottom (compare `firstVisibleItemIndex`/`layoutInfo` to the list end). For `fadeOlder`, apply a `Modifier.graphicsLayer` with `alpha` interpolated based on the item's position relative to the viewport. Each message is a `Composable` equivalent of `MessageBubble`. Typing indicator is rendered as a `Composable` when `isTyping` is true (unless suppressed).
- **AppKit / UIKit**:
  - **UIKit**: Implement as a `UIScrollView` containing a `UIStackView` (vertical, filling width). Use `scrollRectToVisible` to scroll to the bottom `CGRect` on message arrival or typing state change, gated by whether `contentOffset` is already near `contentSize` (near-bottom check). For `fadeOlder`, apply a `CAGradientLayer` as a mask on the scroll view's `layer`, anchored to the scroll view's bounds (use `scrollViewDidScroll` to update the mask position as the user scrolls, so it stays pinned to the viewport, not the content). Each message is a `UIView` equivalent of `MessageBubble`; typing indicator is a subview of the stack that is added/removed based on `isTyping` and `suppressTypingIndicator`.
  - **AppKit**: Implement as an `NSScrollView` with a document `NSStackView` (vertical, filling width). Scroll to bottom on message arrival or typing state change by adjusting the `NSClipView`'s bounds origin (or calling `scrollToEndOfDocument:`-style helper), gated by the same near-bottom check as UIKit. For `fadeOlder`, set `wantsLayer = true` and apply a `CAGradientLayer` mask to the scroll view's layer, anchored to the clip view's visible rect and updated on bounds-change notifications. Each message is an `NSView` equivalent of `MessageBubble`; the typing indicator view is inserted into or removed from the stack based on `isTyping` and `suppressTypingIndicator`.
- **WinUI 3**: Implement as a `ScrollViewer` with a `StackPanel` (`Orientation="Vertical"`) inside. On `messages` or `isTyping` changes, call `ScrollViewer.ChangeView(null, scrollViewer.ExtentHeight, null)` to scroll to bottom, gated by whether `VerticalOffset` is already within a small threshold of `ScrollableHeight`. For `fadeOlder`, use a `Windows.UI.Composition.CompositionMaskBrush` (obtained via `ElementCompositionPreview.GetElementVisual`) with a `CompositionLinearGradientBrush` as its mask, anchored to the `ScrollViewer`'s viewport; update the mask's size and offset in the `SizeChanged` and `ViewChanged` events so it stays pinned to the viewport rather than the content. Render each message as a custom control equivalent to `MessageBubble` (typically a `UserControl` with XAML and C# code-behind). Bind the typing indicator's visibility to `IsTyping && !SuppressTypingIndicator` with a `BoolToVisibility`-style value converter (there is no built-in `ConditionalVisibility` converter).

## Design Decisions

- **Decision**: Use `role="region"` (not `role="log"` with `aria-live="polite"`) for the scroll container.
  **Rationale**: `role="log"` carries an implicit live region that announces on every mutation; streamed replies mutate the last bubble a token at a time, so a live region would re-announce the same growing sentence on every frame. `role="region"` lets the user navigate and read the transcript at their own pace, while the typing indicator signals that new content is coming without verbose re-announcement. See the WAI-ARIA `log` and `region` role definitions (references).
  **Approved**: pending

- **Decision**: Make the scroll container keyboard-focusable (`tabIndex={0}` on Web).
  **Rationale**: The container scrolls, and a scroll container that cannot take focus cannot be scrolled from the keyboard — there is no other way to reach the arrow keys' target. This is usually masked by a visible, draggable scrollbar; a theme that hides the scrollbar (e.g., substituting a fade for it) removes the last non-pointer affordance, and without focus, keyboard-only users would have no way to reach older messages.
  **Approved**: pending

- **Decision**: Anchor the fade mask to the bottom of the visible viewport, not to the bottom of the message stack.
  **Rationale**: A stack-anchored fade would keep the same messages faded no matter where the reader scrolls — once a message is dimmed by its position in the stack, it stays dimmed even after being scrolled back into view. A viewport-anchored fade instead computes opacity from position in the visible window, so scrolling any older message back down toward the bottom restores its full opacity, while the newest content still reads as the visual focus by default.
  **Approved**: pending

- **Decision**: Make `selectedIndex` optional, defaulting to `-1`.
  **Rationale**: Not every host needs message selection. Omitting the prop cleanly means no `MessageBubble` receives `isSelected={true}`, so selection state never interferes with hosts that don't use it.
  **Approved**: pending

- **Decision**: Keep `thinkingColorful` and `thinkingTint` as two separate props.
  **Rationale**: Colorfulness (flashing random non-green colors) and tint (applying a specific color tone to specific elements) are independent visual behaviors. Separating them lets a host flash colors without tinting, or tint without flashing.
  **Approved**: pending

- **Decision**: Render the `renderPopover` result as a sibling of `MessageBubble`, not nested inside it.
  **Rationale**: Keeping the message structure flat lets the host application control popover layout (positioning, sizing, animation) without fighting `MessageBubble`'s own DOM structure.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `Transcript.tsx`: `tabIndex={0}` plus `role="region"`/`aria-label={label}` give the container keyboard access and a named landmark (keyboard-navigable, semantic-markup passed); the `label = 'Conversation transcript'` default parameter is an English literal hardcoded in source rather than sourced from a localization resource (no-hardcoded-strings failed), while the `label` prop itself does accept a host-supplied localized string (string-externalization partial). `separation-of-concerns` passes because the component renders over props and delegates scroll behavior to `useScrollToBottom`, and `unit-test-coverage` passes on `Transcript.test.tsx`'s exercise of message rendering, selection, click callbacks, popovers, detail arrows, and the typing indicator.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case (merged the five thinking-* requirements into thinking-props-passthrough; split should-apply-fade-gradient into fade-older/fade-anchor-viewport/fade-restores-on-scroll); documented the near-bottom gating on both scroll-to-bottom requirements; folded the popover condition into the detail-arrows requirement; made requirements and test vectors platform-neutral, moving React-specific details (tabIndex, key, CSS class, onClick) into Platform Notes; fixed SwiftUI's isTyping to a plain let, split AppKit out of the UIKit note, and replaced the nonexistent WinUI 3 OpacityMask/ConditionalVisibility APIs with CompositionMaskBrush and a BoolToVisibility-style converter; corrected the fade design decision's rationale, the Reduce Motion/Increase Contrast wording, and the "focus trap" phrasing; reformatted Design Decisions into Decision/Rationale/Approved rows; linked Compliance to catalog check IDs and added the Internationalization checks the hardcoded default label triggers; added depends-on entries and WAI-ARIA references; dropped the unfounded focus-outline assertion in transcript-006 and added vectors for near-bottom gating, fade anchoring/restoration, and an out-of-range negative selectedIndex. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
