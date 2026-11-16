
- **SwiftUI**: `Core/Process/ExecutableLocator.swift` imports only Foundation; a SwiftUI host uses it unchanged. It is a `public struct ExecutableLocator: Sendable` whose `isExecutable` is an `@Sendable (String) -> Bool`.
- **AppKit / UIKit**: Identical to the SwiftUI note; the file is UI-framework-agnostic. On iOS there is no `PATH` worth walking and no process to spawn, so the type has no use there.
- **Compose**: A data class holding the environment map, the extra directories and a `(String) -> Boolean` check; `File(dir, name).canExecute()` is the default check.
- **React/Web**: Not applicable in a browser. In Node, split `process.env.PATH` on `path.delimiter` and test with `fs.accessSync(candidate, fs.constants.X_OK)`.
- **WinUI 3**: Split `PATH` on `;`, try each `PATHEXT` extension per directory, and replace the default extra directories with the platform's install roots.

