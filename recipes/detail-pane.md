---
id: 292f17e2-1df8-4126-a26c-4160e8e88708
title: Detail Pane
domain: adhsdk://recipes/detail-pane
type: ingredient
version: 1.2.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A collapsible panel that displays detailed information for a selected topic,
  including title, description, images, and related links.
platforms:
- typescript
- web
tags:
- detail-display
- panel
- three-pane-layout
depends-on:
- adhsdk://recipes/connector-anchor
related:
- adhsdk://recipes/three-pane-chat
references:
- https://www.w3.org/WAI/WCAG21/Understanding/focus-order.html
approved-by: ''
approved-date: ''
---

# Detail Pane

## Overview

The Detail Pane is a collapsible side panel that displays contextual details for a selected topic in a three-pane layout. It renders the topic's title, description, images, and linked references. The parent controls the pane's visibility through a boolean prop; the pane holds no visibility state of its own and simply reflects the prop's value as a CSS class (see **visibility-state**). The pane is typically positioned to the right of a main content area and toggled open or closed by parent controls.

## Behavioral Requirements

The pane's data model:

**Topic**

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes | |
| `description` | string | yes | empty string is treated as absent — see **conditional-content** |
| `links` | array of TopicLink | yes | may be empty |
| `images` | array of TopicImage | yes | may be empty |
| `messageIndex` | number | yes | used to build the connector anchor's `data-connector-anchor` value — see **connector-anchor** |

**TopicLink**

| Field | Type | Required | Notes |
|---|---|---|---|
| `label` | string | yes | may be empty — falls back to `url`, see **link-properties** |
| `url` | string | yes | |

**TopicImage**

| Field | Type | Required | Notes |
|---|---|---|---|
| `src` | string | yes | |
| `alt` | string | no | defaults to an empty string when omitted — see **images** |

The `topic` prop itself is either a `Topic` object or `null`.

- **header**: The pane MUST render a fixed header labeled "Details" at the top of the panel.
- **topic-prop**: The pane MUST accept a `topic` prop whose value is either a `Topic` object or `null`.
- **conditional-content**: When `topic` is null, the pane MUST render an empty content area. When `topic` is provided, the pane MUST render all non-empty fields from the topic data.
- **title**: When a topic is present, the pane MUST render the topic's title as a distinct visual element.
- **optional-description**: When a topic is present and has a non-empty description, the pane MUST render the description below the title.
- **images**: When a topic is present and has images, the pane MUST render each image with its `src` attribute. If an image lacks an `alt` attribute, the pane MUST use an empty string.
- **image-load-callback**: When an image finishes loading, the pane MUST call the optional `onImageLoad` callback if provided.
- **links-section**: When a topic is present and has links, the pane MUST render a "Links" label followed by a list of clickable links.
- **link-properties**: Each link MUST open in a new tab (target="_blank") with `rel="noopener noreferrer"`. If a link has no label, the pane MUST display the URL as the link text.
- **visibility-state**: The pane MUST accept a `visible` prop and apply a CSS class indicating visibility state (`pc-pane-visible` when true, `pc-pane-hidden` when false).
- **content-mounted-when-hidden**: When `visible` is false, the pane MUST keep the header and all topic content mounted in the DOM. It MUST NOT unmount the subtree and MUST NOT apply `inert`, `aria-hidden`, or a negative `tabIndex` to the root element or its descendants.
- **focus-untouched**: The pane MUST NOT set, move, or restore focus when `visible` changes. Changing `visible` MUST change only the root element's class name and MUST leave the active element exactly as it was.
- **literal-ui-strings**: The pane MUST render "Details" and "Links" as literal English text; today it does so without any localization key, catalog, or translation hook. This absence is a known gap (see Localization), not a permanent constraint — a future revision that introduces localization for these strings SHOULD do so without being treated as breaking this requirement.
- **ref-forwarding**: The pane MUST support ref forwarding to expose the root `HTMLDivElement`.
- **connector-anchor**: When `topic` is present, the pane MUST render a ConnectorAnchor element carrying a `data-connector-anchor` attribute constructed from the message index in the format `panel-{messageIndex}-in` (not a DOM `id`), provided a `ConnectorRegistryProvider` is present in the tree — without one, ConnectorAnchor renders nothing. When `topic` is null, the pane MUST NOT render a ConnectorAnchor element at all.
- **header-semantics**: The pane SHOULD render the header using a heading element (e.g., an `<h2>`) and the root SHOULD carry a landmark role (e.g., `role="complementary"`) when used as a primary content region. The current implementation renders both as plain `div`s with no heading or landmark semantics (see Compliance: `semantic-markup`).
- **no-analytics**: The pane MUST NOT emit analytics events. A consuming application that needs instrumentation MUST add it at the call site — for example by wrapping the `onImageLoad` callback it passes in, by observing the `visible` prop it controls, or by attaching its own handler to the rendered links.
- **no-logging**: The pane MUST NOT write log messages. A consuming application that needs diagnostics MUST emit them at the call site, where the `topic` and `visible` props and the `onImageLoad` callback are already available.

## Appearance

- **Container**: Background and spacing are inherited from the parent layout; the pane itself supplies no chrome beyond its content.
- **Header**: A fixed "Details" label sits at the top of the panel, visually distinct from the content below it.
- **Content area**: A single region below the header that holds the topic's rendered fields.
- **Title**: The topic title renders as a distinct, prominent visual element at the top of the content area.
- **Description**: When present, the description renders as a block of text directly below the title.
- **Images**: When present, images render as a group below the description; layout, sizing, and spacing are supplied by the parent stylesheet.
- **Links label**: When links are present, a "Links" label introduces the links list.
- **Links**: Each link renders as a native link element in a list below the links label.
- **Visibility**: The root container has one of two mutually exclusive visual states, visible or hidden — see States. The parent stylesheet defines the visual difference and any transition between them.

## States

| State | Appearance change |
|-------|------------------|
| Visible | Root element has `pc-pane-visible` class; pane is displayed or animated into view |
| Hidden | Root element has `pc-pane-hidden` class; pane is hidden or animated out of view. Content stays mounted and focus is not moved |
| Empty (no topic) | Content area is rendered but empty; header remains visible |
| Loaded (topic present) | All available topic fields are rendered; images display when loaded |

## Accessibility

- **Role**: The pane does not have an explicit ARIA role; it is a plain `div` container. The "Details" header is also a `div`, not a heading element, so it carries no heading semantics and serves as a visual landmark only (see **header-semantics**).
- **Link accessibility**: Links use native `<a>` elements and are keyboard accessible. Link text MUST be meaningful (either the label or the URL).
- **Image alt text**: Images MUST have an `alt` attribute; if not provided in the source data, an empty string is used (Note: empty alt strings should only be used for decorative images; if images are content, ensure they are marked with descriptive alt text in the data source).
- **Focus across visibility transitions**: NEEDS REVIEW: Not implemented in source. The pane performs no focus management. Toggling `visible` swaps `pc-pane-visible` for `pc-pane-hidden` on the root element and does nothing else: the subtree is not unmounted, `inert`/`aria-hidden`/`tabIndex` are never applied, and `focus()` is never called. Focus therefore stays wherever it was — including on a link inside the pane after the pane is hidden. The only shipped definition of `pc-pane-hidden` (`packages/web/packages/chat/src/css/modes/three-pane.css`) sets `opacity: 0` and `pointer-events: none`, not `visibility: hidden` or `display: none` (see Design Decisions: **Visibility Is Styling Only, Focus Left Untouched**). Opacity and pointer-events changes remove an element from neither the accessibility tree nor the tab order, so a hidden pane's links stay focusable and are still announced by screen readers while the pane is not visible — a WCAG 2.1 SC 2.4.3 (Focus Order) failure. Resolving `pc-pane-hidden` to `visibility: hidden` would settle this without the box-collapse that `display: none` would cause.
- **Semantic structure**: The pane uses semantic nesting of `div` elements with CSS classes for styling; see **header-semantics** for the concrete recommendation to use a heading element and a landmark role.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| detail-001 | header, literal-ui-strings | pane rendered | Header element contains the literal text "Details" |
| detail-002 | conditional-content | topic = null | Content area renders empty (no topic title/description/images/links) |
| detail-003 | title | topic = {title: "Test Topic", ...} | Title element renders with text "Test Topic" |
| detail-004 | optional-description | topic = {description: "Test desc", ...} | Description element renders below title |
| detail-005 | optional-description | topic = {description: "", ...} | Description element does not render |
| detail-006 | images | topic = {images: [{src: "/img.jpg", alt: "Alt text"}], ...} | Image element renders with src="/img.jpg" and alt="Alt text" |
| detail-007 | images | topic = {images: [{src: "/img.jpg"}], ...} | Image element renders with alt="" |
| detail-008 | image-load-callback | image loads + onImageLoad provided | onImageLoad callback is invoked |
| detail-009 | links-section, literal-ui-strings | topic = {links: [{label: "Link1", url: "http://example.com"}], ...} | Links section renders with the literal label "Links" and a clickable link with text "Link1" |
| detail-010 | link-properties | topic = {links: [{label: "Link1", url: "http://example.com"}], ...} | Link element has target="_blank" and rel="noopener noreferrer" |
| detail-011 | link-properties | topic = {links: [{label: "", url: "http://example.com"}], ...} | Link element displays URL text "http://example.com" |
| detail-012 | visibility-state | visible = true | Root element has class "pc-pane-visible" |
| detail-013 | visibility-state | visible = false | Root element has class "pc-pane-hidden" |
| detail-014 | connector-anchor | topic = {messageIndex: 5, ...}, rendered inside a `ConnectorRegistryProvider` | ConnectorAnchor element renders with `data-connector-anchor="panel-5-in"` (no `id` attribute) |
| detail-015 | content-mounted-when-hidden | topic present, rendered with visible = true, then re-rendered with visible = false | Title, description, image and link elements are all still present in the DOM; the root element has no `inert`, `aria-hidden`, or `tabindex` attribute |
| detail-016 | focus-untouched | topic with one link, visible = true; focus that link, then re-render with visible = false | `document.activeElement` is still the link element; the component issues no focus() call |
| detail-017 | no-analytics | topic present; render, load an image, click a link, toggle visible | No analytics event is dispatched by the component; the module references no analytics client |
| detail-018 | no-logging | topic present; render, load an image, toggle visible, render with topic = null | No console or logger output is produced by the component |
| detail-019 | topic-prop | topic = {title: "T", description: "", links: [], images: [], messageIndex: 0} (minimal valid Topic), rendered standalone with no `ConnectorRegistryProvider` | Component renders without error; per conditional-content, only the title renders — the connector anchor renders nothing, because ConnectorAnchor requires a `ConnectorRegistryProvider` |
| detail-020 | ref-forwarding | a ref object is passed to the component | `ref.current` is the root `HTMLDivElement` |
| detail-021 | connector-anchor | topic = null | No ConnectorAnchor element renders; no element carries a `data-connector-anchor` attribute |

## Edge Cases

- **Null topic with visible=true**: The pane renders with visibility class applied but no content to display. Expected: header "Details" renders; content area is empty.
- **Empty arrays**: When `topic.images` or `topic.links` are empty arrays (length=0), those sections do not render. Expected: only the title and description render if present.
- **Missing optional fields**: If topic lacks a description (field undefined or empty) or has empty arrays for images/links, those sections are conditionally omitted. Expected: only available fields render.
- **Image load failure**: If an image fails to load, the pane does not render an error state. Expected: broken-image placeholder behavior is left entirely to the platform's default image-failure rendering; the pane exposes no error callback — only `onImageLoad` exists, and it fires on successful loads only.
- **Concurrent image loads**: When multiple images are present and load asynchronously, `onImageLoad` callback fires for each image's load event. Expected: callback invoked once per image.
- **Null ref forwarding**: If the ref prop is not provided or is null, the component still renders and functions normally. Expected: no error; optional ref is handled by React.forwardRef.
- **Focus held inside a hidden pane**: If a link inside the pane holds focus when `visible` flips to false, the component leaves focus on that link. Expected: focus is unchanged (MUST, per focus-untouched); whether the link remains reachable by keyboard depends entirely on how `pc-pane-hidden` is styled (see Accessibility).
- **Topic replaced while hidden**: If `topic` changes while `visible` is false, the pane re-renders the new topic immediately, because its content is never unmounted. Expected: on the next show the pane already displays the new topic, with no intermediate empty state (MUST, per content-mounted-when-hidden).
- **No topic (anchor omitted)**: When `topic` is null, the pane renders no ConnectorAnchor at all — the anchor lives inside the `topic &&` block, so it doesn't exist while there's no topic (see Null topic with visible=true). Expected: no element carries a `data-connector-anchor` attribute; only the header renders.

## Configuration

Not applicable: This is a presentational component with no configuration options. All behavior is controlled via props (topic, visible, onImageLoad).

## Deep Linking

Not applicable: The component does not implement deep linking. Deep linking is a routing concern handled by the parent three-pane layout component.

## Localization

The pane is not localized. It renders two hardcoded English strings and contains no localization layer: neither string is read from a key, a message catalog, or a translation hook, and no fallback or locale-selection logic exists. The keys below are names a consuming application would have to introduce; they do not exist today. See **literal-ui-strings**.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none — hardcoded | "Details" | Header text of the detail pane, written as a literal in the component markup |
| none — hardcoded | "Links" | Section label rendered above the links list, written as a literal in the component markup |

Link labels and image alt text are not UI strings: they arrive through the `topic` prop and are rendered verbatim, so localizing them is the caller's responsibility.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The pane does not implement this on its own. Parent layout or CSS media queries should suppress `pc-pane-visible`/`pc-pane-hidden` transition animations if reduce-motion is enabled. |
| Increase Contrast | The pane does not implement this on its own. Parent styling or CSS should ensure links meet WCAG AA contrast ratios. |
| Differentiate Without Color | The pane does not implement this on its own. Link styling should not rely on color alone to indicate state. |

## Feature Flags

Not applicable: The component does not expose feature flags. Feature control is handled by the parent layout if needed.

## Analytics

Not applicable: the pane emits no analytics events. The source imports no analytics client, declares no event names, and has exactly one callback — `onImageLoad`, invoked from the `<img>` `onLoad` handler as a layout notification, not as an instrumentation hook. See **no-analytics**.

## Privacy

- **Data collected**: The component does not collect data. It displays data passed via props.
- **Storage**: No data is stored locally by the component.
- **Transmission**: No data transmission is performed by the component itself. Links open via standard browser navigation (target="_blank").
- **Retention**: The component does not persist state across sessions.

## Logging

Not applicable: the pane performs no logging. The source declares no subsystem and no category, imports no logger, and contains no `console` call on any path — including image load, visibility change, and the null-topic branch. See **no-logging**.

## Platform Notes

- **React/Web**: The source platform. `DetailPane.tsx` in `packages/web/packages/chat/src/modes/three-pane/` is a single `forwardRef` function component with no state and no effects; its sibling import `./connectors/ConnectorAnchor` is what ties the pane to the layout's connector lines, so a port must provide an equivalent anchor identified as `panel-{messageIndex}-in`. All appearance lives in `pc-`-prefixed classes supplied by a parent stylesheet, which is also where the show/hide mechanism is defined — the component only names the class. The classes are: `pc-detail-pane` (root), `pc-panel-header` (header), `pc-detail-content` (content area), `pc-detail-title` (title), `pc-detail-desc` (description), `pc-detail-images` / `pc-detail-image` (images container / each image), `pc-detail-links-label` (links label), `pc-detail-links` (links container), `pc-connector-anchor-in` (anchor position), and `pc-pane-visible` / `pc-pane-hidden` (visibility state).

- **SwiftUI**: Start from a `VStack(alignment: .leading)` inside a `ScrollView`, with the header as a `Text("Details")`, the body driven by `if let topic`, images as `AsyncImage` (use its phase transition to fire the `onImageLoad` equivalent), and links as `Link(label, destination:)`, which already opens externally so no `target="_blank"` analogue is needed. Drive visibility from an `isVisible` `Bool` with `.opacity`/`.offset` plus `.animation`. Note the difference from the source: SwiftUI drops a view from the accessibility tree only when it is not rendered or is marked `.accessibilityHidden(true)`, so apply `.accessibilityHidden(!isVisible)` to match a correctly styled hidden pane. The ConnectorAnchor maps to an `.anchorPreference` on the title row that publishes its bounds to the layout.

- **Compose**: Use a `Column` in a `verticalScroll`, `Text` for header, title and description, `AsyncImage` (Coil) with `onSuccess` for the load callback, and a `Text` composable rendering an `AnnotatedString` with a `LinkAnnotation.Url` for each link — it opens the URL through the system handler and replaces the deprecated `ClickableText`. Wrap the pane in `AnimatedVisibility(visible = visible)`, which unmounts content on exit — a deliberate divergence from the source, which keeps content mounted; if mounted-while-hidden matters (to preserve scroll position or image decode state), use `Modifier.alpha` plus `Modifier.semantics { invisibleToUser() }` instead. ConnectorAnchor becomes an `onGloballyPositioned` callback reporting the title row's bounds.

- **AppKit / UIKit**: Build the pane as an `NSStackView` / `UIStackView` (`.vertical`) inside an `NSScrollView` / `UIScrollView`, with `NSTextField`/`UILabel` for header, title and description, `NSImageView`/`UIImageView` fed by an async loader whose completion fires the load callback, and `NSButton` with the `.link` bezel style / `UIButton` calling `NSWorkspace.shared.open` / `UIApplication.shared.open` for links. Toggle visibility with the root view's `isHidden`, which — unlike the source's class swap — removes the view from both the accessibility tree and the key-view loop automatically; if animating with `alphaValue`/`alpha` instead, also set `accessibilityElementsHidden = true` and resign first responder explicitly. ConnectorAnchor maps to a zero-size marker view whose frame is converted into the layout's coordinate space for the connector drawing layer.

- **WinUI 3**: Use a `Grid` with two rows (header, content) inside a `ScrollViewer` as the root, a `TextBlock` for the "Details" header, and an `ItemsRepeater` (or `ItemsControl`) bound to the images and links collections. Images are `Image` elements with `ImageOpened` wired to the load callback; links are `HyperlinkButton` elements with `NavigateUri` set, which opens the default browser and so already matches `target="_blank"` with `rel="noopener noreferrer"`. Model the visible/hidden pair as `VisualState`s (`PaneVisible`, `PaneHidden`) in a `VisualStateManager.VisualStateGroups` on the root, driven by `VisualStateManager.GoToState`, and animate with a `Storyboard` or a `Microsoft.UI.Composition` implicit `Opacity`/`Translation` animation. End the hide state with the root's `Visibility="Collapsed"`: a collapsed element is skipped by both tab navigation and Narrator, which is exactly what the web version's stylesheet has to do explicitly. Express the `pc-` classes as `Style` resources keyed in a `ResourceDictionary` (`DetailPaneStyle`, `PanelHeaderStyle`, `DetailTitleStyle`, `DetailDescStyle`, `DetailLinksLabelStyle`) so the visual contract stays in one place. ConnectorAnchor becomes a zero-width `Border` in the title row, named with `x:Name="PanelAnchorIn"`, whose position the layout reads through `TransformToVisual(layoutRoot).TransformPoint(...)`.

## Design Decisions

**Ref Forwarding**
**Decision**: The component uses `forwardRef` to expose the root `HTMLDivElement` to parent consumers.
**Rationale**: This enables advanced layout control (e.g., measuring the pane's dimensions) without importing the component directly. This is a common React pattern for layout-sensitive components.
**Approved**: pending

**Empty Alt Strings For Images**
**Decision**: When image data lacks an `alt` attribute, the component assigns an empty string rather than a fallback description.
**Rationale**: This is correct for decorative images but relies on the data source to provide meaningful alt text for content images. Consumers MUST ensure image data includes descriptive alt text.
**Approved**: pending

**Link Opening Behavior**
**Decision**: Links always open in a new tab (`target="_blank"`) with security attributes (`rel="noopener noreferrer"`).
**Rationale**: This prevents the three-pane layout from being interrupted when a user follows a link, while `rel="noopener noreferrer"` blocks reverse-tabnabbing. Consumers SHOULD signal this behavior to users — for example by appending "opens in a new tab" to a link's accessible name, or by pairing the link with an icon that carries an equivalent accessible label — since neither the component nor the anchor markup announces it on its own.
**Approved**: pending

**Connector Anchor Placement**
**Decision**: The ConnectorAnchor is rendered at the start of the title, using a CSS class (`pc-connector-anchor-in`) to position it visually. The message index is embedded in the anchor's `data-connector-anchor` attribute (registered with `ConnectorRegistry`, not exposed as a DOM `id`) to support bidirectional linking in the three-pane layout.
**Rationale**: This design ties the pane's visual structure to the message flow; changes to title structure may require updates to the anchor positioning.
**Approved**: pending

**Conditional Rendering Of Sections**
**Decision**: Images and links sections only render if their arrays are non-empty.
**Rationale**: This keeps the UI clean when data is sparse. Consumers should expect variable content heights and plan layout accordingly.
**Approved**: pending

**Visibility Is Styling Only, Focus Left Untouched**
**Decision**: Hiding the pane is expressed entirely as a class name (`pc-pane-hidden`) on the root element. The component deliberately keeps its content mounted, applies no `inert`/`aria-hidden`/`tabIndex`, and never calls `focus()`.
**Rationale**: This keeps the component free of effects and lets the layout animate the pane in and out without losing scroll position or image decode state. The shipped `pc-pane-hidden` style (`opacity: 0; pointer-events: none;`) keeps the connector anchor's box measurable while the pane is offscreen, which `display: none` would defeat by collapsing it to zero — but unlike `visibility: hidden`, it does not remove the pane from the accessibility tree or the tab order, leaving open the question on **Focus across visibility transitions** of whether a hidden pane's links should stay keyboard-reachable.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | failed | Accessibility |
| [image-optimization](agenticdevelopercookbook://compliance/performance#image-optimization) | failed | Performance |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`semantic-markup` fails because the pane is built entirely from `div` elements: the "Details" header and the topic title are `div`s rather than heading elements, and the root carries no landmark role (see **header-semantics**). `image-optimization` fails because each `<img>` is rendered with only `src` and `alt` — no `loading`, `decoding`, `width`, or `height` attributes — so images load eagerly and reserve no layout space. `string-externalization` fails because "Details" and "Links" are literal English strings with no localization key, catalog, or translation hook (see Localization, **literal-ui-strings**). `separation-of-concerns` passes because `DetailPane.tsx` only renders the `TopicData` it is handed — no data fetching, backend calls, or business rules live in the component. `unit-test-coverage` fails because no test file in the `chat` package exercises `DetailPane`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Filled missing 1.0.0 history date; Compliance best-practices rows added (prior fixer did the VID work). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected the Overview's visibility-ownership claim; downgraded the literal-strings and semantic-markup gaps to documented SHOULDs instead of frozen MUSTs; resolved the display:none/visibility:hidden contradiction between Design Decisions and Accessibility; added a Topic/TopicLink/TopicImage type reference; added a no-topic connector-anchor requirement plus edge case; renamed every requirement to subject-only kebab-case and moved no-analytics/no-logging into Behavioral Requirements; reformatted Design Decisions to Decision/Rationale/Approved; added references and depends-on/related links; rewrote Appearance platform-neutrally and relocated the `pc-*` classes to the React/Web note; replaced the deprecated Compose `ClickableText` recommendation; added missing test vectors for topic-prop, ref-forwarding, and connector-anchor; dropped contradictory trailing "Not applicable" lines from Accessibility Options and Privacy; and rebuilt Compliance against real catalog checks |
| 1.1.0 | 2026-09-22 | — | Replace hedged gap markers in Accessibility, Localization, Analytics and Logging with statements traced to the source; add focus, mounting, literal-string, no-analytics and no-logging requirements plus their test vectors |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
