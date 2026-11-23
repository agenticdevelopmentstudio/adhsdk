
- **SwiftUI**: Source is `macOS/Features/TerminalSession/TerminalChatDirectory.swift` and `TerminalChatDirectoryToolSource.swift`, with no view code, so a SwiftUI app uses them unchanged; create the directory once, pass it to panes and register `TerminalChatDirectoryToolSource(directory:)` with the app's MCP host. The protocol is `Core/Terminal/TerminalChatControl.swift`.
- **Compose**: Hold a main-dispatcher-confined map of `WeakReference` chat entries, expose each tool through the app's MCP tool registry, and use `withTimeout` for the settle and timeout values.
- **React/Web**: Hold chats in a `Map` of `WeakRef`, register the five tools with the MCP server SDK's `server.tool(...)`, and clamp numbers with `Math.min(Math.max(...))`.
- **AppKit / UIKit**: The source is main-actor Swift using `Foundation` only; the tool source is `@unchecked Sendable` and hops to the main actor for every read and call.
- **WinUI 3**: Keep the directory as a `Dictionary<string, (Listing, WeakReference<TerminalChatSession>)>` on the UI thread, marshal each tool call there with `DispatcherQueue.TryEnqueue` and a `TaskCompletionSource`, and clamp settle and timeout with `Math.Clamp` into a `TimeSpan`.
