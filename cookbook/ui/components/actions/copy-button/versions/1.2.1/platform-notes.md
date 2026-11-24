
- **SwiftUI**: A Swift equivalent would compose the native `Button` with a clipboard
  write. SwiftUI has no built-in clipboard API; use `NSPasteboard.general.setString(_:forType:)`
  (macOS) or set `UIPasteboard.general.string` (iOS). Writing requires no app
  entitlement on either platform — the iOS 16+ system paste-permission prompt applies
  only when *reading* another app's pasteboard content, not when writing. The 1200ms
  flash pattern and glyph swap work identically via `@State` transitions.
- **Compose (Android)**: Use `IconButton` in Material 3 Compose, paired with
  `LocalClipboardManager.current.setText(...)` for the write. The lazy text
  resolution pattern (`getText` thunk) maps cleanly to a lambda. Success state and
  icon swap work via `remember { mutableStateOf() }`. Writing via `ClipboardManager`
  requires no runtime permission on modern Android.
- **React/Web**: Source files `packages/web/packages/ui/src/components/copy-button.tsx` and hook `packages/web/packages/ui/src/hooks/useClipboard.ts`. The component carries `"use client"` directive (reads `navigator.clipboard` and holds transient `copied` state). Composes the shared `Button` (variant="outline", size="icon", overridden to size-6) and lucide `Copy`/`Check` icons. Demo available in `ui-showcase` Topic "copy-button" under "Composite controls" group (regenerate `sources.generated.ts` via `gen-sources.py` after source changes).
- **AppKit / UIKit**: `NSButton` (macOS) or `UIButton` (iOS) styled with outline
  appearance and a smaller icon size. Clipboard write via
  `NSPasteboard.general.setString(_:forType:)` (macOS) or `UIPasteboard.general.string`
  (iOS). Implement the 1200ms timer with `Timer.scheduledTimer` or
  `DispatchSourceTimer`. Writing requires no entitlement or permission on either
  platform; only *reading* another app's pasteboard content triggers the iOS 16+
  user-facing paste prompt, which does not apply here.
- **WinUI 3**: Use `Button` with `IconSource` (lucide or Segoe Fluent icon assets for
  `Copy` → `CheckMark` swap). Clipboard write via
  `Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(DataPackage)` — put the
  text on a `DataPackage` via `SetText()` and pass it to `SetContent`; there is no
  `Clipboard.SetTextAsync()` API. The 1200ms revert uses `DispatcherTimer`. Clipboard
  writes require no declared capability in either the packaged (UWP) or unpackaged
  (Win App SDK) model.

