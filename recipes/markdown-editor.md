---
id: b118c7bc-e163-40f0-bcc8-eb079e835794
title: MarkdownEditor
domain: adhsdk://recipes/markdown-editor
type: recipe
version: 1.2.1
status: review
language: en
created: '2026-06-26'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A labelled markdown-body textarea with an editor toolbar: built-in .md upload, a quick-reference popover, and a slot for extra toolbar controls."
platforms:
- typescript
- web
tags:
- markdown
- editor
- textarea
- toolbar
- form
ingredients:
- adhsdk://recipes/textarea
- adhsdk://recipes/label
- adhsdk://recipes/editor-toolbar
- adhsdk://recipes/markdown-quick-reference
- adhsdk://recipes/button
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# MarkdownEditor

## Overview

A composition in `@adh-sdk/ui` (`blocks/markdown-editor`) that encapsulates
markdown **body** editing: a labelled `Textarea` for the raw markdown source with
an `EditorToolbar` row above it. The toolbar carries an optional built-in
upload control (accepting `.md`, `.markdown`, and `.txt` files), a built-in
`MarkdownQuickReference` popover, and a slot for extra controls (e.g. a future
spell-check toggle).

It is controlled via `value` / `onChange`. The label is associated with the
textarea (`htmlFor`), so it is the textarea's accessible name. The editor owns no
title, category, or classification fields — those stay with the consuming form
(e.g. a research-notes detail view), which composes this block for the body and
derives a title from an upload when it wants one.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| Textarea | adhsdk://recipes/textarea | The markdown source field | yes | `id` (from `useId`), `rows`, `spellCheck`, mono font |
| Label | adhsdk://recipes/label | Caption bound to the textarea via `htmlFor` | yes | mono uppercase caption styling |
| EditorToolbar | adhsdk://recipes/editor-toolbar | `role="toolbar"` row holding the controls | yes | `ariaLabel` |
| MarkdownQuickReference | adhsdk://recipes/markdown-quick-reference | Built-in quick-reference popover control | optional (`quickReference`, default on) | side/align defaults |
| Button | adhsdk://recipes/button | The "Upload .md" trigger | optional (only when `onUpload` set) | `variant="outline" size="sm"` |

> The Textarea, Label, and EditorToolbar are atomic `@adh-sdk/ui` primitives
> reused as-is; the upload control wraps a hidden native `<input
> type="file">` (the only way to open a file picker — recorded with an
> `adh-ui-allow: cs-no-bespoke` marker in the source).

## Integration Requirements

- **label-textarea**: The editor MUST render the markdown source in a
  `Textarea` whose accessible name is the `label` (default `Markdown body`),
  associated via `htmlFor`/`id`.
- **controlled-value**: The editor MUST render `value` in the textarea and call
  `onChange` with the next string on every edit (no internal source-of-truth).
- **default-spellcheck-off**: The editor MUST default `spellCheck` to `false`
  on the textarea, while allowing the consumer to enable it.
- **show-toolbar-when-controls-exist**: The editor MUST render a
  `role="toolbar"` row when any toolbar control is present (`onUpload`,
  `quickReference`, or `toolbarExtras`), and MUST omit the toolbar entirely when
  none are.
- **upload-on-demand**: When `onUpload` is provided, the editor MUST render a
  built-in "Upload .md" control that reads the chosen file's text and calls
  `onUpload(text, fileName)`; it MUST NOT render the control when `onUpload` is
  absent.
- **accept-markdown-and-text-files**: The upload control's native file input
  MUST accept `.md`, `.markdown`, and `.txt` files (MIME types `text/markdown`
  and `text/plain`).
- **reset-file-input**: The upload control MUST clear the native file input
  after each selection so re-choosing the same file fires `change` again.
- **include-quick-reference**: The editor MUST include the
  `MarkdownQuickReference` control in the toolbar by default, and MUST omit it
  when `quickReference={false}`.
- **slot-extra-controls**: The editor MUST render `toolbarExtras` in the
  toolbar ahead of the built-in controls.
- **propagate-disabled**: When `disabled`, the editor MUST disable the
  textarea and the upload control. It leaves the quick-reference control and
  `toolbarExtras` enabled: `MarkdownQuickReference` exposes no `disabled` prop
  to receive, and `toolbarExtras` content is the consumer's own to disable (see
  **Design Decisions**).

## Layout

```
┌ MarkdownEditor (flex flex-col gap-1.5) ────────────────────────────┐
│ ┌ header row (flex items-center justify-between) ────────────────┐ │
│ │ MARKDOWN BODY            [extras] [⬆ Upload .md] [▮ Markdown]   │ │
│ │  └ Label (htmlFor)        └──── EditorToolbar (role="toolbar") ─┘ │
│ └────────────────────────────────────────────────────────────────┘ │
│ ┌ Textarea (id, rows, mono) ─────────────────────────────────────┐ │
│ │ # My research                                                  │ │
│ │ …                                                              │ │
│ └────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

- The header row puts the `Label` on the left and the `EditorToolbar` on the
  right (`justify-between`).
- Toolbar order: `toolbarExtras` → Upload .md (if `onUpload`) → quick reference
  (if `quickReference`).
- The textarea sits full-width below the row, mono (`font-mono text-[0.8rem]`),
  `rows` tall (default 16).
- Tokens only (inherited from Textarea/Label/Button/Popover); no raw hex, no
  `!important`.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| markdown source | consumer (`value`) | Textarea | down | controlled `value` prop |
| edits | Textarea | consumer (`onChange`) | up | `onChange(next: string)` |
| uploaded file | upload control | consumer (`onUpload`) | up | `onUpload(text, fileName)` — caller sets body + title |
| textarea id | `useId()` (internal) | Label `htmlFor` ↔ Textarea `id` | internal | generated once per instance |
| popover open/closed | MarkdownQuickReference (internal) | — | internal | the shared Popover's own state |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | label-textarea | Render with no `label` | A `TEXTAREA` is reachable by accessible name `Markdown body` |
| T2 | label-textarea | Render `label="Notes"` | The textarea's accessible name is `Notes` |
| T3 | controlled-value | Type `# Title` into the textarea | `onChange` is called with `# Title` |
| T4 | default-spellcheck-off | Render with defaults | The textarea has `spellcheck="false"` |
| T5 | show-toolbar-when-controls-exist | Render with defaults (quick-ref on) | A `role="toolbar"` named `Markdown editor toolbar` is present |
| T6 | show-toolbar-when-controls-exist, include-quick-reference | Render `quickReference={false}` with no upload/extras | No `role="toolbar"` and no `Markdown quick reference` button |
| T7 | upload-on-demand | Render without `onUpload`, then with it | The `Upload .md` button is absent, then present |
| T8 | upload-on-demand, reset-file-input | Provide `onUpload`; select a `notes.md` file containing `# Hello` twice in a row | `onUpload` is called twice, both times with `('# Hello', 'notes.md')` |
| T9 | accept-markdown-and-text-files | Inspect the upload control's native file input | Its `accept` attribute lists `.md`, `.markdown`, `.txt`, `text/markdown`, `text/plain` |
| T10 | include-quick-reference | Click the `Markdown` toolbar control | The quick-reference popover opens (see markdown-quick-reference T2) |
| T11 | slot-extra-controls | Pass `toolbarExtras={<button>Spell check</button>}` | The `Spell check` button renders inside the toolbar |
| T12 | propagate-disabled | Render `disabled` | The textarea and the `Upload .md` button are both disabled |

## Edge Cases

- With `quickReference={false}` and no `onUpload`/`toolbarExtras`, there are no
  controls, so the toolbar row is omitted entirely (no empty `role="toolbar"`).
- The same file chosen twice in a row still fires `onUpload` twice — once per
  selection — because the native input value is reset after each selection.
- `onUpload` reports raw file text + name only; deriving a title (or anything
  else) is the consumer's job — the editor never mutates `value` from an upload.
- Each instance gets a distinct `useId` textarea id, so multiple editors on one
  page never collide on the Label↔Textarea association.
- An empty `value` shows the `placeholder`; the editor renders no empty/error
  state of its own (the body is always valid text — validation belongs to the
  consuming form).
- Disabling the editor (`disabled`) reaches the textarea and the upload
  control only; the quick-reference control and any `toolbarExtras` stay
  interactive (see **propagate-disabled**).

## Platform Notes

- **React / Web (TypeScript):** Block at `packages/web/packages/ui/src/blocks/markdown-editor.tsx`, exported from `@adh-sdk/ui/blocks`. Composes `Textarea` + `Label` + `EditorToolbar` (`components/editor-toolbar`) + `MarkdownQuickReference` (`components/markdown-quick-reference`) + `Button`. Uses `useId()` for instance-unique textarea ids and `role="toolbar"` semantics. Consumed by the host application's own detail views. Demo lives in the workspace's component showcase (Compositions group).
- **SwiftUI:** Start with `TextEditor` for markdown source and `Text` for label. Wrap both in a `VStack`, with an `HStack` above it holding the toolbar controls — not a `ToolbarItem`, which targets window/navigation toolbars rather than an inline row. Use `@Binding<String>` for the controlled value. Note: `TextEditor` has no built-in file picker; use the `.fileImporter(isPresented:allowedContentTypes:onCompletion:)` modifier from `UniformTypeIdentifiers`, allowing `.plainText` plus UTTypes for `md`/`markdown`, or wrap a custom file picker.
- **Compose:** Start with `BasicTextField` for markdown source and `Text` for label, taking `value: String` and `onValueChange: (String) -> Unit` parameters so the composable stays controlled by its caller. Wrap in a `Column` with a `Row` above it for the toolbar controls — a handful of controls doesn't need `LazyRow`'s virtualization. Note: For file picking, use `ActivityResultContracts.OpenDocument()` filtered to MIME types `text/markdown` and `text/plain`.
- **AppKit / UIKit:** Start with `NSTextView` (macOS) or `UITextView` (iOS) for markdown source, `NSTextField` or `UILabel` for label. Add an `NSView` (macOS) or `UIView` (iOS) subclass for the toolbar, using `NSStackView` (macOS, `orientation: .horizontal`) or `UIStackView` (iOS, `axis: .horizontal`). Use `Combine` or property observers for value binding. Note: Native text views require a custom file picker for opening a file; use `NSOpenPanel` (macOS) or `UIDocumentPickerViewController` (iOS) with content types `net.daringfireball.markdown` and `public.plain-text` to accept markdown and plain text.
- **WinUI 3:** Start with a `TextBox` (`AcceptsReturn="True"`, a monospace `FontFamily`, and `IsSpellCheckEnabled="False"` to match **default-spellcheck-off**) for markdown source, `TextBlock` for label. Create a `Grid` with `RowDefinitions` for the label row and the content row, and a secondary `Grid` or `StackPanel` with `Orientation="Horizontal"` for the toolbar controls. Bind value to `TextBox.Text` via `x:Bind` or `Binding`. Note: File picker uses `Windows.Storage.Pickers.FileOpenPicker`; set `FileTypeFilter` to `new[] { ".md", ".markdown", ".txt" }` and `SuggestedStartLocation` to `PickerLocationId.DocumentsLibrary`.

## Design Decisions

**Decision**: Upload reports `(text, fileName)` via `onUpload` instead of
mutating `value` itself.
**Rationale**: Keeps the editor body-only and reusable; the consuming form
decides whether an upload also sets a title or other fields (separation of
concerns).
**Approved**: pending

**Decision**: The quick-reference control is built in (default on) but
toggleable, and there is also a generic `toolbarExtras` slot.
**Rationale**: Common editors get the cheatsheet for free, while bespoke
toolbars can add controls (e.g. a spell-check toggle) without forking the
block.
**Approved**: pending

**Decision**: The textarea id comes from `useId`, not a fixed string.
**Rationale**: A shared component must support multiple instances per page
without colliding the Label↔Textarea association.
**Approved**: pending

**Decision**: `EditorToolbar` is factored as its own exported primitive with
`role="toolbar"`.
**Rationale**: Reusable a11y-correct toolbar semantics for any editor surface,
and it keeps the block focused on composition.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on the source: the textarea's accessible name comes from
`htmlFor`/`id` (T1–T2) and the upload button pairs a visible "Upload .md"
label with the visually-hidden native `<input type="file">`
(screen-reader-support passed); every control — textarea, upload button,
quick-reference trigger — is a native or Base UI element reachable by Tab
(keyboard-navigable passed); the composition uses only `apt-*` tokens with no
raw hex (contrast-ratio passed); `EditorToolbar`'s `role="toolbar"`/`aria-label`
and the `Label`↔`Textarea` `htmlFor` association are wired correctly
(semantic-markup passed); `label`, `toolbarLabel`, and `placeholder` are all
overridable via props, but the upload control's `Upload .md` button text has
no override (no-hardcoded-strings partial); the upload control filters by
`accept` client-side but the source performs no server-side, size, or
encoding validation of the chosen file's content before calling `onUpload`
(input-sanitization partial); and the editor holds and forwards exactly the
`value`/file content the consumer wires in, nothing more (data-minimization
passed). Touch-target sizing and toolbar keyboard-roving are governed by the
composed Button and EditorToolbar recipes, not re-assessed here; User Safety
is omitted because the editor neither moderates nor publicly displays content.
`separation-of-concerns` passes: `markdown-editor.tsx` composes `Label`,
`Textarea`, `EditorToolbar`, and `MarkdownQuickReference`, and its only
non-presentational code — `UploadMarkdownControl`'s file read — is isolated
in its own small subcomponent rather than entangled with the editor's
layout. `unit-test-coverage` fails — no test file in the `ui` package
exercises `MarkdownEditor` or `UploadMarkdownControl`.

## API

`@adh-sdk/ui/blocks/markdown-editor`:

```ts
interface MarkdownEditorProps {
  value: string
  onChange: (next: string) => void
  label?: React.ReactNode        // default "Markdown body"
  placeholder?: string
  rows?: number                  // default 16; ignored when `fill`
  spellCheck?: boolean           // default false
  onUpload?: (text: string, fileName: string) => void
  quickReference?: boolean       // default true
  toolbarExtras?: React.ReactNode
  toolbarLabel?: string          // default "Markdown editor toolbar"
  className?: string
  textareaClassName?: string
  disabled?: boolean
  fill?: boolean                 // default false — root becomes `min-h-0 flex-1`
                                  // and the textarea flexes to the parent's
                                  // height instead of a fixed `rows` box; the
                                  // parent MUST supply a bounded height
}
export function MarkdownEditor(props: MarkdownEditorProps): React.ReactElement
```

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Conventions_5: moved `## API` from between Platform Notes/Design Decisions to after Compliance, before Change History. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; add an API prop table; add accept-markdown-and-text-files requirement and vector; clarify disabled-scope for quick-reference/toolbarExtras; link ingredient domains; approve design decisions; rebuild Compliance from the catalog; correct SwiftUI/Compose/AppKit/WinUI 3 platform-note APIs; strengthen T8/T12 vectors; genericize consumer-specific naming; dedupe related; fix 1.1.0 author attribution |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Expand Platform Notes with SwiftUI, Compose, AppKit/UIKit, and WinUI 3 translation guidance; update domain to agenticdevelopercookbook; set status to review |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe for the shared MarkdownEditor extracted from hub's ResearchDetail (contract c9). |
