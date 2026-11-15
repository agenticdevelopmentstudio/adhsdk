
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
Divergences below). `ScriptedBackend` (Swift, `Sources/Backend/ScriptedBackend.swift`) is the one
concrete conformer this ingredient specifies; it is the toolkit's own scripted/mock `Backend`, shipped
so a consumer can exercise the contract with no live endpoint configured. The
contract carries no message history and no credentials: `Backend.send`
receives only the new message and its attachments, never a transcript.
persona-chat ([adhsdk.ingredient.chat.modes.persona-chat](cookbook:447d0e33-c66e-4bf9-8511-e7823bdbcf9b)) builds a real, network-backed `Backend` on top of this same
contract; chat-input-field ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.sources-ui.macos.chat.chat-input-field](cookbook:0ae70642-28e7-436a-b934-0b445652ac09)) and chat-window-controller ([adhsdk.ingredient.agentic-developer-hub-sdk.sdk.sources-ui.macos.chat.chat-window-controller](cookbook:91114bf5-ad41-4cbd-b91b-c49bba9625d5)) are UI components a host
assembles around a `ChatViewModel` this contract defines.

