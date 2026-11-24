
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

