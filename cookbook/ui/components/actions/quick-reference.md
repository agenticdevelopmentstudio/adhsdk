---
id: 40a6b717-cbdb-4d49-9f98-b318668b396c
title: "Syntax Quick Reference"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Toolbar control that opens a dismissible popover displaying a syntax cheatsheet for language features."
platforms:
  - typescript
  - web
tags:
  - toolbar
  - popover
  - cheatsheet
  - reference
depends-on:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
related: []
references: []
approved-by: ""
approved-date: ""
---

# Syntax Quick Reference

## Overview

A toolbar control that opens a dismissible popover listing a language syntax cheatsheet. The component provides a reusable shell for displaying reference material as labeled code examples. It is language-agnostic: the entries (label and syntax pairs) are provided by the consumer. Built on the shared Popover primitive, it inherits outside-click and Escape dismissal, plus automatic focus restoration to the trigger button on close.

## Behavioral Requirements

- **trigger-button-style**: The trigger MUST render as a subdued (non-primary) button at a small size, so it reads as a toolbar utility rather than a call to action. (Web: `variant="outline" size="sm"` — see React/Web platform note.)
- **trigger-book-icon**: The trigger MUST display a book icon positioned at the inline start of any visible label. (Web: lucide-react `BookText` — see React/Web platform note.)
- **trigger-accessible-name**: The trigger MUST have an `aria-label` set to the `ariaLabel` prop, and `ariaLabel` MUST be a non-empty string describing the cheatsheet's purpose (e.g., "Markdown quick reference"). When `triggerLabel` is also provided, `ariaLabel` MUST contain the visible `triggerLabel` text (WCAG 2.5.3 Label in Name), since the component does not derive one from the other — see #edge-cases and quick-ref-002.
- **trigger-disclosure-state**: The trigger MUST expose `aria-expanded` reflecting whether the popover is open, and MUST expose `aria-haspopup` identifying it as a popup trigger (both inherited from the Popover primitive's Base UI `Trigger`; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))). On web, `aria-expanded="true"` additionally switches the trigger's own background/foreground color (the outline variant's `aria-expanded:` styling).
- **popover-opens-on-click**: The component MUST open the popover when the trigger button is clicked, or activated via keyboard (the trigger is a native `button`, so Enter/Space also activate it).
- **popover-title-display**: The popover MUST display the provided title using field-caption typography styling. (Web: `fieldCaptionClass` — see React/Web platform note.)
- **entries-definition-list**: The component MUST render syntax entries as a definition list (`dl`) in a two-column layout with label (`dt`) and code (`dd`) pairs, the label column narrower than the code column.
- **entry-label-style**: Entry labels (`dt`) MUST render at a small font size and in a muted foreground color, distinguishing them from the code values below them.
- **entry-code-style**: Code values (`dd`) MUST render in a monospace font, smaller than the label text, with whitespace preserved (line breaks and indentation in the source syntax are not collapsed) and normal (non-loose) line spacing.
- **escape-dismissal**: The popover MUST close when the Escape key is pressed (inherited from Popover primitive; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))).
- **outside-click-dismissal**: The popover MUST close when the user clicks outside the popover bounds (inherited from Popover primitive).
- **focus-restoration**: The component MUST restore focus to the trigger button after the popover is dismissed (inherited from Popover primitive).
- **optional-trigger-label**: The component MUST accept an optional `triggerLabel` prop to display visible text on the trigger button.
- **customizable-width**: The component MAY accept a `contentClassName` prop to customize the popover's rendered width; the default renders at 20rem (see React/Web platform note for the literal class).
- **customizable-columns**: The component MAY accept a `columnsClassName` prop to customize the entries grid's column split; the default makes the label column narrower than the code column (see React/Web platform note for the literal class).
- **customizable-position**: The component MAY accept `side` and `align` props to position the popover relative to the trigger — `side` picks which edge of the trigger it opens from (default `bottom`), and `align` positions it along that edge (default `end`).
- **customizable-trigger-classes**: The component MAY accept a `className` prop to apply additional CSS classes to the trigger button.

## Appearance

- **Trigger button**: Outline variant, small size, with BookText icon positioned at inline-start and optional text label.
- **Title**: Uses field-caption typography class with vertical spacing (space-y-3 in grid container).
- **Entry label (dt)**: Small font size, muted foreground color (text-apt-text-muted).
- **Code block (dd)**: 
  - Font: monospace (font-mono)
  - Size: extra-small (text-xs)
  - Whitespace: pre-wrap (preserves formatting)
  - Line height: snug (leading-snug)
  - Foreground: default text color (text-apt-text)
  - Width constraint: min-w-0 to prevent overflow in grid
- **Grid layout**: Two-column definition list with horizontal gap of 3 units (gap-x-3) and vertical gap of 2 units (gap-y-2).
- **Popover container**: Default width of 20rem (w-80), vertical spacing of 3 units (space-y-3).

## States

| State | Appearance change |
|-------|------------------|
| Default (closed) | Trigger button displays in outline style. Popover is hidden. |
| Open | Popover is visible above, below, or beside the trigger (per `side` and `align` props). The trigger reflects `aria-expanded="true"` and switches to the muted background/foreground treatment (outline variant's `aria-expanded:` styling). |
| Hover | Trigger background lightens (`hover:bg-input/50`) and text moves to full foreground color (outline variant hover styling). |
| Pressed | The trigger does not get the usual dip/brighten pressed treatment — buttons carrying `aria-haspopup` are excluded from it (`not-aria-[haspopup]` in the shared button styles), though `data-pressed` is still set while held. |
| Focused | Trigger button receives keyboard focus and shows a focus ring (`focus-visible:ring-3`), inherited from the button element. |

## Accessibility

- **Button role**: The trigger is a native `button` element with semantic button role.
- **Accessible name**: See #requirements (trigger-accessible-name). The trigger's `aria-label` MUST be non-empty and, when `triggerLabel` is present, MUST contain its text (WCAG 2.5.3 Label in Name).
- **Disclosure state**: See #requirements (trigger-disclosure-state). `aria-expanded` and `aria-haspopup` are set on the trigger by the Popover primitive, not by this component's own code.
- **Popover accessible name**: The popover panel itself sets no `aria-labelledby` linking it to the title text (the `<p>` element). Popover's own spec only recommends, but does not require, this association (`label-association`; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))), and this component does not add it. Screen readers get the panel's content without an explicit accessible name tied to the title.
- **Definition list structure**: Entries are marked up as `dl`, `dt`, and `dd` elements, providing semantic structure for assistive technology.
- **Focus management**: The popover is non-modal and does not contain focus while open; restoring focus to the trigger on dismiss is handled by the Popover primitive (see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))), not reimplemented here.
- **Keyboard interaction**: Escape dismisses the popover (inherited from Popover; see accessibility ([adhsdk.ingredient.popover](cookbook:c61a220c-b63e-4dcd-a12b-715de20f7b5d))). Tab and Shift+Tab navigate within the popover while it is open.
- **Minimum touch target**: On web, the trigger MUST meet at least 24×24 CSS px (WCAG 2.5.8 Target Size Minimum) — the `sm` button size renders at 28px tall (`h-7`), which satisfies this. Native ports (iOS/Android) MUST meet the platform minimum (44×44pt / 48×48dp respectively).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| quick-ref-001 | trigger-button-style, trigger-book-icon | Component rendered | Trigger button is visible, subdued/outline style, small size, with book icon at inline start |
| quick-ref-002 | trigger-accessible-name | ariaLabel="Markdown quick reference" | Trigger has aria-label="Markdown quick reference" |
| quick-ref-003 | popover-opens-on-click | User clicks trigger button | Popover becomes visible |
| quick-ref-004 | popover-title-display | title="Markdown Syntax" | Popover displays "Markdown Syntax" in field-caption style |
| quick-ref-005 | entries-definition-list | entries=[{label: "Bold", syntax: "**text**"}, {label: "Italic", syntax: "*text*"}] | Popover displays two rows in grid: "Bold" / "**text**" and "Italic" / "*text*" |
| quick-ref-006 | entry-label-style | Entry with label "Bold" | Label rendered at a small font size, in muted color (the code text is smaller still — see quick-ref-007) |
| quick-ref-007 | entry-code-style | Syntax with newlines: "line1\nline2" | Code block preserves newlines, uses monospace font, smaller than label text, normal line spacing |
| quick-ref-008 | escape-dismissal | Popover is open; user presses Escape | Popover closes |
| quick-ref-009 | outside-click-dismissal | Popover is open; user clicks outside popover | Popover closes |
| quick-ref-010 | focus-restoration | Popover is open; user dismisses it by pressing Escape while focus is inside the popover panel | Focus moves back to the trigger button (not to `document.body` or elsewhere) |
| quick-ref-011 | optional-trigger-label | triggerLabel="Syntax" | Trigger button displays "Syntax" text alongside icon |
| quick-ref-012 | customizable-width | contentClassName="w-96" | Popover renders with width class w-96 (24rem) instead of default w-80 |
| quick-ref-013 | customizable-columns | columnsClassName="grid-cols-[10rem_1fr]" | Entry grid uses 10rem / 1fr column split instead of default 7rem / 1fr |
| quick-ref-014 | customizable-position | side="top", align="start" | Popover opens above trigger (top) and aligns to the start of that edge |
| quick-ref-015 | customizable-trigger-classes | className="custom-trigger-class" | Trigger button receives custom-trigger-class in addition to its style and size classes |
| quick-ref-016 | popover-opens-on-click | Trigger button is focused; user presses Enter or Space | Popover becomes visible (native `button` keyboard activation) |
| quick-ref-017 | trigger-disclosure-state | Popover transitions from closed to open | Trigger's `aria-expanded` changes from "false" to "true"; trigger carries `aria-haspopup` in both states |
| quick-ref-018 | entries-definition-list | entries=[] | Popover renders the title and an empty `dl` with no `dt`/`dd` rows |

## Edge Cases

- **Empty entries array**: If no entries are provided, the popover still renders the title and a definition list with no rows (see quick-ref-018). Result: a popover with only the title text is shown.
- **No triggerLabel**: If `triggerLabel` is undefined or null, the trigger button displays only the BookText icon without text. Result: icon-only button.
- **Very long syntax text**: The `dd` element has `min-w-0` to allow its content to shrink below its grid column's default size, preventing overflow. If syntax text is exceptionally long, the `whitespace-pre-wrap` class breaks lines within the code block. Result: text wraps instead of overflowing.
- **Narrow customized width**: If `contentClassName` is set to a very narrow width, the popover may be too small to display entries clearly. Responsibility rests with the consumer to provide appropriate width. Result: entries may be cramped or wrap unexpectedly.
- **Custom className conflicts**: If `className` prop contains classes that conflict with outline/size styling, the merged classes follow Tailwind's conflict resolution (later classes override). Result: unexpected styling if conflicting classes are intentional.
- **Empty aria-label**: If `ariaLabel` is an empty string or omitted, the trigger button has no accessible name. The component performs no runtime validation: it does not fail fast with a dev-time assertion, and it does not fall back to `title`. Result: screen readers cannot announce the button's purpose. Consumers MUST supply a non-empty, descriptive `ariaLabel` (see trigger-accessible-name).
- **Label-in-name mismatch**: `ariaLabel` and `triggerLabel` are independent props — the component does not derive one from the other or reconcile them. If `triggerLabel` shows visible text (e.g., "Syntax") and `ariaLabel` is unrelated text (e.g., "Reference panel"), the accessible name will not contain the visible label, which can fail WCAG 2.5.3 Label in Name. Result: consumers MUST choose an `ariaLabel` that contains the visible `triggerLabel` text (see trigger-accessible-name).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | string | required | The popover's heading text, e.g., "Markdown quick reference" |
| `entries` | ReadonlyArray<{label: string; syntax: string}> | required | Array of syntax entries to display as label-code pairs |
| `ariaLabel` | string | required | The accessible name for the trigger button, typically matching the title |
| `triggerLabel` | React.ReactNode | undefined | Optional visible text to display on the trigger button alongside the icon |
| `side` | "top" \| "right" \| "bottom" \| "left" | "bottom" | Which edge of the trigger the popover opens from |
| `align` | "start" \| "center" \| "end" | "end" | Alignment of the popover along the edge named by `side` (perpendicular to `side` — e.g., vertical when `side` is `left` or `right`) |
| `className` | string | undefined | Additional CSS classes to apply to the trigger button |
| `contentClassName` | string | "w-80" | CSS class(es) for the popover width; override for wider content |
| `columnsClassName` | string | "grid-cols-[7rem_1fr]" | CSS class(es) for grid column layout; adjust label column width if needed |

## Deep Linking

Not applicable: this component is a toolbar control for displaying reference material within a page, not a navigable destination or route target.

## Localization

String content (title, triggerLabel, ariaLabel, entry labels, syntax) is provided entirely by the consumer; the component renders no hard-coded UI strings. The component sets no explicit `dir` attribute on the `dd`/`code` elements that hold syntax examples: under an RTL-locale ancestor, syntax such as `**text**` inherits `rtl` directionality and can reorder unexpectedly, since the source applies no bidi isolation to code content (see [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d)).

## Accessibility Options

Not applicable: the component inherits focus management and popover behavior from the shared Popover primitive. It does not respond to system accessibility display options such as Reduce Motion, Increase Contrast, or Differentiate Without Color. Applications using this component SHOULD implement motion and contrast handling at the Popover level if needed.

## Feature Flags

Not applicable: no feature flags are present in the source code. The component is always enabled.

## Analytics

Not applicable: no analytics instrumentation is present in the source code. Applications using this component MAY instrument interactions (e.g., trigger click, dismiss) themselves if desired.

## Privacy

Not applicable: the component does not collect, store, or transmit user data. It renders static reference material provided by the consumer.

## Logging

Not applicable: no logging is implemented in the source code.

## Platform Notes

- **React/Web**: Source files are in `packages/web/packages/ui/src/components/quick-reference.tsx`. Uses React hooks, the shared Popover primitive (PopoverTrigger, PopoverContent), button variants from the component library, and Tailwind CSS for styling. Trigger: `buttonVariants({ variant: "outline", size: "sm" })`; the book icon is lucide-react's `BookText`. Title: `fieldCaptionClass`. Code: `font-mono text-xs leading-snug whitespace-pre-wrap`. Defaults: `contentClassName="w-80"` (20rem), `columnsClassName="grid-cols-[7rem_1fr]"`.
- **SwiftUI**: Use the `.popover(isPresented:)` modifier on the trigger `Button`, whose label is the SF Symbol `book.closed` (or `book.closed.fill`) plus optional text. The popover content is a `VStack` with a `Text` title and a `Grid` of `GridRow`s — one row per entry, label in the first column and code in the second using `.monospaced()`. Restore focus to the trigger on dismiss via the `.popover`'s `onDismiss` closure and `@FocusState`.
- **Compose**: Use a Button composable as the trigger with an Icon from Material Icons. Wrap the popover content in a Popup or Dialog composable. Entries can be rendered as a LazyColumn with rows displaying label and code. Use Material's color tokens and typography.
- **AppKit / UIKit**: 
  - **macOS (AppKit)**: Create an NSButton with an icon image and optional label. Use NSPopover for the content, positioning it with NSRectEdge. Display entries in an NSTableView with two columns (label and code) or a custom stack view. Restore responder chain focus on close.
  - **iOS (UIKit)**: Create a UIButton styled as a system button. Use UIPopoverPresentationController to present the reference content. Display entries in a UITableView or a UIScrollView with UIStackViews for rows. Manage focus and accessibility via UIAccessibility.
- **WinUI 3**: Use a `Button` styled to look subdued (a subtle/transparent style, not an accent style) containing a `FontIcon` glyph from Segoe Fluent Icons — a book glyph such as `Library` — plus optional `Content` text. Use a `Flyout` (not `MenuFlyout`, which is for menu commands) to host the reference content. Define a `DataTemplate` for entries with a `TextBlock` for the label and a `TextBlock` set to a monospace font (e.g. Cascadia Mono) for the code — not `RichEditBox`, which is editable. Rely on the `Flyout`'s built-in light-dismiss behavior for focus return and keyboard (Escape) dismissal.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/quick-reference.tsx` | unverified |

## Design Decisions

**Decision**: Build the component on the shared Popover primitive rather than reimplementing outside-click dismissal, Escape handling, and focus restoration.
**Rationale**: This ensures consistent behavior across the application and reduces code duplication — all popovers behave identically.
**Approved**: pending

**Decision**: Mark up entries as a definition list (`dl`, `dt`, `dd`) rather than a table or unordered list; the grid layout is applied via CSS (Tailwind), decoupling presentation from semantics.
**Rationale**: This gives each label-syntax pair explicit semantic meaning (term and definition) for assistive technology.
**Approved**: pending

**Decision**: Default the popover width to 20rem (`w-80`) and the column split to 7rem (labels) / 1fr (code), customizable via `contentClassName` and `columnsClassName`.
**Rationale**: These defaults fit common use cases (Markdown, code snippets); a language needing more or less space can override them per call site.
**Approved**: pending

**Decision**: Position the BookText icon at the inline-start of the trigger using the `data-icon="inline-start"` data attribute rather than hardcoding absolute positioning.
**Rationale**: This lets the icon participate in the button's icon-handling logic and flips correctly for RTL (left in LTR, right in RTL) without extra styling.
**Approved**: pending

**Decision**: Make `triggerLabel` optional so the trigger can be icon-only in space-constrained toolbars.
**Rationale**: When present, the label appears alongside the icon; when absent, the icon-only trigger still has an accessible name via `ariaLabel`.
**Approved**: pending

**Decision**: Render code values with `whitespace-pre-wrap` to preserve formatting (indentation, line breaks) in syntax examples.
**Rationale**: This is essential for code reference material, where exact formatting is part of what is being taught.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on: `dl`/`dt`/`dd` markup and the native `button` role with `aria-label` (semantic-markup, keyboard-navigable); Popover's own focus-trap and focus-restore, inherited rather than reimplemented (focus-management); the `sm` button's 28px height meeting WCAG 2.5.8 (touch-target-size); rem-based Tailwind text sizing whose actual scaling behavior isn't verified in source (dynamic-type-support: partial); the absence of runtime `aria-label` validation and of `aria-labelledby` on the popover panel (screen-reader-support: partial); `apt-*` design tokens whose resolved contrast can't be checked from source alone (contrast-ratio: partial); consumer-supplied-only text with no hardcoded strings in the component (string-externalization, no-hardcoded-strings); plain JS string rendering, which is Unicode-transparent (unicode-support); and the missing `dir`/bidi isolation on code cells (rtl-layout-support: failed). `SyntaxQuickReference` is the shell only — entries belong to whoever owns the language, with no business logic in the component (separation-of-concerns passed); it has no test file of its own and is exercised only through its consumer `MarkdownQuickReference` in `markdownQuickReference.test.tsx` (unit-test-coverage partial).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; moved web-specific requirement details to Platform Notes; added Popover to depends-on; reformatted Design Decisions to Decision/Rationale/Approved; replaced Compliance with canonical linked checks; fixed the touch-target contradiction and the focus-containment overclaim; corrected align-axis wording; added non-empty-aria-label and WCAG 2.5.3 label-in-name requirements and edge cases; corrected WinUI 3 and SwiftUI platform notes; added missing test vectors; corrected the Localization bidi note |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed entry-label-style/quick-ref-006 to stop contradicting entry-code-style/quick-ref-007 (code is smaller, not the label); renamed stale should-associate-label ref to popover's label-association. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
