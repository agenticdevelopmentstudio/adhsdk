---
id: 4d2b7231-1235-49e9-8b7d-1e7507c6eba7
title: "Navigation Chrome (Bar + Drawer)"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Fixed navigation bar with burger menu, drawer, and keyboard-managed focus for responsive site navigation."
platforms:
  - typescript
  - web
tags:
  - navigation
  - drawer
  - responsive
  - keyboard-accessible
depends-on: []
related: []
references:
  - https://www.w3.org/WAI/ARIA/apg/patterns/dialogmodal/
approved-by: ""
approved-date: ""
---

# Navigation Chrome (Bar + Drawer)

## Overview

NavChrome is a mobile-first navigation chrome consisting of a fixed bar with a burger menu button, an optional brand/logo, a modal drawer containing navigation links, a scrim overlay, and comprehensive keyboard and focus management. The drawer is modal to both pointer and keyboard—Tab focus is trapped inside when open, Escape closes it, and focus is managed on open and close transitions. It supports smooth scrolling to same-page fragment anchors while moving focus to the target, and degrades gracefully for off-page links.

## Behavioral Requirements

- **render-bar**: Component MUST render a fixed bar containing a burger menu button and an optional brand container.
- **render-burger**: Component MUST render a button that opens the drawer, labeled via `openLabel` prop (default: 'Open menu'). The button only ever opens the drawer; it does not close it (see **drawer-toggle-controls**).
- **render-drawer**: Component MUST render a navigation drawer containing an array of anchor links passed via the `links` prop.
- **render-close-button**: Component MUST render a close button inside the drawer, labeled via `closeLabel` prop (default: 'Close menu').
- **render-scrim**: Component MUST render a scrim overlay that covers the page when the drawer is open.
- **render-optional-brand**: Component MUST render the `brand` prop content in the bar if provided; MUST NOT render a brand container if `brand` is undefined.
- **render-optional-footer**: Component MUST render the `footer` prop content in the drawer if provided; MUST NOT render a footer container if `footer` is undefined.
- **set-nav-label**: Component MUST set `aria-label` on the `<nav>` element to the `navLabel` prop (default: 'Site').
- **drawer-toggle-controls**: The burger button MUST only open the drawer (clicking it while the drawer is already open MUST have no effect — it does not close the drawer). The scrim, the drawer's close button, Escape, and clicking a navigation link MUST close the drawer when clicked/pressed while it is open. The close button sits in the same visual position the burger occupied, so closing reads as if the control itself changed, even though no single control both opens and closes.
- **close-on-link-click**: Component MUST close the drawer when any navigation link is clicked, regardless of whether the link resolves to a same-page fragment, an off-page URL, or no target at all.
- **trap-tab-inside-drawer**: While the drawer is open, Tab focus MUST stay inside it: pressing Tab on the last focusable element wraps focus to the first; pressing Shift+Tab on the first wraps focus to the last; and if focus is ever outside the drawer while it is open (for example, on the scrim), pressing Tab MUST bring focus back inside, to the first focusable element.
- **close-on-escape**: Component MUST close the drawer when the Escape key is pressed while the drawer is open.
- **return-focus-to-burger**: Component MUST return focus to the burger button when the drawer is closed, provided the drawer was previously open (not on initial render).
- **move-focus-to-close-button**: Component MUST move focus to the close button inside the drawer immediately after the drawer opens.
- **set-inert-when-closed**: Component MUST set the `inert` attribute on the drawer when it is closed, removing it when open.
- **dynamic-focusable-elements**: The set of focusable elements the drawer's Tab trap cycles through (buttons and links within the drawer) MUST reflect the current contents at the moment Tab is pressed — an element added or removed while the drawer is open MUST be included or excluded immediately, without requiring the drawer to close and reopen.
- **navigate-to-fragment-target**: Component MUST resolve a same-page fragment link (an `href` beginning with `#`) to the element with that id and, when found, scroll it into view.
- **move-focus-to-fragment-target**: Component MUST move focus to the target element after a same-page fragment scroll, using `tabindex="-1"` to make arbitrary elements focusable.
- **prevent-default-navigation-on-fragment-match**: When a same-page fragment link's target element is found, the component MUST prevent the browser's default anchor navigation and move focus to and scroll to the target itself; when no target is found (or the link is off-page), default navigation MUST proceed unimpeded. Smooth scrolling comes from `scroll-behavior: smooth`, which the host sets on its own `html` element.
- **handle-encoded-fragments**: Component MUST decode percent-encoded fragment IDs using `decodeURIComponent()`, and MUST gracefully handle malformed percent-encoding by falling back to the raw fragment.
- **fragment-focus-not-overridden-by-close-return**: When a fragment link click moves focus to the target element, the drawer's close→burger focus-return behavior MUST NOT subsequently move focus away from that target back to the burger button.
- **handle-empty-focusables**: Component MUST not throw an error if no focusable elements are found inside the drawer (e.g., if the links array is empty and no footer is provided).
- **aria-expand-burger**: Component MUST set `aria-expanded` on the burger button to `true` when the drawer is open, `false` when closed.
- **aria-hide-scrim**: Component MUST set `aria-hidden="true"` on the scrim.
- **use-button-type**: Component MUST render burger and close buttons with `type="button"` to prevent form submission.
- **support-custom-labels**: Component MUST accept `openLabel`, `closeLabel`, and `navLabel` props; MUST use default values ('Open menu', 'Close menu', 'Site') when props are undefined.
- **prevent-focus-steal-on-load**: Component MUST NOT move focus on the initial render.

## Appearance

NavChrome provides semantic structure and class names for styling; visual appearance is the responsibility of the host CSS.

- **Classes for styling**:
  - `.lp-bar`: The fixed navigation bar containing burger and optional brand
  - `.lp-burger`: The burger menu button (also used for the close button with `.lp-drawer-close`)
  - `.lp-brand`: Optional brand/logo container
  - `.lp-drawer`: The modal navigation drawer
  - `.lp-drawer--open`: Class added to drawer when open (modifier)
  - `.lp-drawer-close`: Close button inside the drawer (inherits `.lp-burger`)
  - `.lp-scrim`: The overlay covering the page (not focusable, `aria-hidden="true"`)
  - `.lp-scrim--show`: Class added to scrim when drawer is open (modifier)
  - `.lp-nav`: Navigation anchor links inside the drawer
  - `.lp-foot`: Optional footer content container

- **CSS Custom Properties**:
  - `--lp-chrome-top`: Allows the host to offset the entire chrome (bar, scrim, drawer) below a site header; the component references this but does not set it

## States

| State | Appearance change | aria-expanded | inert |
|-------|------------------|---|---|
| Drawer closed | `.lp-drawer` has no `.lp-drawer--open` class; `.lp-scrim` has no `.lp-scrim--show` class | `false` | `true` (drawer) |
| Drawer open | `.lp-drawer` has `.lp-drawer--open` class; `.lp-scrim` has `.lp-scrim--show` class | `true` | `false` (drawer) |

## Accessibility

- **Role**: The navigation bar is a `<div>` (not a `<header>` to avoid creating an unintended banner landmark when a host header already exists). The drawer is a `<nav>` with `aria-label={navLabel}`.
- **Labels**: Burger button labeled via `aria-label={openLabel}`. Close button labeled via `aria-label={closeLabel}`. Nav drawer labeled via `aria-label={navLabel}`.
- **Focus management**: Focus moves to the close button when the drawer opens. Focus returns to the burger button when the drawer closes (if it was previously open). Fragment link clicks move focus to the target element with `tabindex="-1"`.
- **Inert**: Drawer is `inert={true}` when closed, preventing keyboard and assistive technology access.
- **Tab trap**: Tab key is trapped inside the drawer when open; focus wraps from last to first and first to last, and is pulled back inside if it ever lands outside the drawer while open. See **trap-tab-inside-drawer**.
- **Escape key**: Escape closes the drawer, the standard dismissal gesture.
- **Scrim**: Scrim has `aria-hidden="true"` and is not focusable; it is a visual overlay for pointer users only.
- **Keyboard accessibility**: All navigation is keyboard-accessible: Escape exits the drawer, Tab and Shift+Tab wrap focus within it, and all links are reachable.
- **Link semantics**: Links are standard `<a>` elements with real `href` attributes, so they degrade gracefully without JavaScript.
- **Minimum touch target**: Component does not define a minimum tap target size; host CSS MUST ensure burger and close buttons meet platform requirements (44×44pt iOS, 48×48dp Android, etc.).
- **Modal pattern departure**: The drawer is modal to pointer and keyboard (tab-trapped, `inert` when closed), but it does not implement the full WAI-ARIA dialog-modal pattern this recipe cites for reference: there is no `role="dialog"`/`aria-modal="true"` on the drawer and no `aria-controls` on the burger button. Modality here is enforced procedurally (the tab trap plus `inert`) rather than declared through dialog semantics, which keeps the drawer a `<nav>` landmark rather than an unlabeled dialog; the cited pattern is followed for its focus-trap and Escape-to-dismiss behavior, not adopted as a literal `role="dialog"` implementation.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| nav-001 | render-bar | Render NavChrome with default props | Bar div with className 'lp-bar' contains a button with className 'lp-burger' |
| nav-002 | render-burger, aria-expand-burger | Render with drawer closed | Burger button has aria-expanded="false" |
| nav-003 | render-burger, aria-expand-burger | Click burger to open drawer | Burger button has aria-expanded="true" |
| nav-004 | drawer-toggle-controls | Render with drawer closed, click burger | Drawer className changes to include 'lp-drawer--open' |
| nav-005 | drawer-toggle-controls | Drawer open, click burger again | No-op: drawer className still includes 'lp-drawer--open' (the burger never closes the drawer) |
| nav-006 | render-scrim, drawer-toggle-controls | Render with drawer open, click scrim | Drawer closes and scrim className no longer includes 'lp-scrim--show' |
| nav-007 | render-optional-brand | Render with brand prop | Brand content appears in bar div with className 'lp-brand' |
| nav-008 | render-optional-brand | Render with brand undefined | No 'lp-brand' div is rendered |
| nav-009 | close-on-link-click | Drawer open, click a navigation link with same-page fragment href | Drawer closes |
| nav-010 | close-on-link-click | Drawer open, click a navigation link with off-page href | Drawer closes |
| nav-011 | navigate-to-fragment-target, prevent-default-navigation-on-fragment-match | Render with link href='#section1', click link | Browser default anchor navigation is prevented; target element is located by id |
| nav-012 | move-focus-to-fragment-target | Click link href='#section1' where section1 exists | Target element receives focus; tabindex="-1" is set on target |
| nav-013 | navigate-to-fragment-target | Render with link href='#section%20one' | fragmentId() correctly decodes percent-encoding and locates element by decoded id |
| nav-014 | handle-encoded-fragments | Render with link href='#%XX' (malformed percent) | fragmentId() catches decodeURIComponent error and uses raw fragment |
| nav-015 | trap-tab-inside-drawer | Drawer open with 3 focusable elements, Tab from last element | Focus wraps to first element |
| nav-016 | trap-tab-inside-drawer | Drawer open, Shift+Tab from first element | Focus wraps to last element |
| nav-017 | trap-tab-inside-drawer | Drawer open, focus moved to the scrim (outside the drawer), press Tab | preventDefault() is called and focus moves to the first focusable element inside the drawer |
| nav-018 | close-on-escape | Drawer open, press Escape key | Drawer closes |
| nav-019 | move-focus-to-close-button | Drawer closed, click burger to open | Close button has focus immediately after open |
| nav-020 | return-focus-to-burger, drawer-toggle-controls | Drawer open, click close button or Escape to close | Focus returns to burger button |
| nav-021 | prevent-focus-steal-on-load | Render page with NavChrome | No element receives unwanted focus on initial render |
| nav-022 | set-inert-when-closed | Drawer closed | Drawer has inert={true} |
| nav-023 | set-inert-when-closed | Drawer open | Drawer has inert={false} |
| nav-024 | render-optional-footer | Render with footer prop | Footer content appears in drawer with className 'lp-foot' |
| nav-025 | render-optional-footer | Render with footer undefined | No 'lp-foot' div is rendered |
| nav-026 | set-nav-label | Render with navLabel='Main Navigation' | Nav has aria-label='Main Navigation' |
| nav-027 | dynamic-focusable-elements | Drawer open, modify focusable elements, press Tab | New focusable elements are included in Tab trap calculation |
| nav-028 | handle-empty-focusables | Render with empty links array and no footer, drawer open | Tab key does not throw error; trap simply has no elements to cycle |
| nav-029 | close-on-link-click | Click link href='/other-page' | Drawer closes; browser navigates to off-page URL |
| nav-030 | aria-hide-scrim | Drawer open | Scrim has aria-hidden="true" |
| nav-031 | fragment-focus-not-overridden-by-close-return | Drawer open, click link href='#section1' (section1 exists) | Focus moves to and stays on #section1; it is not subsequently returned to the burger button by the close→burger focus-return behavior |
| nav-032 | render-drawer | Render with links=[{ href: '#a', label: 'A' }] | Drawer (`.lp-drawer`) contains an `<a>` with text 'A' and href '#a' |

## Edge Cases

- **Bare fragment (#)**: A link with href='#' or an empty href. fragmentId() returns null, and go() allows the browser to handle it (scroll to top). The drawer still closes.
- **Non-existent fragment**: A link with href='#missing-section' where no element has id='missing-section'. fragmentId() returns 'missing-section', getElementById() returns null, go() does not navigate but still closes the drawer and allows the browser to attempt the navigation.
- **Off-page link**: A link with href='/other-page' or 'https://example.com'. fragmentId() returns null (does not start with '#'), go() closes the drawer unconditionally, and allows the browser to navigate.
- **Malformed percent-encoding**: A link with href='#bad%ZZ'. decodeURIComponent() throws, fragmentId() catches and returns the raw fragment 'bad%ZZ'.
- **Empty links array**: No navigation links provided. Drawer renders with only the close button and optional footer. Tab trap works correctly with remaining focusables.
- **No footer**: Footer prop is undefined. Footer container is not rendered.
- **No brand**: Brand prop is undefined. Brand container is not rendered.
- **Focus outside drawer while open**: A click on the scrim or elsewhere that moves focus outside the drawer; the next Tab press pulls focus back into the drawer via the trap.
- **Escape key on page with no drawer**: Escape listener is only attached when drawer is open (useEffect dependency), so no interference with other page Escape handlers.
- **Tab press with no focusable elements**: If focusable array is empty (e.g., no links, no footer, close button is somehow hidden), Tab does nothing and focus does not move.
- **Browser autofocus behavior**: The drawer is rendered off-screen with a transform (delegated to host CSS) and `inert={true}` when closed, preventing browser autofocus from reaching elements inside.
- **Very long page with many focusable elements**: All focusables are queried from the DOM every Tab press, not cached, so new or removed focusables are reflected immediately.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `brand` | `ReactElement \| undefined` | `undefined` | Optional content to render in the bar (e.g., logo, wordmark) |
| `links` | `Array<{ href: string; label: string }>` | required | Array of navigation links; each has `href` (same-page fragment or URL) and `label` (link text) |
| `footer` | `ReactElement \| undefined` | `undefined` | Optional content to render in the drawer footer |
| `openLabel` | `string` | `'Open menu'` | aria-label for the burger button |
| `closeLabel` | `string` | `'Close menu'` | aria-label for the close button |
| `navLabel` | `string` | `'Site'` | aria-label for the nav drawer |

## Deep Linking

| Platform | Pattern | Behavior |
|----------|---------|----------|
| Web | `/#section-id` | Drawer closes; same-page fragment is targeted by id lookup, focus moves to target, scroll-behavior is smooth (set on host html element) |
| Web | `#encoded%20id` | Drawer closes; fragment is percent-decoded before id lookup |
| Web | `/other-page` | Drawer closes; browser navigates to URL (off-page link) |

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `openLabel` | `'Open menu'` | Burger button aria-label |
| `closeLabel` | `'Close menu'` | Close button inside drawer aria-label |
| `navLabel` | `'Site'` | Navigation drawer aria-label |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The component itself performs no animation, but its behavior drives two host-controlled motion effects: the drawer's open/close transition (triggered by the `.lp-drawer--open` class) and the smooth scroll on fragment navigation (`scroll-behavior: smooth` on the host's `html`). Host CSS MUST honor `prefers-reduced-motion` by disabling or reducing both, e.g. `@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto } .lp-drawer { transition: none } }`. |
| Increase Contrast | Not applicable: styling is the responsibility of host CSS; component provides only class names and semantic elements. |
| Differentiate Without Color | Not applicable: component uses no color to convey state; state is conveyed through aria-expanded, aria-hidden, and class name changes that are styled by the host. |

## Feature Flags

Not applicable: Feature flags are not implemented in source. The component is always enabled and has no feature flag configuration.

## Analytics

Not applicable: Analytics events are not implemented in source. The component provides no built-in analytics instrumentation. Host applications may attach click listeners or track navigation links independently.

## Privacy

**Data collected**: No data is collected by the component itself. The component stores only internal state (drawer open/closed) in React component state.

**Storage**: No data is persisted.

**Transmission**: No data is transmitted.

**Retention**: No data is retained. State is lost on page reload.

## Logging

Not applicable: Logging is not implemented in source. The component provides no built-in logging instrumentation.

## Platform Notes

- **TypeScript/React**: NavChrome is a React functional component in `packages/web/packages/landing/src/chrome/NavChrome.tsx`. It uses `useState` for drawer open state, `useRef` for element references to manage focus, and `useEffect` hooks for focus management and keyboard event listeners. The component returns JSX with semantic HTML (`<nav>`, `<button>`, `<a>`) and relies on host CSS for all styling via class names (`.lp-bar`, `.lp-burger`, `.lp-drawer`, `.lp-scrim`, etc.).

- **SwiftUI**: SwiftUI has no drawer/scrim primitive to reach for directly, but `NavigationSplitView` gives a comparable off-canvas panel (its sidebar column) and should be preferred over a hand-rolled overlay when that layout fits. Where a true overlay-style drawer is required, use a `ZStack` with a semi-transparent `Color` as the scrim (dismissible via `.onTapGesture`) and a sliding panel driven by `@State`, transitioning with `.transition(.move(edge: .leading))`. Keyboard handling (for keyboard-attached iPad/Mac use) uses `.onKeyPress(.tab)` and `.onKeyPress(.escape)` — not `.onReceive(publisher)`, which observes Combine publishers rather than key events, and `NavigationView` is deprecated in favor of `NavigationStack`/`NavigationSplitView`. Focus uses `@FocusState` and `.focusable()`; the Tab trap is expressed as a computed `@FocusState` binding that resets to the first/last focusable identifier, mirroring the explicit focus restoration this recipe requires.

- **Compose**: Material 3's `ModalNavigationDrawer` (with `DrawerState`/`rememberDrawerState`) is the native fit for this pattern — it already provides the scrim, dismiss-on-scrim-tap, and slide animation, so prefer it over `ModalDrawer`, which is Material 2 and deprecated. State is tracked via `DrawerState`/`mutableStateOf()`. Keyboard handling uses `Modifier.onPreviewKeyEvent { }` intercepting `Key.Escape` and `Key.Tab` — not `KeyboardOptions`, which configures software-keyboard behavior for text input rather than handling key events. Focus management uses `FocusRequester` to move focus to the close affordance on open and back to the burger on close; Tab trapping queries the focusable descendants of the drawer content and wraps focus manually, since Compose has no built-in trap.

- **AppKit / UIKit**: `UIButton` for the burger and close buttons, a scroll view or `UITableViewController` for the drawer content, and a `UIView` with a tap gesture recognizer for the scrim. State is tracked via a property. On iPadOS (and any environment with `UIFocusSystem`, i.e. keyboard/trackpad input or Apple TV remote), Tab focus cycling is real and governed by `UIFocusEnvironment`/`UIFocusGuide` — a focus guide can constrain Tab to the drawer while it is open, mirroring the trap. `setNeedsFocus()` is tvOS-only for retriggering the focus engine; to move focus programmatically elsewhere, use `becomeFirstResponder()` (UIKit) or update `preferredFocusEnvironments` (tvOS/iPadOS focus engine). Dismiss is typically by gesture (swipe) or the close button; VoiceOver users reach it via the accessibility rotor and standard swipe navigation.

- **WinUI 3**: `NavigationView` with `PaneDisplayMode="LeftMinimal"` is the native fit — it already renders the hamburger button, the off-canvas pane, and light-dismiss behavior, so prefer it over assembling a `SplitView` by hand. If finer control is needed, `SplitView` with `DisplayMode="Overlay"` and `SplitView.IsPaneOpen` (not a plain `IsOpen` property) is the lower-level building block; its `Pane` is the drawer and its own light-dismiss covers the scrim. Escape and Tab are handled via a `KeyDown` handler on the pane content; Tab trapping cycles focus among the pane's focusable children via `FocusManager.TryMoveFocus` within the pane's `XamlRoot`. Transitions use the control's built-in animation rather than manual `Storyboard`/`Composition` work.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/chrome/NavChrome.tsx` | unverified |

## Design Decisions

**Tab trap listens on `document`, not the drawer**

**Decision**: The keyboard event listener for Tab and Escape is attached to `document`, not to the drawer element itself.
**Rationale**: This ensures Tab is caught even when focus has escaped the drawer (for example, via a stray click on the scrim). A listener on the drawer alone would miss those cases and let Tab move focus outside the drawer.
**Approved**: pending

**`inert` on the closed drawer**

**Decision**: The drawer is marked `inert={true}` when closed.
**Rationale**: This removes all closed-drawer elements from the accessibility tree and tab order, preventing keyboard and screen reader users from reaching them. It is more comprehensive than `tabIndex={-1}` alone, which would hide the drawer from Tab but not from assistive technology.
**Approved**: pending

**`wasOpen` gates focus return**

**Decision**: A ref (`wasOpen`) records whether the drawer has previously been open, and the focus-return effect only returns focus to the burger button when that ref is `true`.
**Rationale**: React runs effects after the initial render too, so without this gate the focus-return effect's "drawer is closed" branch would fire on mount and move focus to the burger button the user has not yet interacted with. `wasOpen` starts `false` and is only set once the drawer has actually been opened, so the gate is a no-op on mount and only fires after a real open→close transition.
**Approved**: pending

**Fragment targets resolved with `getElementById`, not `querySelector`**

**Decision**: Fragment targets are looked up with `document.getElementById(id)` rather than `document.querySelector('#' + id)`.
**Rationale**: An HTML `id` can legally contain characters that are invalid or require escaping in CSS selector syntax — for example, one that starts with a digit (`2024-results`) or contains a colon or dot. `querySelector` would throw a `SyntaxError` on such ids unless manually escaped, whereas `getElementById` takes the raw string and simply returns `null` when nothing matches, letting the fallback path run instead of throwing. (A `mailto:` link never reaches this lookup at all — `fragmentId()` only looks at hrefs that start with `#`.)
**Approved**: pending

**Smooth scrolling is the host's CSS, not the component's**

**Decision**: The host sets `scroll-behavior: smooth` on its own `html` element; the component does not set it anywhere.
**Rationale**: This lets the host control scroll behavior globally, so smooth scrolling works the same way whether a fragment link is clicked from the drawer or anywhere else on the page. The component's only job is to call `scrollIntoView()` on the resolved target and move focus to it.
**Approved**: pending

**Drawer positioning via CSS transform, not JavaScript**

**Decision**: The drawer is positioned off-screen and on-screen by the host's `.lp-drawer` / `.lp-drawer--open` CSS rules, not moved by JavaScript.
**Rationale**: This keeps the animation in CSS and lets the host use transitions or media queries to adjust positioning for different screen sizes without touching the component.
**Approved**: pending

**Burger and close buttons share a class**

**Decision**: Both the burger and the close button use the `.lp-burger` class, with `.lp-drawer-close` added to the close button.
**Rationale**: This allows shared styling for button dimensions and appearance, with additional rules in `chrome.css` for the close button's X-icon transformation via `.lp-drawer-close`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Passed statuses rest on the source's explicit `aria-label`/`aria-expanded`/`aria-hidden`/`inert` attributes, its Tab-trap/Escape/focus-management effects, its `decodeURIComponent`-based fragment decoding, and its prop-driven default labels (documented in Localization above, so callers can override them); partial statuses reflect that visual styling (color, spacing, font, motion easing), RTL layout, and href content validation are left entirely to host CSS and host-supplied data, which the source neither constrains nor can attest to on its own. `separation-of-concerns` is partial: the fragment-id parser (`fragmentId`) is extracted as a standalone pure function, but the open/close state, focus trap, and Escape/link-close handling all live inline in the one `NavChrome` component (a deliberate choice — see the Overview's "share one `open` boolean" note — not an extraction into hooks). `unit-test-coverage` is partial: `nav-chrome.test.tsx` covers open/close-on-link, focus movement, and off-page-link focus return, but has no case for clicking the burger while the drawer is already open, which is exactly the behavior this revision corrects (**drawer-toggle-controls**, nav-005).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: merged duplicate requirements into drawer-toggle-controls, close-on-link-click, and trap-tab-inside-drawer; rewrote implementation-coupled requirements as observable, platform-neutral behavior; renamed all requirements to subject-only kebab-case; fixed the toggle/close ambiguity and three contradictions (fragment default-navigation, scroll-behavior ownership, Shift+Tab exit claim); reformatted Design Decisions to Decision/Rationale/Approved and corrected two decisions' rationale; added a Compliance table; corrected Platform Notes APIs and pointed each port at its native drawer control; fixed dangling and mis-scoped test-vector references and added two missing vectors; retitled the recipe; documented the drawer's intentional departure from the full ARIA dialog-modal pattern |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Burger only opens the drawer (never closes); nav-005 corrected to no-op. |
