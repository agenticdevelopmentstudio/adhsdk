---
id: b3059939-21f5-414b-82e4-edd11b192ae8
title: "Model Picker"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-19
modified: 2026-11-19
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A popover model chooser for one provider, and the `AI Model ⌄: <name>` control that is its only anchor."
platforms:
  - swift
  - macos
tags:
  - ai-plugins
  - model-selection
  - popover
  - settings
depends-on:
  - c8438764-89c9-4286-9b58-10c9cd175a97
  - f628f7f9-9c7b-4820-a4bf-231312a74839
  - 5069f11f-e0c6-40c3-92ca-6152b8df3bc2
related:
  - e886e448-6aa5-4359-979d-49fba713ab2a
  - c9385bf6-3abc-486b-82b5-d57a62d86735
references: []
approved-by: ""
approved-date: ""
---

# Model Picker

## Overview

The model picker is how a person chooses one provider configuration's model
anywhere a host app configures AI: the AI Providers panel's
default model, the Coding Partner, AI Summaries, AI Oversight, the Sessions
window and the AI chat window. It is one component in two parts:

- **The model chooser**: a filterable list of the provider's models beside a
  detail pane describing the selected one (capabilities, specs, provider
  terms, memory fit, popularity, rank, description), shown in a transient
  popover. It is presented only through one entry point, which takes the view
  to point at, a chooser context (the provider's plugin, template, base URL,
  key, current model and memory-guard thresholds) and a choice callback.
- **The model picker control**: a settings row reading
  `<label> ⌄ : <model name>`. Clicking its caret or its name opens the
  chooser, anchored to the caret. It is the chooser's only anchor in settings.

The control knows nothing about storage. Its caller supplies, through
injected closures, the name to show, the context to list and what to do with
a choice. The combined provider-and-model control
([adhsdk.ingredient.ai.plugins.provider-model-picker](cookbook:c9385bf6-3abc-486b-82b5-d57a62d86735)) is the
usual caller; the AI Providers panel's default model row
([adhsdk.ingredient.ai.plugins.plugin-runtime](cookbook:e886e448-6aa5-4359-979d-49fba713ab2a)) is another.

What the list holds and how it filters (the use facets, the fits-this-Mac
filter, the all-versions toggle, the scattered-letter search) is the model
catalog's and the facets' business
([adhsdk.ingredient.ai.models.model-catalog](cookbook:c8438764-89c9-4286-9b58-10c9cd175a97),
[adhsdk.ingredient.ai.models.model-use-facet](cookbook:f628f7f9-9c7b-4820-a4bf-231312a74839)); the
large-model tiers are the fit policy's
([adhsdk.ingredient.ai.models.local.model-fit-policy](cookbook:5069f11f-e0c6-40c3-92ca-6152b8df3bc2)). This
ingredient covers the presentation, the choosing rules and the control.

## Behavioral Requirements

### Presentation

- **single-presentation-path**: The chooser MUST be presented only through
  its one entry point, which takes an anchor view, a chooser context and a
  choice callback. It MUST NOT be presented in a window of its own, and it
  MUST have no OK or Cancel button.
- **transient-popover**: The entry point MUST show the chooser in a transient
  popover pointing at the given anchor view, on the anchor's bottom edge
  (below the anchor, whichever way its coordinates run).
- **fixed-content-size**: The popover MUST open at the chooser's fixed
  content size, 720 by 450 points, not at the chooser's fitting size.
- **one-chooser-at-a-time**: Presenting the chooser while one is already shown
  MUST close the shown one first, so at most one chooser is open.
- **search-field-focus**: When the popover opens, the chooser's search field
  MUST be first responder, so typing filters the list at once.
- **opens-on-current-model**: The chooser MUST open with the row of the
  context's current model selected (a stored alias selects the row of the
  model it resolves to). Opening, and the selection the list makes for itself
  when it reloads or filters, MUST NOT choose a model.

### Choosing

- **select-chooses-and-stays-open**: A click on a row MUST choose that row's
  model at once, calling the choice callback, and MUST leave the popover
  open, so the detail pane and the choice can be compared.
- **arrow-moves-only**: An arrow key in the search field MUST move the
  selection (and the detail pane with it) without choosing; Return then
  chooses the selected row.
- **return-chooses-and-closes**: Return in the search field, or a double-click
  on a row, MUST choose the selected row's model and close the popover.
- **escape-or-outside-closes**: Escape, or a click outside the popover, MUST
  close it without choosing anything further; a model already chosen by a
  selection stays chosen.
- **chooses-only-visible-rows**: Return MUST choose nothing when the current
  filter leaves no row visible; it MUST NOT choose a row an earlier keystroke
  selected and the filter has since hidden.
- **repeat-choice-reported**: A click, Return or double-click on the row
  already chosen MUST call the choice callback again with the same value;
  the chooser does not filter repeats.
- **alias-kept-when-unchanged**: Choosing the row the context's stored model
  resolves to (a stored alias such as `fast` opens on the model it runs
  today) MUST report the stored value, not the resolved model, so the alias
  keeps following the newest model of its family.
- **large-model-confirmation**: Choosing a model whose memory fit is in the
  warn tier MUST first show one app-modal confirmation alert, with the
  popover's dismissal on outside clicks suspended until it is answered, and
  MUST call the choice callback
  only when the person confirms. Declining MUST leave the previously chosen
  model chosen and the popover open. A block-tier model MUST stay choosable
  with no confirmation; its fit line already says it will not run.
- **live-list-refresh**: The chooser MUST open on the last loaded model list
  and replace it with the provider's live list when that arrives, keeping the
  selected row (following an alias to what it now resolves to). A refresh
  MUST NOT choose a model.

### The Model Picker Control

- **control-layout**: The control MUST lay out, in one row, a label, a caret
  button, a colon and a name button: `<label> ⌄ : <model name>`.
- **control-default-label**: The label MUST default to "AI Model" and MUST be
  settable by the caller.
- **control-name-text**: The name button MUST show the name the display-name
  closure returns, and "Choose a Model" when that closure returns none or an
  empty string. When the context closure returns a context, the name MUST be
  passed through that context's display-name lookup (the context resolves an
  alias to its id and returns the display name it has for it, or the id
  unchanged when it has none); the control does no lookup of its own.
- **control-name-truncates-middle**: A name too long for the row MUST be
  truncated in the middle, so its start and end stay readable.
- **control-opens-chooser**: Clicking the caret or the name button MUST
  present the chooser through its one entry point, anchored to the caret,
  with the context the context closure returns at that moment.
- **control-forwards-choice**: Each model the chooser reports MUST be passed
  to the caller's choice closure, and the control MUST then re-read its name.
- **control-refresh**: Refreshing the control MUST re-read the name from the
  display-name closure and the enabled state from the context closure.
- **control-disabled-without-context**: The control MUST be disabled (caret
  and name both) when the context closure returns none, and clicking it then
  MUST NOT open anything.
- **control-no-globals**: The control MUST take everything it shows and does
  through its injected closures and MUST NOT read settings, a plugin manager
  or any other shared state itself.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

## Appearance

- **Corner radius**: The popover's own; the chooser sets none.
- **Padding**: The chooser keeps its current layout inside the popover: the
  search field above the list on the left, the detail pane on the right,
  divided by a split; the detail pane uses the composable settings panel's
  standard insets. The control uses the settings row insets of the panel it
  sits in, with the platform's standard spacing between label, caret, colon
  and name.
- **Font**: The control's label uses the theme's body font, like every
  settings row label. The name button uses the body font in the link style
  (the accent color, no bezel). List rows use the body font; the detail
  pane's heading uses the heading font, its fact lines the caption font and
  its description the body font.
- **Background**: The popover's material behind the chooser; the list's scroll
  host paints the theme's surface color.
- **Foreground/Text**: Control label: primary text color. Caret: a borderless
  button showing the `chevron.down` symbol in the secondary text color. Name
  button: the accent color, as a link. Detail fit line: secondary text when
  the model fits, warning color in the warn tier, danger color in the block
  tier.
- **Border**: None on the control's buttons (both borderless).
- **Shadow**: The popover's own; none of the component's.
- **Min/Max size**: The popover has a fixed content size of 720×450 points;
  the list keeps its width and the detail pane takes the rest.

## States

| State | Appearance change |
|-------|------------------|
| Default (control) | `AI Model ⌄ : <model name>`; caret and name enabled. |
| No model (control) | The name button reads "Choose a Model"; still enabled when a context exists. |
| Disabled (control) | No context: caret and name disabled and dimmed; clicking does nothing. |
| Open | The popover points at the caret; the search field has focus; the current model's row is selected and described. |
| Pressed | The caret or name button shows its platform pressed state while the mouse is down. |
| Focused | The search field shows the platform focus ring while the popover is open. |
| Loading | The list shows the last loaded models while the live list loads; there is no spinner, and rows and detail lines update in place as data arrives. |
| Confirming | A warn-tier choice shows the large-model confirmation; the list does not change until it is answered. |

## Accessibility

- **Role/trait**: The caret and the name are buttons; the label is static text.
  The chooser's list is a table and its search field a search field.
- **Label requirements**: The caret button's symbol MUST carry the
  accessibility description "Choose a model" (it shows only a symbol), and
  the name button MUST use the control's label as its accessibility title
  element, so a screen reader reads the shown name with the label as its
  title rather than a bare model id.
- **Announce state changes**: Opening the popover moves focus to the search
  field, which the platform announces; a chosen model updates the name
  button's title, which the platform reports.
- **Minimum tap target**: Pointer-driven controls on macOS; the 44×44pt
  minimum is touch guidance. The caret is a borderless, inline-bezel symbol
  button at the platform's regular control size (the control sets no smaller
  size).
- **Contrast**: Colors come from theme roles (primary and secondary text,
  accent, warning, danger); whether a theme's resolved values clear 4.5:1 is
  the theme's property, not this component's.

Keyboard: Tab reaches the caret and the name button; Space or Return on
either opens the chooser. In the popover, the arrow keys move the selection
from the search field, Return chooses and closes, and Escape closes.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| model-picker-001 | single-presentation-path, transient-popover | Present the chooser for a control's caret | A transient popover points at the caret; no window titled for the chooser exists; the chooser has no OK or Cancel button |
| model-picker-002 | search-field-focus | Present the chooser | The search field is first responder |
| model-picker-003 | opens-on-current-model | Context current model `fast`, which resolves to `acme-fast-2` | The `acme-fast-2` row is selected; the choice callback has not been called |
| model-picker-004 | select-chooses-and-stays-open | Open with `m1` current; click the `m2` row | The choice callback is called once with `m2`; the popover is still shown |
| model-picker-005 | arrow-moves-only, return-chooses-and-closes | Open; arrow down to `m3`; press Return | The arrow move calls nothing; the callback receives `m3` once, for Return; the popover is closed |
| model-picker-006 | escape-or-outside-closes | Open with `m1` current; press Escape | The popover is closed; the callback was never called |
| model-picker-007 | chooses-only-visible-rows | Type a query matching no model; press Return | The callback is not called |
| model-picker-008 | alias-kept-when-unchanged | Context current model `fast`; select another row, then double-click the `acme-fast-2` row | The last value the callback receives is `fast` |
| model-picker-009 | large-model-confirmation | A local model in the warn tier; click its row, then decline the confirmation | The callback is not called for it; the previously chosen model stays chosen; the popover is still shown |
| model-picker-010 | large-model-confirmation | A local model in the block tier; click its row | No confirmation is shown; the callback receives that model |
| model-picker-011 | control-name-text, control-default-label | Display name closure returns none | The control reads `AI Model ⌄ : Choose a Model` |
| model-picker-012 | control-opens-chooser | Click the name button | The chooser opens anchored to the caret with the context closure's current value |
| model-picker-013 | control-forwards-choice | The chooser reports `m2`; the display-name closure now returns "Model Two" | The caller's choice closure receives `m2`; the name button reads "Model Two" |
| model-picker-014 | control-disabled-without-context | Context closure returns none; click the caret | Both buttons are disabled; nothing is presented |
| model-picker-015 | one-chooser-at-a-time | Present for control A, then present for control B | Only B's popover is shown |
| model-picker-016 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |
| model-picker-017 | fixed-content-size | Present the chooser | The popover's content size is 720×450 points |
| model-picker-018 | live-list-refresh | Open with `m1` selected; the live list arrives with `m1` and a new `m4` | The `m4` row is listed; `m1` stays selected; the callback is not called |
| model-picker-019 | live-list-refresh | Context current model `fast`; the live list arrives in which `fast` resolves to `acme-fast-3` | The `acme-fast-3` row is selected; the callback is not called |
| model-picker-020 | control-refresh | The display-name closure starts returning "Model Two" and the context closure starts returning none; refresh the control | The name button reads "Model Two"; both buttons are disabled |
| model-picker-021 | control-no-globals | Build the control from a display-name closure, a context closure over a stub context and a recording choice closure, with no settings or plugin manager supplied; choose `m2` | The control shows the stub's name, opens on the stub context and reports `m2` to the recording closure |
| model-picker-022 | escape-or-outside-closes | Open with `m1` current; click outside the popover | The popover is closed; the callback was never called |
| model-picker-023 | return-chooses-and-closes | Open; double-click the `m3` row | The callback receives `m3`; the popover is closed |
| model-picker-024 | control-name-truncates-middle | The display-name closure returns a name wider than the row | The name button shows the name's start and end with an ellipsis between them |
| model-picker-025 | repeat-choice-reported | Open; click the `m2` row, then click the `m2` row again | The callback is called twice, each time with `m2` |

## Edge Cases

- A provider whose template lists no models and has no live source: the list
  shows only the current model (when there is one); the popover still opens.
- A context whose current model is empty: no row is chosen at open; the first
  row is selected for the detail pane but not chosen.
- The live list arrives after the person has chosen a row: the chosen row
  stays selected, and the arrival does not call the choice callback.
- The anchor view leaves its window while the popover is open (its settings
  panel is switched away): the popover closes.
- The person clicks outside the popover while the large-model confirmation
  is up: the confirmation is app-modal and the popover's outside-click
  dismissal is suspended, so the popover stays open until the confirmation
  is answered.
- A very long model name: the name button truncates in the middle
  (**control-name-truncates-middle**).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Anchor view | view | — (required) | The view the popover points at; the control passes its caret. |
| Chooser context | chooser context | — (required) | Plugin identifier, provider template, base URL, API key, current model, and warn and block thresholds (percent of RAM, defaulting to the fit policy's). |
| Choice callback | function from model id | — (required) | Called with each model chosen. |
| Label (control) | text | "AI Model" | The control's leading label. |
| Display name (control) | function returning optional text | — (required) | The name to show; none or empty shows "Choose a Model". |
| Context (control) | function returning an optional chooser context | — (required) | What the chooser lists; none disables the control. |
| On choose (control) | function from model id | — (required) | Receives each chosen model. |

## Deep Linking

Not applicable: the chooser is a transient popover over a settings row, not
a navigable screen, and has no route of its own.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `AI Model` | The control's default label |
| (none — hardcoded literal) | `Choose a Model` | The control's name when no model is shown |
| (none — hardcoded literal) | `Choose a model` | The caret symbol's accessibility description |
| (none — hardcoded literal) | `Good for` | The use filter's label |
| (none — hardcoded literal) | `Filter models` | The search field's placeholder |
| (none — hardcoded literal) | `Fits this Mac` | The fit filter's title |
| (none — hardcoded literal) | `All versions` | The all-versions toggle's title |
| (none — hardcoded literal) | `Large model` | The large-model confirmation's title |
| (none — hardcoded literal) | `Use Model` | The large-model confirmation's accept button |
| (none — hardcoded literal) | `Cancel` | The large-model confirmation's decline button |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The popover's open and close animation is the platform's, which honors Reduce Motion itself; the component adds no animation. |
| Increase Contrast | Colors come from theme roles; the theme layer resolves their high-contrast values. |
| Differentiate Without Color | The fit tier is spelled out in its line's text ("⚠ large", "won't run"), not shown by color alone. |

## Feature Flags

Not applicable: the chooser and the control are always available; no flag
gates them.

## Analytics

Not applicable: neither part records an analytics or telemetry event.

## Privacy

- **Data collected**: None of the component's own. The context carries the
  provider's API key so the chooser can fetch the provider's live model list.
- **Storage**: None. The component stores no setting; the caller decides what
  to do with a chosen model.
- **Transmission**: The live model list, model metadata, descriptions,
  popularity and ranks are fetched through the provider model stores the
  chooser uses, with the context's key for the provider's own list; the
  component sends nothing else.
- **Retention**: The context lives only while the popover is open.
- **Security-violation handling**: Not applicable: the component has no
  detection surface; a key the provider rejects only leaves the live list
  unloaded.

## Logging

Not applicable: the component logs nothing of its own; the model stores it
calls own their logging.

## Platform Notes

- **SwiftUI**: A `Button` with a `chevron.down` `Image` and a `.link`-styled
  name button in an `HStack`, with `.popover(isPresented:arrowEdge:)` attached
  to the caret. The popover's content is an `HStack` (not a
  `NavigationSplitView`)
  of a `List(selection:)` with `.searchable` and a detail `ScrollView`;
  a row's tap gesture calls the choice closure, `.onChange(of: selection)`
  only updates the detail (so arrow moves never choose), `.onSubmit`
  chooses and dismisses, and `@FocusState` gives the search field focus on
  appear.
- **Compose**: A `Row` of a `Text` label, an `IconButton` with
  `Icons.Default.KeyboardArrowDown` and a `TextButton` name; the chooser in a
  `Popup` (or `DropdownMenu` for a narrow one) anchored to the icon button,
  holding a `TextField` with a `FocusRequester` requested on open and a
  `LazyColumn` whose row `clickable` chooses. `onDismissRequest` handles
  Escape and outside taps; Enter is an `onKeyEvent` on the field.
- **React/Web**: A `<span>` label, a `<button aria-label="Choose a
  model">` caret and a link-styled `<button>` name whose `aria-labelledby`
  names the label and itself; the chooser is a
  popover (`popover` attribute or a positioned dialog) anchored to the caret,
  with an `<input type="search" autofocus>` and a `role="listbox"` list whose
  `onClick` chooses. Escape and outside clicks close it (`popover="auto"`
  gives both); Enter on the input chooses and closes.
- **AppKit/UIKit** (source platform): All under
  `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/`.
  `ModelChooserViewController.swift` holds `ModelChooserContext`, the
  `NSViewController` and the `ModelChooser.present(relativeTo:context:onChoose:)`
  entry point, which shows it in an `NSPopover` with `behavior = .transient`
  and `preferredEdge` `view.isFlipped ? .maxY : .minY`, the anchor's bottom
  edge either way (below the anchor). The 720×450 content
  size is set three times: as the root view's frame in `loadView` and as
  `preferredContentSize` (nothing inside pins a height, so the fitting size
  would be just the filter row), and as the popover's `contentSize` after
  `contentViewController` is assigned, since assigning it resizes the popover.
  `PickerKeyboardController` maps the search field's `moveUp:`/`moveDown:`,
  `insertNewline:` and `cancelOperation:` commands. The large-model
  confirmation is an `NSAlert` run with `runModal()` while the presenter
  switches the popover's `behavior` to `.applicationDefined`, so the alert
  taking the key window does not close the transient popover; the behavior
  is restored when the alert returns. `AIModelPickerControl.swift`
  is the `NSView` row: an `NSTextField` label, a borderless `NSButton` with
  `NSImage(systemSymbolName: "chevron.down")`, a colon label and a
  borderless name button styled as a link; its inputs are
  `displayName: () -> String?`, `context: () -> ModelChooserContext?` and
  `onChoose: (String) -> Void`, plus `refresh()`. The AI chat window's
  Choose Model… opens the same popover. A UIKit port would use
  `UIPopoverPresentationController` with `sourceView` set to the caret.
- **WinUI 3**: The control is a horizontal `StackPanel` of a `TextBlock`, a
  `Button` with a transparent background and no border (a subtle button
  style) holding a
  `FontIcon Glyph="&#xE70D;"` (ChevronDown) and a `HyperlinkButton` for the
  name. The chooser is a `Flyout` (`Placement="Bottom"`, below the anchor)
  attached to the caret
  (`FlyoutBase.ShowAttachedFlyout`), holding a `Grid` with an
  `AutoSuggestBox` or `TextBox` over a `ListView`
  (`SelectionMode="Single"`, `IsItemClickEnabled="True"`, `ItemClick`
  choosing and `SelectionChanged` only updating the detail) beside a `ScrollViewer` detail. Focus
  the box in the flyout's `Opened` handler with `Focus(FocusState.Programmatic)`;
  `KeyDown` Enter chooses and calls `Hide()`; light dismiss handles Escape and
  outside clicks. The large-model confirmation is a `ContentDialog` with
  `XamlRoot` set to the flyout's. Set
  `AutomationProperties.Name` on the chevron button to "Choose a model",
  and `AutomationProperties.LabeledBy` on the name button to the label.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/ModelChooserViewController.swift` | confirmed (1.1.0) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/AIModelPickerControl.swift` | confirmed (1.1.0) |

## Design Decisions

- **Decision**: Show the chooser in a transient popover pointing at the
  control's caret, with no OK or Cancel button, instead of an app-modal
  window.
  **Rationale**: A modal window took the whole app for a one-field choice and
  hid the setting it changed; a popover keeps the row in view and closes on
  Escape or a click outside, the platform's own way to dismiss a picker. The
  modal window's frame persistence and its OK and Cancel buttons went with it.
  **Approved**: pending
- **Decision**: A click on a row chooses at once and the popover stays open;
  Return or a double-click chooses and closes.
  **Rationale**: The detail pane is how models are compared, so choosing must
  not end the comparison; with every click applied, there is nothing left for
  an OK button to confirm.
  **Approved**: pending
- **Decision**: The control is the chooser's only anchor in settings, and it
  takes closures rather than settings.
  **Rationale**: One control means one way to choose a model everywhere a
  provider is configured, and closures let the AI Providers panel, the
  combined provider-and-model control and the chat window bind it to their
  own settings without the control knowing any of them.
  **Approved**: pending
- **Decision**: Keep the stored alias when the person chooses the row it
  resolves to.
  **Rationale**: An alias follows the newest model of its family; replacing
  it with today's resolved id whenever the person merely looked would pin the
  configuration without their asking.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`native-controls-preference` rests on `NSPopover`, `NSSearchField`,
`NSTableView` and borderless `NSButton`s; `keyboard-navigable` and
`focus-management` on **search-field-focus**, the arrow, Return and Escape
paths and the control's two tab stops; `screen-reader-support` on the
caret's accessibility description and the name's title element. `separation-of-concerns`
passes because the control holds no storage (**control-no-globals**) and the
chooser reports choices through a callback. `unit-test-coverage` is `failed`
until the choosing rules (**select-chooses-and-stays-open**,
**alias-kept-when-unchanged**, **large-model-confirmation**) and the
control's name and enabled rules have tests; the code exists, and those
tests are what is missing.
`no-hardcoded-strings` fails because the strings under Localization are
English literals.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-19 | Mike Fullerton | Lint pass: arrow keys move without choosing, repeat choices are reported, popover opens below the caret, accessibility names match the code, more vectors |
| 1.0.1 | 2026-11-19 | Mike Fullerton | Fixed popover content size; the name shows a known id by its display name |
| 1.0.0 | 2026-11-19 | Mike Fullerton | Initial creation, ahead of the code: the popover chooser and the AI model picker control |
