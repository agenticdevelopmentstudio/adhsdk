
- **SwiftUI**: Model `ErrorIssue` as a `Codable` struct and the section as a value type; the shaping is pure and ports as plain functions over arrays. The cached resolved count is an `actor` holding a task and an expiry date.
- **Compose**: Pure shaping in Kotlin extension functions over `List<ErrorIssue>`; the counter is a class with a `Mutex` and a `Deferred` that is cleared on failure.
- **React/Web**: Keep the module as is; `cachedSingleFlight` is the shared single-flight cache from the `@adh-sdk/deploy-platform/util` package, and `resolvedCounter` is built on it.
- **AppKit / UIKit**: Same as SwiftUI; the shaping runs on a background `Task` and publishes the section to the main actor.
- **WinUI 3**: Records and `System.Linq` (`OrderByDescending`, `GroupBy`) for the shaping, `DateTimeOffset.TryParse` for `isoMs`, and a `Lazy<Task<int?>>` guarded by a `SemaphoreSlim` with an expiry for the single-flight cache; fetch with `HttpClient` and a `CancellationTokenSource` timeout.

