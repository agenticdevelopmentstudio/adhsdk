---
id: 9e06ce25-a124-473e-9cf6-ea11a7c40b2d
title: "KeyWindowBorderView"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A hairline accent-color border drawn inside the window frame, brightening when the window is key."
platforms:
  - swift
  - macos
tags:
  - ui
  - chrome
  - macos
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# KeyWindowBorderView

## Overview

`KeyWindowBorderView` is a macOS window decoration that draws a faint accent-colored hairline on the inside edge of a frameless or translucent window. The line brightens when the window becomes key, providing a visual affordance for which window has focus. The view is click-through and does not respond to mouse events.

## Behavioral Requirements

- **stroke-border**: Component MUST draw a 1-point stroked rounded rectangle aligned to the window's edge.
- **half-point-inset**: Component MUST inset the path by 0.5 points horizontally and vertically so the 1-point stroke lies fully inside `bounds`, which on a 1x display also aligns the stroke to the pixel grid.
- **accent-stroke-color**: Component MUST use the theme's accent color as the stroke color.
- **inactive-alpha**: Component MUST apply `inactiveAlpha` opacity to the stroke when the window is not key.
- **active-alpha**: Component MUST apply `activeAlpha` opacity to the stroke when the window is key.
- **click-through**: Component MUST return `nil` from `hitTest(_:)` and not intercept mouse events.
- **key-state-redraw**: Component MUST observe window key state notifications and redraw when key state changes.
- **initial-key-state**: Component MUST read the window's current key state when it first moves to a window and draw accordingly, without waiting for a subsequent key-state notification.
- **corner-radius-customization**: Component MUST allow the corner radius to be customized via the public `cornerRadius` property.
- **alpha-customization**: Component MUST allow the inactive and active alpha values to be customized via the public `inactiveAlpha` and `activeAlpha` properties.
- **redraw-on-property-change**: Component MUST mark itself for redisplay when `cornerRadius`, `inactiveAlpha`, or `activeAlpha` properties are modified.
- **theme-color-update**: Component MUST observe theme palette changes and update the accent color when the theme changes.
- **observer-cleanup**: Component MUST remove all observers from the notification center when deallocated or moved to a window.
- **main-actor-isolation**: Component MUST be annotated as `@MainActor` to ensure all drawing and observation occur on the main thread.

## Appearance

- **Stroke width**: 1 point
- **Stroke inset**: 0.5 points (half the stroke width) on all sides
- **Corner radius**: Default 10 points (customizable via `cornerRadius` property)
- **Color**: Theme accent color
- **Inactive opacity**: Default 0.28 (customizable via `inactiveAlpha` property)
- **Active opacity**: Default 0.85 (customizable via `activeAlpha` property)
- **Background**: Transparent (no fill)

## States

| State | Appearance change | Opacity | When triggered |
|-------|------------------|---------|-----------------|
| Detached | No stroke drawn | — | View has no window (`window` is `nil`); no key-state observers are registered |
| Inactive | Border faded | `inactiveAlpha` (0.28) | Window is not key; see `NSWindow.didResignKeyNotification` |
| Active | Border brightened | `activeAlpha` (0.85) | Window is key; see `NSWindow.didBecomeKeyNotification` |

## Accessibility

Not applicable: This component is a purely decorative visual affordance with no interactive function. It serves as a window chrome hint and does not expose accessible content, controls, or state beyond its visual appearance.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| key-001 | stroke-border | Component initialized and added to a window | `draw(_:)` strokes a rounded-rect path with `lineWidth == 1` within the view's bounds |
| key-002 | half-point-inset | Component draws | The stroked path's rect equals `bounds.insetBy(dx: 0.5, dy: 0.5)` |
| key-003 | accent-stroke-color | Theme accent is red (example) | `strokeColor`'s underlying color, ignoring alpha, equals the theme's red accent |
| key-004 | inactive-alpha | Window is not key; `inactiveAlpha` = 0.28 | `strokeColor.alphaComponent == 0.28` |
| key-005 | active-alpha | Window becomes key; `activeAlpha` = 0.85 | `strokeColor.alphaComponent == 0.85` |
| key-006 | click-through | Mouse event at (x, y) within component bounds | `hitTest(_:)` returns `nil`; event passes through to the view underneath |
| key-007 | key-state-redraw | Window key state changes from inactive to active | `keyStateChanged()` sets `needsDisplay = true`; the next `draw(_:)` computes `strokeColor.alphaComponent == activeAlpha` |
| key-008 | corner-radius-customization | Set `cornerRadius` to 15 | The stroked path is built with `xRadius == 15` and `yRadius == 15` |
| key-009 | alpha-customization | Set `inactiveAlpha` to 0.5; window is not key | `strokeColor.alphaComponent == 0.5` |
| key-010 | redraw-on-property-change | Modify `cornerRadius`, `inactiveAlpha`, or `activeAlpha` | `needsDisplay` becomes `true` immediately after the property's `didSet` runs |
| key-011 | theme-color-update | Theme palette changes; accent color changes to blue | `accent` updates to blue and `needsDisplay` becomes `true`; the next stroke uses the blue accent |
| key-012 | observer-cleanup | Component is deallocated | `deinit` calls `NotificationCenter.default.removeObserver(self)`; no further notifications reach the instance |
| key-013 | observer-cleanup | `viewDidMoveToWindow()` runs with `window == nil` (view removed from its window) | Observers registered for the previous window are removed; no drawing is scheduled; no observers remain for `self` |
| key-014 | observer-cleanup | Component is moved from window A to window B | Observers for window A are removed before observers for window B are registered; `needsDisplay` becomes `true` for the new window |
| key-015 | initial-key-state | `viewDidMoveToWindow()` runs for the first time on a window that is already key | `needsDisplay` becomes `true`, and the next `draw(_:)` uses `activeAlpha`, without waiting for a `didBecomeKeyNotification` |
| key-016 | main-actor-isolation | Project builds under Swift strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`) | The build succeeds with zero data-race or actor-isolation diagnostics for `KeyWindowBorderView` |

## Edge Cases

- **Window move between windows**: If the view is moved from one window to another, observers for the old window are removed and re-registered for the new window. The stroke is redrawn to reflect the new window's key state. See **observer-cleanup**.
- **Nil window**: If `viewDidMoveToWindow()` is called and `window` is `nil` (view removed), all observers are cleaned up and no drawing occurs. See **observer-cleanup**.
- **Zero or negative corner radius**: The behavior is not explicitly constrained by the source; the underlying `NSBezierPath` method determines the rendering. A host that sets invalid radii accepts that consequence.
- **Alpha values outside [0, 1]**: Setting `inactiveAlpha` or `activeAlpha` to values outside the valid range does not raise an error; the `NSColor.withAlphaComponent(_:)` method handles or clips the value, and drawing proceeds.
- **Theme change during deallocating**: The `ThemePaletteObserver` is held by the view; when the view deallocates, the observer is released and no further theme updates are received.
- **Rapid key state toggles**: Each key-state notification calls `keyStateChanged()`, which sets `needsDisplay = true`. AppKit coalesces multiple `needsDisplay` requests made within the same run-loop pass into a single redraw before the next display cycle, so rapid toggles do not produce one draw call per notification.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cornerRadius` | `CGFloat` | `10.0` | Corner radius of the stroked rectangle in points |
| `inactiveAlpha` | `CGFloat` | `0.28` | Opacity of the stroke when the window is not key (range [0, 1]) |
| `activeAlpha` | `CGFloat` | `0.85` | Opacity of the stroke when the window is key (range [0, 1]) |

## Deep Linking

Not applicable: This component is a window decoration with no user interaction or navigation. It does not handle deep links or URL-based state.

## Localization

Not applicable: This component displays no user-facing text or strings.

## Accessibility Options

Not applicable: This component is a decorative visual element with no semantic meaning or interactive state for assistive technologies to expose.

## Feature Flags

Not applicable: No feature flag mechanism is implemented in the source. The component is always enabled when instantiated.

## Analytics

Not applicable: The component does not perform user interaction tracking or emit analytics events.

## Privacy

Not applicable: The component does not collect, store, or transmit any user data.

## Logging

Not applicable: No logging is implemented in the source.

## Platform Notes

- **SwiftUI**: SwiftUI can express this natively without wrapping the AppKit view. Apply `.overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(Color.accentColor, lineWidth: 1))`, inset by 0.5 points to match the AppKit version's alignment, to the window's root content view. Read `@Environment(\.controlActiveState) private var controlActiveState` and set the overlay's opacity to `activeAlpha` when it is `.key` and `inactiveAlpha` otherwise. Add `.allowsHitTesting(false)` so the overlay never intercepts events, matching the source's `hitTest` override.

- **Compose**: Android does not have frameless or translucent windows with key-state semantics equivalent to macOS, so the component has no equivalent there. Compose Desktop windows do expose a focus state, though: `LocalWindowInfo.current.isWindowFocused` reports whether the window currently has focus. A `Modifier.border(width = 1.dp, color = MaterialTheme.colorScheme.primary.copy(alpha = if (isWindowFocused) activeAlpha else inactiveAlpha), shape = RoundedCornerShape(cornerRadius.dp))` overlay reproduces the same brightening affordance for a Compose Desktop translucent window.

- **React/Web**: Browsers expose window focus via the `focus` / `blur` events on `window`, and `document.hasFocus()` reads the current state synchronously. For an app shell running in a borderless/frameless window (for example, an Electron `BrowserWindow` with `frame: false`), a CSS overlay — `position: absolute; inset: 0; border-radius: var(--corner-radius); border: 1px solid var(--accent); opacity: var(--inactive-alpha); pointer-events: none;` — toggling to `var(--active-alpha)` via a class set from those listeners reproduces the affordance. A page rendered inside ordinary browser chrome has no use for this, since the OS-drawn window frame already shows focus.

- **AppKit / UIKit**: On macOS, `KeyWindowBorderView` is implemented as an `NSView` subclass, drawn with `NSBezierPath(roundedRect:xRadius:yRadius:)` and `stroke()` inside `draw(_:)`. It observes `NSWindow.didBecomeKeyNotification` and `NSWindow.didResignKeyNotification` on its window to react to key-state changes. On iOS, `UIWindow` does have a key-state concept — `UIWindow.isKeyWindow`, plus `UIWindow.didBecomeKeyNotification` / `didResignKeyNotification` — but a scene-based app's foreground/background transitions are better tracked via `UIScene.activationState` and the owning `UIWindowSceneDelegate`'s `sceneDidActivate(_:)` / `sceneWillDeactivate(_:)`. A UIKit port would draw the same inset, rounded, stroked path in `draw(_:)` (or a `CAShapeLayer`) and toggle its alpha from those callbacks.

- **WinUI 3**: On Windows, implement this as a `Microsoft.UI.Xaml.Controls.Border` with `CornerRadius` set to `cornerRadius` and a `BorderThickness` of 1, its `BorderBrush` bound to the app's accent-color resource (for example `{ThemeResource SystemAccentColor}`, or a custom theme provider). A XAML `Border` draws its stroke fully inside its own bounds, so the manual 0.5-point inset this view needs in AppKit is unnecessary there. Set `IsHitTestVisible="False"` to make it click-through. Toggle the brush's opacity between `inactiveAlpha` and `activeAlpha` from the `Window.Activated` event, switching on `e.WindowActivationState == WindowActivationState.Deactivated` (inactive) versus any other value (active) — WinUI 3's `Window` has no separate `Deactivated` event.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/KeyWindowBorderView.swift` | unverified |

## Design Decisions

- **Decision**: Inset the stroke path by 0.5 points on all sides.
  **Rationale**: A 1-point stroke is centered on its path, so half its width would fall outside `bounds` without the inset; insetting keeps the full stroke within the view. At 1x this also lands the stroke on a single pixel column rather than straddling two, avoiding blur — on Retina displays 0.5pt maps to a whole number of device pixels, so the pixel-alignment benefit is a 1x-specific side effect rather than the primary reason for the inset.
  **Approved**: pending

- **Decision**: Default `inactiveAlpha` to 0.28 and `activeAlpha` to 0.85.
  **Rationale**: The gap between the two is deliberate: the inactive line must read as the window's edge rather than a highlight, while the active line must be bright enough to clearly signal which window has focus. These defaults are calibrated for readability against both light and dark desktops.
  **Approved**: pending

- **Decision**: Implement click-through by overriding `hitTest(_:)` to always return `nil`, rather than hiding the view or intercepting events another way.
  **Rationale**: Returning `nil` from `hitTest(_:)` is the standard `NSView` mechanism for excluding a view from mouse-event dispatch — AppKit's hit-testing walks the view tree and skips any view whose `hitTest(_:)` returns `nil`, passing the event to the view underneath. This keeps the border purely decorative while every window beneath it remains fully interactive.
  **Approved**: pending

- **Decision**: Observe theme changes via `ThemePaletteObserver` rather than reading the accent color once at init.
  **Rationale**: Ties the border's color to the app's live theme so it updates immediately if the user or the app changes the accent color, instead of requiring the view to be recreated.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`platform-design-language` and `platform-theming` rest on the source drawing with the system accent color and mirroring macOS's own key/inactive window semantics via `NSWindow.didBecomeKeyNotification` / `didResignKeyNotification` and `ThemePaletteObserver`. `fault-tolerance` is partial because out-of-range `cornerRadius` and alpha inputs (see Edge Cases) do not crash the view, but the source also does not validate or normalize them to a defined result. `separation-of-concerns` passes because the `strokeColor` derivation is named apart from `draw(_:)` precisely so it can be asked about without rasterizing; `unit-test-coverage` passes on `KeyWindowBorderViewTests.swift`'s direct exercise of the accent color, the key/inactive alpha swap, the repaint-on-notification path, and click-through.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; added an `initial-key-state` requirement and vector for reading key state on first window attachment; moved the `NSBezierPath`/`stroke()` implementation detail from Appearance into the AppKit/UIKit platform note; corrected the UIKit note's false "always key" claim to `UIWindow.isKeyWindow`/`UIScene.activationState`, the WinUI 3 note's UWP namespaces and nonexistent `Deactivated` event to `Microsoft.UI.Xaml`/`WindowActivationState` with a native `Border`, and the SwiftUI note to prefer a native `.overlay(RoundedRectangle.strokeBorder)` over `NSViewRepresentable`; replaced the Compose and React/Web "Not applicable" notes with minimal focus-based equivalents; rewrote the click-through and half-point-inset Design Decisions to drop UIKit-only APIs and the inaccurate 2-point-blur claim, and reformatted all Design Decisions into the Decision/Rationale/Approved form; rebuilt Compliance as a linked checks table (platform-design-language, platform-theming, fault-tolerance) and dropped the invented Usability/Concurrency categories; added a Detached state and fixed the rapid-key-state-toggle edge case to describe `needsDisplay` coalescing; split the "sharp"/"visible" test vectors into concrete assertions, turned main-actor-isolation into a build-time check, and added observer-cleanup vectors for deallocation and window removal; fixed the 1.0.0 row's author to Mike Fullerton |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial recipe extraction from KeyWindowBorderView.swift |
