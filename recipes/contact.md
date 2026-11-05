---
id: 8c5e2f9b-7d3a-4a1c-b8e4-9f2d1c5a7b3e
title: Contact
domain: adhsdk://recipes/contact
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A closing section component that composes a title, body content, mailto link,
  and optional colophon.
platforms:
- typescript
- web
tags:
- contact
- footer
- closing
depends-on:
- adhsdk://recipes/closer
related: []
references: []
approved-by: ''
approved-date: ''
---

# Contact

## Overview

The Contact component renders a page closing section that wraps a Closer component and adds a mailto link and optional colophon paragraph. It is used as the final element of a landing page, providing contact information and optional attribution or supplementary text.

## Behavioral Requirements

- **title-prop**: Component MUST accept a `title` prop of type `ReactNode`.
- **children-prop**: Component MUST accept a `children` prop of type `ReactNode`.
- **mail-prop**: Component MUST accept a `mail` prop with `href` (string) and `label` (ReactNode) properties.
- **mail-link-render**: Component MUST render an anchor element with `href` attribute matching `mail.href` and text content matching `mail.label`, appended to `Closer`'s children immediately after the caller-supplied `children`.
- **mailto-scheme**: `mail.href` SHOULD use the `mailto:` scheme so the rendered link opens the user's mail client.
- **colophon-prop**: Component MUST accept an optional `colophon` prop of type `ReactNode`.
- **colophon-paragraph**: Component MUST render a paragraph element with colophon content when `colophon` is not `undefined`.
- **closer-composition**: Component MUST compose the `Closer` component rather than duplicating its markup, passing `title` and `children` through to `Closer` and adding the mail link and optional colophon as further children after the caller's `children`, in that order.
- **css-classes**: The composed element MUST carry both the `lp-closer` class (applied by `Closer`) and the `lp-contact` class; the mailto link MUST carry `lp-mail`; the optional colophon paragraph MUST carry `lp-colophon`.

## Appearance

Styling is provided via external CSS rules (`.lp-contact`, `.lp-mail`, `.lp-colophon` selectors in `css/blocks.css`). The component renders semantic HTML elements without inline styles.

## States

| State | Appearance change |
|-------|------------------|
| Default | Selector `.lp-contact a.lp-mail`: accent-bright color, no underline, thin bottom border in the hairline color |
| Hover | Selector `.lp-contact a.lp-mail:hover`: border color brightens to `--lp-accent` |
| Visited / Focus / Active | No dedicated CSS rule exists in `css/blocks.css`; the browser's default styling applies |

## Accessibility

- **semantic-link**: The mailto link MUST be rendered as an `<a>` element with a valid `href` attribute (`mailto:...`).
- **link-label**: The link MUST contain non-empty visible text (from `mail.label`) that describes the contact action; an empty or missing label renders an unlabeled but still-focusable anchor, which fails this requirement.
- **keyboard-support**: The link SHOULD be keyboard-accessible via standard browser link navigation (Tab key, Enter to activate).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| contact-001 | mail-prop, mail-link-render, semantic-link | `mail: { href: "mailto:test@example.com", label: "Email us" }` | Rendered `<a href="mailto:test@example.com">Email us</a>` element |
| contact-002 | css-classes | Any valid props | Link has class `lp-mail` |
| contact-003 | colophon-paragraph | `colophon: "© 2026 Example"` | Rendered `<p class="lp-colophon">© 2026 Example</p>` |
| contact-004 | closer-composition, title-prop, children-prop | `title: "Get in Touch"`, `children: <p>We'd love to hear from you</p>` | `Closer` receives `title` unchanged; `Closer`'s rendered children are the caller's `children`, followed by the mail link, followed by the optional colophon, in that order |
| contact-005 | colophon-paragraph | `colophon: undefined` | No colophon paragraph rendered |
| contact-006 | css-classes | Any valid props | Composed element matches the compound selector `.lp-closer.lp-contact` |
| contact-007 | link-label | `mail: { href: "mailto:test@example.com", label: "" }` | Anchor renders with empty text content, failing **link-label** |
| contact-008 | mailto-scheme | `mail: { href: "https://example.com/contact", label: "Contact" }` | Anchor `href` does not use the `mailto:` scheme, failing **mailto-scheme** |
| contact-009 | colophon-paragraph | `colophon: ""` | Rendered `<p class="lp-colophon"></p>` (empty paragraph present in the DOM) |
| contact-010 | closer-composition | `children: undefined` | `Closer` receives `children: undefined` unchanged |
| contact-011 | closer-composition | `title: undefined` | `Closer` receives `title: undefined` unchanged |

## Edge Cases

- **Null or empty mail.label**: If `mail.label` is an empty string or null, the rendered anchor has no visible text, failing **link-label** (contact-007); the anchor element still exists and is focusable.
- **Invalid mail.href**: If `mail.href` does not use the `mailto:` scheme, the link renders but may not open the user's mail client as expected, failing **mailto-scheme** (contact-008). This is a source fidelity gap: the component performs no validation.
- **Empty colophon**: If `colophon` is an empty string, the paragraph still renders per **colophon-paragraph**, because the check is for `undefined`, not falsy values; an empty paragraph is rendered to the DOM (contact-009).
- **Children prop omitted**: If `children` is not provided, React passes `undefined` through to `Closer` unchanged (contact-010); `Closer`'s own handling of missing children determines the outcome, since Contact performs no validation.
- **Title prop omitted**: If `title` is not provided, React passes `undefined` through to `Closer` unchanged (contact-011); `Closer`'s own handling of missing title determines the outcome.

## Configuration

Not applicable: This component accepts props (title, children, mail, colophon) but does not support configuration options or environment variables.

## Deep Linking

Not applicable: This is a component, not a page. It does not define URL patterns or deep linking behavior.

## Localization

Not applicable: The component accepts all text content as props (`title`, `children`, `mail.label`, `colophon`) and does not contain hardcoded user-facing strings. Localization is the responsibility of the calling code.

## Accessibility Options

Not applicable: This component does not respond to accessibility display options (e.g., Reduce Motion, Increase Contrast, Differentiate Without Color). Styling applied via CSS may respond to these options if defined in the style rules.

## Feature Flags

Not applicable: This component does not implement feature flag logic or conditional rendering based on feature flags.

## Analytics

Not applicable: This component does not emit analytics events. Event tracking is the responsibility of the calling code or click handlers added to the mail link.

## Privacy

Not applicable: This component does not collect, store, or transmit any data. The `mail.href` is user-provided and may contain a mailto URL; no PII handling occurs within the component.

## Logging

Not applicable: This component does not perform any logging.

## Platform Notes

- **Web (TypeScript/React)**: Implemented in `packages/web/packages/landing/src/blocks/Contact.tsx`. Accepts props for title, children, mail object (with href and label), and optional colophon. Renders as a composition of the `Closer` component with an injected `<a class="lp-mail">` link and conditional `<p class="lp-colophon">` paragraph, appended after the caller's `children` in that order. CSS classes `lp-contact`, `lp-mail`, and `lp-colophon` are applied for styling via external stylesheet.
- **SwiftUI**: Compose the SwiftUI `Closer` port (`adhsdk://recipes/closer#platforms/swiftui`) rather than rebuilding its title/content layout; add a `Link` control pointing at the `mailto:` URL as an additional child after the caller's content, and conditionally append a `Text` view for the colophon.
- **Compose**: Compose the Compose `Closer` port (`adhsdk://recipes/closer#platforms/compose`) rather than rebuilding its `Column`/title/content layout; add the mailto action as `Text` with a `LinkAnnotation.Url` inside an `AnnotatedString` (`ClickableText` is deprecated) as an additional child after the caller's content, and conditionally append another `Text` for the colophon.
- **AppKit / UIKit**: Compose the AppKit/UIKit `Closer` port (`adhsdk://recipes/closer#platforms/appkit-uikit`) rather than rebuilding its stack-view/title/content layout; add a `UIButton` / `NSButton` (or link-styled control) configured to open the `mailto:` URL as an additional arranged subview after the caller's content, and conditionally append a `UILabel` / `NSTextField` for the colophon.
- **WinUI 3**: Compose the WinUI 3 `Closer` port (`adhsdk://recipes/closer#platforms/winui-3`) rather than rebuilding its `StackPanel`/title/content layout; add a `HyperlinkButton` with `NavigateUri` bound to the mail URL as an additional child after the caller's content, and conditionally append a `TextBlock` for the colophon.

## Design Decisions

**Decision**: `Contact` composes the `Closer` component rather than duplicating its markup, appending the mailto link and then the optional colophon after the caller's `children`.
**Rationale**: Sharing `Closer`'s markup keeps both components' styling and behavioral semantics in sync. The rendered element carries both `lp-closer` and `lp-contact` classes (see **css-classes**) so the compound selector `.lp-closer.lp-contact` in `css/blocks.css` — which the stylesheet's own comment says must stay compound rather than being split into separate rules — continues to apply.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `Contact.tsx` rendering a native `<a>` element with no ARIA overrides and no hardcoded user-facing strings (title, children, mail.label, and colophon are all caller-supplied props), which gives it a native accessible name and keyboard behavior once `mail.label` satisfies **link-label**; `contrast-ratio` is `partial` because `css/blocks.css` defines the link and colophon colors through CSS custom properties whose real computed contrast cannot be confirmed from source. separation-of-concerns passes because `Contact.tsx` is pure presentation that composes `Closer` and appends a mailto link and optional colophon over its props with no logic of its own, and unit-test-coverage passes because `blocks-close.test.tsx` renders `Contact` directly and asserts its `.lp-closer.lp-contact` composition and mailto link with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: correct the States table to the real `.lp-contact a.lp-mail` / `:hover` selectors and drop the unsupported visited/focus/active rows, rename requirements to subject-only kebab-case, state that the mail link and colophon are appended to Closer's children after the caller's `children` in that order and fix contact-004 to match, strengthen colophon rendering to a MUST, require both `lp-closer` and `lp-contact` on the composed element with a compound-selector test vector, add `mail.label` non-empty and `mail.href` mailto-scheme requirements with test vectors, reformat Design Decisions into Decision/Rationale/Approved form and move the compound-selector MUST into Behavioral Requirements, add a Compliance table, rewrite Platform Notes so each platform composes its own Closer port and replace the deprecated Compose `ClickableText`, add `Closer` to `depends-on`, and drop the quoted `modified` date. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
