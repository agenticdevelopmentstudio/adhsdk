
- **SwiftUI**: Hold the caches in an `actor` per dashboard; `read` returns a snapshot value type, and `Task` plus `async let` run the independent provider refreshes. Observe the snapshot from a view model with `AsyncStream` while `refreshing`.
- **Compose**: Use a repository class with a `CoroutineScope` per cache, `StateFlow` for the snapshot, and `withTimeoutOrNull` for the settle deadline.
- **React/Web**: Keep the module as is: closures over a `Map`, `Promise.race` for settle. A browser client polls the route while `refreshing` is true.
- **AppKit / UIKit**: Same as SwiftUI; run each refresh on a background `Task` and deliver the snapshot to the main actor.
- **WinUI 3**: Register the set as a singleton in the ASP.NET Core `IServiceCollection`; each cache is a class with a `ConcurrentDictionary` of key state and a background `Task` per refresh, and settle uses `Task.WhenAny(refresh, Task.Delay(timeout))`. Routes are minimal API endpoints, and the `IMemoryCache` is not used because the stale-while-revalidate rule keeps stale data on failure.

