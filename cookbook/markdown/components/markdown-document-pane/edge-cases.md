
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

