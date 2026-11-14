
`PersonaChatCoordinator` is the Apple implementation of the
`persona-chat-coordinator` ingredient: a `Backend`-conforming actor that
turns a chat UI's `send`/`inboundEvents` contract into calls against adh's
chat API. adh orchestrates the turn — it resolves the persona from its slug,
assembles the prompt, reads and writes history, calls the provider, and
streams the reply — so the coordinator itself holds no history, no prompt,
and no credentials. It lazily creates one adh conversation per instance,
posts each outgoing message with no history attached, and translates the
resulting Server-Sent Events stream (`open`, `status`, `token`,
`tool_call_started`, `tool_call_completed`, `done`, `error`) into
`InboundEvent` values a consumer such as `ChatViewModel` can render.

`SSEParser` is its private, single-purpose collaborator: an incremental
reader that turns raw byte chunks into complete `event:`/`data:` blocks,
buffering across chunk boundaries so a block split mid-word or
mid-separator is never truncated or duplicated.

