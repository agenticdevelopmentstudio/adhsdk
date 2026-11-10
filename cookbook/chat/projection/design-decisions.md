
**Decision**: Web-only display extras (`content`, `popover`, `toolCalls`) ride through the contract as one `Attachment` under a vendor media type rather than as fields on `Message`.
**Rationale**: The contract's message vocabulary is deliberately portable; a platform that does not recognize the vendor media type can ignore the attachment entirely without knowing anything about it, while `ThreePaneChat` and `InlineChat` build their popover and content rendering entirely from it.
**Approved**: pending

**Decision**: `encodeRichDisplay` returns `null` for an empty payload rather than an attachment carrying `{}`.
**Rationale**: An empty attachment list already spells "no extras"; giving the same state two spellings is one more check every consumer of `Message.attachments` would have to make.
**Approved**: pending

**Decision**: Rich display data is JSON-encoded into an inline attachment rather than mapped onto `AttachmentSource.remote`.
**Rationale**: `remote` holds a parsed `URL`, and a relative `src` — which `ImageContent` permits — has no absolute form until something supplies a base. Lossless beats semantically tidy for a payload whose only reader is the bubble it came from.
**Approved**: pending

**Decision**: A draft's projected id is keyed by participant (`draft:${participantID}`) rather than freshly generated on every update.
**Rationale**: A draft that grows over dozens of `draftUpdated` events keeps one id, and so one React key and one DOM node, across the whole stream; a new id per token would remount the bubble on every character, losing focus, restarting animations, and defeating scroll anchoring.
**Approved**: pending

**Decision**: A draft's `toolCalls` come from the live `activeCommands` channel when any exist for that participant, and from the decoded display payload only otherwise — never merged.
**Rationale**: The live list is the truth while the turn is open; a payload the backend chose to record is the frozen truth once the message has committed. Preferring one over the other, rather than combining them, avoids double-counting or conflicting entries during the handoff between the two.
**Approved**: pending

**Decision**: A rich-display attachment that fails to decode is treated as absent rather than surfaced as an error.
**Rationale**: A hand-rolled attachment under this vendor media type is the sender's bug, not the transcript's; letting a malformed payload throw inside a render pass would take the whole conversation down with it.
**Approved**: pending

**Decision**: The open question on **duplicate-resolved-ids** (colliding resolved ids) is left unresolved by this module rather than guessed at.
**Rationale**: This module does not construct message ids; picking a de-duplication policy here would require guessing which of two colliding messages is canonical, a call only the id's producer — the `ChatViewModel` implementation — can make correctly.
**Approved**: pending

**Decision**: The projection surfaces only the `failed` delivery kind (**delivery-status-projection**); the other `MessageDeliveryStatus` kinds are dropped rather than carried on `ChatMessage`.
**Rationale**: No consumer in the given source reads a "sending" versus "delivered" distinction from `ChatMessage`; whether the transcript should ever show it is a product decision for whoever owns the chat UI contract, not one this projection can make on its own.
**Approved**: pending

**Decision**: `decodeRichDisplay` accepts any non-null value of type `object` from a matching attachment's JSON, including a JSON array, rather than validating against the `RichDisplay` shape.
**Rationale**: `typeof parsed !== 'object'` is JavaScript's coarsest possible type check, but the cost of accepting an unrecognized shape is benign — the decoded value simply carries none of `content`, `popover`, or `toolCalls`, and every dependent field renders as absent, which is indistinguishable from "no extras." The source accepts this rather than adding a schema validator for a payload only its own encoder ever produces.
**Approved**: pending

