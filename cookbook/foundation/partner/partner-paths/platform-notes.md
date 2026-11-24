
- **SwiftUI**: Source is `Core/Partner/PartnerPaths.swift`, a `public struct` importing only `Foundation`; it uses `URL.appendingPathComponent`. Nothing is SwiftUI-specific, so a SwiftUI host passes it to whatever creates files.
- **Compose**: A Kotlin data class holding a `java.nio.file.Path` home and a string token, with computed properties built by `Path.resolve`; data-class equality matches the `Equatable` requirement.
- **React/Web**: An immutable object or class with getters that join segments using a path utility such as `path.join`; Node only, because a browser has no home directory.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic and uses only `Foundation` URLs.
- **WinUI 3**: A C# `record` (value equality for free) over a `string` home path and `string` token, with expression-bodied properties built by `Path.Combine`; the `Windows.Storage` APIs are not needed because nothing is opened. A Windows port decides what the home directory is (`Environment.GetFolderPath` with `SpecialFolder.UserProfile`), and the shared `.claude/skills` location is the one the `claude` CLI reads, so it must stay under that folder.

