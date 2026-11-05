---
id: 7f84a93a-013e-452f-a963-7ffb4808dd5c
title: TextBubble
domain: adhsdk://recipes/text-bubble
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A decorative traveling-lens text effect: a lens sweeps the string, scaling/blurring the glyphs under it — plain, accessible text when inactive."
platforms:
  - typescript
  - web
tags:
  - component
  - animation
  - text
  - decorative
  - ui
depends-on: []
related: []
references:
  - https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/color-mix
  - https://developer.mozilla.org/en-US/docs/Web/API/ResizeObserver
  - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions/Unicode_Property_Escapes
  - https://www.w3.org/TR/css-values-4/#invalid-at-computed-value-time
approved-by: ''
approved-date: ''
---

# TextBubble

## Overview

`TextBubble` (`@adh-sdk/ui`) renders a string and runs a purely **cosmetic**
traveling-"distortion lens" over it: a soft lens glides along the text in reading
order, and each glyph under the lens is magnified, faintly blurred, and
colour-shifted from `colorFrom` toward `colorTo`. When the lens reaches the end
it restarts at the beginning (a forward loop), optionally parking for `pauseMs`
between sweeps. Ported from the distortion bubble on mikefullerton.com; used by
the concept graph's founder note.

The effect is decoration only — the real text content stays intact and legible:

- The element renders `text` as plain content first (crawlable, accessible), and
  the lens only splits it into per-glyph spans **while `active`**.
- While animating, an off-screen copy of the full string is kept for assistive
  tech, and the visible per-glyph copy is marked `aria-hidden`.
- On cleanup (or `active === false`) the original plain text is restored.

Two symbols ship from `@adh-sdk/ui/components/text-bubble`:

- `TextBubble` — the component: `<TextBubble text as className style {...options} />`.
- `useTextBubble(options)` — the underlying hook, returning a ref to attach to any
  real DOM element whose text the lens should ride over.

## Behavioral Requirements

- **render-plain-text**: When `active` is false, the component MUST render `text` as ordinary, selectable text content in the host element.
- **decorative-when-inactive**: When `active` is false, the component MUST leave the text un-split and un-animated (plain).
- **animate-lens-when-active**: When `active` is true, the component MUST run a lens that sweeps the glyphs in reading order and restarts from the beginning (a forward loop).
- **scale-and-blur-under-lens**: The component MUST magnify (up to `1 + maxScale`) and blur (up to `maxBlur`) each glyph in proportion to its nearness to the lens centre, and MUST leave glyphs outside `radius` untouched.
- **color-shift-under-lens**: The component MUST shift each in-lens glyph's colour from `colorFrom` toward `colorTo` in proportion to its nearness to the lens centre.
- **preserve-accessible-text**: While animating, the component MUST keep the full string available to assistive technology and MUST mark the visible per-glyph copy `aria-hidden`.
- **restore-on-cleanup**: On unmount, on `active` becoming false, or on a `resetKey` change, the component MUST restore the element's original plain text.
- **follow-text-direction**: The lens MUST travel left-to-right for `ltr` elements and right-to-left for `rtl` elements, top line to bottom line.
- **skip-cursive-scripts**: For text containing cursive-joining scripts — the Unicode `Script=` values `Arabic`, `Syriac`, `Mongolian`, `Nko`, `Mandaic`, `Adlam` (matched by `\p{Script=Arabic}|\p{Script=Syriac}|\p{Script=Mongolian}|\p{Script=Nko}|\p{Script=Mandaic}|\p{Script=Adlam}`) — the component MUST leave the text rendered normally and MUST NOT split it into per-character spans.
- **not-break-words-at-wrap**: The component MUST only allow line breaks between words (never mid-word) when it splits the visible copy into glyphs.
- **remeasure-on-resize**: The component MUST re-measure glyph positions and re-read direction when the host element rewraps on resize.
- **noop-on-empty-text**: When `active` is true and `text` is empty or whitespace-only, the component MUST NOT build spans or animate.

## Appearance

A lens (influence radius `radius`, default 44px) travels the string; glyphs near
its centre bulge and soften:

```
The founder note text under the traveling lens
              ~~~( O )~~~
                  ^ glyphs here: scale↑, blur↑, color colorFrom→colorTo
   glyphs outside the radius: plain, untouched
```

- Nearness `t = smoothstep(1 − dist/radius)` drives all three effects together:
  `transform: scale(1 + t·maxScale)`, `filter: blur(t·maxBlur)` (dropped below
  ~0.03px), `color: color-mix(in oklab, colorFrom, colorTo t%)`.
- Only glyphs currently under the lens get `will-change` promoted; it is dropped
  as each glyph leaves the lens, so at most a handful are ever composited.
- Defaults are subtle by design: `maxScale 0.18`, `maxBlur 0.4px`, `radius 44px`,
  `msPerChar 48`, `minDuration 4500ms`, `pauseMs 0` (continuous loop). Colours
  default to `currentColor` on both ends (no colour shift unless overridden).
- No raw hex, no `!important`; colours come from the caller / `currentColor`.

## States

| State | Behavior |
|---|---|
| Inactive (`active === false`) | plain, un-split text; no animation |
| Active — idle hold | during the leading/`pauseMs` window each cycle, glyphs are cleared to plain |
| Active — sweeping | lens glides along glyph centres; in-lens glyphs scale/blur/shift |
| Loop restart | at the end of a sweep the lens returns to the start (after `pauseMs`) |
| Cursive script text | left rendered normally; effect disabled for that string |
| Empty / whitespace-only text | no spans built; nothing animates |
| Cleanup / `resetKey` change | original plain text restored; element remounted on `resetKey` |

## Accessibility

- The text content is real and remains available to assistive technology: while
  animating, an off-screen (visually clipped) span carries the full string, and
  the visible per-glyph copy is `aria-hidden`, so screen readers read the whole
  phrase, not a stream of single letters.
- When inactive the element is simply plain text — fully selectable and crawlable.
- The effect is decorative and never conveys information; disabling it (via
  `active={false}`) removes all motion while leaving the message intact. The
  component does not itself detect `prefers-reduced-motion`; hosts MAY gate
  `active` on it (see **Design Decisions**).
- Cursive-joining scripts are deliberately left un-split so their letter shaping
  (which depends on joining) is not broken.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-plain-text + decorative-when-inactive | `active={false}` | host `textContent` equals `text`; no glyph spans |
| T2 | animate-lens-when-active | `active={true}`, wait a frame | host contains per-glyph `<span>`s with inline `transform` on some |
| T3 | scale-and-blur-under-lens (Playwright) | active, sample styles over frames | at least one glyph shows `scale(>1)` and a `blur()` filter near the lens |
| T4 | color-shift-under-lens | `colorFrom` ≠ `colorTo`, active | an in-lens glyph carries an inline `color: color-mix(...)` |
| T5 | preserve-accessible-text | active | an off-screen span holds the full string; the visible copy is `aria-hidden="true"` |
| T6 | restore-on-cleanup | active → `active={false}` (or unmount) | host `textContent` equals original `text`; no spans/inline transforms |
| T7 | skip-cursive-scripts | `text` = Arabic string, active | text unchanged; no per-character spans created |
| T8 | not-break-words-at-wrap | multi-word text, active | each word wrapped in an `inline-block; white-space:nowrap` span |
| T9 | follow-text-direction | `dir="rtl"` host, active | reading order sorts right-to-left within each line |
| T10 | remeasure-on-resize (Playwright) | active, resize host to rewrap | glyph centres re-measured; lens stays aligned |
| T11 | noop-on-empty-text | empty/whitespace `text`, active | no spans built; nothing animates |
| T12 | animate-lens-when-active | active, `pauseMs=500` | for the first ~500ms of each cycle every glyph is cleared (plain) before the sweep begins |
| T13 | animate-lens-when-active | active, 3-character `text`, default `minDuration` (4500ms) | the sweep across the string takes at least 4500ms (the duration floor applies) |

## Edge Cases

- **Empty or whitespace-only text**: the hook bails early (nothing to split), so
  no spans and no animation (**noop-on-empty-text**).
- **Cursive-joining scripts**: detected via the Unicode `Script=` property set
  `Arabic`, `Syriac`, `Mongolian`, `Nko`, `Mandaic`, `Adlam`
  (`\p{Script=Arabic}|\p{Script=Syriac}|\p{Script=Mongolian}|\p{Script=Nko}|\p{Script=Mandaic}|\p{Script=Adlam}`);
  the string is left rendered normally so joining/shaping isn't broken
  (**skip-cursive-scripts**). Non-joining RTL scripts (e.g. Hebrew) still
  animate, right-to-left.
- **`resetKey` change**: `TextBubble` keys the element by `resetKey` (defaulting to
  `text`) so a text/version change remounts a fresh node instead of reconciling new
  text against imperatively-created spans (which would leave stale split text).
- **Host still animating in**: glyphs are measured in layout space
  (`offsetLeft/offsetTop`), which ignores an ancestor entrance/scale transform, so
  the lens doesn't desync from the glyphs during an entrance animation.
- **Word wrapping**: whole words are wrapped in `inline-block; nowrap` spans and the
  inter-word whitespace stays plain, so breaks only ever happen between words.
- **Compositor pressure**: `will-change` is set only on glyphs currently in the lens
  and cleared as they leave, so only a handful of glyphs are promoted at once.
- **`pauseMs > 0`**: the lens parks (text plain) for `pauseMs` before each sweep;
  the first park is the start delay, later parks are the between-loop pause.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `text` | `string` | — (required) | The text the lens rides over. |
| `active` | `boolean` | — (required) | Run the lens; false keeps the plain, un-split text. |
| `as` | `keyof JSX.IntrinsicElements` | `"p"` | Element to render (must be a real DOM element). |
| `resetKey` | `string \| number` | the `text` | Re-split + re-measure (and remount) when it changes. |
| `colorFrom` | `string` | `"currentColor"` | Glyph colour at the lens edge. |
| `colorTo` | `string` | `"currentColor"` | Glyph colour at the lens centre (equal to `colorFrom` = no shift). |
| `radius` | `number` | `44` | Lens influence radius in px. |
| `maxScale` | `number` | `0.18` | Extra scale at the lens centre (1 → 1+maxScale). |
| `maxBlur` | `number` | `0.4` | Blur in px at the lens centre. |
| `msPerChar` | `number` | `48` | Travel speed: ms the lens spends per glyph. |
| `minDuration` | `number` | `4500` | Floor (ms) so short strings don't whip past. |
| `pauseMs` | `number` | `0` | Idle hold (ms) before each sweep; 0 = continuous loop. |
| `className` / `style` | `string` / `CSSProperties` | — | Passed to the rendered element. |

`useTextBubble<T>(options)` returns a `RefObject<T | null>` to attach to any real
DOM element; `TextBubble` is the ready-made wrapper around it.

## Deep Linking

Not applicable: TextBubble is a decoration-only animation component with no user-facing navigation or state that would warrant deep-linkable URLs.

## Localization

Not applicable: TextBubble applies a visual animation to provided text content. The text itself is the caller's responsibility; the component preserves it and adds no additional strings.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not detected by the component itself; hosts MAY gate `active` off when `prefers-reduced-motion: reduce` is set (see the reduced-motion **Design Decision**). |
| Increase Contrast | Not applicable — glyph colours come from the caller (`colorFrom`/`colorTo`) or default to `currentColor`; the component introduces no colours of its own to adjust. |
| Differentiate Without Color | Not applicable — the colour shift is decorative only and conveys no information that would need a non-colour alternative. |

## Feature Flags

Not applicable: TextBubble is a self-contained UI component with no feature-gating needs. The caller controls behavior via `active`.

## Analytics

Not applicable: TextBubble is a purely cosmetic animation. It emits no events, user interactions, or telemetry.

## Privacy

Not applicable: TextBubble operates entirely on client-side text content and rendering, with no data collection, transmission, or persistence.

## Logging

No logging. `TextBubble` is a purely cosmetic animation; it emits no events or
telemetry.

## Platform Notes

- **React/Web** (source): File `packages/web/packages/ui/src/components/text-bubble.tsx`. Client-side only (`"use client"`), uses `useEffect`/`useRef`, `requestAnimationFrame`, and `ResizeObserver` (guarded for SSR). Color shift via `color-mix(in oklab, …)` — a modern CSS feature; an inline style with an unsupported value is invalid at computed-value time, so older engines fall back to the element's inherited/`currentColor` value instead of applying it. No external dependencies beyond React.
- **SwiftUI**: Build on `TimelineView(.animation)` driving a `Canvas` (or, on iOS 18+/macOS 15+, a custom `TextRenderer`) that draws each glyph with its own scale/blur/colour — `CADisplayLink` plus a `GeometryReader` per character is not idiomatic SwiftUI, and this avoids both. Measure glyph centres from the resolved glyph runs (`Canvas`'s `context.resolve(text:)`, or `TextRenderer`'s layout) rather than a per-character view, and use `displayScale` for DPI-aware radius. Detect cursive-joining scripts with the same Unicode `Script=` set and skip splitting for them (**skip-cursive-scripts**); keep whole words undivided so wrapping only breaks between words (**not-break-words-at-wrap**); expose the full string via `.accessibilityLabel` on the container while the per-glyph drawing stays `.accessibilityHidden(true)` (**preserve-accessible-text**).
- **Compose (Android)**: `graphicsLayer` applies to composables, not to `AnnotatedString` spans, so draw each glyph yourself: measure glyph boxes with `TextLayoutResult.getBoundingBox(index)` and either render one small composable per glyph (each with its own `graphicsLayer` for scale/blur/colour) or draw the glyphs directly with `drawText` in a `Canvas`/`drawBehind`. Use `Animatable`/`withInfiniteAnimationFrameMillis` to drive the lens position. Detect cursive scripts with the same Unicode `Script=` set and skip per-glyph rendering for them (**skip-cursive-scripts**); group glyphs into word units so wrapping only breaks between words (**not-break-words-at-wrap**); keep the full string as the container's `contentDescription` and mark the per-glyph drawing `clearAndSetSemantics {}` so it is hidden from accessibility (**preserve-accessible-text**).
- **AppKit / UIKit**: `NSTextField`/`UITextView` attributed-string splitting can't drive per-glyph transforms; use a custom `NSView`/`UIView` subclass that draws Core Text runs itself, so each glyph can be scaled/blurred/tinted independently. Measure glyph frames from `CTLine`/`CTRun` (`CTLineGetGlyphRuns`, `CTRunGetPositions`), not bounding rects. Use `CADisplayLink` for animation timing. RTL detection: `NSLocale.characterDirection(forLanguage:)` on macOS, `UITextView.textDirection`/`NSParagraphStyle.baseWritingDirection` on iOS. Skip cursive scripts via the same Unicode `Script=` set (**skip-cursive-scripts**); lay out whole words as undividable runs so breaks stay between words (**not-break-words-at-wrap**); back the view with an accessibility element whose label/value is the full string, with the glyph-drawing layer `accessibilityElementsHidden` (**preserve-accessible-text**).
- **WinUI 3**: A `Run` is an `Inline`, not a `UIElement`, so it can't take a `ScaleTransform`, and `BlurEffect` is not a XAML element — instead, render one `TextBlock` per glyph inside a panel, with words grouped into their own sub-panels so a line only wraps between words (**not-break-words-at-wrap**), and animate each `TextBlock`'s `ScaleTransform`/`Foreground` via `Storyboard` + `DoubleAnimation`/`ColorAnimation`. Do the blur with a Composition (`Windows.UI.Composition`) or Win2D effect applied to the glyph's visual, not `BlurEffect`. Use `SizeChanged` on the container to re-measure on layout changes. Skip cursive scripts using the same Unicode `Script=` set (**skip-cursive-scripts**). Expose the full string via `AutomationProperties.Name` on the container and hide the glyph `TextBlock`s from the accessibility tree (**preserve-accessible-text**). For colour mixing in oklab, compute manually or fall back to sRGB `Color.FromArgb` blends.

## Design Decisions

**Decision**: The text renders plain (crawlable, selectable) first and is only imperatively split into per-glyph spans while `active`; an off-screen full-text copy plus `aria-hidden` on the visible spans keeps screen readers reading the whole phrase, and cleanup restores the plain text.
**Rationale**: The effect never carries meaning, so turning it off (or restoring it on cleanup) loses nothing — decorative-first keeps the component accessible by construction rather than by afterthought.
**Approved**: pending

**Decision**: The lens centre interpolates along the polyline of glyph centres (in reading order) instead of moving in raw screen space.
**Rationale**: Following the text lets the lens sweep to the next line at each wrap and stay visually locked to the glyphs regardless of layout.
**Approved**: pending

**Decision**: Glyph positions are measured with `offsetLeft`/`offsetTop` (layout space) rather than `getBoundingClientRect`.
**Rationale**: Layout-space measurement ignores an ancestor entrance/scale transform, so the lens stays aligned while the host is still animating in.
**Approved**: pending

**Decision**: Whole words are wrapped in `inline-block; nowrap` spans, with the inter-word whitespace left as plain text.
**Rationale**: Splitting bare characters would let a line break occur mid-word; wrapping at the word level prevents that while still allowing per-character animation inside each word.
**Approved**: pending

**Decision**: Text containing cursive-joining scripts (see **skip-cursive-scripts**) is left rendered normally rather than split into per-character spans.
**Rationale**: Per-character spans break cursive joining, so scripts that join (Arabic, Syriac, …) would be mis-shaped if split.
**Approved**: pending

**Decision**: Glyphs beyond the (squared) lens radius are skipped without a `sqrt`, and `will-change` is toggled on/off per glyph as it enters/leaves the lens.
**Rationale**: Culling cheaply and promoting only the handful of in-lens glyphs keeps a long string's compositing cost low.
**Approved**: pending

**Decision**: The component does not itself detect `prefers-reduced-motion`; hosts control the effect entirely through the `active` prop, which they MAY gate on that media query.
**Rationale**: The lens is purely decorative and never carries information, so whether to suppress it under reduced motion is a per-host UX choice; keeping the check out of the component avoids duplicating logic an app may already centralize in one place.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on the source: the off-screen full-text span plus `aria-hidden` on the visible copy and the absence of any fixed font-size override on glyph spans pass outright (semantic-markup, dynamic-type-support); `colorFrom`/`colorTo` defaulting to `currentColor` with no contrast check of its own, and no built-in `prefers-reduced-motion` detection beyond the `active` prop hosts may gate, are partial (contrast-ratio, reduced-motion); and `getComputedStyle(host).direction` driving reading order plus the `\p{Script=…}` cursive-script regex pass outright (rtl-layout-support, unicode-support). `separation-of-concerns` passes: the sweep, measurement, and DOM-splitting logic lives entirely in the `useTextBubble` hook, separate from the `TextBubble` presentational component, which only renders `text` and attaches the ref. `unit-test-coverage` is failed: no test file exercises `TextBubble` or `useTextBubble`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Restored on-main 1.0.0 Change History wording ("Initial recipe" not "Initial ingredient"); added missing separation-of-concerns/unit-test-coverage Compliance rows. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirement IDs to subject-only kebab-case; narrow render-plain-text to the inactive state; add noop-on-empty-text (remaps T11) and pauseMs/minDuration test vectors (T12/T13); name the exact cursive-script Unicode set; rewrite Platform Notes for SwiftUI/Compose/AppKit-UIKit/WinUI 3 with correct APIs and per-platform cursive-skip/word-wrap/accessible-text coverage; reformat Design Decisions into Decision/Rationale/Approved form and add a reduced-motion opt-out decision; resolve the Accessibility Options contradiction; rewrite Compliance as canonical linked checks; add references; correct Change History wording and authorship. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | AI-assisted (Claude Haiku 4.5): bump version, update modified date, add all template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy marked not applicable; expand Platform Notes with concrete WinUI/AppKit/UIKit/Compose guidance). |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the decorative traveling-lens effect, its sweep params, and the preserved accessible text. |
