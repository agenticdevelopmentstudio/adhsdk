
- **SwiftUI**: Source is `Core/Stenographer/StenographerWire.swift`, a caseless `enum` with two `static` functions using `JSONEncoder.keyEncodingStrategy`, `JSONDecoder.keyDecodingStrategy` and the `iso8601` date strategies from `Foundation`. Nothing is SwiftUI-specific.
- **Compose**: Use kotlinx.serialization `Json` with `namingStrategy = JsonNamingStrategy.SnakeCase` and `explicitNulls = false`, with a serializer for ISO-8601 dates (`java.time.Instant`). Define it once in a single holder object.
- **React/Web**: Write one pair of functions that map keys between camelCase and snake_case and convert `Date` to and from `toISOString()`; nothing else in the app should call `JSON.stringify` on a DTO directly.
- **AppKit / UIKit**: Same source and calls; `Foundation` behaves the same on iOS and macOS.
- **WinUI 3**: Use `System.Text.Json.JsonSerializerOptions` with `PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower`, `DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull` and a `JsonConverter<DateTime>` for ISO-8601, exposed through a static factory that returns a new options object. `System.Text.Json` accepts fractional seconds in ISO-8601 dates, which the source's strategy does not; keep that difference in mind if a test asserts the failure.

