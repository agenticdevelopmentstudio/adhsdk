---
id: d7a2af70-0812-4360-afa7-02be1a44e7b8
title: "Resource Card"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A content card for displaying a resource with title, optional identifier, description, and metadata in a navigational or interactive context."
platforms:
  - typescript
  - web
tags:
  - card
  - resource
  - navigation
  - interactive
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Resource Card

## Overview

ResourceCard is a flexible card component for displaying a resource (application, ecosystem entry, persona) with a title, optional reverse-domain identifier, optional description, and optional metadata chips. It serves three interactive modes: navigational (anchors to a URL via LinkComponent or native `<a>`), interactive (executes an onClick handler with role="button"), or inert (static content). The component prioritizes semantic HTML and browser affordances — when navigation is intended, it uses a real anchor rather than a simulated link, enabling middle-click, keyboard shortcuts, history, and status bar preview. It supports custom routing libraries through the LinkComponent prop and applies interactive styling (hover state, focus outline, cursor) only when interactive.

## Behavioral Requirements

- **render-title**: Component MUST render the `title` prop as plain text (the source renders a `<div>`, not a semantic heading element).
- **accept-href**: Component MUST accept an `href` prop and, when provided, render as an anchor element with the destination URL.
- **accept-onclick**: Component MUST accept an `onClick` prop and, when provided and `href` is not set, render as a button-role div with keyboard activation (Enter or Space key).
- **href-precedence**: When both `href` and `onClick` are provided, the component MUST render as an anchor, execute the `onClick` handler before navigation, and allow the navigation to proceed. `onClick` MUST NOT block navigation (e.g. by calling `preventDefault`, which would cancel it) and its return value MUST NOT be awaited — navigation happens synchronously with the click. Implementers with asynchronous side effects (analytics, logging) MUST use a fire-and-forget mechanism such as `navigator.sendBeacon` or a `fetch` call with `keepalive: true`, not a Promise the click handler waits on.
- **use-link-component**: When `href` is provided and `LinkComponent` prop is supplied, the component MUST use LinkComponent to render the anchor rather than a native `<a>` element, passing the destination as the `to` prop.
- **fallback-link-component**: When `href` is provided and `LinkComponent` is not supplied, the component MUST render a native `<a>` element (via the default `LinkComponent`, which wraps a plain `<a href>`).
- **keyboard-activation**: When `onClick` is provided without `href`, the component MUST respond to Enter and Space keys on `keydown` by invoking `onClick`, calling `preventDefault()` so Space does not scroll the page — the same scroll-prevention native `<button>` elements provide.
- **button-focusable**: When `onClick` is provided without `href`, the component MUST set `tabIndex={0}` on the button-role div so it participates in the default tab order.
- **optional-identifier**: Component MUST render the `identifier` prop as monospace text below the title when provided and non-empty; it MUST NOT render if `identifier` is undefined, null, or an empty string.
- **optional-description**: Component MUST render the `description` prop as paragraph text below the identifier (or title if no identifier) when provided and non-empty; it MUST NOT render if `description` is undefined, null, or an empty string.
- **optional-meta**: Component MUST render the `meta` prop as a flex-wrapped row of chips below the description when provided; it MUST NOT render if `meta` is undefined or null.
- **meta-no-nested-interactive**: When the card is interactive (`href` or `onClick` is set), `meta` MUST NOT contain interactive elements (links, buttons). Nesting an interactive element inside an anchor or a `role="button"` container is invalid HTML and unreachable by assistive technology.
- **interactive-styling**: When `href` or `onClick` is provided, the component MUST apply cursor-pointer, a hover state (stronger border and different background color), and a focus-visible state (gold-tinted border).
- **classname-support**: Component MUST accept a `className` prop and apply it to the outermost element, merging it with the default classes.
- **left-aligned-text**: Component MUST use `text-left` alignment for all text content. (Hardcoded to the physical left edge, not the logical start edge — see the `rtl-layout-support` compliance status below.)

## Appearance

- **Corner radius**: `rounded-xl` (border-radius 0.75rem / 12px)
- **Padding**: 5 (1.25rem / 20px on all sides)
- **Gap between sections**: 2 (0.5rem / 8px between title/identifier area, description, and meta)
- **Font (title)**: font-medium (500 weight), token role **text-primary** (`apt-text`)
- **Font (identifier)**: font-mono, text-xs (0.75rem / 12px), token role **text-muted** (`apt-text-muted`)
- **Font (description)**: text-sm (0.875rem / 14px), token role **text-muted** (`apt-text-muted`), line-clamped to 3 lines
- **Font (meta)**: font-mono, text-xs (0.75rem / 12px), token role **text-dim** (`apt-text-dim`), flex-wrapped with gap-x-4 (1rem / 16px) and gap-y-1 (0.25rem / 4px)
- **Border**: 1px solid, token role **border** (`apt-border`)
- **Background**: token role **surface** (`apt-surface`)
- **Layout**: flex column, full width, with transition-colors animation
- **Interactive hover**: border becomes token role **border-strong** (`apt-border-strong`); background becomes token role **surface-hover** (`apt-surface-2`)
- **Interactive focus-visible**: border becomes token role **focus-accent** (`apt-gold` at 60% opacity)
- **Interactive cursor**: pointer

## States

| State | Appearance Change |
|-------|------------------|
| Default | Static card with **surface** background and **border** border. |
| Hover (interactive only) | Border strengthens to **border-strong**; background becomes **surface-hover**. |
| Focus (interactive only) | Border becomes **focus-accent**; outline is visible via focus-visible pseudo-class. |

## Accessibility

- **Root element role**: When `href` is set, a native or LinkComponent-wrapped anchor element (implicit link role). When `onClick` is set without `href`, a div with `role="button"`. When neither is set, a div with no explicit role (content container).
- **Keyboard activation**: When role="button", Enter and Space keys MUST trigger the click handler. Anchor elements receive native browser keyboard support. See **keyboard-activation**.
- **Focus indicator**: Focus-visible state applies a visible border color change (focus-accent), satisfying visibility requirements.
- **Text labels**: Title is rendered as plain text; no aria-label or aria-description attributes are used in the component, so content must be self-describing.
- **Identifier label**: Identifier is rendered in monospace and is visually secondary; implementers should ensure context makes its purpose clear (e.g., via a label above it or in documentation).
- **Touch/click target size**: The card's default padding (1.25rem on all sides) combined with its full-width layout MUST produce a touch target of at least 44×44pt in normal use (a title-only card is already taller than 44pt once line-height and padding are included). Implementers who override the default padding or width via `className` are responsible for preserving this minimum.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| resource-card-001 | render-title | `title="My App"` | Title "My App" is rendered as plain text in font-medium. |
| resource-card-002 | accept-href | `href="/app"` | Root element is an anchor or LinkComponent with href="/app". |
| resource-card-003 | accept-onclick, button-focusable | `onClick={handler}` without href | Root element is a div with role="button" and tabIndex=0. |
| resource-card-004 | href-precedence | `href="/app"` and `onClick={handler}` | onClick handler is executed, then navigation to /app proceeds; navigation is not delayed by the handler. |
| resource-card-005 | use-link-component | `href="/app"` and custom LinkComponent | LinkComponent is rendered with to="/app" prop. |
| resource-card-006 | fallback-link-component | `href="/app"` without LinkComponent | Native `<a href="/app">` is rendered. |
| resource-card-007 | keyboard-activation | role="button" and Space key pressed | onClick handler is invoked and the keydown event's default action is prevented (no page scroll). |
| resource-card-008 | keyboard-activation | role="button" and Enter key pressed | onClick handler is invoked. |
| resource-card-009 | optional-identifier | `identifier="com.example.app"` | Identifier is rendered in monospace, text-xs, below title. |
| resource-card-010 | optional-identifier | No identifier prop, or `identifier=""` | No identifier text is rendered. |
| resource-card-011 | optional-description | `description="A great app"` | Description is rendered in text-sm, muted color, clamped to 3 lines. |
| resource-card-012 | optional-description | No description prop, or `description=""` | No description text is rendered. |
| resource-card-013 | optional-meta | `meta={<span>iOS</span>}` | Meta content is rendered in flex-wrapped row, monospace, text-xs. |
| resource-card-014 | optional-meta | No meta prop | No meta row is rendered. |
| resource-card-015 | interactive-styling | href or onClick provided | Cursor is pointer; hover and focus-visible states are applied. |
| resource-card-016 | interactive-styling | Neither href nor onClick provided | Cursor is default (not pointer); hover and focus states are not visible. |
| resource-card-017 | classname-support | `className="custom-class"` | Custom class is applied to the outermost element along with defaults. |
| resource-card-018 | left-aligned-text | Any props | Text content uses text-left alignment. |
| resource-card-019 | meta-no-nested-interactive | `href="/app"` and `meta={<a href="/x">link</a>}` | No `<a>`, `<button>`, or `[role="button"]` descendant exists inside `meta` when the card itself is an anchor or role="button" element. |

## Edge Cases

- **No props except title**: Card renders as inert div with title only. No errors occur.
- **Very long title**: Title text wraps to multiple lines within the card width. No truncation.
- **Very long identifier**: Identifier may wrap; recommend limiting identifier length in parent or using text-overflow/ellipsis in custom styling.
- **Description exceeds 3 lines**: Description is clamped to 3 lines via line-clamp-3; overflow text is hidden.
- **Meta content overflows horizontally**: Meta row uses flex-wrap to wrap items to the next line with gap-y-1 (0.25rem) between rows.
- **Both href and onClick with navigation**: onClick runs synchronously and is never awaited, so the anchor's navigation is not delayed by it — see **href-precedence**. Implementers MUST NOT call `preventDefault` to stall the click for an async side effect, since that cancels the navigation entirely; use `navigator.sendBeacon` or a `fetch` call with `keepalive: true` for fire-and-forget work instead.
- **Empty or null meta children**: If `meta` is present but contains no children, an empty flex row is rendered; no content or error. Callers should omit `meta` entirely rather than pass an empty node, to avoid the unwanted gap.
- **Interactive content in `meta` on an interactive card**: See **meta-no-nested-interactive**. Nesting a link or button inside an anchor or `role="button"` container is invalid HTML and unreachable by assistive technology; restrict `meta` to static chips (text, icons) when the card itself is interactive.

## Configuration

Not applicable: ResourceCard is a presentational component configured entirely through props; it does not accept a separate configuration object or settings interface.

## Deep Linking

Not applicable: ResourceCard itself does not implement deep linking; it delegates navigation to the anchor or LinkComponent, which handle URLs. Parent consumers can wire routes and navigation based on the `href` prop passed to ResourceCard.

## Localization

Not applicable: ResourceCard renders content passed in via props (title, identifier, description, meta); it does not provide built-in localization. All text content is supplied by the parent and should be pre-localized. Note that the card's own layout is not locale-aware: **left-aligned-text** hardcodes `text-left` rather than the logical `text-start`, so the card does not mirror for right-to-left locales (see the `rtl-layout-support` compliance status below).

## Accessibility Options

Not applicable: ResourceCard does not directly respond to platform accessibility display options (Reduce Motion, Increase Contrast, etc.). The `transition-colors` class applies a CSS transition on hover/focus state changes; it does not include a `motion-reduce:` variant, so the transition still plays for viewers with `prefers-reduced-motion` enabled — the browser does not suppress it automatically. Consumers who need to respect that preference should add `motion-reduce:transition-none` (or equivalent) via the `className` prop. Focus outline styling (focus-accent) is always present and is not affected by Increase Contrast or other options.

## Feature Flags

Not applicable: ResourceCard is a presentational component with no feature flags or runtime toggles.

## Analytics

Not applicable: ResourceCard does not emit analytics events. The onClick handler is provided by the parent and may trigger analytics if desired; the component itself performs no event logging.

## Privacy

Not applicable: ResourceCard does not collect, store, or transmit any data. It is a view-layer component that renders content provided by its parent.

## Logging

Not applicable: ResourceCard does not emit log messages or perform diagnostic logging.

## Platform Notes

- **SwiftUI**: SwiftUI has no direct ResourceCard equivalent. Implement with a VStack containing Text (title), optional Text (identifier in monospace), optional Text (description with line limit of 3), and optional HStack (meta chips). Apply the card appearance with `.padding()` and `.background(...)`/`.overlay(RoundedRectangle(cornerRadius:).stroke(...))` — there is no `Card` modifier in SwiftUI. Use NavigationLink to wrap the entire stack when navigation is needed, or use onTapGesture and button styling for onClick behavior. Replicate focus state with `.focusable()` and a border-color change on focus (matching the source's focus-visible border) rather than a scale effect.

- **Compose**: Android Material Design 3 provides a Card composable for layout and styling. Use `Modifier.clickable` for interactivity — `onClick = { navController.navigate(destination) }` for navigation, or `onClick = { onClickHandler() }` for interactive behavior — rather than an Intent, which is unrelated to Compose's click handling. Nest a Column for vertical layout (title, identifier, description, meta), each as Text or Row composables. Ripple feedback comes for free from `Modifier.clickable`'s default indication; apply `Modifier.clip` and `contentColor` for theming. Replicate focus state with `FocusRequester` and a `Modifier.border` color change on focus.

- **React/Web**: This is the reference implementation. Component is exported from `packages/web/packages/ui/src/blocks/resource-card.tsx`. Uses semantic HTML (native `<a>` or LinkComponent-wrapped anchor for navigation, div[role="button"] for onClick interactivity). Styling is driven by Tailwind CSS utility classes and semantic color tokens (apt-* family). Customization via className prop. No additional wrappers or theming layer needed.

- **AppKit / UIKit**: macOS AppKit: use an `NSView` subclass with an `NSTrackingArea` for hover feedback and an `NSClickGestureRecognizer` (or `mouseDown`/`mouseUp`) for click handling; for navigation, push a new view controller from the click handler. iOS UIKit: use a `UIControl` subclass (its built-in tap target, `isHighlighted`, and `sendActions(for: .touchUpInside)` cover the interaction) or a `UIButton` with a custom content view; for navigation, call `navigationController.pushViewController` from its action. Style the border and background with `layer.borderColor`/`layer.backgroundColor` — both are `CALayer`-backed views, not `NSAppearance`, which governs system chrome rather than a custom view's colors. Animate border/background changes on hover (macOS) or focus with `CABasicAnimation` or `UIView.animate`.

- **WinUI 3**: Windows has no `Card` control; use a `UserControl` (or a `Button` with a custom `ControlTemplate`) instead. Wrap the title/identifier/description/meta layout in a StackPanel or Grid and set it as the `Content` of the `UserControl` (or the `Button`'s `Content`, when the whole card should be a single focusable, clickable control). For navigation, use a HyperlinkButton or `Frame.Navigate()`; for onClick, use the Button's `Click` event. Apply `VisualStateManager` to define Normal, PointerOver, and Focused states (matching the source's default/hover/focus-visible states). Set `Foreground` and `Background` from theme resources (equivalent to the apt-* tokens). A real `Button` handles Enter/Space activation natively; a plain `UserControl` needs an explicit `KeyDown` handler for Enter/Space if it is not built on `Button`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/resource-card.tsx` | unverified |

## Design Decisions

1. **Decision**: `href` takes precedence over `onClick` — when both props are provided, the component renders as an anchor and executes `onClick` before navigation.
   **Rationale**: This prioritizes semantic HTML and browser affordances (middle-click, ⌘-click, history, status bar URL preview) while allowing side effects (analytics, state mutation) to occur first.
   **Approved**: pending

2. **Decision**: `div[role="button"]` is used for the `onClick` root instead of a native `<button>`.
   **Rationale**: The card's flow content (paragraph `<p>` for description, div for meta) is not valid inside a native button element. A div allows arbitrary children and is semantically correct when paired with `role="button"` and keyboard handlers.
   **Approved**: pending

3. **Decision**: The `LinkComponent` prop accepts a wrapper component (e.g. Next.js Link or React Router Link) instead of hard-coding a router dependency, and follows the `to` naming convention rather than `href`.
   **Rationale**: This matches the shared `DocLinkComponent` injection pattern (`packages/web/packages/ui/src/blocks/doc-types.ts`), used by every block in this family that accepts a router component (e.g. `doc-nav`, `doc-breadcrumbs`), so a host writes one adapter for all of them.
   **Approved**: pending

4. **Decision**: Hover, focus, and cursor-pointer styling are applied only when `href` or `onClick` is provided.
   **Rationale**: This avoids misleading static cards into appearing interactive and prevents unnecessary state management.
   **Approved**: pending

5. **Decision**: No built-in `aria-label` or `aria-description`.
   **Rationale**: The component relies on its rendered content (title, identifier, description) to be self-describing. Implementers should ensure context makes the purpose of each field clear or add aria-attributes at the parent level if more explicit labeling is needed.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Accessibility statuses rest on the source's native anchor/`role="button"` roots with keydown-based Enter/Space handling and `tabIndex={0}` (screen-reader-support, keyboard-navigable, semantic-markup), its rem-based Tailwind text sizes (dynamic-type-support), and its padding/full-width layout (touch-target-size); `contrast-ratio` is `partial` because the source references `apt-*` theme tokens rather than literal color values, and `reduced-motion` is `failed` because `transition-colors` has no `motion-reduce:` variant. Internationalization statuses rest on the component taking all user-visible text as props with no hardcoded strings (string-externalization, no-hardcoded-strings, unicode-support), its hardcoded `text-left` alignment (rtl-layout-support, `failed`), and its unclamped title alongside its 3-line-clamped description (text-expansion-tolerance, `partial`). The three-root branching (`href`/`onClick`/inert) is pure view logic over props with the router itself injected via `LinkComponent` (separation-of-concerns passed); `resourceCard.test.tsx` directly exercises all three roots, the injected `LinkComponent`, the combined href+onClick case, and the `className` override (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | (cookbook update) | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and updated every citation; replaced the "Not applicable" Compliance section with a real table; reformatted Design Decisions to the three-line form; corrected fictitious APIs in the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes; corrected the reduced-motion and touch-target-size accessibility claims; fixed the onClick/navigation edge case's contradiction with href-precedence; added the button-focusable and meta-no-nested-interactive requirements with test vectors; added semantic token roles to Appearance and States |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
