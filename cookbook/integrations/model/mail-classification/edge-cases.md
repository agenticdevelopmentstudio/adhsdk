
- **Empty array**: `classify(labelIds: [])` MUST return `.archived`. Gmail messages with no labels are those removed from the inbox with no other label; the test suite pins this.
- **Only attribute labels**: A message with only `UNREAD`, `IMPORTANT`, `CHAT` and `CATEGORY_*` labels MUST return `.archived`.
- **Conflicting labels**: `TRASH` together with `SPAM`, `INBOX` or a user label MUST return `.trash`; `SPAM` together with `INBOX` MUST return `.spam`. Both are pinned by the test suite.
- **Duplicate ids**: Repeated ids MUST NOT change the result.
- **Unknown or future system label**: A Gmail label id outside `systemLabelIds` and without the `CATEGORY_` prefix MUST be treated as a user label and classify as `.filed`. The classifier cannot tell it from a user label.
- **Empty or whitespace id**: An empty string, or an id with surrounding whitespace, is not special-cased and is treated as a user label.
- **Case**: Matching is case-sensitive; a lowercase variant of a system id is a user label.
- **Very large arrays**: The cost is linear in the number of labels; there is no cap.
- **Concurrent access**: Not a concern. The function reads only immutable static sets and its argument, and `MailClass` is `Sendable`, so concurrent calls need no ordering rule.
- **Error states, network and offline**: Not applicable. The function does no I/O, takes no dependency that can fail, and never throws.
- **Stale classification**: The class is computed from the label ids at the moment of the call. This file does not recompute it when labels change; a caller that re-fetches a message gets a new result by calling again.

