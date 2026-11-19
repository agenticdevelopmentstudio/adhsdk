
- **SwiftUI**: Replace with an `HStack` pairing `Text(viewModel.title)`
  leading and a trailing `TextField("", text: $value)`, tracked through a
  local editing state. Commit the value back into the underlying setting
  on `.onSubmit` (Return) or when a `@FocusState` boolean bound to the
  field transitions from `true` to `false` (focus loss) — not on every
  keystroke via the binding setter — with an equality guard before
  assigning, mirroring skips-redundant-commits and the platform's own
  commit points. Give the field an explicit
  `.accessibilityLabel(viewModel.title)` — the SwiftUI analog of the
  source's label-to-field title link (titles-every-field-by-label) — and
  drive its font/color from the same semantic theme tokens (`.body`,
  `primaryText`, `placeholderText`) rather than fixed literals, mirroring
  applies-theme-styling/restyles-existing-placeholder. The subclass hooks
  (control view, editable-fields list, stored-value-changed and reload)
  have no SwiftUI counterpart: compose a variant instead, taking the
  trailing control as a `@ViewBuilder` parameter and reacting to a change
  of the setting from outside with `.onChange(of:)`.
- **Compose**: Use a `Row` with `Text(title)` leading and a trailing
  `OutlinedTextField(value = value, onValueChange = { value = it },
  singleLine = true)` backed by local text state. Commit to the backing
  state/view model only on focus loss (`Modifier.onFocusChanged`) or
  `ImeAction.Done`, not on every `onValueChange` call — `onValueChange`
  fires per keystroke — comparing against the previous value before
  writing, mirroring skips-redundant-commits and the platform's own commit
  points. Give it `Modifier.semantics { contentDescription = title }` (the
  Compose analog of titles-every-field-by-label). Compose variants by
  composition rather than the subclass hooks: take the trailing control as
  a `@Composable` slot parameter, and react to a change of the setting from
  outside with `LaunchedEffect(value)`.
- **React/Web**: A flex row (`display: flex; align-items: center;
  justify-content: space-between`) containing a `<label>` for the title
  and an `<input type="text">` whose `aria-labelledby` points at the
  title `<label>`'s `id` — the web analog of the source's label-to-field
  title link (titles-every-field-by-label). Track the typed value locally
  and commit the new value to the parent's setter only on the input's
  `blur` handler or Enter via `onKeyDown`, not on every `onChange` call —
  an `<input>` fires `onChange` per keystroke — comparing against the
  previous value before calling the parent's setter, mirroring
  skips-redundant-commits and the platform's own commit points; style the
  input's font/color and any placeholder from theme tokens equivalent to
  `.body`/`primaryText`/`placeholderText`, mirroring applies-theme-styling.
  Build variants by composition rather than the subclass hooks: pass the
  trailing control as a `children` or render prop, and react to a change
  of the setting from outside in a `useEffect` keyed on the value.
- **AppKit/UIKit** (source platform): Source file
  `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/Views/TextEditView.swift`:
  a macOS-only, `@MainActor` `NSView` subclass inside the
  `ComposableSettings` namespace, `open` to subclassing through its
  `makeTextField(initialValue:)` factory — the mechanism
  `SecureTextEditView.swift` (in the same directory) uses to substitute
  `NSSecureTextField`. For every field in `editableFields`, the
  initializer sets `target` to the view itself and `action` to
  `#selector(textFieldChanged(_:))`, its module-internal `@objc` handler
  that performs the commit (see wires-text-field-action), and calls
  `setAccessibilityTitleUIElement(label)` (see
  titles-every-field-by-label).
  The component is constructed only via `init(with:)`: the
  fatal-erroring `init?(coder:)` and the frame-only `init(frame:)` are
  overridden to trap, so a caller cannot construct one without a view
  model. `@MainActor` confines construction and mutation to the main actor
  under Swift's concurrency checking. `TextEditView` conforms to
  `SettingsViewProtocol`, a marker protocol
  (`.../Views/SettingsViewProtocol.swift`) that `ComposableSettings` uses to
  type its row views; the protocol adds no requirements of its own beyond
  `NSView` conformance. The file is macOS-only (`import AppKit`); there is
  no UIKit code path in source. A UIKit port would replace `NSTextField`
  with a `UITextField` and the target/action pattern with
  `.addTarget(_:action:for: .editingDidEndOnExit)`. The frame-only and
  coder initializers trap with "has not been implemented"; the row is built
  only through `init(with:)`.
- **WinUI 3**: Build the row as a `Grid` with column definitions `Auto,*`:
  a `TextBlock` for the title in column 0 (`Auto`, sized to its content,
  the WinUI analog of the row's label), and a `TextBox` — the direct
  analog of the plain text field this class constructs — in column 1
  (the `*` column, which claims the row's leftover space), with
  `HorizontalAlignment="Stretch"` so the field, not the title, takes the
  leftover width the way expands-text-field-to-fill-row does. Set
  `AutomationProperties.LabeledBy` on the `TextBox` to the `TextBlock` —
  the WinUI analog of the source's label-to-field title link
  (titles-every-field-by-label). Commit on the `TextBox.LostFocus` event (or `KeyDown` on
  Enter, mirroring the platform's own commit-firing points), writing
  through a property setter that skips the assignment (and so skips
  raising `INotifyPropertyChanged`) when the incoming value already equals
  the current one, mirroring skips-redundant-commits. Bind
  `TextBox.Foreground` and `PlaceholderForeground`/`PlaceholderText` to
  theme resource brushes equivalent to `primaryText`/`placeholderText`
  rather than hardcoded colors, mirroring
  applies-theme-styling/restyles-existing-placeholder. For a secure
  variant, a `PasswordBox` is the WinUI analog to build against instead,
  the way the Secure Text Edit View overrides this class's factory. The
  other subclass hooks map to composition: a `ContentPresenter` in column 1
  for the control view, and a handler on the view model's
  `PropertyChanged` event for a change of the setting from outside.

