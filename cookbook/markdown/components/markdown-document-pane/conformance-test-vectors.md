
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

