
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

