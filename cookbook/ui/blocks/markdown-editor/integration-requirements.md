
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

