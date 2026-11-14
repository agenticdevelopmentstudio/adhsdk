
- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/Views/TableFillingView.swift`, an AppKit `NSView`. In SwiftUI, put a `Table` in a `VStack` with `.frame(maxHeight: .infinity)`; SwiftUI sizes the table to the space left, so no height pass is needed.
- **Compose**: A `Column` with the card at the top and a `LazyColumn` given `Modifier.weight(1f)` so it takes the remaining height; set `fillMaxWidth()` on both.
- **React/Web**: A flex column container with `min-height: 120px`; the table wrapper takes `flex: 1 1 auto; min-height: 0; overflow: auto`.
- **AppKit / UIKit**: In AppKit the view pins the card's top, leading and trailing anchors and overrides `layout()` to add the slack to `tableHeight`. A height anchor at or above the minimum lets the view shrink below the card's current height. On UIKit, give the table view a `heightAnchor` equal to the container's remaining height, or use a `UIStackView` with the table set to low content-hugging priority.
- **WinUI 3**: A `Grid` with two rows: `RowDefinition Height="Auto"` for any card header and `Height="*"` for a `ListView` or `DataGrid`, with `MinHeight="120"` on the Grid; the star row fills the rest with no code-behind.

