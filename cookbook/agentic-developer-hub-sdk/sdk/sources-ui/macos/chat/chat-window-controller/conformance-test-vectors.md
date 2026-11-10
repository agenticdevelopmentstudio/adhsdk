
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cwc-001 | own-chat-view | Initialize with valid view model | `controller.chatView` returns non-nil `InlineChatView` |
| cwc-002 | own-appearance-controller | Initialize with valid configuration | `controller.appearance` returns non-nil `ChatWindowAppearanceController` |
| cwc-003 | configure-from-struct | Create `ChatWindowConfiguration` and pass to init | Controller stores all configuration values and passes them to window and appearance controller |
| cwc-004 | hide-title-bar | Initialize and inspect window | Window's `titleVisibility` is `.hidden`, `titlebarAppearsTransparent` is `true`, and `standardWindowButton(_:)?.isHidden` is `true` for `.closeButton`, `.miniaturizeButton`, and `.zoomButton` |
| cwc-005 | translucent | Initialize and inspect window | Window's `isOpaque` is `false`, `backgroundColor` is `.clear` |
| cwc-006 | size-window-correctly | Initialize with `contentSize = NSSize(width: 500, height: 700)` | Window's `contentView.frame.size` is exactly `NSSize(width: 500, height: 700)` |
| cwc-007 | restore-frame | Initialize with namespace `N`, move and resize the window (AppKit records the new frame per **autosave-frame**), deinit the controller, then initialize a new controller with the same namespace `N` | The new window's frame matches the previously recorded position and size exactly, restored via `setFrameUsingName(_:)` during init |
| cwc-008 | autosave-frame | Initialize with namespace `N`, move or resize the window once | The frame is written to `UserDefaults.standard` under the AppKit-managed key `"NSWindow Frame N.chatWindowFrame"` without an explicit save call |
| cwc-009 | focus-input-on-show | Call `showWindow(nil)` | Composer field receives first responder focus |
| cwc-010 | focus-input-on-key | Programmatically make another view (e.g. the transcript's text view) the window's first responder, then post `NSWindow.didBecomeKeyNotification` for the window | The other view's first-responder status is preserved; `focusInput()` is not called because the window's first responder was not the window itself |
| cwc-011 | find-first-editable-field | Call `focusInput()` with hierarchy containing multiple text fields (only one editable) | First editable `NSTextField` is located and made first responder |
| cwc-012 | prohibit-nib-init | Code inspection (not executed — invoking it would crash the test process) | `init?(coder:)` is `required`, marked `@available(*, unavailable)`, and its body calls `fatalError`, so nib/storyboard instantiation is a compile-time error |
| cwc-013 | movable-by-background | Initialize and inspect window | Window's `isMovableByWindowBackground` is `true`; user can drag window by clicking anywhere on chat surface |
| cwc-014 | accept-optional-backdrop | Initialize once with `backdrop: nil` and once with a real `NSView` | When non-nil, `chatView.backdrop` is the same instance passed in; when `nil`, `chatView.backdrop` is `nil` |
| cwc-015 | use-full-size-content-view | Initialize and inspect window | `window.styleMask.contains(.fullSizeContentView)` is `true` |
| cwc-016 | disable-autoresizing-mask | Initialize and inspect window | `window.contentView?.autoresizingMask` is `[]` |
| cwc-017 | set-window-title | Initialize with `configuration.title = "Test Chat"` | `window.title` is `"Test Chat"` (the title bar itself remains hidden per **hide-title-bar**) |
| cwc-018 | use-content-view-controller | Initialize and inspect window | `window.contentViewController` is a `ChatContentViewController` wrapping `chatView`; `window.contentView` is not `chatView` directly |
| cwc-019 | install-appearance | Initialize and inspect window | `window.titlebarAccessoryViewControllers` contains the accessory installed by `appearance.install()` at the trailing edge |
| cwc-020 | allow-subclassing | Declare a subclass that overrides `showWindow(_:)` and adds a new stored property | Subclass compiles; its `showWindow(_:)` override runs; `chatView` and `appearance` remain accessible but cannot be overridden |
| cwc-021 | remove-observer-on-deinit | Initialize a controller, then deinit it | Its `NSWindow.didBecomeKeyNotification` observer is removed; posting that notification afterward has no effect (no crash, no callback) |

