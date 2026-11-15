
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

