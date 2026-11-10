
`chat-coordinator-projection` is the read-only translation layer between the chat package's portable contract (`ChatViewModel`, `Message`, `ActiveDraft`, `ActiveCommand`, `Attachment`) and the web transcript's display model (`ChatMessage`). It has two responsibilities, implemented as pure functions with no I/O of their own:

- `projection/toChatMessages.ts` — `projectMessages` flattens `ChatViewModel.messages` and `ChatViewModel.activeDrafts` into a single ordered `ChatMessage[]`, folding in `activeCommands` for a still-open draft's tool-call display; `draftMessageID` gives a draft's projected id a stable, participant-keyed form.
- `projection/richContent.ts` — `encodeRichDisplay`/`decodeRichDisplay` carry web-only display extras (`content`, `popover`, `toolCalls`) through the portable `Attachment` vocabulary under the vendor media type `RICH_DISPLAY_MEDIA_TYPE`, so a backend can attach transcript-only data without the contract itself knowing about it.

Its only caller is `hooks/useChatSession.ts`, which supplies the `StampFor` clock and re-runs the projection on every `ChatUpdate`.

