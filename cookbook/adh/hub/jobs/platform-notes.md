
- **SwiftUI**: A `NavigationSplitView` with jobs in the sidebar and a `Form` detail. Use a `.sheet` for
  create and for the once-shown secret, with `.interactiveDismissDisabled()` until it is copied. Use a
  `Table` for the run status. Read the run stream with `URLSession.bytes(for:)` and cancel the task
  when the view disappears.
- **Compose**: A `ListDetailPaneScaffold` with a `LazyColumn` of jobs. A `ModalBottomSheet` holds create and
  the secret reveal. Collect the run stream in a `ViewModel` flow scoped to the screen, and show status as
  text in an `AssistChip`.
- **React/Web**: The source platform. The package is a client component library built from the shared
  UI blocks (hierarchical detail view, field groups, button bar, create dialog, rail host, editable
  list) and the shared list resource hook. The topic sets sit in a plain-data module behind `./topics`.
  The data client is a plain module of `authedJson` calls with an `EventSource` for the run stream.
- **AppKit / UIKit**: A split view controller with an `NSOutlineView` or `UITableView` of jobs. The status
  table is an `NSTableView`, and a sheet holds the secret reveal. Stream with a `URLSession` data task
  delegate and cancel it on `viewWillDisappear`.
- **WinUI 3**: A `NavigationView` with a `ListView` of jobs. A `ContentDialog` holds create and the secret
  reveal, with `PrimaryButtonText` "Done" and a confirmation on close. The status table is a
  `DataGrid`, and step reordering uses up and down `Button`s for keyboard reach.

