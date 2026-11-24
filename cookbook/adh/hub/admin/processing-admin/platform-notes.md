
- **SwiftUI**: A `Toggle("Pool", isOn:)` in the create `Form`, and a `List` of dead rows with a trailing
  "Retry" `Button` per row; disable it while its task runs.
- **Compose**: A `Checkbox` with a `Text` label in a `Row` with `Modifier.toggleable`, and a `LazyColumn` of dead
  rows each with a `TextButton("Retry")`.
- **React/Web**: The source platform. The checkbox is a native input in the shared create dialog, the
  list is the shared editable list, and the two calls are `authedJson` functions in `api/processing.ts`
  with react-query hooks beside the others.
- **AppKit / UIKit**: An `NSButton` checkbox (or `UISwitch`) in the sheet, and an `NSTableView` or
  `UITableView` of dead rows with a Retry button cell.
- **WinUI 3**: A `CheckBox` in the `ContentDialog`, and a `ListView` of dead rows with a Retry
  `Button` in each item template.

