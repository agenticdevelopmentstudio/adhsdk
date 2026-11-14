
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `view` | `Pick<ChatViewModel, 'messages' \| 'activeDrafts' \| 'activeCommands'>` | required | The slice of chat state `projectMessages` reads; only these three fields are consulted. |
| `parts` | `ProjectionParticipants` (`{ persona, user, localParticipantID }`) | required | Which `ChatParticipant` represents the local user versus the persona, and the id that marks a sender as local. |
| `stampFor` | `StampFor` (`(key: string) => Date`) | required | Caller-supplied clock for a message or draft with no timestamp of its own; MUST be stable per key (see **stamp-for-stability**). `useChatSession.ts` backs this with a per-session `Map`. |
| `id` (to `encodeRichDisplay`) | `string` | required | The identifier assigned to the produced `Attachment`; the function does not generate or validate it. |
| `display` (to `encodeRichDisplay`) | `RichDisplay` (`{ content?, popover?, toolCalls? }`) | required | The payload to encode; an all-empty value encodes to `null` rather than an attachment. |
| `attachments` (to `decodeRichDisplay`) | `ReadonlyArray<Attachment>` | required | The list scanned for a rich-display payload; an empty array decodes to `{}`. |
| `RICH_DISPLAY_MEDIA_TYPE` | `string` constant | `application/vnd.adhsdk.rich-display+json` | The vendor media type identifying a rich-display attachment; not caller-configurable, but consumers on either side of the wire rely on its exact value for interop. |

