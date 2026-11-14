
- **SwiftUI**: Not used here; the chat view shows what the session builds from `newOutput`.
- **Compose**: a Kotlin `class` with a `var nextRow: Int?`, `shownPrefix` and `pendingEcho`, `String.trimEnd()` for each row, and `lines` as a `List<String>`.
- **React/Web**: a TypeScript class with the same three fields; a terminal emulator such as xterm.js supplies the rendered rows through its buffer API.
- **AppKit / UIKit**: The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalOutputTracker.swift`: two `public struct` types, `trimmingCharacters(in:)` for the echo, and range-mapped row access; the macOS target builds the snapshot from its terminal view.
- **WinUI 3**: Use a C# `struct` or `record struct` with `string.TrimEnd()` per row and `StartsWith` and `EndsWith` with `StringComparison.OrdinalIgnoreCase`; build the snapshot from a ConPTY screen buffer, counting rows from the first line ever scrolled so row numbers stay stable.

