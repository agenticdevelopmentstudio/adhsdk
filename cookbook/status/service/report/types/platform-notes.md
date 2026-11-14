
- **SwiftUI**: Model the payload as `Codable` structs. `Severity`, `ReportVerdict` and `ReportSourceId` become `String`-backed enums with the same raw values, and `Record<K, V>` becomes `[K: V]`. Decode with `JSONDecoder` and treat an unknown `schema` as unreadable.
- **Compose**: Use `kotlinx.serialization` `@Serializable` data classes with enum classes carrying `@SerialName`. Nullable sections map to nullable properties, and optional fields default to null.
- **React/Web**: Keep the TypeScript declarations as the contract. `as const` tuples give the literal unions, and `typeof REPORT_SCHEMA` pins the schema field. A client should check `schema` before reading the rest.
- **AppKit / UIKit**: Same `Codable` models as SwiftUI; present `verdict` and `findings` as supplied and do not re-sort or re-derive severity.
- **WinUI 3**: Use `System.Text.Json` records with `JsonStringEnumConverter` and `JsonPropertyName` for camelCase names, `Dictionary<string, T>` for the keyed maps and nullable reference types for null sections. On the server side an ASP.NET Core minimal API binds `ReportParams` from the query string and returns a 400 with the same `{ error: { message } }` body for a rejected param.

