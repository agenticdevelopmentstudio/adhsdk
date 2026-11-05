---
id: c99e2822-f5a9-4e84-8740-9341880bb82a
title: Disclosure
domain: adhsdk://recipes/disclosure
type: ingredient
version: 1.3.1
status: review
language: en
created: '2026-06-26'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A self-contained collapsible section — a header row with a rotating chevron toggles its children; controlled or uncontrolled; optional header actions.
platforms:
- typescript
- web
tags:
- disclosure
- collapsible
- expander
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Disclosure

## Overview

**Disclosure** is a self-contained collapsible section: a clickable header row
with a rotating chevron that shows or hides its children, themed with the family
`apt-*` tokens. It is uncontrolled by default (`defaultOpen`) but accepts
`open`/`onOpenChange` to be driven by a caller. The header can carry trailing
`actions` that do not toggle the section — useful for per-section buttons (e.g.
a section's own danger-zone action).

## Behavioral Requirements

- **toggle-on-header-click**: Clicking the header toggle MUST flip the visibility of the children.
- **support-uncontrolled**: With `defaultOpen` and no `open` prop, the component MUST manage its own open state.
- **support-controlled**: When `open` is provided, the component MUST reflect that prop and report intent via `onOpenChange`, without mutating internal state.
- **rotate-chevron**: The leading chevron MUST rotate 90° when open and return when closed.
- **actions-exempt-from-toggle**: Interacting with the header `actions` slot MUST NOT toggle the disclosure.
- **mount-children-only-when-open**: Children MUST be mounted only when open (and unmounted when closed), not merely visually hidden.
- **expose-expanded-state**: The toggle button MUST carry `aria-expanded` reflecting the current open state.

## Appearance

Container: `rounded-lg border border-apt-border bg-apt-surface`. Header:
`flex items-center gap-2 px-3 py-2`; the toggle is a `<button>` showing a
`ChevronRight` that gains `rotate-90` when open, a `text-sm font-medium
text-apt-text` title and an optional `text-xs text-apt-text-muted` subtitle (both
truncate). `actions` are pinned to the right. The open body is separated by
`border-t border-apt-border px-3 py-3`. Focus ring `apt-gold/40`. No raw hex; no
`!important`. The chevron's rotation is animated with the `transition-transform`
class; no `motion-reduce:` variant is applied, so the rotation does not defer to
the reduced-motion preference (see Compliance).

## States

| State | Appearance change |
|---|---|
| collapsed | chevron points right; children unmounted |
| expanded | chevron rotated 90°; children shown under a top border |
| header focus | `focus-visible` ring on the toggle button |

## Accessibility

The header toggle is a real `<button>` carrying `aria-expanded` that reflects the
open state (**expose-expanded-state**), with a visible `focus-visible` ring. As a
native `<button>`, the toggle is reachable via Tab and activatable via Enter or
Space without extra wiring (**toggle-on-header-click**). The `actions` slot sits
outside the toggle button, so its controls are independently reachable and do not
trigger the toggle.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | toggle-on-header-click | click the header | children show, then hide |
| T2 | support-uncontrolled | `defaultOpen` only | manages its own state |
| T3 | support-controlled | `open={false}` and an `onOpenChange` that ignores the call; click the header | callback fires once; children stay unmounted |
| T4 | rotate-chevron | open it | chevron gains `rotate-90` |
| T5 | actions-exempt-from-toggle | click a button in `actions` | disclosure state unchanged |
| T6 | mount-children-only-when-open | collapsed | children absent from the DOM |
| T7 | toggle-on-header-click | Enter/Space on the focused header | children show, then hide |
| T8 | expose-expanded-state | inspect the toggle button after opening and closing | `aria-expanded` matches the current open state |

## Edge Cases

- In controlled mode the component never writes internal state — the caller owns `open`.
- `actions` are rendered outside the toggle `<button>`, so a click there cannot bubble into a toggle.
- Title and subtitle both truncate to keep the header a single row.
- Because children unmount when collapsed (**mount-children-only-when-open**), any uncommitted state inside them — e.g. a half-filled form — is discarded when the section closes, and they start fresh when it reopens.

## Configuration

Props: `title`, `subtitle?`, `actions?`, `defaultOpen?` (false), `open?`,
`onOpenChange?`, `className?`, `headerClassName?`, `children`. Export:
`Disclosure`.

## Deep Linking

None: the source subscribes to no router and reads/writes no URL. Open/closed
state is either held internally (`internalOpen`) or fully controlled by the
host via `open`/`onOpenChange`.

## Localization

None applicable: the component contains no hardcoded user-facing strings.
`title`, `subtitle`, and `actions` are all supplied by the caller via props.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: the chevron's `transition-transform` runs unconditionally; the source has no `prefers-reduced-motion` check. |
| Increase Contrast | Depends on the `apt-*` design tokens (`apt-border`, `apt-surface`, `apt-text`, `apt-text-muted`); the component itself does no `prefers-contrast` handling. |
| Differentiate Without Color | The chevron's rotation (`rotate-90` when open) indicates state independent of color, and `aria-expanded` carries it for assistive technology. |

## Feature Flags

None: feature-gating a disclosure is not a concern of the component itself; a
consumer wraps it or omits it via its own app-level flag logic.

## Analytics

None: the source emits no analytics or telemetry. A consumer can attach one via
`onOpenChange`, which already fires on every toggle.

## Privacy

None: the component collects and transmits nothing; `children` is whatever the
caller passes in.

## Logging

None — a presentational primitive. Callers own any open/close telemetry.

## Platform Notes

- **SwiftUI**: `DisclosureGroup` already supplies its own chevron and an `isExpanded:` binding for controlled mode — use it directly, or build an equivalent with `@State` for toggle state and `.rotationEffect(.degrees(isOpen ? 90 : 0))` for the chevron.
- **Compose**: `var expanded by remember { mutableStateOf(false) }` for toggle state, a chevron `Icon` with `Modifier.rotate(if (expanded) 90f else 0f)`, and `if (expanded) { content() }` so the body unmounts when collapsed.
- **React/Web**: `packages/web/packages/ui/src/components/disclosure.tsx`. Uses lucide `ChevronRight` icon for the toggle chevron. Marked `"use client"` for Next.js server components. Respects Tailwind theme tokens (`apt-*` family). Header truncates rather than wrapping; verify responsive behavior via Playwright at 375 / 768 / 1440.
- **AppKit / UIKit**: AppKit — an `NSButton` with `bezelStyle = .disclosure`, adding or removing the content view on toggle. UIKit — a `UIButton` toggling by adding or removing the content view as an arranged subview of a `UIStackView`.
- **WinUI 3**: the stock `Expander` puts its chevron on the trailing edge and flips it 180°, keeps collapsed content in the visual tree, and its `Expanding`/`Collapsing` events don't carry controlled-mode intent — following it as-is breaks **rotate-chevron** and **mount-children-only-when-open**. Either re-template `Expander` (leading chevron, `RotateTransform` at 90°, content set to `null` when collapsed) or build a custom `ToggleButton` + `ContentPresenter` pair that sets `Content` to `null` on collapse.

## Design Decisions

**Decision**: Support both controlled and uncontrolled open state, via an optional `open`/`onOpenChange` pair layered over an internal `useState`.
**Rationale**: Simple cases need no wiring; callers that must observe or drive the state can pass `open`/`onOpenChange` instead.
**Approved**: pending

**Decision**: Render `actions` outside the toggle `<button>`.
**Rationale**: Per-section buttons stay in the header without toggling the section, avoiding a surprise state change when a user clicks an action (principle of least astonishment).
**Approved**: pending

**Decision**: Unmount collapsed children instead of hiding them.
**Rationale**: Collapsed children leave the DOM so they hold no hidden tab stops; the trade-off is that any uncommitted state inside them resets each time the section closes (see Edge Cases).
**Approved**: pending

**Decision**: Implement the toggle as a hand-rolled `<button>` with conditional rendering rather than native `<details>`/`<summary>`.
**Rationale**: The component must support a fully controlled mode that reflects an external `open` prop without mutating internal state, and must unmount rather than hide its children when closed; native `<details>` ties its open state to the DOM `open` attribute and keeps collapsed content in the tree, which fights both requirements without extra imperative sync code.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on `packages/web/packages/ui/src/components/disclosure.tsx`: the real `<button>` with `aria-expanded` and native keyboard semantics ground the passed and partial accessibility checks, the unconditional `transition-transform` with no `motion-reduce:` variant grounds the failed reduced-motion check, the consumer-supplied `title`/`subtitle`/`children` props ground the passed internationalization checks, and the `truncate` classes with no leading-chevron RTL mirroring ground the failed and partial internationalization checks. `separation-of-concerns` is partial because `Disclosure`'s open/controlled toggle state and its `toggle()` handler are implemented inline in the component rather than extracted; `unit-test-coverage` fails because the only name-matching test, `viewSourceDisclosure.test.tsx`, actually exercises a different component (`ViewSourceDisclosure`), so no test exercises `disclosure.tsx`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added the Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics and Privacy sections. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: failed). |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case and add expose-expanded-state; rewrite Compliance as linked catalog checks (Accessibility, Internationalization); fix SwiftUI/Compose/AppKit-UIKit/WinUI 3 platform notes; reformat Design Decisions and add native-controls and unmount-state-loss entries; add keyboard-toggle and aria-expanded test vectors and rephrase the controlled-mode vector; add child-state-loss edge case; document the chevron's transition and its reduced-motion gap in Appearance; drop the unobservable "no internal mutation" clause from the controlled-mode test vector; credit v1.1.0/v1.2.0 to the human author with AI assistance noted in each Summary |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Revise Platform Notes: remove "Not applicable" phrasing from non-web bullets; sharpen guidance with concrete control names, properties, and XAML patterns (AI-assisted, Claude Haiku 4.5) |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Expand Platform Notes to include all five required bullets with concrete platform-specific guidance; update status to review; fix domain URI (AI-assisted, Claude Haiku 4.5) |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial draft |
