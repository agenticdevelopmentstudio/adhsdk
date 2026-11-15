
- **SwiftUI**: a `WindowGroup(for: URL.self)` with a `NavigationSplitView`; this toolkit's windows are AppKit.
- **Compose**: not applicable (desktop git windows only).
- **React/Web**: not applicable.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitWindowFeature: AppFeature`, `GitWindowSession`, `public enum GitWindowPanes` (a `ComposableTabLayoutSpec` on `ComposableTabsLayout`), `GitWindowToolbar`, and `NotInRepositoryAlert`, all in `AgenticDeveloperHubSDKMacOS` (`macOS/Features/Git/Window/`); the window is a `ComposableTabsWindowController` from `ProjectWindowManager.openStandaloneWindow`. The keyed window set, not the window manager, decides what reopens. UIKit: not applicable.
- **WinUI 3**: a window with a `SplitView`.
