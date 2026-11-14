
- **SwiftUI**: Source is `macOS/Features/TerminalSession/TerminalChatToolSource.swift`, with no view code; the persona terminal chat view controller creates it with a closure that finds the pane's Terminal Chat. It conforms to `ChatToolSource` from the core framework and builds schemas with `ToolJSONSchema`.
- **Compose**: Implement the same tool-source interface with three tool definitions whose parameters are JSON Schema strings, and a `suspend` call that obtains the chat from a `suspend () -> TerminalChat?` function on `Dispatchers.Main`.
- **React/Web**: A web persona chat would define the three tools as JSON Schema entries and a handler that awaits a `() => Promise<TerminalChat | undefined>` supplied by the host, returning `{ content, isError }`.
- **AppKit / UIKit**: The source is Foundation-only Swift marked `@unchecked Sendable`, with the closure hop to `@MainActor`. iOS has no shell to connect to, so it does not apply there.
- **WinUI 3**: Implement `IChatToolSource` with a `Func<Task<TerminalChatSession?>>` that dispatches to the UI thread through `DispatcherQueue.TryEnqueue` and a `TaskCompletionSource`. Return `ToolDefinition` records with schemas built by `System.Text.Json.Nodes.JsonObject`, parse the arguments with `JsonDocument.Parse` inside a `try`, and return a `(string Content, bool IsError)` tuple.

