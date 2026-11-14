---
id: 91114bf5-ad41-4cbd-b91b-c49bba9625d5
title: "ChatWindowController"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A macOS window controller that displays a chat interface with no title bar, transparent background, and appearance settings gear."
platforms:
  - swift
  - macos
tags:
  - chat
  - window
  - macos
  - appkit
depends-on:
  - 1794948f-2bb2-4f25-b9b5-72b1e6306ea1
related: []
references: []
approved-by: ""
approved-date: ""
---

# ChatWindowController

## Overview

ChatWindowController is an AppKit window controller that presents a chat interface in a floating window. The window has no title bar, uses a transparent background to respect the theme's alpha values, and provides appearance controls (text size, transparency, optional backdrop animation) via a gear icon at the trailing edge. It manages window frame persistence, input focus, and integrates with a host application's chat view model and backend. Subclass it to add host-specific behavior such as connection rituals or status items.

## Behavioral Requirements

- **own-chat-view**: The controller MUST own and display an `InlineChatView` instance, accessible via the `chatView` property.
- **own-appearance-controller**: The controller MUST own a `ChatWindowAppearanceController` instance, accessible via the `appearance` property; installing it (see **install-appearance**) places the gear in the window's trailing (right-side) titlebar accessory.
- **configure-from-struct**: The controller MUST be initialized with a `ChatWindowConfiguration` struct that supplies title, defaults namespace, appearance title, initial content size, chrome style, and backdrop toggle label.
- **accept-view-model**: The controller MUST accept an `ObservableChatViewModel` instance and a local participant ID string during initialization; the ID is passed to `InlineChatView` to distinguish the local participant's own messages from other participants' messages in the transcript.
- **accept-optional-backdrop**: The controller MUST accept an optional `NSView` backdrop that is passed to the `InlineChatView`.
- **hide-title-bar**: The window MUST have `titleVisibility` set to `.hidden` and `titlebarAppearsTransparent` set to `true`, and MUST explicitly hide the close, miniaturize, and zoom buttons via `standardWindowButton(_:)?.isHidden = true` for each — `titleVisibility`/`titlebarAppearsTransparent` alone remove the bar's material and text but not its buttons.
- **movable-by-background**: The window MUST set `isMovableByWindowBackground` to `true` so the chat surface itself serves as the drag handle.
- **translucent**: The window MUST set `isOpaque` to `false` and `backgroundColor` to `.clear`, allowing the theme's alpha values in the view to be visible.
- **use-full-size-content-view**: The window MUST include `.fullSizeContentView` in its style mask, extending content to the top edge.
- **size-window-correctly**: The window MUST open at the size specified in `ChatWindowConfiguration.contentSize`, not shrink-wrap to the view's minimum width. The controller MUST set `ChatContentViewController.preferredContentSize = contentSize` when constructing the content view controller wrapper.
- **disable-autoresizing-mask**: The window's content view MUST have an empty autoresizing mask (`[]`) to prevent the layout engine from treating it as a flexible mask and shrinking the window.
- **set-window-title**: The window MUST set its title from `ChatWindowConfiguration.title`. The title is hidden from the title bar but used by the Window menu, Mission Control, and the accessibility tree.
- **restore-frame**: The controller MUST call `setFrameUsingName(_:)` with the namespaced frame name (see **autosave-frame**) to restore the saved window frame. If it returns `false` (no frame saved yet), the window MUST center on screen.
- **autosave-frame**: The controller MUST set `windowFrameAutosaveName` to a namespaced frame name of the exact form `"<defaultsNamespace>.chatWindowFrame"`, and MUST do so after calling `super.init(window:)` — adopting a window clears any autosave name set beforehand. This enables AppKit's automatic frame persistence on every move and resize; **restore-frame** performs the one-time read of the saved frame at launch, so the two requirements act in this order: adopt the window, set the autosave name, then restore (or center).
- **use-content-view-controller**: The `InlineChatView` MUST be contained within a `ChatContentViewController` (not assigned directly to `contentView`) to ensure the window correctly sizes the chat view to the requested size rather than shrink-wrapping it.
- **install-appearance**: The controller MUST call `appearance.install()` during initialization to activate the appearance controller, which places the gear in the window's trailing titlebar accessory.
- **focus-input-on-show**: When `showWindow(_:)` is called, the controller MUST call `focusInput()` to place focus in the composer field.
- **focus-input-on-key**: The controller MUST observe `NSWindow.didBecomeKeyNotification` and call `focusInput()` only if the window's first responder is still the window itself. This ensures the composer is ready for typing without overriding an existing selection in the transcript.
- **find-first-editable-field**: The `focusInput()` method MUST walk the view hierarchy to locate the first editable `NSTextField` (the composer) and make it the first responder.
- **prohibit-nib-init**: The controller MUST prohibit initialization from a nib by implementing `required init?(coder:)` with `fatalError`.
- **remove-observer-on-deinit**: The controller MUST remove itself from `NotificationCenter` in `deinit` to avoid dangling observer references.
- **main-actor**: The class itself MUST be annotated `@MainActor`, making all public API and view-related logic isolated to the main actor.
- **allow-subclassing**: The class MUST be declared `open` to allow subclasses to add host-specific behavior. Only the class and `showWindow(_:)` are declared `open`; `chatView`, `appearance`, and `focusInput()` are `public` (not `open`), so subclasses may call them but not override them — new behavior is added via a subclass's own initializer (which calls `super.init`), new stored properties, or an override of `showWindow(_:)`.

## Appearance

- **Title bar**: Hidden (`.titleVisibility = .hidden`, `titlebarAppearsTransparent = true`)
- **Background**: Transparent (`.isOpaque = false`, `backgroundColor = .clear`)
- **Drag handle**: Window background (movable by window background; `.isMovableByWindowBackground = true`)
- **Default window size**: See `contentSize` under **Configuration** below (`ChatWindowConfiguration`'s default)
- **Gear/appearance control**: Trailing edge, managed by `ChatWindowAppearanceController`
- **Chat view**: Fills window content area, respects theme alpha and styling

## States

| State | Appearance change |
|-------|------------------|
| Default | Window centered on screen, chat ready for input |
| Restored | Window positioned and sized at last saved frame |
| Key (active) | First responder set to composer field for immediate typing |

## Accessibility

- **Window role**: Standard window with title accessible to the accessibility tree (title bar hidden but title retained for screen readers, Mission Control, and the Window menu).
- **Chat view and composer**: Accessibility provided by `InlineChatView` and the contained text field; the controller does not impose additional barriers.
- **Keyboard navigation**: First responder management ensures the composer field receives keyboard focus when the window becomes key, enabling immediate text input without requiring Tab navigation.
- **Minimum interaction target**: Not applicable. This component manages the window and focus; interactive elements (buttons, fields) are owned by `InlineChatView` and governed by their own specifications.

## Conformance Test Vectors

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

## Edge Cases

- **Null backdrop**: A nil backdrop is acceptable; the chat view renders without a background animation.
- **Empty view model**: The controller accepts the view model but delegates all chat display to `InlineChatView`; an empty or uninitialized view model is a concern for the view model, not the controller.
- **First responder already set**: If `focusInput()` is called when another view already has first responder status, the method attempts to set the composer as first responder; the window or other views may retain focus if they refuse to release it (e.g., during a drag operation).
- **Frame restoration failure**: If `setFrameUsingName(_:)` returns `false` (no saved frame), the window centers on screen; subsequent moves and resizes update the saved frame.
- **Window becoming key during text selection**: The `windowBecameKey` observer checks if the current first responder is the window itself before calling `focusInput()`. If a transcript selection or other view holds first responder, `focusInput()` is not called, preserving the selection.
- **Multiple ChatWindowController instances**: Each controller with a different `defaultsNamespace` maintains separate frame and appearance settings. Controllers with the same namespace share settings.
- **Window close/deinit**: The controller removes itself from `NotificationCenter` in `deinit` to avoid dangling observer references (see **remove-observer-on-deinit**).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `String` | Required | Window title, hidden in title bar but used by Window menu and accessibility |
| `defaultsNamespace` | `String` | Required | Prefix for saved appearance settings; namespaces allow multiple windows to maintain independent settings |
| `appearanceTitle` | `String` | Required | Caption for the appearance control panel, localized to the reader's language |
| `contentSize` | `NSSize` | `(460, 620)` | Initial width and height of the window's content area |
| `chrome` | `InlineChatChrome` | Default instance | Chat view styling (stock look or terminal theme) |
| `backdropToggleTitle` | `String` | `"Background animation"` | Label for the backdrop animation toggle in the appearance panel; e.g., `"Rain"` for a window with rain backdrop |

## Deep Linking

Not applicable: ChatWindowController is a window container, not a user-navigable destination. Deep linking into a chat is a concern for the host application and the view model it supplies.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `appearanceTitle` | *(required, no default)* | Caption at the top of the gear's panel, supplied by the host via `ChatWindowConfiguration`; the host is responsible for localizing it. |
| `backdropToggleTitle` | "Background animation" | Label for the backdrop toggle in the appearance panel. `ChatWindowConfiguration.init` bakes this English literal in as the default when a host does not override it — a host that relies on the default rather than supplying its own value MUST still localize it upstream (e.g. give it a strings-catalog key); it is not an invariant, non-user-facing string. |

## Accessibility Options

Not applicable: The controller does not directly render text or interactive elements. Text size, transparency adjustments, and other accessibility features are managed by `ChatWindowAppearanceController` and `InlineChatView`.

## Feature Flags

| Flag Key | Default | Description |
|----------|---------|-------------|
| Not applicable | — | The controller has no runtime feature flags; it is always active when instantiated |

## Analytics

| Event | Properties | When |
|-------|-----------|------|
| Not applicable | — | `ChatWindowController` emits no analytics events itself. |

## Privacy

- **Data collected**: ChatWindowController collects no personal user data. It persists two kinds of local preference state — window frame geometry and appearance settings (text size, transparency, backdrop visibility, floating, caret blink) — both scoped to the `defaultsNamespace` supplied in `ChatWindowConfiguration`.
- **Storage**: Frame geometry is stored by AppKit itself under the key `"NSWindow Frame <namespace>.chatWindowFrame"` in `UserDefaults.standard`, via `windowFrameAutosaveName` (see **autosave-frame**). Appearance settings are stored by `WindowAppearanceDefaults` in `UserDefaults.standard` under `<namespace>.textScale`, `<namespace>.transparencyPercent`, `<namespace>.backdrop.off`, `<namespace>.floating`, and `<namespace>.blinkCaret.off`. All of this is local to the device.
- **Transmission**: No data transmission occurs.
- **Retention**: Frame and appearance settings are retained indefinitely until the host application, the user, or `WindowAppearanceDefaults.resetWindowAppearance()` clears them.

## Logging

Subsystem: Determined by host application | Category: ChatWindowController

| Event | Level | Message |
|-------|-------|---------|
| Not applicable | — | The controller itself does not emit log messages; diagnostic logging is the host's responsibility |

## Platform Notes

- **Apple (source)**: `ChatWindowController` in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/ChatWindowController.swift`. An AppKit `NSWindowController` subclass that manages a window with no title bar, transparent background, and frame persistence. Uses `ChatWindowConfiguration` as a value type to support multiple windows with independent settings. Delegates chat display to `InlineChatView` and appearance controls to `ChatWindowAppearanceController`. The `ChatContentViewController` wrapper ensures the content view scales to the requested size rather than shrink-wrapping it.
- **SwiftUI**: SwiftUI does not provide a direct equivalent to AppKit's `NSWindowController`. `NSViewControllerRepresentable` wraps view controllers, not window controllers, so it cannot host `ChatWindowController` directly; `@Environment(\.openWindow)` opens a SwiftUI `Window` scene, not an arbitrary `NSWindowController`. The closer equivalent is a `Window` scene styled with `.windowStyle(.hiddenTitleBar)` and `.containerBackground(.clear, for: .window)` to approximate the hidden title bar and translucency, built from SwiftUI views; or, when the AppKit implementation itself must be reused, keep `ChatWindowController` as a plain AppKit controller instantiated and shown from the SwiftUI app's `@main` entry point rather than trying to wrap it as a scene.
- **Compose**: Android does not have a single-window model; Chat UI is typically displayed full-screen or in a modal dialog. Equivalent behavior would be a modal `Dialog` or `ModalBottomSheet` with a `TopAppBar` containing appearance controls and a text input field for the composer.
- **AppKit / UIKit**: The actual implementation is AppKit: an `NSWindowController` subclass managing an `NSWindow` with `titleVisibility = .hidden`, `titlebarAppearsTransparent = true`, explicit `standardWindowButton(_:)?.isHidden = true` for each title-bar button, `isOpaque = false`/`backgroundColor = .clear` for translucency, `isMovableByWindowBackground = true`, and `windowFrameAutosaveName` for frame persistence (see **hide-title-bar**, **translucent**, **movable-by-background**, **autosave-frame**). None of this applies directly on iOS — UIKit has no window chrome to hide and no window-frame autosave API. Present a chat interface in a modal `UIViewController` or a dedicated screen in a navigation stack instead, using `navigationBarTitleDisplayMode(.inline)` or a custom header view for a minimal title presentation, and `UIApplication.supportsMultipleScenes`/`SceneDelegate` state restoration in place of frame autosave.
- **WinUI 3**: On Windows, create a chat window using `Microsoft.UI.Xaml.Window` with `ExtendsContentIntoTitleBar = true` to remove the standard chrome, and call `SetTitleBar` (or `InputNonClientPointerSource.SetRegionRects` with `NonClientRegionKind.Caption`) over the chat surface so the window remains draggable without a visible title bar — a `Canvas` with a pointer-entered handler alone does not make a window movable. Use a `SystemBackdrop` (e.g. `MicaBackdrop` or `DesktopAcrylicBackdrop`) for translucency; `RequestedTheme` only switches light/dark colors and does not make the window transparent. Persist window position, size, and appearance settings to a local file (e.g. JSON under `ApplicationData.Current.LocalFolder`) rather than `ApplicationData.Current.LocalSettings`, which throws in unpackaged (non-MSIX) apps.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/ChatWindowController.swift` | unverified |

## Design Decisions

**Decision**: Hide the title bar (`titleVisibility = .hidden`, `titlebarAppearsTransparent = true`, all three standard buttons hidden) while keeping the window's `title` set.
**Rationale**: The title is retained because it is what the Window menu, Mission Control, and the accessibility tree read; hiding only the bar's furniture balances visual minimalism with platform discoverability.
**Approved**: pending

**Decision**: The window is translucent (`isOpaque = false`, `backgroundColor = .clear`).
**Rationale**: So the theme's own alpha values in the view layer are visible; an opaque window would composite its background first, obscuring theme transparency.
**Approved**: pending

**Decision**: `InlineChatView` is wrapped in a `ChatContentViewController` rather than assigned directly to `contentView`.
**Rationale**: AppKit sizes a direct content view to its minimum unless explicitly constrained; the wrapper's `preferredContentSize` determines the window's initial size instead.
**Approved**: pending

**Decision**: The content view's autoresizing mask is set to `[]` (no flexibility flags — a fixed mask), not left at `NSWindow`'s default flexible mask.
**Rationale**: A flexible mask against `NSThemeFrame` (which auto layout does not manage) leaves the content view's width an unconstrained free variable, so the layout engine settles it at the view's minimum and shrink-wraps the window. A fixed (`[]`) mask makes AppKit derive `width == frame.width` and re-derive it every time the window sets the content frame, so the window still resizes — it just stops shrink-wrapping on the way up.
**Approved**: pending

**Decision**: The `windowBecameKey` observer calls `focusInput()` only when the window's first responder is still the window itself.
**Rationale**: Taking focus unconditionally would clobber an active text selection in the transcript when the window is re-fronted (a status-bar item, ⌘\`, or clicking back from another app).
**Approved**: pending

**Decision**: The frame autosave name is `"<defaultsNamespace>.chatWindowFrame"`, prefixed with the `defaultsNamespace` from `ChatWindowConfiguration`.
**Rationale**: Allows multiple chat windows to maintain independent positions and sizes; each window remembers where it was left without colliding with another window's saved frame.
**Approved**: pending

**Decision**: Both `chatView` and `appearance` are `public` (not `open`) properties.
**Rationale**: Host applications can drive the view directly (e.g., display a placeholder during connection) and access appearance state, without being able to override them from a subclass — see **allow-subclassing**.
**Approved**: pending

**Decision**: The class is declared `open`, and only `showWindow(_:)` is declared `open override`-able.
**Rationale**: This lets hosts subclass to add connection rituals, status-item management, or other application-specific behavior — via a subclass's own initializer that calls `super.init`, new stored properties, or an override of `showWindow(_:)` — without forking the controller or requiring every member to be overridable.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`keyboard-navigable` and `focus-management` rest on the `windowBecameKey`/`focusInput()` first-responder handling that puts the composer in the key chain without requiring a pointer; `state-recovery` rests on `setFrameUsingName(_:)` restoring the saved frame and centering as a fallback; `string-externalization` is `partial` because `ChatWindowConfiguration.backdropToggleTitle` defaults to the hardcoded English literal `"Background animation"` (see Localization) even though every other user-facing string is host-supplied. separation-of-concerns passes because `ChatWindowController` delegates appearance state to `ChatWindowAppearanceController` and layout to `ChatContentViewController`/`ChatContainerView`, keeping only window-lifecycle plumbing (frame autosave, first-responder focus) in the controller itself, and unit-test-coverage passes because `ChatWindowTests.swift` exercises frame namespacing, theme-scope propagation, and the backdrop switch's conditional presence with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; added remove-observer-on-deinit requirement and 8 missing test vectors; fixed non-deterministic and self-referential test vectors; corrected the SwiftUI, AppKit/UIKit, and WinUI 3 platform notes; rewrote the Compliance table with real accessibility, reliability, and internationalization checks; corrected the Privacy section's storage keys and API name; added a Localization entry for the hardcoded backdrop-toggle default; removed unsupported Analytics attribution and the false "initializer not marked final" claim; clarified subclassing surface, frame-autosave order and naming, and the autoresizing-mask mechanism; removed the unobservable "Not key" state row and duplicate default window size |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
