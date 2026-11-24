
- **SwiftUI**: Source is `Core/Partner/PartnerProcessConfiguration.swift`, a `public struct` importing only `Foundation`; nothing is UI-specific. Tests are in `PartnerProcessConfigurationTests`.
- **Compose**: A Kotlin data class with a computed `arguments` property returning `List<String>` built with `buildList`; `java.util.UUID.toString()` is already lowercase.
- **React/Web**: A plain object and a function returning `string[]`; a browser cannot launch a process, so this is Node only, and a UUID string is lowercased with `toLowerCase()`.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic.
- **WinUI 3**: A C# `record` with a computed `IReadOnlyList<string> Arguments` built into a `List<string>`; `Guid.ToString()` is lowercase by default (the `D` format). Hand the list to `ProcessStartInfo.ArgumentList` rather than joining it into `ProcessStartInfo.Arguments`, so entries with spaces stay single arguments; `ProcessStartInfo.WorkingDirectory` takes `workingDirectory`.

