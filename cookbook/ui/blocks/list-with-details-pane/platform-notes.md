
- **React / Web (TypeScript):** Block at `packages/web/packages/ui/src/blocks/list-with-details-pane.tsx` (exported via `./blocks/*`). Composes `DataTable`, `ResizableSplit`, `AlertModal`, `Button`, `Input`, `Separator`. Core responsibilities: filter state (controlled-or-internal), multi-select state as `Set<string>`, URL parameter sync (when `paramKey` provided), stale-link pruning on row changes, split bar and column width persistence via localStorage.
- **SwiftUI:** Start with a `@State` var for selection (`Set<String>`), a `List` for the rows (or a custom table if columns are needed), an `@ViewBuilder` for the detail pane, and a custom header-bar view (drag gesture + disclosure chevron) as the divider between them — matching **render-details-header-bar** rather than a plain `Divider`. Adapt the controlled-or-internal filter pattern using `@State` for internal state and a binding for controlled. The URL parameter pattern (`URLComponents`, `history.replaceState` equivalent) requires reading/writing `NavigationPath` or the app's own route state. Stale-link pruning happens on every rows change (in `onChange` of the list selection or a `.task` tracking rows), gated on the loading state per **clear-stale-deep-link**. Column width and split position persistence use `@AppStorage` or `UserDefaults`. No equivalent to `AlertModal` builtin; compose `Alert` or the `.confirmationDialog` view modifier. Master/detail layout uses `NavigationSplitView` (iPad) or conditional `.sheet` (iPhone).
- **Compose:** Build with `Column` wrapping a `TextField` (filter), a `LazyColumn` for rows (with selection state as `MutableState<Set<String>>`), and a divider + details pane below. Adapt the controlled-or-internal filter pattern with `mutableStateOf()` for internal and a lambda callback for controlled. URL parameter sync (if needed) maps to reading/writing a route state managed by the app's navigation. Stale-link pruning is a `LaunchedEffect` tracking rows, gated on the loading state per **clear-stale-deep-link**. Column width and split position use `SharedPreferences` or a data store. No builtin confirm dialog; use `AlertDialog` or Material's `Dialog`. Master/detail split uses `BoxWithConstraints` (or `WindowSizeClass`) to decide side-by-side vs. stacked layout: a wide window (the `WindowWidthSizeClass.EXPANDED` breakpoint, or an equivalent) is side-by-side, a narrower one is stacked (overflow scrolls).
- **AppKit / UIKit:** For a native, non-SwiftUI implementation: use `NSTableView` (AppKit) or `UITableViewController` (UIKit, legacy) for the table, or compose list-like views if a true table isn't needed. Selection state is a property (mutable set or array). Filter uses a text field and a predicate applied to rows before the table. Stale-link pruning on rows changes (KVO or didSet), gated on the loading state per **clear-stale-deep-link**. Split position via `NSSplitViewController` (AppKit) or manually constraining two views with a draggable divider (UIKit). URL parameter sync (if needed) uses `URLComponents` and reads/writes app state (no `history.replaceState` in native apps; this is web-specific). Persistence uses `UserDefaults` or `NSCoding`. Confirm dialogs use `NSAlert` (AppKit) or `UIAlertController` (UIKit). Not yet implemented for this platform; the mapping above describes how the pattern would translate when it is.
- **WinUI 3:** Build using `Grid` rows: top row is a toolbar (`CommandBar` or `StackPanel` of `Button` + `TextBox` for filter), middle row is a `DataGrid` from the CommunityToolkit (`CommunityToolkit.WinUI.Controls.DataGrid`; not a WinUI 3 built-in) bound to rows, selection via its `SelectionChanged` event, bottom row is a details pane (a `ScrollViewer` with a `StackPanel` of detail content). Selection state is a C# property (`HashSet<string>`; an `ObservableCollection<T>` doesn't fit a set of selected ids). Filter uses a `TextBox.TextChanged` event to apply a predicate. Stale-link pruning is a property change handler on rows, gated on the loading state per **clear-stale-deep-link**. Split position (draggable divider) uses `Grid.RowDefinition` with `*` (flex) sizing and a `GridSplitter`, also from the CommunityToolkit (`CommunityToolkit.WinUI.Controls.GridSplitter`; not a WinUI 3 built-in), between rows; persist via `ApplicationData.Current.LocalSettings`. URL parameter sync (`paramKey` feature) is web-specific and not applicable to WinUI 3. Confirm dialog uses `ContentDialog`. Column width persistence: `DataGrid` columns expose a `Width` property; save/restore in app settings.

### API

`@adh-sdk/ui/blocks/list-with-details-pane`:

```ts
interface ListAction {
  id: string
  label: React.ReactNode
  onClick: (selectedIds: string[]) => void
  requiresSelection?: boolean        // disabled when 0 selected
  dividerBefore?: boolean            // visual separator before this action
  variant?: React.ComponentProps<typeof Button>["variant"]  // default "outline"
}
interface ListWithDetailsPaneProps<T> {
  columns: DataTableColumn<T>[]
  rows: T[]
  getRowId: (row: T) => string
  renderDetail: (row: T) => React.ReactNode
  emptyDetail?: React.ReactNode      // default "Select a row to see details."
  filterText?: string                // controlled; internal state if omitted
  onFilterTextChange?: (t: string) => void
  filterPlaceholder?: string         // default "Filter…"
  filterRow?: (row: T, query: string) => boolean   // default: see filter-rows
  onDelete?: (selectedIds: string[]) => void
  deleteConfirm?: { title: string; description?: React.ReactNode }  // AlertModal copy
  actions?: ListAction[]
  storageKey?: string                // forwarded to ResizableSplit, persists split bar position
  paramKey?: string                  // opt-in URL-driven selection (deep-linkable detail row): mirror single selected row to ?<paramKey>=<id>
  loading?: boolean
  emptyLabel?: string                // table empty text
  autoSizeColumns?: boolean           // size each column to its widest cell, user can drag to override
  columnWidthsKey?: string            // persist dragged column widths under this key (distinct from storageKey)
  reorder?: DataTableReorder          // allow rows to be dragged into a new order; withhold when filter is non-empty
  detailsLabel?: string              // title on the details pane's header bar (default "Details")
  ariaLabel: string                  // toolbar label
  className?: string
}
export function ListWithDetailsPane<T>(props: ListWithDetailsPaneProps<T>): React.ReactElement
```

### Accessibility

The toolbar is `role="toolbar"` + `aria-label`; Delete/action buttons have
labels and their `disabled` reflects the selection (see
**disable-selection-actions**). The delete `AlertModal` traps focus and is
keyboard-dismissable (its own contract).

