
- **SwiftUI**: Start from a `NavigationSplitView` whose sidebar is a `List` of services (name as the
  title, provider kind as the subtitle, a `Label` with an SF Symbol) and whose detail is a `Form` with
  `Section`s for Service, Connection and Models. Create in a `.sheet`. The models table is a `Table`
  with `TableColumn`s and a `Toggle` column for Available; format counts with a custom `K`/`M` rule, not
  `formatted()`, to match this recipe. Unsaved-change protection has no automatic equivalent: use a
  confirmation dialog on selection change.
- **Compose**: A list-detail layout (`ListDetailPaneScaffold`) with a `LazyColumn` rail and a form
  `Column`; create in a `ModalBottomSheet` or dialog. The models table is a `LazyColumn` of rows with a
  `Checkbox` (use `Modifier.toggleable` on the row so the whole row is the target and the label is the
  model name) and an `AssistChip` row for capabilities. Keep the draft in a `ViewModel` and compare
  against the loaded baseline for the Save gate.
- **React/Web**: The source platform. The files are `ServicesSection.tsx` (the section, the create form,
  the editor and the models table), `useUserServices.ts` (the cached list and the exported key),
  `AiSettingsSection.tsx` (`ServicesSection` titled "AI Settings"), `index.ts` (the barrel with
  `ServicesSection`, `AiSettingsSection`, `useUserServices` and the key),
  `package.json` and `sources.css`. It is a client component built from the shared UI blocks
  (hierarchical detail view, field groups, button bar, create dialog, rail host) and the shared list
  resource hook. Selection is dual mode (URL or state) and the pane is published into a rail host when
  one exists. The availability call and the revalidation go through the personas data client and the
  list cache.
- **AppKit / UIKit**: A split view controller with an `NSOutlineView` or `UITableView` rail and a form
  detail. The models table is an `NSTableView` with a checkbox cell (`NSButton` of switch type) or a
  `UITableView` with `UISwitch` accessory views. The Save gate maps to `isDocumentEdited` on AppKit, and
  an unsaved-changes sheet on selection change. The Apple model item (`PersonasModels.swift`, generated
  from the OpenAPI) carries `available` as an optional field; read a missing value as available.
- **WinUI 3**: Use a `NavigationView` (or a two-column `Grid` with a `ListView`) for the rail, with an
  `ItemTemplate` showing name and a subtitle `TextBlock`; the pane is a `ScrollViewer` holding
  `StackPanel` groups (`Expander` or `HeaderedContentControl` for Service, Connection and Models). Create
  in a `ContentDialog` whose `IsPrimaryButtonEnabled` follows the draft's validation and whose
  `Opened` event focuses the Name `TextBox`. Provider is a `ComboBox` with `IsEnabled` false when
  editing; API key is a `PasswordBox`. Template choice is a `ComboBox`; informational templates are
  `Border` cards with `HyperlinkButton`s for "Use <name>". The models table is a `DataGrid` (Windows
  Community Toolkit) or an `ItemsRepeater` of rows with a `CheckBox` column bound two-way to
  `Available`; give each box `AutomationProperties.Name` set to the model's display name, and use
  `AutomationProperties.LiveSetting` on the blocker and connect messages. "No longer offered" is a
  `VisualState` of the row (checkbox unchecked, secondary-brush text). Save is a `Button` whose
  `IsEnabled` is `IsDirty && IsValid`; guard navigation with the `NavigationView.ItemInvoked` handler and
  a `ContentDialog`. Numbers use the same K/M rule, not `ToString("N0")`.

