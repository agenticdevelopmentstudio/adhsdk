
The chat contract is the shared logic layer both platforms' chat UIs are built
against: attachments and media, a `Backend` a UI talks through, chat state
(`ChatViewModel`/`ChatUpdate`/`ChatStateObserver`), commands, configuration
(`ChatConfig`/`DisplayConfig`), gating and observing hooks, messages,
conversations and participants, and permissions. It ships in two idiomatic
forms — Swift protocols/enums/structs under
`packages/apple/AgenticDeveloperHubSDK/SDK/Sources/` and TypeScript
interfaces/discriminated unions under
`packages/web/packages/chat/src/contract/` — that agree on shape wherever the
languages allow, and diverge in a small, named set of places (see Cross-Platform
Divergences below). `ScriptedBackend` (Swift) is the one concrete conformer
given as source here; it is the toolkit's own scripted/mock `Backend`, shipped
so a consumer can exercise the contract with no live endpoint configured. The
contract carries no message history and no credentials: `Backend.send`
receives only the new message and its attachments, never a transcript.
`persona-chat` builds a real, network-backed `Backend` on top of this same
contract; `chat-input` and `chat-window-controller` are UI components a host
assembles around a `ChatViewModel` this contract defines.

