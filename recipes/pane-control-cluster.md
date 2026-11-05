---
id: f7fbabba-4b48-4b6b-a99c-b888cedec056
title: Pane Control Cluster
domain: adhsdk://recipes/pane-control-cluster
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A trio of control buttons (close, minimize, zoom) for a pane's title bar,
  mirroring window-level controls.
platforms:
- swift
- macos
tags:
- pane
- controls
- title-bar
depends-on: []
related:
- adhsdk://recipes/pane-title-bar-view
- adhsdk://recipes/pane-minimize-picker
references: []
approved-by: ''
approved-date: ''
---

# Pane Control Cluster

## Overview

A horizontal cluster of three buttons at the leading edge of a pane's title bar: close, minimize, and zoom. The component mirrors the arrangement and meanings of the window title bar controls, ensuring visual and behavioral consistency. The cluster reports state (zoomed, minimized, enabled/disabled) and does not make decisions about pane lifecycle — the hosting container retains full responsibility for closing, resizing, and state management.

## Behavioral Requirements

- **render-three-buttons**: The component MUST render exactly three buttons in left-to-right order: close, minimize, zoom.
- **standard-glyphs**: The component MUST display SF Symbol glyphs in the default state: "xmark" for close, "minus" for minimize, "arrow.up.left.and.arrow.down.right" for zoom. State-dependent glyph changes are covered by **render-minimized-state** and **render-zoomed-state**.
- **report-close-action**: The component MUST invoke the `onClose` closure when the close button is activated.
- **report-minimize-action**: The component MUST invoke the `onMinimize` closure when the minimize button is activated in the non-minimized state, passing a reference to the button itself as an anchor point (for example, so the host can present a picker popover from it without looking the button up again). On platforms without a native view-reference type, the host receives an equivalent positional anchor (e.g., a frame/rect in the cluster's coordinate space).
- **report-restore-action**: The component MUST invoke the `onRestore` closure when the minimize button is activated in the minimized state.
- **report-zoom-action**: The component MUST invoke the `onZoom` closure when the zoom button is activated.
- **render-minimized-state**: When `isMinimized` is true, the component MUST render the minimize button with a "plus" glyph, "Restore Pane" label, "pane.restore" accessibility ID, and enable it regardless of `canMinimize`.
- **render-zoomed-state**: When `isZoomed` is true, the component MUST render the zoom button with the "arrow.down.right.and.arrow.up.left" glyph and "Unzoom Pane" label; when false, MUST render "arrow.up.left.and.arrow.down.right" and "Zoom Pane" label.
- **disable-close-button**: When `canClose` is false, the component MUST disable the close button and tint it with the tertiary text color (in place of the secondary text color used when enabled).
- **disable-minimize-button**: When `canMinimize` is false and `isMinimized` is false, the component MUST disable the minimize button and tint it with the tertiary text color (in place of the secondary text color used when enabled).
- **respond-to-state-changes**: The component MUST respond to changes in `isZoomed`, `isMinimized`, `canMinimize`, and `canClose` properties and update the button appearances and enabled states accordingly.
- **borderless-icon-buttons**: The component MUST render each button borderless, with only its glyph visible (no title text, no bezel/border).
- **tinted-glyph-color**: The component MUST tint each glyph using a single content color, so the color can be swapped centrally for enabled/disabled state and for theme changes (see **theme-aware-tinting**).
- **theme-aware-tinting**: The component MUST observe `ThemeManager.didChangeNotification` and `ThemeScope.didChangeNotification`, and re-apply tinting to all buttons whenever either fires: secondary text color for enabled buttons, tertiary text color for disabled buttons. These notifications post on an explicit theme selection, an in-place edit of the active theme, or a text-scale change — never directly from the OS's Increase Contrast setting or a bare system light/dark appearance switch, neither of which the component observes on its own (see Edge Cases).

## Appearance

- **Layout**: Horizontal stack, 2pt spacing between buttons, centered vertically
- **Buttons**: Three equal-sized button controls with no border
- **Glyphs**: SF Symbols rendered at system size, tinted (not filled)
- **Spacing**: 2pt between each button
- **Padding**: None specified; buttons manage their own bounds
- **Background**: Transparent; inherits from container
- **Tint**: Secondary text color (enabled), tertiary text color (disabled), theme-responsive

## States

| State | Appearance Change |
|-------|------------------|
| Default (not zoomed, not minimized, all enabled) | Close: "xmark" enabled; Minimize: "minus" enabled; Zoom: "arrow.up.left.and.arrow.down.right" enabled |
| Zoomed | Zoom button: "arrow.down.right.and.arrow.up.left" glyph; label changes to "Unzoom Pane" |
| Minimized | Minimize button: "plus" glyph, label "Restore Pane", enabled regardless of `canMinimize`; minimize button appears in restore role |
| Close disabled | Close button: tertiary text color tint, no interaction |
| Minimize disabled | Minimize button: tertiary text color tint (only when not minimized) |
| Dark mode | Tinting adjusts to match a dark theme once `ThemeManager.didChangeNotification`/`ThemeScope.didChangeNotification` fires (theme selection, in-place theme edit, or text-scale change); secondary/tertiary text colors recalculated from that notification, not from the OS appearance switch directly |
| Light mode | Tinting adjusts to match a light theme once `ThemeManager.didChangeNotification`/`ThemeScope.didChangeNotification` fires (theme selection, in-place theme edit, or text-scale change); secondary/tertiary text colors recalculated from that notification, not from the OS appearance switch directly |

## Accessibility

- **Role/trait**: Container with three buttons, each with button role
- **Accessibility IDs**: Close: "pane.close"; Minimize: "pane.minimize" (or "pane.restore" when minimized); Zoom: "pane.zoom"
- **Accessibility labels**: Close: "Close Pane"; Minimize: "Minimize Pane" or "Restore Pane"; Zoom: "Zoom Pane" or "Unzoom Pane"
- **Tooltips**: Identical to accessibility labels; displayed on hover
- **Glyph accessibility**: Each button's SF Symbol includes an accessibility description matching its label (e.g., "Close Pane" for the xmark)
- **State announcements**: Minimize button's label and glyph change reflect the state; screen readers announce the change on next access
- **Minimum target size**: macOS (pointer-based, `.accessoryBarAction` bezel): no fixed minimum is enforced; the button matches the compact sizing convention of system window controls. iOS (touch, per the UIKit port in Platform Notes): 44×44pt per Apple HIG.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cluster-001 | render-three-buttons | Component initialized | Three buttons appear in order: close, minimize, zoom |
| cluster-002 | standard-glyphs | Component in default state | Close button shows "xmark"; Minimize shows "minus"; Zoom shows "arrow.up.left.and.arrow.down.right" |
| cluster-003 | report-close-action | Close button activated | `onClose` closure invoked once |
| cluster-004 | report-minimize-action | `isMinimized = false`, minimize button activated | `onMinimize` closure invoked once, passed the minimize button as an anchor reference |
| cluster-005 | report-restore-action | `isMinimized = true`, minimize button activated | `onRestore` closure invoked once |
| cluster-006 | report-zoom-action | Zoom button activated | `onZoom` closure invoked once |
| cluster-007 | render-minimized-state | `isMinimized = true` | Minimize button renders "plus" glyph, "Restore Pane" label, "pane.restore" ID, enabled state |
| cluster-008 | render-zoomed-state | `isZoomed = true` | Zoom button renders "arrow.down.right.and.arrow.up.left" glyph, "Unzoom Pane" label |
| cluster-009 | render-zoomed-state | `isZoomed = false` | Zoom button renders "arrow.up.left.and.arrow.down.right" glyph, "Zoom Pane" label |
| cluster-010 | disable-close-button | `canClose = false` | Close button disabled, tinted with the tertiary text color |
| cluster-011 | disable-minimize-button | `isMinimized = false`, `canMinimize = false` | Minimize button disabled, tinted with the tertiary text color |
| cluster-012 | disable-minimize-button | `isMinimized = true`, `canMinimize = false` | Minimize button enabled (restore state overrides `canMinimize` disable) |
| cluster-013 | respond-to-state-changes | `isZoomed` changes from false to true | Zoom button glyph and label update immediately |
| cluster-014 | respond-to-state-changes | `canClose` changes from true to false | Close button immediately disables and re-tints to the tertiary text color |
| cluster-015 | theme-aware-tinting | The app's active theme is switched to a dark `ColorTheme` via `ThemeManager.selectTheme(id:)` | All button tints re-resolve to dark theme secondary/tertiary text colors, driven by the resulting `ThemeManager.didChangeNotification` |
| cluster-016 | borderless-icon-buttons, tinted-glyph-color | Component rendered | No border visible; buttons appear borderless; glyphs tinted, not filled |
| cluster-017 | render-three-buttons | Component initialized | Close/minimize/zoom buttons expose accessibility IDs "pane.close"/"pane.minimize"/"pane.zoom" and labels "Close Pane"/"Minimize Pane"/"Zoom Pane" |
| cluster-018 | render-three-buttons | Component initialized | Each button's tooltip equals its accessibility label |
| cluster-019 | render-minimized-state | `isMinimized = true` | Minimize button's tooltip equals "Restore Pane" |
| cluster-020 | render-zoomed-state | `isZoomed = true` | Zoom button's tooltip equals "Unzoom Pane" |
| cluster-021 | disable-close-button | `canClose = false` | Close button's content tint resolves to the palette's tertiary-text color (a color swap, not an alpha/opacity change) |
| cluster-022 | disable-minimize-button | `isMinimized = false`, `canMinimize = false` | Minimize button's content tint resolves to the palette's tertiary-text color (a color swap, not an alpha/opacity change) |
| cluster-023 | report-close-action, report-minimize-action, report-restore-action, report-zoom-action | `onClose`, `onMinimize`, `onRestore`, `onZoom` all nil | Activating any button has no effect and does not crash |
| cluster-024 | respond-to-state-changes | `isMinimized` changes from false to true | Minimize button transitions from "minus" / "Minimize Pane" / "pane.minimize" / `canMinimize`-gated enabled state to "plus" / "Restore Pane" / "pane.restore" / always-enabled state |
| cluster-025 | render-three-buttons | macOS button rendered with the `.accessoryBarAction` bezel | Hit area matches the compact accessory-bar sizing convention; no 44×44pt minimum is enforced, consistent with system window-control sizing |
| cluster-026 | render-three-buttons | iOS UIKit port renders the equivalent buttons (see Platform Notes) | Each button's hit area is at least 44×44pt per Apple HIG |
| cluster-027 | theme-aware-tinting | System Increase Contrast enabled, with no theme-change notification posted | Button tint does not change: the component observes only `ThemeManager`/`ThemeScope` theme-change notifications, and nothing posts one for the OS Increase Contrast setting; the palette's colors are static sRGB values with no dynamic/high-contrast variant to switch to |
| cluster-028 | render-minimized-state | Differentiate Without Color enabled | Minimize button's state is distinguished by glyph shape (minus vs. plus) and accessibility label, not by color alone |

## Edge Cases

- **Minimize when canMinimize is false**: Component ignores clicks on the minimize button; the button appears disabled. When `isMinimized` becomes true programmatically (set by the host), the button becomes enabled and shows restore state.
- **Restore when isMinimized is true**: The minimize button is always enabled while `isMinimized = true`, even if `canMinimize = false`. This ensures the user can always restore a minimized pane.
- **Close when canClose is false**: Component ignores clicks on the close button; the button appears disabled. The button remains visually reachable (disabled, not hidden) to communicate state, not capability, per principle-of-least-astonishment.
- **Multiple state changes in sequence**: If `isZoomed`, `isMinimized`, `canClose`, and `canMinimize` are all modified before layout occurs, the component updates all three buttons in a single internal pass, rather than updating each one independently as its own property changes — see **respond-to-state-changes**.
- **Theme changes during interaction**: If a `ThemeManager`/`ThemeScope` theme-change notification fires while a button is highlighted or being interacted with, the component re-applies tinting immediately — see **theme-aware-tinting**.
- **No actions configured**: All four closures (`onClose`, `onMinimize`, `onRestore`, `onZoom`) are optional. If a closure is nil, activating the corresponding button has no effect.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `isZoomed` | `Bool` | `false` | Flips the zoom glyph and tooltip. Set by the host; the component never infers it from a click. |
| `isMinimized` | `Bool` | `false` | Turns the minimize button into restore — glyph, tooltip, action, and accessibility identifier. |
| `canMinimize` | `Bool` | `true` | False for a pane with no sibling to hand its space to. Ignored while minimized, so restoring stays reachable. |
| `canClose` | `Bool` | `true` | False for a pane its container will not give up. |
| `onClose` | `(() -> Void)?` | `nil` | Invoked when the close button is activated. |
| `onMinimize` | `((NSButton) -> Void)?` | `nil` | Invoked, with the minimize button as an anchor, when it is activated in the non-minimized state. |
| `onRestore` | `(() -> Void)?` | `nil` | Invoked when the minimize button is activated in the minimized state. |
| `onZoom` | `(() -> Void)?` | `nil` | Invoked when the zoom button is activated. |

## Deep Linking

Not applicable: This component is a UI control cluster with no deep linking semantics; navigation and routing belong to the hosting pane or window container.

## Localization

All user-visible text is produced by the accessibility labels and tooltips below (identical per state). The source hard-codes them as English string literals — there is no `NSLocalizedString` call, string catalog, or localization provider in `PaneControlCluster.swift`.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| pane.close.label | Close Pane | Accessibility label and tooltip for the close button |
| pane.minimize.label | Minimize Pane | Accessibility label and tooltip for the minimize button, non-minimized state |
| pane.restore.label | Restore Pane | Accessibility label and tooltip for the minimize button, minimized state |
| pane.zoom.label | Zoom Pane | Accessibility label and tooltip for the zoom button, non-zoomed state |
| pane.unzoom.label | Unzoom Pane | Accessibility label and tooltip for the zoom button, zoomed state |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: The component has no animations; it renders states instantly. Reduce Motion does not affect visual appearance. |
| Increase Contrast | Not supported: the component observes only `ThemeManager`/`ThemeScope` theme-change notifications, and nothing posts one for the OS Increase Contrast setting. The palette's secondary/tertiary text colors are fixed sRGB values with no dynamic/high-contrast variant, so the tint does not react to Increase Contrast — see **theme-aware-tinting**. |
| Differentiate Without Color | Supported: state is conveyed by glyph shape (xmark, minus/plus, the two diagonal-arrow variants) and by accessibility labels, never by color alone. |

## Feature Flags

Not applicable: This component has no feature flag gates; it is always enabled when instantiated.

## Analytics

Not applicable: The component does not emit analytics events; event tracking belongs to the hosting container.

## Privacy

Not applicable: The component does not collect, store, or transmit any user data or personal information.

## Logging

Not applicable: The component does not emit diagnostic logs. Hosting containers may log user interactions with pane controls.

## Platform Notes

- **SwiftUI**: Wrap `PaneControlCluster` (an `NSViewRepresentable`, macOS 14.0+) in a state-binding adapter: pass `@State` values for `isZoomed`, `isMinimized`, `canMinimize`, `canClose` in, and forward the four closures out. SwiftUI has no built-in `ButtonStyle` equivalent to AppKit's `.accessoryBarAction` bezel, so a pure-SwiftUI port needs a custom `ButtonStyle` that renders icon-only content (no title, no background, no border) and drives the glyph's foreground color from `isEnabled` the same way the AppKit source drives `contentTintColor`.
- **Compose**: Build an equivalent using three composable buttons in a `Row` with a small fixed spacing (2dp). Use Material Design 3 icon buttons (`IconButton`) with appropriate icons (close, minimize, unfold less/more). Apply theme-aware tinting via the `contentColor` parameter. Keep the composable stateless: accept `isZoomed`, `isMinimized`, `canMinimize`, and `canClose` as parameters from the caller — never hold them in local `remember { mutableStateOf(...) }` state — and emit `onClose`/`onMinimize`/`onRestore`/`onZoom` callbacks. The host, not the composable, owns and mutates the state, matching the AppKit source.
- **React/Web**: Render three buttons in a horizontal flex container with a 2px gap. Use specific SVG icon sets rather than ambiguous glyphs — for example Lucide's `x` (close), `minus`/`plus` (minimize/restore), and `maximize-2`/`minimize-2` (zoom/unzoom). Apply `aria-label` matching each state's accessibility label ("Close Pane", "Minimize Pane"/"Restore Pane", "Zoom Pane"/"Unzoom Pane"), and set `aria-pressed` (or swap the label, matching the platform pattern above) on the zoom button so its toggled state is exposed to assistive tech. Toggle `disabled` and `aria-disabled` based on the four state properties. Use CSS custom properties for theme-aware text-color tinting (secondary/tertiary).
- **AppKit / UIKit**: The source `PaneControlCluster.swift` is the canonical AppKit implementation: `NSButton` with `bezelStyle = .accessoryBarAction`, `isBordered = false`, `imagePosition = .imageOnly`, and `contentTintColor` driving glyph color (see **borderless-icon-buttons**, **tinted-glyph-color**). State changes funnel through a single internal update pass so the three buttons never see the four flags in an inconsistent order, and a theme observer re-resolves tint on `ThemeManager`/`ThemeScope` theme-change notifications — not directly on OS Increase Contrast or a bare system appearance switch (see **theme-aware-tinting**). On UIKit (iOS 17.0+), adapt using three `UIButton` instances configured with system images and equivalent styling (`.plain()` configuration, no background, template image with `tintColor`). Manage state via observed properties, KVO, or Combine publishers if the hosting container uses reactive patterns. On macOS with AppKit, use `PaneControlCluster` directly from AgenticDeveloperHubSDK.
- **WinUI 3**: Use three `Button` controls in a `StackPanel` with `Orientation="Horizontal"` and `Spacing="2"`. Apply `Microsoft.UI.Xaml.Controls.FontIcon` with the Segoe Fluent Icons glyphs: `` (ChromeClose) for close, `` (ChromeMinimize) for minimize, `` (ChromeMaximize) for zoom, and `` (ChromeRestore) for unzoom. Set the `IsEnabled` binding for each button based on the four state flags. Use `Foreground` to apply theme-aware tinting (secondary/tertiary text from app theme resources). Bind `Click` (or `Command`) to a handler that dispatches to the four callbacks, giving the minimize button its dual minimize/restore role based on current state.

## Design Decisions

**Decision**: The cluster mirrors the order and meanings of the window title bar's close/minimize/zoom controls, not their exact glyphs — macOS window controls are colored circles, while this cluster uses SF Symbol glyphs.
**Rationale**: Principle of least astonishment: a pane is a window-shaped thing inside a window, and a reader who has to learn a second control arrangement pays for nothing.
**Approved**: pending

**Decision**: A disabled button (`canClose = false`, or `canMinimize = false` while not minimized) is rendered dim (tertiary text color tint) rather than hidden.
**Rationale**: A live-looking, unresponsive button reads as a broken pane; a dim button reads as a protected one, which matches the host's responsibility model — the host decides whether a pane may be closed or minimized.
**Approved**: pending

**Decision**: The minimize button serves a dual role (minimize / restore), swapping its glyph, label, tooltip, and accessibility identifier based on `isMinimized`, rather than showing a second button.
**Rationale**: Keeps the control cluster compact while accessibility stays correct, since the identifier and label always match the button's current role.
**Approved**: pending

**Decision**: The component observes `ThemeManager`/`ThemeScope` theme-change notifications and re-applies each button's tint automatically, rather than requiring the host to push an explicit update whenever the app's own theme changes. It does not itself observe the OS Increase Contrast setting or a bare system light/dark appearance switch — `ThemeManager.refreshApplicationAppearance()`, the path a host uses for that case, deliberately posts no notification, so this component's tint only follows a theme change that goes through `ThemeManager.selectTheme(id:)`, an in-place theme edit, or a text-scale change.
**Rationale**: Keeps theme-responsiveness self-contained for the changes the component's own semantic palette actually models; the host only has to manage `isZoomed`, `isMinimized`, `canMinimize`, and `canClose` — appearance follow-through for those changes is the component's job. OS-level Increase Contrast and appearance-only changes are out of scope because the palette has no dynamic/high-contrast variant to switch to.
**Approved**: pending

**Decision**: The component never infers `isZoomed` from a click; only the host sets it, after deciding whether to grant the zoom request.
**Rationale**: The pane's zoom state must always reflect the host's actual internal state — a click is a request, not an outcome, and the host may refuse it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | passed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Screen-reader-support and the hard-coded-string findings come directly from the source (`setAccessibilityLabel`/`accessibilityID` calls on every button, versus inline English literals with no localization call); text-expansion-tolerance passes because the buttons are icon-only and carry no visible title text to overflow. Keyboard, contrast, touch-target, and RTL statuses are partial because they rely on default AppKit and palette behavior that `PaneControlCluster.swift` does not itself exercise or measure; the view only renders host-supplied state via `applyState()` and reports clicks through closures, per its own "reports and does not decide" doc comment (separation-of-concerns: passed), and `PaneControlClusterTests.swift` exercises button wiring, click routing, the minimize/restore swap, and disabled state (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed theme-aware-tinting requirement/vectors/states/decision/platform-notes: re-tint follows ThemeManager/ThemeScope notifications only, not OS Increase Contrast or a bare system appearance switch (refreshApplicationAppearance posts none); Increase Contrast marked Not supported. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: restate AppKit implementation details (accessory-bar bezel, image-only tint) as platform-neutral behavioral requirements; rename all requirements to subject-only kebab-case; disambiguate the default-state glyph requirement; fix disabled-state wording from opacity to a tertiary-color tint; give the minimize-button anchor parameter a stated purpose and platform-neutral fallback; reformat Design Decisions into Decision/Rationale/Approved blocks and correct the "exact" window-control-glyph and race-condition claims; replace "Not applicable" in Compliance, Localization, and Accessibility Options with grounded findings; add missing conformance test vectors (accessibility IDs/labels, tooltips, disabled-tint, nil-closure, isMinimized transition, touch-target, contrast, differentiate-without-color); split the touch-target minimum by platform; make the Compose platform note stateless; correct the WinUI 3 namespace and glyph codes and the SwiftUI hedge; name concrete icons and add aria-pressed guidance to the Web note; replace "tapped" with "activated" throughout; fix the frontmatter `modified` date format; add related recipes. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from PaneControlCluster.swift source |
