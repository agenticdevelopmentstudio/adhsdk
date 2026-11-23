
- **SwiftUI**: Not used here; the app's Terminal Chat panes are served by the tools and need no change to be driven.
- **Compose**: a Kotlin port keeps the same field names as `kotlinx.serialization` data classes; the five actions and the resolver are plain logic.
- **React/Web**: a TypeScript port keeps the same field names as interfaces and the resolver as a pure function; the transport is the host's MCP server.
- **AppKit / UIKit**: The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalChatControl.swift`: a caseless `public enum` with nested `Codable` types, the `Defaults` constants and `resolve`.
- **WinUI 3**: Use C# `record` types with `System.Text.Json` and the same property names, and the resolver as a static method; the transport is the host's MCP server.

