
- **SwiftUI**: Replace with an `HStack` pairing `Text(viewModel.title)`
  leading and a trailing `SecureField("", text: $value)` swapped for a
  `TextField` on the same binding while a `@State var isShown` is true, then
  two `.borderless` image buttons (`doc.on.doc` writing
  `NSPasteboard.general`, and `eye` / `eye.slash` toggling `isShown`).
  Reset `isShown` in `.onChange(of: scenePhase)`, on
  `NSWindow.didResignKeyNotification` via `.onReceive`, in `.onDisappear`
  and when the value changes from outside. The binding's setter writes back
  to the setting behind an equality guard before assigning, mirroring
  **skips-redundant-commits**. Give the field an
  explicit `.accessibilityLabel(viewModel.title)` — the SwiftUI analog of
  **titles-fields-with-label** — and drive
  its font/color from the same semantic theme tokens (`.body`, `primaryText`,
  `placeholderText`) rather than fixed literals, mirroring the theme styling
  documented for `TextEditView`.
- **Compose**: Use a `Row` with `Text(title)` leading and a trailing
  `OutlinedTextField(value = value, onValueChange = { ... },
  visualTransformation = if (shown) VisualTransformation.None else
  PasswordVisualTransformation(), singleLine = true)` with a `trailingIcon`
  row of two `IconButton`s (copy through `LocalClipboardManager`, and the
  visibility toggle); hold `shown` in `remember`, never `rememberSaveable`,
  and reset it on `Lifecycle.Event.ON_PAUSE` and when the value changes from
  outside — `PasswordVisualTransformation` is Compose's dot-masking analog
  of `NSSecureTextField`. Commit to the backing state/view model on focus loss
  or `ImeAction.Done` (`KeyboardOptions(imeAction = ImeAction.Done)` with a
  `KeyboardActions.onDone`, or a `Modifier.onFocusChanged` check), not on
  every `onValueChange` call — `onValueChange` fires per keystroke, which
  would otherwise write partial secrets to storage — comparing against the
  previous value before writing, mirroring **skips-redundant-commits**. Give
  it `Modifier.semantics { contentDescription = title }` (the Compose analog
  of **titles-fields-with-label**).
- **React/Web**: A flex row (`display: flex; align-items: center;
  justify-content: space-between`) containing a `<label>` for the title and
  an `<input>` whose `type` is `password` or, while shown, `text`, followed
  by two `<button type="button">`s (copy through
  `navigator.clipboard.writeText`, and the eye with `aria-pressed`); reset
  the shown state on `window` `blur`, `visibilitychange` and unmount. The
  input's `aria-labelledby` points at the title
  `<label>`'s `id` — the web analog of **titles-fields-with-label**. Commit the new value on the input's
  `blur` handler (or Enter via `onKeyDown`), not on every `onChange` call —
  an `<input>` fires `onChange` per keystroke, which would otherwise write
  partial secrets to storage — comparing against the previous value before
  calling the parent's setter, mirroring **skips-redundant-commits**; style
  the input's font/color and any placeholder from theme tokens equivalent to
  `.body`/`primaryText`/`placeholderText`, mirroring the theme styling
  documented for `TextEditView`.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/Views/SecureTextEditView.swift`
  — a macOS-only, `@MainActor`, `final` subclass of `TextEditView` inside the
  `ComposableSettings` namespace. It overrides
  `makeTextField(initialValue:)` to return the masking field, and adds the
  two trailing `NSButton`s (borderless, SF Symbols `doc.on.doc` for copy,
  and `eye` while obscured and `eye.slash` while shown for the reveal and
  conceal glyphs). AppKit has no reveal mode on `NSSecureTextField`, so
  showing swaps in a plain `NSTextField` holding the same string, keeping
  first responder. Copy writes the view's `pasteboard` property, which
  defaults to `NSPasteboard.general` (tests inject a private one), with
  `.string` only. `TextEditView.init` calls
  `setAccessibilityTitleUIElement(label)` on every field in
  `editableFields`, which this view overrides to `[textField, revealField]`,
  so both the secure field and the reveal field are titled by the label.
  Re-obscuring observes `NSWindow.didResignKeyNotification` for its window
  (re-registered in `viewDidMoveToWindow`, which also obscures when the
  window becomes nil) and `NSApplication.didResignActiveNotification`, and
  the inherited `viewModel.onChange` sync obscures before it sets the new
  value only when that value differs from the text the row shows, so the
  row's own commit leaves it shown. The AI Providers editor is AppKit and
  built from the ComposableSettings row views: it constructs a
  `SecureTextEditView` directly for each secret field. `final` is what
  forecloses further specialization (the
  requirement this ingredient's Behavioral Requirements section defers to this
  entry): it makes `SecureTextEditView` the terminal specialization of
  `TextEditView` for masked entry, so the compiler rejects any attempt to
  declare a further subclass of it. Because the class is `final`, the
  override of `TextEditView`'s `open class func makeTextField` is declared
  `override static func`. `TextEditView.swift`
  ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)) supplies everything else — row
  layout, content-hugging, the `textFieldChanged(_:)` target/action commit
  path, `observeTheme` styling, and `viewModel.onChange` sync — and is out of
  this ingredient's scope. There is no UIKit code path in source; a UIKit port
  would replace `NSSecureTextField` with a `UITextField` configured
  `isSecureTextEntry = true`, and would enforce "no further subclassing" (if
  desired) with a `final` class declaration, UIKit's own equivalent
  mechanism.
- **WinUI 3** (the reason this ingredient exists): Build the row as a `Grid`
  with column definitions `Auto,*,Auto,Auto`, one column each: a `TextBlock`
  for the title in column 0; a `PasswordBox` — WinUI's own dot-masking
  control and the direct analog of `NSSecureTextField` — in column 1,
  `HorizontalAlignment="Stretch"` so the `*` column's leftover width goes to
  the field rather than the title, the WinUI analog of
  `expands-text-field-to-fill-row`; a copy `Button` with a `SymbolIcon`
  `Copy` writing `Clipboard.SetContent` in column 2; and the eye
  `ToggleButton` (below) in column 3. Set
  `AutomationProperties.LabeledBy` on the `PasswordBox` to the `TextBlock` —
  the WinUI analog of the AppKit source's `setAccessibilityTitleUIElement`
  link (**titles-fields-with-label**). Commit on the `PasswordBox`'s `LostFocus`
  event (or Enter), not on every `PasswordChanged` event — `PasswordChanged`
  fires per keystroke, which would otherwise write partial secrets to
  storage (the keychain, in the typical setup) — writing through a property
  setter that skips the assignment (and so skips raising
  `INotifyPropertyChanged`) when the incoming value already equals the
  current one, mirroring **skips-redundant-commits**. Bind
  `PasswordBox.Foreground`/`PlaceholderForeground` to theme resource
  brushes equivalent to `primaryText`/`placeholderText`, mirroring the
  theme styling documented for `TextEditView`. For the eye, set
  `PasswordRevealMode="Hidden"` and drive `PasswordRevealMode` between
  `Hidden` and `Visible` from a `ToggleButton` with `SymbolIcon` `View`,
  since the built-in `Peek` mode only shows while pressed. Reset it to
  `Hidden` on `Window.Activated` with `WindowActivationState.Deactivated`,
  on `Unloaded`, and when the bound value changes from outside; keep the
  toggle out of the view model's persisted state.

