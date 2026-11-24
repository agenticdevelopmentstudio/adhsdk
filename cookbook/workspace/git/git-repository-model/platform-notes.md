
- **SwiftUI**: The model could be `@Observable`; this toolkit's views are AppKit and use `observe(_:)` instead.
- **Compose**: A `ViewModel` exposing `StateFlow`s per part, with a `WatchService` on the three directories.
- **React/Web**: Not applicable in a browser. An Electron host runs `chokidar` on the three directories and pushes change kinds over IPC.
- **AppKit / UIKit**: AppKit: `@MainActor final class GitRepositoryModel` in `AgenticDeveloperHubSDKMacOS`; the watcher wraps the toolkit's FSEvents `FileSystemWatcher` (several roots, one stream). UIKit: not applicable (no git on iOS).
- **WinUI 3**: `System.IO.FileSystemWatcher` per directory feeding the same classifier.

