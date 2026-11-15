
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`separation-of-concerns` passes because the overlay owns only the conversation
(the poll, the narrowed session and the Return rule) and leaves backdrop,
fade and dismissal to the dismissible overlay and rows to the transcript
view. `keyboard-navigable` passes because the composer takes the focus on
presentation and Escape closes from anywhere. `screen-reader-support` is
partial because the source sets an accessibility identifier but no label and
posts no notification when the overlay appears or disappears.

`unit-test-coverage` is `partial`. `Chat/ConversationFocusTests.swift` drives
the overlay through the Conversations feed, and
`ConversationsWindow/ConversationFocusOverlayConformanceTests.swift` builds the
overlay directly and covers every vector (001 to 018) by id. Skipped:
conversation-focus-019 (confines-to-ui-thread), because the overlay is
`@MainActor` and a use from another thread is rejected at build time, so there
is no runtime behavior to observe.
