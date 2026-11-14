
- **SwiftUI**: a `WindowGroup(for: URL.self)` with a `NavigationSplitView`; this toolkit's windows are AppKit.
- **Compose**: not applicable (desktop git windows only).
- **React/Web**: not applicable.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitWindowFeature: AppFeature`, `public final class GitWindowController: SingleWindowController`, `GitWindowSplitViewController: ThemedSplitViewController`, the toolbar from `WindowToolbarBuilder`, all in `AgenticDeveloperHubSDKMacOS` (`macOS/Features/Git/Window/`). The window spec persists the frame only: the keyed window set, not the window manager, decides what reopens. UIKit: not applicable.
- **WinUI 3**: a window with a `SplitView`.
