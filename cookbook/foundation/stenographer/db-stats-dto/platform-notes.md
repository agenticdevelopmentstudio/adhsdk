
- **SwiftUI**: A diagnostics view lists the two arrays in a `Table` or `List`, one row per pool.
- **Compose**: Kotlin data classes with `kotlinx.serialization`; `Int` becomes `Long`, because Swift `Int` is 64-bit on Apple platforms and counters could overflow a 32-bit `Int`; `Double` stays `Double`; the property names are the JSON keys.
- **React/Web**: TypeScript interface with `write: Pool[]` and `read: Pool[]`; all numbers are `number`.
- **AppKit / UIKit**: The types are UI-agnostic; an AppKit or UIKit diagnostics panel reads the two arrays into an `NSTableView` or `UITableView`, one row per pool. Public memberwise initializers must be written out by hand in Swift because synthesized ones are internal.
- **WinUI 3**: Use C# records (`public sealed record DbStats(IReadOnlyList<Pool> Write, IReadOnlyList<Pool> Read)` and a nested `Pool` record with `int` and `double` members) and `System.Text.Json` with `JsonNamingPolicy.CamelCase`; bind the lists to a `DataGrid` or `ListView` through an `ObservableCollection` when the view refreshes; `HttpClient.GetFromJsonAsync` reads the endpoint.

