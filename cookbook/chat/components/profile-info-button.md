---
id: 995da39d-685d-4e28-a572-e6425eace958
title: "ProfileInfoButton"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Small circled i link on the chat frame's top-left corner that opens the persona's profile page in a new tab."
platforms:
  - typescript
  - web
tags:
  - persona
  - profile
  - link
  - chat
depends-on: []
related:
  - f8e3d2a1-4c9b-4d7e-8f2b-a5c3e7b1d4f6
references: []
approved-by: ""
approved-date: ""
---

# ProfileInfoButton

## Overview

ProfileInfoButton is a small circled "i" that sits on the chat frame's top border, just past the rounded top-left corner, and links to the persona's profile (for example its Agentic Persona Registry page). It is a plain link, not a button: it navigates, it holds no state, and it opens the profile in a new tab.

The host renders it as a sibling of the chat view, inside the host's `position: relative` wrapper. It is not rendered inside the `.persona-chat` element, because the component's own comment says that element's `overflow: hidden` would clip the half of the circle that hangs over the top edge (`base.css` sets `.persona-chat` to `overflow: visible`, while modes such as `.pc-mobile-overlay` set it to `hidden`). The host also imports the opt-in stylesheet `css/components/profile-info.css` (`BitbagChat` documents importing it as `css/chat/components/profile-info.css` from `@adh-sdk/persona`, which re-imports the chat package's file); the component ships no styling of its own. Colors come from the chat theme's own tokens, so the button reads as part of whichever theme the chat wears. It is exported from the chat package together with its `ProfileInfoButtonProps` type, and `BitbagChat` renders it only when it has a profile URL.

Inputs:

| Prop | Type | Required | Meaning |
|------|------|----------|---------|
| `profileUrl` | string | yes | The persona's profile URL; opens in a new tab. |
| `label` | string | yes | Accessible name and hover tooltip (for example "olylo's profile"). |
| `className` | string | no | Extra class name appended after the component's own class. |

## Behavioral Requirements

- **link-destination**: The component MUST render a hyperlink whose destination is the `profileUrl` value.
- **new-tab**: The component MUST open its destination in a new browsing context (`target="_blank"`).
- **opener-isolation**: The component MUST set the link relationship to `noopener noreferrer`, so the opened page gets no reference to the opening page and no referrer.
- **accessible-name**: The component MUST expose the `label` value as the link's accessible name (`aria-label`).
- **tooltip**: The component MUST expose the `label` value as the hover tooltip (`title`).
- **glyph**: The component MUST display the single lowercase character "i" as its only visible content.
- **glyph-hidden**: The component MUST mark the glyph element as hidden from assistive technology (`aria-hidden="true"`), so the label is the only name announced.
- **root-class**: The component MUST put the class `pc-profile-info` on its root element; the stylesheet selects on it.
- **extra-class**: The component MUST append `className`, separated by one space, after `pc-profile-info`, and MUST omit it when it is undefined or empty.
- **placement**: The stylesheet MUST position the button absolutely at `top: 0` and at a horizontal offset of `--pc-pi-inset` (default 21px) from the wrapper's left edge, translated by minus 50% on both axes, so the circle's center sits on the frame's top border.
- **size**: The stylesheet MUST declare the circle's `width` and `height` as `--pc-pi-size` (default 22px) with a 50% border radius and a 1px border; it sets no `box-sizing`, so the outer diameter is that size plus the border unless the host applies border-box sizing.
- **glyph-scale**: The stylesheet MUST set the glyph's font size to 0.6 times `--pc-pi-size`.
- **stacking**: The stylesheet MUST give the button `z-index: 2`.
- **opaque-face**: The stylesheet MUST fill the button with `--pc-surface` (fallback `#050805`), so it covers the frame border beneath it.
- **theme-tokens**: The stylesheet MUST take the border color from `--pc-input-border` (fallback `rgba(255, 255, 255, 0.35)`), the glyph color from `--pc-persona-text` (fallback `#d0d0d0`), and the font from `--pc-font-mono` (fallback `ui-monospace, monospace`).
- **hover-focus-highlight**: On hover and on keyboard focus (`:focus-visible`), the stylesheet MUST change the border color to the current text color and add a 6px glow of that color at 45% strength, with the browser's default outline removed.
- **highlight-transition**: The stylesheet SHOULD animate the border color and box shadow over 0.18s with an ease curve.
- **no-decoration**: The stylesheet MUST remove the link's text decoration.
- **memoized**: The component SHOULD skip re-rendering while its props are unchanged.
- **host-placement**: The host MUST render the button outside any ancestor that clips overflow within half of `--pc-pi-size` of the frame's top edge, and MUST import `css/components/profile-info.css`.

## Appearance

- **Corner radius**: 50% (a circle).
- **Padding**: none; the glyph is centered with `display: flex`, `align-items: center` and `justify-content: center`.
- **Font**: monospace from `--pc-font-mono`; size 0.6 times the circle diameter (13.2px at the default 22px); line height 1; the glyph is the lowercase letter "i".
- **Background**: `--pc-surface`, fallback `#050805`; opaque.
- **Foreground/Text**: `--pc-persona-text`, fallback `#d0d0d0`.
- **Border**: 1px solid `--pc-input-border`, fallback `rgba(255, 255, 255, 0.35)`; on hover and focus-visible, `currentColor`.
- **Shadow**: none at rest; on hover and focus-visible, `0 0 6px` of `currentColor` mixed to 45% with transparent.
- **Min/Max size**: no min or max; the diameter is `--pc-pi-size`, default 22px.
- **Position**: absolute, `top: 0`, `left: --pc-pi-inset` (default 21px, chosen to clear the rounded corner), centered on that point by `translate(-50%, -50%)`, so half the circle overhangs the top edge. `z-index: 2`.
- **Cursor**: pointer.
- **target-size**: NEEDS REVIEW: Not implemented in source. The default 22px square sets no larger hit area, and the source does not say whether that is acceptable; a decision against the platform touch-target minimums (WCAG 2.2 AA 24px, Apple 44pt, Material 48dp) would settle it.
- **contrast**: NEEDS REVIEW: Not implemented in source. The colors come from theme tokens and fixed fallbacks, and the source cannot say whether glyph-on-face and border-on-frame meet WCAG 2.1 contrast ratios (4.5:1 for text, 3:1 for the border) in every theme; a contrast audit of each chat theme's token values would settle it.

## States

| State | Appearance change |
|-------|------------------|
| Default | Circle with a 1px theme border, opaque face, theme text color, no shadow. |
| Hover | Border becomes the current text color and a 6px glow at 45% appears, over 0.18s. |
| Focused | Keyboard focus (`:focus-visible`) gets the same border and glow as hover; the default outline is removed, so the border and glow are the only focus indication. |
| Pressed | Not applicable: the stylesheet defines no `:active` rule, so a press looks like hover or focus. |
| Disabled | Not applicable: the component renders a link with no disabled prop or disabled style. |
| Loading | Not applicable: the component fetches nothing and has no async work. |

## Accessibility

- **Role/trait**: Link. The root is a native anchor with an `href`, so it is focusable and activated by Enter without extra code.
- **Label requirements**: `label` is required and becomes both `aria-label` and `title`; the visible "i" is hidden from assistive technology.
- **Keyboard**: Reachable with Tab in document order and activated with Enter, as for any anchor. Focus is shown by the border and glow described under States.
- **Announce state changes**: Not applicable: the component has no changing state. Activation opens a new tab; the source gives no cue that the link opens a new tab beyond the `label` the host supplies.
- **Minimum tap target**: see the open question on `target-size` under Appearance.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| profile-info-button-001 | link-destination | From `ProfileInfoButton.test.tsx` ("links to the profile in a new tab with the accessible label"): render with `profileUrl="https://registry.example/olylo"` and `label="olylo's profile"` | The link found by role "link" has `href` equal to `https://registry.example/olylo`. |
| profile-info-button-002 | new-tab, opener-isolation | Same render | The link has `target="_blank"` and `rel="noopener noreferrer"`. |
| profile-info-button-003 | accessible-name, tooltip | Same render | The link is found by role "link" with accessible name `olylo's profile`, and its `title` is `olylo's profile`. |
| profile-info-button-004 | root-class, glyph | Same render | The link has class `pc-profile-info` and its text content is `i`. |
| profile-info-button-005 | glyph-hidden | Same render | The only child is a span with `aria-hidden="true"` containing `i`. |
| profile-info-button-006 | extra-class | Render with `className="host-extra"` | The class attribute is `pc-profile-info host-extra`. |
| profile-info-button-007 | extra-class | Render without `className`, and again with `className=""` | The class attribute is exactly `pc-profile-info` in both cases, with no trailing space. |
| profile-info-button-008 | placement, size | Render in a `position: relative` wrapper with the stylesheet and no custom properties | The circle's declared width and height are 22px and its center is 21px from the wrapper's left edge and on its top edge. |
| profile-info-button-009 | placement, size, glyph-scale | Set `--pc-pi-size: 30px` and `--pc-pi-inset: 40px` on the wrapper | The circle's declared width and height are 30px, its center is 40px from the left edge, and the glyph font size is 18px. |
| profile-info-button-010 | theme-tokens, opaque-face | Render in a wrapper with none of the `--pc-*` tokens defined | Face `#050805`, glyph `#d0d0d0`, border `rgba(255, 255, 255, 0.35)`, font monospace. |
| profile-info-button-011 | hover-focus-highlight | Hover the button, then separately Tab to it | In both cases the border color equals the glyph color and a box shadow is present; no outline is drawn. |
| profile-info-button-012 | memoized | Re-render the host with identical `profileUrl`, `label` and `className` | The inner render function does not run again. |
| profile-info-button-013 | host-placement | Render the button inside `.persona-chat` (`overflow: hidden`) | The upper half of the circle is clipped, which is the failure the host must avoid. |
| profile-info-button-014 | link-destination | Render with `profileUrl=""` | An anchor is rendered with an empty `href`; the component does not hide itself (the host guard is what omits it). |

Vectors 001 to 007, 012 and 014 are asserted in `ProfileInfoButton.test.tsx`; 008 to 011 and 013 are `it.skip` there because jsdom cannot exercise stylesheet layout, `var()` fallbacks, `:hover`/`:focus-visible` or overflow clipping. `highlight-transition`, `no-decoration` and `stacking` have no vector because they are visual-only rules checked by inspection of the stylesheet.
## Edge Cases

- **Null and empty input**: An empty `profileUrl` renders an anchor with an empty `href`; the component has no guard, so it MUST NOT be relied on to hide itself. The host decides: `BitbagChat` renders the button only when `profileUrl` is truthy. An empty `label` renders an empty accessible name and tooltip, which the component does not prevent.
- **Boundary values**: `--pc-pi-size` scales the circle and the glyph together and the component does not clamp it. A `--pc-pi-inset` smaller than half the size pushes part of the circle past the frame's left edge, because nothing clamps it.
- **Concurrent access**: Not applicable: the component is a stateless render with no shared mutable state.
- **Error states**: The component makes no request. If the profile URL is unreachable, the failure appears in the new tab, not in this component.
- **Offline or disconnected state**: Not applicable: nothing is fetched while the component renders; only the newly opened tab needs a connection.
- **Overflow clipping**: If any ancestor within half of `--pc-pi-size` of the frame's top edge clips overflow, the overhanging half is cut off. The host MUST avoid this (see host-placement).
- **Streaming re-renders**: The host chat re-renders on every streamed token while this component's props stay static, so the component SHOULD stay memoized.
- **Unsafe URL schemes**: The component does not validate the URL scheme; it passes `profileUrl` to `href` unchanged, so the host MUST supply a trusted URL.
- **Theme tokens missing**: When the chat theme defines none of the `--pc-*` tokens, the stylesheet's dark-terminal fallbacks apply (see theme-tokens).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `profileUrl` | string | none (required) | Destination of the link; opens in a new tab. |
| `label` | string | none (required) | Accessible name and hover tooltip. |
| `className` | string | none | Extra class appended after `pc-profile-info`. |
| `--pc-pi-size` | CSS length | `22px` | Circle diameter; glyph font size is 0.6 times this. |
| `--pc-pi-inset` | CSS length | `21px` | Distance from the frame's left edge to the circle's center. |
| `--pc-surface` | CSS color | `#050805` | Face color (chat theme token). |
| `--pc-input-border` | CSS color | `rgba(255, 255, 255, 0.35)` | Border color at rest (chat theme token). |
| `--pc-persona-text` | CSS color | `#d0d0d0` | Glyph color (chat theme token). |
| `--pc-font-mono` | CSS font family | `ui-monospace, monospace` | Glyph font (chat theme token). |

## Deep Linking

Not applicable: the component is an outbound link to a URL the host supplies; it has no route of its own and is not a deep-link target.

## Localization

Not applicable: the component owns no strings. The accessible name and tooltip are the `label` prop the host supplies, and the visible "i" is a fixed glyph that is hidden from assistive technology.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the 0.18s border and glow transition is not gated on `prefers-reduced-motion`; the stylesheet has no media query for it. |
| Increase Contrast | Not applicable: the stylesheet has no `prefers-contrast` rule; colors come from theme tokens only. |
| Differentiate Without Color | Not applicable: the stylesheet has no rule for it; the button is identified by its circle shape and "i" glyph, and the hover and focus highlight is a border color change plus a glow. |

## Feature Flags

Not applicable: the component has no flag; the only conditional is the host's `profileUrl` check in `BitbagChat`.

## Analytics

Not applicable: the component emits no events and calls no analytics code.

## Privacy

- **Data collected**: None.
- **Storage**: None; the component keeps nothing.
- **Transmission**: The component transmits nothing itself. Following the link sends the browser to the profile URL, and `noreferrer` stops the opening page's URL from being sent as a referrer.
- **Retention**: Not applicable: nothing is stored.

## Logging

Not applicable: the component writes no log output.

## Platform Notes

- **SwiftUI**: Use a `Link` with a `URL` (it opens in the system browser, so there is no new-tab call) containing a `Text("i")` in a `Circle` background and overlay stroke. Set `.accessibilityLabel(label)` and hide the glyph with `.accessibilityHidden(true)`. On macOS add `.help(label)` for the tooltip. Overlay it on the chat frame with `.overlay(alignment: .topLeading)` and an offset of half its size, and keep the frame from clipping with no `.clipped()` on the container.
- **Compose**: Use a `Box` with `Modifier.size(22.dp).clip(CircleShape).background(surface).border(1.dp, border, CircleShape).clickable(role = Role.Button)` and a `Text("i")` inside. Open the URL with `LocalUriHandler.current.openUri(profileUrl)`. Put the label in `semantics { contentDescription = label }` on the Box and clear the inner text's semantics. Material's 48dp minimum target needs `minimumInteractiveComponentSize()` or a larger touch area around the 22dp visual. Position it with `Modifier.align(Alignment.TopStart).offset(...)` in the frame's `Box`.
- **React/Web**: `packages/web/packages/chat/src/components/ProfileInfoButton.tsx` is a memoized function component exported as a `NamedExoticComponent`; it renders an anchor with a hidden span. `packages/web/packages/chat/src/css/components/profile-info.css` holds all styling and is opt-in; `packages/web/packages/persona/src/styles/chat/components/profile-info.css` only re-imports it so consumers never name the SDK package. The component is re-exported from the chat package index with its props type, and `BitbagChat` is the reference host.
- **AppKit / UIKit**: On AppKit, subclass `NSButton` (borderless, circular layer, `NSTrackingArea` for the hover glow, `toolTip` set to the label) and open the URL with `NSWorkspace.shared.open`. On UIKit, use a `UIButton` with a circular layer, `accessibilityLabel` set to the label, and `UIApplication.shared.open` (or `SFSafariViewController`). Set `clipsToBounds = false` on the superview so the overhang shows, and use `UIPointerInteraction` for a hover effect on iPadOS. Keep a 44pt hit area by overriding `point(inside:with:)`.
- **WinUI 3**: Start from a `HyperlinkButton` with `NavigateUri` bound to the profile URL (it launches the default browser, the counterpart of `target="_blank"`) and restyle its `ControlTemplate`: a `Grid` of 22 by 22 with a `Border` using `CornerRadius="11"`, `BorderThickness="1"`, `Background` from a theme resource, and a centered `TextBlock Text="i"` with `FontFamily="Consolas"` and `FontSize="13"`. Set `AutomationProperties.Name` to the label and `ToolTipService.ToolTip` to the same string, and set `AutomationProperties.AccessibilityView="Raw"` on the inner `TextBlock` so only the label is read. Express hover and focus with `VisualStateManager` states `PointerOver` and `Focused` by setting the `Border`'s `BorderBrush` to the foreground brush and adding a glow with `ThemeShadow` or a `DropShadowPanel`; keep `UseSystemFocusVisuals="True"` or supply a `FocusVisualPrimaryBrush`, because the web version removes the default outline. For placement, put it in the same `Grid` as the chat frame with `HorizontalAlignment="Left"`, `VerticalAlignment="Top"`, a `TranslateTransform` of minus 11 on both axes and a left margin of 21; the parent must not set `Clip`, and a `ScrollViewer` ancestor would clip the overhang. A `HyperlinkButton` has a larger default minimum size than 22, so set `MinHeight` and `MinWidth` to 22, or enlarge the hit area with transparent padding.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/components/ProfileInfoButton.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Render a plain anchor with `target="_blank"` and `rel="noopener noreferrer"` instead of a button that calls `window.open`.
**Rationale**: The control navigates, so a link gets keyboard activation, middle-click, copy-link and status-bar URL from the browser. `noopener noreferrer` keeps the profile page from reaching back into the chat page and from receiving its URL.
**Approved**: pending

**Decision**: Hide the "i" glyph from assistive technology and put the name on `aria-label`, repeated in `title`.
**Rationale**: A lone letter would be announced as "i", which tells a screen reader user nothing; the label names the destination. `title` gives sighted pointer users the same text as a tooltip.
**Approved**: pending

**Decision**: Split the component and its stylesheet, and make the stylesheet opt-in, with `--pc-pi-size` and `--pc-pi-inset` as the only knobs.
**Rationale**: Hosts that do not show the button pay nothing for its CSS, and the two knobs are all a theme needs to resize it or move it clear of a differently rounded corner. Colors reuse the chat theme tokens so no theme needs button-specific colors.
**Approved**: pending

**Decision**: Position the button with absolute coordinates and a minus 50% translate, so half of it overhangs the frame's top edge, and render it outside `.persona-chat`.
**Rationale**: The overhang is what makes the button read as perched on the corner, and its opaque face hides the border beneath it. The cost, as the component's comment states, is that `.persona-chat` can be `overflow: hidden` (the mobile overlay mode sets it), which would clip the overhang, so the host must place the button as a sibling in the outer `position: relative` wrapper.
**Approved**: pending

**Decision**: Wrap the implementation in `memo` (SHOULD, not MUST).
**Rationale**: The host chat re-renders on every streamed token while this button's props never change after mount, so memoizing avoids that work. Skipping it is only a performance loss, not a behavior change, which is why it is a SHOULD.
**Approved**: pending

**Decision**: Replace the default outline with a border color change and glow on hover and `:focus-visible`, and keep the 0.18s transition (SHOULD).
**Rationale**: The source gives hover and keyboard focus the same highlight, which suits the circular shape better than a rectangular outline. The transition is cosmetic, so an implementation may drop it. Whether the glow is a sufficient focus indicator is an open question and is not settled here.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`screen-reader-support`, `keyboard-navigable` and `semantic-markup` pass because the root is a native anchor with an `href`, an `aria-label`, and an `aria-hidden` glyph. `touch-target-size` is partial because the visible circle is 22px by default and the source adds no larger hit area. `separation-of-concerns` passes because the component holds only markup and a class name, and all styling lives in a separate opt-in stylesheet. `unit-test-coverage` is partial because `ProfileInfoButton.test.tsx` covers vectors 001 to 007, 012 and 014, while 008 to 011 (placement, size, theme tokens, hover and focus highlight) and 013 (overflow clipping) are skipped: they depend on real layout, `var()` resolution and pseudo-class styling that jsdom does not provide.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (ProfileInfoButton.test.tsx, 14 of 14 vectors, 5 skipped for jsdom limits); unit-test-coverage now partial. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
