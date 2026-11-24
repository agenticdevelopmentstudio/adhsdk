---
id: d7a2af70-0812-4360-afa7-02be1a44e7b8
title: "Resource Card"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
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
related:
  - 0fe9833b-2a5c-47d5-a455-87e00d3797cf
  - ef7191ff-63a9-442a-b6d0-f8452a0aa1d6
  - c9c48e65-6905-4035-b8e1-e053219599f1
references: []
approved-by: ""
approved-date: ""
---

# Resource Card

## Overview

ResourceCard is a flexible card component for displaying a resource (application, ecosystem entry, persona) with a title, optional reverse-domain identifier, optional description, and optional metadata chips. It serves three interactive modes: navigational (anchors to a URL via LinkComponent or native `<a>`), interactive (executes an onClick handler with role="button"), or inert (static content). The component prioritizes semantic HTML and browser affordances — when navigation is intended, it uses a real anchor rather than a simulated link, enabling middle-click, keyboard shortcuts, history, and status bar preview. It supports custom routing libraries through the LinkComponent prop and applies interactive styling (hover state, focus outline, cursor) only when interactive.

## Behavioral Requirements

- **render-title**: Component MUST render the `title` prop inside a non-heading `div`; any `ReactNode` is accepted, so markup in `title` is allowed (the source renders a `<div>`, not a semantic heading element).
- **accept-href**: Component MUST accept an `href` prop and, when provided, render as an anchor element with the destination URL.
- **accept-onclick**: Component MUST accept an `onClick` prop and, when provided and `href` is not set, render as a button-role div with keyboard activation (Enter or Space key).
- **href-precedence**: When both `href` and `onClick` are provided, the component MUST render as an anchor and MUST NOT render the `role="button"` root.
- **href-and-onclick-both-fire**: When both `href` and `onClick` are provided, the component MUST pass `onClick` to the anchor so it runs on click ahead of the navigation, and the component MUST NOT cancel the navigation itself.
- **use-link-component**: When `href` is provided and `LinkComponent` prop is supplied, the component MUST use LinkComponent to render the anchor rather than a native `<a>` element, passing the destination as the `to` prop.
- **fallback-link-component**: When `href` is provided and `LinkComponent` is not supplied, the component MUST render a native `<a>` element (via the default `LinkComponent`, which wraps a plain `<a href>`).
- **keyboard-activation**: When `onClick` is provided without `href`, the component MUST respond to Enter and Space keys on `keydown` by invoking `onClick`, calling `preventDefault()` so Space does not scroll the page — the same scroll-prevention native `<button>` elements provide.
- **inert-root**: When neither `href` nor `onClick` is provided, the component MUST render a plain `div` with no role and no `tabIndex`, and without the interactive styling.
- **ignore-other-keys**: On the `role="button"` root, keys other than Enter and Space MUST NOT invoke `onClick`.
- **link-keeps-card-classes**: When rendered through `LinkComponent`, the component MUST pass its own classes to it as `className`, so the card's styling survives the host's adapter.
- **button-focusable**: When `onClick` is provided without `href`, the component MUST set `tabIndex={0}` on the button-role div so it participates in the default tab order.
- **optional-identifier**: Component MUST render the `identifier` prop as monospace text below the title when provided and truthy; it MUST NOT render if `identifier` is undefined, null, false or an empty string. A numeric `0` is falsy-guarded by `&&` and renders the text "0", so callers MUST NOT pass a number as `identifier`; convert it to a string first.
- **optional-description**: Component MUST render the `description` prop as paragraph text below the identifier (or title if no identifier) when provided and non-empty; it MUST NOT render if `description` is undefined, null, false or an empty string. A numeric `0` renders the text "0", so callers MUST NOT pass a number as `description`; convert it to a string first.
- **optional-meta**: Component MUST render the `meta` prop as a flex-wrapped row of chips below the description when provided and truthy; it MUST NOT render if `meta` is undefined, null, false or an empty string. A numeric `0` renders the text "0", so callers MUST NOT pass a number as `meta`; convert it to a string first.
- **meta-no-nested-interactive**: When the card is interactive (`href` or `onClick` is set), `meta` MUST NOT contain interactive elements (links, buttons). Nesting an interactive element inside an anchor or a `role="button"` container is invalid HTML and unreachable by assistive technology.
- **interactive-styling**: When `href` or `onClick` is provided, the component MUST apply cursor-pointer, a hover state (stronger border and different background color), and a focus-visible state (gold-tinted border).
- **classname-support**: Component MUST accept a `className` prop and apply it to the outermost element, merging it with the default classes.
- **classname-overrides-defaults**: A `className` utility that conflicts with a default one (for example `rounded-lg` against `rounded-xl`, or `p-4` against `p-5`) MUST replace the default rather than sit beside it.
- **left-aligned-text**: Component MUST align all text content to the start edge of the reading direction. (The web source currently hardcodes `text-left`, the physical left edge, so it does not meet this in right-to-left layouts — see the `rtl-layout-support` compliance status; the gap is recorded in Compliance only.)
- **focus-indicator-contrast**: When an interactive card receives keyboard focus, the component MUST show a visible focus indicator with at least 3:1 contrast (WCAG 2.4.7 and 1.4.11) against the adjacent surface. The web implementation removes the default outline and changes the border to `apt-gold` at 60% opacity; whether that meets 3:1 is unverified (see **focus-border-contrast** in Accessibility).
- **touch-target-size**: An interactive card MUST present a target of at least 44×44 CSS px (the Apple HIG floor of 44×44pt on native ports). The default `p-5` padding (20px per side) plus the full-width layout meets this for a title-only card; a caller who overrides the padding or width through `className` owns preserving the minimum.
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
- **Interactive outline**: the default browser outline is removed (`outline-none`) on interactive cards; the focus-visible border change is the only focus indicator
- **Text alignment**: `text-left`; width `w-full`

## States

| State | Appearance Change |
|-------|------------------|
| Default | Static card with **surface** background and **border** border. |
| Hover (interactive only) | Border strengthens to **border-strong**; background becomes **surface-hover**. |
| Focus (interactive only) | Border becomes **focus-accent** (focus-visible); the default outline is removed, so the border change is the only indicator. |

## Accessibility

- **Root element role**: When `href` is set, a native or LinkComponent-wrapped anchor element (implicit link role). When `onClick` is set without `href`, a div with `role="button"`. When neither is set, a div with no explicit role (content container).
- **Keyboard activation**: When role="button", Enter and Space keys MUST trigger the click handler. Anchor elements receive native browser keyboard support. See **keyboard-activation**.
- **Focus indicator**: Interactive cards remove the default outline and change the border to `apt-gold` at 60% opacity on focus-visible.
- **focus-border-contrast**: NEEDS REVIEW: Not implemented in source. The requirement **focus-indicator-contrast** asks for 3:1, but the only focus indicator is a border-color change to a 60%-opacity gold token; the source does not state its contrast against the card's surface or the page, so a token-pair measurement in each theme against the 3:1 non-text floor (WCAG 1.4.11) would settle it.
- **Text labels**: Title is rendered as plain text; no aria-label or aria-description attributes are used in the component, so content must be self-describing.
- **Identifier label**: Identifier is rendered in monospace and is visually secondary; implementers should ensure context makes its purpose clear (e.g., via a label above it or in documentation).
- **Touch/click target size**: See **touch-target-size**. The card's default padding (1.25rem on all sides) combined with its full-width layout produces a target well over 44×44 CSS px for a title-only card; see test vector resource-card-024.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| resource-card-001 | render-title | `title="My App"` | Title "My App" is rendered as plain text in font-medium. |
| resource-card-002 | accept-href (test: "renders a real anchor for href — the thing ⌘-click and \"copy link\" need") | `href="/principles/simplicity"` | Root is an `a` with `href="/principles/simplicity"`, exposed as a link, not a button, with no `tabindex` and `cursor-pointer` in its class |
| resource-card-003 | accept-onclick, button-focusable (test: "renders a keyboard-operable div[role=button] for onClick") | `onClick={handler}` without href | Root is a `div` with role "button" and `tabindex="0"` |
| resource-card-004 | href-precedence, href-and-onclick-both-fire (test: "fires onClick alongside navigation when the host passes both") | `href="/x"` and `onClick={handler}`; click the link | `handler` called once; root is a link |
| resource-card-005 | use-link-component, link-keeps-card-classes (test: "routes href through the injected LinkComponent, never a hardcoded router") | `href="/x"` and an adapter that renders `<a data-router="yes" href="#/x">` | Root has `data-router="yes"`, `href="#/x"` and the class `rounded-xl` |
| resource-card-006 | fallback-link-component | `href="/app"` without LinkComponent | A native `<a href="/app">` is rendered |
| resource-card-007 | keyboard-activation (test: same as resource-card-003) | role="button"; click, then keydown Enter, then keydown Space | `onClick` called 3 times |
| resource-card-008 | keyboard-activation | role="button"; keydown Space | The event's default action is prevented (no page scroll) |
| resource-card-009 | ignore-other-keys (test: same as resource-card-003) | role="button" after 3 calls; keydown "a" | `onClick` still called 3 times |
| resource-card-010 | inert-root (test: "renders an inert div when the host passes neither href nor onClick") | `title="Ecosystem"` only | Root is a `div`, no role, no `tabindex`, class has no `cursor-pointer` |
| resource-card-011 | optional-identifier | `identifier="com.example.app"` | Identifier is rendered in monospace, text-xs, below the title |
| resource-card-012 | optional-identifier | No identifier prop, or `identifier=""` | No identifier element is rendered |
| resource-card-013 | optional-description (test: "nests the block content inside the anchor — <a> takes flow content") | `href="/x"`, `description="No interleaving of concerns."` | A `p` inside the anchor holds that text |
| resource-card-014 | optional-description | No description prop, or `description=""` | No description element is rendered |
| resource-card-015 | optional-meta (test: same as resource-card-013) | `meta={<span>principles</span>}` with `href` | The anchor's text contains "principles"; the identifier text also appears inside the anchor |
| resource-card-016 | optional-meta | No meta prop | No meta row is rendered |
| resource-card-017 | interactive-styling | `href` or `onClick` provided | Class contains `cursor-pointer`, a hover border and background change, and a focus-visible border |
| resource-card-018 | classname-support, classname-overrides-defaults (test: "lets the host override geometry through className — twMerge, not append") | `href="/x"`, `className="rounded-lg p-4"` | Class contains `rounded-lg` and `p-4` and contains neither `rounded-xl` nor `p-5` |
| resource-card-019 | left-aligned-text | Any props | Text is aligned to the start edge of the reading direction; the web source currently applies the physical `text-left` class, which is the recorded `rtl-layout-support` gap |
| resource-card-020 | meta-no-nested-interactive | `href="/app"` and `meta={<a href="/x">link</a>}` | The caller has broken the requirement; the card does not prevent it, so a conforming caller passes no link or button inside `meta` |
| resource-card-021 | optional-identifier | `identifier={0}` | Failure mode: the numeral `0` is falsy-guarded by `&&`, so React renders the text "0" instead of nothing; callers MUST NOT pass a numeric identifier (see **optional-identifier**) |
| resource-card-022 | optional-description | `description={0}` | Failure mode: renders the text "0" instead of nothing; callers MUST NOT pass a numeric description |
| resource-card-023 | optional-meta | `meta={0}` | Failure mode: renders the text "0" in the meta row instead of nothing; callers MUST NOT pass a numeric meta |
| resource-card-024 | touch-target-size | `title="My App"` only, with `href="/x"`, rendered at default padding | The measured card height is at least 44 CSS px and its width fills the container |
| resource-card-025 | focus-indicator-contrast | Interactive card receives keyboard focus | Border changes to `apt-gold` at 60% opacity and the default outline is removed; the 3:1 contrast is unverified (see **focus-border-contrast**) |

The tests beside the source are `resourceCard.test.tsx`; vectors that name a test come from its assertions and the others derive from the source.

## Edge Cases

- **No props except title**: Card renders as inert div with title only. No errors occur.
- **Very long title**: Title text wraps to multiple lines within the card width. No truncation.
- **Very long identifier**: Identifier may wrap; recommend limiting identifier length in parent or using text-overflow/ellipsis in custom styling.
- **Description exceeds 3 lines**: Description is clamped to 3 lines via line-clamp-3; overflow text is hidden.
- **Meta content overflows horizontally**: Meta row uses flex-wrap to wrap items to the next line with gap-y-1 (0.25rem) between rows.
- **Both href and onClick with navigation**: onClick runs synchronously and is never awaited, so the anchor's navigation is not delayed by it — see **href-precedence**. `onClick` is typed `() => void`, so the card hands the host's handler no event and itself never calls `preventDefault` on the anchor click.
- **Empty href**: `href=""` is not `undefined`, so the card still renders through `LinkComponent` as a link with an empty destination.
- **Falsy numeric content**: `identifier`, `description` and `meta` are guarded with `&&`, so `0` renders the text "0"; `false`, `null`, `undefined` and `""` render nothing. See resource-card-021 to resource-card-023 and the caller rules in **optional-identifier**, **optional-description** and **optional-meta**.
- **Empty or null meta children**: If `meta` is present but contains no children, an empty flex row is rendered; no content or error. Callers should omit `meta` entirely rather than pass an empty node, to avoid the unwanted gap.
- **Interactive content in `meta` on an interactive card**: See **meta-no-nested-interactive**. Nesting a link or button inside an anchor or `role="button"` container is invalid HTML and unreachable by assistive technology; restrict `meta` to static chips (text, icons) when the card itself is interactive.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `ReactNode` | required | The card's name |
| `identifier` | `ReactNode` | none | Reverse-domain identifier, in monospace |
| `description` | `ReactNode` | none | Body text, clamped to 3 lines |
| `meta` | `ReactNode` | none | Row of mono-dim chips |
| `onClick` | `() => void` | none | Makes the card act; with `href` it also fires on the link |
| `href` | string | none | Makes the whole card a real link |
| `LinkComponent` | `DocLinkComponent` | `DefaultDocLink` (a plain anchor) | The host's router link, used only when `href` is set; receives the destination as `to` |
| `className` | string | none | Merged over the card's classes |

## Deep Linking

Not applicable: ResourceCard itself does not implement deep linking; it delegates navigation to the anchor or LinkComponent, which handle URLs. Parent consumers can wire routes and navigation based on the `href` prop passed to ResourceCard.

## Localization

Not applicable: ResourceCard renders content passed in via props (title, identifier, description, meta); it does not provide built-in localization. All text content is supplied by the parent and should be pre-localized. Note that the card's own layout is not locale-aware: **left-aligned-text** hardcodes `text-left` rather than the logical `text-start`, so the card does not mirror for right-to-left locales (see the `rtl-layout-support` compliance status below).

## Accessibility Options

Not applicable: ResourceCard does not directly respond to platform accessibility display options (Reduce Motion, Increase Contrast, etc.). The `transition-colors` class applies a CSS transition on hover/focus state changes; it does not include a `motion-reduce:` variant, so the transition still plays for viewers with `prefers-reduced-motion` enabled — the browser does not suppress it automatically. Consumers who need to respect that preference should add `motion-reduce:transition-none` (or equivalent) via the `className` prop. The focus-visible border change (focus-accent) is applied on interactive cards and is not affected by Increase Contrast or other options.

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

- **React/Web**: The source is `packages/web/packages/ui/src/blocks/resource-card.tsx`, with `DefaultDocLink` from `blocks/doc-link.tsx` ([adhsdk.ingredient.ui.blocks.doc-link](cookbook:0fe9833b-2a5c-47d5-a455-87e00d3797cf)), the `DocLinkComponent` type from `blocks/doc-types.ts` and `cn` from `lib/utils`; tests are `__tests__/resourceCard.test.tsx`. Uses semantic HTML (native `<a>` or LinkComponent-wrapped anchor for navigation, div[role="button"] for onClick interactivity). Styling is driven by Tailwind CSS utility classes and semantic color tokens (apt-* family). Customization via className prop. No additional wrappers or theming layer needed.

- **AppKit / UIKit**: macOS AppKit: use an `NSView` subclass with an `NSTrackingArea` for hover feedback and an `NSClickGestureRecognizer` (or `mouseDown`/`mouseUp`) for click handling; for navigation, swap the window's `contentViewController` or change the selection of an `NSSplitViewController` or `NSTabViewController` from the click handler (AppKit has no navigation-controller push). iOS UIKit: use a `UIControl` subclass (its built-in tap target, `isHighlighted`, and `sendActions(for: .touchUpInside)` cover the interaction) or a `UIButton` with a custom content view; for navigation, call `navigationController.pushViewController` from its action. Style the border and background with `layer.borderColor`/`layer.backgroundColor` — both are `CALayer`-backed views, not `NSAppearance`, which governs system chrome rather than a custom view's colors. Animate border/background changes on hover (macOS) or focus with `CABasicAnimation` or `UIView.animate`.

- **WinUI 3**: Windows has no `Card` control; use a `UserControl` (or a `Button` with a custom `ControlTemplate`) instead. Wrap the title/identifier/description/meta layout in a StackPanel or Grid and set it as the `Content` of the `UserControl` (or the `Button`'s `Content`, when the whole card should be a single focusable, clickable control). For navigation, use a HyperlinkButton or `Frame.Navigate()`; for onClick, use the Button's `Click` event. Apply `VisualStateManager` to define Normal, PointerOver, and Focused states (matching the source's default/hover/focus-visible states). Set `Foreground` and `Background` from theme resources (equivalent to the apt-* tokens). A real `Button` handles Enter/Space activation natively; a plain `UserControl` needs an explicit `KeyDown` handler for Enter/Space if it is not built on `Button`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/resource-card.tsx` | confirmed (2.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: `href` takes precedence over `onClick` — when both props are provided, the component renders as an anchor and executes `onClick` before navigation.
**Rationale**: This prioritizes semantic HTML and browser affordances (middle-click, ⌘-click, history, status bar URL preview) while allowing side effects (analytics, state mutation) to occur first.
**Approved**: pending

**Decision**: `div[role="button"]` is used for the `onClick` root instead of a native `<button>`.
**Rationale**: The card's flow content (paragraph `<p>` for description, div for meta) is not valid inside a native button element. A div allows arbitrary children and is semantically correct when paired with `role="button"` and keyboard handlers.
**Approved**: pending

**Decision**: The `LinkComponent` prop accepts a wrapper component (e.g. Next.js Link or React Router Link) instead of hard-coding a router dependency, and follows the `to` naming convention rather than `href`.
**Rationale**: This matches the shared `DocLinkComponent` injection pattern (`packages/web/packages/ui/src/blocks/doc-types.ts`), used by every block in this family that accepts a router component (e.g. `doc-nav` ([adhsdk.ingredient.ui.blocks.doc-nav](cookbook:ef7191ff-63a9-442a-b6d0-f8452a0aa1d6)), `doc-breadcrumbs` ([adhsdk.ingredient.ui.blocks.doc-breadcrumbs](cookbook:c9c48e65-6905-4035-b8e1-e053219599f1))), so a host writes one adapter for all of them.
**Approved**: pending

**Decision**: Hover, focus, and cursor-pointer styling are applied only when `href` or `onClick` is provided.
**Rationale**: This avoids misleading static cards into appearing interactive and prevents unnecessary state management.
**Approved**: pending

**Decision**: No built-in `aria-label` or `aria-description`.
**Rationale**: The component relies on its rendered content (title, identifier, description) to be self-describing. Implementers should ensure context makes the purpose of each field clear or add aria-attributes at the parent level if more explicit labeling is needed.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
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

Accessibility statuses rest on the source's native anchor/`role="button"` roots with keydown-based Enter/Space handling and `tabIndex={0}` (screen-reader-support, semantic-markup; keyboard-navigable is `partial` because Tab reachability and Enter/Space activation hold but the focus indicator's visibility is unverified, as for **focus-indicator-contrast**), its rem-based Tailwind text sizes (dynamic-type-support), and its padding/full-width layout (touch-target-size); `contrast-ratio` is `partial` because the source references `apt-*` theme tokens rather than literal color values, and `reduced-motion` is `failed` because `transition-colors` has no `motion-reduce:` variant. Internationalization statuses rest on the component taking all user-visible text as props with no hardcoded strings (string-externalization, no-hardcoded-strings, unicode-support), its hardcoded `text-left` alignment (rtl-layout-support, `failed`), and its unclamped title alongside its 3-line-clamped description (text-expansion-tolerance, `partial`). The three-root branching (`href`/`onClick`/inert) is pure view logic over props with the router itself injected via `LinkComponent` (separation-of-concerns passed); `resourceCard.test.tsx` directly exercises all three roots, the injected `LinkComponent`, the combined href+onClick case, and the `className` override (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | (cookbook update) | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and updated every citation; replaced the "Not applicable" Compliance section with a real table; reformatted Design Decisions to the three-line form; corrected fictitious APIs in the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes; corrected the reduced-motion and touch-target-size accessibility claims; fixed the onClick/navigation edge case's contradiction with href-precedence; added the button-focusable and meta-no-nested-interactive requirements with test vectors; added semantic token roles to Appearance and States |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 2.0.0 | 2026-11-14 | Mike Fullerton | Verified against source: corrected behavior, states and platform notes |
