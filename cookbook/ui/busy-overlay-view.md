---
id: 9f93e781-d196-438c-82f7-25c89f90a0b2
title: "Busy Overlay View"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A blurred layer with a spinner and optional message laid over a whole host view that swallows all pointer input until its owner hides it."
platforms:
  - swift
  - macos
tags:
  - ui
  - overlay
  - busy
  - progress
depends-on: []
related:
  - 0bc93127-4078-4bc6-a250-04dde181788b
references:
  - https://developer.apple.com/design/human-interface-guidelines/progress-indicators
approved-by: ""
approved-date: ""
---

# Busy Overlay View

## Overview

The busy overlay is a layer laid over a whole host view while something the
host shows is being changed. It draws a blurred ground, a spinner, and an
optional single line saying what is happening, and it lets no pointer input
through to the controls beneath.

It is the counterpart of the Dismissible Overlay View with the opposite
manners. That overlay goes away on any press or on Escape. This one goes
away only when its owner calls `hide()`, because what it covers is about to
be redrawn and a click landing on the old layout would act on a row that is
moving. It blends in and out over the Dismissible Overlay View's
`fadeDuration` (0.2 seconds) so the two read as the same kind of surface.

## Behavioral Requirements

- **cover-host**: `show(in:message:)` MUST add the overlay as the topmost subview of the host, above every existing sibling, with its top, leading, trailing and bottom edges pinned to the host's edges.
- **fade-in**: When first laid over a host, the overlay MUST start at opacity 0 and animate to opacity 1 over `fadeDuration` (0.2 seconds).
- **spinner-runs**: `show` MUST start the spinner animating.
- **message-line**: When `message` is a non-empty string, the overlay MUST show it on a single line below the spinner.
- **message-hidden-when-empty**: When `message` is `nil` or the empty string, the overlay MUST hide the message line and MUST clear any earlier text.
- **message-update-in-place**: Calling `show` again with the overlay already over the same host MUST update the message without re-adding the overlay to the host.
- **move-between-hosts**: Calling `show` with a different host MUST remove the overlay from its previous host before adding it to the new one.
- **hide-fades-out**: `hide()` MUST animate opacity to 0 over `fadeDuration` (0.2 seconds).
- **hide-removes**: When the fade-out completes, the overlay MUST stop the spinner and remove itself from its host.
- **hide-idempotent**: `hide()` MUST do nothing when the overlay has no host or is already fading out.
- **show-cancels-hide**: A `show` call during a fade-out MUST cancel the removal and animate the overlay back to opacity 1, leaving it over the host.
- **is-showing**: `isShowing` MUST be true exactly while the overlay has a host and is not fading out.
- **swallow-pointer**: While not hidden and with opacity above 0, the overlay MUST answer the hit test for every point inside its frame, so that no pointer event reaches a view beneath it.
- **ignore-hidden-hits**: When hidden or at opacity 0, the overlay MUST NOT answer any hit test.
- **swallow-click-events**: The overlay MUST consume left, right and other mouse-down events and scroll-wheel events without acting on them.
- **first-click-accepted**: The overlay MUST accept the first mouse event even when its window is inactive, so that event is swallowed too.
- **no-dismiss-on-input**: The overlay MUST NOT remove itself in response to any pointer event.
- **accessibility-role**: The overlay MUST expose the progress-indicator accessibility role.
- **accessibility-label**: `show` MUST set the overlay's accessibility label to the `message` it was given (cleared when `nil`).
- **material-configurable**: The blurred ground MUST use the material passed to the initializer, defaulting to the HUD window material.
- **ground-blends-within-window**: The blurred ground MUST blend with content within the window and MUST always be in the active state.
- **message-truncation**: A message too long for the available width MUST truncate at the tail.
- **content-inset**: The spinner and message stack MUST stay at least 16 points from the leading and trailing edges of the overlay.

## Appearance

- **Corner radius**: None; the overlay is a rectangle matching the host's bounds.
- **Padding**: At least 16 points to the leading and trailing edges for the spinner and message stack; 10 points of vertical spacing between spinner and message.
- **Font**: System font at the system font size for the message.
- **Background**: Blurred ground with the configured material (default HUD window), blending within the window, always active.
- **Foreground/Text**: Message in the secondary label color, centered; spinner in the spinning style at the large control size.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: No fixed size; fills the host, with the spinner and message stack centered horizontally and vertically.

## States

| State | Appearance change |
|-------|------------------|
| Default (not showing) | Not in any view hierarchy; `isShowing == false`; spinner stopped and not displayed when stopped |
| Showing | Over the host at opacity 1; spinner animating; message line visible only when a non-empty message was given |
| Fading in | Opacity animates from 0 to 1 over 0.2 seconds; already swallowing input as soon as opacity is above 0 |
| Fading out | `isShowing == false`; opacity animates to 0 over 0.2 seconds; remains in the host until the fade completes; hit tests answer nothing from the moment `hide()` is called, because the opacity value is set to 0 at once |
| Pressed | Not applicable: the overlay is not interactive; every press is swallowed and nothing changes |
| Disabled | Not applicable: the overlay has no enabled or disabled state in source |
| Focused | Not applicable: the overlay is not a focusable control in source |
| Loading | The Showing state is the loading state: the spinner animates and the optional message reads what is happening |

## Accessibility

- Role/trait: The overlay sets the progress-indicator accessibility role.
- Label requirements: The accessibility label is the message passed to `show`, and is cleared (set to nil) when no message was given.
- **announce-state-changes**: NEEDS REVIEW: Not implemented in source. The overlay posts no accessibility notification when it appears or disappears and does not move focus; evidence that would settle it is a screen-reader pass checking that a user is told the host is busy and when it is ready again.
- Minimum tap target: Not applicable: the overlay has no tappable control of its own; it intentionally swallows every pointer event.

## Conformance Test Vectors

No test file exists beside the source; the vectors below are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| busy-overlay-001 | cover-host, fade-in | A host view with two subviews; `show(in: host)` | The overlay is the last subview of the host; its four edges equal the host's; it starts at opacity 0 and reaches 1 after 0.2 seconds |
| busy-overlay-002 | message-line, accessibility-label | `show(in: host, message: "Saving")` | The message line is visible with the text "Saving"; the accessibility label is "Saving" |
| busy-overlay-003 | message-hidden-when-empty | `show(in: host, message: "Saving")`, then `show(in: host, message: nil)` | The message line is hidden and its text is empty; the accessibility label is cleared |
| busy-overlay-004 | message-hidden-when-empty | `show(in: host, message: "")` | The message line is hidden |
| busy-overlay-005 | message-update-in-place | Overlay already over `host`; `show(in: host, message: "Next")` | The host's subview count is unchanged; the message reads "Next" |
| busy-overlay-006 | move-between-hosts | Overlay over `hostA`; `show(in: hostB)` | The overlay is no longer a subview of `hostA`; it is the topmost subview of `hostB` |
| busy-overlay-007 | hide-fades-out, hide-removes, is-showing | Showing overlay; `hide()` | `isShowing` is false at once; after 0.2 seconds the overlay is removed from the host and the spinner is stopped |
| busy-overlay-008 | hide-idempotent | `hide()` on an overlay never shown; then `hide()` twice in a row on a showing overlay | No error; the second call during the fade changes nothing; the overlay is removed once |
| busy-overlay-009 | show-cancels-hide | Showing overlay; `hide()`; `show(in: host)` before 0.2 seconds elapse | The overlay is still over the host after the fade completes; `isShowing` is true; opacity returns to 1 |
| busy-overlay-010 | swallow-pointer | Showing overlay at opacity 1 over a button; hit test at a point inside the overlay's frame | The hit test answers the overlay, not the button |
| busy-overlay-011 | ignore-hidden-hits | Overlay with `isHidden == true`, or at opacity 0; hit test at a point inside its frame | The hit test answers nothing |
| busy-overlay-012 | swallow-click-events, no-dismiss-on-input | Send left, right and other mouse-down events and a scroll-wheel event to the showing overlay | No action is taken and the overlay stays over the host with `isShowing == true` |
| busy-overlay-013 | first-click-accepted | Ask whether the overlay accepts the first mouse event | The answer is true |
| busy-overlay-014 | accessibility-role | Read the accessibility role of a new overlay | The role is progress indicator |
| busy-overlay-015 | material-configurable | Initialize with a given material, then with no argument | The blurred ground carries the given material, then the HUD window material |

## Edge Cases

- **Empty or nil message** (MUST): The message line is hidden and the text cleared; the spinner alone shows.
- **Long message** (MUST): The message truncates at the tail within the width left after the 16-point insets.
- **show called twice with the same host** (MUST): Only the message and the accessibility label change; the overlay is not re-added and its opacity is not reset to 0, though the fade-in animation to 1 is requested again.
- **hide called when not showing** (MUST): Does nothing; safe to call at any time.
- **hide called twice during the fade** (MUST): The second call returns at once; the first fade completes and removes the overlay.
- **show during fade-out** (MUST): The pending removal is cancelled by the hiding flag being cleared; the completion handler finds the flag false and leaves the overlay up.
- **show on a different host while showing** (MUST): The overlay leaves the old host and starts again at opacity 0 over the new host.
- **Pointer events during fade-out** (MUST): `hide()` sets the overlay's opacity to 0 through the animator, which updates the opacity value at once while the fade is drawn over 0.2 seconds, so hit tests answer nothing from the moment `hide()` is called and presses reach the controls beneath while the overlay is still visibly fading.
- **Keyboard input** (MUST NOT): The overlay overrides only the three mouse-down events and scroll wheel; it overrides no key event and no mouse-up or drag event, so it does not intercept keystrokes.
- **Concurrent access** (MUST): The type is confined to the main actor, so every call runs serialized on the main thread; there is no cross-thread access to define.
- **Network or offline state**: Not applicable: the overlay performs no network, disk or other external work; its owner decides when work is done.
- **Decoding from an archive** (MUST NOT): The coder initializer is unavailable and traps if called; the overlay is built only in code.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| material | NSVisualEffectView.Material | .hudWindow | What the blurred ground is made of; set at initialization |
| host | NSView | none | The view to cover; passed to `show(in:message:)` |
| message | String? | nil | Optional line shown under the spinner; nil or empty hides the line |

## Deep Linking

Not applicable: the overlay is a transient layer over another view and has no address or route in source.

## Localization

Not applicable: the overlay holds no string of its own. The message is supplied by the caller, so localizing it is the caller's job.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | See the marker below the table. |
| Increase Contrast | Not applicable: the overlay sets no color of its own beyond the system secondary label color and the system blur material, which the system adapts. |
| Differentiate Without Color | Not applicable: the overlay conveys busy state by a moving spinner and optional text, not by color. |

- **reduce-motion**: NEEDS REVIEW: Not implemented in source. The fade animation runs at 0.2 seconds regardless of the reduce-motion setting; evidence that would settle it is a decision on whether a 0.2-second opacity fade needs a reduced-motion path.

## Feature Flags

Not applicable: the source reads no flag; the overlay is shown whenever its owner calls `show`.

## Analytics

Not applicable: the source emits no event.

## Privacy

- **Data collected**: None.
- **Storage**: None; the message is held only in a label.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the source writes no log entry.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/CoreUI/BusyOverlayView.swift`, an AppKit view. In SwiftUI, overlay a `ProgressView` and optional `Text` on a `.background(.regularMaterial)` with `.overlay`, and `.allowsHitTesting(true)` plus `.contentShape(Rectangle())` so presses are absorbed; drive it from a `@State` flag with `.transition(.opacity)`.
- **Compose**: Use a `Box` with `Modifier.fillMaxSize()` over the content, a semi-transparent scrim (Compose has no built-in blur on every API level; `Modifier.blur` applies to the content beneath on API 31 and up), a `CircularProgressIndicator` and an optional `Text`; swallow input with `Modifier.pointerInput(Unit) {}` that consumes every event, and fade with `AnimatedVisibility`.
- **React/Web**: A `position: absolute; inset: 0` element above the host with `backdrop-filter: blur()`, a CSS-animated spinner, and `pointer-events: auto` so it absorbs clicks and wheel events; give it `role="progressbar"` (or `role="status"` for the message), `aria-busy="true"` on the host and `aria-label` set to the message; fade with an opacity transition of 200ms.
- **AppKit / UIKit**: In AppKit the source subclasses `NSView`, pins it with Auto Layout, uses `NSVisualEffectView` (within-window blending), `NSProgressIndicator` and `NSStackView`, and swallows input through `hitTest(_:)` plus empty mouse overrides. On UIKit, use a `UIVisualEffectView` with a `UIBlurEffect`, a `UIActivityIndicatorView` (large), and set `isUserInteractionEnabled = true` on the overlay so it absorbs touches; animate alpha with `UIView.animate`.
- **WinUI 3**: Place a full-size `Grid` as the last child of the host's root `Grid` so it sits above siblings in z-order, with `Background` set to an `AcrylicBrush` (in-app acrylic, `BackgroundSource="Backdrop"` is system-wide so use the in-app brush from `Microsoft.UI.Xaml.Media`) or a semi-transparent `SolidColorBrush`, a centered `StackPanel` holding a `ProgressRing` (`IsActive="True"`, `Width` and `Height` of 48) and a `TextBlock` with `TextTrimming="CharacterEllipsis"`, `TextAlignment="Center"`, `Foreground="{ThemeResource TextFillColorSecondaryBrush}"` and `Margin="16,0"`. Set `Background` non-null so the `Grid` is hit-testable and handle `PointerPressed`, `PointerWheelChanged` and `RightTapped` with `e.Handled = true`; set `IsHitTestVisible="True"` and, to stop keyboard focus reaching the content beneath, set `IsTabStop="False"` on the host content or set its `IsEnabled="False"` while shown. Fade with an `OpacityTransition` (`Opacity` implicit animation, 0.2s) or a `Storyboard` with a `DoubleAnimation` on `Opacity`; collapse the overlay (`Visibility="Collapsed"`) in the `Completed` handler. For accessibility use `AutomationProperties.AutomationId`, `AutomationProperties.Name` bound to the message, and a `ProgressRing` (its UIA control type is ProgressBar); raise `AutomationPeer.RaiseNotificationEvent` when it appears.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/CoreUI/BusyOverlayView.swift` | confirmed (1.0.1) |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The overlay is removed only by its owner calling `hide()`, never by a press or a key.
**Rationale**: What it covers is about to be redrawn; a click landing on the old layout would act on a row that is moving.
**Approved**: pending

**Decision**: The overlay fades with the Dismissible Overlay View's `fadeDuration` (0.2 seconds) rather than its own constant.
**Rationale**: The two read as the same kind of surface, and one duration keeps them in step.
**Approved**: pending

**Decision**: The overlay is added above every sibling of the host, titlebar accessories included.
**Rationale**: Nothing beneath may be reachable; a lower z-position would leave some control clickable.
**Approved**: pending

**Decision**: `show` during a fade-out takes the fade back instead of waiting for removal, tracked by an internal hiding flag that the fade-out completion checks.
**Rationale**: A caller that finishes one piece of work and starts another must not see the overlay flicker away and return, or be left with a removed overlay.
**Approved**: pending

**Decision**: Input is swallowed by answering every hit test inside the frame and giving mouse-down, right-mouse-down, other-mouse-down and scroll-wheel handlers empty bodies, and by accepting the first mouse event.
**Rationale**: A click on an inactive window would otherwise reach the control beneath; the empty handlers stop the event from travelling up the responder chain.
**Approved**: pending

**Decision**: Hit tests answer nothing once the overlay is hidden or at opacity 0.
**Rationale**: The guard on hidden and zero opacity keeps a transparent overlay from taking a press. Because the fade is animated through the animator, which sets the opacity value at once, this also means a fading-out overlay stops swallowing input as soon as `hide()` is called.
**Approved**: pending

**Decision**: Key events are not intercepted, and no accessibility announcement or reduced-motion path exists.
**Rationale**: The source implements only pointer swallowing; the open questions on Announce state changes and Reduce Motion record what a reviewer should settle.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | accessibility |
| [adc.check.performance.progress-indication](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6ba6685b-9d35-5eb2-96e7-afbccd1e5848) | passed | performance |

The view does one job: cover a host, show progress and absorb input, leaving
the decision of when work ends to its owner, so separation of concerns
passes. No test file beside the source exercises the overlay, so unit test
coverage fails. Screen reader support is partial because the progress
indicator role and the message label are set, but nothing announces the
overlay appearing or disappearing. The fade runs regardless of the
reduce-motion setting, so that check fails. The spinner and optional message
give clear progress indication.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Review markers in one-line form |
