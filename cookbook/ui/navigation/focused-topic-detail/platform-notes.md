
- **SwiftUI**: Use a `NavigationSplitView` with a sidebar `List(selection:)` of topics and a `Picker` or `Menu` as its first row for focus; when nothing is focused, show a `LazyVGrid` of card views in the detail column. Key the focused detail by `.id(focusedId)` to remount it.
- **Compose**: A `Row` with a rail `Column` (a `DropdownMenu` selector over a `LazyColumn` of topics) and a pane; the pane switches between `children` and a `LazyVerticalGrid` of cards. Wrap the focused content in `key(focusedId)`.
- **React/Web**: The source is `packages/web/packages/ui/src/blocks/focused-topic-detail.tsx`. A `Fragment key={focusedId}` remounts pane content, and Tailwind `apt-*` tokens carry the colours.
- **AppKit / UIKit**: An `NSSplitViewController` with a source-list sidebar whose first row is an `NSPopUpButton`; the detail swaps between the consumer's view controller and an `NSCollectionView` of cards. On UIKit use `UISplitViewController` with a `UIMenu` button.
- **WinUI 3**: A `NavigationView` with `PaneDisplayMode="Left"`, a `DropDownButton` with `RadioMenuFlyoutItem` entries as the pane header, and a `Frame` whose content swaps between the consumer's page and an `ItemsRepeater` of card controls; recreate the focused page on a focus change so it starts with fresh state.

