---
id: 46a9c075-098d-46bd-9b62-e3afeb9bd577
title: "Markdown Document Pane"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A whole detail pane for one markdown document: a flush Cancel/Save bar above a padded Source / Preview editor body, with a read-only mode."
platforms:
  - typescript
  - web
tags:
  - document-pane
  - editing-actions
  - markdown-editor
depends-on: []
related:
  - c54698ea-490c-41e2-ad8f-762f257839ca
references: []
approved-by: ""
approved-date: ""
---

# Markdown Document Pane

## Overview

The Markdown Document Pane is a whole detail pane for one markdown document. It stacks two things: the platform's Cancel/Save bar, flush against the top and sides of the pane, and below it a padded body holding the document's Source / Preview view. The document comes from a `useVersionedDocument` hook (it carries the text, an `edit` function and the save, conflict and revert state). The pane owns the layout so that a host renders it as the pane's content with no padding of its own and cannot wrap the bar in padding by mistake.

The pane also exports `MarkdownDocumentPaneBody`, the padded body on its own, for a host that shows something else in the pane's place (loading, not found, an error) and wants it to line up with the loaded pane. The Cancel/Save bar is the Document Save Bar ([adhsdk.ingredient.ui.blocks.document-save-bar](cookbook:c54698ea-490c-41e2-ad8f-762f257839ca)) block; the editing view is the `MarkdownDocumentEditor` component, to which every prop the pane does not consume is forwarded.

## Behavioral Requirements

- **pane-root-slot**: The pane MUST render a root element carrying `data-slot="markdown-document-pane"`.
- **pane-root-layout**: The pane root MUST be a full-height, vertical flex column that may shrink below its content size on both axes (classes `flex h-full min-h-0 min-w-0 flex-col`).
- **bar-first**: When the bar is shown, the pane MUST render it as the first child of the root, before the body.
- **bar-outside-body**: The pane MUST NOT render the bar inside the padded body.
- **bar-when-editable**: The pane MUST show the Cancel/Save bar while `editable` is true.
- **bar-hidden-read-only**: The pane MUST NOT show the bar when `editable` is false and the document is neither dirty nor in conflict.
- **bar-kept-for-draft**: The pane MUST keep the bar while `document.dirty` is true, even when `editable` is false, so Cancel stays within reach.
- **bar-kept-for-conflict**: The pane MUST keep the bar while `document.conflict` is not null, even when `editable` is false, so Reload theirs stays within reach.
- **bar-document**: The pane MUST pass the `document` prop to the bar as the bar's document.
- **bar-noun**: The pane MUST pass `noun` to the bar, and `noun` MUST default to `document` when omitted.
- **bar-messages**: The pane MUST pass `messages` to the bar unchanged, so a host can replace any of the bar's notices.
- **body-slot**: The body MUST render a root element carrying `data-slot="markdown-document-pane-body"`.
- **body-padding**: The body MUST be padded with `p-4` (1rem on every side) and lay its children out in a vertical flex column with a `gap-3` (0.75rem) gap.
- **body-fills-pane**: The body MUST fill the space below the bar (`flex-1`) and may shrink below its content size (`min-h-0 min-w-0`).
- **host-children-first**: The pane MUST render the `children` prop inside the body, above the editor.
- **editor-after-load**: The pane MUST render the editor only once `document.value` is not null.
- **body-empty-before-load**: While `document.value` is null the pane MUST render no editor, leaving the body with only the host's children.
- **editor-value**: The pane MUST give the editor the document's `value` as its `value`.
- **editor-change**: The pane MUST give the editor `document.edit` as its `onChange`.
- **editor-read-only**: The pane MUST give the editor `readOnly` set to the negation of `editable`.
- **editor-forwarding**: The pane MUST forward every prop it does not consume (everything except `document`, `editable`, `noun`, `messages` and `children`) to the editor.
- **editor-props-closed**: The pane MUST NOT accept `value`, `onChange` or `readOnly` from the host, because they are derived from `document` and `editable` (the props type omits them).
- **body-export**: The module MUST export `MarkdownDocumentPaneBody` as a standalone component rendering the same padded body, for a host's loading, not-found or error states.

## Appearance

- **Corner radius**: None on the pane or body; the pane is a layout shell.
- **Padding**: The body is 16px on all sides (`p-4`); the bar has none and sits flush against the top and sides of the pane.
- **Font**: Not applicable: the pane renders no text of its own; text comes from the bar and the editor.
- **Background**: None set by the pane; it inherits from the host.
- **Foreground/Text**: None set by the pane.
- **Border**: None on the pane or body.
- **Shadow**: None.
- **Min/Max size**: The pane fills the height of its container (`h-full`) and may shrink below content size (`min-h-0 min-w-0`) so the editor scrolls inside it. The body is a column with a 12px gap (`gap-3`) between the host's children and the editor.

## States

| State | Appearance change |
|-------|------------------|
| Default | Bar above (when shown), body below with the editor in editable mode. |
| Pressed | Not applicable: the pane is a layout container with no pressable surface of its own; the bar's buttons own pressed styling. |
| Disabled | Read-only: `editable` is false, the editor is given `readOnly`, and the bar is absent unless a draft or conflict is pending. |
| Focused | Not applicable: the pane takes no focus itself; focus lives in the bar's buttons and the editor's controls. |
| Loading | `document.value` is null: the body shows only the host's children and no editor. |
| Draft pending, not editable | The bar stays visible and the editor is read-only. |
| Conflict pending, not editable | The bar stays visible, including the bar's conflict warning with Reload theirs and Overwrite. |

## Accessibility

- **Role/trait**: The pane root and body are plain `div` elements with no role of their own. The bar's toolbar is labeled "Editing actions" (the Button Bar's default `ariaLabel`, observed in the pane's test); the editor owns the Source and Preview semantics.
- **Label requirements**: The pane adds no labels. A host that renders two panes on one page must rely on the editor's `subject` prop (forwarded) to tell the layout controls apart.
- **Announce state changes**: The pane announces nothing itself; save errors, gone and conflict notices are rendered by the bar.
- **Keyboard path**: Every interactive control is inside the bar or the editor; the pane adds none and does not intercept keys.
- **Minimum tap target**: Not applicable: the pane has no controls of its own; target sizes are set by the bar's buttons and the editor.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-001 | bar-first, bar-outside-body, body-padding, editor-read-only | `markdownDocumentPane.test.tsx` "puts the Cancel/Save bar first, flush, outside the padded body": a loaded, clean document, `editable` true | The "Editing actions" toolbar is inside the root's first child, not inside the body; the body class contains `p-4`; the editor reports `data-readonly="false"` |
| pane-002 | bar-hidden-read-only, editor-read-only | `markdownDocumentPane.test.tsx` "shows a read-only document without the bar": clean document, `editable` false | No "Editing actions" toolbar; the editor reports `data-readonly="true"` |
| pane-003 | bar-kept-for-draft | `markdownDocumentPane.test.tsx` "keeps the bar while a draft is pending after the document stops being editable": `dirty` true, `editable` false | The "Editing actions" toolbar is present |
| pane-004 | host-children-first, body-slot | `markdownDocumentPane.test.tsx` "renders the host's own content in the body, above the editor": a `<p>` child, `editable` true | The body's first element child is the host paragraph and the body contains the editor |
| pane-005 | editor-after-load, body-empty-before-load | `markdownDocumentPane.test.tsx` "leaves the body empty until the document loads": `value` null, `editable` false | No editor is rendered |
| pane-006 | bar-kept-for-conflict | Clean document with `conflict` set to a non-null value, `editable` false | The bar is present |
| pane-007 | bar-hidden-read-only | `dirty` false, `conflict` null, `editable` false | The bar is absent (negative companion to pane-003 and pane-006) |
| pane-008 | editor-value, editor-change | `value` "# Hello", `edit` a spy | The editor receives "# Hello" as its value; its `onChange` is the `edit` function |
| pane-009 | editor-forwarding | An extra editor prop such as `defaultLayout` passed to the pane | The editor receives that prop unchanged |
| pane-010 | body-slot, body-export | Render `MarkdownDocumentPaneBody` with a child | A `data-slot="markdown-document-pane-body"` element wraps the child; no bar or editor is rendered |
| pane-011 | bar-noun, bar-messages | `noun` omitted, then `noun` "note" with a `messages` override | The bar's notices use "document" by default, then "note", and the override text replaces the default wording |

`markdownDocumentPane.test.tsx` covers pane-001 to pane-011.

## Edge Cases

- **Null document value**: When `document.value` is null the pane MUST render the body with only the host's children and no editor (**editor-after-load**).
- **Empty string value**: An empty string is not null, so the pane MUST render the editor with an empty value; the editor, not the pane, decides what an empty document looks like.
- **Editable flips to false with a draft**: The pane MUST keep the bar visible while `dirty` is true, so the author can still Cancel the draft (**bar-kept-for-draft**).
- **Editable flips to false with a conflict**: The pane MUST keep the bar visible while `conflict` is not null (**bar-kept-for-conflict**).
- **Editable flips to true**: The bar appears at once and the editor loses `readOnly`; the pane keeps no state of its own.
- **No children**: With no `children` the body holds only the editor, or nothing before load.
- **Error states**: The pane does not handle errors itself. A failed save, a vanished document and a conflict are shown by the bar from the document's flags; a host showing a load error renders `MarkdownDocumentPaneBody` instead.
- **Boundary values**: Not applicable: the pane has no numeric or length-constrained input.
- **Concurrent access**: The pane is a stateless view over the document object it is handed; concurrent edits are detected by the document hook and surfaced as the conflict flag, not by the pane.
- **Offline or disconnected state**: Not applicable: the pane makes no network calls; a save that fails is reported by the bar as a save error.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `document` | `DocumentSaveBarProps['document'] & { value: string or null; edit: function }` | required | The document from `useVersionedDocument`. Until `value` loads the body is empty. |
| `editable` | boolean | required | Whether the document may be changed here. False shows the same view without the bar, unless a draft or conflict is pending. |
| `noun` | string | `document` | What the document is called in the bar's notices ("file", "note"). |
| `messages` | `DocumentSaveBarMessages` | none | Replaces any of the bar's notices. |
| `children` | ReactNode | none | The host's own content above the editor, inside the padded body. |
| Editor props | `MarkdownDocumentEditorProps` less `value`, `onChange`, `readOnly` | editor's own | Every other prop is forwarded to `MarkdownDocumentEditor`. |

## Deep Linking

Not applicable: the pane is a layout component with no route or URL of its own; any routing is the host's.

## Localization

Not applicable: the pane renders no strings of its own. The bar's notices are English templates built from `noun` and can be replaced through `messages`; the Source and Preview labels belong to the editor.

## Accessibility Options

Not applicable: the pane has no motion, color or contrast behavior of its own, and responds to no accessibility display option; any such response belongs to the bar and the editor.

## Feature Flags

Not applicable: the pane is always enabled when rendered; the source reads no flag.

## Analytics

Not applicable: the pane emits no events.

## Privacy

- **Data collected**: None by the pane.
- **Storage**: None; the document text lives in the `useVersionedDocument` object the host passes in.
- **Transmission**: None by the pane; saving is performed by the document's `save` function, outside the pane.
- **Retention**: Not applicable: the pane keeps no data.

## Logging

Not applicable: the pane emits no log messages.

## Platform Notes

- **SwiftUI**: Use a `VStack(spacing: 0)` with the save bar as the first child (full width, no padding) and a padded `VStack(spacing: 12)` body below it with `.padding(16)`. Show the bar when `editable || dirty || conflict != nil`. Pass `.disabled(!editable)` or a read-only text view for the source; `TextEditor` has no native read-only flag, so use `Text` with `.textSelection(.enabled)` for read-only. Build the Source / Preview switch with a `Picker` in `.segmented` style.
- **Compose**: Use a `Column(Modifier.fillMaxSize())` with the bar first and a `Column(Modifier.weight(1f).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp))` body. Show the bar with `if (editable || dirty || conflict != null)`. Use `OutlinedTextField(readOnly = !editable)` for the source and a `TabRow` for Source and Preview.
- **React/Web**: The source is `packages/web/packages/markdown/src/components/MarkdownDocumentPane.tsx`, a client component exporting `MarkdownDocumentPane` and `MarkdownDocumentPaneBody` (re-exported from the package index). It composes `DocumentSaveBar` from `@adh-sdk/ui/blocks/document-save-bar` and `MarkdownDocumentEditor`, styled with Tailwind utility classes. The tests are `packages/web/packages/markdown/src/__tests__/markdownDocumentPane.test.tsx`, which mocks the editor and checks only layout.
- **AppKit / UIKit**: On AppKit use an `NSStackView` (vertical, spacing 0) with the bar first and a padded inner stack of 12pt spacing and 16pt edge insets; set `NSTextView.isEditable = editable` and `isSelectable = true` for read-only. On UIKit use a vertical `UIStackView` with `layoutMargins` of 16 on the body and `UITextView.isEditable = editable`.
- **WinUI 3**: Use a `Grid` with two `RowDefinition`s, the first `Height="Auto"` for the save bar and the second `Height="*"` for the body, with the bar at `Grid.Row="0"` and no margin so it sits flush. Make the body a `StackPanel Spacing="12" Padding="16"` (or a `Grid` with `RowSpacing="12"`). Bind the bar's `Visibility` to `Editable or Dirty or Conflict is not null` through a converter. For the editor use a `TextBox` with `AcceptsReturn="True"`, `TextWrapping="Wrap"` and `IsReadOnly="{x:Bind Editable, Converter=...}"`; a read-only `TextBox` stays selectable, matching the source's "selectable but not editable". Pair it with a `Pivot` or `SelectorBar` for Source and Preview, and a `WebView2` or `MarkdownTextBlock` for the preview. The bar's visual states come from the default `Button` style (Normal, PointerOver, Pressed, Disabled).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/markdown/src/components/MarkdownDocumentPane.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The pane, not the host, owns the layout of the bar and the body, with the bar flush and only the body padded.
**Rationale**: The source comment says this is "the whole point of the pane": a host renders it with no padding, so no host can wrap the bar in padding by mistake.
**Approved**: pending

**Decision**: The bar stays visible after the document stops being editable while a draft is dirty or a conflict is pending.
**Rationale**: The source comment gives the reason: Cancel and Reload theirs must stay within reach, or an author could be left with an unsaved draft they cannot discard.
**Approved**: pending

**Decision**: The editor is not rendered until `document.value` is not null; the body stays empty rather than showing a placeholder.
**Rationale**: The prop documentation says "Until its `value` loads the pane shows its body empty." Hosts show their own loading state through the children or `MarkdownDocumentPaneBody`.
**Approved**: pending

**Decision**: `value`, `onChange` and `readOnly` are omitted from the pane's props and derived from `document` and `editable`.
**Rationale**: The type extends the editor's props with those three omitted, so the pane stays the single place that wires the document to the editor and a host cannot pass a value that disagrees with the document.
**Approved**: pending

**Decision**: `MarkdownDocumentPaneBody` is exported separately.
**Rationale**: The source comment says it is for a host "showing something in the pane's place (loading, not found, an error) so it lines up with the loaded pane."
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |

The pane contains no logic beyond one boolean (`dirty` or `conflict`) and one null check; saving, conflicts and editing are delegated to the bar, the document hook and the editor, so separation-of-concerns passes. The test file covers all eleven vectors (bar placement, read-only, a pending draft or conflict, host children, pre-load, editor value and change, prop forwarding, the standalone body, `noun` and `messages`), so unit-test-coverage passes. Every control is inside the bar and the editor and the pane adds none, so keyboard navigation passes by delegation. The pane's own elements are plain `div` elements with `data-slot` attributes and no landmark or role, so semantic-markup is partial.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (markdownDocumentPane.test.tsx, 11 of 11 vectors); unit-test-coverage now passed. |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
