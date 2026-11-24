
`FocusedTopicDetail` is a block in `@adh-sdk/ui` that frames a collection of items of one kind. At any moment the reader is either focused on one item or looking at all of them.

- **Focused**: the rail lists that item's topics, the active topic is selected, and the pane shows a section header followed by whatever the consumer passes as `children`.
- **All** (nothing focused): the topics dim and cannot be chosen, the gold selection bar sits on the selector row, and the pane shows a header and a grid of cards, one per item. Clicking a card focuses that item.

A selector popup at the top of the rail switches between items and All, and can offer a New entry. The block composes four existing blocks and nothing else: `PopupMenu`, `TopicDetail`, `SectionHeader` and `ResourceCard`. It owns no state. The consumer holds `focusedId` and `activeTopicId` and passes the change callbacks. What goes inside the focused pane is the consumer's content.

The source does not implement renaming an item's identifier, deleting an item, an All-view filter, a list or card toggle, or remembering the last focus. A route that wants those builds them around this block.

