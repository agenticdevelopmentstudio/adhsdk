---
id: 10cd0ad8-b7b7-4674-9f8c-80a071fecb6f
title: "Sheet"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An edge-anchored drawer panel that slides in from a specified edge, used for supplementary content or actions without full-screen navigation."
platforms:
  - typescript
  - web
tags:
  - sheet
  - drawer
  - modal
  - dialog
depends-on: []
related:
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
references: []
approved-by: ""
approved-date: ""
---

# Sheet

## Overview

Sheet is a compound component that renders a slide-out drawer anchored to one edge of the viewport. It wraps a Base UI Dialog primitive and provides styled, animated panels for supplementary content, settings, or actions. The component supports positioning from top, right, bottom, or left edges and includes an animated backdrop that blocks interaction with underlying content.

## Behavioral Requirements

- **render-compound-components**: Component MUST export individual compound parts: Sheet (root), SheetTrigger, SheetClose, SheetContent, SheetHeader, SheetFooter, SheetTitle, and SheetDescription. `SheetPortal` and `SheetOverlay` are module-local helpers used only inside SheetContent; they are not exported and are not importable by consumers.
- **position-by-side**: SheetContent MUST position the drawer based on a `side` prop ("top" | "right" | "bottom" | "left"), with default value "right".
- **render-overlay**: Component MUST render an overlay element with semi-transparent dark background that appears behind the drawer.
- **backdrop-blur**: Overlay MUST apply a blur effect (backdrop-filter: blur) on supporting browsers.
- **close-button-default-visible**: SheetContent MUST render a close button by default in the top-right corner.
- **close-button-visibility-control**: SheetContent MUST accept a `showCloseButton` boolean prop (default `true`) to control close button visibility.
- **close-icon**: Close button MUST render a close ("X") icon.
- **close-button-accessible-label**: Close button MUST include a screen-reader-accessible label ("Close") identifying its purpose to assistive technology.
- **animate-transitions**: Drawer content and overlay MUST animate with a CSS transition on appearance and disappearance.
- **animation-scale**: Animation duration MUST be calculated using the CSS custom property `--apt-anim-scale` (default 1), with specific durations: 150ms for overlay, 200ms for drawer. A scale of 0 or a negative value MUST result in an instant (zero-duration) transition, since a non-positive value multiplied against either base duration computes to zero or less and CSS clamps a negative transition-duration to 0.
- **close-on-overlay-click**: Clicking the overlay MUST close the drawer by default. Base UI's Dialog root ships pointer dismissal enabled unless a caller passes `disablePointerDismissal`; Sheet does not set that prop, so the inherited default applies. Callers MAY disable it by passing `disablePointerDismissal` to `Sheet`.
- **width-constrained-on-sides**: When positioned left or right, SheetContent MUST constrain width to 75% of the viewport, capped at 24rem on small+ (`sm`, ≥640px) screens.
- **content-composition-props**: Sheet, SheetTrigger, SheetClose, and SheetContent MUST accept and spread component props to their underlying Base UI primitives. Internally, the module-local `SheetPortal` and `SheetOverlay` helpers do the same, but that is unreachable from outside the module since neither is exported (see **render-compound-components**).
- **header-footer-divs**: SheetHeader and SheetFooter MUST render as `<div>` elements with predefined padding and flex layout.
- **title-description-typography**: SheetTitle and SheetDescription MUST wrap Base UI primitives with styled typography.

## Appearance

- **Corner radius**: None (sharp edges, matching popover design token).
- **Padding**: 
  - SheetHeader: 1rem (16px) all sides, with 4px gap between children.
  - SheetFooter: 1rem (16px) all sides, with 8px gap between children.
  - SheetContent: 1rem (16px) gap between top-level children.
- **Font**: 
  - SheetTitle: font-weight 500, size 1rem (16px).
  - SheetDescription: size 0.875rem (14px).
- **Background**: Popover background color (via `bg-popover` token).
- **Foreground/Text**: 
  - Popover foreground for default text (via `text-popover-foreground` token).
  - Muted foreground for SheetDescription (via `text-muted-foreground` token).
  - Foreground color for SheetTitle (via `text-foreground` token).
- **Border**: 1px border using `border-apt-border` token, position varies by side (top, right, bottom, or left as appropriate).
- **Shadow**: Box shadow applied to drawer panel (via `shadow-lg` token).
- **Overlay appearance**: Black with 20% opacity (`bg-black/20`), semi-transparent with backdrop blur.
- **Close button position**: Absolute, top-right corner (16px from edges), size `icon-sm` (smaller than default button).
- **Width constraints**: 
  - Left/right positioning: 75% of viewport width, capped at 24rem on small and larger screens (`sm:max-w-sm`).
  - Top/bottom positioning: full width, height auto.

## States

| State | Appearance change |
|-------|------------------|
| Closed | Drawer is off-screen; overlay is not rendered. |
| Opening | Drawer animates into viewport; overlay fades in. Opacity and transform transition based on `--apt-anim-scale`. |
| Open | Drawer is fully visible at its final position; overlay covers background at full opacity. |
| Closing | Drawer animates out of viewport; overlay fades out. Uses `data-ending-style` for exit transition. |

## Accessibility

- **Role/trait**: Drawer is rendered as a Dialog (via Base UI `Dialog` primitive), which is announced as a dialog by screen readers.
- **Label requirements**: The drawer MUST have an accessible name at all times — supplied by SheetTitle (auto-associated by Base UI Dialog via `aria-labelledby`) or, when no visible title is used, by an `aria-label` prop passed to SheetContent (accepted via **content-composition-props**).
- **Announce state changes**: Base UI Dialog handles focus management and announces opening/closing to screen readers.
- **Minimum tap target**: The close button's `size="icon-sm"` Button variant renders at 1.75rem (28px) square (`size-7`, per `button.tsx`), below the 44×44pt minimum — this is a known failure, not an enforced minimum.
- **Keyboard navigation**: Base UI Dialog primitive handles Escape key to close and focus trapping within the drawer. Source code relies on these inherited behaviors.
- **Screen reader text**: Close button includes a screen-reader-only label ("Close") — invisible on screen but exposed to assistive technology (see **close-button-accessible-label**).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sheet-001 | render-compound-components | Import Sheet and sub-components | All 8 exports (Sheet, SheetTrigger, SheetClose, SheetContent, SheetHeader, SheetFooter, SheetTitle, SheetDescription) are available and usable; importing `SheetPortal` or `SheetOverlay` fails, since neither is exported. |
| sheet-002 | position-by-side | Render SheetContent with `side="left"` | Drawer appears on left edge of viewport with `data-side="left"` attribute. |
| sheet-003 | position-by-side | Render SheetContent without a `side` prop | Drawer appears on right edge (default) with `data-side="right"` attribute. |
| sheet-004 | render-overlay | Render Sheet with content | Overlay element with `data-slot="sheet-overlay"` appears behind drawer. |
| sheet-005 | backdrop-blur | Inspect overlay's computed style in a supporting browser | Overlay's computed `backdrop-filter` includes a blur value (implemented via the `supports-backdrop-filter:backdrop-blur-xs` Tailwind utility — see React/Web Platform Note). |
| sheet-006 | close-button-default-visible | Render SheetContent without `showCloseButton` prop | Close button renders in top-right corner. |
| sheet-007 | close-button-visibility-control | Render SheetContent with `showCloseButton={false}` | Close button does not render. |
| sheet-008 | close-icon | Inspect the close button's icon graphic | Icon renders as an "X" shape (implemented via lucide-react's `XIcon` — see React/Web Platform Note). |
| sheet-009 | close-button-accessible-label | Render close button and inspect its accessible name | Close button exposes the accessible name "Close" to assistive technology (implemented via a visually hidden span — see React/Web Platform Note). |
| sheet-010 | animate-transitions | Open the drawer and inspect CSS during entry | Drawer and overlay apply `transition` CSS; opacity and transform animate from their starting-style values to their open-state values. |
| sheet-011 | animate-transitions | Close the drawer and inspect CSS during exit | Drawer and overlay apply `transition` CSS; opacity and transform animate from their open-state values to their ending-style values. |
| sheet-012 | animation-scale | Open drawer with `--apt-anim-scale` set to 2 | Overlay animation duration is 300ms (150ms × 2); drawer animation is 400ms (200ms × 2). |
| sheet-013 | animation-scale | Open drawer with `--apt-anim-scale` set to 0 or a negative value | Computed transition-duration is 0 (0 or negative ms clamps to 0), so the drawer and overlay transition instantly with no visible animation. |
| sheet-014 | close-on-overlay-click | Click the overlay while the drawer is open | Drawer closes; `onOpenChange` fires with a pointer/outside-press dismissal reason. |
| sheet-015 | width-constrained-on-sides | Render SheetContent with `side="right"` on a small+ (≥640px) viewport | Width is 75% of viewport width, capped at 24rem (`sm:max-w-sm` applies once 75% would exceed 24rem). |
| sheet-016 | content-composition-props | Render SheetContent with additional `className` | Additional class is applied to the drawer element. |
| sheet-017 | header-footer-divs | Render SheetHeader and SheetFooter | Both render as `<div>` elements with padding (`p-4`) and flex layout. |
| sheet-018 | title-description-typography | Render SheetTitle and SheetDescription | Title renders with `font-medium`, description with muted foreground color. |
| sheet-019 | Edge case: null/empty content | Render SheetContent with no children | Drawer renders visible but empty; no error is thrown. |
| sheet-020 | Edge case: multiple sheets | Render two Sheet instances simultaneously, both open | Both render independently via separate Base UI Portals; because SheetOverlay and SheetContent both use a fixed `z-50`, relative stacking order between the two is determined by DOM order, not managed by the component. |
| sheet-021 | Edge case: animation interruption | Toggle the drawer open, then toggle it closed before the opening transition finishes | The CSS transition is interrupted and reverses from its current computed value (standard CSS transition-interruption behavior); no additional interruption handling exists in source beyond this. |
| sheet-022 | Edge case: side boundary | Render SheetContent with `side="left"` on a 320px-wide viewport | Drawer renders at 75% of viewport width (240px); no additional minimum-width or narrow-viewport safeguard is applied by the component. |

## Edge Cases

- **Null/empty content**: If SheetContent is rendered with no children, drawer is still visible but empty. No error is thrown (see sheet-019).
- **Overlay interaction**: Covered by **close-on-overlay-click** — clicking the overlay closes the drawer by default, inherited from Base UI's Dialog root (see sheet-014).
- **Multiple sheets**: The component places no limit on how many Sheet instances may be open at once; each renders independently via its own Base UI Portal. SheetOverlay and SheetContent both use a fixed `z-50`, so the visual stacking order between multiple simultaneously open sheets is determined by DOM order, not managed by the component (see sheet-020).
- **Animation interruption**: Rapidly toggling the drawer open and closed interrupts the current CSS transition; the browser continues from its current computed opacity/transform value toward the new target (standard CSS transition-interruption behavior). No additional interruption handling exists in source beyond this (see sheet-021).
- **Side boundary**: On mobile with `side="left"` or `side="right"`, the 75%-capped-at-24rem width constraint may leave insufficient space; width calculations use viewport units without media-query safety checks for very narrow viewports (see sheet-022).
- **Custom animation scale**: A scale of 0 or negative computes a zero-or-negative transition-duration; CSS clamps this to an instant (zero-duration) transition, per **animation-scale** (see sheet-013). The defined behavior comes from CSS's own duration clamping, not app-level validation.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | "top" \| "right" \| "bottom" \| "left" | "right" | Specifies which edge the drawer slides in from. |
| `showCloseButton` | boolean | `true` | Controls whether the close button is rendered in the top-right corner. |

## Deep Linking

Not applicable: Sheet is a modal overlay component with no navigation entry point or URL routing integration in the source.

## Localization

Sheet does carry one user-visible string: the close button's screen-reader label, "Close" (see **close-button-accessible-label**). It is hardcoded in `sheet.tsx` rather than sourced from a localization resource, so it renders in English regardless of the consuming app's locale — a real i18n gap in the current source, not a "not applicable" case.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Sheet respects the `--apt-anim-scale` custom property, which can be set to 0 by the application to disable animations for users who prefer reduced motion. |
| Increase Contrast | Overlay opacity (`bg-black/20`) and text contrast rely on the underlying design token system; no component-level contrast override is implemented. |
| Differentiate Without Color | Component does not rely on color alone to communicate state; positional and structural changes are visible independently of color. |

## Feature Flags

Not applicable: Sheet has no conditional behavior or feature flag integration in the source.

## Analytics

Not applicable: Sheet contains no analytics event tracking or data collection in the source.

## Privacy

- **Data collected**: None. Sheet does not collect, store, or transmit user data.
- **Storage**: No local storage or session storage is used.
- **Transmission**: No network requests are made.
- **Retention**: Not applicable.

## Logging

Not applicable: Sheet has no logging or debugging output in the source.

## Platform Notes

- **SwiftUI**: No SwiftUI version exists. A port would use a `.sheet()` or `.presentationDetents()` modifier for top/bottom drawers, or `.inspector()` for a side-anchored panel. Positioning logic for arbitrary edges would need manual implementation.
- **Compose**: No Compose version exists. A port would use `ModalBottomSheet` for top/bottom drawers, or Material3's `ModalNavigationDrawer` for left/right side drawers. The four-side positioning would require custom composition logic to unify both under one API.
- **React/Web**: This is the React/Web version. It uses Base UI Dialog as the foundational primitive, Tailwind CSS for styling, and CSS custom properties for animation scaling. Implementation-specific details: the close icon is lucide-react's `XIcon`; the close button's accessible label is a visually hidden `<span className="sr-only">Close</span>`; the overlay's blur uses the `supports-backdrop-filter:backdrop-blur-xs` utility; left/right width uses the `w-3/4` and `sm:max-w-sm` utilities; and header/footer padding uses the `p-4` utility.
- **AppKit / UIKit**: No AppKit or UIKit version exists. `NSPanel` is a floating panel, not a drawer, so it is not the right mapping. A port would use `NSSplitViewController` with a collapsible side pane on macOS, or `UIViewController` with `.modalPresentationStyle = .custom` and a custom transition controller for slide-in behavior on iOS.
- **WinUI 3**: No WinUI 3 version exists. `ContentDialog` is a centered modal dialog, not a drawer, so it is not the right mapping. A port would use `SplitView` with `DisplayMode="Overlay"` and `OpenPaneLength` for left/right side drawers, or a custom `Grid` with `ThicknessTransition` animations for top/bottom. Side constraints would use `ColumnDefinition` widths or `RelativePanel` for left/right sides.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/sheet.tsx` | unverified |

## Design Decisions

**Decision**: Sheet is implemented as a series of composed sub-components (Header, Footer, Title, Description) rather than a monolithic component.
**Rationale**: This allows flexibility in content structure and reuse of individual parts. The pattern matches the shadcn/ui design philosophy.
**Approved**: pending

**Decision**: The component wraps Base UI's Dialog primitive, which provides keyboard handling (Escape to close), focus management, and ARIA attributes automatically.
**Rationale**: This offloads accessibility complexity to a vetted foundation.
**Approved**: pending

**Decision**: Animation durations are calculated using `calc()` with a `--apt-anim-scale` custom property.
**Rationale**: This allows global animation control (e.g., for reduced motion) without changing component code.
**Approved**: pending

**Decision**: The `showCloseButton` prop defaults to `true`, providing an always-available close affordance.
**Rationale**: Users can disable it if a custom close mechanism is preferred.
**Approved**: pending

**Decision**: Left and right drawers are constrained to 75% viewport width, capped at 24rem, on small+ screens, leaving the underlying content partially visible.
**Rationale**: This preserves context and allows custom overflow behavior.
**Approved**: pending

**Decision**: The backdrop includes a blur effect (via `supports-backdrop-filter:backdrop-blur-xs`) to create visual separation.
**Rationale**: This is a visual preference; the blur is optional on unsupporting browsers.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`sheet.tsx` grounds these statuses: Base UI's `Dialog` primitive supplies focus trapping/restoration, Escape handling, `role="dialog"`, `aria-modal`, and `aria-labelledby` (the `passed` rows); the close button's `size="icon-sm"` Button variant is 28px square per `button.tsx`, under the 44×44pt minimum (`touch-target-size: failed`); the close label "Close" is a hardcoded, non-externalized string (`string-externalization` and `no-hardcoded-strings: failed`); side positioning uses physical `left-0`/`right-0` rather than logical inline-start/inline-end properties, so it does not flip for RTL locales (`rtl-layout-support: failed`); and `--apt-anim-scale` gives the app a lever for reduced motion, but the component never reads `prefers-reduced-motion` itself (`reduced-motion: partial`). Font sizing in `rem` and unrestricted children content leave `dynamic-type-support`, `contrast-ratio`, `text-expansion-tolerance`, and `unicode-support` as either `partial` (the source can't itself guarantee the outcome) or `passed` (nothing in source restricts it). `separation-of-concerns` passes because `sheet.tsx` only forwards props onto `@base-ui/react`'s `Dialog` primitive, carrying no business logic of its own. `unit-test-coverage` fails because no test file in the `ui` package exercises `Sheet`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Compliance best-practices rows added (prior fixer already fixed E_2 exports). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed Behavioral Requirements to subject-only kebab-case and updated every citation; moved web-specific implementation details (lucide `XIcon`, Tailwind utility classes, the `sr-only` span) out of requirements and test vectors into the React/Web Platform Note; corrected the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 Platform Notes to real native drawer APIs (`.inspector()`, `ModalNavigationDrawer`, `NSSplitViewController`, `SplitView`/`DisplayMode="Overlay"`); added a close-on-overlay-click requirement and test vector grounded in Base UI's default pointer-dismissal behavior; recorded the close button's actual 28px hit target as a known touch-target-size failure instead of a false 44pt claim; defined scale-0/negative as an instant transition via CSS duration clamping and described CSS transition-interruption on rapid toggling instead of leaving both undefined; corrected the width requirement to "75%, capped at 24rem on sm+" and fixed the sheet-012/sheet-003 test vectors to match; rebuilt Compliance as a canonical linked accessibility/internationalization table; reformatted Design Decisions into Decision/Rationale/Approved blocks; added dialog and popover to related; fixed the circular label requirement, the "visible screen-reader-only" and "semantic divs" wording, the unbounded multiple-sheets edge case, the mischaracterized "Not applicable" Localization section, and the "side drawer" summary; added test vectors for every edge case |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Remove review marker from Compliance section; state Base UI Dialog inheritance as fact and list satisfied WCAG compliance items |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
