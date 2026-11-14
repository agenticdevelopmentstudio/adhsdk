
- **SwiftUI**: The source is already an `ObservableObject` with a `@Published`
  property, so a SwiftUI view can hold it as `@ObservedObject` or
  `@EnvironmentObject` and bind a `Toggle` to `hidesExcludedContent`; SwiftUI
  reads the new value on the next render pass, so the will-set timing of the
  publisher does not bite. On newer SDKs the `@Observable` macro with a
  did-set observer is the equivalent.
- **Compose**: Hold a `MutableStateFlow<Boolean>` (or `mutableStateOf`) in a
  `ViewModel` shared by every screen that must agree, initialised to `true`,
  and expose an `onChange` lambda that fires only when the new value differs
  (use `distinctUntilChanged` for the persistence collector). Collection runs
  after the store, so there is no will-set quirk.
- **React/Web**: A single store object (a Zustand or Redux slice, or a context
  with `useSyncExternalStore`) shared by every browser component. Fire the
  persistence callback only on a real change by comparing to the previous
  value. Subscribers see the new value because stores update before notifying.
- **AppKit / UIKit**: Source files:
  `macOS/UI/ViewControllers/FileBrowser/FileBrowserExclusionState.swift` (the
  type), consumed by `FileBrowserViewController` (which subscribes through
  Combine with `removeDuplicates`, `dropFirst` and a main run loop hop, and
  toggles it from a pane-options menu item) and created per project by the
  project workspace. UIKit has no menu-item state to bind, so a port
  subscribes the same way and sets a switch or a menu action state itself.
- **WinUI 3**: Implement a `partial` class that implements
  `INotifyPropertyChanged` (or a `CommunityToolkit.Mvvm` `ObservableObject`
  with `[ObservableProperty] private bool hidesExcludedContent = true;`) and a
  public `Action<bool>? OnChange` field. In the setter, compare with the old
  value and call `OnChange?.Invoke(value)` only when different, after the
  backing field is set. Bind a `ToggleMenuFlyoutItem.IsChecked` or
  `ToggleSwitch.IsOn` with `{x:Bind ViewModel.HidesExcludedContent, Mode=TwoWay}`.
  Share the one instance through the project object. Unlike Combine,
  `PropertyChanged` is raised after the field changes, and WinUI requires
  UI-bound changes on the `DispatcherQueue` thread, which replaces the source's
  main-actor isolation.

