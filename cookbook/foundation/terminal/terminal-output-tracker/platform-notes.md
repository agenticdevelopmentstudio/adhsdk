
- **SwiftUI**: Not used here; the chat view shows what the session builds from `newOutput`.
- **Compose**: an immutable Kotlin `data class` with `nextRow: Int?`, `shownPrefix` and `pendingEcho`, whose `noteSent` and `newOutput` return the new state with `copy()` (a copy must carry its own position, as the Swift value type does), `String.trimEnd()` for each row, and `lines` as a `List<String>`.
- **React/Web**: an immutable TypeScript object with the same three fields, replaced on each call (or copied on write), since a shared mutable instance would alias the position that the Swift value type copies; a terminal emulator such as xterm.js supplies the rendered rows through its buffer API.
- **AppKit / UIKit**: This source is platform-neutral Foundation-only Swift with no AppKit or UIKit dependency; it runs unchanged on any Swift platform. The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/TerminalOutputTracker.swift`: two `public struct` types, `trimmingCharacters(in:)` for the echo, and range-mapped row access; the macOS target builds the snapshot from its terminal view.
- **WinUI 3**: Use a C# `struct` or `record struct` with `string.TrimEnd()` per row and `StartsWith` and `EndsWith` with `StringComparison.OrdinalIgnoreCase`; build the snapshot from a ConPTY screen buffer, counting rows from the first line ever scrolled so row numbers stay stable.

