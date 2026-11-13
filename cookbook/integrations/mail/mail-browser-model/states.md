
| State | Appearance change |
|-------|------------------|
| Default | Not applicable: the model has no appearance. Data state: `accounts` and `messages` are empty, `selectedMailbox` and `selectedMessageId` are nil, `hasMore` and `loading` are false and `errorMessage` is nil. |
| Pressed | Not applicable: the model is not a control. |
| Disabled | Not applicable: the model has no disabled state. |
| Focused | Not applicable: the model takes no focus. |
| Loading | `loading` is true for the length of `reload` only. `select(mailbox:)`, `loadMore` and `select(messageId:)` do not set it. |
| Error | `errorMessage` holds the latest failure's `localizedDescription` until `dismissError` or the next failure replaces it; a later success does not clear it. |
| No accounts | `accounts` is empty, `selectedMailbox` is nil and the list and open message are empty. |
| Mailbox selected | `selectedMailbox` is set and `messages` holds the loaded pages; `hasMore` is true while a next cursor exists. |
| Message open | `selectedMessageId` is set; `openedMessage` is nil until the full message loads. |

