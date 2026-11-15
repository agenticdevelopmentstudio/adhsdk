
- **SwiftUI**: Two synchronized `ScrollView`s of lazy rows would serve; this toolkit's views are AppKit.
- **Compose**: Two `LazyColumn`s sharing one scroll offset.
- **React/Web**: Two virtualized lists with a shared scroll handler.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitMergeViewController: NSViewController` and `public struct GitMergeLayout` in `AgenticDeveloperHubSDKMacOS`, over three `LineViewerViewController`s with a `LineViewerScrollSync` on the two sides; `GitConflictDocument` in `AgenticDeveloperHubSDKCore`.
