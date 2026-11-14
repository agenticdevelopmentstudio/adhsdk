---
id: 8e7fa376-f174-4a10-b2ef-2a5c10854d4e
title: "Connection Overlay"
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Modal card that obscures the current view when a live feed becomes unreachable, displaying connection status and retry countdown."
platforms:
  - typescript
  - web
tags:
  - connection-status
  - modal
  - network
depends-on: []
related: []
references:
  - https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
  - https://www.w3.org/WAI/WCAG21/Understanding/target-size-enhanced.html
  - https://www.w3.org/WAI/WCAG21/Understanding/focus-visible.html
  - https://developer.apple.com/design/human-interface-guidelines/buttons
approved-by: ""
approved-date: ""
---

# Connection Overlay

## Overview

Connection Overlay is a modal card displayed over the current board or dashboard when a live data feed becomes unreachable (dark). It presents a calm, non-alarming state to the user rather than tearing down panels or displaying an error. The component shows the current connection status (either a backend deployment or unreachability), a spinner, a countdown timer to the next automatic retry attempt, and a manual "Try again now" button. The component obscures the underlying content with a semi-opaque background and blur effect, making it clear the view is temporarily unavailable without destroying the user's context.

## Behavioral Requirements

"Outage duration" below means `elapsedMs`, an internal timer, not a prop: it starts at 0 the instant the overlay becomes shown (1200ms after `active` becomes `true`) and is reset to 0 the instant `active` becomes `false`. It measures time since the overlay itself appeared, not time since `active` first became `true`.

- **hidden-when-inactive**: Component MUST NOT be rendered (return null) when the `active` prop is `false`.
- **show-after-delay**: Component MUST NOT be shown in the DOM until the `active` prop has been `true` for at least 1200ms; if `active` becomes `false` before 1200ms elapses, the component MUST NOT appear.
- **hide-immediately-on-recovery**: Component MUST hide when `active` transitions from `true` to `false`, regardless of elapsed time or remaining countdown, and MUST NOT wait out the 1200ms show-delay debounce (see show-after-delay) to do so. Source performs the hide from a passive effect that runs after the render in which `active` changes, not synchronously within that render: the render that first sees `active=false` can still return the overlay, and a countdown tick already in flight — including an auto-retry call — can fire before the effect's `clearInterval` cleanup runs.
- **display-deploying-status-within-grace-period**: Component MUST display the heading "Backend deploying" when the outage duration is less than 90,000ms (90 seconds).
- **display-unreachable-status-after-grace-period**: Component MUST display the heading "Backend unreachable" when the outage duration is 90,000ms or greater.
- **display-deploying-subtext-when-deploying**: Component MUST display the subtitle "The backend is restarting — reconnecting automatically. This usually takes a moment." when the heading is "Backend deploying".
- **display-unreachable-subtext-when-unreachable**: Component MUST display the subtitle "Still can't reach the backend. Retrying automatically." when the heading is "Backend unreachable".
- **display-countdown**: Component MUST render "Retrying in {countdown}s", where `{countdown}` starts at 15 the instant the overlay is shown and decrements by 1 once per second down through 1. On the tick that would advance it to 0, the component MUST NOT render 0; it instead invokes `onRetry` (see auto-retry-on-countdown-zero) and immediately resets the displayed value to 15. The visible range is therefore 15…1, repeating indefinitely.
- **auto-retry-on-countdown-zero**: Component MUST invoke the `onRetry` callback exactly once at the moment the internal countdown would advance to 0, then immediately reset the countdown to 15 without ever rendering 0.
- **provide-manual-retry-button**: Component MUST display a button labeled "Try again now" that, when clicked, resets the countdown to 15 and immediately invokes the `onRetry` callback.
- **display-detail-text-after-grace-period**: Component MUST display the `detail` prop text (if provided and not null) only when the outage duration is 90,000ms or greater; the detail text MUST NOT be displayed during the deploying phase.
- **use-aria-live-region**: Component MUST set `role="status"` and `aria-live="polite"` on the root overlay element to announce connection state changes to assistive technologies.
- **hide-countdown-from-screen-readers**: Component MUST mark the countdown timer display with `aria-hidden="true"` to prevent the per-second countdown from being announced to screen readers.
- **prevent-interaction-with-underlying-content**: Component MUST render an overlay that covers its containing block (inset: 0) at z-index 50, with a background that obscures the underlying content, blocking pointer and visual access to the view beneath. The parent MUST establish a positioning context (`position: relative` or equivalent) for `inset: 0` to cover it — see Design Decision 8. This requirement is pointer/visual only; see Focus management for the fact that keyboard and screen-reader focus can still reach the controls it obscures.
- **display-spinner-icon**: Component MUST display an animated spinner icon (34px size) colored with the blue theme token.
- **visible-focus-indicator**: Component MUST NOT suppress the platform's default focus indicator on the "Try again now" button. Source sets no `outline: none` and no custom `:focus` style, so the browser's default focus ring remains visible (WCAG 2.4.7).
- **respects-reduced-motion**: Component SHOULD stop the spinner's rotation when the user has `prefers-reduced-motion` set. Source applies the `animate-spin` class unconditionally and never reads that media feature; this requirement documents the gap for an implementer to close.

## Appearance

- **Container positioning**: Absolute, full inset (top, right, bottom, left: 0), z-index 50
- **Container background**: color-mix(in srgb, bg 90%, transparent) with 3px blur (backdrop-filter: blur(3px) + -webkit-backdrop-filter: blur(3px))
- **Card container**: Flex column, center-aligned, centered horizontally and vertically in viewport
- **Card padding**: 28px vertical × 34px horizontal
- **Card border radius**: 12px
- **Card background**: Surface theme token (var(--color-apt-surface))
- **Card border**: 1px solid, border theme token (var(--color-apt-border))
- **Card shadow**: 0 8px 40px rgba(0,0,0,0.35)
- **Card gap between elements**: 13px
- **Card max-width**: 46ch
- **Font family**: ui-monospace with monospace fallback
- **Heading font**: 17px, weight 700, letter-spacing 0.02em, text color (var(--color-apt-text))
- **Subheading font**: 12.5px, color muted (var(--color-apt-text-muted)), line-height 1.5
- **Countdown font**: 11.5px, color dim (var(--color-apt-text-dim))
- **Button padding**: 7px vertical × 18px horizontal
- **Button border radius**: 8px
- **Button background**: Blue theme token (var(--color-apt-blue))
- **Button text color**: white
- **Button text font**: 12.5px, weight 600, family monospace
- **Button cursor**: pointer
- **Button appearance**: none (reset default browser styling)
- **Detail text font**: 10.5px, color dim (var(--color-apt-text-dim)), opacity 0.75, word-break break-word

## States

| State | Appearance change |
|-------|------------------|
| Hidden (active=false or delay not elapsed) | Component does not render (returns null) |
| Shown (active=true, delay elapsed, deploying) | Heading: "Backend deploying", subheading: deployment-specific text, spinner visible, countdown visible, no detail text |
| Shown (active=true, delay elapsed, unreachable) | Heading: "Backend unreachable", subheading: unreachable-specific text, spinner visible, countdown visible, detail text displayed (if provided) |
| Button focused | No custom focus style is defined in source (no `outline: none`, no `:focus` rule), so the browser's default focus ring applies — see visible-focus-indicator |

## Accessibility

- **Role**: The root element MUST have `role="status"` to announce it as a live region.
- **Live announcements**: The root element MUST have `aria-live="polite"` to announce connection state changes to screen readers.
- **Spinner icon**: MUST have `aria-hidden="true"` to hide it from screen readers (decorative only).
- **Countdown timer**: MUST have `aria-hidden="true"` to prevent per-second countdown announcements, as the heading and subheading already convey state.
- **Detail text announcement**: No explicit aria-label or description provided; the detail text is visible text and will be read by screen readers.
- **Button labeling**: The "Try again now" button MUST have visible text label; no additional aria-label is provided in source.
- **Keyboard interaction**: The retry control is a native `<button type="button">`, so it sits in the document tab order and is activated by Enter and Space through built-in button semantics; keyboard activation reaches the same click handler as a pointer. The source adds no `keydown` or `keyup` handlers, and the overlay exposes no dismiss action to any input device — it is removed only when the consumer sets `active` to `false` — so there is no Escape path to specify.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. The button sets no `min-height` or `min-width`; its hit area is the 7px × 18px padding around one line of 12.5px monospace text, resolving to roughly 29–31 CSS px tall — clearing the 24×24 CSS px floor of WCAG 2.2 AA (SC 2.5.8) but not the 44×44 figure of WCAG 2.1 AAA (SC 2.5.5) or the Apple Human Interface Guidelines. Settle it with a measured hit box on the shipping dashboards plus a decision on whether the overlay is reachable from touch or pen input; if it is, the button needs an explicit minimum height.
- **Focus management**: The layer is modal in intent (`prevent-interaction-with-underlying-content`, scoped to pointer/visual access only — see Behavioral Requirements), but the source installs no focus trap, moves no focus into the card when it appears, and restores no focus when it is removed; keyboard and screen-reader focus can still reach the controls the overlay covers, so a keyboard user can operate a panel they cannot see.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overlay-001 | hidden-when-inactive | active=false | Component returns null; nothing rendered |
| overlay-002 | show-after-delay | active=true, wait 1200ms | Component renders in DOM after 1200ms delay |
| overlay-003 | show-after-delay (too early) | active=true, wait 500ms | Component does not render before 1200ms elapsed |
| overlay-004 | hide-immediately-on-recovery | active=true (shown), then active=false | Component is removed from the DOM without waiting out the 1200ms show-delay debounce — but not synchronously within the render that saw `active=false`: the hide runs in the passive effect that commits after that render, so a countdown tick already in flight can still fire once before the overlay disappears |
| overlay-005 | display-deploying-status-within-grace-period | active=true, elapsedMs < 90000 | Heading text is "Backend deploying" |
| overlay-006 | display-unreachable-status-after-grace-period | active=true, elapsedMs >= 90000 | Heading text is "Backend unreachable" |
| overlay-007 | display-deploying-subtext-when-deploying | active=true, elapsedMs < 90000 | Subheading text is "The backend is restarting — reconnecting automatically. This usually takes a moment." |
| overlay-008 | display-unreachable-subtext-when-unreachable | active=true, elapsedMs >= 90000 | Subheading text is "Still can't reach the backend. Retrying automatically." |
| overlay-009 | display-countdown | active=true, shown=true | Countdown displays starting at 15 and decrements by 1 every second, down through 1; 0 is never rendered |
| overlay-010 | auto-retry-on-countdown-zero | active=true, shown=true, countdown reaches 1 and ticks again | onRetry callback invoked exactly once; countdown resets to 15 without ever displaying 0 |
| overlay-011 | provide-manual-retry-button | active=true, shown=true | Button with text "Try again now" is rendered and clickable |
| overlay-012 | provide-manual-retry-button (click) | Button clicked while countdown=10 | onRetry callback invoked; countdown resets to 15 immediately |
| overlay-013 | display-detail-text-after-grace-period | active=true, elapsedMs >= 90000, detail="Network timeout" | Detail text "Network timeout" is displayed |
| overlay-014 | display-detail-text-after-grace-period (no display during deploy) | active=true, elapsedMs < 90000, detail="Error" | Detail text is not displayed |
| overlay-015 | display-detail-text-after-grace-period (null detail) | active=true, elapsedMs >= 90000, detail=null | Detail text element is not rendered |
| overlay-016 | use-aria-live-region | active=true, shown=true | Root div has role="status" and aria-live="polite" |
| overlay-017 | hide-countdown-from-screen-readers | active=true, shown=true | Countdown div has aria-hidden="true" |
| overlay-018 | prevent-interaction-with-underlying-content | active=true, shown=true, parent establishes a positioning context | Overlay element's computed `position` is `absolute` with `inset: 0` and `z-index: 50`, covering the parent's content box; a pointer event dispatched at a point within that box is captured by the overlay, not by an element beneath it |
| overlay-019 | display-spinner-icon | active=true, shown=true | An animated spinner element, 34px, colored with the blue theme token, is rendered with `aria-hidden="true"` |
| overlay-020 | visible-focus-indicator | Button rendered, no source CSS override | Button's computed `outline` is not `none`; giving it keyboard focus shows the platform's default focus ring |
| overlay-021 | display-countdown, display-unreachable-status-after-grace-period (persistence) | active=true; countdown at 8 when elapsedMs crosses 90000ms | Heading switches from "Backend deploying" to "Backend unreachable" at that tick; countdown continues from 8 — it is not reset to 15 |
| overlay-022 | show-after-delay (rapid toggle) | active: true → false → true, the second `true` arriving 500ms after the first (before the 1200ms debounce completes) | Component does not render at the original 1200ms mark; the first timer is cancelled and no state changes result from it; the component renders 1200ms after the second `true` |
| overlay-023 | respects-reduced-motion | prefers-reduced-motion: reduce, active=true, shown=true | Target behavior: the spinner's rotation is stopped. Source currently keeps the `animate-spin` class unconditionally, so this vector fails today — see Compliance |

## Edge Cases

- **Manual retry with one second remaining**: Clicking the button when countdown=1 sets `remainingRef`/`countdown` to 15 and invokes `onRetry` immediately, but it does not restart the running `setInterval` — the interval's own 1-second phase, set by whenever it last ticked, is untouched. The next tick therefore lands wherever that phase already was, anywhere from just after the click up to a full second later, not reliably "1 second later" from the click.
- **Null or undefined detail prop**: If `detail` is `null` or `undefined`, the detail element is not rendered (conditional: `detail && !deploying`). No error is thrown.
- **Rapid active toggles**: If `active` toggles from true to false to true within the 1200ms delay window, the timer resets and the component waits a full 1200ms from the most recent `true` value before showing. (Confirmed by setTimeout cleanup in useEffect.)
- **onRetry callback changes between renders**: The component stores `onRetry` in a ref (`onRetryRef`) to prevent re-triggering the interval effect when the callback identity changes. The latest callback is always called, even if it was replaced since the last tick.
- **Strict Mode double-invoke**: React Strict Mode unmounts and remounts effects during development. The countdown interval is properly cleaned up and re-initialized, preventing double-retry invocations (confirmed by use of ref instead of setState in the interval callback).
- **Component unmounted while shown**: If the component is unmounted while `shown=true`, the interval is cleaned up (clearInterval in useEffect return).
- **Recovery while the countdown is ticking**: When `active` becomes `false` while the overlay is shown and ticking, the debounced-show effect sets `shown` to `false` — but from a passive effect, not synchronously within the render that first saw `active=false`. That render still returns the overlay (`shown` is still `true`), and the tick effect's `clearInterval` cleanup does not run until a later commit flushes with `shown=false`. If the 1-second interval fires at any point in that window, it still calls `onRetryRef.current()` — an auto-retry that fires after the feed has already recovered — before the interval is finally torn down.
- **Very long outage (elapsed > 90 seconds)**: The grace period is a fixed 90,000ms; outages longer than this display "Backend unreachable" indefinitely and allow detail text to be shown. No special behavior for hours-long outages.
- **Detail text longer than card width**: The detail div has `word-break: break-word`, causing long strings to wrap within the 46ch max-width container.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `active` | boolean | (required) | True when the live feed is dark (unreachable); false when connection is healthy. Controls visibility and state of the overlay. |
| `onRetry` | function | (required) | Callback invoked when the user clicks "Try again now" or when the 15-second countdown reaches 0. Receives no arguments. |
| `detail` | string \| null | undefined | Optional error detail text displayed only after the grace period (elapsedMs >= 90000) expires. If null or undefined, the detail section is not rendered. |

`elapsedMs` (outage duration) is not a configurable option — it is internal state derived from `active` and the show delay, not a prop. See the note at the top of Behavioral Requirements for exactly how it is measured and reset.

## Deep Linking

Not applicable: Connection Overlay is a modal overlay component without its own deep link path. It is shown conditionally within a parent view (Overview/Details board or dashboard) and does not represent a distinct navigable destination.

## Localization

Every visible string — "Backend deploying", "Backend unreachable", both subtitles, "Retrying in {countdown}s" and "Try again now" — is a hard-coded English literal in the component. The source defines no string keys, no message catalogue and no locale parameter, so there is no key table to fill; translating the component means changing those literals in source. This fails the `no-hardcoded-strings` compliance check (see Compliance).

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The spinner carries the `animate-spin` class unconditionally and the source never reads `prefers-reduced-motion`, so the rotation and the once-per-second countdown update continue unchanged when Reduce Motion is on. No enter or exit transition is applied to the overlay, so there is nothing else to disable. See respects-reduced-motion. |
| Increase Contrast | Not applicable: All colors use ADH theme tokens (var(--color-apt-*)) that are defined by the consuming application. The component passes through whatever theme colors are set; contrast is determined by the theme, not the component. |
| Differentiate Without Color | Not applicable: The spinner and countdown are identifiable by non-color attributes (animated icon shape, numeric countdown value). The primary status message is text-based. |

## Feature Flags

Not applicable: the component is always enabled. It reads no flag service and exposes no enable/disable option; the consumer controls whether it appears solely through the `active` prop.

## Analytics

Not applicable: the source fires no analytics events. Nothing is emitted on render, on the deploying-to-unreachable transition, on the button click, or on auto-retry, and the component imports no telemetry client. A consumer that wants outage or retry metrics instruments its own `onRetry` handler.

## Privacy

- **Data collected**: None. The component does not collect, store, or transmit any user data beyond the `detail` prop string (which is provided by the consumer).
- **Storage**: No data is stored persistently or in sessionStorage/localStorage.
- **Transmission**: No network requests are initiated by the component. The `onRetry` callback is delegated to the consumer.
- **Retention**: No data is retained.

## Logging

Not applicable: the component performs no logging. It declares no subsystem or category and makes no `console` or logger call on any path — show, hide, tick, auto-retry or manual retry. Outage diagnostics come from the `detail` prop the consumer passes in and from the consumer's own retry handler.

## Platform Notes

- **React / Web (source platform)**: `packages/web/packages/ui/src/components/connection-overlay.tsx`, vendored as `@adh-sdk/ui`. Specific to this file: the `"use client"` directive for the Next.js server/client boundary; `useState`/`useRef`/`useEffect` for state, with `setTimeout` for the 1,200ms debounce and `setInterval` for the 1s tick; the `remainingRef` + `onRetryRef` pair that keeps the auto-retry out of a `setState` updater (which React may run twice under StrictMode) and off the effect's dependency list (an inline consumer callback would otherwise reset the countdown on every parent render); the `Loader2` spinner from `lucide-react`; inline styles rather than classes; and the modern CSS the layer leans on — `inset: 0`, `color-mix(in srgb, …)` and `backdrop-filter: blur(3px)` with its `-webkit-` twin.

- **SwiftUI**: Start from `.overlay(alignment: .center)` on the board view (or a `ZStack` layer), gated by the debounced `shown` state, so the board is covered rather than replaced — `.sheet` and `.fullScreenCover` are wrong here because both are dismissible and take over the screen. The scrim is `Color(.aptBg).opacity(0.9)` over `.background(.ultraThinMaterial)`; SwiftUI has no `backdrop-filter`, and material is the nearest equivalent. The card is a `VStack(spacing: 13)` with `.padding(.vertical, 28).padding(.horizontal, 34)`, `.background(Color(.aptSurface), in: RoundedRectangle(cornerRadius: 12))`, `.overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.aptBorder), lineWidth: 1))`, `.shadow(color: .black.opacity(0.35), radius: 20, y: 8)` and `.frame(maxWidth: 360)` — there is no `ch` unit, so convert 46ch against the monospace face. Spinner: `ProgressView().progressViewStyle(.circular).controlSize(.large).tint(Color(.aptBlue))`, which animates itself, so nothing replaces `animate-spin`. Timing: a cancellable `Task` with `try await Task.sleep(for: .milliseconds(1200))` for the debounce, and `.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect())` for the tick, cancelled in `.onDisappear`. Type: `.font(.system(size: 17, weight: .bold, design: .monospaced))` for the heading with `.kerning(0.34)` for the 0.02em tracking. Accessibility: `.accessibilityElement(children: .contain)` with `.accessibilityLabel(heading)` gives the card a single announced label, but `.accessibilityAddTraits(.updatesFrequently)` is not a substitute for `aria-live="polite"` — it only hints that VoiceOver may re-poll the value, it does not force an announcement. Post `AccessibilityNotification.Announcement(heading)` whenever `heading` changes (deploying → unreachable), matching the UIKit bullet's `UIAccessibility.post(notification: .announcement, …)`; mark the spinner and the countdown `.accessibilityHidden(true)`. Give the button `.frame(minWidth: 44, minHeight: 44)` — the source's 7×18 padding does not reach the HIG target.

- **Compose**: Start from a `Box(Modifier.matchParentSize())` inside the board's own `Box`, not `Dialog` — a dialog draws in its own window and dims the whole screen, while this layer must cover only the board. If a `Dialog` is unavoidable, pass `DialogProperties(usePlatformDefaultWidth = false, dismissOnBackPress = false, dismissOnClickOutside = false)` to match a layer that has no dismiss action. Scrim: `Modifier.background(MaterialTheme.colorScheme.background.copy(alpha = 0.9f))`; there is no portable backdrop blur, so either apply `Modifier.blur(3.dp)` to the content beneath on Android 12+ or drop the blur and keep the 90% scrim. Card: `Surface(shape = RoundedCornerShape(12.dp), border = BorderStroke(1.dp, …), shadowElevation = 8.dp)` around a `Column(verticalArrangement = Arrangement.spacedBy(13.dp), horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.widthIn(max = 360.dp).padding(horizontal = 34.dp, vertical = 28.dp))`. Spinner: `CircularProgressIndicator(modifier = Modifier.size(34.dp), color = …)`. Timing: `LaunchedEffect(active) { delay(1_200); shown = true }` for the debounce and `LaunchedEffect(shown) { while (true) { delay(1_000); … } }` for the tick — coroutine cancellation on key change replaces the `clearTimeout`/`clearInterval` cleanup. `rememberUpdatedState(onRetry)` is the direct analogue of `onRetryRef`. Map the tokens onto a Material 3 `ColorScheme` and use `FontFamily.Monospace`. Accessibility: `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` on the layer, `Modifier.clearAndSetSemantics {}` on the countdown and the spinner, and `Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp)` on the button for the Material 3 target size.

- **AppKit / UIKit**: UIKit — add a plain `UIView` constrained to the board view's edges rather than presenting a `UIViewController`, which would replace the board instead of sitting over it. Layer a `UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))` under a 0.9-alpha background colour for the scrim. The card is a `UIStackView(axis: .vertical, spacing: 13)` inside a container with `layer.cornerRadius = 12`, `layer.borderWidth = 1`, `layer.shadowOffset = CGSize(width: 0, height: 8)`, `layer.shadowRadius = 20`, `layer.shadowOpacity = 0.35`, and `directionalLayoutMargins` of 28/34. Spinner: `UIActivityIndicatorView(style: .large)` with `color` set, or a `UIImageView` driven by a repeating `CABasicAnimation` on `transform.rotation.z` if the Loader2 glyph is kept. Timing: a `DispatchWorkItem` (or `Timer`) for the 1.2s debounce and `Timer.scheduledTimer(withTimeInterval: 1, repeats: true)` added to `RunLoop.main` in `.common` mode so the countdown keeps ticking during scroll tracking; invalidate both when the view is hidden or deallocated. AppKit — the same layering with `NSVisualEffectView(material: .hudWindow, blendingMode: .withinWindow)`, an `NSStackView` card and `NSProgressIndicator(style: .spinning)`. Replace the `--color-apt-*` custom properties with a `UIColor`/`NSColor` asset-catalogue set carrying light and dark variants; neither framework inherits CSS custom properties. Accessibility: there is no `aria-live`, so post `UIAccessibility.post(notification: .announcement, argument: heading)` (AppKit: `NSAccessibility.post(element:notification:.announcementRequested)`) when the heading changes, set `isAccessibilityElement = false` on the countdown label and the spinner, and give the button a 44×44pt minimum frame on iOS.

- **WinUI 3**: Place a `Grid` spanning the board's rows and columns inside the page's root `Grid`, with `Canvas.ZIndex="50"` — not a `ContentDialog`, which dims and disables the entire window and is dismissible, whereas this layer covers only the board and has no dismiss action. Scrim: a `SolidColorBrush` over the page background with `Opacity="0.9"`; XAML has no `backdrop-filter`, so get the blur from a window `DesktopAcrylicBackdrop` or from a `Microsoft.UI.Composition` `GaussianBlurEffect` painted through a `CompositionBrush` on the layer. Card: a `Border` with `CornerRadius="12"`, `BorderThickness="1"`, `BorderBrush="{ThemeResource CardStrokeColorDefaultBrush}"`, `Background="{ThemeResource CardBackgroundFillColorDefaultBrush}"`, `Padding="34,28"`, `MaxWidth="460"` and a `ThemeShadow` with a `Translation` Z offset for the `0 8 40` shadow, wrapping a `StackPanel Spacing="13" HorizontalAlignment="Center"`. Spinner: `<ProgressRing IsActive="True" Width="34" Height="34" Foreground="{ThemeResource AccentFillColorDefaultBrush}"/>`. Timing: a `DispatcherTimer` with `Interval="0:0:1"` for the tick and a second `DispatcherTimer` (or `Task.Delay(1200)` with a `CancellationTokenSource`) for the show debounce; stop both in `Unloaded`. Bind `Heading`, `Sub`, `Retrying in {countdown}s` and the detail row's `Visibility` with `x:Bind` against a ViewModel implementing `INotifyPropertyChanged`, using a `BoolToVisibilityConverter` for the detail row — the equivalent of the `detail && !deploying` guard. Typography: `FontFamily="Cascadia Mono"`, heading on `{StaticResource SubtitleTextBlockStyle}` with `FontWeight="Bold"`, subtitle on `{StaticResource CaptionTextBlockStyle}` with `Foreground="{ThemeResource TextFillColorSecondaryBrush}"`, countdown with `TextFillColorTertiaryBrush`. The stock `Button` style already supplies the `CommonStates` visual states (`Normal`, `PointerOver`, `Pressed`, `Disabled`); the source defines none, so accept the Fluent defaults rather than flattening them. Accessibility: `AutomationProperties.LiveSetting="Polite"` on the layer with `AutomationProperties.Name` carrying the heading replaces `role="status"` + `aria-live="polite"`; set `AutomationProperties.AccessibilityView="Raw"` on the countdown `TextBlock` and the `ProgressRing`; set `MinWidth="44" MinHeight="44"` on the button to reach the Fluent 2 target size. Map each `--color-apt-*` token onto the `ThemeResource` brushes above so the layer follows the app's light/dark theme.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/connection-overlay.tsx` | unverified |

## Design Decisions

1. **Show delay (1200ms)**
   **Decision**: Debounce the overlay's appearance by 1200ms after `active` becomes `true`, and skip that debounce entirely — hiding as soon as the recovery effect runs — the instant `active` becomes `false`.
   **Rationale**: This absorbs brief network hiccups and momentary reconnects without flashing an alarming overlay at the user; hiding skips the debounce on recovery so the overlay never lingers past the outage, even though the hide itself lands on the next commit (a passive effect), not synchronously within the render that saw `active=false` (see hide-immediately-on-recovery). 1200ms is a source constant — the code comments describe intent ("don't flash on a momentary blip") but the exact value's derivation is not documented in source and should be treated as unverified rather than tied to any specific deploy-restart measurement.
   **Approved**: pending

2. **Grace period (90 seconds)**
   **Decision**: Frame outages under 90 seconds as "Backend deploying" (calm, expected) and outages at or past 90 seconds as "Backend unreachable" (explicit acknowledgment).
   **Rationale**: A redeploy briefly drops the connection; framing that as deploying avoids alarming the user during an expected, short gap, while a longer outage warrants a plainer, less reassuring message. Like the show delay, 90,000ms is a source constant with no documented derivation in source — treat its rationale as unverified rather than confirmed against real backend restart timings.
   **Approved**: pending

3. **Retry countdown (15 seconds)**
   **Decision**: Use a fixed 15-second auto-retry cadence, independent of the consuming application's own poll clock.
   **Rationale**: A fixed local countdown always counts cleanly down to a real retry without drift or desynchronization from an external clock; 15 seconds balances frequent attempts (low user wait time) against backend load (not hammering a recovering service).
   **Approved**: pending

4. **Countdown persists across heading changes**
   **Decision**: The countdown continues running when the outage crosses the 90-second grace period and the heading switches from "deploying" to "unreachable" — it is not reset by the heading change.
   **Rationale**: Resetting the countdown at the same moment the heading changes would be visually jarring and would wrongly suggest that retries had restarted, when in fact they have been continuing steadily throughout.
   **Approved**: pending

5. **Detail text hidden during deploy phase**
   **Decision**: Hide the `detail` text during the deploying phase; show it only once the grace period has expired.
   **Rationale**: During a brief, expected deploy window, a technical error string is distracting and irrelevant noise; once the outage is plainly abnormal, the detail becomes useful context.
   **Approved**: pending

6. **ref-based callback storage (onRetryRef)**
   **Decision**: Store `onRetry` in a ref (`onRetryRef`), updated on every render, rather than including it in the tick effect's dependency array.
   **Rationale**: A consumer passing a new inline callback identity on every render is common; listing `onRetry` as a dependency would re-run the effect and reset the countdown on every parent re-render, so the 15s auto-retry would never actually fire.
   **Approved**: pending

7. **aria-hidden on countdown and spinner**
   **Decision**: Mark both the countdown and the spinner `aria-hidden="true"`.
   **Rationale**: The countdown updates every second and would spam a screen reader if announced; the spinner is purely decorative. The heading and subheading, inside the `aria-live="polite"` region, already convey all necessary state.
   **Approved**: pending

8. **Absolute positioning with inset: 0**
   **Decision**: Position the overlay with `inset: 0` (shorthand for top/right/bottom/left) rather than four longhand declarations, covering the parent container's content box.
   **Rationale**: `inset: 0` is more concise and maintainable than specifying each side individually; the overlay's parent must establish a positioning context (`position: relative` or equivalent) for this to cover it correctly — the overlay covers its containing block, not necessarily the browser viewport.
   **Approved**: pending

9. **App-agnostic color tokens, except button text and shadow**
   **Decision**: Colors reference ADH theme tokens (`var(--color-apt-*)`) for every surface, border, and text color, so the component adapts to the consuming application's theme without modification — except the button's text color (hard-coded `white`) and the card's drop shadow (hard-coded `rgba(0,0,0,0.35)`), which are fixed values rather than tokens.
   **Rationale**: Token-based colors let the overlay track the app's light/dark theme; the button text and shadow are left as fixed values in source rather than tokenized, narrowing this decision's scope to "all colors except those two."
   **Approved**: pending

10. **Obscuring background (90% opacity + blur)**
    **Decision**: Make the overlay's background 90% opaque with a 3px blur.
    **Rationale**: A transparent overlay would blur the distinction between "overlay present" and "content behind it"; a fully opaque one would hide context entirely. 90% opacity with blur keeps the overlay the clear visual focus while still hinting at the content underneath.
    **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`keyboard-navigable`, `focus-management`, `reduced-motion`, and `no-hardcoded-strings` are read directly from source: a native `<button>` in the normal tab order, no focus trap or restore around the modal card, the `animate-spin` class applied unconditionally with no `prefers-reduced-motion` check, and five hard-coded English literals with no key table. `touch-target-size` is `partial` because source sets no explicit hit-area size — closing it needs a decision beyond what the source shows: see the open question on touch-target-size. `contrast-ratio` is `partial` because colors resolve to app-supplied theme tokens whose actual contrast the source itself cannot verify. separation-of-concerns is partial because the show-delay debounce, 15-second countdown, and auto-retry timers are the component's actual behavior rather than incidental bookkeeping, and none of that state-machine logic is factored out of `connection-overlay.tsx` into a separate hook, while unit-test-coverage is failed because no test file exercises this component at all.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Corrected hide-immediately-on-recovery/overlay-004/two edge cases/Design Decision 1 to reflect the async passive-effect hide, not synchronous. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: failed). |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirement IDs to drop must-/should- prefixes and fix the backwards hidden-when-inactive name; add visible-focus-indicator and respects-reduced-motion requirements; define outage-duration (elapsedMs) measurement in Behavioral Requirements and Configuration; scope prevent-interaction-with-underlying-content to pointer/visual access only; reformat Design Decisions to Decision/Rationale/Approved and mark the show-delay and grace-period rationale as unverified source constants; narrow the color-tokens decision to exclude button text and shadow; link Compliance checks to the catalog, fix their statuses, and drop the non-catalog Offline behavior row; mark Localization's no-hardcoded-strings failed; correct the WCAG SC 2.5.8 level citation and add references; rewrite the overlay-004/018/019 test vectors to assert observable outcomes and add vectors for the focus indicator, reduced motion, countdown persistence, and the rapid-toggle debounce; retitle and clarify two edge cases; remove appearance/state rows that added no guidance; correct the SwiftUI live-region guidance to post an announcement on heading change; and reword full-viewport coverage to containing-block coverage |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Replace unresolved-gap placeholders with source-traced facts; add concrete translation guidance to Platform Notes; reword Compliance statuses |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source code (generated by Claude Haiku 4.5) |
