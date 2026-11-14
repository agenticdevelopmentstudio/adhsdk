
- **SwiftUI**: Hold the group as an `@StateObject` or `@ObservedObject` and read
  `activeRepoIDs` for a list and `selectedRepoID` for the selection;
  `ProjectShelfPanel` maps to a `Picker` or a toolbar of buttons using the
  `symbol` name with `Image(systemName:)`. A `NavigationSplitView` is the
  native shape, though the source swaps whole windows instead of views.
- **Compose**: A `ViewModel` with `MutableStateFlow` for the list, selection
  and panel and a `Map` flow for filter text; `activate` and `deactivate` become
  pure functions on an immutable list. Use `NavigationRail` or a `TabRow` for the
  panels, with icon names mapped from the SF Symbols.
- **React/Web**: A store (reducer or Zustand) with `activeRepoIDs`,
  `selectedRepoID`, `panel` and a `filterText` record; persist only the
  state without `filterText`. Panels become tabs (`role="tablist"`).
- **AppKit / UIKit**: Source file:
  `macOS/Features/Projects/ProjectWindowGroup.swift`, consumed by the project
  shelf and active-projects view controllers, the window manager and the
  composable-tabs window controllers (the group shows exactly one project
  window by ordering one in and another out). `@MainActor` and
  `ObservableObject` come from Combine; SF Symbols need macOS 11 or iOS 13.
- **WinUI 3**: A view-model class using `CommunityToolkit.Mvvm`
  (`ObservableObject`) with `ObservableCollection<Guid> ActiveRepoIds`,
  `Guid? SelectedRepoId`, a `ShelfPanel` enum property and a
  `Dictionary<ShelfPanel,string>` for filters; a `record` for the persisted
  state serialised with `System.Text.Json` (use `JsonStringEnumConverter` so
  the persisted names stay `browser` and `activeProjects`). Show panels with a
  `NavigationView` or a `SelectorBar` whose items use `FontIcon` glyphs in place
  of SF Symbols, and the filter with `AutoSuggestBox.PlaceholderText`. WinUI
  requires UI-bound changes on the `DispatcherQueue` thread, replacing the
  main-actor isolation; the group swap becomes showing one `Window` or
  `Frame` content and hiding the others.

