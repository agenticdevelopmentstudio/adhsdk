
- **SwiftUI**: Not used here; a port would show `displayName` wherever it names a terminal to the user.
- **Compose**: a Kotlin `data class KnownTerminal(val displayName: String, val bundleId: String, val termProgramValues: List<String>)` and a `val all` list; Android has no bundle ids, so a port keys on the platform's package or process name.
- **React/Web**: a TypeScript interface plus a frozen array, and `catalog.find(t => t.termProgramValues.includes(v))` for the match.
- **AppKit / UIKit**: AppKit: feed `bundleID` to `NSRunningApplication.runningApplications(withBundleIdentifier:)` to find a running instance and activate it. UIKit: not applicable, since iOS has no bundle-id lookup of other running apps. The type is a `public struct` with a public memberwise `init` and a caseless `public enum` namespace, and the match is `first { ... }`.
- **WinUI 3**: Use a C# `record KnownTerminal(string DisplayName, string ProcessName, IReadOnlyList<string> TermProgramValues)` with the process name in place of a bundle id, and `catalog.FirstOrDefault(t => t.TermProgramValues.Contains(v))` for the match; Windows Terminal reports `WT_SESSION` rather than `TERM_PROGRAM`, so a port adds its own detection beside the match.

