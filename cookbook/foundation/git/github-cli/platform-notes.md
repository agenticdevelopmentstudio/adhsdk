
- **SwiftUI**: `Core/Git/GitHubCLI.swift` and `Core/Git/GitPullRequest.swift` import only Foundation. `GitHubCLI` is a `public actor`; a SwiftUI caller drives it from a cancellable task and treats `CancellationError` as its own.
- **AppKit / UIKit**: Identical to the SwiftUI note. The runner type is `@Sendable (URL, [String], URL, [String: String], Duration) async throws -> SubprocessChannel.RunResult`; the default runs `SubprocessChannel.run` with `.mergeOverParent` and the budget in seconds. A budget overrun arrives as `WallClockBudgetExceeded`. `GitPullRequest` is `Sendable, Hashable, Identifiable, Decodable`, decoding the date itself with `Date.ISO8601FormatStyle`, so it needs no decoder strategy.
- **Compose**: A class with a suspend function per verb over an injected `ProcessBuilder` runner and `kotlinx.serialization` models; the budget is `withTimeout`.
- **React/Web**: Not applicable in a browser (no process). In Node, `child_process.execFile` with `env` and `timeout`, and `JSON.parse` of standard output.
- **WinUI 3**: `Process` with `RedirectStandardOutput`/`RedirectStandardError`, the three variables in `Environment`, and `System.Text.Json` models.

