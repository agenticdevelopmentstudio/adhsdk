
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `client` | `MailClient` | none (required) | The mail service client every tool call goes through; supplied to `init(client:)` |
| `limit` | integer | 50 | `mail_list_messages` page size, 1 to 500 |
| `include_bodies` | boolean | false | Whether list and thread results carry message bodies |
| `from` | string array or absent | absent (INBOX) | Labels `mail_move_messages` removes; empty array removes none |

The component reads no environment variables or settings keys.

