
- **SwiftUI**: Implement with `.popover(isPresented:)` (or an equivalent overlay) attached to the trigger `Button`, not `Menu` — `Menu` and its toggle items dismiss after each selection, which breaks the multi-select toggle interaction. Inside the popover, lay out the "All"/"None" buttons above a `ScrollView` of checkbox-style `Toggle` rows. Apply `.disabled()` to the trigger `Button` when `options` is empty.

- **Compose**: Implement with a custom, non-dismissing dropdown surface (e.g. a themed `Popup` or `DropdownMenu` composable configured to stay open on item selection) anchored to the trigger `Button` — not `ExposedDropdownMenuBox`, which is a single-select text-field pattern that closes on pick. Render "All"/"None" as `Button`s above a `Column` of checkbox rows constrained with `Modifier.heightIn(max = 256.dp)` and vertical scrolling.

- **React/Web**: Implement using this package's `Popover`/`PopoverTrigger`/`PopoverContent`, `Button`, and `Checkbox` components, as shown in `blocks/facet-menu.tsx`: the trigger is a ghost `Button` (disabled when `options` is empty); the popover content holds "All"/"None" ghost `Button`s above a vertically scrollable (`max-h-64 overflow-auto`) column of `<label>`-wrapped `Checkbox` rows.

- **AppKit / UIKit**: Implement with a custom, non-dismissing popover — `NSPopover` on macOS, a custom-anchored or sheet-presented view controller on iOS — rather than `NSMenu`/`UIMenu`, both of which close after a single item is picked and would break the multi-select toggle. The popover content mirrors the React layout: "All"/"None" buttons above a scrollable checkbox list.

- **WinUI 3**: Implement with a `Flyout` attached to the trigger `Button` (not a plain `ComboBox`, which is a single-select text field, and not `InfoBar`, which is a notification banner — neither fits a multi-select filter). Place "All"/"None" `Button`s in the flyout content above a `ScrollViewer` bounded to a fixed height (e.g. `MaxHeight="256"`) containing `CheckBox` rows.

