
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

