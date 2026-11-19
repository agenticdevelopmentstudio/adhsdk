---
id: 2e0bf51e-905d-476d-9c0c-48465174ba59
title: "Secure Text Edit View"
type: ingredient
version: 1.4.0
status: review
language: en
created: 2026-09-23
modified: 2026-11-19
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A settings text row that masks its entry, for secrets such as API keys and passwords."
platforms:
  - swift
  - macos
tags:
  - settings
  - form-control
  - text-input
  - secure-input
depends-on:
  - c1787e74-2485-4d7b-a219-feb4c07cf97c
related:
  - e9c10ff7-4e13-4007-a963-d2a9e4006745
references: []
approved-by: ""
approved-date: ""
---

# Secure Text Edit View

## Overview

The Secure Text Edit View is a settings text row. Per the source's own doc
comment, it is meant for API keys, passwords, and other secrets that are
still routed through a view model — typically one whose backing setting has
secure storage enabled and is therefore stored through a keychain-backed
storage provider.

It specializes the text edit row
([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)), overriding
its field construction to make a masking (dot-obscured) secure field, so
a stored secret shows as one dot per character, and adding two
right-aligned buttons after the field: copy, which puts the secret on the
pasteboard, and an eye, which toggles showing the secret in plain text. A
shown secret is hidden again as soon as the person could look away from it:
when the window resigns key, the app resigns active, the view leaves its
window, or the setting changes from outside. Shown is a transient state and
is never persisted. The AI Providers editor's secret fields
([adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a)) use it.

The text edit row's own row layout, theme-driven font/color styling,
commit path, and view-model sync are out of this recipe's scope; only the
delta this specialization adds — the masked field, the copy and reveal
buttons, the re-obscure rules and the ban on further specialization — is
documented here. See
[adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c) for everything a
caller instantiating this component also gets.

## Behavioral Requirements

- **masks-entry-with-secure-field**: Component MUST construct its field as
  a masking (dot-obscured) secure text field, so the field is a secure,
  masking field rather than the plain field its base row would otherwise
  construct.
- **stored-secret-shows-as-dots**: A stored, non-empty secret MUST show as one
  dot glyph per character while the field is obscured, without the person
  having to focus or edit the field.
- **trailing-accessory-buttons**: The row MUST place two buttons after the
  field, right-aligned in the row: copy, then the eye.
- **copy-puts-secret-on-pasteboard**: The copy button MUST replace the
  general pasteboard's contents with the field's current value, as plain
  text, whether the secret is obscured or shown.
- **copy-disabled-when-empty**: The copy button MUST be disabled while the
  field's value is empty.
- **eye-toggles-reveal**: The eye button MUST toggle the field between
  obscured (dots) and shown (plain text), keeping the value, first
  responder and the commit path unchanged.
- **eye-icon-tracks-state**: The eye button MUST show the `eye` symbol while
  obscured and `eye.slash` while shown.
- **reobscure-on-window-resign-key**: A shown secret MUST return to obscured
  when the view's window resigns key.
- **reobscure-on-app-resign-active**: A shown secret MUST return to obscured
  when the app resigns active.
- **reobscure-on-leave-window**: A shown secret MUST return to obscured when
  the view is removed from its window, so a row that comes back is obscured.
- **reobscure-on-external-change**: A shown secret MUST return to obscured
  when the field's setting changes from outside the row (the view-model sync
  path), and the new value MUST show as dots.
- **reveal-state-not-persisted**: The shown state MUST be held only in the
  view and MUST NOT be written to any setting or store; every new row starts
  obscured.
- **edits-commit-in-either-state**: An edit made while shown MUST commit
  through the same commit path, with the same redundant-commit guard, as an
  edit made while obscured.

All other behavior — row layout, expanding the field to fill the row,
wiring the field's action, initializing from and syncing with the view
model, theme styling, restyling an existing placeholder, exposing the
label and the field, the designated-initializer-only construction rule,
and UI-thread confinement — is inherited unmodified from the text edit
row; see
behavioral-requirements ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))
(arranges-row-layout, expands-text-field-to-fill-row,
wires-text-field-action, initializes-from-view-model,
commits-value-on-change, skips-redundant-commits, syncs-on-external-change,
applies-theme-styling, restyles-existing-placeholder,
exposes-constituent-views, requires-designated-initializer,
rejects-frame-only-initialization, confines-to-ui-thread). Foreclosing
further specialization of this component is a platform-specific
construction detail, recorded in Platform Notes rather than as a
normative requirement here (see Platform Notes).

- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

Inherited unmodified from the text edit row — corner radius, padding,
font, background, foreground/text, border, shadow, and min/max size are
all as documented at
appearance ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)); this
component sets no font or color of its own. The differences this
specialization introduces:

- **Masking**: while obscured, the field's characters render as the
  platform's built-in dot-mask glyphs rather than plain text (see
  **masks-entry-with-secure-field** and **stored-secret-shows-as-dots**).
- **Accessory buttons**: two borderless, image-only buttons after the field,
  right-aligned: copy (`doc.on.doc`) and the eye (`eye` obscured,
  `eye.slash` shown), each sized to the field's height and separated from
  the field and from each other by the row's standard spacing. Their tint is
  the theme's secondary text role; a disabled copy button is dimmed by the
  platform.
- **Min/Max size**: the field still fills the row's leftover width; the two
  buttons keep their intrinsic size and never compress.

## States

| State | Appearance change |
|-------|------------------|
| Default | Label shows the view model's title; the field's underlying value equals the view model's value, rendered as one dot-mask glyph per character — the platform's own built-in masked rendering, per the source's doc comment ("so the entry is dot-masked") — see **masks-entry-with-secure-field**. |
| Obscured | The default for every new row: dots, eye button shows `eye`. |
| Shown | The field shows the value in plain text; eye button shows `eye.slash`. Left for Obscured on window resign key, app resign active, leaving the window or an external change. |
| Empty | Copy button disabled; the eye still toggles. |
| All other states | Editing, Committed, Placeholder shown, Disabled, Pressed, and Loading are inherited unmodified from the text edit row; see states ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)). |

## Accessibility

- **Role/trait**: Inherited unmodified from the text edit row — no
  explicit accessibility role override appears in either file; the
  platform's secure text field carries its own built-in secure-text-field
  accessibility role.
- **Label requirements**: Neither the text edit row's construction (which
  this component inherits unmodified) nor this component's own source
  links the field's accessible name to the label — unlike the sibling
  checkbox row ([adhsdk.ingredient.ui.settings.rows.checkbox-view](cookbook:e9c10ff7-4e13-4007-a963-d2a9e4006745)),
  which links its switch to its label for exactly this reason (the
  platform gives a bare switch no name). Without that link, a screen
  reader announces the field as an unnamed secure text field rather than
  by the row's title.
- **Accessory buttons**: The copy button's accessibility label MUST be
  "Copy" and the eye's MUST be "Show" while obscured and "Hide" while
  shown, since image-only buttons otherwise announce the symbol name. Both
  are in the key-view loop after the field.
- **Announce state changes**: Inherited unmodified from the text edit row
  — the component has no loading state and never disables itself in
  source; masked characters being typed or deleted are announced through
  the platform's own native accessibility value reporting.
- **Minimum tap target**: Inherited unmodified from the text edit row —
  this is a pointer/trackpad-driven control composition (no touch input
  path in source); the 44×44pt minimum is touch guidance, not a
  pointer-interface requirement.
- **Contrast**: Inherited unmodified from the text edit row — the label
  and the field's typed-text color both resolve to the theme's
  `primaryText` role, and placeholder text resolves to `placeholderText`,
  which is guaranteed only a 1.6:1 contrast floor against the background
  (see design-decisions ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))
  and **contrast-ratio** in Compliance below). Whether an active theme's
  actual resolved colors clear WCAG 2.1 SC 1.4.3's 4.5:1 threshold for
  body text is a property of the chosen theme, not of this component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| secure-text-edit-view-001 | masks-entry-with-secure-field | Construct the component with any view model | The field is a secure, masking field, not a plain text field |
| secure-text-edit-view-002 | initializes-from-view-model | View model's value is "abc" | After construction the secure field's string value is "abc", displayed masked |
| secure-text-edit-view-003 | commits-value-on-change | User types "s3cret" into the secure field and the field's action fires | The view model's setting observer value is "s3cret" |
| secure-text-edit-view-004 | skips-redundant-commits | The field's action fires while its string equals the view model's current value | The view model's setting observer is not written |
| secure-text-edit-view-005 | syncs-on-external-change | The view model's value changes externally and its change callback fires | The secure field's string value shows the new value |
| secure-text-edit-view-006 | exposes-constituent-views | Read the row's label and text field after construction | The label shows the view model's title and the text field is the secure, masking field |
| secure-text-edit-view-007 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |
| secure-text-edit-view-008 | stored-secret-shows-as-dots, reveal-state-not-persisted | Construct with a stored value "sk-123" | The field shows six dots; the eye shows `eye` |
| secure-text-edit-view-009 | eye-toggles-reveal, eye-icon-tracks-state | Value "sk-123"; press the eye | The field shows "sk-123" in plain text; the eye shows `eye.slash`; the setting is not written |
| secure-text-edit-view-010 | eye-toggles-reveal | Shown; press the eye again | The field shows six dots; the eye shows `eye` |
| secure-text-edit-view-011 | copy-puts-secret-on-pasteboard | Obscured, value "sk-123"; press copy | The general pasteboard's string is "sk-123" |
| secure-text-edit-view-012 | copy-disabled-when-empty | Value "" | The copy button is disabled |
| secure-text-edit-view-013 | reobscure-on-window-resign-key | Shown; the window resigns key | The field is obscured |
| secure-text-edit-view-014 | reobscure-on-app-resign-active | Shown; the app resigns active | The field is obscured |
| secure-text-edit-view-015 | reobscure-on-leave-window | Shown; remove the row from its window and add it back | The field is obscured |
| secure-text-edit-view-016 | reobscure-on-external-change | Shown; the setting changes elsewhere to "sk-999" | The field is obscured and holds "sk-999" |
| secure-text-edit-view-017 | edits-commit-in-either-state | Shown; type "sk-777" and the field's action fires | The setting is "sk-777" |

All other conformance test vectors — row layout, content-hugging, action
wiring, view-model sync, theme styling, placeholder restyling,
constituent-view exposure, the initializer traps, and UI-thread
confinement — are inherited unmodified from the text edit row; see
conformance-test-vectors ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)).

## Edge Cases

All edge-case behavior — the non-optional view-model parameter ruling out
a missing value, unbounded text length, UI-thread-serialized concurrent
access, the absence of any throwing or error-producing API, no
networking, and the change-notification-callback overwrite when a second
observer is constructed against the same view model — is inherited
unmodified from the text edit row, whose initializer this component
reuses without change; see
edge-cases ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)).
This component's own edge cases:

- Reveal while editing: switching between obscured and shown keeps the
  typed, uncommitted text and keeps the field first responder.
- Copy while editing: copies the field's current text, which may not be
  committed yet.
- An empty value: copy is disabled; the eye still toggles, so a person can
  see what they type.
- The window resigns key because the person opened a sheet or popover from
  the same window: the secret is obscured anyway; it is the person's to show
  again.
- Two rows bound to the same setting: each has its own shown state; an
  external change made by the other row obscures this one.

## Configuration

Inherited unmodified from the text edit row — this component accepts no
configuration option of its own beyond the view-model parameter
documented at
configuration ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)).
The only thing this specialization changes about that shared
configuration is what the value is typically used for: per the source's
own doc comment, a secret such as an API key or password.

## Deep Linking

Not applicable: this component is a row inside a composable settings
window, not a navigable screen; no URL scheme, route, or deep-link handler
appears anywhere in source or the behavior it inherits.

## Localization

Not applicable: this component's own source contains no user-facing
string literal of its own. The row's title comes entirely from the view
model's title, a value the caller provides, so there is nothing for this
component to localize itself.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Inherited unmodified from the text edit row — source contains no animation or transition call in either file; every state change is an instantaneous property assignment. |
| Increase Contrast | Inherited unmodified from the text edit row — text/label color comes from the theme's `primaryText`/`placeholderText` roles, whose actual resolved contrast (including the placeholder role's 1.6:1 floor — see **contrast-ratio** in Compliance below) is the theme layer's responsibility, not this component's. |
| Differentiate Without Color | Inherited unmodified from the text edit row; also not applicable on its own terms here — masking is communicated by replacing characters with the system's dot glyphs, not by color, so there is no color-only signal for this component to provide an alternative to. |

## Feature Flags

Not applicable: no feature-flag lookup or conditional gate appears
anywhere in this component's own source or the text edit row behavior it
inherits; the row always renders once constructed.

## Analytics

Not applicable: neither this component's own source nor the text edit row
behavior it inherits contains an analytics or telemetry call.

## Privacy

- **Data collected**: The field's typed value — per the source's own doc
  comment, typically a secret such as an API key or password — which the
  platform's secure field masks on screen as it is typed. The component
  does not otherwise classify or redact this value; it holds it in the
  view model's value and passes it through unchanged (see
  privacy ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)) for
  the storage, transmission, and retention behavior this shares with the
  text edit row, which applies to whatever string value either component
  holds).
- **Storage**: Not applicable within this component's own source itself —
  persistence, when it happens, is owned by the caller-supplied view
  model's backing setting: the settings store routes a setting with
  secure storage enabled to a secure storage provider (a keychain-backed
  one, by default) — this is the reason the source recommends this view
  for secrets, but none of it is code in this component's own source
  itself.
- **Transmission**: No networking. The copy button writes the secret to
  the general pasteboard, where any app and Universal Clipboard can read it;
  that is the person's explicit act and the component writes it nowhere
  else.
- **Exposure on screen**: The secret is shown in plain text only after the
  person presses the eye, and only until the window resigns key, the app
  resigns active, the view leaves its window or the setting changes from
  outside; the shown state is never persisted.
- **Retention**: Inherited unmodified from the text edit row — the value
  lives only in the field and the view model's value for as long as the
  row is on screen and its view model is retained; see
  privacy ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)).
- **Security-violation handling**: Not applicable — this component has no
  detection surface of its own (no validation, rate-limiting, or
  authentication logic); it only masks, reveals and copies. Any
  violation-handling behavior belongs to whatever storage/auth layer the
  caller's setting is wired to, outside these two files.

## Logging

Not applicable: neither this component's own source nor the text edit row
behavior it inherits contains a logging call (no print, log, or logger
reference anywhere in source).

## Platform Notes

- **SwiftUI**: Replace with an `HStack` pairing `Text(viewModel.title)`
  leading and a trailing `SecureField("", text: $value)` swapped for a
  `TextField` on the same binding while a `@State var isShown` is true, then
  two `.borderless` image buttons (`doc.on.doc` writing
  `NSPasteboard.general`, and `eye` / `eye.slash` toggling `isShown`).
  Reset `isShown` in `.onChange(of: scenePhase)`, on
  `NSWindow.didResignKeyNotification` via `.onReceive`, in `.onDisappear`
  and when the value changes from outside. The binding's setter writes writing the
  binding's setter back into the underlying setting with an equality guard
  before assigning, mirroring **skips-redundant-commits**. Give the field an
  explicit `.accessibilityLabel(viewModel.title)` — the fix this recipe's
  Accessibility section flags as missing from the AppKit source — and drive
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
  it `Modifier.semantics { contentDescription = title }` (the missing
  accessibility link's Compose analog).
- **React/Web**: A flex row (`display: flex; align-items: center;
  justify-content: space-between`) containing a `<label>` for the title and
  an `<input>` whose `type` is `password` or, while shown, `text`, followed
  by two `<button type="button">`s (copy through
  `navigator.clipboard.writeText`, and the eye with `aria-pressed`); reset
  the shown state on `window` `blur`, `visibilitychange` and unmount. The
  input's `aria-labelledby` points at the title
  `<label>`'s `id` — the web analog of the accessibility link this recipe
  flags as missing from the source. Commit the new value on the input's
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
  two trailing `NSButton`s (borderless, SF Symbols `doc.on.doc`, `eye`,
  `eye.slash`). AppKit has no reveal mode on `NSSecureTextField`, so
  showing swaps in a plain `NSTextField` holding the same string, keeping
  first responder. Copy writes `NSPasteboard.general` with `.string`.
  Re-obscuring observes `NSWindow.didResignKeyNotification` for its window
  (re-registered in `viewDidMoveToWindow`, which also obscures when the
  window becomes nil) and `NSApplication.didResignActiveNotification`, and
  the inherited `viewModel.onChange` sync obscures before it sets the new
  value. The AI Providers editor is SwiftUI, so it hosts this view through
  `NSViewRepresentable` or moves its field rows to the ComposableSettings
  views. `final` is what forecloses further specialization (the
  requirement this recipe's Behavioral Requirements section defers to this
  entry): it makes `SecureTextEditView` the terminal specialization of
  `TextEditView` for masked entry, so the compiler rejects any attempt to
  declare a further subclass of it. The override requires `class func` (not
  `static`) because it overrides `TextEditView`'s `open class func
  makeTextField`, which trips SwiftLint's `static_over_final_class` rule
  (see Design Decisions). `TextEditView.swift`
  ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c)) supplies everything else — row
  layout, content-hugging, the `textFieldChanged(_:)` target/action commit
  path, `observeTheme` styling, and `viewModel.onChange` sync — and is out of
  this recipe's scope. There is no UIKit code path in source; a UIKit port
  would replace `NSSecureTextField` with a `UITextField` configured
  `isSecureTextEntry = true`, and would enforce "no further subclassing" (if
  desired) with a `final` class declaration, UIKit's own equivalent
  mechanism.
- **WinUI 3** (the reason this recipe exists): Build the row as a `Grid`
  with column definitions `Auto,*`: a `TextBlock` for the title in column 0
  and a `PasswordBox` — WinUI's own dot-masking control and the direct
  analog of `NSSecureTextField` — in column 1, `HorizontalAlignment="Stretch"`
  so the `*` column's leftover width goes to the field rather than the
  title (add an `Auto` column holding a copy `Button` with a `SymbolIcon`
  `Copy` writing `Clipboard.SetContent`), the WinUI analog of `expands-text-field-to-fill-row`. Set
  `AutomationProperties.LabeledBy` on the `PasswordBox` to the `TextBlock` —
  the WinUI analog of the `setAccessibilityTitleUIElement` link this recipe
  flags as missing from the AppKit source; add it in the port even though
  the source itself omits it. Commit on the `PasswordBox`'s `LostFocus`
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

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/Views/SecureTextEditView.swift` | confirmed (1.3.2) |

## Design Decisions

Decisions governing the text edit row's inherited behavior — the
content-hugging priority, the factory-method pattern, theme-observation
placement, placeholder-restyle timing, and the placeholder contrast floor
— are recorded at
design-decisions ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))
and are not repeated here.

- **Decision**: Implement this component as a specialization of the text
  edit row that overrides its field construction and adds the accessory
  buttons, rather than composing a new view from scratch.
  **Rationale**: This reuses all of the text edit row's row layout, theme
  styling, and commit wiring; a secure row differs only in its field and
  its two buttons.
  **Approved**: pending
- **Decision**: Re-obscure a shown secret on window resign key, app resign
  active, leaving the window and an external change, and never persist the
  shown state.
  **Rationale**: Each of those is a moment the person may stop watching the
  screen or the value is no longer the one they chose to see; a secret left
  in plain text in a background window is visible to anyone at the screen or
  in a screen share. A new row always starts obscured.
  **Approved**: pending
- **Decision**: Foreclose further specialization of this component
  (AppKit/UIKit source: declared `final`).
  **Rationale**: Traceable to `public final class SecureTextEditView:
  TextEditView` in source — forecloses further subclassing since it is the
  one masking variant the text edit row needs (see Platform Notes).
  **Approved**: pending
- **Decision**: Suppress a lint rule (AppKit/UIKit source: `//
  swiftlint:disable:next static_over_final_class`) on the
  field-construction override.
  **Rationale**: Overriding the text edit row's open factory method
  requires a non-static override even though this component itself
  forecloses further specialization, which trips a lint rule that
  otherwise prefers a static method — this is an intentional, documented
  suppression traceable to the source comment, not an accidental disable,
  and is recorded here per the source-fidelity requirement to document
  known workarounds.
  **Approved**: pending
- **Decision**: Treat storage and persistence of the masked value as
  entirely out of scope of this component's own source.
  **Rationale**: Per the source's own doc comment, the value is
  "typically" routed to a setting with secure storage enabled, which the
  settings store then routes to a keychain-backed secure storage provider;
  this component's own source only masks the on-screen glyphs and never
  itself reads or writes the keychain.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | platform-compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | accessibility |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`native-controls-preference` and `platform-design-language` rest on
`textField` being an unmodified `NSSecureTextField` with AppKit's default
bezel styling (**masks-entry-with-secure-field**) and the accessory buttons
being standard borderless `NSButton`s with SF Symbols; `keyboard-navigable`,
`idempotent-operations`, and `separation-of-concerns` rest on behavior that
is `TextEditView`'s concern and out of this recipe's scope (the field's
inherited, unmodified `NSControl` tab order, **skips-redundant-commits**,
and the view holding no persistence or business logic of its own); `screen-
reader-support` is `partial` because `textField` has no accessibility label
linking it to `label`'s title text — see Label requirements in
Accessibility above; `contrast-ratio` is
`partial` because the inherited placeholder-text color clears only a 1.6:1
floor against WCAG's 4.5:1 threshold (see
design-decisions ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))).

No test in the repository's test targets constructs `SecureTextEditView`, so `unit-test-coverage` is `failed`: a search of `AgenticDeveloperHubSDKMacOSTests` and the other test targets for the type name finds nothing. Its behavior (masking, copy, reveal and the re-obscure rules) is not asserted; the inherited text-row paths are covered by `RecordFieldRefreshTests.swift` for `TextEditView` only.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-23 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-23 | Mike Fullerton | Lint pass: restructure to a delta-only recipe depending on text-edit-view, pruning duplicated requirements/appearance/states/test-vectors/edge-cases/configuration/privacy/logging content to the masking-specific delta (masks-entry-with-secure-field, forecloses-subclassing); reword forecloses-subclassing platform-neutrally and move the `final`/SwiftLint detail to Platform Notes; drop the macos tag; add text-edit-view to depends-on and checkbox-view to related; reformat Design Decisions to the bold convention and move the inherited placeholder-timing/contrast-floor decisions to text-edit-view; fix the WinUI Grid column order (Auto,\*) and correct WinUI/Compose/React commit timing to end-editing/submit instead of per-keystroke; add a partial contrast-ratio compliance row with a supporting sentence; remap compliance citations to the catalog |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.2.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to ui/settings/rows/. |
| 1.3.0 | 2026-10-04 | Mike Fullerton | Added 4 conformance test vectors (inherited text-row behavior applied to the secure field) and the unit-test-coverage Compliance row. |
| 1.3.1 | 2026-10-04 | Mike Fullerton | UI-thread confinement restated as the shared confines-to-ui-thread requirement, with a test vector; the @MainActor mechanism is in Platform Notes. |
| 1.3.2 | 2026-10-04 | Mike Fullerton | Swift-only constructs in normative sections restated as platform-neutral behavior; the Apple mechanism is in Platform Notes. |
| 1.4.0 | 2026-11-19 | Mike Fullerton | Copy and eye buttons, dots for a stored secret, and re-obscure rules for a shown secret |
