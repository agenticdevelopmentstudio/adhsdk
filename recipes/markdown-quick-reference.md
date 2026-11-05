---
id: f5d2eb1c-fb0e-48e3-b124-7e730ac8231c
title: Markdown Quick Reference
domain: adhsdk://recipes/markdown-quick-reference
type: ingredient
version: 1.3.1
status: review
language: en
created: '2026-06-26'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An outline-button toolbar control that opens a dismissible popover listing common markdown syntax (headings, bold/italic, code, lists, links, quote)."
platforms:
  - typescript
  - web
tags:
  - markdown
  - popover
  - help
  - reference
  - toolbar
depends-on:
  - adhsdk://recipes/button
related:
  - adhsdk://recipes/markdown-editor
references: []
approved-by: ''
approved-date: ''
---

# Markdown Quick Reference

## Overview

A standalone toolbar control in `@adh-sdk/ui`
(`components/markdown-quick-reference`). It is a thin wrapper that passes a
fixed `MARKDOWN_SYNTAX` list into the shared `SyntaxQuickReference` shell
(`components/quick-reference`) — the same shell the ink editor's quick
reference uses. `SyntaxQuickReference` renders the outline `Button` trigger
and the dismissible `Popover` listing the common GitHub-flavoured markdown
syntax — headings, bold/italic, inline + fenced code, bullet/numbered lists,
links, and blockquote.

Because `SyntaxQuickReference` is built on the shared `Popover` primitive, the
control inherits outside-click and Escape dismissal plus focus restore to the
trigger. It is wired into the `MarkdownEditor` toolbar by default, but is
exported on its own so any editor toolbar can drop it in. It holds no state of
its own and takes no value.

## Behavioral Requirements

- **render-labelled-trigger**: The control MUST render a single `Button`
  trigger whose accessible name is `Markdown quick reference`, regardless of the
  visible trigger text.
- **start-closed**: The control MUST NOT render the reference content until
  the trigger is activated (the popover starts closed).
- **open-on-trigger**: The control MUST open the popover and reveal the
  reference content when the trigger is activated (click or keyboard).
- **list-common-syntax**: The open popover MUST list, at minimum, headings,
  bold, italic, inline code, fenced code block, bullet list, numbered list,
  link, and blockquote — each as a label paired with its literal markdown
  snippet.
- **dismiss-on-escape**: The control MUST close the popover when Escape is
  pressed while it is open.
- **dismiss-on-outside-click**: The control MUST close the popover when a
  pointer interaction occurs outside it.
- **restore-focus**: The control MUST return focus to the trigger when the
  popover closes.
- **honor-custom-trigger-label**: The control MUST render `triggerLabel` as
  the visible trigger text while keeping the fixed `Markdown quick reference`
  accessible name.

## Appearance

```
┌ trigger ─────────┐
│ [▮] Markdown     │  ← outline Button (size sm), BookText icon + label
└──────────────────┘
        ▼ on open (popover, side=bottom align=end, w-80)
  ┌──────────────────────────────────────┐
  │ MARKDOWN QUICK REFERENCE              │  ← mono uppercase caption
  │ Headings     # H1 / ## H2 / ### H3    │  ← <dl>: term | <code> snippet
  │ Bold         **bold text**            │
  │ Italic       _italic text_            │
  │ Inline code  `inline code`            │
  │ Code block   ```ts … ```              │
  │ Bullet list  - one / - two            │
  │ Numbered list 1. one / 2. two         │
  │ Link         [label](https://url)     │
  │ Blockquote   > quoted text            │
  └──────────────────────────────────────┘
```

- Trigger: shared `Button` via `buttonVariants({ variant: "outline", size: "sm" })`
  with a leading `BookText` icon (`data-icon="inline-start"`).
- Popover surface: the shared `PopoverContent` (`bg-apt-surface`,
  `border-apt-border`, `text-apt-text`), widened to `w-80`.
- Caption: the shared `fieldCaptionClass` (from `lib/typography`), not a
  hard-coded style — this is what keeps the caption typography from forking
  between `SyntaxQuickReference` consumers.
- Rows: a two-column `<dl>` with the column widths set by `columnsClassName`
  (default `grid-cols-[7rem_1fr]`) — `<dt>` label in `text-apt-text-muted`,
  `<dd>` a `whitespace-pre-wrap` mono `<code>` in `text-apt-text`.
- Tokens only: no raw hex, no arbitrary colors, no `!important`.

## States

| State | Appearance change |
|---|---|
| Closed (default) | Only the outline trigger button is shown; no popover content in the DOM |
| Trigger hover/focus | Standard outline-Button hover + gold focus ring (`focus-visible`) |
| Open | `aria-expanded="true"` on the trigger; the portalled popover lists the syntax |
| Dismissed (Escape / outside-click) | Popover unmounts; focus returns to the trigger |

## Accessibility

- The trigger is a real `<button>` with `aria-label="Markdown quick reference"`,
  so the accessible name is stable even when the visible label changes.
- Open/closed state is conveyed via the Popover's `aria-expanded` /
  `aria-controls` wiring on the trigger (from the shared primitive).
- Escape closes the popover; focus is restored to the trigger (handled by the
  shared `Popover`).
- The reference content is a semantic `<dl>` (term/description pairs), so the
  label↔snippet relationship is exposed to assistive tech.
- Content is reference-only (no focusable controls), so there is no focus trap to
  manage beyond the primitive's defaults.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-labelled-trigger, start-closed | Render the control | One button named `Markdown quick reference`; no `Markdown quick reference` caption text in the DOM |
| T2 | open-on-trigger, list-common-syntax | Click the trigger | The popover shows the caption plus all nine labels: `Headings`, `Bold`, `Italic`, `Inline code`, `Code block`, `Bullet list`, `Numbered list`, `Link`, `Blockquote` |
| T3 | dismiss-on-escape, restore-focus | Open, then press Escape | The popover content is removed; focus returns to the trigger |
| T4 | honor-custom-trigger-label | Render with `triggerLabel="Syntax"` | The trigger shows `Syntax` but is still named `Markdown quick reference` |
| T5 | dismiss-on-outside-click, restore-focus | Open, then click a point outside the popover | The popover content is removed; focus returns to the trigger |

## Edge Cases

- The syntax list is a fixed, hard-coded reference (no props feed it), so the
  content never varies between consumers — one authoritative cheatsheet.
- Fenced-code and list snippets contain newlines; the `<code>` uses
  `whitespace-pre-wrap` so multi-line snippets render literally.
- `side` / `align` are forwarded to the popover positioner; near a viewport edge
  the shared primitive flips/clamps the popover to stay on screen.
- Re-opening after dismissal re-mounts fresh content (the control is stateless).

## Configuration

`@adh-sdk/ui/components/markdown-quick-reference`

| Option | Type | Default | Description |
|---|---|---|---|
| `side` | `PopoverContentProps["side"]` | `"bottom"` | Popover placement side |
| `align` | `PopoverContentProps["align"]` | `"end"` | Popover alignment along the side |
| `triggerLabel` | `ReactNode` | `"Markdown"` | Visible text on the trigger button |
| `className` | `string` | — | Extra classes on the trigger button |

```ts
type PopoverContentProps = React.ComponentProps<typeof PopoverContent>

export function MarkdownQuickReference(props: {
  side?: PopoverContentProps["side"]
  align?: PopoverContentProps["align"]
  triggerLabel?: React.ReactNode
  className?: string
}): React.ReactElement
```

## Deep Linking

Not applicable: this is a reusable UI primitive exported for toolbar integration and does not participate in app routing or deep linking.

## Localization

Known gap, not "not applicable": the component hard-codes every user-facing
string — the `"Markdown quick reference"` title/aria-label, the `"Markdown"`
default trigger text, and all nine `MARKDOWN_SYNTAX` row labels — with no
locale-sensitive formatting per source. The underlying `SyntaxQuickReference`
shell already accepts `title` and `ariaLabel` as props, but
`MarkdownQuickReference` does not forward them as its own props, so a
consumer has no way to localize this ingredient without editing it.

## Accessibility Options

This is a lightweight reference popover that inherits focus management and
keyboard dismissal from the shared `Popover` primitive. See
**dismiss-on-escape** and **restore-focus** in Behavioral
Requirements.

## Feature Flags

Not applicable: this ingredient is a reusable UI component and is not gated by feature flags.

## Analytics

Not applicable: this ingredient is presentational. Consumers may instrument trigger activation and popover interactions in their own event tracking systems.

## Privacy

Not applicable: this component collects no data, performs no network requests, and stores no persistent state.

## Logging

This ingredient is presentational and emits no structured log events. Opening or
dismissing the reference is local UI state and is not reported to the consumer.

## Platform Notes

- **React / Web (TypeScript)**: Component at `packages/web/packages/ui/src/components/markdown-quick-reference.tsx`. It composes (does not re-export) the shared `SyntaxQuickReference` shell (`components/quick-reference.tsx`), passing it the authoritative `MARKDOWN_SYNTAX` array; `SyntaxQuickReference` itself is built on the `Popover` + `Button` primitives. Demo lives in `ui-showcase` (Overlays group); re-run `gen-sources.py` after edits.
- **SwiftUI**: Start with a `Popover` anchored to a `Button` trigger. The reference list renders as a scrollable container of label–snippet pairs, each pair using a two-column layout (label on the left in secondary foreground color, snippet on the right in monospace font `Font.system(.body, design: .monospaced)`). Dismissal via the popover's auto-dismiss on outside tap and keyboard handling with `.onKeyPress(.escape)`.
- **Compose**: Start with a `Popup` (or `DropdownMenu` for a simpler alternative) anchored to an `IconButton` trigger, using its `onDismissRequest` for outside-tap/Escape dismissal and an `Alignment`/offset for anchoring — Material 3 has no `Popover` component. Render the syntax list as a `LazyColumn` of rows, each holding a label and a monospace code snippet using `fontFamily = FontFamily.Monospace`.
- **AppKit / UIKit**: macOS uses an `NSPopover` anchored to the trigger button in the toolbar; iOS uses a `UIPopoverPresentationController`-presented view controller (a popover-style sheet, not a `UIMenu` — the content is a reference to read, not a set of selectable commands). On both platforms, render the list as a scrollable container with term–snippet pairs displayed in rows. Use monospace fonts via `NSFont.monospacedSystemFont(ofSize:weight:)` on macOS and `UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)` on iOS, so both platforms get the same Dynamic Type–friendly system monospace behavior. Dismissal on outside tap, on both platforms.
- **WinUI 3**: Start with a `Flyout` anchored to the trigger `Button` and opened via `Flyout.ShowAt(sender)`. Render the syntax reference as an `ItemsRepeater` or `Grid` within the Flyout, with rows containing a `TextBlock` pair — the label in a secondary-brush proportional font (matching the web spec's muted, proportional labels) and only the snippet in monospace `FontFamily="Cascadia Mono"`. Light-dismiss is built-in; map web outside-click dismissal to `Flyout.IsLightDismissEnabled="true"` and Escape key dismissal to the Flyout's keyboard handling.

## Design Decisions

**Decision**: The syntax list is a module-level constant inside the component
rather than a prop.
**Rationale**: It is a fixed reference; a single authoritative cheatsheet
(DRY) is better than letting each consumer pass a divergent list.
**Approved**: pending

**Decision**: Built on the shared `SyntaxQuickReference` shell, which itself
is built on `Popover` (not a bespoke overlay or the modal `Dialog`).
**Rationale**: Reuse the platform dismissal + focus-restore behavior; a
lightweight, non-modal reference should not trap focus or dim the page.
**Approved**: pending

**Decision**: A fixed `aria-label` independent of `triggerLabel`.
**Rationale**: Keeps the accessible name stable for tests and assistive tech
even when a consumer shortens the visible label.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The trigger carries `aria-label="Markdown quick reference"` and the reference
content is a semantic `<dl>`, both driven by the shared `Popover` primitive's
`aria-expanded`/`aria-controls` wiring and keyboard (click or Escape)
handling — the source shows nothing that would make any of these `partial` or
`failed`. `no-hardcoded-strings` is `failed` because the title, aria-label,
default trigger text, and all nine row labels are fixed English strings with
no override or localization path from this component. `separation-of-concerns`
passes because `MarkdownQuickReference` only supplies the markdown-specific
`MARKDOWN_SYNTAX` entries and props to the shared `SyntaxQuickReference` shell,
with no popover, dismissal, or rendering logic of its own. `unit-test-coverage`
passes because `markdownQuickReference.test.tsx` exercises the collapsed
default, opening/listing the syntax entries, Escape dismissal, and a custom
trigger label.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Restored on-main 1.0.0 row (recipe, period); added best-practices Compliance rows. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: correct Overview/Appearance/Platform Notes to describe composing the shared SyntaxQuickReference shell instead of re-exporting it; fix title casing; replace the non-existent iOS UIMenu with UIPopoverPresentationController; fix the macOS/Compose/WinUI platform notes; ground Appearance in fieldCaptionClass and the shell's column width; add a dismiss-on-outside-click test vector and cover all nine labels in T2; reformat Design Decisions with Approved lines; rebuild Compliance as linked, source-grounded accessibility/internationalization checks; flag the hard-coded-strings localization gap as a known review item; correct the 1.0.0 row to say "ingredient"; and rename requirements to subject-only names |
| 1.2.0 | 2026-09-22 | Claude Haiku 4.5 | Rewrite Platform Notes with concrete translation guidance for SwiftUI, Compose, AppKit/UIKit, and WinUI 3 |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Update domain URI, fill all template sections with "Not applicable" explanations where no source implementation exists, correct status to review |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe for the shared markdown quick-reference popover (contract c11). |
