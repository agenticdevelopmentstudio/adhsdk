
- **SwiftUI**: Not used; an error list binds to `IngestionErrorDTO` rows, a badge counts those with `exhausted` true, and a Retry All sheet polls `RetryProgressDTO` into a `ProgressView`.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; optional fields are nullable with a default of null; model `status` as a String with a helper enum for the five known values.
- **React/Web**: TypeScript interfaces with `lastRetriedAt: string | null`; a polling hook (interval plus `running` check) stands in for the progress poll.
- **AppKit / UIKit**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/IngestionErrorDTO.swift`: three `Codable`, `Sendable` structs without `Equatable`, with explicit public initializers; the XPC side needs these to cross as `Codable` payloads.
- **WinUI 3**: Use C# records with `System.Text.Json` (`string?` and `int?` for the optionals); `HttpClient` calls the log route; a `DispatcherTimer` or `PeriodicTimer` polls progress until `Running` is false and updates `ObservableCollection` rows and a `ProgressBar` (`Maximum` from `Total`, `Value` from `Processed`); an `InfoBadge` over the nav item shows the exhausted count.

