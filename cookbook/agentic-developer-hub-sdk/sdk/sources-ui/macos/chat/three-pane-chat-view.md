---
id: 2d27892d-a3df-4e7d-ba47-dfd6c45b4c6d
title: "Three Pane Chat"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Multi-pane chat layout displaying transcript, topics list, and detail pane with visual connectors."
platforms:
  - typescript
  - web
  - swift
  - macos
tags:
  - chat-ui
  - layout
  - pane
  - topic
depends-on:
  - dcf1a793-0a47-466b-8b09-0bcf091fd55a
  - 98e78d31-2c3a-47dc-a156-435a5732a29f
  - 0ae70642-28e7-436a-b934-0b445652ac09
  - 4c3c4287-95bd-47f5-9a07-2382e0db523b
  - d7a1229c-cf03-436f-8287-d99b52747510
  - e5b8e26f-2869-4a09-8d8e-0bb68ece805d
related: []
references: []
approved-by: ""
approved-date: ""
---

# Three Pane Chat

## Overview

The Three Pane Chat component orchestrates a sophisticated multi-pane chat layout designed for exploratory, structured conversations. It displays three side-by-side columns: an optional topics pane (left), a chat transcript pane (center), and a collapsible detail pane (right). Messages that include popover metadata automatically generate selectable topics, which when activated display their associated detail panel in the detail pane. SVG connectors visually link selected topics to their corresponding messages and message details, providing navigation context. The component manages focus, keyboard navigation, and responsive layout recalculation to adapt to viewport changes and content updates.

## Behavioral Requirements

- **derive-topics-from-messages**: Component MUST derive a list of topics from messages that contain popover metadata. Each message with popover data (title and description) generates one topic entry. This derived list is only committed (and the active topic re-synced) when the number of popover-bearing messages changes from the previously committed count; an update that keeps the same popover count — trimming and replacing messages, swapping to a different conversation with the same number of popovers, or editing a popover in place — leaves the previously committed topics (titles, descriptions, links, images, and `messageIndex` values) unchanged.
- **track-active-topic**: Component MUST maintain which topic is currently active (selected). Only one topic MAY be active at a time.
- **show-detail-panel-for-active-topic**: When a topic is active, its detail panel (containing title, description, links, and images) MUST be displayed within the detail pane.
- **append-visible-topic-on-selection**: When a topic becomes active, Component MUST append it to a visible topics stack if not already present, allowing stacked navigation history.
- **arrow-key-navigation**: Component MUST allow navigation between visible topics using the arrow up and arrow down keys, moving to the previous or next topic in the visible stack. Navigation clamps at the ends of the stack — pressing past the first or last visible topic keeps the current topic active rather than wrapping around. This navigation is global: it is not gated on where keyboard focus currently is (see edge case **topic-selection-during-typing**).
- **input-focus-keystroke**: When a single-character keystroke (not ctrl/meta/alt modified) is pressed and focus is not already in an input or textarea, Component MUST focus the chat input field, and the triggering character MUST land in the input.
- **draw-connectors-between-panes**: Component MUST render SVG connectors that visually link: (1) active topics to their source message in transcript, and (2) messages to their corresponding detail panels when visible.
- **recalculate-layout-on-image-load**: Component MUST recalculate the three-pane layout dimensions when images in a detail panel finish loading, to account for dimension changes.
- **topic-selection-click**: When a user clicks a topic in the topics pane, Component MUST activate that topic and select its corresponding message in the transcript.
- **message-click-from-transcript**: When a user clicks a message in the transcript, Component MUST select that message. If the message has an associated topic, Component MUST activate that topic; if it has no associated topic, the active topic MUST be left unchanged.
- **detail-arrow-indicator**: Component SHOULD display an indicator (detail arrow) on messages that have associated topics to signal that detail is available.

## Appearance

- **Corner radius**: 0 (rectangular panes)
- **Padding**: none at component level; sub-panes (topics, transcript, detail) manage internal spacing
- **Font**: inherited from message and topic content
- **Background**: the topics pane and each visible detail panel share the `--pc-surface` token (transparent until activated, fading in per the visible-pane transition); the chat pane has no separate pane-level background of its own — its transcript and input sub-elements supply theirs.
- **Foreground/Text**: inherited from content
- **Border**: thin separator between panes (1px)
- **Shadow**: none
- **Min/Max size**: Component fills available container; responsively adjusts pane widths based on viewport and content

## States

| State | Appearance change |
|-------|------------------|
| Default | Topics pane visible (if layout permits), transcript centered, detail pane empty/collapsed |
| Topic Active | Selected topic highlighted in topics pane, detail pane expands with topic content, connectors drawn |
| No Topics | Topics pane hidden, transcript and detail panes remain, full width available to transcript |
| Image Loading | Detail pane height recalculates when images finish loading |
| Input Focused | Chat input shows a focus indicator when it holds keyboard focus |
| Topic Navigating | No distinct visual chrome; arrow key presses move the active topic and update the highlighted topic/detail panel regardless of where focus currently is |

## Accessibility

- **Role/trait**: Composite container with semantically structured panes; topics pane is a list of selectable items, transcript is a scrollable region, detail pane is a dynamic content region.
- **Label requirements**: Topics MUST have accessible labels (title and description); messages MUST have accessible content (text or aria-label); detail pane MUST announce its active topic when it updates.
- **Announce state changes**: When a topic is activated, the accessibility tree MUST be updated to reflect the active topic and detail pane content. When connectors render, their presence MUST not interfere with text reader navigation.
- **Keyboard navigation**: Arrow up/down MUST navigate between visible topics, including while the chat input has focus (see **arrow-key-navigation**). Single-character keystrokes (without modifiers) MUST focus the chat input when focus is not already in an input. Tab MUST navigate between focusable regions (topics list, transcript, input, detail pane links).
- **Minimum tap target**: Topics list items and messages MUST have a minimum touch target of 44×44pt on mobile platforms, 48×48dp on Android.
- **Assistive technology**: Screen readers MUST announce the count and titles of topics. Connectors are visual only and MUST NOT clutter the accessible tree.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| three-pane-001 | derive-topics-from-messages | Messages array with 3 messages, 2 with popover metadata | Topics list contains 2 entries with titles and descriptions from popover data |
| three-pane-002 | track-active-topic | User selects the first topic | The first topic becomes active; only one topic is marked active at a time |
| three-pane-003 | show-detail-panel-for-active-topic | Topic 1 is active | The detail pane shows topic 1's detail panel: title, description, links, and images |
| three-pane-004 | append-visible-topic-on-selection | User selects topic 2 while topic 1 is visible | Both topic 1 and topic 2 remain in the visible-topics stack; the earlier selection is preserved for back-navigation |
| three-pane-005 | arrow-key-navigation | Three topics are visible; the second (of three) is active; user presses arrow down | The active topic moves to the third (last) visible topic |
| three-pane-006 | arrow-key-navigation | Two topics are visible; the second (last) is active; user presses arrow down | The active topic stays at the last visible topic; navigation clamps rather than wrapping to the first |
| three-pane-007 | input-focus-keystroke | Focus is on the topics pane; user presses 'a' (no modifiers) | Chat input field receives focus; the 'a' character is inserted into the input |
| three-pane-008 | input-focus-keystroke | Focus is already in the chat input; user presses 'a' | The keystroke is inserted into the input as normal; focus remains in the input |
| three-pane-009 | draw-connectors-between-panes | The first topic is active and is associated with a message in the transcript | A connector is drawn from the active topic to its message in the transcript, and another from that message to its detail panel |
| three-pane-010 | recalculate-layout-on-image-load | A detail panel with images is shown | After each image finishes loading, the three-pane layout recalculates its dimensions |
| three-pane-011 | topic-selection-click | User clicks a topic in the topics pane | The clicked topic becomes active; the message associated with that topic is selected in the transcript |
| three-pane-012 | message-click-from-transcript | User clicks a message that has an associated topic | The message is selected; the topic associated with that message becomes active |
| three-pane-013 | message-click-from-transcript | User clicks a message without an associated topic | The message is selected; the active topic is left unchanged (it is not cleared or reset) |
| three-pane-014 | derive-topics-from-messages | Messages array is updated to remove a message with popover data | Topics list is recalculated; the topic derived from the removed message no longer appears |
| three-pane-015 | detail-arrow-indicator | Message 2 has an associated topic | Transcript renders a detail arrow indicator on message 2 |
| three-pane-016 | derive-topics-from-messages | Messages array is replaced by a different conversation whose popover count is unchanged (e.g. 2 popover messages swapped for 2 different popover messages) | Topics list is NOT recomputed; the previously committed topics (titles, descriptions, `messageIndex` values) remain, now stale relative to the new messages |

## Edge Cases

- **Empty or null input**: If the messages array is empty or null, the topics array MUST be initialized as empty and the topics pane MUST be hidden or show an empty state. No crash occurs.
- **Messages without popover data**: Messages without popover metadata MUST be ignored when deriving topics. They appear in transcript but do not generate topic entries.
- **Active topic out of bounds**: If the active topic refers to a topic that no longer exists, it MUST be treated as no topic being active, and the detail pane MUST be cleared.
- **Visible topics stack out of bounds**: The visible-topics stack is written only by an append-only effect; recalculating topics never removes a stale entry from it. An index whose topic no longer exists is merely skipped wherever it is consumed — `PanelStack` renders nothing for it, and message-click/arrow-key navigation treat a missing topic as a no-op — but the index itself stays in the stack, and if a later topic recalculation produces a new topic at that same index, the stale entry silently rebinds to it.
- **Keyboard navigation with no visible topics**: Arrow-key handling is gated on the visible-topics stack being non-empty, not on whether any topic currently exists. If the stack still holds stale (now-nonexistent) entries, arrow key presses are still intercepted (`preventDefault`) even though there is nothing to navigate to; arrow keys are ignored outright only once the stack itself is empty.
- **Layout recalculation during scroll**: If the layout recalculates while the user is scrolling, it MUST update without interrupting scroll position or changing the active topic.
- **Image loading errors**: If an image in a detail panel fails to load, the layout MUST still recalculate to maintain layout correctness.
- **Multiple connector updates**: If topics or the visible-topics stack change rapidly, connectors MUST be recalculated for each change without rendering stale connectors; SVG rendering MUST remain consistent with the current state.
- **Topic-selection-during-typing**: Arrow up/down navigation is global — it is not scoped to the topics pane having focus. If a user presses arrow up/down while typing in the chat input, the keys navigate the visible topics, and the input's default cursor-movement behavior for those keys is suppressed for that keypress.
- **Rapid topic switching**: If the active topic changes multiple times in rapid succession, each change MUST be processed; the visible-topics stack MUST accumulate selections; no topics are skipped.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `session` | `ChatSession` (ref) | required | Chat session object containing messages, isTyping, sendMessage, selectedIndex, selectMessage |
| `className` | `string` | `""` | CSS class name applied to the top-level frame and chat pane for styling |

## Deep Linking

Not applicable: Three Pane Chat is a composite container rendered within a chat application, not a standalone route or page.

## Localization

Three Pane Chat renders no static copy of its own beyond panel headers (handled by its sub-panes' own recipes), but the Accessibility section requires assistive-technology announcements that carry user-visible text and MUST be localized:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `three_pane_chat.topic_activated_announcement` | "{title} details shown" | Announced by assistive technology when a topic becomes active and its detail panel is shown |
| `three_pane_chat.topic_count_announcement` | "{count} topics" | Announced by assistive technology when the topics list changes |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | When enabled, SVG connector animations and pane transitions SHOULD be disabled or simplified to static rendering. |
| Increase Contrast | Topic and message selection highlights SHOULD use higher-contrast colors to meet WCAG AA standards. |
| Differentiate Without Color | Topic and message selection SHOULD be communicated via both color and additional visual indicators (e.g., bold text, borders, icons) to avoid color-only differentiation. |

## Feature Flags

Not applicable: Three Pane Chat is an intrinsic component of the chat mode system and is not gated by feature flags in the source.

## Analytics

None of the following events are emitted by the current source (no analytics or tracking calls exist in `ThreePaneChat.tsx` or its sub-components); they are proposed instrumentation points and MAY be implemented by consumers.

| Event | Properties | When |
|-------|-----------|------|
| `three_pane_chat.topic_selected` | `{ topicIndex: number, messageIndex: number }` | User selects a topic in the topics pane |
| `three_pane_chat.message_clicked` | `{ messageIndex: number, hasAssociatedTopic: boolean }` | User clicks a message in the transcript |
| `three_pane_chat.keyboard_navigation` | `{ direction: "up" \| "down", fromTopicIndex: number, toTopicIndex: number }` | User navigates between topics using arrow keys |
| `three_pane_chat.input_focus_keystroke` | `{}` | User presses a keystroke that auto-focuses the chat input |

## Privacy

Not applicable: Three Pane Chat does not collect, store, or transmit user data beyond rendering the session's existing message and topic data. The `input_focus_keystroke` analytics event above intentionally carries no properties — earlier drafts of this instrumentation point captured the triggering character, which would have recorded the first character of user input; that property was removed.

## Logging

Subsystem: application (inherited from AgenticDeveloperHubSDK) | Category: `ThreePaneChatView`

| Event | Level | Message |
|-------|-------|---------|
| topics_recalculated | debug | `ThreePaneChatView: Topics recalculated. Count: {count}, Active: {activeIndex}` |
| layout_recalculated | debug | `ThreePaneChatView: Layout recalculated. Show topics: {showTopics}, Height: {height}` |
| connector_pairs_updated | debug | `ThreePaneChatView: Connector pairs updated. Pairs: {count}` |
| keyboard_navigation | debug | `ThreePaneChatView: Keyboard navigation: {direction}, Active topic now: {index}` |

## Platform Notes

- **Web (React)**: Source implementation in `packages/web/packages/chat/src/modes/ThreePaneChat.tsx`. Renders a frame div with class `pc-three-pane-frame` containing an inline ConnectorSVG, a TopicsPane subcomponent (conditionally shown), a chat pane with Transcript and ChatInput, and a PanelStack subcomponent for detail panels. Uses React hooks (useState, useRef, useCallback, useEffect, useMemo) to manage state. Layout visibility is driven by the `useThreePaneLayout` hook which calculates available space and determines whether the topics pane should be shown. Keyboard handling is set up in a `useEffect` whose `handleKey` listener manages focus and navigation; the arrow-key branch runs before the input-focus check and is not gated on where focus is. Topics are recomputed from message popovers on every messages change, but the recomputed list is committed only when the popover count differs from the previously committed count — an unchanged count leaves the committed topics (and their `messageIndex` values) stale.

- **SwiftUI**: Implement as a container view that lays out three side-by-side regions: a topics list (List or ScrollView with topic items), a transcript region (ScrollView or custom scroll container with message cells), and a detail pane (dynamic content area stacking one panel per visible topic). Use `@State` properties to track the active topic and the visible-topics stack; derive topics in a computed property from the session's messages. Wrap keyboard handling in a `.onKeyPress` or custom gesture handler to capture arrow keys globally and route single-character keystrokes to a focused input field. Model shared layout state (whether the topics pane shows, available height) with an `@Observable` model type read via `@Environment`, not `EnvironmentObject`. Render visual connectors as an overlay Canvas or ZStack with Path drawing to connect pane nodes. The current Apple source is a stub that renders `InlineChatView` instead of this layout — see the Design Decisions entry recording that as a known gap.

- **Compose**: Implement as a composable function that manages topics state with `remember { mutableStateOf(emptyList()) }`. Derive topics from messages with `remember(messages) { ... }` or `derivedStateOf`, not a `LaunchedEffect` side effect, so topics stay synchronized with input rather than lagging a frame behind. Use a Row or Spacer-based layout (or a custom layout with the Layout composable) to position the topics LazyColumn, a transcript Column/LazyColumn, and a detail pane. Track the active topic and visible-topics stack with `mutableStateOf`. Handle keyboard input with a KeyEvent callback or FocusRequester to route navigation and input focus. Use Canvas to draw connectors between composables by querying their layout coordinates via LocalDensity and LayoutCoordinates observers. Animate connector appearance with transition and updateTransition, gated behind the system Reduce Motion setting (see **Accessibility Options**).

- **AppKit / UIKit**: Implement as an NSView (macOS) or UIView (iOS) subclass that manages three child views: a topics table view (NSTableView or UITableView), a transcript scroll view with custom message cells, and a detail pane view (UIView or NSView) hosting one panel per visible topic. Use Auto Layout constraints to position the three panes and adjust their widths/visibility based on layout calculations. Model the active topic and visible-topics stack in an `@Observable` view model, not `@Published`/`ObservableObject`. Derive topics from messages in a method called on each messages change. Capture arrow keys and route single-character keystrokes with `UIKeyCommand`/`pressesBegan` on iOS and `keyDown` on macOS — `UIView.inputView` does not receive key presses and cannot be used for this. Draw connectors using CAShapeLayer with UIBezierPath (iOS) or NSBezierPath (macOS), querying frame positions of the panes. Note: the current source stub (`ThreePaneChatView.swift`) defers implementation and renders `InlineChatView` instead; full implementation is pending (see Design Decisions).

- **WinUI 3**: Implement as a UserControl containing a Grid with three columns (topics column, transcript column, detail column) or a custom Panel layout. Use a `ListView` (not `ListBox`) for the topics pane. Use a ScrollViewer for the transcript region. Bind to a ViewModel's Topics (`ObservableCollection<TopicData>`), ActiveTopicIndex, and the visible-topics stack. Derive topics in the ViewModel using LINQ transformations on the messages collection. Handle keyboard input by attaching a KeyDown event handler to the root UserControl; use e.Key to detect arrow keys and route single-character keystrokes to the input field. Draw connectors with `Microsoft.UI.Xaml.Shapes.Path` elements on a `Canvas` overlay (or a Win2D `CanvasControl` for more complex curves) — WinUI 3 has no `OnRender`/`DrawingContext`; those are WPF-only APIs. Animate connector appearance with a Storyboard, respecting the system reduced-motion setting.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/ThreePaneChatView.swift` | unverified |
| web | `packages/web/packages/chat/src/modes/ThreePaneChat.tsx` | unverified |

## Design Decisions

- **Decision**: Topics are automatically extracted from message popover metadata rather than passed as a separate prop.
  **Rationale**: Keeps the component stateless with respect to topics. Tradeoff: the message format must include popover data for topics to appear, and because the recomputed list is committed only when the popover count changes (see **derive-topics-from-messages**), topics do not always reflect the current message set — an update that keeps the same popover count leaves stale topics in place.
  **Approved**: pending

- **Decision**: The visible-topics stack preserves visited topics rather than replacing the view, and entries are only ever appended, never removed by user action.
  **Rationale**: Supports back-navigation and context stacking, letting users maintain multiple active exploration threads. There is currently no mechanism in the source for a user to remove ("pop" or close) a topic from the stack, and topic recalculation does not remove one either: `visibleTopicIndexes` is written only by an append-only effect, so an entry whose topic no longer exists stays in the stack — it is merely skipped wherever it is consumed, and can silently rebind to whatever topic a later recalculation places at that index (see edge case **Visible topics stack out of bounds**).
  **Approved**: pending

- **Decision**: Only one topic can be active (selected) at a time, even though multiple topics may be visible in the stack.
  **Rationale**: Simplifies focus management and connector rendering. Tradeoff: viewing multiple detail panels simultaneously requires a different pattern or component.
  **Approved**: pending

- **Decision**: Arrow up/down navigate between topics; Tab navigates regions.
  **Rationale**: Reserves arrow keys for topic-scoped navigation while keeping Tab for region-scoped navigation. Traceability: `ThreePaneChat.tsx`, the `handleKey` keydown listener registered in the keyboard-navigation effect.
  **Approved**: pending

- **Decision**: Single-character keystrokes (not ctrl/meta/alt) auto-focus the chat input, and the triggering character is delivered into the input rather than discarded.
  **Rationale**: Supports rapid-fire text input without requiring an explicit focus click, common in chat UX. Traceability: `ThreePaneChat.tsx`, the single-character branch of the `handleKey` keydown listener. The topics pane has no letter-search feature of its own, so this heuristic never competes with one — a pressed letter always ends up in the chat input.
  **Approved**: pending

- **Decision**: The connector-drawing component takes an array of `ConnectorPair` objects (from/to IDs), not direct node references.
  **Rationale**: Decouples connector rendering from pane element structure and allows connector updates without querying the DOM. Traceability: `ThreePaneChat.tsx`, the `connectorPairs` computation.
  **Approved**: pending

- **Decision**: The component delegates layout visibility and height recalculation to a dedicated layout hook (`useThreePaneLayout` on web) that measures the frame and available space.
  **Rationale**: Keeps the component focused on state and user interaction while delegating layout logic to a specialized hook. See requirement **recalculate-layout-on-image-load**.
  **Approved**: pending

- **Decision**: The Apple (AppKit) implementation, `ThreePaneChatView.swift`, currently renders `InlineChatView` instead of a full three-pane layout.
  **Rationale**: Keeps `PersonaChatMode` total so hosts can compile against the full mode enum today. The three-pane port — equivalents of TopicsPane, DetailPane, PanelStack, and ConnectorSVG — is deferred deliberately rather than shipped half-built. See the **AppKit / UIKit** platform note.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | failed | Accessibility |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | failed | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.user-safety.harmful-content-filtering](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0ba78b76-8359-58e4-b507-2d5a61848d33) | partial | User Safety |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on the web source: `TopicsPane.tsx`/`DetailPane.tsx` render plain `<button>`/`<a>`/`<ul>` markup with no ARIA roles or `aria-live` announcements (screen-reader-support, semantic-markup); the keydown handler in `ThreePaneChat.tsx` makes all navigation reachable from the keyboard (keyboard-navigable); `three-pane.css` mixes `rem` and hardcoded `px` font sizes (dynamic-type-support), uses theme-variable colors whose contrast can't be verified from source alone (contrast-ratio), sizes `.pc-topic-item` well under 44px tall (touch-target-size), and transitions pane opacity/background/border with no `prefers-reduced-motion` query (reduced-motion); focus is redirected to the chat input on a plain keystroke without a dedicated focus-region scope (focus-management); `DetailPane.tsx` renders `link.url` and `img.src` directly with no scheme or origin validation (input-sanitization); the four Logging events log only counts and numeric indices, never message or topic text (secure-log-output, no-pii-in-logs); topic/link/image content is rendered as received from the chat backend with no filtering in this component (harmful-content-filtering); and `TopicsPane.tsx`/`DetailPane.tsx` hardcode the English strings "Topics", "Details", and "Links" (string-externalization) while otherwise rendering arbitrary message/topic text through React, which handles the full Unicode range natively (unicode-support); `separation-of-concerns` is `partial` because `TopicsPane`/`DetailPane`/`PanelStack` are split out, but the topic-derivation and stack-mutation logic (see **derive-topics-from-messages**) lives inline in `ThreePaneChat.tsx`'s effects rather than an extracted hook, and the only Apple source is a stub that renders `InlineChatView` instead of this layout; `unit-test-coverage` is `partial` — `ThreePaneChat.test.tsx` covers basic derivation and selection, but neither the stale-visible-topics-stack behavior nor the popover-count-gated recompute this revision documents had a prior test vector, and the Apple stub has none.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | derive-topics commits only on popover-count change; stale stack entries doc'd; vector 016 added. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and merged the duplicate arrow-key requirements; corrected the input-focus-keystroke swallow and documented that arrow-key navigation is global (not input-scoped), fixing the contradicting edge case and vectors; disambiguated the clamp-vs-wrap and no-topic-click vectors; removed web-internal identifiers from cross-platform requirements and edge cases; replaced line-number traceability with file/symbol citations and fixed the wrong source filename; corrected the WinUI 3, UIKit, SwiftUI, and Compose platform notes to real APIs; added depends-on links to the sub-pane recipes, a Localization table for the required announcements, and a Compliance table; fixed the "vertically stacked" overview contradiction and the detail-pane/detail-panel terminology; removed the keystroke-capturing property from analytics and marked all analytics events as unimplemented/optional; dropped the unsupported topic-removal claim from Design Decisions and recorded the Apple stub as a known gap; split the Keyboard Focus state and named the shared background token. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
