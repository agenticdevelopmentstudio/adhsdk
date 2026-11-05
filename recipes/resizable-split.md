---
id: c21473ee-a075-4800-96db-ff3de0888515
title: "ResizableSplit"
domain: adhsdk://recipes/resizable-split
type: ingredient
version: 2.2.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A vertical two-pane split with a draggable divider (seam or header bar), animated collapse, reveal-to-fit, and optional persisted ratio."
platforms:
  - typescript
  - web
tags:
  - component
  - layout
  - split
  - ui
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# ResizableSplit

## Overview

A vertical (top/bottom) split with a draggable divider and a collapse toggle for the bottom pane, in `@adh-sdk/ui`. It lays out two stacked panes — PEERS in the column; the bottom never overlays the top — whose split ratio the user drags; the bottom pane can be collapsed/expanded via a chevron on the divider, with an animated boundary. It offers controlled collapse plus an optional persisted ratio, and is otherwise self-contained.

The divider has two forms:

- **seam** (default): a 1px connected boundary with a visible centered grip pill and a generous 24px transparent grab band; the collapse chevron sits at the right edge.
- **header bar** (`header`/`headerActions` set): the divider IS the bottom pane's header — a real strip with the pane's title left, optional actions and the disclosure chevron at the far right. The whole bar is a drag target, and the bar stays visible while the pane is hidden (it is the collapsed remnant).

It adapts the hand-rolled divider in `status-backend`'s `Dashboard.tsx` (ratio state, `row-resize`, clamp, localStorage persistence) into a reusable, token-styled component. It is used by `ListWithDetailsPane` (table over details).

## Behavioral Requirements

- **drag-captures-pointer**: On pointer-down on the divider, the component MUST capture the pointer via `setPointerCapture()`.
- **drag-maps-to-ratio**: On pointer-move while captured, the component MUST map `clientY` within the container bounding rect to a top-pane ratio (`(clientY - rect.top) / rect.height`).
- **drag-clamps-ratio**: The component MUST clamp the ratio to `[minRatio, maxRatio]`.
- **drag-releases-on-pointerup**: On pointer-up, the component MUST release the pointer capture via `releasePointerCapture()`.
- **drag-cursor-and-no-select**: While dragging, the component MUST show `cursor: row-resize`. The header-bar variant additionally suppresses text selection via `user-select: none` (Tailwind `select-none`); both variants set `touch-action: none` on the drag surface to prevent touch-scroll interception during a drag.
- **persist-ratio-when-keyed**: When `storageKey` is set, the component MUST write the ratio to `localStorage[storageKey]` on drag release and MUST restore it on mount, guarded for SSR contexts and parse errors.
- **collapse-toggles-bottom**: Activating the divider chevron MUST toggle `collapsed`; collapsed MUST give the bottom pane height 0 via `flex-basis`, let the top fill, and flip the chevron icon.
- **collapse-remembers-ratio**: The component MUST remember the last drag ratio while collapsed and restore it on expand.
- **collapse-controlled-or-internal**: The component MUST be controlled whenever `collapsed !== undefined` — the visible state always reflects that prop; otherwise the visible state MUST come from internal state. Independently, `onCollapsedChange` MUST fire whenever it is provided, in both controlled and uncontrolled configurations.
- **chevron-toggle-suppressed-by-drag**: A pointer-down/move/up sequence that moves more than 3px before release — even one that starts and ends on the chevron — MUST NOT trigger the collapse toggle; only a press-release with no motion past that threshold MUST toggle.
- **keyboard-nudges-ratio**: When the divider handle is focused, `ArrowUp` MUST decrease the top-pane ratio by 0.03 (3%) and `ArrowDown` MUST increase it by 0.03, each clamped to `[minRatio, maxRatio]`; each nudge MUST persist immediately (not deferred to keyup).
- **keyboard-toggles-collapse**: Enter/Space on the chevron button MUST toggle collapse (handled via native button behavior).
- **header-bar-variant**: When `header` (or `headerActions`) is set, the divider MUST render as a header bar: `header` content left-aligned in a truncated flex column, `headerActions` then the disclosure chevron at the far right.
- **header-bar-always-visible**: The header bar MUST stay visible while the bottom pane is collapsed — only the bar remains (the bar has no `inert` wrapper).
- **header-bar-drag-anywhere**: Pointer-down anywhere on the header bar EXCEPT on its interactive controls (buttons, links, inputs, selects, textareas, or `[data-no-drag]` elements) MUST start a resize drag; while expanded the bar MUST show `cursor: row-resize`. While collapsed, pointer-down on the bar (other than the chevron) MUST be a no-op — no drag starts and the cursor is `default`; only the chevron reopens the pane.
- **toggle-animates**: Collapse/expand MUST animate the shared boundary for 0.3s (ease-in-out) via `flex-basis` transition. It MUST NOT animate when the app-level appearance setting `html[data-reduce-motion="on"]` is active. Drags are direct manipulation and MUST never animate.
- **expand-to-content**: With `expandToContent` (default on for the header-bar variant), expanding from collapsed MUST open the bottom pane exactly far enough to show ALL its content (via `scrollHeight`), clamped to `[minRatio, maxRatio]`; when the container/content can't be measured it MUST fall back to the last drag ratio.
- **bottom-stays-mounted**: The bottom pane MUST stay mounted while collapsed (height 0 via flex-basis, clipped by `overflow-hidden`, marked `inert`) so its state survives a hide/show cycle and reveal-to-fit can measure the hidden content.

## Appearance

```
seam (default):
┌───────────────────────────────┐
│  top                          │  flex: 0 1 ratio%
├────────── ▬▬ ──────────── ⌄ ──┤  1px seam + centered grip pill + 24px grab band
│  bottom                       │  flex: 1
└───────────────────────────────┘
header bar:
┌───────────────────────────────┐
│  top                          │  flex: 0 1 ratio%
├ Details ────────── [actions] ⌄┤  the bar IS the divider (drag anywhere on it)
│  bottom                       │  flex: 1
└───────────────────────────────┘
collapsed (either form):
┌───────────────────────────────┐
│  top (fills)                  │
├ Details ─────────────────── ⌃ ┤  only the divider/bar remains; bottom stays
└───────────────────────────────┘  mounted at height 0 (clipped, inert)
```

- **Container**: `flex flex-col min-h-0`. Panes: `min-h-0 overflow-auto` (bottom wrapped in `overflow-hidden` so the collapse animation never exposes a scrollbar).
- **Seam**: 1px `bg-apt-border`, hover `bg-apt-border-strong`; centered grip pill (`bg-apt-border-strong`, `rounded-full`, 10px × 4px); invisible 24px grab band centered on seam carries the drag; `cursor: row-resize`; chevron right-aligned, `text-apt-text-muted` on idle, `text-apt-text` on hover.
- **Header bar**: `border-y border-apt-border bg-apt-surface`, mono muted title left (`font-mono text-[11px] tracking-wide text-apt-text-muted`), actions + chevron right; `cursor: row-resize` across the bar (default cursor on its controls and while collapsed).
- **No raw hex**; no `!important`.

## States

| State | Appearance change |
|---|---|
| Idle | divider `bg-apt-border` |
| Divider hover | seam `bg-apt-border-strong`; grip pill opacity 100% |
| Dragging | `cursor: row-resize`; touch-action: none blocks touch-scroll on both variants; text selection also suppressed via `select-none` on the header bar; no animation (direct manipulation) |
| Handle focused | divider receives `tabIndex=0`; browser focus ring |
| Expanded | bottom pane visible at the current ratio; chevron icon `ChevronDown` |
| Collapsed | bottom pane height 0 (still mounted, `inert`); top fills; chevron icon `ChevronUp`; header bar (if any) stays visible |
| Toggling | boundary animates 0.3s ease-in-out via `flex-basis` transition; skipped under `html[data-reduce-motion="on"]` |

## Accessibility

- **Divider handle**: `role="separator"`, `aria-orientation="horizontal"`, `aria-valuenow`/`aria-valuemin`/`aria-valuemax` reflecting the ratio as percentages, `tabIndex=0`.
- **Collapse button**: a real native `<button>` with `aria-expanded` (reflects `!isCollapsed`) and `aria-label` from `bottomLabel` (default "Details").
- **Keyboard support**: ↑/↓ on the focused divider nudges the ratio; Enter/Space on the button toggles collapse (native button behavior).
- **Touch targets**: The chevron glyph is 14px (header bar) or 12px (seam), but the touch/click target is larger: on the seam, a full-width, 24px-tall transparent grab band (`h-6`, `inset-x-0`) meets the WCAG 2.5.8 minimum of 24×24 CSS px; on the header bar, the whole full-width row — not just the glyph — is the drag/click surface.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | drag-clamps-ratio | drag past the minimum (0%) | ratio clamps at `minRatio` (default 0.2) |
| T2 | drag-clamps-ratio | drag past the maximum (100%) | ratio clamps at `maxRatio` (default 0.85) |
| T3 | collapse-toggles-bottom | click the chevron | bottom hidden (height 0); `aria-expanded="false"` |
| T4 | collapse-toggles-bottom | click the chevron again | bottom visible (height restored); `aria-expanded="true"` |
| T5 | persist-ratio-when-keyed | set `storageKey`, drag to 0.5, unmount, remount | ratio restores to 0.5 from `localStorage` |
| T6 | keyboard-nudges-ratio | focus divider, press ↑ | ratio nudges down by 0.03, clamped |
| T7 | keyboard-nudges-ratio | focus divider, press ↓ | ratio nudges up by 0.03, clamped |
| T8 | drag-captures-pointer | pointer-down on divider, move mouse, pointer-up | split ratio follows the pointer throughout; motion past 3px is tracked internally |
| T9 | keyboard-toggles-collapse | focus chevron button, press Enter | collapse toggles |
| T10 | keyboard-toggles-collapse | focus chevron button, press Space | collapse toggles |
| T11 | header-bar-variant | render with `header="Details"` | the separator renders as a bar containing the title; chevron is inside, far right |
| T12 | header-bar-always-visible | collapse the header-bar variant | the bar (title + chevron `⌃`) renders; bottom is `inert`, height 0 |
| T13 | header-bar-drag-anywhere | pointer-down on `headerActions` button element | no drag starts; the button's native click fires |
| T14 | expand-to-content | collapsed; content `scrollHeight` 300px in 1000px container (28px bar); expand | top pane ratio ≈ 0.672 = 1 − (300 + 28) / 1000 |
| T15 | bottom-stays-mounted | collapse the component | bottom content remains in the DOM inside an `overflow-hidden` wrapper with `inert` attribute |
| T16 | toggle-animates | set `html[data-reduce-motion="on"]`, toggle collapse | boundary animates with zero duration (no transition style applied) |
| T17 | toggle-animates | toggle collapse with `html[data-reduce-motion]` unset | boundary animates 0.3s ease-in-out |
| T18 | drag-cursor-and-no-select | drag the divider | cursor shows `row-resize`; `touch-action: "none"` blocks touch-scroll; the header-bar variant additionally suppresses text selection via `user-select: none` |
| T19 | chevron-toggle-suppressed-by-drag | press on the chevron, move 5px, release | no toggle occurs (collapse state unchanged) |
| T20 | bottom-stays-mounted | mount bottom with internal state (e.g. an input's typed value), collapse, then expand | the input's value is unchanged (the bottom pane was never unmounted) |
| T21 | drag-releases-on-pointerup | pointer-down, drag, pointer-up | `releasePointerCapture()` is called with the same `pointerId` that was captured |
| T22 | drag-maps-to-ratio | container top at `clientY=0`, height 1000px; pointer-move to `clientY=400` | ratio updates to 0.4 |
| T23 | collapse-remembers-ratio | drag to ratio 0.5, collapse, then expand (seam, `expandToContent` off) | ratio restores to 0.5, not the default |

## Edge Cases

- **localStorage access failure (SSR, sandboxed iframes, disabled storage)**: Wrapped in try-catch; on any error the component silently falls back to `defaultRatio` or the in-memory ratio.
- **Restored value outside bounds**: A persisted `localStorage` value outside `[minRatio, maxRatio]` (e.g. after the bounds changed since it was saved) is clamped to the current bounds on restore, the same as any other ratio update.
- **Zero-height container or content**: `revealRatioForContent()` guards against `containerH <= 0` or `contentH <= 0` by returning the fallback ratio; prevents NaN.
- **Concurrent collapse requests**: When controlled via `onCollapsedChange`, rapid toggles are handled by React state; uncontrolled (internal) state updates synchronously per toggle, with no queue.
- **Drag-over-chevron suppression**: A fresh pointer-down — including one that lands on the chevron — always resets the drag-passed-over-target state, so a short drag over the chevron does not also trigger its click. See **chevron-toggle-suppressed-by-drag**.
- **Animation timer cleanup**: The animation timer is cleared on unmount to prevent dangling timeouts.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `top` | `React.ReactNode` | — | Top pane content (required). |
| `bottom` | `React.ReactNode` | — | Bottom pane content (required). |
| `defaultRatio` | `number` | `0.6` | Initial top fraction (0..1), clamped to `[minRatio, maxRatio]`. |
| `minRatio` | `number` | `0.2` | Lower clamp bound (0..1). |
| `maxRatio` | `number` | `0.85` | Upper clamp bound (0..1). |
| `storageKey` | `string` | — | When set, persist the ratio in `localStorage[storageKey]` on drag release; restore on mount. |
| `collapsed` | `boolean` | — | Controlled collapse state of the bottom pane; the component is controlled whenever this prop is defined (`collapsed !== undefined`). When omitted, the visible state comes from internal state. |
| `onCollapsedChange` | `(collapsed: boolean) => void` | — | Called whenever collapse state changes (via chevron click), in both controlled and uncontrolled configurations. If provided without a controlled `collapsed` prop, the caller must feed the value back for the visible state to update. |
| `bottomLabel` | `string` | `"Details"` | Accessibility label for the chevron button (`aria-label`). |
| `header` | `React.ReactNode` | — | When set, render the divider as the bottom pane's header bar with this left-aligned content; triggers header-bar variant. |
| `headerActions` | `React.ReactNode` | — | Right-aligned interactive controls on the header bar, before the chevron; never drag targets. Setting this also triggers header-bar variant. |
| `expandToContent` | `boolean` | `true` (header bar), `false` (seam) | On expand-from-collapsed, size the bottom pane to show all its content (clamped to `[minRatio, maxRatio]`). |
| `className` | `string` | — | Additional CSS classes applied to the container. |

Collapse state is internal whenever `onCollapsedChange` is not provided. The ratio is always internal, seeded from `storageKey` or `defaultRatio`, and persisted on drag release.

## Deep Linking

Not applicable: ResizableSplit is a layout primitive, not a navigation target or content container that would benefit from deep linking.

## Localization

ResizableSplit renders no user-facing text of its own — `header`, `top`, and `bottom` content come from the consumer, and the chevron is a pure icon — but `bottomLabel` defaults to the hardcoded English string `"Details"` when the consumer omits it. Consumers with localized UIs MUST pass a localized `bottomLabel`, or source the default from their own string table; the component does not localize it itself.

## Accessibility Options

- **Reduce Motion**: The component respects `html[data-reduce-motion="on"]` set by the app-level appearance setting. When active, collapse/expand animations are skipped (no transition style applied). This is distinct from the OS `prefers-reduced-motion` media query.

## Feature Flags

Not applicable: ResizableSplit is a foundational UI primitive with no feature-gated behavior.

## Analytics

Not applicable: ResizableSplit emits no analytics events; it is a presentational layout component.

## Privacy

ResizableSplit collects no personal data. `localStorage` persistence of the ratio is scoped to the browser origin (not the page) and never transmitted; consumers using `storageKey` SHOULD namespace it (e.g. prefix with a route or feature name) to avoid collisions with other components writing to the same origin's `localStorage`.

## Logging

No logging. ResizableSplit is a presentational layout primitive; it emits no structured log events.

## Platform Notes

- **React/Web** (TypeScript, source platform): Component in `packages/web/packages/ui/src/components/resizable-split.tsx`. Uses Lucide React icons (`ChevronDown`, `ChevronUp`). Flex layout with `flex-basis` for ratio and collapse animation. Pointer events for drag; keyboard handlers for nudge and toggle. `localStorage` for optional persistence, guarded for SSR. The seam variant uses an invisible 24px grab band centered on a 1px seam; the header-bar variant is always-visible and full-width draggable. Demo in `ui-showcase`.
- **SwiftUI**: Use a `VStack` with `Divider` or a custom separator shape; bind the top pane to a `@State` proportion and animate via `.animation()` gated on an app-level reduce-motion flag (mirroring the web version's `data-reduce-motion` attribute), not `@Environment(\.accessibilityReduceMotion)` directly — apps whose own accessibility settings already derive that flag from the OS setting would otherwise double-gate. Drag gesture on the divider maps `translation.height` to the proportion; keyboard support via `.onKeyPress()` for ↑/↓ nudge and chevron button. Persist via `UserDefaults` on drag release. Header-bar variant renders the divider as the bottom pane's header with drag anywhere (except buttons). Seam variant uses a thin opacity-variable separator with a pill-shaped accent.
- **Kotlin/Compose**: Use `Column` with `weight()` for ratio; `Draggable` modifier on the divider for drag input, map `delta` to proportion. Animate via `.animateTo()` for collapse/expand, respecting the platform's animator-duration-scale setting (`Settings.Global.ANIMATOR_DURATION_SCALE`) or an app-level reduce-motion flag mirroring the web version's `data-reduce-motion` attribute — not `LocalAccessibilityManager.current.isScreenReaderEnabled`, which reflects screen-reader use, not a reduced-motion preference. Persist via `DataStore` on drag release. Header-bar variant: compose the divider as a full-width `Row` above the bottom pane. Seam variant: thin `Divider()` with a centered pill accent.
- **AppKit / UIKit**: On AppKit, use `NSSplitView` — the native vertical/horizontal resizable split container with a divider, delegate-based min/max constraints, and autosave-position support (mirrors `storageKey` persistence). UIKit has no equivalent built-in control; compose a `UIStackView` with a custom pan-gesture-driven divider view, mapping `translation` to the ratio and clamping to `[minRatio, maxRatio]`; persist via `UserDefaults`. Collapse maps to a zero-height divider constraint; the header-bar variant renders the divider view's content with the title left, actions and chevron far right.
- **WinUI 3**: Use a `Grid` with two `RowDefinition`s (top/bottom panes) and the CommunityToolkit `GridSplitter` between them for the draggable divider — `GridSplitter` handles pointer capture and a resize cursor natively. Bind `RowDefinition.Height` to the ratio; drag updates it live. Model collapse as setting the bottom `RowDefinition.Height` to `0`, animated via a `Storyboard`/`ThemeTransition` on the `Height` property (gated on the app's reduce-motion flag). For the header-bar variant, render the bottom pane's header content — title left, actions and chevron far right — spanning the full row width, layered above or templated into the `GridSplitter`. Persist via `ApplicationData.Current.LocalSettings` on drag release.

## Design Decisions

**Decision**: Generalize the hand-rolled divider from `status-backend`'s `Dashboard.tsx` (ratio state, `row-resize`, clamp, `localStorage` persistence) into a reusable, token-styled primitive.
**Rationale**: Avoids re-rolling the same divider logic per site; centralizes it as a token-styled component other consumers (e.g. `ListWithDetailsPane`) can reuse.
**Approved**: pending

**Decision**: Keep the ratio internal, seeded from `storageKey` or `defaultRatio`; make persistence opt-in via `storageKey`.
**Rationale**: Keeps the component simple and avoids prop drilling while still supporting stateful, persisted use cases.
**Approved**: pending

**Decision**: Keep the bottom pane mounted while collapsed (`inert`, `height: 0` via `flex-basis`) instead of unmounting it.
**Rationale**: Preserves the bottom pane's internal state across a toggle cycle, enables reveal-to-fit measurement of hidden content, and keeps both endpoints of the `flex-basis` transition always defined.
**Approved**: pending

**Decision**: Offer two divider forms — a minimal 1px seam and an always-visible header bar.
**Rationale**: The seam works best as a divider between independent panes; the header bar anchors the bottom pane's identity and stays visible while collapsed, making clear what the chevron reveals.
**Approved**: pending

**Decision**: Default `expandToContent` to `true` for the header-bar variant and `false` for the seam.
**Rationale**: The header bar already occupies fixed space, so the pane's content size is the more useful secondary signal; the seam has no such anchor, so a user's last manual ratio is the best guess at their preference.
**Approved**: pending

**Decision**: Gate the collapse/expand animation on the app-level `html[data-reduce-motion="on"]` attribute, not the OS `prefers-reduced-motion` media query directly.
**Rationale**: Apps that import the toolkit themes' `accessibility.css` already derive that attribute from the media query; reading the media query directly here too would double-gate.
**Approved**: pending

**Decision**: Suppress the chevron's click when a drag passes over it (reset per pointer-down, tripped after 3px of motion).
**Rationale**: Without this, a small accidental drag while aiming for the chevron would also toggle collapse — the "dancing divider" problem.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | failed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Keyboard, ARIA, and reduced-motion statuses rest on the `role="separator"`/native-`<button>` markup and the `document.documentElement.dataset.reduceMotion` check in `resizable-split.tsx`; touch-target is partial because only the seam's 24px grab band is confirmed at the WCAG 2.5.8 minimum, while the header-bar row's height isn't; dynamic-type and both internationalization checks fail because the header-bar title uses a fixed `text-[11px]` size and `bottomLabel` defaults to the hardcoded English string `"Details"`. The reveal-ratio math is extracted into the standalone, exported `revealRatioForContent`, but the drag handling and the `window.localStorage` persistence (`persist`/the load effect) are direct data access inline in the component rather than pulled into a separate hook (separation-of-concerns partial); `resizableSplit.test.tsx` directly exercises collapse toggling, the storageKey round-trip, the separator's clamped aria values, and `revealRatioForContent`'s own edge cases (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 2.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 2.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: shorten summary; correct drag-cursor-and-no-select, collapse-controlled-or-internal, and keyboard-nudges-ratio to match source; add chevron-toggle-suppressed-by-drag requirement and vector; add missing test vectors for drag-releases-on-pointerup, drag-maps-to-ratio, collapse-remembers-ratio, and bottom-stays-mounted; add restored-value-clamped edge case; remove internal identifier names from requirements and edge cases; rewrite AppKit/UIKit, WinUI 3, SwiftUI, and Compose platform notes for correct APIs and consistent reduce-motion gating; rename touch-target bullet and correct target-size claim; correct Localization and Privacy sections; reformat Design Decisions to Decision/Rationale/Approved; replace Compliance prose with a checks table. |
| 2.1.0 | 2026-09-22 | Mike Fullerton | Correct domain URI to agenticdevelopercookbook://recipes/resizable-split; add missing template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy) marked not applicable; expand conformance test vectors to 18 (separate keyboard up/down, add drag-over-chevron, reduce-motion with and without); document edge cases including animation timer cleanup; clarify platform notes with specific control names and patterns for SwiftUI, Compose, WinUI 3; strengthen requirements with implementation details (latest.current, scrollHeight, moved flag, flex-basis). |
| 2.0.0 | 2026-07-10 | Mike Fullerton | Header-bar divider variant (always-visible details header, drag anywhere, chevron far right); animated collapse gated on app-level reduce-motion; expand-to-content reveal; bottom pane stays mounted (inert) while collapsed; documented the shipped grip-pill + 24px grab-band seam. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec. |
