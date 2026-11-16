
- **SwiftUI**: a `List` with `.onMove` and a `Picker` per row would serve; this toolkit's views are AppKit.
- **Compose**: a reorderable `LazyColumn` with a dropdown per row.
- **React/Web**: a sortable list with a `<select>` per row.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitRebaseEditorViewController: NSViewController` in `AgenticDeveloperHubSDKMacOS`, over a `ThemedTableView` with a local pasteboard type; `GitRebasePlan` and `GitRebaseEntry` in `AgenticDeveloperHubSDKCore`. The window's `GitAlertPresenter.editRebase(_:)` shows it as a sheet.
