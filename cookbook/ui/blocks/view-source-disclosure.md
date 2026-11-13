---
id: 16e99364-8af3-40cb-beaf-d5a66a2fa2c0
title: "View Source Disclosure"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Collapsible disclosure component that reveals raw document source text on demand."
platforms:
  - typescript
  - web
tags:
  - disclosure
  - source
  - chrome
  - accessibility
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# View Source Disclosure

## Overview

A footer disclosure component that permits readers to view and copy the raw source of a document without parsing or transformation. The disclosure is deliberately understated—rendered as quiet chrome at the document's end—designed for readers actively seeking the markdown, not a feature meant to catch attention. The component is uncontrolled; once opened by the reader, state remains under the reader's control.

## Behavioral Requirements

- **render-trigger-button**: Component MUST render a button element that acts as the disclosure trigger.
- **render-label**: The trigger MUST render the provided `label` prop (defaults to "View source").
- **render-chevron-icon**: The trigger MUST render a chevron-right icon that visually indicates the disclosure state.
- **toggle-on-click**: Clicking the trigger MUST toggle the disclosure between open and closed states.
- **start-closed-by-default**: The disclosure MUST start in the closed state unless the `defaultOpen` prop is explicitly set to `true`.
- **render-source-verbatim**: When open, the component MUST render the `source` prop text exactly as provided, as a plain text node (escaped by the rendering framework), without parsing or transformation. The component MUST NOT inject the source via `innerHTML`, `dangerouslySetInnerHTML`, or any other HTML-parsing API.
- **not-parse-markdown**: The component MUST NOT interpret, parse, or render the source text as markdown or any other format.
- **render-source-in-pre-tag**: The source text MUST be rendered within a `<pre>` element to preserve whitespace and line breaks.
- **rotate-chevron-on-open**: The chevron icon MUST rotate 90 degrees when the disclosure is open and return to its default angle when closed.
- **wrap-text-not-truncate**: Text in the revealed source MUST wrap to the container width rather than truncate.
- **scroll-horizontally-for-long-lines**: When a single unbreakable token (long URL, table rule) exceeds the container width, the source area MUST scroll horizontally without wrapping that token.
- **source-selectable**: The revealed source text MUST be selectable using native text selection, so the reader can copy it.
- **accept-classname-prop**: The component MUST accept and apply a `className` prop to customize styling.
- **accept-html-attributes**: The component MUST accept and pass through standard HTML `div` attributes (via spread `...rest`).
- **set-aria-expanded**: The trigger button MUST set `aria-expanded` to `true` when open and `false` when closed.
- **conditionally-set-aria-controls**: When the disclosure is open, the trigger MUST set `aria-controls` to the panel's ID; when closed, `aria-controls` MUST NOT be set.

## Appearance

- **Container margin**: Top margin 32px (2rem); top border as a hairline rule in subtle border color; padding-top 16px (1rem)
- **Container border**: Top border only; width 1px; color `var(--color-border-subtle)`
- **Trigger styling**: Inline flex layout, items centered, gap 6px (0.375rem); monospace font, extra-small font size (~12px); text color `var(--color-text-dim)` at default, `var(--color-text-secondary)` on hover
- **Trigger button type**: `type="button"` (not submit or reset)
- **Chevron icon size**: 12px × 12px
- **Chevron stroke width**: 2.5 (SVG stroke-width units)
- **Chevron rotation**: 90 degrees when open; transition duration 150ms
- **Source panel styling**: Top margin 12px (0.75rem), padding 16px (1rem), border-radius medium (~6px), background `var(--color-surface-raised)`, border 1px `var(--color-border-subtle)`, monospace font, extra-small font size, text color `var(--color-text-secondary)`, relaxed line-height
- **Source panel overflow**: Horizontal scroll when needed, text wraps by default

## States

| State | Appearance change |
|-------|------------------|
| Default (closed) | Chevron points right (0°), source panel not rendered |
| Open | Chevron rotates 90° to point down, source panel visible below trigger |
| Hover (on trigger) | Trigger text color changes from dim to secondary |
| Focus (keyboard, on trigger) | Default browser focus ring is shown; the component applies no custom focus style |

## Accessibility

- **Role**: The trigger is a native button element; the `<pre>` element holding the source has no special ARIA role (it exposes as a generic element, not a code role), so assistive technology reads its content as plain text.
- **Expanded state**: The button MUST announce expanded/collapsed state via `aria-expanded`.
- **Panel association**: The button MUST associate the panel via `aria-controls` (only when open, per source implementation).
- **Label**: The trigger text serves as the button's accessible label via its text content.
- **Keyboard navigation**: As a native button, the trigger is keyboard accessible; Enter or Space activates it. No custom keyboard handling is required.
- **Assistive technology**: Screen readers will announce "View source, button, expanded" (or "collapsed") and read the panel content when opened.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| disclosure-001 | render-trigger-button, render-label | No props (defaults) | Trigger button renders with text "View source" |
| disclosure-002 | render-chevron-icon | No props | Chevron-right icon renders inside trigger |
| disclosure-003 | start-closed-by-default | No props | Disclosure starts closed; source panel is not in DOM |
| disclosure-004 | start-closed-by-default, render-source-in-pre-tag | `defaultOpen={true}` | Disclosure starts open; source panel is in DOM and visible |
| disclosure-005 | toggle-on-click, render-source-verbatim, not-parse-markdown | Click trigger when closed; `source="# Heading\n\n- List item"` | Panel appears showing raw text exactly as `"# Heading"` and `"- List item"`, not parsed as markdown |
| disclosure-006 | toggle-on-click | Click trigger when open | Panel closes and is removed from DOM |
| disclosure-007 | rotate-chevron-on-open | Click trigger to open | Chevron rotates to 90° with 150ms transition |
| disclosure-008 | rotate-chevron-on-open | Click trigger to close | Chevron rotates back to 0° with 150ms transition |
| disclosure-009 | wrap-text-not-truncate | `source="Short line\nVery long line that would exceed container width"` in narrow viewport | Long line wraps to multiple lines within container; does not overflow or truncate |
| disclosure-010 | scroll-horizontally-for-long-lines | `source="https://example.com/path/to/very/long/url/that/is/one/unbreakable/token"` in narrow viewport | Source area allows horizontal scroll; the URL does not wrap |
| disclosure-011 | accept-classname-prop | `className="custom-class"` | Custom class is applied to outer div alongside default classes |
| disclosure-012 | accept-html-attributes | `data-testid="source-disclosure"` | data attribute is present on outer div |
| disclosure-013 | set-aria-expanded | Click trigger to open, inspect button | `aria-expanded="true"` on button |
| disclosure-014 | set-aria-expanded | Click trigger to close, inspect button | `aria-expanded="false"` on button |
| disclosure-015 | conditionally-set-aria-controls | Trigger closed, inspect button | `aria-controls` attribute is absent |
| disclosure-016 | conditionally-set-aria-controls | Trigger open, inspect button and panel | `aria-controls` matches the panel's `id` |
| disclosure-017 | render-source-verbatim, not-parse-markdown | Click trigger to open; `source="<script>alert(1)</script>"` | Panel shows the literal text `<script>alert(1)</script>`; no `<script>` element is created and no code executes |
| disclosure-018 | source-selectable | Trigger open; select text within the source panel | Source text can be selected and copied via native text selection |

## Edge Cases

- **Empty source string**: If `source=""`, the component MUST render an empty `<pre>` element; the button remains functional and toggles the empty panel open/close.
- **Very long source**: If `source` contains many thousands of lines, all MUST be rendered in the `<pre>` without truncation or lazy loading; scrolling performance depends on browser capability.
- **Whitespace-only source**: If `source` contains only whitespace (spaces, tabs, newlines), it MUST be rendered exactly as provided within the `<pre>`.
- **Special characters in label**: If `label` is a string containing HTML special characters (e.g., `"<test>"`), it MUST be rendered as text, not parsed as HTML.
- **ReactNode label**: If `label` is a ReactNode (e.g., a component), it MUST be rendered as such within the button.
- **Multiple instances**: Multiple ViewSourceDisclosure components on the same page MUST each maintain independent open/close state via their own `useState` hook and `useId` hook for unique panel IDs.
- **State after unmount/remount**: The component is uncontrolled; if unmounted and remounted, it resets to `defaultOpen` state.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | `string` (required) | N/A | Raw document source text to reveal; rendered verbatim in `<pre>` |
| `label` | `ReactNode` | `"View source"` | Text or component rendered as the trigger's label |
| `defaultOpen` | `boolean` | `false` | Whether the disclosure starts open |
| `className` | `string` | `""` | Additional CSS classes to apply to the outer `<div>` |

## Deep Linking

Not applicable: this component is a disclosure toggle for static source content and does not navigate to or expose URLs.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `view-source-trigger-label` | "View source" | Default trigger label; can be overridden via `label` prop |

## Accessibility Options

- **Reduce Motion**: The chevron rotation transition (150ms) SHOULD respect `prefers-reduced-motion`. When this preference is active, the chevron SHOULD change angle instantly without transition.
- **Increase Contrast**: The component uses `var(--color-text-dim)` and `var(--color-text-secondary)` on hover. These CSS variables SHOULD be defined to meet WCAG AA contrast requirements (4.5:1 for text) even when Increase Contrast is active.
- **Differentiate Without Color**: The component does not rely on color alone to convey state; the chevron's rotation provides a visual indicator independent of color.

## Feature Flags

Not applicable: this component does not implement feature-flagged behavior.

## Analytics

Not applicable: this component does not emit analytics events. Host applications MAY track disclosure open/close events if desired, but the component itself does not.

## Privacy

- **Data collected**: None. The component receives `source` (raw document text) but does not transmit, store, or log it.
- **Storage**: No persistent storage.
- **Transmission**: The source text is never transmitted; it resides on the client.
- **Retention**: No data retention; state is ephemeral and lost on page navigation or refresh.

## Logging

Not applicable: this component does not emit logs.

## Platform Notes

- **React/Web**: Implemented using React hooks (`useState`, `useId`). Uses Lucide icon (`ChevronRight`) for the arrow. Styling via Tailwind utility classes with CSS variable references (`var(--color-*)`) for theme integration — see the `VIEW_SOURCE_DISCLOSURE_CLASS`, `VIEW_SOURCE_TRIGGER_CLASS`, and `VIEW_SOURCE_PRE_CLASS` exports for the exact classes (`mt-8`/`pt-4` for container spacing, `gap-1.5`/`text-xs` for the trigger, `h-3 w-3` for the chevron, `mt-3`/`p-4`/`rounded-md` for the panel, `duration-150` for the chevron transition). The component is a function component with uncontrolled state; the source text renders as a JSX text-node child of `<pre>`, which React escapes automatically.
- **Compose**: On Android, prefer a lightweight `Row(Modifier.clickable { ... })` or `TextButton` for the trigger rather than a filled `Button`, since the design calls for quiet inline chrome, not a prominent control; retain open/close state with `rememberSaveable { mutableStateOf(defaultOpen) }` so it survives configuration changes. Use an `Icon` for the chevron, animated with `animateFloatAsState()` and `Modifier.rotate()`. Wrap the revealed source `Text` in a `SelectionContainer` so it can be copied, and apply `Modifier.horizontalScroll(rememberScrollState())` so an unbreakable token scrolls instead of wrapping. Use `Modifier.border()`, `Modifier.padding()`, and `Modifier.clip()` to match the appearance.
- **SwiftUI**: On iOS/macOS, prefer `DisclosureGroup` as the native disclosure control, restyling its label and content to match the quiet chrome (no card frame); fall back to a custom `VStack` with a `Button` trigger only if `DisclosureGroup`'s built-in chrome cannot be suppressed for a given target. Use `@State` for the open/closed binding. Animate the chevron with `.rotationEffect(.degrees(isOpen ? 90 : 0))` inside `withAnimation(.easeInOut(duration: 0.15))`. Render the source in `Text(source).font(.system(.caption, design: .monospaced))` with `.textSelection(.enabled)` inside a horizontal `ScrollView` so long tokens scroll instead of wrapping.
- **AppKit / UIKit**: On older macOS or iOS targets, implement using `NSButton` (AppKit) or `UIButton` (UIKit) for the trigger, and `NSTextView` (AppKit) or `UITextView` (UIKit) with a monospace font for the source display. The text view MUST be non-editable and selectable, and MUST sit inside a scroll view that scrolls horizontally so a long unbreakable token can be reached without wrapping. Manage state with a boolean property and toggle it on the button's action. Use `CABasicAnimation` or `UIView.animate()` to rotate the chevron icon by 90°. Use `NSStackView` (AppKit) or `UIStackView` (UIKit) to manage layout.
- **WinUI 3**: On Windows, prefer the native `Expander` control (`Microsoft.UI.Xaml.Controls.Expander`) as the disclosure, restyling its header and content presenter to remove its default framed chrome; fall back to a hand-built trigger only if `Expander`'s chrome cannot be suppressed. If hand-building, use a `Button` with a `FontIcon` for the chevron (Segoe Fluent Icons glyph U+E76C, chevron-right) rotated via a `RotateTransform`, and a `TextBlock` with a monospace `FontFamily` (e.g. `Cascadia Code`) sized from a theme font-size resource rather than a hard-coded value, wrapped in a horizontally-scrolling `ScrollViewer` so long tokens scroll instead of wrapping. Place the trigger and content in a `StackPanel` with `Orientation="Vertical"`. Animate the chevron's `Angle` (0° to 90°) over 150ms with a `Storyboard`/`DoubleAnimation`. Bind the trigger's `Click` event to toggle `IsOpen`, and set `TextBlock.IsTextSelectionEnabled="True"` so the source can be copied.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/view-source-disclosure.tsx` | unverified |

## Design Decisions

**Decision**: Do not compose the toolkit's shared `Disclosure` component; keep this as a separate, self-contained disclosure.
**Rationale**: `Disclosure` renders a framed card — a rounded border, a raised surface, a `text-sm font-medium` title, and a ruled content box — for a host that wants that shape. Reaching this component's quiet inline look through `Disclosure` would mean cancelling nine of its visual decisions: the card chrome, the header padding, the chevron's size and colour, the title's family/size/weight/colour, and the content frame — to keep roughly 20 lines of open/close state. That is a standing coupling that would let a future `Disclosure` restyle silently break this component. The two disclosures encode different knowledge (a framed section vs. an inline text toggle), so duplicating the open/close mechanics is not a DRY violation.
**Approved**: pending

**Decision**: Keep the component uncontrolled — no `open`/`onOpenChange` props; state lives in an internal `useState`.
**Rationale**: Once opened, the reader owns the state. This reflects the component's role as a low-priority reader convenience, not a controlled UI element that a host form or flow needs to drive.
**Approved**: pending

**Decision**: Set `aria-controls` on the trigger only while the panel exists (open state).
**Rationale**: `aria-controls` is an IDREF; pointing it at a nonexistent element is an authoring error (axe: `aria-valid-attr-value`), not a harmless no-op. `aria-expanded` alone already announces the open/closed state to assistive technology, so nothing is lost by omitting `aria-controls` while the panel is absent.
**Approved**: pending

**Decision**: Render the source text as a plain text node — interpolated as a JSX child of `<pre>`, never assigned via `innerHTML`, `dangerouslySetInnerHTML`, or any other HTML-parsing API — with no markdown parsing or syntax highlighting.
**Rationale**: The rendering framework escapes text-node content automatically, so arbitrary source text (including strings that look like HTML or script tags) is always displayed literally and never interpreted as markup. The component is a raw-text viewer; the host owns syntax highlighting or transformation if it wants either.
**Approved**: pending

**Decision**: Use deliberately muted colors and small monospace type so the trigger reads as chrome, not content.
**Rationale**: A reader seeking the raw markdown will look for the disclosure; a reader who doesn't need it should not be visually drawn to notice it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The source grounds the passed rows: a native `button` with `aria-expanded` and conditional `aria-controls`, and a source panel rendered as a JSX text-node child of `<pre>` (never `innerHTML`). The `partial` rows rest on things the source does not itself control — the `--color-*` token values, whether `prefers-reduced-motion` is honored, and whether text sizing scales with system font settings are all defined outside this component. `separation-of-concerns` passes because the component holds only its own open/closed UI state with no business logic; `unit-test-coverage` passes on `viewSourceDisclosure.test.tsx`'s exercise of its open/close toggle, verbatim source rendering, ARIA state, and class contracts.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited; reworded verbatim-rendering to rule out HTML injection and added a script-payload test vector; added a `source-selectable` requirement and vector; fixed the disclosure-005 test-vector text and the disclosure-012 requirement mapping; corrected the `<pre>` role claim; converted Design Decisions to the Decision/Rationale/Approved format and removed source-referential phrasing; expressed Appearance in generic units and moved Tailwind classes to the React/Web platform note; added a keyboard-focus state; corrected the SwiftUI, Compose, WinUI 3, and AppKit/UIKit platform notes and led each with its native disclosure control; added tags and a Compliance table; fixed the lowercase "must" in the very-long-source edge case |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
