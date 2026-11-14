
- **SwiftUI**: The source file `Core/Routing/InvalidTimestamp.swift` imports only `Foundation` and is UI-independent, so a SwiftUI host uses it unchanged. It is a `public struct` conforming to `Error`, `Equatable` and `CustomStringConvertible`; `Equatable` is synthesized from the single stored property.
- **Compose**: A Kotlin `data class InvalidTimestamp(val message: String)` gives value equality and a `toString` override that returns `message`. To use it in a result type, return `Result.failure` with an exception subclass, or a sealed result class; Kotlin's `Throwable` carries a `message` already.
- **React/Web**: A small class extending `Error` with the `message` field, or a plain frozen object `{ message }` in a discriminated union; compare by `message` since JavaScript has no synthesized value equality.
- **AppKit / UIKit**: Identical to the SwiftUI note: the file is UI-framework-agnostic and only the embedding application differs, never this contract.
- **WinUI 3**: A C# `record InvalidTimestamp(string Message)` gives value equality; override `ToString()` to return `Message`. A .NET port that needs it throwable derives from `Exception` (passing `Message` to the base constructor); otherwise return it through a result type. Equality on an exception subclass is by reference unless overridden, so keep the record shape for the value contract.

