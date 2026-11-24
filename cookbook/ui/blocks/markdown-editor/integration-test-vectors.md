
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
