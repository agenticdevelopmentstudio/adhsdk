
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `labelIds` | `[String]` | none (required argument) | The Gmail label ids of one message, as returned by the Gmail API. |
| `MailClassifier.systemLabelIds` | `Set<String>` | `INBOX`, `SENT`, `DRAFT`, `STARRED`, `SPAM`, `TRASH`, `UNREAD`, `IMPORTANT`, `CHAT` | Public constant; the ids Gmail owns. Not configurable at runtime. |

No environment variables, settings keys or injected dependencies. Whether a class is mirrored is configured elsewhere, in `MailSyncSettings`.

