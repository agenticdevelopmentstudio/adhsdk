
- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/CoreUI/TopAnchoredFlippedView.swift`, a final AppKit `NSView` overriding `isFlipped`. A SwiftUI `ScrollView` already anchors short content at the top, so no counterpart is needed; when embedding in an `NSViewRepresentable` scroll view, use this view as the document.
- **Compose**: A `Column` in `verticalScroll` places content at the top by default; no counterpart is needed.
- **React/Web**: A block container with `overflow: auto` places content at the top by default; no counterpart is needed.
- **AppKit / UIKit**: In AppKit, override `isFlipped` to return true and use the view as `NSScrollView.documentView`, pinning content to its top and leading edges. UIKit's origin is already top-left, so a `UIScrollView` content view needs nothing.
- **WinUI 3**: A `ScrollViewer` with a `StackPanel` content places content at the top by default; no counterpart is needed.

