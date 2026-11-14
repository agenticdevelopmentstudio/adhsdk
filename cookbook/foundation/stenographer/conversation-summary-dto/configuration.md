
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| homeDirectory | String | `NSHomeDirectory()` | Home used to write paths `~`-relative. |
| liveSessions | array of `SessionDTO` | none (caller supplies) | Active sessions the pane-sharer check reads. |
| attachment | `AttachmentProbe` | `ConversationSendability.processAttachment` | Reports whether a session's process has a terminal; nil when unreadable. |


`baseBranches` is a fixed constant (see **base-branches**), not an option.
