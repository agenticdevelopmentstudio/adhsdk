
- **SwiftUI**: Not used; the types have no view layer.
- **Compose**: Kotlin `data class` with `val` string properties, which gives structural equality and immutability; the session id is a computed property.
- **React/Web**: Readonly TypeScript interfaces or frozen object literals with string fields; a plain function returns the `app:` prefix plus the span id, since object equality is by reference and a comparison helper is needed.
- **AppKit / UIKit**: `BillingAppSpanRow` and `BillingIdleInterval` in `Core/Billing/BillingAppSpans.swift`, public structs conforming to `Sendable` and `Equatable`, with explicit public memberwise initializers (a public struct gets no public memberwise initializer for free) and a `swiftlint` identifier_name suppression on `tz` and `startedAt`; `ActivitySpanSession` lives in `Core/WorkTracking/WorkTrackingModels.swift`.
- **WinUI 3**: C# `record` or `readonly record struct` types with `init`-only string properties, which give value equality and immutability; a `SessionId` property returns `"app:" + Id`. Use `string.Empty` for the sentinels and parse timestamps with `DateTimeOffset.TryParse` in the consuming code, not in the type. Records are safe to share across `Task` boundaries.

