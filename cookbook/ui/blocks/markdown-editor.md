---
id: b118c7bc-e163-40f0-bcc8-eb079e835794
title: "MarkdownEditor"
type: recipe
version: 1.2.2
status: review
language: en
created: 2026-06-26
modified: 2026-11-14
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
  - 1e323e69-44d2-4a15-a11e-22a68e8e6a8c
  - c5703986-6d14-4341-8719-b89e44f2ab80
  - 3c65c844-6c3c-43e2-b792-8575f5dda9cf
  - f5d2eb1c-fb0e-48e3-b124-7e730ac8231c
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
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

| Name | rdid | Role | Required | Configuration |
|---|---|---|---|---|
| Textarea | [adhsdk.ingredient.ui.components.inputs.textarea](cookbook:1e323e69-44d2-4a15-a11e-22a68e8e6a8c) | The markdown source field | yes | `id` (from `useId`), `rows`, `spellCheck`, mono font |
| Label | [adhsdk.ingredient.ui.components.inputs.label](cookbook:c5703986-6d14-4341-8719-b89e44f2ab80) | Caption bound to the textarea via `htmlFor` | yes | mono uppercase caption styling |
| EditorToolbar | [adhsdk.ingredient.ui.components.actions.editor-toolbar](cookbook:3c65c844-6c3c-43e2-b792-8575f5dda9cf) | `role="toolbar"` row holding the controls | yes | `ariaLabel` |
| MarkdownQuickReference | [adhsdk.ingredient.ui.components.actions.markdown-quick-reference](cookbook:f5d2eb1c-fb0e-48e3-b124-7e730ac8231c) | Built-in quick-reference popover control | optional (`quickReference`, default on) | side/align defaults |
| Button | [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) | The "Upload .md" trigger | optional (only when `onUpload` set) | `variant="outline" size="sm"` |

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
- **fill-parent-height**: When `fill` is set, the editor MUST make its root a
  `min-h-0 flex-1` column and let the textarea flex to the parent's height
  (`min-h-0 flex-1 resize-none`, no `rows` attribute, no manual resize grip);
  `rows` is ignored. The parent MUST supply a bounded height — a fill editor
  inside a scroller has nothing to fill. Without `fill`, the textarea is `rows`
  tall (default 16).
- **forward-textarea-props**: The editor MUST set the textarea's `placeholder`
  from `placeholder`, and MUST merge `textareaClassName` onto the textarea after
  its own classes; `className` MUST be merged onto the root element after the
  root's own classes. These three props are plain pass-throughs.

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
- With `fill`, the root gains `min-h-0 flex-1` and the textarea flexes to fill it
  (no `rows`, no resize grip); the parent MUST provide a bounded height (see
  **fill-parent-height**).
- Tokens only (the `apt-*` token utilities, inherited from Textarea/Label/Button/Popover);
  no raw hex, no `!important`.

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
| T10 | include-quick-reference | Click the `Markdown` toolbar control | The quick-reference popover opens (see vector T2 of the `MarkdownQuickReference` ingredient, [adhsdk.ingredient.ui.components.actions.markdown-quick-reference](cookbook:f5d2eb1c-fb0e-48e3-b124-7e730ac8231c)) |
| T11 | slot-extra-controls | Pass `toolbarExtras={<button>Spell check</button>}` | The `Spell check` button renders inside the toolbar |
| T12 | propagate-disabled | Render `disabled` | The textarea and the `Upload .md` button are both disabled |
| T13 | fill-parent-height | Render with defaults, then with `fill` | By default the textarea has `rows="16"`; with `fill` it has no `rows` attribute, carries `flex-1` and `resize-none`, and the root carries `flex-1` |
| T14 | forward-textarea-props | Render `placeholder="Write here"`, `textareaClassName="x-ta"` and `className="x-root"` with an empty `value` | The textarea shows the placeholder and has class `x-ta`; the root element has class `x-root` |
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
- Reading an uploaded file is not guarded: the control awaits the file's text
  with no error handling and no size limit, so a failed read rejects unhandled
  and `onUpload` is not called; whatever the browser decodes is passed along as-is.
- Disabling the editor (`disabled`) reaches the textarea and the upload
  control only; the quick-reference control and any `toolbarExtras` stay
  interactive (see **propagate-disabled**).

## Platform Notes

- **React / Web (TypeScript):** Block at `packages/web/packages/ui/src/blocks/markdown-editor.tsx`, exported from `@adh-sdk/ui/blocks`. Composes `Textarea` + `Label` + `EditorToolbar` (`components/editor-toolbar`) + `MarkdownQuickReference` (`components/markdown-quick-reference`) + `Button`. Uses `useId()` for instance-unique textarea ids and `role="toolbar"` semantics. Consumed by the host application's own detail views. Demo lives in the workspace's component showcase (Compositions group).
- **SwiftUI:** Start with `TextEditor` for markdown source and `Text` for label. Wrap both in a `VStack`, with an `HStack` above it holding the toolbar controls — not a `ToolbarItem`, which targets window/navigation toolbars rather than an inline row. Use `@Binding var text: String` for the controlled value. Note: `TextEditor` has no built-in file picker; use the SwiftUI `.fileImporter(isPresented:allowedContentTypes:onCompletion:)` modifier, with `UTType` values from `UniformTypeIdentifiers`, allowing `.plainText` plus UTTypes for `md`/`markdown`, or wrap a custom file picker.
- **Compose:** Start with `BasicTextField` for markdown source and `Text` for label, taking `value: String` and `onValueChange: (String) -> Unit` parameters so the composable stays controlled by its caller. Wrap in a `Column` with a `Row` above it for the toolbar controls — a handful of controls doesn't need `LazyRow`'s virtualization. Note: For file picking, use `ActivityResultContracts.OpenDocument()` filtered to MIME types `text/markdown` and `text/plain`.
- **AppKit / UIKit:** Start with `NSTextView` (macOS) or `UITextView` (iOS) for markdown source, `NSTextField` or `UILabel` for label. Add an `NSView` (macOS) or `UIView` (iOS) subclass for the toolbar, using `NSStackView` (macOS, `orientation: .horizontal`) or `UIStackView` (iOS, `axis: .horizontal`). Use `Combine` or property observers for value binding. Note: Native text views require a custom file picker for opening a file; use `NSOpenPanel` (macOS) or `UIDocumentPickerViewController` (iOS) with content types `net.daringfireball.markdown` and `public.plain-text` to accept markdown and plain text.
- **WinUI 3:** Start with a `TextBox` (`AcceptsReturn="True"`, a monospace `FontFamily`, and `IsSpellCheckEnabled="False"` to match **default-spellcheck-off**) for markdown source, `TextBlock` for label. Create a `Grid` with `RowDefinitions` for the label row and the content row, and a secondary `Grid` or `StackPanel` with `Orientation="Horizontal"` for the toolbar controls. Bind value to `TextBox.Text` via `x:Bind` or `Binding`. Note: File picker uses `Windows.Storage.Pickers.FileOpenPicker`; set `FileTypeFilter` to `new[] { ".md", ".markdown", ".txt" }` and `SuggestedStartLocation` to `PickerLocationId.DocumentsLibrary`.

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

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/markdown-editor.tsx` | confirmed (1.2.2) |

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

**Decision**: When `disabled`, the quick-reference control and `toolbarExtras`
stay enabled.
**Rationale**: The quick reference is read-only help that is harmless while the
body is locked, and `MarkdownQuickReference` takes no `disabled` prop; the
`toolbarExtras` content belongs to the consumer, who disables it themselves.
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
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy & Data |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

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
layout. `unit-test-coverage` is passed —
`markdownEditor.test.tsx` has one test per vector T1 to T14: the label,
controlled value, spell-check default, toolbar presence, quick reference, extras,
upload (including the file-input reset and `accept` list), `disabled`, fill and
the pass-through props.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.2 | 2026-11-14 | Mike Fullerton | Added fill-parent-height and forward-textarea-props requirements with vectors T13-T14, recorded the unguarded file read and the disabled-leaves-quick-reference decision, linked the quick-reference ingredient in T10, moved API ahead of Compliance, set unit-test coverage to partial, and fixed the SwiftUI notes and the token wording. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Conventions_5: moved `## API` from between Platform Notes/Design Decisions to after Compliance, before Change History. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; add an API prop table; add accept-markdown-and-text-files requirement and vector; clarify disabled-scope for quick-reference/toolbarExtras; link ingredient domains; approve design decisions; rebuild Compliance from the catalog; correct SwiftUI/Compose/AppKit/WinUI 3 platform-note APIs; strengthen T8/T12 vectors; genericize consumer-specific naming; dedupe related; fix 1.1.0 author attribution |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Expand Platform Notes with SwiftUI, Compose, AppKit/UIKit, and WinUI 3 translation guidance; update domain to agenticdevelopercookbook; set status to review |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe for the shared MarkdownEditor extracted from hub's ResearchDetail (contract c9). |
