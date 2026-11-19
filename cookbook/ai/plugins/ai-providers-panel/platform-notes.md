
- **Apple implementation (AppKit)**: The panel lives in
  `Features/AIPlugins/Settings/`. `AIPanelViewController`
  (`AISettingsViewPanelController.swift`) is a
  `SettingsPanelSplitViewController` whose footer is an
  `AddRemoveFooterView`; the + button presents `ProviderPicker` over the
  window, − confirms with an `NSAlert` (a sheet when the panel has a
  window), and each configuration's page is a private
  `ProviderConfigPanelViewController` reused by configuration id.
  `LLMProvidersListViewModel` owns the list, add, rename and remove;
  `PluginLoadFailuresPanel` is the trailing failures page, fed by
  `AIPluginManager.loadAllPlugins().failures`. The editor is the AppKit view
  `LLMProviderEditorView` (`LLMProvidersView.swift`), built from
  ComposableSettings rows: a secret field is a
  `ComposableSettings.SecureTextEditView`, any other field a
  `ComposableSettings.TextEditView`, and the connection group is a
  `ComposableSettings.GroupView` with an empty header view. The default
  model row is an `AIModelPickerControl` labelled "Default Model" over
  `AIProviderConfigStore.modelSetting(config:template:)`, refreshed by a
  `UserSettingObserver` on that setting. The subtitle and title come from
  `ProviderConfigTitles` (`template.resolvedProvider`, `resolvedLLM`,
  `resolvedConfigType`), and the subtitle is set on the panel's
  `descriptor.subtitle`. The Test Chat is
  `AIChatViewController(pluginManager:configuration:pinsConfiguration: true)`
  inside a themed card, whose "Choose Model…" button presents
  `ModelChooser` in a popover. Deleting calls
  `AIProviderConfigStore.clearStoredValues(config:fields:)`, which writes
  `""` to each field setting and the model setting; a secure setting's
  value lives in the Keychain.
- **SwiftUI**: A SwiftUI port would keep the list model as an observable
  object and host `ComposableSettings.SecureTextEditView` and
  `AIModelPickerControl` through `NSViewRepresentable`, or port those rows.
