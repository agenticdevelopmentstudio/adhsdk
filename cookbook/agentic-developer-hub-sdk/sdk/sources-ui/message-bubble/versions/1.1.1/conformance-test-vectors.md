
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

