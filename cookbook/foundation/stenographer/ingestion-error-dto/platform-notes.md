
- **SwiftUI**: A consumer view can bind an error list to `IngestionErrorDTO` rows, a badge counts those with `exhausted` true, and a Retry All sheet polls `RetryProgressDTO` into a `ProgressView`.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; optional fields are nullable with a default of null; model `status` as a String with a helper enum for the five known values.
- **React/Web**: TypeScript interfaces with `lastRetriedAt: string | null`; a polling hook (interval plus `running` check) stands in for the progress poll.
- **AppKit / UIKit**: Bind `IngestionErrorDTO` rows to an `NSTableView` data source (or `UITableView` on iOS), and drive an `NSProgressIndicator` (or `UIProgressView`) from `RetryProgressDTO` by polling until `running` is false; the structs are `Codable` and `Sendable`, so they cross XPC as payloads.
- **WinUI 3**: Use C# records with `System.Text.Json` (`string?` and `int?` for the optionals); `HttpClient` calls the log route; a `DispatcherTimer` or `PeriodicTimer` polls progress until `Running` is false and updates `ObservableCollection` rows and a `ProgressBar` (`Maximum` from `Total`, `Value` from `Processed`); an `InfoBadge` over the nav item shows the exhausted count.

