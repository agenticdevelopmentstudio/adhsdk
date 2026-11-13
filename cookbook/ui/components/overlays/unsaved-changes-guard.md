---
id: 6d2dc0d3-e373-448c-81c9-76b2e5c03057
title: "Unsaved Changes Guard"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Blocks navigation and page unload while unsaved changes exist, prompting user confirmation before discard."
platforms:
  - typescript
  - web
tags:
  - navigation-guard
  - forms
  - unsaved-changes
depends-on:
  - 9e36a0ef-67ef-485d-8ace-68886add841c
related: []
references: []
approved-by: ""
approved-date: ""
---

# Unsaved Changes Guard

## Overview

A navigation guard that prevents accidental data loss by blocking page navigation and unload events when the guard is armed (`when` is true). It intercepts four classes of navigation: hard navigation (reload, tab close, external link), in-app anchor clicks, programmatic router navigation, and browser Back/Forward button presses. When a blocked navigation is triggered, the guard displays a confirmation modal; the user must explicitly choose to discard changes or stay on the page.

## Behavioral Requirements

- **block-beforeunload**: The guard MUST prevent `beforeunload` events from unloading the page when `when` is true and no navigation has been approved via `approveNavigation()`.
- **prompt-anchor-navigation**: The guard MUST intercept a same-origin anchor click and display a confirmation prompt instead of navigating when all of the following hold: it is a plain left click with no modifier keys (`button === 0`, no Cmd/Ctrl/Shift/Alt) and the event has not already been default-prevented by an earlier handler; the closest ancestor `<a href>` has no `target` attribute or `target="_self"`; the anchor has no `download` attribute; `anchor.href` parses as a valid URL via `new URL()`. If any of those conditions fails, the click proceeds untouched.
- **skip-marked-anchors**: The guard MUST NOT intercept anchors bearing the `GUARDED_NAV_ATTR` attribute — the literal DOM attribute `data-guarded-nav` — because those anchors' own handlers consult `confirmNavigation(): Promise<boolean>` directly.
- **skip-same-page-links**: The guard MUST NOT block same-page navigations (same pathname and search; hash-only changes are allowed through).
- **skip-cross-origin**: The guard MUST NOT intercept cross-origin anchor navigations (they unload the page and `beforeunload` already covers them).
- **guard-back-button**: The guard MUST intercept browser Back/Forward via a same-URL history sentinel; only the primary guard in a multi-guard registry arms the sentinel.
- **register-with-registry**: The guard MUST register itself with the navigation-guard registry — `registerNavigationGuard(guard: () => boolean | Promise<boolean>): () => void` — so that a `confirmNavigation(): Promise<boolean>` call from elsewhere (e.g. `router.push()`) awaits this guard's answer instead of navigating unchecked.
- **call-on-navigate**: When the user confirms discard on an anchor navigation, the guard MUST call `onNavigate(href)` if provided; otherwise fall back to `window.location.assign(href)`.
- **approve-briefly**: After the user confirms, the guard MUST set an internal approval flag (`approvedRef.current`) that prevents `beforeunload` from re-prompting during the navigation itself, self-expiring after 1000ms. The registry's exported `approveNavigation(windowMs = 1000): void` shares the same default and lets a caller override the window per call.
- **coalesce-multiple-guards**: When multiple guards are armed, the registry's first-registered guard is primary; only the primary answers `confirmNavigation()` and arms the sentinel. Non-primary guards' `beforeunload` listeners coalesce into the browser's native prompt.
- **prompt-after-approval**: The guard MUST NOT display a confirmation prompt if a prior guard has already approved the navigation via `approveNavigation()` (called just before a successful save).
- **prevent-default**: The guard MUST call `e.preventDefault()` on an intercepted click, and MUST NOT call `e.stopPropagation()` or `e.stopImmediatePropagation()` — other handlers on the same anchor (menu close-on-select, analytics) and the framework router's own defaulted-event check still need to run.
- **clear-sentinel-on-back**: The guard MUST set the stored sentinel URL to null when Back consumes it, so re-arming at the same URL pushes a fresh sentinel.
- **update-sentinel-on-rearm**: The guard SHOULD re-arm the Back sentinel whenever primary status changes, in case a prior primary disarmed and this guard inherits the role.

## Appearance

Not applicable: This component is a guard with no visible UI. The `UnsavedChangesAlert` child component renders the confirmation modal.

## States

Not applicable: The guard has no visual states. It maintains internal state (confirm pending, approval flag, sentinel URL) but these are not user-facing states.

## Accessibility

Not applicable: Accessibility is handled by the `UnsavedChangesAlert` component that renders the confirmation modal.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| guard-001 | block-beforeunload | Guard armed (`when=true`); user presses Cmd+R or closes tab | Browser's native "Leave site?" prompt appears; page does not reload |
| guard-002 | prompt-anchor-navigation | Guard armed; user left-clicks an anchor to `/other?foo=bar` on same origin | `UnsavedChangesAlert` opens; page stays at current URL until user chooses |
| guard-003 | skip-marked-anchors | Guard armed; anchor has `GUARDED_NAV_ATTR` attribute | No confirmation from guard; anchor's own handler runs uninterrupted |
| guard-004 | skip-same-page-links | Guard armed; user clicks `href="#section"` on same page | Navigation completes without confirmation; hash changes |
| guard-005 | skip-cross-origin | Guard armed; user clicks anchor to `https://example.com` | No confirmation from guard; browser handles cross-origin unload via `beforeunload` |
| guard-006 | guard-back-button | Guard armed as primary; user presses browser Back button | Sentinel same-URL history entry is consumed; `UnsavedChangesAlert` opens |
| guard-007 | call-on-navigate | Guard armed; user confirms discard on anchor to `/next`; `onNavigate` is provided | `onNavigate("/next")` is called with the target href |
| guard-008 | call-on-navigate | Guard armed; user confirms discard on anchor to `/next`; `onNavigate` is not provided | `window.location.assign("/next")` is called |
| guard-009 | approve-briefly | User confirms navigation; page stays mounted with dirty state | `beforeunload` does not prompt during the 1000ms approval window |
| guard-010 | prompt-after-approval | `approveNavigation()` called (prior guard); guard with `when=true` sees a navigation | No confirmation is raised; navigation proceeds |
| guard-011 | prevent-default | Guard armed; user clicks anchor | `e.preventDefault()` is called; other click handlers still execute; `e.stopPropagation()` is never called |
| guard-012 | prompt-anchor-navigation | Guard armed; a same-origin anchor click event already has `defaultPrevented === true` (e.g. another capture-phase listener intercepted it first) | `onClick` returns immediately; no confirm is raised by this guard |
| guard-013 | clear-sentinel-on-back | Primary guard armed; user presses Back (consumes sentinel); user confirms discard | The guard issues a real second `window.history.back()`; pressing Back again afterward does not re-trigger this guard's confirm (no stale sentinel remains armed at the prior URL) |
| guard-014 | update-sentinel-on-rearm | Secondary guard armed at URL A; primary guard disarms (unregisters) while this guard is still at URL A; membership-change subscription fires | This guard becomes primary and pushes a fresh same-URL history entry — `history.length` increases by one immediately after the disarm |
| guard-015 | guard-back-button | Primary and a non-primary guard both armed, both with popstate listeners; user presses browser Back | Only the primary's popstate handler proceeds past the primary check and consumes the sentinel; the non-primary's popstate handler returns early and raises no confirm |
| guard-016 | block-beforeunload | Confirm dialog open (anchor navigation pending); `when` transitions from true to false before the user responds | Effect cleanup removes the `beforeunload`/`popstate`/`click` listeners and unregisters from the registry; the alert stays open (`confirm` state is untouched) and the user's Discard/Stay choice still resolves normally |
| guard-017 | register-with-registry | A registry-awaited confirm is pending (`requestConfirm()`'s promise unresolved, e.g. from `router.push()` or a popstate) when a same-origin anchor is then clicked | `setConfirm` overwrites the pending state with the anchor's `{href}`; the earlier `resolve` is never called, so the earlier caller's awaited `confirmNavigation()` never settles |
| guard-018 | prompt-anchor-navigation | Guard armed; anchor has `target="_other"` | `onClick` returns early on the target check; browser opens in the specified target without a confirm |
| guard-019 | prompt-anchor-navigation | Guard armed; user Cmd-clicks (or Ctrl/Shift/Alt) a same-origin anchor | `onClick` returns early on the modifier-key check; browser opens the link in a new tab without a confirm |
| guard-020 | guard-back-button | Primary guard armed; user presses Back (sentinel consumed, confirm raised); user chooses Stay | `window.history.pushState` re-pushes a same-URL entry and the sentinel is set back to the current URL, so a second Back press is required to leave and re-raises the same confirm |

## Edge Cases

- **Navigation after mount disarm**: If `when` transitions from true to false before any navigation event fires, all listeners clean up and no state persists.
- **Multiple confirms pending**: A popstate fires while an anchor click's confirm is open. Only one confirm can be pending at a time; `setConfirm` overwrites the prior one. The prior resolver never fires — see **register-with-registry** for the caller-visible consequence.
- **Disarm mid-navigation**: If `when` becomes false while a confirm is displayed, cleanup removes the event listeners and unregisters from the registry, but it does not touch `confirm` state: the alert stays open and the user's eventual Discard/Stay choice still resolves and navigates or stays exactly as if `when` were still true.
- **Sentinel URL changes before re-arm**: Page navigates to a new URL while guard is still armed. The stored sentinel URL no longer matches `window.location.href`, so the next re-arm pushes a fresh sentinel.
- **beforeunload suppressed only by approval**: The `beforeunload` handler returns without prompting in exactly one case regardless of primary/non-primary status: `approvedRef.current` is true (this guard just approved its own exit) or `isNavigationApproved()` is true (module-scoped — another guard, or the calling app, called `approveNavigation()` for a just-completed save). With neither true, the handler always calls `preventDefault()`, per **block-beforeunload**.
- **Anchor with hash-only href change from current location**: Anchor href is `#section` when page is already at `/path?q=1#other`. Same pathname and search match; guard does not prompt.

## Configuration

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `when` | boolean | yes | — | Activates the guard; when true, navigation is blocked until approved or discarded |
| `onNavigate` | `(href: string) => void` | no | `window.location.assign` | Custom handler for confirmed anchor navigations; if not provided, uses full-page load |

## Deep Linking

Not applicable: The guard is a container component, not a route or page destination.

## Localization

Not applicable: The guard passes control to `UnsavedChangesAlert`, which handles localized confirmation strings.

## Accessibility Options

Not applicable: Accessibility concerns are delegated to `UnsavedChangesAlert` (keyboard focus, `aria` roles, dismissal by Escape key).

## Feature Flags

Not applicable: The guard's visibility and behavior are controlled by the parent component via the `when` prop.

## Analytics

Not applicable: Analytics events (if any) are emitted by `UnsavedChangesAlert` when the user chooses discard or stay.

## Privacy

Not applicable: The guard stores no user data, collects no analytics, and transmits no information.

## Logging

Not applicable: Internal state changes (confirm pending, approval flag, sentinel URL) are not logged; they are private to the component.

## Platform Notes

- **SwiftUI**: The primary mechanism is `.interactiveDismissDisabled(_:)` to block a sheet's swipe-to-dismiss while dirty, paired with a confirmation `.alert` before the caller actually calls `dismiss()`; a `presentationDetents` sheet composes the same way. For push navigation, `navigationDestination` cannot itself intercept a pop — bind the `NavigationStack`'s `NavigationPath` and wrap its setter to raise the confirm before mutating the path. There is no `beforeunload` equivalent, and `scenePhase` cannot block app exit — rely on autosave rather than trying to veto termination.
- **Compose**: The primary mechanism is `BackHandler` (`androidx.activity.compose`), registered conditionally on the `when` flag, to intercept the system Back gesture/button and raise the confirm before calling through to the real back action. For programmatic navigation, wrap the `NavController`/destination with the same registry pattern: a `CompositionLocal` holding the currently-armed guard(s), following the same primary/coalesce rule. `onPause` and other lifecycle callbacks cannot block process death or app exit — there is no `beforeunload` equivalent; rely on autosave.
- **React/Web**: Source implementation in `packages/web/packages/ui/src/components/unsaved-changes-guard.tsx`. The component listens to `beforeunload`, intercepts anchor clicks via a document capture-phase listener, and manages browser history via `pushState` for Back button interception. See `lib/navigation-guard.ts` for the registry pattern that coalesces multiple guards into one primary.
- **AppKit / UIKit**: The primary mechanism on AppKit is `NSDocument.isDocumentEdited` paired with `NSWindowDelegate.windowShouldClose(_:)`, which can synchronously refuse the close and present the confirmation itself — no polling or event interception needed. On UIKit, guard a modal's swipe-to-dismiss with `isModalInPresentation` (or `interactiveDismissDisabled` in a hosted SwiftUI sheet) and confirm in `presentationControllerShouldDismiss(_:)`. For a `WKWebView`, `webView:decidePolicyForNavigationAction:` intercepts navigation the way the web listener does. Back/Forward stacks are app-owned here, so guarding is just calling the confirm before popping.
- **WinUI 3**: Intercept in-app navigation via `Frame.Navigating` (set `NavigatingCancelEventArgs.Cancel = true` to block) — not `Frame.NavigationFailed`, which fires only on navigation errors and cannot block anything. Guard window/app close via `AppWindow.Closing` (set `AppWindowClosingEventArgs.Cancel = true`). For `WebView2` content, attach to `CoreWebView2.NavigationStarting` (not `WebResourceRequested`, which is for resource-level interception) and set `args.Cancel = true`. `SystemNavigationManager.BackRequested` is UWP-only with no WinUI 3 equivalent; guard the Back button by handling the app's own back-navigation command instead.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/unsaved-changes-guard.tsx` | unverified |

## Design Decisions

- **Decision**: Track the Back-button interposer by the URL a sentinel history entry was pushed for, rather than a boolean "already armed" flag.
  **Rationale**: A long-lived mount (an app shell that outlives many routes) must not stack a second sentinel when re-arming at a URL it has already armed — that would cost the user two Back presses — but must push a fresh one at a URL it has not armed yet.
  **Approved**: pending

- **Decision**: Cap the guard's self-approval window (`approveBriefly`) at 1000ms, matching the registry's `approveNavigation(windowMs = 1000)` default.
  **Rationale**: The window has to stay open long enough to cover the `beforeunload`/`popstate` it is approving (both fire synchronously or near-synchronously), but expire quickly enough that if the navigation turns out to be a client-side `router.push()` with no unload, the page stays mounted, dirty, and re-armed well before the window would matter again. The value is a fixed constant in this component; `approveNavigation()`'s exported `windowMs` parameter lets a caller override it for the save-then-leave case.
  **Approved**: pending

- **Decision**: Multiple guards may be armed at once (e.g. a root layout mounting a settings-panel guard alongside a page-level guard). Only the primary answers `confirmNavigation()`, so one navigation raises exactly one prompt.
  **Rationale**: The prompt is generic ("you have unsaved changes") and Discard means discard everything, so asking every armed guard would ask the same question repeatedly. Non-primary guards still block `beforeunload` (the browser coalesces those into one native prompt), and their click listeners bail once the primary's `preventDefault()` has run. If the primary disarms, the first still-registered guard takes over — registration order (the order each guard's mount effect called `registerNavigationGuard`), never creation or render order — matching **coalesce-multiple-guards**.
  **Approved**: pending

- **Decision**: Attach the click interceptor to `document` in the capture phase rather than to individual anchors.
  **Rationale**: A capture-phase listener runs before the framework router's own click handler, so it can `preventDefault()` first; the anchor's other handlers (menu close-on-select, analytics) still run because the guard never calls `stopPropagation()`. An anchor carrying `GUARDED_NAV_ATTR` is exempt — its own handler is responsible for calling `confirmNavigation()` itself.
  **Approved**: pending

- **Decision**: The confirm resolver returns `true` for Discard and `false` for Stay.
  **Rationale**: This gives both callers of `requestConfirm()` — the popstate handler and whoever awaits `confirmNavigation()` — a single boolean to act on: the popstate handler re-issues `window.history.back()` on `true` or re-pushes the sentinel on `false`.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Keyboard navigation and focus trapping for the confirmation dialog are delegated to `UnsavedChangesAlert`, which this source does not show, so those two checks are partial; `safe-defaults` passes because every guarded exit in this source — `beforeunload`, anchor clicks, popstate — blocks by default and only proceeds after an explicit user confirmation or an explicit `approveNavigation()` call. `separation-of-concerns` is partial because the registry itself lives apart in `lib/navigation-guard.ts`, but the click-interception, popstate, and sentinel state-machine logic sits inline in `UnsavedChangesGuard` rather than in an extracted hook; `unit-test-coverage` passes on `unsavedChangesGuard.test.tsx`'s exhaustive exercise of link interception, the registry, history/unload, sentinel tracking, and multi-guard arbitration.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case (fixing the `must-register-with-guide` typo); consolidated the anchor-intercept bail predicate into `prompt-anchor-navigation` and added an explicit no-`stopPropagation` constraint to `prevent-default`; fixed wrong test-vector citations, split guard-012, replaced two vectors' internal-state assertions with observable ones, and added five coverage vectors; corrected the WinUI 3 and SwiftUI/Compose platform notes and named AppKit/UIKit's native document- and dismissal-guard APIs; reformatted Design Decisions into Decision/Rationale/Approved, fixed the primary-guard takeover ordering to match `coalesce-multiple-guards`, and rewrote the 1000ms-window rationale; replaced the "Not applicable" Compliance section with a table; corrected the "Disarm mid-navigation" and "beforeunload" edge cases to match the source; added `unsaved-changes-alert` to `depends-on` and specified the registry contract (`GUARDED_NAV_ATTR`, `registerNavigationGuard`, `confirmNavigation`, `approveNavigation`) inline; replaced app-specific template examples with generic ones |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
