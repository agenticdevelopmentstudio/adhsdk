---
id: 42e7a2ea-f138-4edb-899f-43c1946e4ef8
title: FAQ
domain: adhsdk://recipes/faq
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Disclosure list of questions and answers using native HTML details/summary
  elements, requiring no JavaScript for expand/collapse.
platforms:
- typescript
- web
tags:
- faq
- disclosure
- disclosure-list
depends-on: []
related:
- adhsdk://recipes/accordion
- adhsdk://recipes/disclosure
references: []
approved-by: ''
approved-date: ''
---

# FAQ

## Overview

The FAQ component renders a list of questions and answers as a disclosure
list: collapsible widgets where, unlike an accordion, more than one entry can
be open at the same time. Each question appears in a clickable summary;
clicking expands to reveal the answer. Built entirely from native HTML
`<details>` and `<summary>` elements, it requires no JavaScript logic for
expand/collapse behavior. The component supports setting one or more entries
to start in the expanded state. It remains open when printed, and question
text plus the content of any currently open entry is searchable with the
browser's Find function. See adhsdk://recipes/accordion for a
single-open variant of this pattern, and adhsdk://recipes/disclosure
for a single collapsible section.

## Behavioral Requirements

- **one-details-per-entry**: Each entry in the `entries` array MUST render as its own `<details>` element, in the same order as the array.
- **entries-prop**: Component MUST accept an `entries` prop of type `FaqEntry[]`.
- **question-in-summary**: The `question` field of each FaqEntry MUST render inside a `<summary>` element as the disclosure label.
- **answer-as-content**: The `answer` field of each FaqEntry MUST render as content inside the `<details>` element, outside the `<summary>`.
- **initial-open-state**: Each FaqEntry's `open` field MUST cause the corresponding `<details>` element's `open` attribute to be set to match `open === true` on every render. Because the value is re-applied whenever `entries[i].open` changes, a later render that changes the value overrides whatever the user had toggled in the browser; when `entries[i].open` does not change between renders, the user's own toggle is left alone. See #edge-cases/re-render-with-changed-open.
- **reactnode-content**: Both `question` and `answer` MUST accept any valid React `ReactNode` value, including strings, numbers, components, and fragments.
- **browser-native-toggle**: Users MUST be able to toggle disclosure by clicking the summary, using Enter or Space keys on keyboard focus, or tapping on mobile, with no custom event handlers required — browser-native `<details>` behavior applies.
- **print-preserves-open**: When the page is printed, all expanded entries MUST remain open in the print layout.
- **findable-text**: Question text and the content of any currently open entry MUST be discoverable using the browser's Find feature (Ctrl+F / Cmd+F) without JavaScript interception. Only Chromium-based browsers additionally search inside a *closed* `<details>` element and auto-expand it on a match; other browsers do not search collapsed content, so a closed answer is not guaranteed findable across browsers. See #test-vectors/faq-007.

## Appearance

The component renders semantic HTML with no inline styles. Appearance is entirely controlled by external CSS via the `lp-faq` class on the root container and browser default `<details>`/`<summary>` styling:

- **Container**: A `<div>` with class `lp-faq` wraps all entries.
- **Entry structure**: Each entry is a native `<details>` element.
- **Summary styling**: Browser default — typically bold text, with a disclosure triangle before the text. Exact appearance (icon shape, animation, colors) depends on the stylesheet.
- **Details content**: Rendered as block content within the details element. Browser default includes margin/padding between summary and content.
- **Visual state indicators**: The browser provides a visual indicator (disclosure triangle rotation or similar) when the details element is open vs. closed.

## States

| State | Behavior |
|-------|----------|
| Closed | Summary visible; answer hidden. Disclosure triangle/icon points right (or icon is neutral). Clicking or pressing Enter/Space toggles to open. |
| Open | Summary visible; answer visible below. Disclosure triangle/icon points down. Clicking or pressing Enter/Space toggles to closed. |
| Focused (keyboard) | When summary receives keyboard focus (via Tab), the summary element shows focus indicator (browser or CSS-defined). |

The component does not manage state internally — all state changes are handled by the browser's native `<details>` element.

## Accessibility

- **Semantic role**: The native `<details>` and `<summary>` elements carry their standard ARIA semantics. Screen readers announce the summary as a disclosure button with expanded/collapsed state.
- **Keyboard navigation**: Tab navigation moves focus between summaries. Enter and Space toggle the open state. Arrow keys are not required (disclosure is a button, not a tree widget).
- **Screen reader announcement**: Screen readers announce the summary text and whether the disclosure is expanded or collapsed. The answer content is announced when the disclosure is expanded.
- **Label requirement**: Each summary MUST contain meaningful text that describes the question or topic (the `question` prop). This label is read by screen readers and serves as the button label.
- **No custom ARIA required**: The `<details>` and `<summary>` elements provide `role=button` and `aria-expanded` semantics automatically; no custom ARIA markup is needed.
- **Focus visibility**: The browser provides a focus indicator on the summary when navigated via keyboard. CSS may customize this via standard focus-visible styling.
- **Minimum touch target**: Not specified in source. Per [WCAG 2.2 SC 2.5.8 (Target Size Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html), the summary click target SHOULD be at least 24×24 CSS pixels (Level AA baseline); [WCAG 2.5.5 (Target Size, Level AAA)](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html) recommends the stricter 44×44 CSS pixels. Meeting either is the responsibility of the consuming stylesheet.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| faq-001 | one-details-per-entry, question-in-summary, answer-as-content | entries = `[{ question: "Q1", answer: "A1" }]` | HTML output contains one `<details>` with one `<summary>` containing "Q1" and one text node "A1" as child of details (not summary). |
| faq-002 | entries-prop | entries = `[]` | Component renders without error; output is `<div class="lp-faq"></div>` (no child details elements). |
| faq-003 | initial-open-state | entries = `[{ question: "Q1", answer: "A1", open: true }, { question: "Q2", answer: "A2", open: false }]` | First details element renders with `open` attribute; second does not. |
| faq-004 | reactnode-content | entries = `[{ question: <h3>Question</h3>, answer: <p>Answer text</p> }]` | Summary contains the h3; details body contains the p element. Both render without type errors. |
| faq-005 | browser-native-toggle | Rendered FAQ with two entries, first `open: false`. Playwright: `page.getByText('Q1').click()`. | The first `<details>` element's `open` attribute goes from absent to present and its answer locator becomes visible (`toBeVisible()`). Repeating with the summary focused and `Enter`/`Space` pressed instead of clicked produces the same result. |
| faq-006 | print-preserves-open | Rendered page with one entry `open: true`, one `open: false`. Playwright: `page.emulateMedia({ media: 'print' })`. | The open entry's `<details>` element still has the `open` attribute and its answer is not `display: none`; the closed entry's `open` attribute is still absent. |
| faq-007 | findable-text | Rendered FAQ with entry `question: "What is this?"`, `answer: "It is a FAQ."`, entry closed. | The summary text "What is this?" is present and visible in the DOM, so a browser Find match on it succeeds without JavaScript. The closed answer text "It is a FAQ." is present in the DOM but its `<details>` ancestor is closed (`isHidden()`); only Chromium's Find searches inside it and auto-expands the element, which this vector documents rather than asserts (Playwright cannot drive the browser's native Find UI). |
| faq-008 | initial-open-state | Rendered entry `open: false`. User clicks the summary to open it (native browser toggle). Component re-renders with the same `entries` array where that entry's `open` is still `false` (value unchanged). | The `<details>` element remains open: React does not write to the `open` DOM property because the value passed to it did not change from the previous render. |
| faq-009 | initial-open-state | Continuing from faq-008 (entry opened by the user, prop still `false`), the parent then re-renders with that entry's `open` prop changed to `true`. | React writes `open` to `true` on the `<details>` element (no visible change here since it was already open by the user's toggle). If the prop instead changed to `false` while the user had opened it, the element would be forced closed. This demonstrates that `open` is re-asserted on every change to the prop's value, not applied once at mount. |

## Edge Cases

- **Empty entries array**: Component MUST render without error. Output is a single `<div class="lp-faq"></div>` with no children.
- **Null or undefined entries**: Not applicable. The prop type is `FaqEntry[]`; null/undefined assignment is a type violation, not a runtime edge case the component handles.
- **Null or undefined question/answer**: React will render `null` or `undefined` as nothing (empty space). If this is undesirable, the caller MUST validate entries before passing to the component.
- **Very long question or answer**: No constraint in source. Content renders as-is; CSS is responsible for text wrapping and overflow handling.
- **Special characters or HTML in question/answer**: Behavior depends on the input type. If `question` is a string, HTML characters are rendered as text (safe). If `question` is a component containing HTML, that HTML renders as intended. No HTML sanitization is performed by the component.
- **Multiple entries with open: true**: All MUST start expanded. Browser allows multiple `<details>` elements to be open simultaneously (unlike a single-open accordion — see adhsdk://recipes/accordion); behavior matches the source design.
- **Key collisions**: Entries are keyed by array index (`key={i}` in the source). If the entries array is mutated (items reordered or removed), React will reuse DOM nodes by index, which may cause state mismatches. This is a known limitation of index-based keying; the component does not validate or warn about it, and the source has no `id` field to key by instead — see **index-based-keying** under Design Decisions.
- **Re-render with changed open**: See **initial-open-state**. A re-render that changes `entries[i].open` overrides the user's own toggle for that entry; a re-render that leaves the value unchanged does not touch the browser's live state. See #test-vectors/faq-008 and #test-vectors/faq-009.

## Configuration

Not applicable. The component accepts only the `entries` prop; no configuration options are exposed.

## Deep Linking

Not applicable, and not supported by the source: entries carry no `id` field, so there is no per-entry anchor or URL pattern to link a specific question into view. A caller needing this would have to wrap each entry with an externally-managed anchor id; the component itself defines none.

## Localization

Not applicable. All text (question and answer) is provided by the caller via the `entries` prop. The component does not render any fixed text strings. Localization is the caller's responsibility.

## Accessibility Options

The component responds to all standard browser and system accessibility settings:

| Option | Behavior |
|--------|----------|
| Reduce Motion | The component itself defines no animation. Any consumer CSS animation applied to the disclosure triangle or the details/summary transition MUST be disabled (or reduced to an instant state change) under the `prefers-reduced-motion` media query. |
| Increase Contrast | The browser's default `<details>` and `<summary>` styling respects the system contrast setting. High-contrast CSS MUST ensure the disclosure button text, background, and focus indicator meet WCAG AA or AAA contrast ratios. |
| Differentiate Without Color | Disclosure state MUST NOT be indicated by color alone. The browser's default triangle or icon indicator provides a shape change; custom CSS styling MUST preserve a non-color differentiator (icon change, text decoration, etc.). |

## Feature Flags

Not applicable. The component does not reference or check any feature flags in the source code.

## Analytics

Not applicable. The component does not emit or listen for analytics events. Analytics instrumentation is the caller's responsibility.

## Privacy

Not applicable. The component does not collect, store, or transmit any user data.

## Logging

Not applicable. The component does not emit any log messages.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/landing/src/blocks/Faq.tsx`. Exports a functional component accepting `{ entries: FaqEntry[] }` where `FaqEntry` has `question`, `answer`, and optional `open` fields. Renders entries as native HTML `<details>` and `<summary>` elements wrapped in a `<div class="lp-faq">` container. All state management is delegated to the browser's native disclosure behavior; no React state or event handlers are used for toggle logic.

- **SwiftUI**: Implement using SwiftUI's native `DisclosureGroup`. Each entry becomes a `DisclosureGroup` with the question as the label and the answer as the content. The `isExpanded` binding is seeded from the source's `open` field, matching the source's uncontrolled default. SwiftUI has no equivalent of browser print layout or Find; **print-preserves-open** and **findable-text** have no native counterpart on this platform.

- **Compose**: Implement each entry as a clickable header `Row` (the question) with `Modifier.semantics { stateDescription = if (expanded) "Expanded" else "Collapsed" }`, toggling a local `mutableStateOf<Boolean>` seeded from the source's `open` field, followed by `AnimatedVisibility` wrapping the answer content — or a Material 3 `ExpandableCard`-style composable providing the same pattern. There is no Compose equivalent of browser print layout or Find; **print-preserves-open** and **findable-text** do not apply on this platform.

- **AppKit / UIKit**: A static Q&A list does not need `NSOutlineView` or `UITableView`. Implement using an `NSButton` with a `.disclosure` bezel style inside an `NSStackView` on macOS, and a `UIButton` toggle driving a `UIStackView` on iOS. The `open` field maps to the button's initial expanded state. Keyboard navigation (Tab, Enter/Space) and VoiceOver support come from the standard control and stack view accessibility; give the toggle control an `accessibilityLabel` describing the question and an `accessibilityHint` indicating it expands/collapses the answer.

- **WinUI 3**: Implement using the `Expander` control, one per question-answer pair inside an `ItemsControl` or stack panel. Bind `Expander.IsExpanded` to a boolean in the data model, seeded from the `open` field's initial value. The `Header` property displays the question; the `Content` property displays the answer. Keyboard support (Enter/Space on a focused header) and Narrator screen-reader support come from the native `Expander` control.

## Design Decisions

- **Decision**: Build the disclosure list from native HTML `<details>`/`<summary>` elements rather than a custom JavaScript accordion component.
  **Rationale**: Eliminates the need for stateful JavaScript logic, reduces bundle size, ensures the component works without client-side rendering, and leverages the browser's built-in accessibility and print handling. Trade-off: the animation and visual styling are browser-default and less customizable than a fully scripted accordion; customization is achieved through CSS.
  **Approved**: pending

- **Decision**: Key each rendered entry by its array index (`key={i}`) rather than by a caller-supplied identifier (index-based-keying).
  **Rationale**: Acceptable for a static or rarely-reordered list. If the `entries` array is mutated (items added, removed, or reordered), React reuses DOM nodes by index, which can cause open/closed state to attach to the wrong entry. The source does not validate or guard against this, and defines no `id` field — keeping the array stable is the caller's responsibility.
  **Approved**: pending

- **Decision**: Make `open` optional per entry, defaulting to `false`, with the convention (documented in a source comment) that normally exactly one entry carries it.
  **Rationale**: Showing exactly one answer expanded by default reads as an FAQ section rather than a list of collapsed links. The component does not enforce this convention — the caller controls which entries are open.
  **Approved**: pending

- **Decision**: Define no custom `onClick`, `onChange`, or other event handlers; delegate all interactivity to the browser's native `<details>` implementation.
  **Rationale**: Keeps the component functional without JavaScript and preserves browser behaviors like print preservation and Find searchability (**print-preserves-open**, **findable-text**). Callers who need to react to state changes (e.g., an analytics event) must add a wrapper outside this component.
  **Approved**: pending

- **Decision**: Describe this component as a "disclosure list," not an "accordion," in its title, summary, and tags.
  **Rationale**: Several entries can be open at the same time, which is not how an accordion usually behaves. adhsdk://recipes/accordion is the single-open variant; readers who expect single-open behavior are pointed there instead of finding it here under a name that overpromises.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The passed accessibility rows rest on the source using native `<details>`/`<summary>` elements, which carry built-in disclosure semantics and full keyboard support (click, Enter, Space) with no custom ARIA or event handlers. The partial rows rest on the source rendering no inline styles, colors, or sizing at all — text scaling, contrast, and touch target size are fully determined by the `lp-faq` stylesheet, which is not part of this source file. The internationalization row rests on the source containing zero user-facing string literals; all text is supplied by the caller through the `entries` prop. `separation-of-concerns` is `passed` because the component is pure presentation over the `entries` prop with no logic beyond mapping; `unit-test-coverage` is `passed` because `blocks-close.test.tsx` renders `Faq` directly and asserts its `<details>` markup.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; narrowed findable-text to question text plus open-entry content and noted the Chromium-only closed-details Find behavior; clarified initial-open-state as re-asserted on every prop change rather than initial-only, with two new test vectors; rewrote the browser-behavior test vectors as Playwright assertions; corrected the touch-target citation to WCAG 2.2 SC 2.5.8 (AA) with 2.5.5 (AAA) as the stricter option; reformatted Design Decisions into Decision/Rationale/Approved form; added a Compliance table; renamed the component a disclosure list rather than an accordion and added the accordion and disclosure recipes to related; trimmed SwiftUI/Compose/WinUI 3 platform notes to drop unbuilt persistence and print/export behavior; replaced the Compose and AppKit/UIKit platform notes with fitting controls; stated Deep Linking is unsupported explicitly; scoped Reduce Motion to consumer CSS animation |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Reshaped the index-based-keying Design Decision into a `**Decision**`/`**Rationale**`/`**Approved**` line triple. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
