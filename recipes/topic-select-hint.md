---
id: 86b4d53c-8122-480c-9a33-43e08b063469
title: TopicSelectHint
domain: adhsdk://recipes/topic-select-hint
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A centered card prompt for selecting an item from a list when no selection
  is active.
platforms:
- typescript
- web
tags:
- selection
- placeholder
- empty-state
depends-on: []
related:
- adhsdk://recipes/empty-state
- adhsdk://recipes/card
references: []
approved-by: ''
approved-date: ''
---

# TopicSelectHint

## Overview

TopicSelectHint is a centered card component displayed when no selection is active in a list-based UI. It provides context-specific guidance to the user about what to select, using dynamic headline generation based on available metadata (item noun, list title). The component renders a mouse-pointer icon, an optional headline, and optional descriptive content, composited into a Card primitive.

## Behavioral Requirements

- **render-card**: Component MUST render a Card element containing an icon, optional headline, and optional descriptive content.
- **render-icon**: Component MUST render a mouse-pointer icon (MousePointerClick from lucide-react) inside a circular container.
- **use-test-hook**: Component MUST set `data-htd-select-hint` attribute on the root container for test targeting. The `htd` prefix is the shared test-hook namespace for the whole HierarchicalTopicDetail component family (`topic-detail`, `hierarchical-topic-detail`, `hierarchical-menu-detail`); TopicSelectHint is that family's shared "nothing selected" placeholder, so it carries the same prefix rather than a bespoke one.
- **accept-custom-title**: Component MUST render the `title` prop as the headline verbatim when provided, taking precedence over computed headlines and over `selectable` — an explicit `title` still renders even when `selectable` is false.
- **compute-headline-from-noun**: Component MUST generate the headline as "Select [article] [noun]" when `noun` is provided (truthy) and `title` is not, where `article` is `"an"` when `noun`'s first character matches `/^[aeiou]/i` (case-insensitive) and `"a"` otherwise. This is a naive first-letter rule, not true English pronunciation, so it mis-genders words like "hour" and "user" — see Edge Cases.
- **compute-headline-from-list-title**: Component MUST generate the headline as "Select an item from [listTitle]" when `listTitle` is provided (truthy), `noun` is not, and `title` is not.
- **use-fallback-headline**: Component MUST generate the headline as "Select an item from the list" when none of `title`, `noun`, or `listTitle` are provided (or `noun`/`listTitle` are falsy, e.g. an empty string), and `selectable` is true.
- **append-edit-suffix**: Component MUST append " to view or edit it here." to the computed headline when `selectable` is true and no `children` are provided. This applies to every computed headline (noun-derived, listTitle-derived, and the fully generic default) equally.
- **hide-headline-when-not-selectable**: Component MUST NOT render the computed headline when `selectable` is false and no `title` is provided; an explicit `title` still renders regardless of `selectable`.
- **render-children**: Component MUST render the `children` prop as descriptive content when provided.
- **hide-children-when-not-provided**: Component MUST not render a content section when `children` are not provided.
- **center-content**: Component MUST center the card horizontally and vertically within its container.

## Appearance

- **Container**: Flex column, full height and width, centered items, overflow-y auto, 24px padding (p-6)
- **Card**: Maximum width 448px (max-w-md), gap 12px (gap-3), padding 32px horizontal × 40px vertical (px-8 py-10), centered text alignment
- **Icon circle**: 44px (size-11), flexbox centered, rounded full, border 1px (border-apt-border), background apt-surface, text color apt-text-dim
- **Icon**: 20px (size-5) MousePointerClick from lucide-react
- **Headline**: Font weight semibold, line height snug, text color apt-text
- **Description text**: Font size 14px (text-sm), line height relaxed, text color apt-text-muted; strong elements are semibold with apt-text color

**Design tokens** — the `apt-*` classes are semantic tokens the host project's Tailwind config must define; each maps to a platform-neutral color role a Swift, Compose, or WinUI port can use its own equivalent for:
- `apt-border`: neutral border/divider color (icon circle outline)
- `apt-surface`: elevated surface background (icon circle fill)
- `apt-text`: primary foreground text (headline, description `<strong>` runs)
- `apt-text-dim`: secondary/dim foreground (the decorative icon)
- `apt-text-muted`: tertiary muted foreground (description body text)

## States

| State | Appearance change |
|-------|------------------|
| Default | Card displayed with content as specified |
| Empty list (selectable: false) | Computed headline hidden (an explicit `title` still renders), description (children) shown if provided |
| No description | Headline shown, no description section rendered |

## Accessibility

- **Role**: The component uses a semantic `div` container with no explicit ARIA role; it functions as a visual prompt and does not require assistive technology interaction.
- **Icon accessibility**: The icon container has `aria-hidden="true"` to hide it from screen readers, treating it as purely decorative.
- **Headline**: Renders as a plain `<div>`, not a semantic heading (`<h1>`–`<h6>`) or `<p>` element; screen readers do not expose it as a heading or landmark, so its only accessible presence is as inline text content.
- **Description**: Rendered as plain text content; strong elements within children are styled but not specially announced.
- **Keyboard navigation**: Component does not capture focus or require keyboard interaction; it is a passive display element.
- **Minimum tap target**: The component is not an interactive control and does not define a tap target; it contains no buttons or clickable elements.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| topic-select-hint-001 | render-card, render-icon, use-test-hook, use-fallback-headline | No props (defaults) | Renders Card with mouse-pointer icon, data-htd-select-hint attribute present, default headline "Select an item from the list to view or edit it here." |
| topic-select-hint-002 | accept-custom-title | `title="Custom headline"` | Headline renders as "Custom headline" exactly |
| topic-select-hint-003 | compute-headline-from-noun | `noun="workspace"` | Headline renders as "Select a workspace to view or edit it here." |
| topic-select-hint-004 | compute-headline-from-noun | `noun="item"` | Headline renders as "Select an item to view or edit it here." |
| topic-select-hint-005 | compute-headline-from-list-title, append-edit-suffix | `listTitle="Workspaces"` | Headline renders as "Select an item from Workspaces to view or edit it here." (the edit suffix applies to the listTitle-derived headline too) |
| topic-select-hint-006 | compute-headline-from-noun, compute-headline-from-list-title | `noun="workspace"` `listTitle="Workspaces"` | Headline renders as "Select a workspace to view or edit it here." (noun takes precedence) |
| topic-select-hint-007 | accept-custom-title | `title="Select a group"` `noun="workspace"` | Headline renders as "Select a group" (title takes precedence) |
| topic-select-hint-008 | render-children | `children="Choose one to begin editing."` | Description text is rendered below headline |
| topic-select-hint-009 | append-edit-suffix | `noun="site"` (no children) | Headline ends with " to view or edit it here." |
| topic-select-hint-010 | append-edit-suffix | `noun="site"` `children="Some description"` | Headline does NOT end with " to view or edit it here." |
| topic-select-hint-011 | hide-headline-when-not-selectable | `selectable={false}` | Headline is not rendered, only children (if provided) are shown |
| topic-select-hint-012 | hide-headline-when-not-selectable | `selectable={false}` (no children) | Card is rendered but both headline and description sections are hidden |
| topic-select-hint-013 | hide-children-when-not-provided | `children={undefined}` | No description section is rendered |
| topic-select-hint-014 | center-content | `noun="workspace"` | The outer container computes to `display: flex; flex-direction: column; align-items: center; justify-content: center;`, centering the Card both horizontally and vertically within it |
| topic-select-hint-015 | accept-custom-title, hide-headline-when-not-selectable | `title="Confirm delete"` `selectable={false}` | Headline still renders as "Confirm delete" — an explicit `title` takes precedence over `selectable` |
| topic-select-hint-016 | use-fallback-headline | `noun=""` | Headline renders as "Select an item from the list to view or edit it here." — an empty string is falsy in JS, so `noun` is treated as not provided |
| topic-select-hint-017 | use-fallback-headline | `listTitle=""` | Headline renders as "Select an item from the list to view or edit it here." — an empty string is falsy in JS, so `listTitle` is treated as not provided |
| topic-select-hint-018 | compute-headline-from-noun | `noun="hour"` | Headline renders as "Select a hour to view or edit it here." — the article rule tests only the first letter, not English pronunciation, so this is a known grammatical miss |

## Edge Cases

- **Empty string `noun`**: An empty string is falsy in JavaScript, so `noun` is treated the same as not provided; the headline falls through to `listTitle` (if given) or the fully generic default. See **use-fallback-headline**.
- **Empty string `listTitle`**: Likewise falsy; `listTitle=""` falls through to the fully generic default rather than producing a "Select an item from " string with a trailing space.
- **Naive article selection**: `article()` (`/^[aeiou]/i.test(noun)`) tests only the noun's first letter, not English pronunciation, so it mis-genders words like "hour" ("a hour" instead of "an hour") and "user" ("an user" instead of "a user"). This is a known, accepted limitation — see **compute-headline-from-noun**.
- **Custom title with selectable false**: `title` is checked with `??` (nullish coalescing), which only defers to the computed headline when `title` is `null`/`undefined`. An explicit `title` therefore still renders even when `selectable` is false; `selectable` only ever suppresses the *computed* headline. See **hide-headline-when-not-selectable**.
- **null/undefined children**: Component correctly skips rendering the children section entirely when not provided.
- **selectable false with empty children**: Component hides the computed headline but does not render a fallback; only the icon and optional children are shown.
- **Very long noun or listTitle**: Component does not define text truncation; long values will wrap or overflow based on Card max-width constraint.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | ReactNode | undefined | Custom headline text; overrides computed headline and `selectable` |
| `noun` | string | undefined | Singular noun for the selectable item (e.g. "workspace", "site") |
| `listTitle` | string | undefined | Display name of the list; used as fallback when noun not provided |
| `selectable` | boolean | true | Whether the list has items to select; false hides the computed headline (not an explicit `title`) and shows only children |
| `children` | ReactNode | undefined | Optional descriptive content (e.g. "What these items are and why to pick one") |

## Deep Linking

Not applicable: TopicSelectHint is a passive display component with no deep linking behavior or navigation support.

## Localization

TopicSelectHint does not provide localization infrastructure: the computed headline's English scaffolding is hardcoded in source and is not exposed as translatable resource strings. Only prop values (`noun`, `listTitle`, `children`) pass through unmodified from the caller — the surrounding English sentence structure does not.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `select-hint.prefix` | "Select" | Leads every computed headline |
| `select-hint.article` | "a" / "an" | Chosen by a naive first-letter rule, not true English grammar — see **compute-headline-from-noun** |
| `select-hint.list-fallback` | "an item from" | Used when `listTitle` is given and `noun` is not |
| `select-hint.generic-fallback` | "an item from the list" | Used when neither `noun` nor `listTitle` is given |
| `select-hint.edit-suffix` | " to view or edit it here." | Appended when no `children` are provided |

An application that needs a fully localized headline must override it entirely via the `title` prop with pre-translated text; there is no per-fragment translation hook.

## Accessibility Options

Not applicable: TopicSelectHint does not respond to system accessibility display options (Reduce Motion, Increase Contrast, Differentiate Without Color). The component renders static content with no animations or color-dependent information.

## Feature Flags

Not applicable: TopicSelectHint does not define or consume feature flags; it is always enabled.

## Analytics

Not applicable: TopicSelectHint does not emit analytics events. Applications using this component may track when it is displayed, but the component itself provides no instrumentation.

## Privacy

Not applicable: TopicSelectHint does not collect, store, or transmit any data. It renders static UI based on props provided by the application.

## Logging

Not applicable: TopicSelectHint does not emit log events or debug output.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/topic-select-hint.tsx`. Uses Tailwind CSS classes and lucide-react for the icon. Composed from the Card primitive. The component is a "use client" directive (Client Component in Next.js). Headline generation uses a custom `article()` helper function for naive English article selection (a/an, first-letter only).
- **SwiftUI**: Adapt from SwiftUI's VStack and HStack for centering. Use the SF Symbol `"cursorarrow.click"` instead of lucide-react's MousePointerClick. Compose with a local Card equivalent or SwiftUI's built-in container shapes.
- **Compose**: Use Compose's Column (vertically centered) and Row (icon circle). A Material 3 Card or ElevatedCard for the container. Use Compose Material icons (e.g., `Icons.Default.TouchApp` or custom pointer icon). Apply Compose Modifier chains for sizing, padding, and text styling.
- **AppKit / UIKit**: Use NSStackView (AppKit) or UIStackView (UIKit) for layout. NSImageView or UIImageView with an appropriately sized system or custom pointer icon. NSTextView or UILabel for headline and description. Position the Card in a centered view controller or container view. Apply Auto Layout constraints for centering.
- **WinUI 3**: Use Grid with HorizontalAlignment and VerticalAlignment set to Center. WinUI 3 has no built-in Card control, so use a `Border` with a corner radius for the card container. A `FontIcon` or `SymbolIcon` for the pointer icon (WinUI 3 has no built-in Image/IconElement equivalent for system glyphs). TextBlock controls for headline and description. Apply grid Row and Column properties for layout; use StackPanel or RelativePanel for nested alignment.

## Design Decisions

- **Decision**: Headline precedence is `title` > `noun` > `listTitle` > the fully generic default.
  **Rationale**: The hierarchy allows maximum flexibility — a custom title can override computed headlines entirely, while the noun provides specificity. This design prioritizes application control over component magic.
  **Approved**: pending

- **Decision**: The suffix " to view or edit it here." is appended to computed headlines only when no `children` are provided.
  **Rationale**: When descriptive copy is present, the suffix is omitted to avoid redundant messaging and keep the interface concise.
  **Approved**: pending

- **Decision**: The mouse-pointer icon is marked `aria-hidden` and conveys no essential information beyond visual guidance.
  **Rationale**: The icon is semantically decorative; marking it `aria-hidden` prevents assistive technology from announcing it redundantly with the headline text.
  **Approved**: pending

- **Decision**: When the list is empty (`selectable=false`), the computed headline is hidden; an explicit `title` still renders regardless of `selectable`.
  **Rationale**: There is nothing to select in an empty list, so the automatic call-to-action headline is suppressed, while the optional `children` prop still allows explanatory text (e.g., "No workspaces yet. Create one to get started.") without a false call to action.
  **Approved**: pending

- **Decision**: The Card is constrained to a maximum width of 448px (`max-w-md`).
  **Rationale**: This keeps the component readable and prevents it from sprawling on very wide screens; it is a responsive affordance, not a hard constraint.
  **Approved**: pending

- **Decision**: All appearance properties (colors, sizes, spacing) are expressed as Tailwind classes and `apt-*` semantic tokens.
  **Rationale**: This makes the component portable to any Tailwind-configured project; the design tokens (`apt-border`, `apt-surface`, `apt-text`, `apt-text-dim`, `apt-text-muted`) must be defined in the host project's Tailwind config.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on `topic-select-hint.tsx`: headline/description sizes use relative Tailwind units but are not verified against OS-level type scaling (dynamic-type-support); the `apt-*` tokens are referenced by name only with no resolved color values in source, so contrast cannot be confirmed (contrast-ratio); the headline renders as a plain `<div>` rather than a semantic heading or paragraph element (semantic-markup); and the computed headline's English words are literal string fragments in source, not externalized resources (no-hardcoded-strings); `TopicSelectHint` is presentation assembled over the `Card` primitive, with only simple string-building (`article`, the headline fallback) and no business logic or data access (separation-of-concerns passed), and no test file in the web workspace exercises this source (unit-test-coverage failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and dropped a duplicate; corrected the `title`/`selectable` precedence and the empty-string `noun`/`listTitle` fallthrough to match source; fixed the listTitle headline's missing edit-suffix in test 005; documented the `htd` test-hook prefix, the naive article rule, and hardcoded English strings as a Localization limitation; reformatted Design Decisions and Compliance to convention; added `related` links; added test vectors 015-018. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
