
- **SwiftUI**: A `List` with `Section`s and `.badge(_:)` would serve; this toolkit's views are AppKit.
- **Compose**: A `LazyColumn` with sticky headers; the badge as trailing text.
- **React/Web**: A listbox with grouped options; the badge as a trailing span.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitRefsSidebarViewController: NSViewController` in `AgenticDeveloperHubSDKMacOS`, hosting a `TopicListViewController` as a child; `@MainActor public final class GitHistoryViewController: NSViewController` on a `ThemedTableView`, and `public enum GitHistorySearch` in `AgenticDeveloperHubSDKCore`. UIKit: not applicable (no git on iOS).
- **WinUI 3**: A `ListView` with grouped items.

