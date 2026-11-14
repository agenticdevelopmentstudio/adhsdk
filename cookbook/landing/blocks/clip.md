---
id: e268fe4f-8e83-4189-b1d2-105cd177308c
title: "Clip"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Auto-playing video component that respects prefers-reduced-motion for accessible playback control."
platforms:
  - typescript
  - web
tags:
  - video
  - media
  - reduced-motion
  - accessibility
depends-on: []
related:
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/3d970d6a-2d71-48f3-9f84-69c1d823d6e8
references:
  - https://www.w3.org/TR/WCAG21/#animation-from-interactions
  - https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
approved-by: ""
approved-date: ""
---

# Clip

## Overview

A video player component that auto-plays on load while respecting the user's `prefers-reduced-motion` preference. When the user has requested reduced motion, the component disables auto-play, disables looping, and enables playback controls to put the user in control. When reduced motion is not requested, the component auto-plays and loops silently without controls.

## Behavioral Requirements

- **accept-src**: Component MUST accept a `src` prop containing the public path to an `.mp4` or `.webm` video file.
- **render-video-element**: Component MUST render a single `<video>` element with the provided `src`.
- **aria-label**: Component MUST accept a `label` prop and set it as the video element's `aria-label`.
- **respect-reduced-motion**: Component MUST read the `prefers-reduced-motion` media query and adapt playback behavior accordingly.
- **autoplay-when-motion-allowed**: Component MUST set `autoPlay=true` on the video element when `prefers-reduced-motion` is false.
- **disable-autoplay-when-motion-reduced**: Component MUST set `autoPlay=false` on the video element when `prefers-reduced-motion` is true.
- **loop-when-motion-allowed**: Component MUST set `loop=true` on the video element when `prefers-reduced-motion` is false.
- **disable-loop-when-motion-reduced**: Component MUST set `loop=false` on the video element when `prefers-reduced-motion` is true.
- **show-controls-when-motion-reduced**: Component MUST set `controls=true` on the video element when `prefers-reduced-motion` is true.
- **hide-controls-when-motion-allowed**: Component MUST set `controls=false` on the video element when `prefers-reduced-motion` is false.
- **always-mute**: Component MUST set `muted=true` on the video element.
- **play-inline**: Component MUST set `playsInline=true` on the video element.
- **respond-to-preference-changes**: Component MUST pause the video immediately via an imperative `ref.current?.pause()` when `prefers-reduced-motion` changes from false to true while the page is open, including the correction that happens right after hydration. When the preference changes from true to false, no imperative action is taken, so playback that was already paused does not resume automatically.
- **accept-dimensions**: Component MUST accept optional `width` and `height` props and apply them to the video element for layout sizing before content loads.

## Appearance

- **Corner radius**: None (native video element, no rounding)
- **Padding**: None (native video element)
- **Font**: Not applicable (video player displays video content, not text)
- **Background**: Transparent or determined by browser default (video fills its container)
- **Foreground/Text**: Not applicable
- **Border**: None (native video element)
- **Shadow**: None (native video element)
- **Min/Max size**: Sized by parent container or `width`/`height` props; aspect ratio determined by video source

## States

| State | Appearance change |
|-------|------------------|
| Default | Video displays at intrinsic size or dimensions specified by `width`/`height` props |
| Autoplaying (motion allowed) | Video plays silently, loops continuously; no controls visible |
| Reduced motion active | Video is paused; autoplay and loop are disabled; playback controls are visible for user-initiated playback |

## Accessibility

- **Role**: The component renders a native HTML `<video>` element. `<video>` has no implicit ARIA role; the accessible name comes entirely from the `aria-label` attribute.
- **Label requirements**: MUST have a `label` prop provided so the video element carries an `aria-label` (see **aria-label**) describing the video content. This is the accessible name for screen readers.
- **Announce state changes**: The component does not announce state changes via ARIA live regions; the user controls playback through visible controls when `prefers-reduced-motion` is true.
- **Motion preference**: MUST respect `prefers-reduced-motion: reduce` per [WCAG 2.1 Animation from Interactions](https://www.w3.org/TR/WCAG21/#animation-from-interactions). When enabled, the component must not autoplay or loop without explicit user action.
- **Keyboard control**: When controls are visible (reduced motion), the native video element provides keyboard support (spacebar, arrow keys) for playback control.
- **Minimum tap target**: Native video controls (when visible) are sized and hit-tested by the browser; this component does not control or verify their tap-target dimensions against platform minimums (44×44pt on iOS, 48×48dp on Android).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| clip-001 | render-video-element, accept-src | `src="https://example.com/video.mp4"` | Video element renders with `src` attribute set to the provided URL |
| clip-002 | aria-label | `label="Demo video"` | Video element has `aria-label="Demo video"` |
| clip-003 | accept-dimensions | `width={640}`, `height={360}` | Video element renders with `width="640"` and `height="360"` attributes |
| clip-004 | autoplay-when-motion-allowed, loop-when-motion-allowed, hide-controls-when-motion-allowed | `prefers-reduced-motion` is false | Video element has `autoPlay={true}`, `loop={true}`, `controls={false}` |
| clip-005 | disable-autoplay-when-motion-reduced, disable-loop-when-motion-reduced, show-controls-when-motion-reduced | `prefers-reduced-motion` is true | Video element has `autoPlay={false}`, `loop={false}`, `controls={true}` |
| clip-006 | always-mute | Any props | Video element has `muted={true}` |
| clip-007 | play-inline | Any props | Video element has `playsInline={true}` |
| clip-008 | respond-to-preference-changes | Video is autoplaying with `prefers-reduced-motion` false; a mocked `matchMedia` change event fires with `matches: true` | Video element pauses immediately via `ref.current?.pause()` |
| clip-009 | accept-src | `src="video.webm"` | Video element's `src` attribute is set to `"video.webm"` (asserted via the DOM attribute; actual `.webm` decoding is not exercised in jsdom) |
| clip-010 | respond-to-preference-changes | Server renders assuming `prefers-reduced-motion` is false; the client's actual OS preference is true | After hydration corrects the `usePrefersReducedMotion` snapshot to `true`, the pause effect fires and the video ends up paused despite the SSR markup emitting `autoPlay` |
| clip-011 | respond-to-preference-changes | Video is paused because `prefers-reduced-motion` was true; the preference then changes to false | `autoPlay`/`loop` update to `true` and `controls` to `false`, but playback does not resume automatically — the video stays paused until the user or host calls `.play()` |

## Edge Cases

- **Empty or missing src**: If `src` is an empty string or undefined, the video element will not load any content. The component renders with an empty `src` attribute; the browser displays no video. This is a valid state and requires the host to handle the missing source.
- **Missing label**: If `label` is not provided, the video element has no `aria-label`. This is an accessibility failure; the video is not described for screen reader users. The component does not provide a fallback; the caller is responsible for always providing a label.
- **Invalid video URL**: If `src` points to a URL that does not exist or is not a valid video file, the video element cannot load it. The browser displays a broken video icon or placeholder. The component does not provide error callbacks; the host is responsible for validating the URL.
- **Reduced motion re-enabled after being disabled**: If the user toggles `prefers-reduced-motion` from true back to false, `autoPlay` and `loop` update to `true` on the video element, but this does not restart playback: an already-mounted `<video>` element does not resume just because its `autoPlay` attribute changes (see **respond-to-preference-changes**). If the video was paused because reduced motion was true, it remains paused until the user presses play or the host calls `.play()` imperatively.
- **Zero or negative dimensions**: If `width` or `height` are 0 or negative, the video element renders with those invalid dimensions. The browser behavior is undefined (likely no visible video). The component does not validate or constrain dimension values.
- **Video ends while looping enabled**: When `loop={true}` (motion allowed), the video replays automatically without interruption. When `loop={false}` (motion reduced), the video stops at the end and requires the user to click play again.
- **Bandwidth or network failure**: If the video fails to load due to network error, the component does not provide error feedback or retry logic. The native video element displays an error indicator; error handling is the caller's responsibility.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `src` | string | — | **Required.** Public path to the `.mp4` or `.webm` video file. |
| `label` | string | — | **Required.** Accessible name for screen readers, describing the video content. |
| `width` | number | — | Optional. Intrinsic width of the video in pixels for layout sizing before load. |
| `height` | number | — | Optional. Intrinsic height of the video in pixels for layout sizing before load. |

## Deep Linking

Not applicable: This component is a playback container for video content. It does not navigate or support deep-linking patterns. The host application provides the video source URL.

## Localization

The component contains no user-facing text of its own; the native video controls (when visible) are localized by the browser using the OS locale. The `label` prop is passed straight through to the video element's `aria-label` without any transformation — the caller MUST pass an already-localized `label` string; the component does not translate, format, or otherwise process it.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Component disables autoplay, disables looping, and enables controls to put playback control in the user's hands. This is the primary accessibility feature of the component. |
| Increase Contrast | Not applicable: The component renders a native video element. Contrast is determined by the video content and native browser controls. |
| Differentiate Without Color | Not applicable: The component contains no color-dependent information. |

## Feature Flags

Not applicable: The component has no feature flag support. Playback behavior is determined entirely by the `prefers-reduced-motion` preference.

## Analytics

Not applicable: The component does not emit events. Event tracking is the caller's responsibility.

## Privacy

- **Data collected**: None. The component reads the OS `prefers-reduced-motion` preference locally; no data is sent to any service.
- **Storage**: None. The preference is read from the browser's media query API and is not cached or persisted by the component.
- **Transmission**: None. No data leaves the device.
- **Retention**: Not applicable. No data is stored.

## Logging

Not applicable: The component does not emit log events.

## Platform Notes

- **Web/TypeScript**: The component uses `useSyncExternalStore` to read `prefers-reduced-motion` via `window.matchMedia()` and subscribe to changes. The server-side snapshot returns `false` (motion allowed) to prevent hydration mismatch; the client snapshot is corrected on first render. The component renders a native `<video>` element with HTML attributes. Source: `packages/web/packages/landing/src/blocks/Clip.tsx`.
- **SwiftUI**: Wrap `AVPlayerViewController` (iOS) or an `NSViewControllerRepresentable`-hosted `AVPlayerView` (macOS) rather than the plain `VideoPlayer` view, since `VideoPlayer` exposes no controls-visibility modifier. Read `@Environment(\.accessibilityReduceMotion)`: when true, show controls and play with a plain `AVPlayer` so playback stops at the end; when false, hide controls and loop with an `AVQueuePlayer` + `AVPlayerLooper` (`AVPlayer` has no built-in loop flag). Keep `player.isMuted = true` in every state. Apply `.accessibilityLabel()` with the provided label string.
- **Compose (Android)**: Use `ExoPlayer` (recommended) hosted in a Compose `AndroidView`. Android has no direct `prefers-reduced-motion` equivalent; detect the closest analog via `Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f`. When reduced, set `useController = true` and `repeatMode = Player.REPEAT_MODE_OFF`; when not reduced, set `useController = false` and `repeatMode = Player.REPEAT_MODE_ALL`. Keep the player muted (`player.volume = 0f`) in every state. Set `contentDescription` on the wrapping view for the accessible label.
- **AppKit / UIKit**: Use `AVPlayerView` (AppKit, macOS) or `AVPlayerViewController` (UIKit, iOS) to host playback, with an `AVQueuePlayer` + `AVPlayerLooper` to loop content (`AVPlayer` has no native loop flag). Bind `showsPlaybackControls` to the platform's reduce-motion signal — `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` on AppKit, `UIAccessibility.isReduceMotionEnabled` on UIKit (both Bool properties, not functions). When reduced motion is true, show controls and use a plain `AVPlayer` (not the looper) so playback stops at the end. Keep `player.isMuted = true` in every state — audio stays muted regardless of the motion preference. Set the view's `accessibilityLabel` to the provided label string.
- **WinUI 3**: Use `MediaPlayerElement` from the Windows App SDK. Windows has no direct `prefers-reduced-motion` API; read `new UISettings().AnimationsEnabled` as the closest system-wide analog. When animations are disabled, set `AutoPlay=false`, `IsLoopingEnabled=false`, and show playback controls. When animations are enabled, hide controls, set `AutoPlay=true`, and set `IsLoopingEnabled=true`. Mute audio via `MediaPlayerElement.MediaPlayer.IsMuted = true` in every state. Use `AutomationProperties.Name` for the accessible label.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Clip.tsx` | unverified |

## Design Decisions

**Decision**: The component always sets `muted=true` on the video element.
**Rationale**: Auto-playing video with sound is widely blocked by browsers and disruptive to users; the caller can provide separate UI to unmute if needed, but auto-play without mute is not a viable strategy on the web.
**Approved**: pending

**Decision**: The server-side snapshot of `useSyncExternalStore` returns `false` (motion allowed), so the initial HTML always includes `autoPlay` and `loop` attributes.
**Rationale**: The server has no OS preference to consult, so returning `false` avoids a hydration mismatch. React corrects the attributes on first hydration once the real client value is available.
**Approved**: pending

**Decision**: The component uses a `useEffect` that calls `ref.current?.pause()` whenever `reduced` becomes `true`.
**Rationale**: Setting `autoPlay=false` does not stop playback that has already started, so an imperative pause is required to guarantee the video stops the instant reduced motion is requested.
**Approved**: pending

**Decision**: The component provides no error callbacks or fallback UI for video loading failures.
**Rationale**: Video loading errors are handled by the browser's native error state; leaving error handling to the caller keeps this a small, reusable media component.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

These rest on the source: the `aria-label` attribute carries the accessible name (screen-reader-support, semantic-markup), the native `<video>` element's keyboard-operable controls when `controls` is shown (keyboard-navigable), the `usePrefersReducedMotion` hook driving `autoPlay`/`loop`/`controls` (reduced-motion), and the unmodified pass-through of the `label` string to `aria-label` (unicode-support); native control sizing is the browser's own and is not verified by the source (touch-target-size). separation-of-concerns passes because the reduced-motion subscription (`usePrefersReducedMotion`, `subscribe`, `getSnapshot`) is factored out of `Clip.tsx` into its own hook, leaving the component itself a thin wrapper over a `<video>`, and unit-test-coverage passes because `clip.test.tsx` exercises both the motion-fine and reduced-motion branches and the force-pause effect with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected the video role and tap-target claims, fixed nonexistent/misused platform APIs, resolved the AppKit/UIKit mute contradiction, merged duplicate requirements and renamed all requirements to subject-only kebab-case, reformatted Design Decisions, rebuilt Compliance as a linked table, merged duplicate States rows, corrected the reduced-motion-reversal edge case, added SSR-hydration and reverse-transition test vectors, fixed the webm and preference-change test vectors, stated the caller's localization obligation, and populated tags/references/related |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
