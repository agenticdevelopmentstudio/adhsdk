
- **SwiftUI**: A `Form` section with a `Picker` bound to the selection
  (`.pickerStyle(.menu)`) and the model control below it; `.onChange(of:
  selection)` writes `""` to the new provider's model setting when the value
  differs, and `.disabled` drives the model row for a sentinel. The source
  becomes an `@Observable` model loading the daemon list in a `.task`.
- **Compose**: An `ExposedDropdownMenuBox` for the provider and the model
  control's `Row` below; a `ViewModel` exposes the source as a `StateFlow`, and
  the selection handler writes the empty model through the repository only
  when the id changes.
- **React/Web**: A `<select>` (or a listbox component) with
  `aria-labelledby` on its label, and the model control below; `onChange`
  writes the selection and resets the model setting when the id differs. The
  daemon source is a fetch in a data hook with a loading state that keeps the
  stored selection listed.
- **AppKit/UIKit** (source platform):
  `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/ProviderModelPickerView.swift`
  holds `ProviderModelPickerView` (an `NSView` of two rows: an `NSPopUpButton`
  and an `AIModelPickerControl`);
  `ProviderRegistrySource.swift` beside it holds the source protocol,
  `ProviderRegistrySource` (named apart from AIPluginKit's
  `ProviderModelSource`, which fetches one provider's catalog), with
  `isAuthoritative` saying whether the list is complete, and its two
  implementations, `LocalProviderRegistrySource` and
  `DaemonProviderRegistrySource`. Local reads `AIPluginManager` and
  `UserSettings.aiProviderConfigurations` and resolves the default through
  `AIProviderConfigStore.modelSetting(config:template:)`; daemon calls
  `StenographerService.aiProviderConfigs()` and takes an optional
  `AIPluginManager`. Settings are `UserSetting<String>` for the selection and
  `modelSetting: (String) -> UserSetting<String>`. It replaces
  `LLMPickerView` and `DaemonProviderPickerView`, which are deleted. Callers:
  `PartnerGeneralSettingsViewController`, `AISummariesSettingsPanel`,
  `AIOversightSettingsPanel`, `OversightFindingsViewController` and
  `SessionsWindowController`; the Sessions, Conversations and Oversight
  coordinators take `pluginManager: AIPluginManager? = nil`, which the Kitchen
  passes and Stenographer does not. A UIKit port would use a `UIButton` with a
  `UIMenu` for the popup.
- **WinUI 3**: A `StackPanel` of two rows: a `ComboBox` (`ItemsSource` bound to
  an `ObservableCollection` of the leading choices then the configurations,
  `SelectedValuePath="Id"`, `SelectedValue` two-way bound to the selection) with
  `AutomationProperties.Name` set to the provider label, and the model control
  below. The view model's selection setter writes `""` to the new provider's
  model only when the id differs, and raises `PropertyChanged` for the model
  row's name. Load the daemon list with an `async` call off the UI thread and
  marshal back through `DispatcherQueue.TryEnqueue`; set the model row's
  `IsEnabled` false for a sentinel.

