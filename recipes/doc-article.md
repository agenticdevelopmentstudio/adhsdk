---
id: eb0b16a5-f27e-4b28-9517-12bedc892b7f
title: Doc Article
domain: adhsdk://recipes/doc-article
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Renders pre-rendered document HTML with prose typography and a heading
  scroll offset.
platforms:
- typescript
- web
tags:
- prose
- content
- html-rendering
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Doc Article

## Overview

DocArticle is a container component for rendering pre-rendered, trusted document HTML with Tailwind prose styling applied. It wraps build-time rendered content (e.g., markdown converted to HTML at build time) and applies consistent typography, a heading scroll offset, and semantic structure. The component is designed for static prose content only — the host is responsible for sanitizing and producing the HTML before passing it to the component.

## Behavioral Requirements

- **html-prop**: Component MUST accept a required `html` string containing pre-rendered document markup.
- **unescaped-html-rendering**: Component MUST render the provided HTML string unescaped, so headings, links, and formatting in the markup appear as authored rather than as literal text.
- **prose-typography**: Component MUST apply prose typography to the rendered content — consistent styling for headings, paragraphs, lists, tables, and code blocks.
- **semantic-element-selection**: Component MUST accept an `as` prop that selects the rendered element's tag: `article`, `div`, or `section`.
- **default-article-element**: Component MUST render as an `article` element when `as` is not provided.
- **attribute-passthrough**: Component MUST forward standard HTML attributes it receives (other than `children` and the HTML-rendering mechanism) to the rendered element.
- **class-name-override**: Component MUST accept a `className` prop and merge it with its own typography classes rather than replacing them.
- **code-pseudo-content-removal**: Component MUST render code blocks without generated quote glyphs before or after their content.
- **heading-scroll-offset**: Component MUST give headings a scroll margin so that jumping to an anchor does not hide the heading under fixed UI above the content.
- **children-prop-ignored**: The `children` prop MUST NOT be part of the component's public API; HTML content MUST be supplied exclusively via the `html` prop. This is a compile-time exclusion only (`Omit<..., "children">` on the props type) — the destructured `...rest` still carries a forced-through `children` value at runtime, and spreading it onto the element alongside `dangerouslySetInnerHTML` throws (React allows only one of the two); `children` is not silently dropped.

## Appearance

- **Typography**: Follows Tailwind prose classes for consistent document rendering (headings, paragraphs, lists, tables, code blocks inherit prose styling).
- **Heading scroll offset**: A scroll margin is applied to all heading elements to account for fixed UI above when anchor links jump to headings.
- **Code block styling**: Pseudo-elements (`::before`, `::after`) removed from inline and block code to prevent stray glyphs.
- **Width constraint**: `max-w-none` allows the component to fill its container width; prose is not constrained to a specific column width.
- **Padding and margin**: Inherited from prose classes; no additional padding or margin applied by the component itself.

## States

| State | Appearance change |
|-------|------------------|
| Default | Prose typography applied; headings have scroll offset; code blocks styled as prose |

## Accessibility

- **Semantic element selection**: The `as` prop allows the host to choose semantically appropriate elements (`article` for standalone documents, `div` for document fragments, `section` for sections within larger pages). This choice directly affects accessibility announcements and document structure.
- **Heading navigation**: The HTML the host supplies MUST use correctly nested heading levels (`<h1>`–`<h6>`). This is a host responsibility, not something DocArticle can enforce — headings are ordinary elements inside the rendered HTML, and screen readers announce them based on standard heading semantics the host's markup provides.
- **Scroll offset for anchor navigation**: The scroll offset ensures that when an anchor link jumps a page to a heading, the heading is not obscured by fixed navigation bars above, preserving readability and accessibility for keyboard and screen reader users.
- **Code block clarity**: Removal of pseudo-content from code blocks ensures screen reader announcements of code are accurate and not cluttered with generated content.
- **Link semantics**: Links within the rendered HTML MUST be properly marked and MUST be navigable via keyboard and assistive technology. This is a host responsibility — DocArticle renders whatever anchor markup the HTML string contains.
- **Image alternatives**: Any images in the rendered HTML MUST have alt text. This is a host responsibility — DocArticle does not inspect or modify the HTML it renders.
- **Color contrast**: The prose classes inherit text and background colors from the document's theme; the host is responsible for ensuring color contrast meets WCAG standards.
- **Resize text**: Text and spacing within prose rendering SHOULD scale appropriately if the user enlarges text via browser or OS settings (inherited from prose classes and browser rendering).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-article-001 | html-prop | `html="<p>Hello world</p>"` | Component renders without error; paragraph is displayed |
| doc-article-002 | unescaped-html-rendering | `html="<strong>Bold text</strong>"` | Text appears bold in the rendered output (HTML is not escaped) |
| doc-article-003 | prose-typography | `html="<h1>Heading</h1><p>Body</p>"` | Heading and paragraph receive prose typography styling |
| doc-article-004 | default-article-element | `html="<p>Content</p>"` (no `as` prop) | Component renders as `<article>` element in the DOM |
| doc-article-005 | semantic-element-selection | `as="div"` with `html="<p>Content</p>"` | Component renders as `<div>` element |
| doc-article-006 | semantic-element-selection | `as="section"` with `html="<p>Content</p>"` | Component renders as `<section>` element |
| doc-article-007 | attribute-passthrough | `id="doc-1" data-test="value"` with `html="<p>Test</p>"` | Attributes are present on the rendered element |
| doc-article-008 | class-name-override | `className="custom-class"` with `html="<p>Test</p>"` | Component has both prose class and custom class applied |
| doc-article-009 | heading-scroll-offset | `html="<h2>Section</h2>"` | Heading has a scroll margin applied |
| doc-article-010 | code-pseudo-content-removal | `html="<code>const x = 1;</code>"` | Code block has no `::before` or `::after` pseudo-elements |
| doc-article-011 | children-prop-ignored | `children="Ignored"` with `html="<p>From HTML</p>"` | `children` is excluded from the props type at compile time, so this requires a type-system bypass to construct at all. Forced through at runtime, `children` lands in `...rest` and is spread onto the element alongside `dangerouslySetInnerHTML`; React throws "Can only set one of `children` or `props.dangerouslySetInnerHTML`." and nothing renders — the component does not silently ignore `children` |
| doc-article-012 | html-prop | `html=""` | Component renders the element with no content and no error |
| doc-article-013 | semantic-element-selection | `as="span"` (an unsupported value) | TypeScript rejects the value at compile time; if forced past the type system, the component renders using the given tag name |
| doc-article-014 | unescaped-html-rendering | `html='<img src="x" onerror="handler()">'` | The `onerror` handler fires: inline event-handler attributes execute when the browser parses HTML inserted this way, unlike `<script>` content. Hosts MUST NOT pass untrusted HTML to this component without sanitizing it first |

Vectors doc-article-009 and doc-article-010 assert computed style only in a test environment where the compiled Tailwind CSS is loaded; without that stylesheet, assert the presence of the prose typography classes on the element instead of the computed style. Vector doc-article-011 needs a `@ts-expect-error` (or equivalent) comment to pass a `children` prop past the type system, since `Omit` excludes it at compile time; expect the render itself (`renderToString` or `createRoot().render`) to throw rather than to succeed with `children` dropped. Vector doc-article-013 likewise needs a type-system bypass (e.g., a cast) to pass an unsupported `as` value.

## Edge Cases

- **Empty HTML string**: If `html=""` is passed, the component renders an empty element with prose classes applied. Expected behavior: a visually empty container with no content.
- **HTML without semantic structure**: If `html` contains only inline text with no paragraph or heading tags, the text is rendered directly. Expected behavior: text appears unstyled (prose classes only style semantic elements).
- **Very large HTML documents**: Large documents with thousands of elements may impact rendering performance. No specific size limit is enforced; the browser's DOM rendering performance applies.
- **HTML with event handlers**: If the rendered HTML includes inline event-handler attributes (e.g., `onclick`, `onerror`), they DO fire — inline handler attributes execute when the browser parses markup inserted this way, unlike `<script>` content. Expected behavior: hosts MUST sanitize any HTML that is not fully trusted before passing it to DocArticle; the component performs no sanitization itself (see **unescaped-html-rendering**).
- **HTML with script tags**: If the rendered HTML includes `<script>` tags, they MUST NOT execute. Expected behavior: unescaped rendering inserts script tags as inert DOM elements without executing them.
- **Missing html prop**: `html` is a required `string` prop, so TypeScript prevents omitting it at compile time. If the type system is bypassed and `html` is `undefined` or `null` at runtime, the component renders an empty element, since no `innerHTML` is set for a nullish value.
- **HTML with inline styles conflicting with prose**: If rendered HTML includes inline `style` attributes that conflict with prose classes (e.g., `<p style="color: red;">`), inline styles take precedence in CSS specificity. Expected behavior: inline styles override prose classes.

## Configuration

Not applicable: DocArticle does not expose configuration options. Behavior is determined entirely by the `html` and `as` props.

## Deep Linking

Not applicable: DocArticle does not implement deep linking. Link navigation within the rendered HTML is handled by the browser's default link behavior.

## Localization

Not applicable: DocArticle renders only the HTML provided by the host. Localization of content is the host's responsibility.

## Accessibility Options

- **Reduce Motion**: The prose classes and scroll behavior do not include animations or transitions affected by the `prefers-reduced-motion` media query. Expected behavior: no additional changes needed for reduced-motion users.
- **Increase Contrast**: Prose classes inherit text and background colors from the document's theme. If the theme respects `prefers-contrast`, prose rendering will reflect increased contrast.
- **Differentiate Without Color**: Whether links in the rendered HTML are visually distinguishable without relying on color (e.g., underlined) depends on the host's prose theme and CSS; DocArticle does not enforce or guarantee this itself. The host is responsible for choosing a prose theme where such affordances are present.

## Feature Flags

Not applicable: DocArticle does not respond to feature flags.

## Analytics

Not applicable: DocArticle does not emit analytics events. The host is responsible for tracking user interactions with content.

## Privacy

Not applicable: DocArticle does not collect or transmit data. The component is a pure rendering layer for host-provided HTML.

## Logging

Not applicable: DocArticle does not produce debug or error logs.

## Platform Notes

- **React/Web**: Native implementation in `packages/web/packages/ui/src/blocks/doc-article.tsx`. Applies the class list `prose max-w-none prose-headings:scroll-mt-20 prose-code:before:content-none prose-code:after:content-none` (Tailwind Typography) for prose typography, heading scroll offset, and code-pseudo-content removal, merged with any host-supplied `className` via a class-merging utility. Exports `DOC_ARTICLE_PROSE_CLASS` for reuse in other prose contexts. `Omit<HTMLAttributes<HTMLElement>, "children" | "dangerouslySetInnerHTML">` excludes `children` from the props type at compile time.
- **SwiftUI**: Use SwiftUI's `WebView` (iOS 26 / macOS 26+) to render the HTML, or `WKWebView` on earlier deployment targets, with equivalent prose CSS injected into the page. Support semantic element choice by wrapping the injected HTML in the requested tag name (`article`, `div`, `section`) rather than via a view modifier, which has no native meaning here.
- **Compose**: Use Compose's `AndroidView` with Android's `WebView`, or a third-party Markdown/HTML rendering library. Apply prose styling via CSS injected into the web view. Support semantic element selection by wrapping the injected HTML in the requested tag.
- **AppKit / UIKit**: Use `WKWebView` on both iOS and macOS (the legacy AppKit `WebView` is deprecated). Inject CSS containing the prose typography, heading scroll-margin, and code pseudo-content rules. Support the `as` parameter by wrapping the injected HTML in the requested tag.
- **WinUI 3**: Use XAML `WebView2`'s `NavigateToString` method to load the HTML with the prose CSS inlined in a `<style>` block, rather than injecting styles after the fact. Support semantic element selection by wrapping the injected HTML in the requested tag (`article`, `div`, or `section`).

## Design Decisions

- **dangerouslySetInnerHTML over children**
  **Decision**: The component renders host-supplied HTML directly rather than accepting pre-rendered React elements as children.
  **Rationale**: The host needs to control the exact HTML string (for build-time markdown rendering, external content sources, etc.). This design pushes the responsibility for sanitization and trust onto the host, which is appropriate for build-time rendered content.
  **Approved**: pending

- **Scroll margin on headings**
  **Decision**: A scroll offset (5rem / 80px) is applied to headings.
  **Rationale**: The offset accounts for fixed navigation or header UI that may be present above the document, so anchor links to headings do not disappear under fixed UI. The 5rem value is a cross-platform default; hosts MAY override this via the `className` prop if their layout requires a different offset.
  **Approved**: pending

- **Removal of code pseudo-content**
  **Decision**: Pseudo-elements are stripped from code blocks (see **code-pseudo-content-removal**).
  **Rationale**: Tailwind Typography's own `code::before`/`::after` rules add quote glyphs around inline and block code by default. Removing them ensures clean code block rendering and accurate screen reader announcements.
  **Approved**: pending

- **No direct support for HTML sanitization**
  **Decision**: The component does not sanitize or validate the `html` prop.
  **Rationale**: The host MUST trust the HTML source and sanitize it before passing it to DocArticle. For user-submitted content, the host MUST use a sanitization library (e.g., `sanitize-html`, `DOMPurify`) before rendering.
  **Approved**: pending

- **HTMLAttributes spread**
  **Decision**: The component forwards standard HTML attributes to hosts via `Omit<HTMLAttributes<HTMLElement>, "children" | "dangerouslySetInnerHTML">`.
  **Rationale**: This allows hosts to pass arbitrary HTML attributes (id, data-* attributes, aria-* attributes) while explicitly blocking misuse of `children` and the HTML-rendering mechanism.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | failed | Security |
| [content-security-policy](agenticdevelopercookbook://compliance/security#content-security-policy) | partial | Security |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`semantic-markup` passes because the `as` prop lets the host choose the correct landmark element for the rendered content. `dynamic-type-support` is partial because text sizing is inherited from the host's prose theme, which the source neither controls nor can vouch for. `input-sanitization` fails because the component explicitly performs no sanitization on the `html` prop by design (see **No direct support for HTML sanitization**). `content-security-policy` is partial because DocArticle renders raw HTML without enforcing a policy itself, leaving CSP enforcement to the host page. `separation-of-concerns` passes because `DocArticle` only forwards the `html` and `as` props with no business logic; `unit-test-coverage` passes because `docArticle.test.tsx` imports `DocArticle` directly and exercises its behavior with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed children/dangerouslySetInnerHTML doc: Omit is compile-time only; forced-through children causes a React throw. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; restated requirements as platform-neutral behavior and moved the Tailwind class string to Platform Notes; corrected inline-event-handler security guidance, the summary/overview wording, and the code-pseudo-content rationale; fixed the SwiftUI and WinUI 3 platform notes; added a compliance table, new test vectors, and assertion guidance for existing vectors; reformatted Design Decisions to the Decision/Rationale/Approved form; reworded accessibility bullets that are really host obligations |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
