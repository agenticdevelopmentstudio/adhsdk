
- **SwiftUI**: The source is `APITransport`, `DaemonContract` and `TransportResolver` in the
  hub client package. It is UI-framework-agnostic — `APITransport` is a plain `Sendable` struct
  and `TransportResolver` a plain `actor`, with no dependency on SwiftUI. A
  SwiftUI host typically calls `await TransportResolver().resolve()` (or
  `ADHClient.resolved(using:)`) once at app-launch time, from a `.task`
  modifier or an `@Observable` view model's initializer, and stores the
  resulting `ADHClient`/`TransportKind` in state.
- **Compose**: Model `TransportKind` as a two-case `enum class` and
  `APITransport` as a `data class` carrying `kind`, `serverURL: String`
  (or `okhttp3.HttpUrl`), and the chosen HTTP client/interceptor. Port the
  probe with `OkHttpClient`/Ktor's client configured with matching connect
  and read timeouts, and model `TransportResolver` as a class backed by a
  `Mutex` (or a single-threaded `CoroutineDispatcher`) guarding the cached
  `TransportKind` — the direct analogue of the source's actor isolation.
  Use `DataStore`/`SharedPreferences` for the `useDirectMode` equivalent.
- **React/Web**: No TypeScript/web implementation of this component exists
  yet in this repo. A port would use `fetch` with an `AbortController`
  driving the probe's timeout, and a module-level (or class-held) cached
  `TransportKind` guarded by ordinary single-threaded JS execution (no actor
  needed). The Daemon path itself does not translate directly to a browser:
  fetching `http://127.0.0.1:<port>` from an `https://` page is blocked by
  mixed-content and CORS policy in every major browser, so a browser-hosted
  port would need either an HTTPS-fronted local proxy or to drop the Daemon
  path entirely — a genuine platform divergence, not an oversight in this
  ingredient.
- **AppKit / UIKit**: Same underlying Swift package as the SwiftUI note
  above — `APITransport`/`TransportResolver` make no distinction between
  SwiftUI and an imperative AppKit/UIKit host. A UIKit/AppKit call site
  awaits `resolve()`/`ADHClient.resolved(using:)` from a `Task` launched in
  `viewDidLoad`/`applicationDidFinishLaunching` and stores the resulting
  client on the owning controller.
- **WinUI 3**: Model `TransportKind` as a two-case `enum`, and `APITransport`
  as a `record` (or plain class) carrying `Kind`, `Uri ServerUrl`, and an
  `HttpClient` (two named/keyed `HttpClient` instances — one for the backend
  base address, one for the loopback daemon base address — mirror
  Direct/Daemon). Use `System.Text.Json` with `JsonSerializerOptions` left at
  its default (which already ignores unknown members, matching
  health-status-decoding) to model `HealthStatus`. Model `TransportResolver`
  as a class exposing `Task<TransportKind> ResolveAsync()`/
  `ReresolveAsync()`, guarding its cached field with a `SemaphoreSlim(1,1)`
  or `lock` — .NET has no actor primitive, so this lock stands in for actor
  isolation. Mirror the Swift reference on the concurrent-`resolve()` race
  (see the concurrent-resolve open question in Edge Cases): do not coalesce
  overlapping first-time calls into one in-flight `Task` until that question
  is settled for every platform. Drive the probe's timeout with a
  `CancellationTokenSource` (`CancelAfter(probeTimeout)`) rather than
  `HttpClient.Timeout`, so a single `HttpClient` instance can serve probes
  with different timeouts. Use
  `Windows.Storage.ApplicationData.Current.LocalSettings` for the
  `useDirectMode` equivalent. `ObservableCollection`/`INotifyPropertyChanged`
  are unnecessary — nothing in the source makes `TransportResolver`'s
  decision observable; a caller reads `CachedKind`/awaits `ResolveAsync()`
  on demand.

