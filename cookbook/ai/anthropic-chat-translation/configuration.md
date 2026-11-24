
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` (request) | text | none (required) | Provider model name placed in the Chat Completions request. |
| `maxTokensKey` | text | `max_tokens` | Name under which the request's `max_tokens` is written; a provider using `max_completion_tokens` passes that name. |
| `fallbackModel` | text | none (required) | Model reported when the reply names none. |
| `status`, `body` | integer, bytes | none (required) | Provider HTTP status and body for `anthropicError`. |
| stream `model` | text | none (required) | Model named in `message_start`. |
| stream `messageID` | text | `msg_` plus a hyphenless UUID | Message id in `message_start`. |

