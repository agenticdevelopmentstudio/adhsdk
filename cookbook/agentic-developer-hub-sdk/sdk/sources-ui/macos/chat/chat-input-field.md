---
id: 0ae70642-28e7-436a-b934-0b445652ac09
title: "Chat Input"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Single-line text input field for composing and sending chat messages."
platforms:
  - typescript
  - web
  - swift
  - macos
tags:
  - chat
  - input
  - form
depends-on: []
related:
  - 91114bf5-ad41-4cbd-b91b-c49bba9625d5
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
references: []
approved-by: ""
approved-date: ""
---

# Chat Input

## Overview

A single-line text input field designed for composing and sending chat messages. The component accepts user text input, validates that the message is not empty, and triggers a send action via an associated send button or Enter key. It supports theming, customizable placeholder text, optional disable state, and platform-specific affordances for send actions. The component explicitly opts out of password manager autofill and iOS contact autofill to prevent unintended mutations of the input field.

## Behavioral Requirements

- **render-input-field**: The component MUST render a text input field that accepts character input from the user.
- **accept-placeholder**: The component MUST accept and display a placeholder string when the input is empty. The default placeholder MUST be "Type a message...".
- **accept-custom-placeholder**: The component MUST allow the placeholder text to be customized via a configuration option.
- **disable-on-empty**: The send button MUST be disabled when the input contains only whitespace or is empty.
- **enable-on-text**: The send button MUST be enabled when the input contains at least one non-whitespace character.
- **send-on-enter**: The component MUST send the message when the user presses Enter (without Shift). On AppKit, Shift+Enter MUST NOT send: the field's delegate only maps the unshifted `insertNewline(_:)` command to a send, so Shift+Enter never reaches it. On web, Shift+Enter is not actually intercepted — `onKeyDown` only calls `preventDefault`/send for `!e.shiftKey` — so with the send button enabled the keystroke falls through to the surrounding `<form>`'s implicit submission and the message is sent and the field cleared, the same as an unshifted Enter; see the Shift+Enter edge case.
- **trim-whitespace**: The component MUST trim leading and trailing whitespace from the message text before sending.
- **clear-on-send**: The component MUST clear the input field after a message is sent.
- **invoke-callback**: The component MUST invoke the `onSend` callback with the trimmed message text when a send action occurs.
- **reject-empty-send**: The component MUST NOT invoke `onSend` if the trimmed message text is empty.
- **support-disabled-state**: The component MUST support a disabled state that prevents typing and sending.
- **show-send-button**: The component MUST render a send button that is visually associated with the input field.
- **receive-autofocus**: The component MUST support an autoFocus option to automatically focus the input field on mount.
- **opt-out-password-manager**: On web, the component MUST set autofill opt-out attributes to prevent password managers from injecting autofill metadata into the input field and form. This is a web-only requirement: native platforms (AppKit, UIKit, WinUI 3) render no DOM for a password manager to scan, so it does not apply there.
- **opt-out-ios-autofill**: On web, the component MUST use a form container with no `name` or `autocomplete` attributes, and MUST set `data-form-type="other"`, to prevent iOS Safari from offering contact autofill. This is a web-only requirement, specific to the DOM-based Safari contact-autofill heuristic described in the React/Web platform note; it does not apply to native AppKit, UIKit, or WinUI 3 controls.
- **provide-accessible-label**: The component MUST provide an accessible label for the input field. On web, the source hardcodes this label as "Message" (`aria-label="Message"`); it is not yet caller-configurable. On macOS, `ChatInputField`/`InlineChatView` set no accessibility label on the input at all — VoiceOver falls back to whatever placeholder text is set, if any — so this requirement is currently unmet on AppKit. See **provide-send-button-label** for the send button's own label, which AppKit does set (`accessibilityDescription: "Send"`).
- **provide-send-button-label**: The send button MUST provide an accessible label ("Send") via `aria-label` (web) or the equivalent native mechanism.
- **provide-input-name**: On web, the input element MUST carry `name="message"` for form submission context; this is separate from — and not one of — the autocomplete/name opt-outs the surrounding `<form>` itself applies under **opt-out-ios-autofill**.
- **support-external-ref**: The component MUST allow the caller to provide an external ref to access the input element directly.
- **retain-text-on-blur**: The component MUST retain the text a user has typed when the input loses focus without a send; nothing in the input clears the field except a completed send.
- **update-theme-while-focused**: On macOS, when the active theme palette changes while the field is focused, the component MUST push the new text color, font, and insertion point color to the live field editor immediately, not only on the next focus change.
- **clamp-block-caret-to-bounds**: On macOS, when `usesBlockCaret` is enabled and the text overflows the field, the block caret MUST stay within the field's clipping bounds rather than being drawn outside it.

## Appearance

The values below are the defaults a themed host applies through the AppKit-only Configuration options (`cornerRadius`, `showsBorder`, `usesBlockCaret`, `caretBlinks`) documented under Configuration. The component itself does not read the active theme for those four properties — whatever constructs the field passes them in; see Platform Notes for how AppKit and web each keep this in sync with the current theme.

- **Corner radius**: 6pt on standard themes; 0pt (squared off) on terminal/retro themes
- **Padding**: 5pt vertical × 8pt horizontal (inset)
- **Font**: Body font from theme palette (size and weight determined by theme; defaults to platform system body)
- **Background**: `chatInputBackground` semantic color (theme-driven; falls back to platform default surface color)
- **Foreground/Text**: `userText` semantic color (theme-driven; typically a light gray on dark theme)
- **Border**: 1pt solid, color is `chatInputBorder` by default; `chatInputFocus` when focused (theme-driven; hidden on terminal themes)
- **Shadow**: None
- **Placeholder color**: `timestampText` semantic color (theme-driven; typically a dimmer gray than user text)
- **Min/Max size**: Single-line height determined by font metrics; width expands to fill container; no maximum width constraint

## States

| State | Appearance change |
|-------|------------------|
| Default | Standard background, border color is `chatInputBorder`, text color is `userText`, placeholder is visible if input is empty |
| Focused | Border color changes to `chatInputFocus`, caret visible (platform-specific: bar on web/iOS/UIKit, block on macOS, system bar on Android) |
| Disabled | Input field is not editable, send button is disabled, visual indication of disabled state (opacity or color dimming per platform) |
| With Text | Send button is enabled |
| Empty/No Text | Send button is disabled, placeholder text visible |
| Block Caret (macOS only) | Character-cell block cursor instead of blinking bar; block can be solid or blinking (configurable per terminal theme) |

## Accessibility

- **Role**: Text input field (semantic role)
- **Label**: MUST have an accessible label. On web, "Message" is hardcoded via `aria-label`. On macOS (AppKit), the source sets no accessible label on the input — a genuine gap; VoiceOver has only the placeholder to fall back on — see **provide-accessible-label**
- **Keyboard navigation**: Input MUST be focusable via Tab key. Send button MUST be keyboard-accessible (Enter triggers send on focused input, or Tab+Space on the button)
- **Announce state changes**: When input transitions to empty → disabled or disabled → enabled, the disabled state of the send button SHOULD be announced to screen readers. Source has no `aria-live` region or equivalent to drive this today; the change is only as announceable as the native `disabled` attribute is when the button itself receives focus.
- **Touch/Click target**: Minimum 44×44pt on iOS; 48×48dp on Android. Send button MUST meet this minimum
- **Color contrast**: Text MUST have sufficient contrast against background per WCAG AA (minimum 4.5:1 for normal text)
- **Don't rely on color alone**: State changes (focused, disabled) MUST use both color and other visual properties (border, opacity) per "Differentiate Without Color" accessibility guidelines

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| chat-input-001 | render-input-field | Component mounts | Input element is rendered and visible |
| chat-input-002 | accept-placeholder | No custom placeholder provided | Input shows default "Type a message..." |
| chat-input-003 | accept-custom-placeholder | Placeholder prop set to "Ask me anything" | Input displays "Ask me anything" when empty |
| chat-input-004 | disable-on-empty | Input is empty | Send button is disabled |
| chat-input-005 | enable-on-text | User types "Hello" | Send button is enabled |
| chat-input-006 | disable-on-empty | User types "   " (spaces only) | Send button is disabled |
| chat-input-007 | send-on-enter | User types "Test" and presses Enter | onSend is called with "Test", input is cleared |
| chat-input-008 | send-on-enter | User types "Test", presses Shift+Enter | AppKit: onSend is NOT called; the text remains exactly "Test" (the delegate maps only unshifted Return to send). Web: onSend IS called with "Test" and the field is cleared — Shift+Enter is not intercepted by `onKeyDown`, so it falls through to the form's implicit submission exactly like an unshifted Enter |
| chat-input-009 | trim-whitespace | User types "  Hello  " and presses Enter | onSend is called with "Hello" (trimmed) |
| chat-input-010 | clear-on-send | Message is sent | Input field is empty, send button is disabled |
| chat-input-011 | reject-empty-send | User types "   " and presses Enter | onSend is NOT called, input is NOT cleared |
| chat-input-012 | support-disabled-state | disabled prop is true | Input cannot be focused or edited, send button is disabled |
| chat-input-013 | show-send-button | Component mounts | Send button is rendered adjacent to input |
| chat-input-014 | receive-autofocus | autoFocus prop is true | Input is focused on mount |
| chat-input-015 | receive-autofocus | autoFocus prop is false (default) | Input is not focused on mount |
| chat-input-016 | opt-out-password-manager | Component renders (web) | Form has `data-form-type="other"`, input has `autocomplete="off"` and password-manager opt-out data attributes |
| chat-input-017 | opt-out-ios-autofill | Component renders on iOS (web) | Form has no `name` attribute, input has no semantic autocomplete hints; iOS does not offer contact autofill |
| chat-input-018 | provide-accessible-label | Component renders (web) or mounts (AppKit) | Web: input has `aria-label="Message"`. AppKit: the input's accessibility label is nil — no `accessibilityLabel`/`setAccessibilityLabel` call exists on `ChatInputField` or its host `InlineChatView`, so this requirement currently fails on macOS |
| chat-input-019 | support-external-ref | inputRef prop provided to component | External ref can access and interact with input element |
| chat-input-020 | support-external-ref | Caller sets `inputRef.current.value = 'Hi'` directly, without dispatching any event | The DOM value updates, but the component's own state does not: `onChange` never runs, `hasText` stays false, and the send button's enabled state is unchanged |
| chat-input-021 | support-external-ref | Caller sets `inputRef.current.value = 'Hi'` then dispatches a native `input` event on the element | `onChange` fires; `hasText` becomes true; the send button becomes enabled, reflecting the programmatic change |
| chat-input-022 | invoke-callback, clear-on-send | User sends "First", then immediately types "Second" and sends again | onSend is called with "First" and separately with "Second"; the input is cleared after each send and the two messages are never conflated |
| chat-input-023 | retain-text-on-blur | User types "Draft" then clicks outside the input without sending | Input still contains "Draft"; the send button's enabled state is unchanged |
| chat-input-024 | support-disabled-state | disabled prop becomes true while the user has unsent text in the field | Input becomes read-only, the typed text is still present, send button is disabled |
| chat-input-025 | update-theme-while-focused | Field is focused (macOS) and the active palette changes | Text color, font, and insertion point color update immediately on the live field editor, without requiring focus to leave and return |
| chat-input-026 | clamp-block-caret-to-bounds | `usesBlockCaret` is true (macOS), text overflows the field width, caret is at the end of the text | The caret layer's frame stays within the field's inset bounds; it is never positioned past the right edge |
| chat-input-027 | provide-send-button-label | Component mounts | Send button has `aria-label="Send"` |
| chat-input-028 | provide-input-name | Component renders (web) | Input has `name="message"` |
| chat-input-032 | render-input-field | User types a message much longer than the field's visible width | Text scrolls horizontally within the input; caret follows the text; no characters are dropped from the underlying value |

## Edge Cases

- **Empty input with whitespace-only entry**: User enters spaces, tabs, or newlines and presses Enter. Expected: onSend is NOT called, input is NOT cleared, send button remains disabled. Behavior: MUST (see **reject-empty-send**; chat-input-011).
- **Rapid successive sends**: User sends a message, input clears, user immediately types and sends again. Expected: Each send is independent, messages are not conflated. Behavior: MUST (see **invoke-callback**, **clear-on-send**; chat-input-022).
- **Focus loss during typing**: User types a message, then clicks elsewhere without sending. Expected: Message text is retained in the field (not lost on blur), can be resumed. Behavior: MUST (see **retain-text-on-blur**; chat-input-023).
- **Disabled state toggle**: Component is disabled while user is typing. Expected: Input becomes read-only, pending text is not lost, send button is disabled. Behavior: MUST (see **support-disabled-state**; chat-input-024).
- **External ref access**: Caller obtains a ref to the input element and sets `.value` directly. Expected: The DOM value updates, but setting `.value` from code does not fire a native `input`/`change` event, so React's `onChange` never runs — the component's `hasText` state and the send button's enabled state do NOT reflect the direct modification. A caller that needs the component to notice a programmatic value change MUST also dispatch a native `input` event on the element after setting `.value`, at which point `onChange` runs normally. Behavior: MUST (see **support-external-ref**; chat-input-020, chat-input-021).
- **Shift+Enter on different platforms**: On AppKit, Shift+Enter is a no-op — the delegate only maps unshifted Return to a send, so nothing sends and the text is unchanged. On web, Shift+Enter is a source bug rather than a no-op: `ChatInput.tsx`'s `onKeyDown` only intercepts `Enter` without `shiftKey`, so with non-empty text the browser's implicit `<form>` submission still fires, and `onSend` is called and the field is cleared exactly as it would be for a plain Enter. Behavior: MUST on AppKit; see **send-on-enter** and chat-input-008 for both platforms' actual results.
- **Password manager attribute injection**: Password manager (Dashlane, 1Password, Bitwarden, Proton Pass) scans the DOM before React hydration. Expected: opt-out attributes prevent injection of autofill metadata. Behavior: MUST (see **opt-out-password-manager**; chat-input-016).
- **Very long message text**: User enters a message much longer than field width. Expected: Text scrolls horizontally within the input; caret follows the text; no character loss. Behavior: MUST (see **render-input-field**; chat-input-032).
- **Theme change during focus**: Theme palette changes (dark → light, or theme swap) while input is focused. Expected: Focus state is retained, border and text colors update immediately, caret appearance updates. Behavior: MUST (see **update-theme-while-focused**; chat-input-025).
- **Block caret with truncated text** (macOS only): Text overflows and is truncated by field width; block caret is visible. Expected: Caret stays within field bounds, does not render outside clipping region. Behavior: MUST (see **clamp-block-caret-to-bounds**; chat-input-026).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| onSend | function(text) | (required) | Callback invoked when a message is sent; receives trimmed message text |
| placeholder | string | "Type a message..." | Text displayed in input when empty |
| autoFocus | boolean | false | Whether to automatically focus the input on mount |
| inputRef | platform ref type | undefined | External ref to access the underlying input element; see Platform Notes for the concrete type per platform (web: `RefObject<HTMLInputElement \| null>`; AppKit: a direct reference to the `NSTextField`/`ChatInputField` instance) |
| disabled | boolean | false | Whether the input is disabled and send is blocked |
| cornerRadius | number (points) | 6 | (macOS AppKit only) Corner radius of input field; 0 for terminal themes |
| showsBorder | boolean | true | (macOS AppKit only) Whether to draw the one-pixel border; false for terminal themes |
| usesBlockCaret | boolean | false | (macOS AppKit only) Whether to use a block caret (terminal style) instead of blinking bar |
| caretBlinks | boolean | true | (macOS AppKit only) Whether the caret (block or bar) blinks or remains solid |

## Deep Linking

Not applicable: Chat Input is a form control, not a navigable view. It does not handle deep links or URL scheme routing.

## Localization

Only the placeholder is caller-configurable today, via the `placeholder` option — it MUST be localizable by the caller (or a localization framework upstream of this component). On web, the "Message" and "Send" accessible labels are presently hardcoded English string literals in source with no override option (`aria-label="Message"`, `aria-label="Send"`); on macOS, only the send button gets a hardcoded label (`accessibilityDescription: "Send"`) — the input has no accessible label to localize at all. See **provide-accessible-label** and **provide-send-button-label**. The table below documents the intended default value and context for each string for a future localization layer or extraction tool; it does not reflect a runtime lookup by key in the current source.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| chat_input_placeholder | "Type a message..." | Placeholder text shown in empty input |
| aria_label_message_input | "Message" | Accessible label for input field on web (source hardcodes the English literal; not yet keyed). AppKit has no equivalent — the input sets no accessibility label at all |
| aria_label_send_button | "Send" | Accessible label for send button (source hardcodes the English literal on both web and AppKit; not yet keyed) |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | (iOS/macOS/web) Block caret SHOULD blink less frequently or not at all when Reduce Motion is enabled; standard bar caret is not animated. Not yet implemented in source — `ChatInputField`'s blink timer runs unconditionally, with no check of the system's reduced-motion preference; the `reduced-motion` compliance check below is marked failed for this gap. |
| Increase Contrast | (iOS/macOS/web) Focus border and interactive state colors SHOULD be more saturated; text contrast ratio SHOULD exceed 7:1 |
| Differentiate Without Color | (iOS/macOS/web) Focus state MUST be indicated by border thickness or pattern change in addition to color; disabled state MUST use opacity or pattern, not color alone |

## Feature Flags

Not implemented in source: No feature flags are used to enable or disable this component.

## Analytics

Not implemented in source: The component does not emit analytics events. Callers MAY wrap the onSend callback to track send actions independently.

## Privacy

- **Data collected**: The message text itself is not collected by the component; it is passed to the onSend callback. The caller is responsible for handling the text (sending, storing, etc.).
- **Storage**: No data is stored persistently by the component. Text in the input field is held in memory only.
- **Transmission**: No data is transmitted by the component itself. The caller determines whether and how to send the message.
- **Retention**: Text is cleared from the input field after send. No logs or history are maintained by the component.

## Logging

Not implemented in source: neither `ChatInput.tsx` (web) nor `ChatInputField.swift`/`InlineChatView.swift` (AppKit) contains any logging call (`console.*`, `Logger`, `os_log`, `print`, `NSLog`). No debug events are emitted for send, rejection, or clearing.

## Platform Notes

- **SwiftUI**: Start from `TextField` with a custom `ViewModifier` to apply semantic colors (background, focus border) from the theme palette, and `.onSubmit` as the send hook (fires on Return). SwiftUI's TextField does not expose the insertion point caret for customization, so a block caret requires wrapping an `NSViewRepresentable` containing the AppKit `ChatInputField` class below. For macOS apps prioritizing terminal aesthetics, the `NSViewRepresentable` route is necessary.
- **Compose**: Start from `BasicTextField` (Compose Foundation) or Material's `OutlinedTextField` with a custom `focusedBorderColor` that maps to the theme palette. Compose's text input does not support a block caret natively; if a terminal theme requires one, implement a custom caret overlay using a `Modifier` and `Brush` drawing. For standard themes, the platform's blinking bar caret is sufficient.
- **React/Web**: Start from an HTML `<input type="text">` element. The component MUST use a form container (not a plain div) to scope autofill classifiers in Safari/iOS. Password manager opt-out is handled via data attributes (`data-form-type="other"`, `data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore`) and the `autocomplete="off"` attribute. The input also carries `name="message"` for form submission context (see **provide-input-name**), independent of those autofill opt-outs. The send button is a form submit button (`type="submit"`) so that Enter and the button both trigger the same code path.
- **AppKit / UIKit**: AppKit uses `NSTextField` with custom `NSTextFieldCell` padding (8pt horizontal, 5pt vertical inset) and a custom block caret layer (`CALayer`) that is positioned and animated independently. UIKit (iOS) uses `UITextField` with a standard keyboard and send button; the block caret feature is macOS-specific and not used on iOS. Both platforms apply theme-driven colors via a `Themeable` protocol observer.
- **WinUI 3**: Start from `TextBox` (for single-line input) with a custom `ControlTemplate` that applies the theme colors to the background, border, and text. Handle `KeyDown`/`PreviewKeyDown` and check for `VirtualKey.Enter` to intercept Enter and avoid sending on Shift+Enter — `CharacterReceived` fires for character input, not the Enter key, and is the wrong event for this. A `Button` styled with the built-in `AccentButtonStyle` serves as the send button. WinUI 3's `TextBox` has no block-caret support; rather than subclassing `TextBox` to draw one, compose an overlay (e.g., a small `Border` positioned on top of the `TextBox` inside a `Grid`) the way the AppKit and web implementations already draw their carets as a layer/element on top of the field, and fall back to the platform's default blinking bar caret when that overlay is absent. The `IsEnabled` property controls the disabled state for both TextBox and Button.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/ChatInputField.swift` | unverified |
| web | `packages/web/packages/chat/src/components/ChatInput.tsx` | unverified |

## Design Decisions

**Decision**: The web component wraps the input in a `<form>` element to prevent iOS Safari from classifying a lone input field against the entire document for autofill purposes.
**Rationale**: A bare input without a form is scoped globally and can trigger contact autofill if the page contains other contact-related content; a form of its own gives the classifier a one-field form that asks for nothing.
**Approved**: pending

**Decision**: The Enter key handler and the send button both trigger form submission, giving keyboard and pointer sends one code path.
**Rationale**: Two independent send paths — an Enter handler calling send logic directly, and a button `onClick` calling it again — could diverge over time; routing both through the same `<form>` submit prevents that.
**Approved**: pending

**Decision**: Whitespace is trimmed only at the point of send, not as the user types.
**Rationale**: The input field shows exactly what the user typed, including leading/trailing spaces, so the user can see what they are about to send; trimming happens once, right before the message leaves the component.
**Approved**: pending

**Decision**: Multiple password-manager opt-out attributes are set (`data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore`), alongside Dashlane's `data-form-type="other"`.
**Rationale**: Each password manager reads its own ignore signal and ignores the others'; broad compatibility requires setting all of them rather than relying on a single standard.
**Approved**: pending

**Decision**: The block caret is implemented as a macOS-specific affordance, drawn by a custom `CALayer` on top of `ChatInputField` (AppKit).
**Rationale**: Terminal themes (old-school-terminal, etc.) want a block caret to match CRT aesthetics; AppKit's field editor does not expose insertion-point-shape customization (`drawInsertionPoint(in:color:turnedOn:)` is not called for a field editor on current macOS), so the caret has to be drawn as the field's own layer instead. Other platforms use their native carets.
**Approved**: pending

**Decision**: On web, the input carries both a `name="message"` attribute and an `aria-label="Message"`; the placeholder is not treated as a substitute for either.
**Rationale**: `name` gives the input identity within its `<form>` for submission context and is unrelated to the DOM-based autofill opt-outs the form's own attributes provide (see **opt-out-ios-autofill**); `aria-label` gives screen readers a stable label that does not depend on the field being empty, unlike a placeholder.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`passed` rows rest on the source directly: the send button's `aria-label`/`accessibilityDescription`, native focusable `<input>`/`<button>` elements plus the Enter-key handler, correct ARIA/HTML usage in `ChatInput.tsx`, no logging of any kind on either platform (so nothing insecure or PII-bearing can reach a log), and a component that only ever holds the in-progress message text in memory. `screen-reader-support` is `partial` rather than `passed`: web sets `aria-label="Message"` on the input, but AppKit's `ChatInputField`/`InlineChatView` set no accessibility label on the input at all, so VoiceOver on macOS falls back to the placeholder alone (see **provide-accessible-label**). `partial` rows otherwise reflect what these two files alone can't settle — actual rendered contrast, touch-target sizing, and Dynamic Type behavior all depend on the CSS/theme layer that sits outside `ChatInput.tsx` and `ChatInputField.swift`; the placeholder is caller-localizable while the web `aria-label` string is still a hardcoded English literal; and the component validates (trims, rejects empty) without doing any broader input sanitization, which is left to whatever renders the sent text. `reduced-motion` is `failed` because `ChatInputField`'s block-caret blink timer runs unconditionally, with no check of the system's reduced-motion preference. separation-of-concerns passes because both `ChatInput.tsx` and `ChatInputField.swift` hold no business logic beyond trimming/sending text and drawing the field's own caret, while unit-test-coverage is partial: `ChatInputFieldTests.swift` thoroughly exercises the Swift field's caret and baseline behavior, but no test file exercises `ChatInput.tsx` at all.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: dropped `must-` prefixes from requirement names and their citations; reformatted Design Decisions into Decision/Rationale/Approved entries and rebuilt Compliance as a linked, source-verified table; added test vectors for previously-untested edge cases and Logging events; corrected the external-ref/`onChange` edge case, the SwiftUI note (`ViewModifier`, `.onSubmit`), and the WinUI 3 note (`KeyDown`/`VirtualKey.Enter`, `AccentButtonStyle`, a composed overlay caret instead of a `TextBox` subclass); scoped the autofill opt-out requirements to web; added `name`/send-button-label requirements and vectors; unified Appearance units to pt; clarified that theme-driven Appearance values are applied through the AppKit Configuration options rather than read internally; and populated `related` with sibling recipes |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed Shift+Enter, aria-label, and Logging sections to split AppKit vs Web; softened screen-reader-support to partial. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
