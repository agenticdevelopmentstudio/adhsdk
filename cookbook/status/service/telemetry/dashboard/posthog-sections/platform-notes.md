
- **SwiftUI**: Build query strings with plain `String` constants and `Date` formatted by a UTC `ISO8601DateFormatter`; send them with `URLSession` and `async`/`await`. Serialise queries through one `actor`. The shapers are pure functions over `[[Any]]` rows.
- **Compose**: Use `HttpURLConnection` or OkHttp with `withTimeout(45_000)`, and a single `Mutex` around the query call; shapers are pure Kotlin functions over `List<List<Any?>>` with `kotlinx.serialization.json` for the response.
- **React/Web**: Keep the module as is: `fetch` with an `AbortController`, and the shared lease in the fetcher for one query at a time across threads.
- **AppKit / UIKit**: Same as SwiftUI; run the loaders on a background `Task`.
- **WinUI 3**: Use `HttpClient` with a `CancellationTokenSource` of 45 seconds and `System.Text.Json` (`JsonDocument`) for the response; serialise queries with a `SemaphoreSlim(1, 1)` held by the data service, and format the window bound with `DateTimeOffset.UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss")`. Shapers are static methods over `IReadOnlyList<object?[]>` using LINQ `GroupBy` and `OrderByDescending`.

