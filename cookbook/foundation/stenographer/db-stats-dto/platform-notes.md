
- **SwiftUI**: Not used; a diagnostics view lists the two arrays in a `Table` or `List`, one row per pool.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; `Int` becomes `Int` or `Long`, `Double` stays `Double`; the property names are the JSON keys.
- **React/Web**: TypeScript interface with `write: Pool[]` and `read: Pool[]`; all numbers are `number`.
- **AppKit / UIKit**: The source is `packages/apple/AgenticDeveloperHubSDK/Core/Stenographer/DBStatsDTO.swift`: `Codable`, `Sendable` structs with a nested `Pool`, no `Equatable`, and public memberwise initializers written out by hand because synthesized ones are internal.
- **WinUI 3**: Use C# records (`public sealed record DbStats(IReadOnlyList<Pool> Write, IReadOnlyList<Pool> Read)` and a nested `Pool` record with `int` and `double` members) and `System.Text.Json` with `JsonNamingPolicy.CamelCase`; bind the lists to a `DataGrid` or `ListView` through an `ObservableCollection` when the view refreshes; `HttpClient.GetFromJsonAsync` reads the endpoint.

