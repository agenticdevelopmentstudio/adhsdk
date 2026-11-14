
- **SwiftUI**: `SessionStatus.swift` in `Core/Sessions` is a Foundation-only `enum` with a `String` raw value. A SwiftUI view should show a label chosen by the view layer and not the raw value.
- **Compose**: Port as a Kotlin `enum class SessionStatus(val raw: String)` with a `fromRaw(String): SessionStatus?` function that returns `null` for an unknown string, matching the failable initializer.
- **React/Web**: Port as a TypeScript string-literal union `"active" | "stale" | "ended"` plus a guard function that narrows an arbitrary string, returning `undefined` or `false` for anything else.
- **AppKit / UIKit**: The same Foundation enum is used unchanged; a table or list cell maps the case to an icon or text. Store and compare the raw string, as the daemon code does.
- **WinUI 3**: Use a C# `enum SessionStatus { Active, Stale, Ended }`. C# enums carry no string raw value, so serialize with `JsonStringEnumConverter` using a camel-case naming policy in `System.Text.Json` to get the lowercase wire strings, and parse an unknown string with `Enum.TryParse` with `ignoreCase: false` to keep the match exact; `Enum.TryParse` accepts numeric strings, so also check `Enum.IsDefined`. For a SQLite column use `Microsoft.Data.Sqlite` and convert at the boundary. Expose the value on a view model through `INotifyPropertyChanged` and bind a glyph or text to it with an `x:Bind` function.

