---
id: 0fe9833b-2a5c-47d5-a455-87e00d3797cf
title: DefaultDocLink
domain: adhsdk://recipes/doc-link
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Injectable link component that renders an anchor element with customizable
  destination path.
platforms:
- typescript
- web
tags:
- link
- routing
- injection
depends-on: []
related:
- adhsdk://recipes/doc-breadcrumbs
- adhsdk://recipes/doc-nav
references: []
approved-by: ''
approved-date: ''
---

# DefaultDocLink

## Overview

DefaultDocLink is a simple, injectable link component that wraps an HTML anchor element. It accepts a `to` prop for the destination path instead of the standard `href` attribute, allowing hosts to inject custom link behavior through a router adapter. This component serves as the default fallback for environments without a router (plain React apps, tests, Storybook stories), while router-aware applications (such as Next.js) can provide their own adapter via component injection.

## Behavioral Requirements

- **render-as-anchor**: The component MUST render as an HTML `<a>` element.
- **accept-to-prop**: The component MUST accept a `to` prop (string) specifying the destination path.
- **pass-to-href**: The component MUST pass the `to` prop value to the `href` attribute of the rendered anchor element.
- **accept-children**: The component MUST accept `children` (ReactNode) as the link text content.
- **render-children**: The component MUST render `children` inside the anchor element.
- **accept-and-spread-attributes**: The component MUST accept additional HTML anchor attributes (via `Omit<AnchorHTMLAttributes, "href">`) and pass them through to the rendered anchor element without modification. `{...rest}` is spread after `href={to}` in JSX, so the `Omit` type is what keeps `to` authoritative for `href` in normal, typed usage; a caller that bypasses the type system to smuggle `href` into the spread attributes would have that value win over `to`.
- **conforms-to-doclinkcomponent**: The component MUST be structurally assignable to the `DocLinkComponent` type (`ComponentType<{ to: string; children?: ReactNode } & Omit<AnchorHTMLAttributes<HTMLAnchorElement>, "href">>`), so consumers such as `doc-breadcrumbs` and `doc-nav` can substitute an alternate implementation (for example, a Next.js `Link` adapter) in its place without changing their own code.
- **non-empty-accessible-label**: The caller SHOULD provide non-empty `children` or an `aria-label`; an anchor with no accessible text confuses assistive technology users even though it remains focusable.

## Appearance

- **Styling**: The component applies no visual styling; it renders an unstyled HTML anchor that inherits browser default link appearance (typically blue, underlined text, per the browser's user-agent stylesheet).
- **Text rendering**: Link text from `children` is rendered as provided; the component does not transform, truncate, or modify content.

## States

Not applicable — the component is stateless and renders a passive link with no internal state management or interactive states beyond the browser's native anchor element behavior (source: no useState calls, no conditional rendering).

## Accessibility

- **Role**: The component renders a native HTML anchor element, which has an implicit link role in assistive technologies — but only while `href` is present; see the **missing-to-prop** edge case for the case where it is not.
- **Label**: Link text from `children` serves as the accessible label when non-empty; see **non-empty-accessible-label** and the **null-or-undefined-children** edge case for the empty case.
- **Focus**: The anchor element receives keyboard focus by default in all browsers, provided `href` is set.
- **Keyboard navigation**: The link is keyboard-navigable via the Enter key following native anchor behavior (source: native `<a>` element).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-link-001 | render-as-anchor | `<DefaultDocLink to="/docs">Link</DefaultDocLink>` | Renders as `<a href="/docs">Link</a>` in the DOM |
| doc-link-002 | accept-to-prop, pass-to-href | `to="/about"` | `href` attribute equals `/about` |
| doc-link-003 | accept-children, render-children | `children="Home"` | Link text displays as "Home" inside the anchor |
| doc-link-004 | accept-children, render-children | Multiple child elements (text + JSX) | All children render inside the anchor element |
| doc-link-005 | accept-and-spread-attributes | `className="nav-link"` and `data-testid="home-link"` | Both attributes present on the rendered anchor element |
| doc-link-006 | accept-and-spread-attributes | `onClick={handler}` passed as a prop | Handler is called when the link is clicked |
| doc-link-007 | pass-to-href, render-children | `to="/docs"` and `children="Read Docs"` | Renders as `<a href="/docs">Read Docs</a>` |
| doc-link-008 | empty-to-prop | `to=""` | Renders `<a href="">Link</a>`; the browser treats the empty `href` as navigation to the current page |
| doc-link-009 | missing-to-prop | `to={undefined}` (bypassing the type system) | React omits the `href` attribute entirely rather than rendering the literal string `"undefined"`; the resulting `<a>` has no `href`, so it is excluded from the tab order and is not exposed with the link role until a valid `href` is set |
| doc-link-010 | null-or-undefined-children, non-empty-accessible-label | `children={null}` and no `aria-label` | Anchor renders with no visible text and no accessible name; assistive technology announces it as an unlabeled link |
| doc-link-011 | unsafe-to-scheme | `to="javascript:alert(1)"` | `href` renders as `javascript:alert(1)` unchanged; the component performs no scheme validation |
| doc-link-012 | accept-and-spread-attributes | `href="/other"` forced into the spread attributes via a type-unsafe cast | Because `{...rest}` spreads after `href={to}`, the runtime `href` from the spread wins over `to` |
| doc-link-013 | conforms-to-doclinkcomponent | `const Link: DocLinkComponent = DefaultDocLink` | Type-checks without error, confirming `doc-breadcrumbs` and `doc-nav` can substitute a custom implementation (e.g., a Next.js adapter) in its place |

## Edge Cases

- **empty-to-prop**: If `to` is an empty string, the anchor renders with `href=""`, which navigates to the current page (browser default behavior).
- **missing-to-prop**: The prop is required by the TypeScript interface; calling without it produces a type error. At runtime, if `undefined` is passed, React omits the `href` attribute entirely (it does not render the literal string `"undefined"`); an `<a>` without `href` is not focusable and is not exposed with the link role.
- **null-or-undefined-children**: If `children` is null or undefined, the anchor renders as an empty element (`<a href="/path"></a>`). The link remains focusable and keyboard-navigable but has no visible or accessible text — see **non-empty-accessible-label**.
- **unsafe-to-scheme**: The component does not validate the destination path or URL scheme; any value passed to `to` — including an unsafe scheme such as `javascript:` — is rendered directly as `href` without sanitization. If `to` can originate from untrusted or user-supplied data, the caller is responsible for validating or allow-listing the scheme before passing it in; see the `input-sanitization` row in Compliance.

## Configuration

Not applicable — the component accepts only React props (`to`, `children`, and HTML anchor attributes); no external configuration mechanism is available (source: functional component with prop-based parameters only).

## Deep Linking

Not applicable — this component is a rendering primitive for constructing links, not an app entry point; deep linking behavior is determined by the application's router implementation and how it handles the `to` value (source: component accepts any path without validation or routing logic).

## Localization

Not applicable — the component contains no hardcoded strings; all text content comes from the `children` prop, making localization the caller's responsibility (source: no string literals in the component body).

## Accessibility Options

Not applicable — this component responds only to browser-level accessibility features (high contrast mode, prefers-reduced-motion) through inherited CSS and the native anchor element; it defines no custom responses to accessibility display options (source: no accessibility-specific conditional logic).

## Feature Flags

Not applicable — the component has no conditional behavior or feature-gated code paths; it always renders the same way regardless of any flags (source: single unconditional render path).

## Analytics

Not applicable — this component does not emit tracking events; analytics is handled by the application's router or by click handlers passed via props (source: no analytics calls in the component).

## Privacy

Not applicable — this component does not collect, store, or transmit user data (source: no data handling).

## Logging

Not applicable — this component does not emit log messages (source: no logging calls).

## Platform Notes

- **SwiftUI**: Start from `Link` wrapping a label. The injection seam can be reproduced with a custom `EnvironmentKey` holding a link-rendering view builder, injected via `.environment(...)` and read by call sites — unlike a component prop, this is SwiftUI's environment-based equivalent of injection, not an unsupported pattern.
- **Compose**: Start from `Text` with an `AnnotatedString` carrying a `LinkAnnotation.Url`; the older `ClickableText` API this superseded is deprecated. Differs: Compose requires imperative navigation handlers passed as callbacks rather than injected components.
- **React/Web**: `packages/web/packages/ui/src/blocks/doc-link.tsx` — wraps an HTML `<a>` element and accepts a `to` prop (not `href`) to enable router adapter injection at runtime (e.g., Next.js Link). Specific to web due to native anchor element and href semantics.
- **AppKit / UIKit**: Start from `NSTextField`/`NSTextView` (AppKit) or `UITextView` (UIKit) with an `NSAttributedString.Key.link` attribute on the destination text; handle taps through the view's link-click delegate. Differs: neither platform has a discrete hyperlink button type, so implement the adapter pattern by passing navigation callbacks that intercept the link-click delegate instead of injected components.
- **WinUI 3**: Start from `HyperlinkButton` bound to `NavigateUri`, but `NavigateUri` launches the system handler (e.g., the default browser) rather than routing inside the app. Differs: for in-app navigation, use `HyperlinkButton`'s `Click` event to call `Frame.Navigate` directly instead of `NavigateUri`, since XAML's declarative navigation model does not support component injection.

## Design Decisions

- **Decision**: Use `to` instead of `href` for the destination prop.
  **Rationale**: Matches the `DocLinkComponent` interface contract used by `doc-breadcrumbs` and `doc-nav` for router-adapter injection on web; other platforms use a different injection mechanism (see Platform Notes), so this is a web-specific naming choice rather than a claim of one signature shared across platforms.
  **Approved**: pending

- **Decision**: Perform no internal validation of `to`.
  **Rationale**: The component trusts the caller to provide a valid, safe destination path. Validating and sanitizing untrusted values — including blocking unsafe schemes such as `javascript:` — is the host application's responsibility, since it has the context about where `to` originates.
  **Approved**: pending

- **Decision**: Apply no visual styling.
  **Rationale**: Delegating all appearance to CSS and browser defaults enables composition into different UI contexts (breadcrumbs, navigation trees, etc.) without tight coupling to a specific design system.
  **Approved**: pending

- **Decision**: Spread remaining props onto the anchor element.
  **Rationale**: Lets callers apply arbitrary HTML attributes, event handlers, and styling without modifying the component. Because `{...rest}` spreads after `href={to}` (see **accept-and-spread-attributes**), the `Omit<AnchorHTMLAttributes, "href">` type is what keeps `to` authoritative for `href` in normal, typed usage.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | failed | Security |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The native `<a>` element gives keyboard operability and correct implicit markup for free (source: `doc-link.tsx` renders a plain `<a href>` with no custom ARIA and no key handling of its own); screen-reader-support is only partial because `children` may be null or undefined, leaving the link with no accessible name (see **null-or-undefined-children**); input-sanitization fails because `to` is passed straight into `href` with no path or scheme validation anywhere in the source (see **unsafe-to-scheme**). `separation-of-concerns` passes because `DefaultDocLink` renders a plain `<a href>` with no business logic; `unit-test-coverage` fails because no test file exercises `doc-link.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; corrected the missing-`to` and browser-underline claims; documented the `javascript:`-scheme risk and spread/href precedence instead of claiming no security surface; corrected Platform Notes APIs (UIKit, Compose, WinUI 3, SwiftUI); rephrased the props-naming decision as web-specific; converted Design Decisions and Compliance to the required formats; added the injection-seam and accessible-label requirements with test vectors; renamed the component to DefaultDocLink throughout; added tags and related recipes |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
