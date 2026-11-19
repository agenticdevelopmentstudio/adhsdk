
- **SwiftUI**: A `Button` with a `chevron.down` `Image` and a `.link`-styled
  name button in an `HStack`, with `.popover(isPresented:arrowEdge:)` attached
  to the caret. The popover's content is a `NavigationSplitView`-free `HStack`
  of a `List(selection:)` with `.searchable` and a detail `ScrollView`;
  `.onChange(of: selection)` calls the choice closure for user changes,
  `.onSubmit` chooses and dismisses, and `@FocusState` gives the search
  field focus on appear. Guard against the initial selection firing the
  closure.
- **Compose**: A `Row` of a `Text` label, an `IconButton` with
  `Icons.Default.KeyboardArrowDown` and a `TextButton` name; the chooser in a
  `Popup` (or `DropdownMenu` for a narrow one) anchored to the icon button,
  holding a `TextField` with a `FocusRequester` requested on open and a
  `LazyColumn` whose row `clickable` chooses. `onDismissRequest` handles
  Escape and outside taps; Enter is an `onKeyEvent` on the field.
- **React/Web**: A `<span>` label, a `<button aria-label="AI Model model
  chooser">` caret and a link-styled `<button>` name; the chooser is a
  popover (`popover` attribute or a positioned dialog) anchored to the caret,
  with an `<input type="search" autofocus>` and a `role="listbox"` list whose
  `onClick` chooses. Escape and outside clicks close it (`popover="auto"`
  gives both); Enter on the input chooses and closes.
- **AppKit/UIKit** (source platform): All under
  `packages/apple/AgenticDeveloperHubSDK/macOS/Features/AIPlugins/Settings/`.
  `ModelChooserViewController.swift` holds `ModelChooserContext`, the
  `NSViewController` and the `ModelChooser.present(relativeTo:context:onChoose:)`
  entry point, which shows it in an `NSPopover` with `behavior = .transient`
  and `preferredEdge` `.maxY` (falling back to `.minY`); the old app-modal
  window, its frame persistence and the OK/Cancel buttons are removed.
  `PickerKeyboardController` maps the search field's `moveUp:`/`moveDown:`,
  `insertNewline:` and `cancelOperation:` commands. The large-model
  confirmation is an `NSAlert` begun as a sheet on the popover's window
  (`beginSheetModal(for:)`), never `runModal()`. `AIModelPickerControl.swift`
  is the `NSView` row: an `NSTextField` label, a borderless `NSButton` with
  `NSImage(systemSymbolName: "chevron.down")`, a colon label and a
  borderless name button styled as a link; its inputs are
  `displayName: () -> String?`, `context: () -> ModelChooserContext?` and
  `onChoose: (String) -> Void`, plus `refresh()`. The AI chat window's
  Choose Model… opens the same popover. A UIKit port would use
  `UIPopoverPresentationController` with `sourceView` set to the caret.
- **WinUI 3**: The control is a horizontal `StackPanel` of a `TextBlock`, a
  `Button` styled `{StaticResource AlternateCloseButtonStyle}`-like with a
  `FontIcon Glyph="&#xE70D;"` (ChevronDown) and a `HyperlinkButton` for the
  name. The chooser is a `Flyout` (`Placement="Top"`, falling back to
  `Bottom` through `FlyoutPlacementMode.Auto`) attached to the caret
  (`FlyoutBase.ShowAttachedFlyout`), holding a `Grid` with an
  `AutoSuggestBox` or `TextBox` over a `ListView`
  (`SelectionMode="Single"`, `SelectionChanged` choosing only when
  `e.AddedItems` came from user input) beside a `ScrollViewer` detail. Focus
  the box in the flyout's `Opened` handler with `Focus(FocusState.Programmatic)`;
  `KeyDown` Enter chooses and calls `Hide()`; light dismiss handles Escape and
  outside clicks. The large-model confirmation is a `ContentDialog` with
  `XamlRoot` set to the flyout's. Set
  `AutomationProperties.Name` on the chevron button to "<label> model
  chooser".

