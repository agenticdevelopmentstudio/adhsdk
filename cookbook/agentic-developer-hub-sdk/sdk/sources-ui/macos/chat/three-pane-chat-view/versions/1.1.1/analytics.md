
None of the following events are emitted by the current source (no analytics or tracking calls exist in `ThreePaneChat.tsx` or its sub-components); they are proposed instrumentation points and MAY be implemented by consumers.

| Event | Properties | When |
|-------|-----------|------|
| `three_pane_chat.topic_selected` | `{ topicIndex: number, messageIndex: number }` | User selects a topic in the topics pane |
| `three_pane_chat.message_clicked` | `{ messageIndex: number, hasAssociatedTopic: boolean }` | User clicks a message in the transcript |
| `three_pane_chat.keyboard_navigation` | `{ direction: "up" \| "down", fromTopicIndex: number, toTopicIndex: number }` | User navigates between topics using arrow keys |
| `three_pane_chat.input_focus_keystroke` | `{}` | User presses a keystroke that auto-focuses the chat input |

