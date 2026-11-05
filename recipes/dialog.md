---
id: 972be0d0-a9f5-45cd-a23b-c8329410b3d1
title: Dialog
domain: adhsdk://recipes/dialog
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-06-26'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Centered modal Dialog (Base UI) themed with apt-* tokens; backdrop dismissal off by default. Composes Trigger/Content/Header/Footer/Title/Description.
platforms:
  - typescript
  - web
tags:
  - dialog
  - modal
  - overlay
  - base-ui
depends-on: []
related:
  - adhsdk://recipes/alert-and-dialog
references: []
approved-by: ''
approved-date: ''
---

# Dialog

## Overview

**Dialog** is the shared centered-modal primitive, built on `@base-ui/react/dialog`
and themed with the family `apt-*` tokens. It is composed from parts —
`Dialog` (root), `DialogTrigger`, `DialogContent`, `DialogHeader`, `DialogFooter`,
`DialogTitle`, `DialogDescription`, and `DialogClose` — and is the base every
larger overlay (AlertModal, the invitation and add-users modals) is built on.

## Behavioral Requirements

- **centered-modal**: `DialogContent` MUST render a centered, portalled popup over a dimmed, blurred backdrop.
- **backdrop-dismissal-disabled**: By default the dialog MUST NOT close on a backdrop or outside click (`disablePointerDismissal`); a caller MAY re-enable it with `disablePointerDismissal={false}`.
- **escape-closes**: Escape MUST close the dialog, unless a composing component overrides it via its own `onOpenChange` handler.
- **close-affordance**: `DialogContent` MUST render a labelled `×` close button by default; `showClose={false}` MUST hide it.
- **focus-trap**: While open, focus MUST be trapped within the dialog and restored to the opener on close.
- **dialog-labelling**: Every composing dialog MUST render a `DialogTitle` so the dialog is labelled for assistive technology; `DialogDescription` MUST be rendered when descriptive text is needed.

## Appearance

- **Backdrop**: `fixed inset-0` positioning, `bg-black/30` overlay (30% black opacity), `backdrop-blur-sm` blur effect, `z-50` stacking.
- **Popup container**: Centered at `top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2`, width `w-[calc(100%-2rem)]` (100% minus 16px side margins), max-width `max-w-md` (448px), `rounded-xl` corner radius (12px), `border` 1px `border-apt-border`, background `bg-apt-surface`, text color `text-apt-text`, padding `p-5` (20px all sides), `shadow-xl` shadow effect, `z-50` stacking.
- **Close button (×)**: Positioned `absolute top-3.5 right-3.5`, icon size `size-4` (16px × 16px), rounding `rounded`, default text color `text-apt-text-muted`, hover state transitions to `text-apt-text`, focus ring `ring-2 ring-apt-gold/40`, no outline.
- **DialogHeader**: Flex layout `flex-col`, vertical gap `gap-1.5` (6px).
- **DialogFooter**: Flex layout with `items-center justify-end`, horizontal gap `gap-3` (12px).
- **DialogTitle**: Font size `text-base` (16px), weight `font-semibold` (600), text color `text-apt-text`.
- **DialogDescription**: Font size `text-sm` (14px), text color `text-apt-text-muted`.
- **Stacking**: Backdrop and popup both use `z-50`; within the same `Portal` the popup renders after the backdrop (see `dialog.tsx`), so DOM order — not the z-index value — is what keeps the popup above the backdrop.
- **Constraint**: No raw hex color values; no `!important` declarations.

## States

| State | Appearance change |
|---|---|
| closed | Portal empty — nothing rendered |
| open | Dimmed/blurred backdrop visible + centered popup visible |
| close button hover | `×` text color shifts from `text-apt-text-muted` to `text-apt-text` |
| close button focus | `×` displays focus ring `ring-2 ring-apt-gold/40` |

## Accessibility

- **Role and properties**: `role="dialog"` with `aria-modal="true"` (set by Base UI); dialog is labelled by `DialogTitle` (via `aria-labelledby`) and described by `DialogDescription` (via `aria-describedby`) when they are rendered — see **dialog-labelling**.
- **Focus management**: Focus is trapped within the dialog while open and restored to the triggering element on close (Base UI handles this).
- **Keyboard**: Escape closes the dialog by default; Tab and Shift+Tab cycle focus within the trapped set. See **escape-closes** for how a composing component overrides this.
- **Close affordance**: The close button (`×`) carries `aria-label="Close"` to announce its purpose; this string is hardcoded directly in `dialog.tsx`'s `DialogContent`, not supplied by Base UI (see Localization).
- **Target size**: The close button's hit area is limited to its `size-4` (16×16px) icon — no padding class enlarges the clickable region — so it does not meet 44×44pt/48×48dp guidance. See Compliance's `touch-target-size` status.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | centered-modal | Open the dialog with `<DialogTrigger>` | Popup appears centered on screen with dimmed, blurred backdrop behind it |
| T2 | backdrop-dismissal-disabled (default) | Click the backdrop area while dialog is open | Dialog remains open |
| T3 | escape-closes (default) | Press Escape key while dialog is open and focused | Dialog closes |
| T4 | close-affordance (default) | Render `<DialogContent>` without `showClose` prop | Close button (×) is rendered in top-right corner |
| T5 | close-affordance (hidden) | Render `<DialogContent showClose={false}>` | Close button is not rendered |
| T6 | focus-trap | Tab through dialog, close it | Focus stays within dialog; on close, focus returns to the trigger element |
| T7 | dialog-labelling | Render with `<DialogTitle>` and `<DialogDescription>` | Assistive technology announces title and description |
| T8 | backdrop-dismissal-disabled (opt-in) | Set `disablePointerDismissal={false}` and click backdrop | Dialog closes on backdrop click |
| T9 | escape-closes (override) | Composing component passes its own `onOpenChange`, calling `eventDetails.cancel()` when the dismissal reason is Escape (or, with a controlled `open`, simply not setting it to `false`), then Escape is pressed while the dialog is open and focused | Dialog remains open — the composing component's override suppresses the default Escape-to-close behavior |
| T10 | dialog-labelling (missing title) | Render `<DialogContent>` with no `<DialogTitle>` child | Popup renders without an `aria-labelledby` attribute; assistive technology announces the dialog with no accessible name |

## Edge Cases

- **Backdrop dismissal is off by default** (see **backdrop-dismissal-disabled**) for modals/alerts — users opt back in with `disablePointerDismissal={false}`.
- **Content width**: Dialog caps at `max-w-md` (448px); composing dialogs widen it via className override (e.g., `sm:max-w-2xl`).
- **Close button hide**: `showClose={false}` hides the affordance for dialogs whose footer buttons are the only dismissal path (e.g., a busy/loading state that also overrides **escape-closes** so Escape is blocked while busy).
- **Responsive behavior**: `w-[calc(100%-2rem)]` preserves 16px side margins on small screens; margins prevent edge-touching on mobile.
- **Escape override**: A composing component overrides **escape-closes** by passing its own `onOpenChange` (forwarded via `{...props}` on the `Dialog` root) and checking the dismissal reason before calling `eventDetails.cancel()` on the event-details argument — Base UI ignores a plain `event.preventDefault()` here — or, with a controlled `open`, by simply returning without flipping it to `false` — e.g., a search input within the dialog that wants to capture Escape for its own purposes.
- **Missing title**: A `<DialogContent>` rendered without `<DialogTitle>` has no `aria-labelledby` and is announced to assistive technology with no accessible name; composing components MUST always render `DialogTitle` (see **dialog-labelling**), hiding it visually with CSS if a visible title isn't wanted.

## Configuration

Subcomponents and their key props:
- **Dialog** (root): `disablePointerDismissal` (bool, default `true`), `open` (bool), `onOpenChange` (callback).
- **DialogTrigger**: Forwards Base UI Trigger props; typically wraps an action button.
- **DialogClose**: Forwards Base UI Close props; used in footer buttons or standalone.
- **DialogContent**: `showClose` (bool, default `true`), `className` (string for overrides); forwards Base UI Popup props.
- **DialogHeader**: `className` override; forwards div props.
- **DialogFooter**: `className` override; forwards div props.
- **DialogTitle**: Forwards Base UI Title props.
- **DialogDescription**: Forwards Base UI Description props.

## Deep Linking

Not applicable: Dialog is a primitive component without its own navigation path. Deep linking to dialog state belongs to the parent page or application that hosts the dialog.

## Localization

Dialog renders one user-facing string: the close button's `aria-label="Close"`. That string is a literal hardcoded directly in `dialog.tsx`'s `DialogContent` — it is not supplied by Base UI — and it is not currently externalized or overridable via a prop. Composing components add their own translatable titles and descriptions via `DialogTitle` and `DialogDescription`.

## Accessibility Options

- **Reduce Motion**: Not applicable — `dialog.tsx` applies no open/close transition or animation classes to the backdrop or the popup; the only `transition-colors` class is on the close button's hover text color, which is not motion.
- **Differentiate Without Color**: Not applicable — no state is conveyed by color alone.
- **Increase Contrast**: Inherits text color contrast from the `apt-*` token family; the actual contrast values live outside this file (see Compliance's `contrast-ratio` status).
- **Reduce Transparency**: Not addressed by the current implementation — the backdrop always renders at `bg-black/30` with `backdrop-blur-sm` regardless of this system preference.

## Feature Flags

Not applicable: Dialog is a primitive component without feature flags. Feature gate decisions belong to composing components.

## Analytics

Not applicable: Dialog is a presentational primitive. Composing components and parent pages own open/close analytics; if needed, wrap the dialog's `onOpenChange` callback to emit events.

## Privacy

Not applicable: Dialog collects no data.

## Logging

None — a presentational primitive that emits no logs of its own.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/components/dialog.tsx`. Built on `@base-ui/react/dialog`. Marked `"use client"` for Next.js. Responsive behavior verified via Playwright (ui-showcase) at 375px, 768px, and 1440px viewport widths.
- **SwiftUI**: Web-only shared component; no SwiftUI implementation exists in `packages/apple` yet. A SwiftUI-native equivalent would present via `.sheet(isPresented:)` (or `.fullScreenCover`), pairing `interactiveDismissDisabled()` with the backdrop-dismissal-disabled default.
- **Compose**: Web-only shared component; no Compose implementation exists yet. A Compose equivalent would use the `Dialog` composable from Material Design 3.
- **AppKit / UIKit**: Web-only shared component. A native equivalent would use `NSWindow.beginSheet(_:completionHandler:)` on AppKit or `UIModalPresentationStyle.formSheet` on UIKit for arbitrary content — not `UIAlertController`, which is scoped to alert/action-sheet styles. `packages/apple`'s existing dialogs (e.g. `WindowOptionsDialog` in `AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome`) are bespoke `NSWindow` presentations built for a different purpose, not a shared counterpart to this primitive.
- **WinUI 3**: A WinUI equivalent would use the `ContentDialog` control with `PrimaryButtonText`, `SecondaryButtonText`, and `CloseButtonText` for its action buttons. Apply theme colors via `Application.Current.Resources` for dark/light mode token equivalents. The backdrop is handled by `ContentDialog`'s built-in smoke layer (`SmokeLayerBackground`), which approximates the `bg-black/30` dimming effect.

## Design Decisions

**Decision**: Backdrop dismissal is disabled by default for modals and alerts.
**Rationale**: Prevents accidental data loss and clarifies intent (see **backdrop-dismissal-disabled** above, which AlertModal and the other composing dialogs inherit unchanged); pointer dismissal is opt-in for advanced use cases.
**Approved**: pending

**Decision**: Built on Base UI (`@base-ui/react/dialog`) rather than a hand-rolled implementation.
**Rationale**: Inherits focus trapping, portalling, and assistive technology support, reducing maintenance burden and ensuring standards compliance.
**Approved**: pending

**Decision**: Backdrop opacity is 30% black (`bg-black/30`), not 60%.
**Rationale**: Keeps the underlying page legible and subordinate while preserving context; the harder 60% opacity obscured the page entirely.
**Approved**: pending

**Decision**: All colors and spacing use the `apt-*` design-token family.
**Rationale**: Ensures consistent theming across the product without raw hex values or `!important` overrides.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on `dialog.tsx`: the explicit `aria-label="Close"` plus Base UI's documented role/focus-trap/portal contract support the passed accessibility rows; the `apt-*` token contrast values and whether the `rem`-based `text-base`/`text-sm` classes track system font scaling aren't verifiable from this file, hence partial; the close button's `size-4` icon has no padding class enlarging its hit area, so it plainly fails the 44×44 target; and the hardcoded, non-overridable `"Close"` string in `DialogContent` fails both internationalization checks. `separation-of-concerns` passes because `dialog.tsx` is a thin composition of `DialogPrimitive.*` with Tailwind classes and no business logic of its own; `unit-test-coverage` is partial because `Dialog`/`DialogContent` are exercised only through parent components (`AlertModal` in `alertModal.test.tsx`, `CategoryPickerDialog` in `categoryPickerDialog.test.tsx`), never by a dedicated test of `dialog.tsx` itself.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed T9/Escape-override to use eventDetails.cancel() (or controlled open) not event.preventDefault(); fixed dangling backdrop-dismissal-disabled cross-ref to point locally instead of alert-and-dialog. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed Behavioral Requirements to subject-only kebab-case and updated every citation; corrected the WinUI 3 and AppKit/UIKit Platform Notes bullets to real APIs and verified against `packages/apple`; relabeled Platform Notes bullets to the standard names; rebuilt Compliance as canonical linked accessibility/internationalization checks with a supporting sentence; reformatted Design Decisions into Decision/Rationale/Approved blocks and cited the alert-and-dialog requirement by fragment instead of a wiki-link and section number; corrected the Localization and Target size claims against `dialog.tsx`; narrowed Logging to stop repeating Analytics; documented the escape-override mechanism and the no-title edge case with new test vectors; noted the backdrop/popup z-order dependency and the unaddressed Reduce Transparency gap |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Correct backdrop opacity from bg-black/60 to bg-black/30 per source; structure Appearance section; fix domain URI from hub to cookbook; expand Accessibility, Edge Cases, and Platform Notes; upgrade status from draft to review |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial draft |
