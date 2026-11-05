---
id: e6c9f895-888f-4984-8fe1-ba86cc855613
title: Rich Content
domain: adhsdk://recipes/rich-content
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Renders linked and embedded media content from structured data with built-in
  security filtering.
platforms:
- typescript
- web
tags:
- content-rendering
- media
- links
depends-on: []
related:
- adhsdk://recipes/message-bubble
references:
- https://owasp.org/www-community/attacks/xss/
- https://www.w3.org/WAI/WCAG21/Understanding/focus-visible.html
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/rel/noopener
approved-by: ''
approved-date: ''
---

# Rich Content

## Overview

The Rich Content component renders a sequence of content items — hyperlinks and images — supplied as structured data. It is designed for displaying formatted responses from language models or other structured content sources where links and embedded media come from untrusted origins. The component applies protocol filtering to all hyperlinks to block script-executing schemes (such as `javascript:` or `data:`) that an attacker-controlled or prompt-injected link could carry, and hides each image until it finishes loading so an incomplete image is never shown mid-load; hiding an image does not delay or prevent its network fetch, which starts immediately regardless of visibility.

## Behavioral Requirements

- **render-items-in-order**: The component MUST render content items in the order they appear in the input array.
- **link-protocol-allowlist**: The component MUST accept only hyperlinks whose resolved protocol is `http:`, `https:`, `mailto:`, or `tel:`. The scheme is parsed case-insensitively and normalized to lowercase before the check (`JaVaScRiPt:` becomes `javascript:`), and leading whitespace/control characters are stripped during parsing, per the URL standard. Links with any other protocol (including `javascript:`, `data:`, `vbscript:`) MUST render as inert text, not as clickable links. The protocol is determined by resolving the URL against a fixed internal base (`https://x.invalid`), not against the page's own origin, so a scheme-less URL (e.g., `/page`) is always resolved as `https:` and accepted regardless of the current page's actual scheme — see **Relative URLs** in Edge Cases. This is the single URL-safety contract for the component; every other section that talks about validating a link URL refers back to this one allowlist rather than defining its own rule.
- **malformed-url-handling**: The component MUST treat a URL as unsafe and render it as inert text when resolving it against the fixed internal base throws — that is, when the URL is unparseable even as a relative path (for example `http://[bad`). A URL string that merely contains an illegal scheme character (for example `ht!tp://invalid`) does not throw: the parser instead restarts in relative mode and resolves it as a path against the base, so it is NOT caught by this check and passes the protocol allowlist as `https:` — see **Malformed-but-parseable URL passes through** in Edge Cases.
- **safe-link-text**: The component MUST display either the link's label or, if no label is provided, the URL itself as the visible text. Links MUST NOT render blank.
- **open-links-in-new-context**: The component MUST open all hyperlinks in a new tab or window (platform-appropriate) with cross-origin isolation (`noopener noreferrer` on web). On native platforms, "new context" means the system browser or the OS's registered handler for the URL's scheme — never in-app or inline navigation.
- **hide-until-loaded**: The component MUST NOT display an image until it has successfully loaded. Images MUST remain hidden until the image load event fires or an error occurs. This hides the visual result of loading, not the network request itself — the image is still fetched immediately regardless of visibility, so hiding it provides no protection against a malicious or oversized response.
- **image-error-handling**: The component MUST handle image load errors by revealing the image element the same way it does on success ("fail open"), rather than leaving the space collapsed and the failure invisible. Because no space is reserved while an image is hidden, this reveal MAY shift surrounding layout — the component does not attempt to preserve the footprint a successfully loaded image would have had.
- **image-alt-text**: The component MUST render alt text on images when provided. If no alt text is supplied, the component MUST use an empty string as the fallback.
- **unknown-item-skip**: The component SHOULD silently omit content items of unknown types. Unknown item types MUST NOT cause rendering errors or break the display of subsequent items.

## Appearance

- **Spacing**: No built-in padding or margins; layout is determined by container and parent context.
- **Link text decoration**: Links SHOULD be visually distinct (underlined or styled) to indicate interactivity; exact styling is platform-dependent.
- **Image display**: Images MUST scale to fit their container context. Platform-specific sizing constraints apply.
- **Background**: Transparent; no background color imposed.
- **Typography**: Inherits from parent context; no font size or weight imposed.

## States

| State | Appearance change |
|-------|------------------|
| Default (link) | Styled as a hyperlink; user can perceive it as interactive |
| Hovered (link) | Platform-specific hover styling (underline emphasis, color change) |
| Focused (link) | Platform-specific focus indicator (outline, highlight) |
| Active/Pressed (link) | Platform-specific pressed state |
| Image loading | Image hidden (`display: none`); no space reserved |
| Image loaded | Image displayed at its natural/CSS-constrained size |
| Image error | Hidden style removed (fail-open reveal, same as success); browser's default broken-image indicator shown; may shift surrounding layout since no space was reserved while hidden |

## Accessibility

- **Link role**: Each link MUST be rendered as an accessible `<a>` element (web) or platform-equivalent interactive control (native), allowing screen readers to identify it as a link.
- **Link label**: Links MUST have meaningful text content. If no label is provided, the URL itself is used as the visible text (per **safe-link-text**) — including when that URL's protocol was rejected by **link-protocol-allowlist**. In that case the rejected URL is still shown, but only as static, non-interactive text with no `href`; a screen reader announces the literal URL string, which can be long or awkward to pronounce but carries no code-execution risk since it is never used as a navigation target.
- **Image alt text**: Images MUST be rendered with an `alt` attribute (web) or equivalent accessibility trait. If no alt text is provided, the alt text MUST be an empty string (decorative image), per **image-alt-text**.
- **Keyboard navigation**: Links MUST be reachable by keyboard (Tab key on web; platform equivalent on native) and MUST be activatable by standard keyboard controls (Enter on web; space/enter on native). This applies only to links that received an `href` under **link-protocol-allowlist**; a rejected link has no `href` and is correctly excluded from the tab order along with the rest of the inert text.
- **Focus indicator**: Links MUST have a visible focus indicator meeting WCAG 2.4.7 (Focus Visible). The indicator's exact rendering (outline width, color, highlight style) follows the platform's native focus-indicator defaults rather than a fixed pixel or contrast value.
- **Minimum touch target**: Not required for links rendered inline within text content — WCAG 2.5.8 (Target Size Minimum) exempts inline links from a minimum target size. When the component's output is styled as a standalone, non-inline tappable element rather than inline text, it SHOULD meet 44×44pt (iOS) or 48×48dp (Android).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| rich-content-001 | render-items-in-order | items = [{type: 'link', label: 'First', url: 'https://example.com'}, {type: 'link', label: 'Second', url: 'https://example.com'}] | Links render in order: "First" then "Second" |
| rich-content-002 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'javascript:alert(1)'}] | No href is set; link renders as inert text "Click" |
| rich-content-003 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'data:text/html,<script>alert(1)</script>'}] | No href is set; link renders as inert text "Click" |
| rich-content-004 | link-protocol-allowlist | items = [{type: 'link', label: 'Email', url: 'mailto:user@example.com'}] | Link has href="mailto:user@example.com"; user can click to open mail client |
| rich-content-005 | link-protocol-allowlist | items = [{type: 'link', label: 'Phone', url: 'tel:+1-555-1234'}] | Link has href="tel:+1-555-1234"; user can click to initiate call |
| rich-content-006 | malformed-url-handling | items = [{type: 'link', label: 'Bad', url: 'http://[bad'}] | Resolving the URL throws; no href is set; link renders as inert text "Bad" |
| rich-content-007 | safe-link-text | items = [{type: 'link', label: 'Visit Site', url: 'https://example.com'}] | Link text displays as "Visit Site" |
| rich-content-008 | safe-link-text | items = [{type: 'link', url: 'https://example.com'}] | Link text displays as "https://example.com" |
| rich-content-009 | open-links-in-new-context | items = [{type: 'link', label: 'Link', url: 'https://example.com'}] | Link has target="_blank" with rel="noopener noreferrer" (web); native platforms open in the system browser/handler, never in-app |
| rich-content-010 | hide-until-loaded | items = [{type: 'image', src: 'https://example.com/image.png', alt: 'Photo'}] | Image element is created with `display: none` (no space reserved) until the load event fires |
| rich-content-011 | hide-until-loaded | items = [{type: 'image', src: 'https://example.com/image.png'}] | Image is shown (hidden style removed) once the load event fires |
| rich-content-012 | image-error-handling | items = [{type: 'image', src: 'https://broken-url.com/image.png'}] | Hidden style is removed when the error event fires (fail-open, same as success); the browser's default broken-image indicator becomes visible in the space it now occupies |
| rich-content-013 | image-alt-text | items = [{type: 'image', src: 'https://example.com/photo.png', alt: 'Portrait'}] | Image has alt="Portrait" |
| rich-content-014 | image-alt-text | items = [{type: 'image', src: 'https://example.com/photo.png'}] | Image has alt="" (empty string, decorative) |
| rich-content-015 | unknown-item-skip | items = [{type: 'link', label: 'Link', url: 'https://example.com'}, {type: 'unknown'}, {type: 'link', label: 'Link2', url: 'https://example.com'}] | Two links render; unknown item is skipped silently |
| rich-content-016 | link-protocol-allowlist | items = [{type: 'link', label: 'Rel', url: '/page'}] | URL has no scheme, so resolving it against the internal base yields `https:` regardless of the page's own scheme; href is set to "/page" and the link is clickable |
| rich-content-017 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'vbscript:msgbox(1)'}] | No href is set; link renders as inert text "Click" |
| rich-content-018 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'JaVaScRiPt:alert(1)'}] | Scheme normalizes to lowercase `javascript:` before the allowlist check; no href is set; link renders as inert text "Click" |
| rich-content-019 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: '  javascript:alert(1)'}] | Leading whitespace is stripped during URL parsing; scheme resolves to `javascript:`; no href is set; link renders as inert text "Click" |
| rich-content-020 | render-items-in-order | items = [] | Container renders with no child elements; no error or console warning |
| rich-content-021 | image-error-handling | items = [{type: 'image', src: 'https://example.com/image.png'}]; the load event then the error event fire in quick succession | Reveal happens once and stays revealed; no duplicate render, no thrown error |
| rich-content-022 | link-protocol-allowlist | items = [{type: 'link', label: 'Bad', url: 'ht!tp://invalid'}] | The `!` is not a legal scheme character, so resolving against the internal base restarts in relative mode and yields protocol `https:`; href is set to "ht!tp://invalid" and the link is clickable (see **Malformed-but-parseable URL passes through** in Edge Cases) |

## Edge Cases

- **Empty items array**: If the component receives an empty array, it MUST render nothing and not produce an error or console warning (rich-content-020).
- **Relative URLs**: URLs without an explicit scheme (e.g., `/page`, `../sibling`) resolve against a fixed internal base (`https://x.invalid`), not the component's actual page origin, and are therefore always treated as `https:` and accepted (see **link-protocol-allowlist**, rich-content-016). This is a deliberate consequence of resolving the URL against a fixed base before checking its protocol, not an oversight.
- **Malformed-but-parseable URL passes through**: A URL string that looks malformed can still pass **link-protocol-allowlist** if the WHATWG URL parser can resolve it as a relative path against the internal base rather than throwing. For example `ht!tp://invalid` contains `!`, which is not a legal scheme character, so the parser restarts in relative mode instead of throwing; it resolves to protocol `https:` against the base and is accepted unchanged as the href (rich-content-022) — a live link the browser then resolves against the current page when clicked. Only a URL that fails to resolve at all (see **malformed-url-handling**, rich-content-006) is treated as unsafe; this is a source quirk, not a MUST, and is not caught by the malformed-URL check.
- **Null or missing fields**: If a link item has no `url` field or a null URL, the component MUST treat it as unsafe and render the label (or empty text) as inert. If an image item has no `src` field, the `<img>` element is still rendered (with no `src` attribute set); the browser fails to load it, which the component handles the same as any other load failure (see **image-error-handling**).
- **Very long URLs**: Long URLs displayed as link text MUST not cause layout breaking; the component SHOULD allow normal text wrapping and overflow behavior.
- **Concurrent load/error events**: If an image fires both a load and an error event in quick succession (e.g., due to network retry), the component MUST handle this gracefully without double-rendering or throwing (rich-content-021).
- **XSS injection via alt text**: Alt text, like every other content-item field, comes from the same untrusted structured-data source as links and images — it is not treated as more trustworthy. It is rendered only as the value of an HTML `alt` attribute, never interpreted as markup or executable code, so standard attribute encoding (applied automatically by the rendering framework) is sufficient; no additional escaping is required by the component.

## Configuration

Not applicable: This component has no configurable options. It is a stateless presentational component that renders an immutable array of content items.

## Deep Linking

Not applicable: This component renders multiple content items and does not represent a single navigable destination. Deep linking patterns depend on the individual links within the content and the hosting application's URL scheme.

## Localization

Not applicable: This component does not generate or display user-facing strings. Content (link labels, image alt text) comes from the data source (LLM or structured input) and is responsibility of that source to localize if needed.

## Accessibility Options

Not applicable: This component does not respond to platform accessibility display options such as Reduce Motion, Increase Contrast, or Differentiate Without Color. It renders text and images in their native form and respects the platform's native font rendering and link styling.

## Feature Flags

Not applicable: This component has no feature flags or conditional behavior based on application configuration.

## Analytics

Not applicable: This component does not emit events or track user interactions. Analytics for link clicks and image loads is the responsibility of the parent application or the links themselves (via target=_blank external navigation).

## Privacy

- **Data collected**: None. The component does not collect, log, or transmit any user data.
- **URL handling**: URLs provided in content items are not modified, validated against a server, or transmitted anywhere outside of the component's rendering context. The component does not make network requests beyond the browser's standard image loading for image items.
- **Image-fetch exposure**: Because image `src` values are fetched unconditionally (hiding an image does not delay its fetch, per **hide-until-loaded**), rendering an item whose `src` points at an attacker-controlled host discloses the viewer's IP address and User-Agent to that host and can act as a tracking beacon or read-receipt, the same as any `<img>` tag pointed at an arbitrary URL. This is standard browser image-loading behavior, not a data-sharing action the component itself performs, and there is no scheme allowlist on `src` (unlike `url` on links).

## Logging

Not applicable: This component does not emit log messages. Errors in URL parsing or image loading are handled silently per the requirements above.

## Platform Notes

- **Web (React)**: Render as a `<div>` container with `<a>` elements for links and `<img>` elements for images. Use the `safeHref()` function — a case-insensitive scheme check against the `http:`/`https:`/`mailto:`/`tel:` allowlist, resolved against a fixed internal base (`https://x.invalid`) so scheme-less URLs are accepted regardless of the page's actual origin — to validate link protocols before setting the `href` attribute. Gate images with `display: none` until the `onLoad` event fires, then remove the style to reveal; handle `onError` the same way (fail-open). Use `target="_blank" rel="noopener noreferrer"` on all links to prevent window-opener attacks.
- **SwiftUI**: Use `Link(destination:)` (or `openURL` from the environment) for every link, including `mailto:` and `tel:`, after validating the URL's scheme against the same allowlist; `Link` opens the system browser or handler, which satisfies **open-links-in-new-context** on this platform. `NavigationLink` is for in-app navigation and MUST NOT be used for these external destinations. Render images with `AsyncImage`; use its phase-based API to hide the view until `.success`, then display the image, and reveal the same way on `.failure` (fail-open, per **image-error-handling**).
- **Compose**: Use `Text` composables wrapped in a `clickable()` modifier for link labels; validate the URL's scheme before constructing the `Intent`/system action. Use `Intent.ACTION_SENDTO` for `mailto:` and `Intent.ACTION_DIAL` for `tel:`. Render images with Coil's or Glide's `AsyncImage`, driving visibility from the loading state with `Modifier.alpha(0f)` (which keeps the layout slot reserved) rather than `Modifier.size(0)` (which collapses it and reintroduces the layout shift **hide-until-loaded** exists to avoid); set alpha back to `1f` on both success and error (fail-open).
- **AppKit / UIKit**: On macOS, render a link as an attributed string carrying a link attribute inside an `NSTextView`, or as a borderless, link-styled `NSButton` — not an `NSTextField` nested inside an `NSButton`, which is not a supported view hierarchy. On iOS, use a `UILabel` with an attributed string plus a tap gesture, or a borderless `UIButton` with an attributed title. Validate the URL's scheme before opening it via `NSWorkspace.shared.open(_:)` (macOS) or `UIApplication.shared.open(_:)` (iOS); `mailto:`/`tel:` URLs are constructed and opened the same way once validated. Render images with `NSImageView`/`UIImageView`: start with the image unset/hidden, load via `URLSession` (or an image-loading library), and reveal the view the same way on success or failure (fail-open).
- **WinUI 3**: Use `HyperlinkButton` with `NavigateUri` set to the validated URL for every link, including `mailto:` and `tel:` — Windows resolves those schemes to their registered handler at the OS level, and `HyperlinkButton` always launches outside the app, satisfying **open-links-in-new-context**. Render images with the `Image` control, binding `Source` to a `BitmapImage` that a view model loads; there is no `WebViewImage` type. Use `VisualStateManager` states ("Loading" with the image hidden, "Loaded"/"Error" with it visible) driven by the view model's load result, revealing the same way on error (fail-open).

## Design Decisions

**Decision**: Only `http:`, `https:`, `mailto:`, and `tel:` schemes are accepted as link hrefs; every other scheme (`javascript:`, `data:`, `vbscript:`, and any custom scheme) is rejected unconditionally.
**Rationale**: These four schemes perform navigational actions or invoke system services, while the rejected schemes can execute arbitrary code in the page's security context. This mitigates script-execution attacks (such as XSS) that could be delivered through attacker-controlled or prompt-injected link data — it does not mitigate prompt injection itself, which is the delivery mechanism, not the vulnerability this filter closes. This is a security requirement, not a feature choice.
**Approved**: pending

**Decision**: Images are hidden (`display: none`) until their `onLoad` event fires, then revealed.
**Rationale**: Prevents an incomplete or default broken-image placeholder from flashing on screen before the real image is ready. This is not lazy loading (`loading="lazy"`) and does not delay or prevent the underlying network fetch — the image request starts immediately regardless of visibility, so hiding it has no bearing on whether a malicious or oversized response is fetched.
**Approved**: pending

**Decision**: On an image load error, the hidden style is removed the same way as on success ("fail open"), rather than leaving the space collapsed indefinitely.
**Rationale**: A permanently collapsed, invisible image looks like a rendering bug rather than a handled failure. Revealing the element (which shows the browser's default broken-image indicator) makes the failure visible instead of silent. Because no width/height is reserved while hidden, this reveal can itself shift the surrounding layout — the component does not attempt to preserve the exact footprint a successfully loaded image would have occupied.
**Approved**: pending

**Decision**: Links always open in a new browsing context — a new tab/window on web (`target="_blank" rel="noopener noreferrer"`), the system browser or registered handler on native platforms — never in-app or inline navigation.
**Rationale**: Keeps the hosting application's state intact when the user follows an external link. `noopener noreferrer` additionally prevents the linked page from reaching back into the opener's `window` object or reading the referrer header.
**Approved**: pending

**Decision**: Content items with an unrecognized `type` are silently skipped and render nothing.
**Rationale**: Lets the component tolerate schema evolution — new item types introduced by the data source before this component is updated — without throwing or breaking the rendering of sibling items.
**Approved**: pending

**Decision**: Every content-item field (`url`, `src`, `label`, `alt`) is treated as coming from the same untrusted source, with no field singled out as more trustworthy than another.
**Rationale**: The component applies no sanitization beyond the link-protocol allowlist and the rendering framework's standard attribute encoding; every field is rendered only as inert text or an attribute value, or fetched as an image, never interpreted as markup or executable code. Treating one field (such as alt text) as an exception would contradict the Overview's own untrusted-origin framing without changing what the component actually does.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [third-party-disclosure](agenticdevelopercookbook://compliance/privacy-and-data#third-party-disclosure) | partial | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The Security and Accessibility statuses rest on `safeHref()`'s protocol allowlist and the native `<a>`/`<img>` elements shown in `RichContent.tsx`, which need no extra ARIA or keyboard wiring. The Privacy & Data status is partial because loading an image from an arbitrary `src` is standard, undisclosed browser behavior the component does not gate (see **Image-fetch exposure** under Privacy). The security-critical `safeHref()` scheme allowlist is a standalone, independently testable function rather than logic tangled into the JSX (separation-of-concerns passed); `RichContent.test.tsx` directly exercises both the image-gating behavior and the `safeHref` protocol allowlist, including the `javascript:` rejection (unit-test-coverage passed).

## Data Model

- **ContentItem**: `LinkContent | ImageContent` — the discriminated union that `items` is built from; `type` is the discriminator.
- **LinkContent**: `{ type: 'link'; url: string; label?: string }`. `url` is required; `label` is optional and falls back to `url` as the visible text (per **safe-link-text**).
- **ImageContent**: `{ type: 'image'; src: string; alt?: string }`. `src` is required; `alt` is optional and falls back to an empty string (per **image-alt-text**).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; added a Data Model section; corrected the prompt-injection and lazy-load overview claims; resolved the image-error layout-shift contradiction and standardized on `display: none`; fixed the relative-URL and alt-text-trust edge cases and the unlabeled-unsafe-link accessibility claim; rescoped the touch-target and focus-indicator accessibility bullets; corrected the SwiftUI, AppKit/UIKit, Compose, and WinUI 3 platform notes; reformatted Design Decisions into the Decision/Rationale/Approved form; replaced the Compliance table with real catalog checks; added test vectors for relative, vbscript, mixed-case, and whitespace-prefixed URLs, an empty array, and concurrent load/error events; added external references and a related cross-reference to message-bubble |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed TV-006/malformed-url-handling to match safeHref(); moved Data Model after Compliance. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
