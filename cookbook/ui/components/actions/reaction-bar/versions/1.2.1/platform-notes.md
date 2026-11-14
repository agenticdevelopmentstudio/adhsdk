
- **React/Web**: File: `packages/web/packages/ui/src/components/reaction-bar.tsx`, exported from `@adh-sdk/ui/components/reaction-bar` via the package's `./components/*` wildcard. Composes the shared `Button` and `Popover`/`PopoverTrigger`/`PopoverContent` primitives, plus a lucide `SmilePlus` icon; carries `"use client"` directive to own the popover's open state. Themes via `@adh-sdk/ui` token system (`apt-gold`, `apt-border`, `apt-text-*`, etc.).

- **SwiftUI**: `VStack`/`HStack` do not wrap, so use a custom flow `Layout` for the chip row.
  Each reaction is a SwiftUI `Button` with its pressed state driven from the `mine` input, not
  from local state, and announced via `.accessibilityAddTraits(mine ? .isSelected : [])` — the
  equivalent of `aria-pressed`. The palette could be a `Menu` or custom `Popup`/`Popover` with
  emoji buttons. Count display uses `Text` with `.monospacedDigit()` font modifier. `@State` is
  used only for whether the palette is open or closed.

- **Compose**: `Row` with `Modifier.fillMaxWidth()` does not wrap, so use `FlowRow` for the chip
  row. Each reaction is a `Button` composable with the pressed state exposed via
  `Modifier.toggleable(value = mine, onValueChange = { ... })` or
  `Modifier.semantics { selected = mine }` — the equivalent of `aria-pressed` — plus a separate
  trigger `Button` styled as a circular icon for the palette. Palette is a `Popup` or
  `DropdownMenu`. Counts display in `Text` with `style = TextStyle(fontFeatureSettings = "tnum")`
  for monospaced digits (`fontFeatureSettings` is a `TextStyle` parameter, not a modifier). Use
  `remember { mutableStateOf(false) }` only for palette open state.

- **AppKit / UIKit**: `NSStackView`/`UIStackView` do not wrap, and `.fillEqually` is wrong for
  chips of different widths, so use `NSCollectionView` (AppKit) or `UICollectionView` (UIKit)
  with a flow layout. Each chip is an `NSButton` (AppKit) with `.pushOnPushOff` for toggle
  semantics, or a `UIButton` (UIKit) with the `.selected` trait bound to `mine`. The palette is
  an `NSPopover` (AppKit) or a `UIMenu`/`UIAction` presented via a
  `UIPopoverPresentationController` (UIKit; `UIMenuActions` does not exist). Accessibility via
  `NSAccessibilityRole` (AppKit) or `accessibilityTraits` (UIKit) set to `.button`, with custom
  `NSAccessibilityElement` / `accessibilityLabel` construction for each chip and trigger.

- **WinUI 3**: `StackPanel` has no `TextWrapping` property, so use an `ItemsRepeater` with a
  `WrapLayout` (or a `WrapPanel`) for the row. Each reaction is a `ToggleButton` with `IsChecked`
  bound to `mine` (`Button` has no `IsToggled` property), styled per the Fluent 2 Design System.
  The palette is a `Flyout` or `MenuFlyout` attached to a `Button` trigger. Count display uses
  `TextBlock` with `FontFamily="Segoe UI Variable"` and `Typography.NumeralAlignment="Tabular"`
  for tabular numerals (`NumberSubstitution.CultureOverride` does not give tabular digits).
  Accessibility via `AutomationProperties.Name` (equivalent to aria-label) for every interactive
  element.

