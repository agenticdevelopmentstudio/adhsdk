---
id: a7e2f9d1-4c8a-4b9e-8f3d-2c5b7e1a9d4f
title: "Inline Disclosure"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Inline, non-floating disclosure component that toggles visibility of supplemental content (title, description, and optional links) in place."
platforms:
  - typescript
  - web
tags:
  - disclosure
  - popover
  - collapsible
depends-on: []
related:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
references:
  - https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/
  - https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel/noopener
approved-by: ""
approved-date: ""
---

# Inline Disclosure

## Overview

Inline Disclosure is a collapsible control that toggles the visibility of supplemental content in place, without floating or overlaying other content — unlike the separate `@adh-sdk/popover` package (see Related), which positions an overlay relative to a trigger. It renders a toggle button with an optional arrow indicator and title, followed by a body section containing optional description text and a collection of links. The component maintains open/closed state internally and allows users to toggle visibility by clicking the toggle button.

## Behavioral Requirements

- **render-toggle-button**: Component MUST render a clickable button element with aria-label="Toggle details".
- **toggle-visibility-on-click**: Component MUST toggle the open state when the toggle button is clicked.
- **initialize-with-default-open**: Component MUST initialize with the open state set to the value of the `defaultOpen` prop, which defaults to `true`.
- **render-title-when-provided**: Component MUST render the title text from `data.title` only if the property is truthy.
- **render-arrow-indicator**: Component MUST render an arrow span element as a visual indicator within the toggle button.
- **render-description-when-provided**: Component MUST render the description from `data.description` only if the property is truthy.
- **render-links-collection**: Component MUST render the links collection from `data.links` only if the property is truthy and has length greater than 0.
- **render-each-link-with-label**: Component MUST render each link with either its `label` property or fall back to its `url` property as the displayed text.
- **open-links-in-new-tab**: Component MUST open links in a new browser tab by setting `target="_blank"` and `rel="noopener noreferrer"` on each link element.
- **set-aria-hidden-attribute**: Component MUST set `aria-hidden="true"` on the root element when open state is `false` and `aria-hidden="false"` when open state is `true`.
- **add-open-class-when-open**: Component MUST add the CSS class `pc-popover-open` to the root element when the open state is `true`.

## Appearance

- **Root container**: Rendered as a `div` with class `pc-popover`, conditionally includes `pc-popover-open` class
- **Toggle button**: Rendered as a `button` element with class `pc-popover-toggle`
- **Arrow indicator**: Rendered as a `span` element with class `pc-popover-arrow`
- **Title**: Rendered as a `span` element with class `pc-popover-title`, optional
- **Body container**: Rendered as a `div` element with class `pc-popover-body`
- **Description**: Rendered as a `div` element with class `pc-popover-desc`, optional
- **Links container**: Rendered as a `div` element with class `pc-popover-links`, optional
- **Individual link**: Rendered as an `a` element with class `pc-popover-link`

All visual styling (colors, spacing, sizing, shadows, hover states, transitions) is controlled via CSS classes. The component itself does not define appearance values.

## States

| State | Appearance change | Trigger |
|-------|------------------|---------|
| Open | `pc-popover-open` class added, `aria-hidden="false"` | User clicks toggle button or `defaultOpen` is `true` |
| Closed | `pc-popover-open` class removed, `aria-hidden="true"` | User clicks toggle button or `defaultOpen` is `false` |

## Accessibility

- **Toggle button role**: The toggle button element is a native `button`, which provides standard keyboard and screen reader semantics.
- **Toggle button label**: The toggle button MUST have `aria-label="Toggle details"` to communicate its purpose to assistive technology.
- **Root visibility**: The root element MUST use `aria-hidden` to communicate to screen readers whether the disclosure content is visible. When `aria-hidden="true"`, the content is hidden from assistive technology; when `aria-hidden="false"`, it is exposed.
- **Link text**: Each link element's text content is provided by the `label` property or falls back to the `url`, ensuring all interactive elements have accessible text.
- **Minimum touch target**: Ensure the toggle button meets platform-specific minimum touch target size requirements (44×44pt on iOS, 48×48dp on Android, 44×44px on web).
- **Root aria-hidden also hides the toggle button**: `aria-hidden` is set on the root element, which contains the toggle button, so when closed the toggle button itself is removed from the accessibility tree along with the body. A screen reader user cannot reach the button to reopen the content. See **Compliance**.
- **Fixed aria-label overrides the visible title**: The toggle button's accessible name is the static string `aria-label="Toggle details"` regardless of `data.title`, so when a title is rendered its visible text is not part of the accessible name, which fails WCAG 2.5.3 Label in Name. The arrow indicator `span` also carries no `aria-hidden`, so it is not explicitly excluded from the accessibility tree. See **Compliance**.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| inline-popover-001 | initialize-with-default-open, set-aria-hidden-attribute | `defaultOpen={true}` | Component renders with `pc-popover-open` class on root and `aria-hidden="false"` |
| inline-popover-002 | initialize-with-default-open, set-aria-hidden-attribute | `defaultOpen={false}` | Component renders without `pc-popover-open` class and `aria-hidden="true"` |
| inline-popover-003 | toggle-visibility-on-click, set-aria-hidden-attribute | User clicks toggle button when open | Component renders with `aria-hidden="true"` and `pc-popover-open` class removed |
| inline-popover-004 | toggle-visibility-on-click, set-aria-hidden-attribute | User clicks toggle button when closed | Component renders with `aria-hidden="false"` and `pc-popover-open` class added |
| inline-popover-005 | render-title-when-provided | `data={{ title: "Test Title" }}` | Title text appears in a `span` with class `pc-popover-title` |
| inline-popover-006 | render-title-when-provided | `data={{ title: "" }}` (`title` is a required `string` on `PopoverData`; an empty string is falsy but still type-valid) | No title element is rendered |
| inline-popover-007 | render-description-when-provided | `data={{ title: "T", description: "Test Description" }}` | Description text appears in a `div` with class `pc-popover-desc` |
| inline-popover-008 | render-description-when-provided | `data={{ title: "T", description: undefined }}` | No description element is rendered |
| inline-popover-009 | render-links-collection | `data={{ title: "T", links: [{ url: "https://example.com", label: "Example" }] }}` | Links container div is rendered with class `pc-popover-links` containing one link element |
| inline-popover-010 | render-links-collection | `data={{ title: "T", links: [] }}` or `data={{ title: "T", links: undefined }}` | No links container is rendered |
| inline-popover-011 | render-each-link-with-label | `data={{ title: "T", links: [{ url: "https://example.com", label: "Click here" }] }}` | Link element displays text "Click here" |
| inline-popover-012 | render-each-link-with-label | `data={{ title: "T", links: [{ url: "https://example.com", label: "" }] }}` (`label` is a required `string` per link; an empty string is falsy but still type-valid) | Link element displays text "https://example.com" as fallback |
| inline-popover-013 | open-links-in-new-tab | `data={{ title: "T", links: [{ url: "https://example.com", label: "" }] }}` | Link element has `target="_blank"` and `rel="noopener noreferrer"` attributes |
| inline-popover-014 | render-arrow-indicator | Any valid data | Arrow span element with class `pc-popover-arrow` is always present in toggle button |
| inline-popover-015 | toggle-visibility-on-click | Toggle button has focus; user presses Enter or Space | Native `button` semantics activate the click handler; open state toggles the same as a mouse click |
| inline-popover-016 | initialize-with-default-open | `defaultOpen` prop omitted | Component initializes open (`pc-popover-open` class present, `aria-hidden="false"`), matching the `defaultOpen = true` default |

## Edge Cases

- **Empty data object**: When `data` is passed as an empty object `{}`, no title, description, or links are rendered. The component still renders the toggle button and body container. Expected behavior: component renders with button and empty body.
- **Null or undefined data properties**: When `data.title`, `data.description`, or `data.links` are null, undefined, or empty string, those content sections are not rendered. Expected behavior: component skips rendering that section.
- **Empty links array**: When `data.links` is an empty array `[]`, the links container div is not rendered. Expected behavior: component does not render the links section.
- **Multiple rapid toggles**: When a user clicks the toggle button multiple times in rapid succession, each click toggles the state immediately. Expected behavior: state always reflects the most recent click.
- **Link with missing label**: When a link in `data.links` has no `label` property, the component falls back to displaying the `url` as the link text. Expected behavior: link is always clickable and has visible text.
- **defaultOpen not specified**: When the `defaultOpen` prop is not provided, the component defaults to `true` and renders in the open state. Expected behavior: component opens by default. See inline-popover-016.
- **Missing stylesheet**: `.pc-popover-body` is always rendered in the DOM regardless of open state; only the `pc-popover-open` class and `aria-hidden` control its visibility. A caller who omits the component's CSS sees the body content displayed even when the disclosure is closed. Expected behavior: callers must supply the matching stylesheet — the component provides no `hidden` attribute or other CSS-independent fallback.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `data` | `PopoverData` | required | Object containing `title`, `description`, and `links` properties |
| `data.title` | `string` (declared required by `PopoverData`; TypeScript rejects an object literal that omits it) | (required) | Title text displayed in the toggle button. The component itself tolerates a falsy value at runtime and skips rendering it — see **render-title-when-provided** — but the declared type does not make it optional. |
| `data.description` | `string \| undefined` | undefined | Optional description text displayed in the disclosure body |
| `data.links` | `Array<{ label: string; url: string }> \| undefined` | undefined | Optional array of link objects. `PopoverData` declares both `label` and `url` as required per item; the component tolerates a falsy `label` at runtime and falls back to displaying the `url` — see **Link with missing label** — but the declared type does not make `label` optional. |
| `defaultOpen` | `boolean` | `true` | Initial open/closed state of the disclosure |

## Deep Linking

Not applicable: This component is a presentation element with no deep linking semantics. Deep linking behavior, if needed, is the responsibility of the containing application.

## Localization

Not applicable: The component displays content from the `data` prop, which is provided by the caller. Localization of title, description, and link labels is the responsibility of the data provider.

## Accessibility Options

- **Reduce Motion**: Not implemented in source. Component does not check for `prefers-reduced-motion` and applies no motion-specific behavior changes.
- **Increase Contrast**: Not implemented in source. Contrast is controlled entirely by CSS classes and must be configured at the style layer.
- **Differentiate Without Color**: Not implemented in source. The component relies on CSS styling to differentiate states; if color alone is used, the caller must add shape or text indicators via CSS.

## Feature Flags

Not applicable: Component has no feature flags in source code.

## Analytics

Not applicable: Component does not emit analytics events. Tracking of toggle interaction or link clicks is the responsibility of the containing application.

## Privacy

Not applicable: Component does not collect, store, or transmit any user data. All content is passed via props and displayed directly.

## Logging

Not applicable: Component does not perform logging.

## Platform Notes

- **React/Web**: The source is `packages/web/packages/chat/src/components/InlinePopover.tsx`. State is managed with React's `useState` hook. CSS classes drive appearance, including `pc-popover`, `pc-popover-open`, `pc-popover-toggle`, `pc-popover-arrow`, `pc-popover-title`, `pc-popover-body`, `pc-popover-desc`, `pc-popover-links`, and `pc-popover-link`. Styling is not included in the component; callers must provide matching CSS. The native `<details>`/`<summary>` elements would provide built-in keyboard and screen-reader disclosure semantics; see **Design Decisions** for why this implementation instead builds the toggle from a `button` and a `div`.
- **SwiftUI**: On iOS, use `DisclosureGroup` for the toggle and body — it provides the native expand/collapse control. Bind its `isExpanded` binding to a `@State` Bool seeded from `defaultOpen`. Place the arrow indicator and title inside the `label` closure and the description/links inside the `content` closure. For links, use `Link(_:destination:)` or the `openURL` environment action to open the system browser — not `NavigationLink`, which pushes an in-app navigation destination rather than opening a URL.
- **Compose**: On Android, use a Column with a Row for the toggle button (a Button with an icon for the arrow). Use a mutableStateOf for the open state. Conditionally render the AnimatedVisibility or if-else branch for the body content. Render links as clickable Text or Button elements that invoke Intent or deep link navigation.
- **AppKit / UIKit**: On macOS (AppKit), use an `NSButton` configured with `bezelStyle = .disclosure` — the native disclosure-triangle control (there is no separate `NSDisclosureTriangle` class) — and lay out the toggle and body with `NSStackView`, managing state with a bound property. On iOS (UIKit), which has no built-in disclosure control, construct a `UIButton` with a custom chevron image for the arrow, use a `UIStackView` for layout, and manage state with a property.
- **WinUI 3**: On Windows, use the native `Expander` control, which already provides the toggle chrome, chevron rotation, and expand/collapse states — set its `Header` to the arrow-plus-title content and its body to the description/links content, bound to a boolean `IsExpanded` seeded from `defaultOpen`. Use `Hyperlink` elements from WinUI for the link collection, setting the `NavigateUri` property.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/components/InlinePopover.tsx` | unverified |

## Design Decisions

**Decision**: The component accepts a `defaultOpen` prop to seed its internal `useState`, and is uncontrolled only — there is no `open` or `onOpenChange` prop, so a caller cannot drive the open state from outside once mounted.
**Rationale**: `defaultOpen` lets the caller pick the initial state; the default of `true` matches a common UX pattern where disclosure content is visible by default, reducing the need for users to discover the toggle.
**Approved**: pending

**Decision**: The disclosure content is marked `aria-hidden` on the root element when closed, rather than relying on CSS `display: none` alone.
**Rationale**: This communicates the hidden state to assistive technology directly. (Applying it to the root instead of only `.pc-popover-body` also hides the toggle button when closed — see **Accessibility**.)
**Approved**: pending

**Decision**: Links always open in a new tab, with `target="_blank"` and `rel="noopener noreferrer"`.
**Rationale**: This prevents navigation away from the containing page and prevents the opened page from accessing the `window.opener` property. Callers who need different link behavior (same-tab navigation, new window) should handle link clicks at a higher level or wrap the component.
**Approved**: pending

**Decision**: Title, description, and links are only rendered if their data is truthy.
**Rationale**: This reduces DOM clutter and improves performance when content is not provided.
**Approved**: pending

**Decision**: The component uses CSS classes (`pc-popover`, `pc-popover-open`, etc.) rather than inline styles.
**Rationale**: This allows complete separation of presentation logic and gives callers full control over appearance.
**Approved**: pending

**Decision**: The toggle is built from a custom `button` + `div` pair with `pc-popover-*` classes rather than the native `<details>`/`<summary>` elements.
**Rationale**: A hand-built toggle lets the arrow indicator and title be composed freely inside the button's label while keeping the existing `pc-popover-*` CSS class contract; `<details>`/`<summary>` would need different default styling and event handling to match it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | failed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | failed | Security |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The toggle is a native `button` (keyboard-navigable: passed), but `aria-hidden` on the root hides the button itself when closed and the fixed `aria-label="Toggle details"` never incorporates the visible title (semantic-markup: failed; screen-reader-support: partial); `href={link.url}` is passed to the anchor with no scheme check, so a `javascript:` URL would execute (input-sanitization: failed); and the hardcoded `aria-label="Toggle details"` string is not externalized even though `data.title`/`data.description`/`data.links` are caller-supplied and already externalizable (string-externalization: partial). `separation-of-concerns` passes because the component holds only its own open/closed toggle state and renders `data` as-is, with no data access or business rule of its own; `unit-test-coverage` fails because no test file exercises `InlinePopover`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Corrected Configuration table + Conformance vectors (006-013) so example data matches PopoverData's required title/label instead of implying they're optional. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed to Inline Disclosure and cross-linked the Popover recipe; reworded the defaultOpen decision as uncontrolled-only; reformatted Design Decisions and Compliance to convention; renamed requirements to subject-only kebab-case; deduplicated aria-hidden vectors and added keyboard-activation and default-open-omitted vectors; corrected Platform Notes API names and pointed to native disclosure controls (DisclosureGroup, Expander, AppKit disclosure-bezel NSButton); fixed the Configuration null/undefined mismatch; documented the root aria-hidden/label-in-name accessibility gaps and the always-rendered body; added missing references and set author |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
