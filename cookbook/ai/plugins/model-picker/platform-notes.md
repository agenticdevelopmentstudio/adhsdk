
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

