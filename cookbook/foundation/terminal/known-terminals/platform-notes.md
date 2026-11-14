
- **SwiftUI**: Not used here; a view shows `displayName` for a session's terminal through `ConversationSummaryDTO.terminalName`.
- **Compose**: a Kotlin `data class KnownTerminal(val displayName: String, val bundleId: String, val termProgramValues: List<String>)` and a `val all` list; Android has no bundle ids, so a port keys on the platform's package or process name.
- **React/Web**: a TypeScript interface plus a frozen array, and `catalog.find(t => t.termProgramValues.includes(v))` for the match.
- **AppKit / UIKit**: The source is Swift in `packages/apple/AgenticDeveloperHubSDK/Core/Terminal/KnownTerminals.swift`: a `public struct` with a public memberwise `init`, a caseless `public enum` namespace, and `first { ... }` for the match; the bundle id feeds `NSRunningApplication` lookup in the macOS target.
- **WinUI 3**: Use a C# `record KnownTerminal(string DisplayName, string ProcessName, IReadOnlyList<string> TermProgramValues)` with the process name in place of a bundle id, and `catalog.FirstOrDefault(t => t.TermProgramValues.Contains(v))` for the match; Windows Terminal reports `WT_SESSION` rather than `TERM_PROGRAM`, so a port adds its own detection beside the match.

