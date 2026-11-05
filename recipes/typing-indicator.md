---
id: 7d2b41f0-63aa-47d1-94f8-19a06caedc6a
title: Typing Indicator
domain: adhsdk://recipes/typing-indicator
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A visual indicator showing that a persona is composing a response, with support
  for animated status words and phase-driven transitions.
platforms:
- typescript
- web
- swift
- macos
- ios
tags:
- chat
- indicator
- animation
- status
depends-on: []
related:
- adhsdk://recipes/inline-chat
- adhsdk://recipes/mobile-chat
- adhsdk://recipes/transcript
references:
- https://www.w3.org/TR/WCAG21/
approved-by: ''
approved-date: ''
---

# Typing Indicator

## Overview

The typing indicator displays an active typing or thinking status during persona response generation. It has two rendering paths: a fallback three-dot pulsing animation when no custom status words are configured, or a phase-driven animated line with rotating braille glyphs, status words, and elapsed-time feedback when vocabulary is provided. The component is themed from the active semantic palette and repaints live on theme change.

## Behavioral Requirements

- **support-two-rendering-paths**: The component MUST support two distinct rendering paths selected by whether status words are configured: a three-dot pulsing animation, or a phase-driven line with an animating glyph and rotating status word. See **handle-empty-word-bag** for the exact rule selecting the dot-pulse path when words are empty, absent, or malformed.

- **render-dots-pulse-when-inactive**: In the three-dot rendering path, when the typing status is inactive (false or null), the web component MUST NOT render any visual indicator. On macOS/iOS, the three dots are created visible at setup (30% alpha) and are never hidden by the dot path or by the host chat view; `update(status: nil)` only stops the pulse timer, leaving whichever dot the last tick lit frozen at its current alpha.

- **render-dots-pulse-when-active**: In the three-dot rendering path, when the typing status is active (true or non-null), the component MUST render three circular dots that animate sequentially by fading to full opacity while others fade to 30% opacity on a 0.35-second cycle.

- **cycle-through-status-words**: When status words are configured, the component MUST cycle through the provided word list using draw-without-replacement (each word in the vocabulary is shown once before any word repeats). The transition to a new word MUST occur on the `labelMs` interval (default 1800ms).

- **animate-glyph**: The component MUST animate a rotating glyph character on the `frameMs` interval (default 260ms). The glyph cycles through the provided frame array in order.

- **support-phase-machine**: The component MUST drive phase transitions (idle, thinking, utterance, done) using a shared phase machine that tracks when a turn begins and ends, manages word bag state, and calculates elapsed time.

- **show-active-line-while-typing**: When the phase is "thinking" (during active response generation), the component MUST display the current glyph followed by a space and the current status word with an ellipsis (e.g., "⠙ thinking…"). The text MUST use the `.personaName` color by default.

- **show-utterance-when-provided**: When an utterance is provided (caller-set transient text), the component MUST display it immediately with the animating glyph, overriding any phase-driven content — including the settled line (see **show-settled-line-when-done**). On web, the utterance MUST persist only until explicitly cleared by the caller. On macOS/iOS, the shared `ThinkingPhase.Machine` does not honor this persistence across a turn transition or a fresh status while an utterance is showing; see the **Turn transitions during utterance** edge case.

- **show-settled-line-when-done**: When the phase is "done" (the active turn has ended) and no utterance is currently showing, the component MUST display the done glyph followed by a space, the past-tense form of the last status word, and elapsed seconds in the format "[glyph] [past word] for [N]s". This line MUST use the `.thinkingDoneText` color and MUST NOT be tinted by the `colorful` or `tint` configuration options. On web, if an utterance is showing when the turn settles, **show-utterance-when-provided** wins: the settled line MUST NOT appear until the caller clears the utterance. On macOS/iOS, the shared phase machine settles `.utterance` straight into `.done` on the turn ending, so the settled line replaces the utterance immediately and the caller's later call to clear the utterance is a no-op; see the **Turn transitions during utterance** edge case.

- **show-idle-phrase-when-configured**: When an idle phrase is configured and the phase is "idle" (before the first turn), the component MUST display the idle phrase with the done glyph and an ellipsis using `.thinkingIdleText` color.

- **not-show-idle-phrase-when-not-configured**: When no idle phrase is configured, the component MUST render no visual indicator during the idle phase.

- **reset-idle-on-first-turn**: The idle phrase, when shown, MUST yield to the thinking state on the first turn transition and never return.

- **support-frame-configuration**: The component MUST accept a frame array containing character strings that form a rotating animation. The default frame array is the ten-character braille spinner sequence: ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'].

- **support-done-glyph-configuration**: The component MUST accept a single character to display as the settled/done glyph. The default is '✱'.

- **support-frame-interval-configuration**: The component MUST accept a frame interval duration in milliseconds (default 260ms) controlling how often the glyph animation advances.

- **support-word-interval-configuration**: The component MUST accept a word interval duration in milliseconds (default 1800ms) controlling how often the status word rotates.

- **support-colorful-mode**: When `colorful` is enabled, the component MUST flash vivid random non-green hues while thinking or uttering. A non-green hue is one that skips the hue band approximately 75°–165° (greens). The color MUST be generated at HSL 85% saturation and 62% lightness. The color MUST NOT be applied to the settled line. On web, the color MUST change on a 1-second cycle during active phases. On macOS (the only other platform where `colorful` is supported; see Configuration), the color is drawn once when a fresh think begins and once per `say()` call, then held for the rest of that phase — it does not recycle every second.

- **support-tint-configuration**: The component MUST accept an optional tint specification that colors the glyph, words, or both while thinking or uttering. The tint MUST NOT be applied to the settled line when done.

- **support-utterance-clear**: The component MUST provide a mechanism for the caller to clear a transient utterance, causing the indicator to resume showing phase-driven content.

- **announce-status-changes**: The component MUST post accessibility announcements when the phase changes (entering thinking, settling to done) or when a fresh utterance is set. Announcements MUST NOT occur on every frame tick or on every status-word rotation — only on phase transitions and utterance changes.

- **respond-to-theme-changes**: The component MUST listen for theme/palette changes and repaint immediately to reflect new semantic colors without requiring component restart.

- **maintain-glyph-box-width**: In platform representations that separate the glyph from the word text (e.g., AppKit/macOS), the glyph MUST occupy a fixed-width box that does not change based on the current frame. The box MUST be wide enough to accommodate the widest frame character in the configured font.

- **handle-empty-frame-array**: If the frame array is empty (malformed configuration), the component MUST render an empty string for the glyph and not crash.

- **handle-empty-word-bag**: If status words are empty, absent, or otherwise malformed (e.g., configured but the array is empty), the component MUST fall back to the three-dot animation path.

## Appearance

- **Dot pulse (fallback path)**:
  - Dots: Three circular shapes, 7×7 points/pixels each
  - Dot spacing: 4 points/pixels horizontal
  - Dot corners: Rounded (50% border radius = 3.5 radius)
  - Dot color: Semantic palette `.secondaryText`
  - Dot opacity: 30% (idle), 100% (active)
  - Animation: Sequential fade, 0.2s transition time per dot, 0.35s cycle interval
  - Minimum component size: 48 × 28 points/pixels

- **Phase-driven line (words-enabled path)**:
  - Font: Semantic palette caption font
  - Text color (active/thinking): `.personaName`
  - Text color (done): `.thinkingDoneText`
  - Text color (idle): `.thinkingIdleText`
  - Glyph box width (macOS/AppKit): Calculated as the maximum of (`1.6ch` where `ch` is the width of the `0` character in the caption font) and the widest glyph character in the configured frames and done glyph. Box is centered.
  - Gap between glyph and words (macOS/AppKit): `0.45em` (45% of caption font point size, rounded)
  - Baseline alignment (macOS/AppKit): Both glyph and word text align to first baseline
  - Line wrapping: Words may truncate at tail if space is constrained
  - Minimum component size: 48 × 28 points/pixels
  - Horizontal padding: 4 points/pixels leading and trailing
  - No background fill or border

- **Colorful mode**:
  - When active, glyph and word colors shift to the randomly generated non-green HSL hue
  - Color cycle interval: 1000ms during thinking or utterance phases (web only)
  - macOS: a new hue is drawn only when a fresh think begins or `say()` is called; it is held for the rest of that phase rather than recycled every second
  - Color does NOT apply to settled/done line

- **Tint mode**:
  - Tint color and apply scope (icons/words/both) MUST NOT apply to settled/done line

## States

| State | Appearance change |
|-------|------------------|
| Idle | Web: no dots visible (unless idle phrase configured). If idle phrase present: grey done glyph with "waiting" phrase and ellipsis. macOS/iOS (dot fallback): the three dots stay visible at 30% alpha; nothing hides them or the host status row. |
| Thinking | Three dots pulsing (fallback), or animating glyph + rotating status word + ellipsis. Text color is `.personaName` (or tinted/colorful override). |
| Utterance | Animating glyph + caller-provided utterance text (overrides phase). Text color is `.personaName` (or tinted/colorful override). Glyph animates, color cycles if colorful. |
| Done | Web: three dots invisible (fallback), or grey done glyph + past-tense word + "for Ns". macOS/iOS (fallback): dots remain visible, frozen at whichever alpha the last pulse tick left them, since stopping the timer does not hide or reset them. Phase-driven path: grey done glyph + past-tense word + "for Ns". Text color is `.thinkingDoneText` (never tinted or colorful). No animation. |

## Accessibility

- Role/trait: The component is a status indicator and does NOT require interactive controls.
- Label requirements: The indicator's content (status words, elapsed time, idle phrase) MUST be accessible to assistive technologies via a live region or announcement mechanism.
- Announce state changes: MUST announce via accessibility API when the phase changes or when a fresh utterance is provided. These announcements MUST be announced at medium or polite priority. Announcing every frame or every word rotation MUST NOT occur.
- Visual hidden text for screen readers: On web, an `aria-live` region holding the current phase announcement (separate from the visual DOM) MUST be present and updated only on phase transitions, not on every glyph frame.
- Minimum tap target: Not applicable; this component is a status display, not an interactive control.
- Color contrast: The status words and done text MUST meet WCAG AA contrast ratio requirements against their backgrounds when rendered in any theme, using the semantic palette's `.personaName`, `.thinkingDoneText`, and `.thinkingIdleText` colors. This guarantee does not extend to **support-colorful-mode**: its hue is drawn at a fixed 85% saturation / 62% lightness without checking the active theme's background, so a given draw is not guaranteed to meet AA contrast on every theme, particularly light ones.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ti-001 | render-dots-pulse-when-inactive | isTyping=false, no words configured | Web: no visual indicator rendered. macOS/iOS: the three dots remain visible at 30% alpha; only the pulse timer is stopped |
| ti-002 | render-dots-pulse-when-active | isTyping=true, no words configured | Three dots animating, cycling through opacity 0.3 → 1.0 on 0.35s cycle |
| ti-003 | show-active-line-while-typing | isTyping=true, words=[{present: "thinking", past: "thought"}] | Glyph animates on 260ms cycle, word "thinking" displays, ellipsis appended |
| ti-004 | cycle-through-status-words | words=[{present: "a", past: "a"}, {present: "b", past: "b"}], labelMs=100 | First render shows word "a"; after 100ms word "b" appears; after 200ms word "a" appears again (no duplicates in between) |
| ti-005 | show-settled-line-when-done | Turn begins and ends, words=[{present: "thinking", past: "thought"}], elapsed=8s | Final render shows "✱ thought for 8s" in `.thinkingDoneText` color, no animation |
| ti-006 | show-idle-phrase-when-configured | idlePhrase="waiting", phase before first turn | Idle phrase renders as "✱ waiting…" in `.thinkingIdleText` color |
| ti-007 | reset-idle-on-first-turn | idlePhrase configured, first isTyping→true transition | Idle phrase disappears and thinking state displays |
| ti-008 | show-utterance-when-provided | utterance="yes!", phase=thinking | Glyph and "yes!" render, overriding status word |
| ti-009 | support-utterance-clear | utterance="yes!" then clearUtterance() called | Thinking state resumes with status word instead of utterance |
| ti-010 | support-colorful-mode | colorful=true, thinking phase | Web: non-green HSL hue applied; color shifts every 1s until done phase reached. macOS: non-green HSL hue applied once at the start of the think; it holds for the rest of the phase and does not shift again until the next fresh think or `say()` |
| ti-011 | not-show-idle-phrase-when-not-configured | No idlePhrase configured, idle phase | No visual indicator rendered |
| ti-012 | announce-status-changes | Phase transitions from idle→thinking→done | Accessibility announcement posted at each transition (thinking, done); no announcement fires on the intervening word rotations |
| ti-013 | respond-to-theme-changes | Component rendered, theme changes | Component repaints with new palette colors immediately |
| ti-014 | handle-empty-frame-array | frames=[], glyph rendering attempted | Empty string rendered as glyph, no crash |
| ti-015 | handle-empty-word-bag | words=[], isTyping=true | Falls back to three-dot pulsing animation |
| ti-016 | maintain-glyph-box-width | Platform with glyph box (macOS), frame changes | Box width remains constant across all frame transitions |
| ti-017 | show-settled-line-when-done, show-utterance-when-provided | utterance="brb" set during thinking phase; isTyping then transitions true→false (turn ends) while the utterance is still set | Web: utterance and glyph continue to display; the settled line does not appear until clearUtterance() is called. macOS/iOS: the shared phase machine settles to done immediately, the settled line replaces "brb", and a subsequent clearUtterance() call is a no-op |
| ti-018 | support-tint-configuration | words configured, tint={color: "#ff0000", applies: "words"}, phase=thinking | Word text renders in the tint color; glyph stays in the default `.personaName` color; once done, the settled line ignores the tint |
| ti-019 | support-frame-interval-configuration | frameMs=100 (web) / frameInterval=.milliseconds(100) (Apple), phase=thinking | Glyph advances to the next frame every 100ms rather than the 260ms default |
| ti-020 | support-word-interval-configuration | labelMs=500 (web) / wordInterval=.milliseconds(500) (Apple), words=[{present: "a", past: "a"}, {present: "b", past: "b"}] | Status word rotates every 500ms rather than the 1800ms default |
| ti-021 | Rapid configuration changes (edge case) | Vocabulary content unchanged but a new array instance is passed mid-turn (same words, new object identity) | The draw-without-replacement bag is NOT rebuilt and the word index is not reset; the current draw order continues uninterrupted |
| ti-022 | Theme palette unavailable (edge case) | Semantic palette cannot be resolved at render time | Component renders using safe fallback (system text) colors and does not crash |
| ti-023 | Idle phrase with no words configured (edge case) | idlePhrase="waiting" configured, words=[] (no vocabulary) | Idle phrase does NOT render; component shows the three-dot fallback path instead |

## Edge Cases

- **Null or empty status words**: See **handle-empty-word-bag**. This fallback requires no phase machine to be running.

- **Rapid configuration changes**: If the status word vocabulary is swapped (e.g., persona changes mid-turn), the component MUST rebuild the draw-without-replacement bag immediately and reset the word index. The phase MUST remain unchanged if the active status does not change. Keying on the content of the words array (not its object identity) MUST prevent unnecessary bag rebuilds when the vocabulary is semantically identical but newly created.

- **Concurrent phase machine operations**: The component's phase machine is actor-isolated (Swift) or main-thread-only (UIKit/AppKit/web). Concurrent writes from multiple threads/tasks are not applicable; all operations on the phase machine MUST serialize through the UI thread.

- **Turn transitions during utterance**: On web, if an utterance is set and the turn status changes (isTyping goes false), the component MUST show the utterance until explicitly cleared by the caller (see **show-utterance-when-provided**); the turn ending does not auto-clear utterances. On macOS/iOS, this does not hold: the shared `ThinkingPhase.Machine` settles a showing `.utterance` straight into `.done` on the turn ending (a `nil` status) or drops it to `.thinking` on a fresh non-nil status, clearing `phaseBeforeUtterance` either way. The settled line (or the new thinking content) replaces the utterance immediately, and the caller's subsequent `clearUtterance()` call is a no-op because it guards on `phase == .utterance`.

- **Colorful mode without utterance/thinking**: The `colorful` flag MUST only affect the active (thinking/utterance) phases. During idle or done phases, colorful has no effect.

- **Tint on settled line**: If a tint is configured and the component enters the done phase, the tint MUST NOT be applied to the settled line. The tint only colors the active and utterance phases.

- **Empty frame array**: See **handle-empty-frame-array**. The word text (if any) continues to display normally.

- **Idle phrase with no words configured**: If idlePhrase is set but no words are configured, the idle phrase MUST NOT render. The three-dot fallback path does not support idle phrases.

- **Theme palette unavailable**: If the semantic palette cannot be resolved, the component MUST use safe fallback colors (system text colors). The component MUST NOT crash due to missing theme.

- **Elapsed time calculation at edge**: When the turn settles, elapsed time MUST be calculated as `max(1, round((now - startTime) / 1000))`, ensuring the minimum reported time is 1 second and the result is rounded to the nearest whole second.

## Configuration

| Option | Web (`TypingIndicatorProps`) | macOS (`ThinkingIndicatorConfiguration`) | iOS (`MobileThinkingIndicatorConfiguration`) | Description |
|--------|------|------|------|-------------|
| Turn active | `isTyping: boolean` (required) | `update(status: ChatStatus?)` method parameter | `update(status: ChatStatus?)` method parameter | Whether a turn is currently in flight. Drives phase transitions. |
| Status words | `labels?: readonly StatusWordPair[]` (default: none) | `words: [ChatStatusWordPair]` (default `[]`) | `words: [ChatStatusWordPair]` (default `[]`) | Vocabulary for status words in present and past tense. Empty means the three-dot fallback (see **handle-empty-word-bag**). |
| Frame glyphs | `frames?: readonly string[]` (default: braille spinner) | `frames: [String]` (default: braille spinner) | `frames: [String]` (default: braille spinner) | Frame characters for the rotating glyph animation. |
| Done glyph | `doneGlyph?: string` (default `'✱'`) | `doneGlyph: String` (default `'✱'`) | `doneGlyph: String` (default `'✱'`) | Character displayed in the settled "done" line. |
| Frame interval | `frameMs?: number` (default `260`) | `frameInterval: Duration` (default `.milliseconds(260)`) | `frameInterval: Duration` (default `.milliseconds(260)`) | Interval between glyph animation frames. |
| Word interval | `labelMs?: number` (default `1800`) | `wordInterval: Duration` (default `.milliseconds(1800)`) | `wordInterval: Duration` (default `.milliseconds(1800)`) | Interval between status word rotations. |
| Colorful mode | `colorful?: boolean` (default `false`) | `colorful: Bool` (default `false`) | Not supported | When true, flash random non-green hues while thinking or uttering. |
| Tint | `tint?: StatusTintSpec` (default `undefined`) | `tint: ThinkingTint?` (default `nil`) | Not supported | Optional color and apply scope (icons/words/both) for the active line. |
| Idle phrase | `idlePhrase?: string` (default `undefined`) | `idlePhrase: String?` (default `nil`) | Not supported | Text to display before the first turn begins (settles to grey). Yields on first turn. |
| Utterance | `utterance?: string \| null` (default `undefined`) | `say(_ utterance: String)` / `clearUtterance()` methods | `say(_ utterance: String)` / `clearUtterance()` methods | Transient utterance text that overrides phase content, including the settled line. On web it persists until the caller clears it. On macOS/iOS it is dropped early by the shared phase machine on a turn transition or a fresh status; see **Turn transitions during utterance**. |

## Deep Linking

Not applicable: The typing indicator is a transient status display within a chat interface and does not support deep linking to a specific state.

## Localization

The status words, idle phrase, and utterance text are caller-provided and are localized by the caller's data layer, not by this component. The text the component itself renders around them, however, is not caller-controlled and is currently hardcoded rather than externalized:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| thinking-ellipsis | `…` | Appended after the active status word or idle phrase (web: `.pc-thinking-ellipsis`; Apple: appended directly to the label text). |
| settled-for | `for` | Connector in the settled line, e.g. "thought for 8s" (web: `.pc-thinking-for`; Apple: `"\(word) for \(machine.elapsedSeconds)s"`). |
| settled-seconds-suffix | `s` | Unit suffix appended to the elapsed-second count in the settled line. |

These three strings are literals in `TypingIndicator.tsx`, `ThinkingIndicatorView.swift`, and `MobileThinkingIndicatorView.swift`, and the elapsed-second count is rendered through a fixed `"for {n}s"` template rather than a locale-aware or pluralizable formatter (see the Compliance section's `locale-aware-formatting` and `no-hardcoded-strings` checks below).

## Accessibility Options

Not applicable: The component does not respond to platform accessibility display options (reduce motion, increase contrast, differentiate without color). It renders status text in semantic palette colors and announces phase changes via live regions/announcements, conforming to WCAG guidelines without option-specific behavior.

## Feature Flags

Not applicable: The component is not gated by feature flags in the sources provided. The two rendering paths (three-dot vs. phase-driven) are determined solely by the presence or absence of configured status words.

## Analytics

Not applicable: The component does not generate or fire analytics events. Analytics integration, if needed, belongs in the caller's chat surface logic that consumes the indicator's phase and utterance props.

## Privacy

Not applicable: The component renders caller-provided status words and utterances but does not collect, store, or transmit any user data beyond what is passed in its configuration.

## Logging

Not applicable: The component does not emit log messages. Platform-specific logging of phase transitions or performance metrics, if needed, belongs to the caller or a higher-level chat orchestrator.

## Platform Notes

- **Web (React)**: The source is `TypingIndicator.tsx` in `packages/web/packages/chat/src/components/`, which also defines the internal `ThinkingStatus` sub-component in the same file. The component accepts `TypingIndicatorProps`, returns early from the main `TypingIndicator` function if `labels` is empty/falsy (rendering classic three-dot dots), otherwise mounts `ThinkingStatus`, which drives phases, word rotation, colorful hue cycling, and utterance handling. Use the exported `TypingIndicator` component directly; `ThinkingStatus` and `StatusWordPair`'s internal helpers are not exported. Styling is via CSS classes (`.pc-thinking`, `.pc-thinking-glyph`, `.pc-thinking-label`, `.pc-thinking-ellipsis`, `.pc-thinking--done`, `.pc-thinking-for`). Accessibility is via an `aria-live="polite"` region (`.pc-status-announce`) that holds phase announcements. The component uses React hooks (`useState`, `useEffect`, `useMemo`, `useRef`) and a `ShuffleBag` utility for draw-without-replacement word selection.

- **SwiftUI**: Not implemented in source; the behavioral requirements above apply to any future implementation. A SwiftUI wrapper around the macOS or iOS UIKit/AppKit views would satisfy them directly. A native SwiftUI implementation would instead need to mirror them itself, using a `TimelineView(.periodic(from:by:))` schedule or a `Timer.publish(every:on:in:).autoconnect()` pipeline for the glyph/dot animation, `@State` for phase tracking, and `AccessibilityNotification.Announcement(_:).post()` for phase-change announcements.

- **Compose (Android/Kotlin)**: Not implemented in source; the behavioral requirements above apply to any future implementation. A Compose implementation would use `LaunchedEffect` for animation timers, `remember`/`mutableStateOf` for phase state and word bag, and `Modifier.semantics { liveRegion = LiveRegionMode.Polite }` on the status text to post accessibility announcements only on phase changes. The visual appearance would mirror iOS: dots for the fallback path, glyph + word text for the phase-driven path.

- **AppKit / UIKit (macOS/iOS)**: The sources are `ThinkingIndicatorView.swift` (macOS/AppKit) and `MobileThinkingIndicatorView.swift` (iOS/UIKit). Both inherit from `NSView`/`UIView`, conform to `Themeable`, and share the same phase machine (`ThinkingPhase.Machine`), but not the same configuration surface: `MobileThinkingIndicatorConfiguration` (iOS) intentionally omits `colorful`, `tint`, and `idlePhrase` — see Configuration above. Initialization is via `init()` or `init(frame:)`. Configuration is installed via `configure(_:)` method; status updates via `update(status:)` method (accepts `ChatStatus?`); utterances via `say(_:)` and `clearUtterance()` methods. Animation uses `Timer` scheduled on `MainActor` for both dot pulse (0.35s cycle, `UIView.animate`/`NSAnimationContext` for opacity transitions) and phase-driven glyph ticking (260ms default). Theme changes via `Themeable` protocol and `ThemePaletteObserver`. Accessibility via `UIAccessibility.post(notification:argument:)` (iOS) or `NSAccessibility.post(element:notification:userInfo:)` (macOS). The macOS version maintains a separate glyph box (`.glyphLabel`) with a fixed-width constraint to prevent text layout shift as glyphs change.

- **WinUI 3**: Not implemented in source; the behavioral requirements above apply to any future implementation. A WinUI 3 implementation would start from `Grid` or `StackPanel` for layout. The three-dot fallback could use three animated `Ellipse` shapes with `Storyboard` for opacity animation. The phase-driven path would use `TextBlock` for glyph and words, `DispatcherTimer` for frame/word cycling, and `VisualStateManager` or custom property animations for phase transitions. Semantic colors would map to XAML `ThemeResource` tokens (e.g., `TextFillColorSecondaryBrush`, `AccentTextFillColorPrimaryBrush`). Accessibility would use `AutomationProperties.Name` and `LiveSetting` on a live-region text block. The glyph box width calculation would use `TextBlock.ActualWidth` measurement of rendered frames.

## Design Decisions

**Decision**: The component provides a three-dot pulse fallback when no status words are configured, rather than requiring every consumer to supply a status vocabulary.
**Rationale**: This preserves backward compatibility with existing consumers and avoids the overhead of the phase machine when custom word vocabularies are not in use. The fallback is the documented default behavior and requires no configuration change.
**Approved**: pending

**Decision**: Status words are drawn from a `ShuffleBag` (draw-without-replacement) rather than chosen at random or in fixed order.
**Rationale**: This ensures each word in the vocabulary is shown once before any word repeats, preventing a four-word persona from showing "thinking thinking zipping thinking" and creating a more balanced rotation. The bag is keyed on the semantic content of the word array, not its object identity, so vocabulary changes mid-turn trigger a rebuild without losing the phase state.
**Approved**: pending

**Decision**: `colorful` mode's random hue draw excludes the ~75°–165° band (greens) and is generated at 85% saturation, 62% lightness.
**Rationale**: Excluding green prevents the active thinking line from rendering in a color typically associated with "done" or "success". The vivid colors are bright enough to distinguish from the grey settled line while remaining readable on typical dark chat backgrounds.
**Approved**: pending

**Decision**: The done/settled line always uses `.thinkingDoneText` and ignores `colorful` and `tint`.
**Rationale**: This creates a visual distinction between the active (possibly vivid/tinted) thinking line and the final settled line, signaling to the user that the turn has completed.
**Approved**: pending

**Decision**: Once the first turn begins, the idle phrase is replaced permanently and never re-shown even if a subsequent turn ends.
**Rationale**: This prevents the idle state from flickering back during rapid turn transitions.
**Approved**: pending

**Decision**: In platform representations where the glyph is a separate visual element (AppKit/macOS), the box containing the glyph has a fixed width that does not change as the animation cycles.
**Rationale**: This prevents the word text from shifting left and right as braille characters of varying widths are displayed. The box width accommodates the widest possible glyph (measured at render time) and centers the glyph within it.
**Approved**: pending

**Decision**: The three-dot rendering path (when no words are configured) does not instantiate or run the phase machine.
**Rationale**: It is a pure visual animation driven by `isTyping`/`status`, keeping memory and CPU overhead minimal for consumers who do not use status vocabularies.
**Approved**: pending

**Decision**: Accessibility announcements are posted only when the phase changes (entering thinking, settling, utterance set), not on every frame or word rotation.
**Rationale**: This provides necessary feedback without overwhelming screen readers with constant updates.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [locale-aware-formatting](agenticdevelopercookbook://compliance/internationalization#locale-aware-formatting) | failed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | partial | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

These rest on: the `aria-live="polite"` region in `TypingIndicator.tsx`, updated only on phase/utterance changes (semantic-markup: passed); the absence of any reduced-motion check around the dot-pulse timers and the phase-driven glyph timer in all three sources, and around web's colorful hue cycle (reduced-motion: failed); the hardcoded `"…"`, `"for"`, and `"s"` strings and the fixed `"for {n}s"` elapsed-time template in `TypingIndicator.tsx`, `ThinkingIndicatorView.swift`, and `MobileThinkingIndicatorView.swift` (string-externalization, no-hardcoded-strings, locale-aware-formatting: failed); the tail-truncating text layout on both web and AppKit/UIKit, which tolerates overflow without crashing but is not verified against a 200% expansion target (text-expansion-tolerance: partial); the semantic-palette caption font and the randomly generated `colorful` hue, neither of which is checked against Dynamic Type or the active theme's contrast at render time (dynamic-type-support, contrast-ratio: partial); the fixed glyph-then-word layout order, which none of the three sources exercises or adapts for RTL locales (rtl-layout-support: partial); and Swift's `String`/`NSAttributedString` plus JavaScript's native Unicode string handling, both full-Unicode-capable (unicode-support: passed); the native views delegate the phase state machine to a shared `ThinkingPhase.Machine` and word selection to `ShuffleBag`, but `TypingIndicator.tsx` implements the entire phase state machine — timers, word-bag draws, elapsed-time calculation — inline inside the `ThinkingStatus` component itself (separation-of-concerns: partial), while `TypingIndicator.test.tsx`, `ThinkingIndicatorViewTests.swift`, and `MobileThinkingIndicatorViewTests.swift` all meaningfully exercise this component's behavior (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; resolved the announce-on-word-rotation contradiction and the utterance-vs-settled-line conflict; deduplicated the empty-word-bag and empty-frame-array restatements; replaced the "Not applicable" Compliance and Localization claims with grounded content; documented colorful mode's contrast limitation; corrected the web source path and non-existent SwiftUI/Compose/WinUI 3 API names in Platform Notes; reformatted Design Decisions to Decision/Rationale/Approved; split the Configuration table by platform; added `related` and `references` entries; added test vectors for utterance-over-done, tint, frame/word intervals, word-bag rebuild suppression, theme-palette fallback, and idle-phrase-without-words. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Scoped utterance-survives-turn-end MUSTs and colorful 1s-cycle MUST to web; documented actual macOS/iOS divergence (utterance drop, single-draw hue, dots never hidden) in reqs/states/vectors (ti-001/ti-010/ti-017). Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
