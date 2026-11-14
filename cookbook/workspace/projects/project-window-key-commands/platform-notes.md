
- **SwiftUI**: Use `.commands { CommandGroup(...) }` with `Button` items and
  `.keyboardShortcut("0", modifiers: .command)`; the key window check becomes
  `@FocusedValue` or `@FocusedObject`, which disables the item (rather than
  declining) when no project window is focused.
- **Compose**: Desktop Compose has `Modifier.onPreviewKeyEvent` or window menu
  `Item(shortcut = KeyShortcut(Key.Zero, meta = true))`; return `false` from the
  handler to let the event fall through, as the source returns `false`.
- **React/Web**: Register a `keydown` listener (or `react-hotkeys-hook`) for
  Meta+0 and Meta+1 (Ctrl on non-Mac) that acts only when the project window root
  has focus and otherwise does not call `preventDefault`, so the chord falls
  through. Browsers reserve Command-0 and Command-1 for zoom and tab selection.
- **AppKit / UIKit**: Source file:
  `macOS/Features/Projects/ProjectWindowKeyCommands.swift`, built on the
  `KeyboardShortcuts` package (`KeyboardShortcuts.Shortcut`),
  `KeyCommandSection`, `KeyCommandDescriptor`, `KeyCommandRegistry.shared` and
  the `ProjectShelfWindow` protocol that the composable-tabs window controller and
  the empty project window controller conform to. The target is
  `KeyCommandRegistry.shared.commandWindow`'s `windowController`. UIKit uses
  `UIKeyCommand` with `UIKeyCommand.inputZero`-style inputs and the responder
  chain, which replaces the explicit key-window lookup.
- **WinUI 3**: Use `KeyboardAccelerator` on a `MenuFlyoutItem` or a
  `XamlUICommand` with `KeyboardAccelerators` (`Key = VirtualKey.Number0`,
  `Modifiers = VirtualKeyModifiers.Control`; Windows uses Control where macOS
  uses Command). Set `KeyboardAccelerator.Invoked` args `Handled = false` to
  decline. Scope it with `KeyboardAcceleratorPlacementMode` or by attaching the
  accelerators to the project window's content so they act only when that
  window is active; write the log entry with `ILogger.LogDebug`.

