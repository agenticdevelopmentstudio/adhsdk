
- **SwiftUI**: Replace the view controller with a `View` over an
  `@StateObject` model holding the session; the status is a `Text` or banner
  above the chat view, the options sheet a `Form` with a `Toggle`, two `Picker`s
  and a `TextEditor` (wrap and commit on `.onSubmit`/focus loss with
  `@FocusState`). Pane choices map to `@AppStorage`-style per-pane keys.
- **Compose**: A `ViewModel` exposing a `StateFlow` of status; the options sheet
  a `ModalBottomSheet` with a `Switch`, two `ExposedDropdownMenuBox`es and an
  `OutlinedTextField` with `maxLines`; cancel the live-model call with a
  `Job` tied to the `viewModelScope`; persist choices in DataStore keyed by
  pane id.
- **React/Web**: A component with a reducer for status and a `useEffect` with an
  `AbortController` for the live model fetch; the options a `<dialog>` with a
  checkbox, two `<select>` elements and a `<textarea>` committing on `blur`; give
  each control a `<label htmlFor>` and `aria-describedby` for the status
  (`role="status"`).
- **AppKit / UIKit**: Source file:
  `macOS/Features/TerminalSession/PersonaTerminalChatViewController.swift`, an
  `NSViewController` using `ThemedBackgroundView`, `ChatView`, `AIChatViewModel`,
  `LocalChatSession`, `CompositeChatToolSource`, `TerminalChatToolSource`,
  `PromptedToolCallingPlugin`, `AIProviderResolver`, `OpenAIModelCatalog`,
  `WindowOptionsToggle` and `NSPopUpButton`/`NSTextField` rows, conforming to
  `PaneOptionsProviding` and `PaneContentTeardown`. UIKit would use a
  `UIViewController` with `UIButton` menus (`UIMenu`) in place of
  `NSPopUpButton` and a `UITextView` for the persona.
- **WinUI 3**: A `UserControl` hosting the chat control (an `ItemsRepeater` or
  `ListView` of messages above a multi-line `TextBox`) in a `Grid` with an
  `InfoBar` (`IsOpen`, `Severity=Informational`, `Message`) for the status, driven
  by a view model implementing `INotifyPropertyChanged`; disable the composer
  `TextBox.IsEnabled` in the no-provider state. The options sheet is a
  `ContentDialog` or `Flyout` holding a `ToggleSwitch` (Connect to Terminal
  Chat), two `ComboBox`es (`SelectedValue` bound to the stored id, a first item
  for None and Provider default) and a `TextBox` with `AcceptsReturn="True"`,
  `TextWrapping="Wrap"`, `MinWidth="360"`, `Height="110"`, committing on
  `LostFocus` as well as `Enter`. Set `AutomationProperties.AutomationId` to the
  ids above and `AutomationProperties.Name` on each control, which also closes
  the open question on `control-labels`. Use `HttpClient` with a
  `CancellationTokenSource` for the live model list, and `DispatcherQueue` to
  apply results on the UI thread. Visual states: the composer's `Disabled` state;
  the `InfoBar` supplies the status text.

